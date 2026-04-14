#=
    NEMO: Next Energy Modeling system for Optimization.
    https://github.com/sei-international/NemoMod.jl

    Copyright © 2024: Stockholm Environment Institute U.S.

    File description: Functions for converting an OSeMOSYS scenario database to NemoMod format.
=#

"""
    convert_osemosys(osemosys_path::String, nemo_path::String;
        defaults::Dict{String, Float64} = Dict{String, Float64}(),
        quiet::Bool = false,
        config_path::String = "")

Converts an OSeMOSYS scenario database to NemoMod format.

`osemosys_path` can be either:
- A path to an SQLite database with OSeMOSYS-format tables (as produced by
  [otoole](https://github.com/OSeMOSYS/otoole)), or
- A path to a directory of otoole-format CSV files (one CSV per OSeMOSYS table, with columns
  named after set members and `VALUE`). In this case, `config_path` must also be provided.
  The CSV directory is loaded into a temporary SQLite database in-process using `CSV.jl` and
  `YAML.jl` — otoole does not need to be installed.

The OSeMOSYS tables should use uppercase column names matching set names (e.g., `REGION`,
`TECHNOLOGY`, `YEAR`) and `VALUE` for data columns.

Creates a new NemoMod scenario database at `nemo_path` using [`createnemodb`](@ref), then copies
and transforms data from the OSeMOSYS source. Tables that exist only in NemoMod (e.g., transmission
network tables) are left empty.

# Arguments
- `osemosys_path::String`: Path to the source OSeMOSYS SQLite database or otoole CSV directory.
- `nemo_path::String`: Path for the output NemoMod SQLite database (will be created/overwritten).
- `defaults::Dict{String, Float64} = Dict{String, Float64}()`: Default values to set in the
  NemoMod `DefaultParams` table, keyed by parameter table name.
- `quiet::Bool = false`: Suppresses status messages when `true`.
- `config_path::String = ""`: Path to otoole config.yaml file. Required when `osemosys_path` is
  a CSV directory. Used to determine each CSV's schema (column types and indices) and to
  validate that every CSV file in the directory matches a declared table.
"""
function convert_osemosys(osemosys_path::String, nemo_path::String;
    defaults::Dict{String, Float64} = Dict{String, Float64}(),
    quiet::Bool = false,
    config_path::String = "")

    # Determine if osemosys_path is a directory (CSV) or file (SQLite)
    local sqlite_path::String = osemosys_path
    local temp_sqlite::Bool = false

    if isdir(osemosys_path)
        # CSV directory: parse config.yaml and load into a temporary SQLite via the native Julia loader.
        isempty(config_path) && error("config_path is required when osemosys_path is a CSV directory.")
        !isfile(config_path) && error("Config file not found: $(config_path)")

        logmsg("Parsing otoole config at $(config_path)...", quiet)
        local config = _parse_otoole_config(config_path)

        sqlite_path = tempname() * ".sqlite"
        temp_sqlite = true

        logmsg("Loading CSV directory into temporary SQLite...", quiet)
        try
            _load_csv_directory_to_sqlite!(osemosys_path, sqlite_path, config)
        catch e
            rm(sqlite_path; force=true)
            error("Failed to load CSV directory at $(osemosys_path): $(e)")
        end

        logmsg("Loaded CSV directory: $(sqlite_path)", quiet)
    elseif !isfile(osemosys_path)
        error("OSeMOSYS path not found: $(osemosys_path)")
    end

    # Open source database
    local srcdb::SQLite.DB
    try
        srcdb = SQLite.DB(sqlite_path)
    catch e
        temp_sqlite && rm(sqlite_path; force=true)
        rethrow()
    end

    logmsg("Opened OSeMOSYS database at $(sqlite_path).", quiet)

    # Create target NemoMod database (this creates full schema at version 11)
    isfile(nemo_path) && logmsg("Warning: overwriting existing file at $(nemo_path).", quiet)
    local destdb::SQLite.DB = createnemodb(nemo_path; defaultvals=defaults)
    logmsg("Created NemoMod database at $(nemo_path).", quiet)

    # Get list of tables in source database
    local src_tables::Vector{String} = [r[:name] for r in
        SQLite.DBInterface.execute(srcdb, "SELECT name FROM sqlite_master WHERE type='table'")]

    # Validate that required dimension tables exist
    required_tables = ["REGION", "TECHNOLOGY", "FUEL", "YEAR", "TIMESLICE", "MODE_OF_OPERATION"]
    missing_tables = filter(t -> !_osemosys_table_exists(src_tables, t), required_tables)
    if !isempty(missing_tables)
        logmsg("Warning: source database is missing required OSeMOSYS tables: $(join(missing_tables, ", ")).", quiet)
    end

    # BEGIN: Wrap all operations in try-catch for rollback on error.
    try
        SQLite.DBInterface.execute(destdb, "BEGIN")

        # Create temporary unique indexes on parameter tables so INSERT OR IGNORE
        # correctly deduplicates rows. NemoMod tables only have PRIMARY KEY(id) with
        # auto-increment, so without these indexes INSERT OR IGNORE never ignores.
        _dedup_indexes = _create_dedup_indexes!(destdb)

        # 1. Convert dimension tables (sets)
        _convert_osemosys_sets!(srcdb, destdb, src_tables, quiet)

        # 2. Convert time slicing structure
        _convert_osemosys_timeslicing!(srcdb, destdb, src_tables, quiet)

        # 3. Copy parameters with compatible schemas
        _copy_osemosys_compatible_params!(srcdb, destdb, src_tables, quiet)

        # 4. Transform parameters with schema differences
        _transform_osemosys_availability_factor!(srcdb, destdb, src_tables, quiet)
        _transform_osemosys_reserve_margin!(srcdb, destdb, src_tables, quiet)
        _transform_osemosys_re_targets!(srcdb, destdb, src_tables, quiet)

        # Log any unrecognized source tables
        known_tables = Set(lowercase.([
            "emission", "fuel", "mode_of_operation", "region", "technology", "timeslice", "year", "storage",
            "season", "daytype", "conversionls", "conversionld", "conversionlh", "daysindaytype",
            "accumulatedannualdemand", "annualemissionlimit", "annualexogenousemission",
            "capacityofonetechnologyunit", "capacitytoactivityunit", "capitalcost", "capitalcoststorage",
            "depreciationmethod", "discountrate", "emissionactivityratio", "emissionspenalty",
            "fixedcost", "inputactivityratio", "minstoragecharge", "modelperiodemissionlimit",
            "modelperiodexogenousemission", "operationallife", "operationallifestorage",
            "outputactivityratio", "retagtechnology", "residualcapacity", "residualstoragecapacity",
            "specifiedannualdemand", "specifieddemandprofile", "storagelevelstart",
            "storagemaxchargerate", "storagemaxdischargerate", "technologyfromstorage",
            "technologytostorage", "totalannualmaxcapacity", "totalannualmaxcapacityinvestment",
            "totalannualmincapacity", "totalannualmincapacityinvestment",
            "totaltechnologyannualactivitylowerlimit", "totaltechnologyannualactivityupperlimit",
            "totaltechnologymodelperiodactivitylowerlimit", "totaltechnologymodelperiodactivityupperlimit",
            "traderoute", "variablecost", "yearsplit",
            "capacityfactor", "availabilityfactor", "reservemargin", "reservemargintagfuel",
            "reservemargintagtechnology", "reminproductiontarget", "retagfuel"
        ]))
        unrecognized = filter(t -> !(lowercase(t) in known_tables), src_tables)
        if !isempty(unrecognized)
            logmsg("Warning: the following source tables were not converted: $(join(unrecognized, ", ")).", quiet)
        end

        # Drop temporary dedup indexes before committing
        for idx_name in _dedup_indexes
            SQLite.DBInterface.execute(destdb, "DROP INDEX IF EXISTS $(idx_name)")
        end

        SQLite.DBInterface.execute(destdb, "COMMIT")
        logmsg("Conversion complete.", quiet)
    catch
        SQLite.DBInterface.execute(destdb, "ROLLBACK")
        DBInterface.close!(destdb)
        rm(nemo_path; force=true)
        rethrow()
    finally
        # Always close source database
        DBInterface.close!(srcdb)

        # Clean up temporary SQLite file if we created one from CSV
        if temp_sqlite
            rm(sqlite_path; force=true)
            logmsg("Cleaned up temporary SQLite file.", quiet)
        end
    end
    # END: Wrap all operations in try-catch for rollback on error.

    return destdb
end  # convert_osemosys

"""
    _osemosys_table_exists(src_tables::Vector{String}, name::String)

Returns `true` if `name` is present in `src_tables` (case-insensitive)."""
function _osemosys_table_exists(src_tables::Vector{String}, name::String)
    return any(t -> lowercase(t) == lowercase(name), src_tables)
end

"""
    _osemosys_table_name(src_tables::Vector{String}, name::String)

Returns the actual table name from `src_tables` matching `name` (case-insensitive),
or `nothing` if not found."""
function _osemosys_table_name(src_tables::Vector{String}, name::String)
    idx = findfirst(t -> lowercase(t) == lowercase(name), src_tables)
    return isnothing(idx) ? nothing : src_tables[idx]
end

"""
    _read_osemosys_set(srcdb::SQLite.DB, src_tables::Vector{String}, name::String)

Reads a set table from the OSeMOSYS database. Returns a Vector{String} of values."""
function _read_osemosys_set(srcdb::SQLite.DB, src_tables::Vector{String}, name::String)
    tname = _osemosys_table_name(src_tables, name)
    isnothing(tname) && return String[]

    df::DataFrame = SQLite.DBInterface.execute(srcdb, "SELECT * FROM $(_quote_id(tname))") |> DataFrame

    if size(df, 1) == 0
        return String[]
    end

    # OSeMOSYS sets typically have a VALUE column (case-insensitive)
    val_col = _resolve_column(String.(names(df)), "VALUE")
    if !isnothing(val_col)
        return string.(df[!, val_col])
    else
        return string.(df[!, 1])
    end
end

"""
    _read_osemosys_param(srcdb::SQLite.DB, src_tables::Vector{String}, name::String)

Reads a parameter table from the OSeMOSYS database. Returns a DataFrame with original column names."""
function _read_osemosys_param(srcdb::SQLite.DB, src_tables::Vector{String}, name::String)
    tname = _osemosys_table_name(src_tables, name)
    isnothing(tname) && return DataFrame()
    return SQLite.DBInterface.execute(srcdb, "SELECT * FROM $(_quote_id(tname))") |> DataFrame
end

"""Quotes a SQL identifier (table or column name) to prevent injection and handle special characters."""
_quote_id(name::String) = "\"" * replace(name, "\"" => "\"\"") * "\""

"""Resolves a column name case-insensitively from a list of actual column names.
Returns the actual column name or `nothing` if not found."""
function _resolve_column(actual_columns::Vector{String}, expected::String)
    idx = findfirst(c -> lowercase(c) == lowercase(expected), actual_columns)
    return isnothing(idx) ? nothing : actual_columns[idx]
end

"""Returns the actual column names for a table in the source database."""
function _get_column_names(srcdb::SQLite.DB, table_name::String)
    colinfo = SQLite.DBInterface.execute(srcdb,
        "PRAGMA table_info($(_quote_id(table_name)))") |> DataFrame
    return String.(colinfo[!, :name])
end

# ---- otoole CSV directory loader ----
# Replaces a former shellout to `otoole convert csv sqlite ...`, which never
# actually existed in any installable otoole release. The native loader uses
# CSV.jl for RFC 4180 parsing and YAML.jl for parsing the otoole config file.

"""otoole config.yaml dtype -> SQLite column type."""
const _OTOOLE_DTYPE_TO_SQLITE = Dict(
    "str"   => "TEXT",
    "int"   => "INTEGER",
    "float" => "REAL",
)

"""
    _parse_otoole_config(config_path::String)

Parses an otoole config.yaml and returns a normalized table-name → schema map.
Each value is a `NamedTuple` with:
- `type`    — `:set` or `:param`
- `dtype`   — the otoole dtype string for the VALUE column ("str", "int", "float")
- `indices` — index column names in declaration order; empty for sets

Throws an `ErrorException` if the YAML is unparseable, if any entry is missing
`type` or `dtype`, if `type` is not "set"/"param", or if `dtype` is not str/int/float.
"""
function _parse_otoole_config(config_path::String)
    raw = try
        YAML.load_file(config_path)
    catch e
        error("Failed to parse otoole config at $(config_path): $(e)")
    end

    isa(raw, AbstractDict) ||
        error("otoole config $(config_path) must be a YAML mapping at the top level")

    out = Dict{String, NamedTuple{(:type, :dtype, :indices), Tuple{Symbol, String, Vector{String}}}}()

    for (tname, entry) in raw
        isa(entry, AbstractDict) ||
            error("otoole config $(config_path): entry $(tname) is not a mapping")

        haskey(entry, "type")  || error("otoole config $(config_path): entry $(tname) is missing 'type'")
        haskey(entry, "dtype") || error("otoole config $(config_path): entry $(tname) is missing 'dtype'")

        ttype_str = String(entry["type"])
        ttype = if ttype_str == "set"
            :set
        elseif ttype_str == "param"
            :param
        else
            error("otoole config $(config_path): entry $(tname) has invalid type '$(ttype_str)' (expected 'set' or 'param')")
        end

        dtype = String(entry["dtype"])
        haskey(_OTOOLE_DTYPE_TO_SQLITE, dtype) ||
            error("otoole config $(config_path): entry $(tname) has invalid dtype '$(dtype)' (expected str/int/float)")

        indices = if ttype == :param
            haskey(entry, "indices") || error("otoole config $(config_path): param $(tname) is missing 'indices'")
            String[String(i) for i in entry["indices"]]
        else
            String[]
        end

        out[String(tname)] = (type=ttype, dtype=dtype, indices=indices)
    end

    return out
end

"""Returns the SQLite type for a column in a given table, given the parsed config.
For the VALUE column, uses the table's own dtype. For index columns (which name a set),
follows the reference back to the set's dtype. Errors if the index references an
undefined or non-set entry."""
function _column_sqlite_type(config::AbstractDict, table_name::String, col_name::String)
    if uppercase(col_name) == "VALUE"
        return _OTOOLE_DTYPE_TO_SQLITE[config[table_name].dtype]
    else
        # col_name should match a set entry in config (case-insensitive)
        keys_vec = collect(keys(config))
        match_idx = findfirst(k -> lowercase(k) == lowercase(col_name) && config[k].type == :set, keys_vec)
        isnothing(match_idx) &&
            error("otoole config: index column '$(col_name)' of $(table_name) does not name a defined set")
        return _OTOOLE_DTYPE_TO_SQLITE[config[keys_vec[match_idx]].dtype]
    end
end

"""
    _load_csv_directory_to_sqlite!(csv_dir::String, sqlite_path::String, config::AbstractDict)

Loads an otoole-format CSV directory into a fresh OSeMOSYS-shaped SQLite database
at `sqlite_path`, using `config` (as produced by [`_parse_otoole_config`](@ref))
to determine each table's schema and to validate the CSV files.

Behavior:
- A SQLite table is created for **every** entry in `config`, with column types
  derived from the otoole dtypes (sets get a single `VALUE` column; params get
  `[indices..., VALUE]`).
- For each table, if a `<NAME>.csv` exists in `csv_dir`, its rows are loaded.
  CSV.jl handles parsing — quoted fields, embedded commas, escaping, and BOMs
  all work transparently.
- Tables with no CSV file (or with an empty CSV file) are left empty (with a
  warning for the empty-file case).
- CSVs whose header columns disagree with the config (case-insensitive set
  comparison) → ERROR with a list of missing/extra columns.
- CSVs with ragged rows (any field is `missing` after parsing) → ERROR with the
  row number and column name.
- CSV files in `csv_dir` whose name does not match a config entry → ERROR
  (catches stale files and typos early).
- Files that are not `*.csv` (case-insensitive), and subdirectories, are silently
  ignored — so `config.yaml`, `README.md`, etc. cohabit cleanly.
- Any existing file at `sqlite_path` is overwritten.

CSV column order in the file may differ from the config's `indices` declaration —
columns are matched by name (case-insensitive) and reordered to match the SQLite
table's declared column order.

On error, the partially-written SQLite file is removed before the exception
propagates, so a parse failure does not leave a stale file behind.
"""
function _load_csv_directory_to_sqlite!(csv_dir::String, sqlite_path::String, config::AbstractDict)
    isfile(sqlite_path) && rm(sqlite_path; force=true)
    db = SQLite.DB(sqlite_path)

    try
        # Discover top-level CSV files (case-insensitive .csv extension, files only)
        csv_files = Dict{String, String}()  # tablename → full path
        for entry in readdir(csv_dir)
            full = joinpath(csv_dir, entry)
            isfile(full) || continue
            lowercase(splitext(entry)[2]) == ".csv" || continue
            tname = splitext(entry)[1]
            csv_files[tname] = full
        end

        # Detect orphaned CSVs (in dir but not in config) — strict
        orphans = setdiff(keys(csv_files), keys(config))
        if !isempty(orphans)
            error("CSV files in $(csv_dir) have no entries in config.yaml: $(join(sort(collect(orphans)), ", "))")
        end

        # Iterate config entries — create tables and load any matching CSV
        for tname in sort(collect(keys(config)))
            entry = config[tname]
            cols = entry.type == :set ? ["VALUE"] : String[entry.indices..., "VALUE"]
            col_decls = join(["\"$(c)\" $(_column_sqlite_type(config, tname, c))" for c in cols], ", ")
            SQLite.DBInterface.execute(db, "CREATE TABLE \"$(tname)\" ($(col_decls))")

            haskey(csv_files, tname) || continue  # no CSV → leave table empty
            full = csv_files[tname]

            if filesize(full) == 0
                @warn "otoole CSV is empty, table $(tname) will have no rows" path=full
                continue
            end

            df = try
                CSV.read(full, DataFrame; types=String, stringtype=String, silencewarnings=true)
            catch e
                error("Failed to parse CSV $(full): $(e)")
            end

            # Header-only file → 0 rows, nothing to insert (table already created)
            size(df, 1) == 0 && continue

            # Validate header (case-insensitive, set equality with declared cols)
            actual_names = String.(names(df))
            actual_lower = Set(lowercase.(actual_names))
            expected_lower = Set(lowercase.(cols))
            if actual_lower != expected_lower
                missing_cols = sort(collect(setdiff(expected_lower, actual_lower)))
                extra_cols = sort(collect(setdiff(actual_lower, expected_lower)))
                error("CSV $(full) header does not match config for table $(tname). " *
                      "Expected columns: $(cols). Got: $(actual_names). " *
                      "Missing: $(missing_cols). Unexpected: $(extra_cols).")
            end

            # Reorder columns to match `cols` (case-insensitive)
            col_indices = Int[
                findfirst(c -> lowercase(c) == lowercase(want), actual_names) for want in cols
            ]

            # Detect ragged rows (any missing in any column → strict error)
            for (i, row) in enumerate(eachrow(df))
                for col_idx in col_indices
                    if ismissing(row[col_idx])
                        error("CSV $(full) row $(i+1) (data row $(i)) has a missing field in column \"$(actual_names[col_idx])\"")
                    end
                end
            end

            placeholders = join(fill("?", length(cols)), ", ")
            insert_sql = "INSERT INTO \"$(tname)\" VALUES ($(placeholders))"
            stmt = SQLite.Stmt(db, insert_sql)
            for row in eachrow(df)
                fields = String[String(row[i]) for i in col_indices]
                DBInterface.execute(stmt, fields)
            end
        end
    catch
        DBInterface.close!(db)
        rm(sqlite_path; force=true)
        rethrow()
    end

    DBInterface.close!(db)
    return sqlite_path
end

"""Creates temporary unique indexes on NemoMod parameter tables so that INSERT OR IGNORE
correctly deduplicates rows. Returns a vector of index names that were created."""
function _create_dedup_indexes!(destdb::SQLite.DB)
    # Map of table name -> data columns (excluding auto-increment id and val)
    table_keys = [
        ("AccumulatedAnnualDemand", ["r", "f", "y"]),
        ("AnnualEmissionLimit", ["r", "e", "y"]),
        ("AnnualExogenousEmission", ["r", "e", "y"]),
        ("AvailabilityFactor", ["r", "t", "l", "y"]),
        ("CapacityOfOneTechnologyUnit", ["r", "t", "y"]),
        ("CapacityToActivityUnit", ["r", "t"]),
        ("CapitalCost", ["r", "t", "y"]),
        ("CapitalCostStorage", ["r", "s", "y"]),
        ("DepreciationMethod", ["r"]),
        ("DiscountRate", ["r"]),
        ("EmissionActivityRatio", ["r", "t", "e", "m", "y"]),
        ("EmissionsPenalty", ["r", "e", "y"]),
        ("FixedCost", ["r", "t", "y"]),
        ("InputActivityRatio", ["r", "t", "f", "m", "y"]),
        ("MinStorageCharge", ["r", "s", "y"]),
        ("ModelPeriodEmissionLimit", ["r", "e"]),
        ("ModelPeriodExogenousEmission", ["r", "e"]),
        ("OperationalLife", ["r", "t"]),
        ("OperationalLifeStorage", ["r", "s"]),
        ("OutputActivityRatio", ["r", "t", "f", "m", "y"]),
        ("REMinProductionTarget", ["r", "f", "y"]),
        ("RETagTechnology", ["r", "t", "y"]),
        ("ReserveMargin", ["r", "f", "y"]),
        ("ReserveMarginTagTechnology", ["r", "t", "f", "y"]),
        ("ResidualCapacity", ["r", "t", "y"]),
        ("ResidualStorageCapacity", ["r", "s", "y"]),
        ("SpecifiedAnnualDemand", ["r", "f", "y"]),
        ("SpecifiedDemandProfile", ["r", "f", "l", "y"]),
        ("StorageLevelStart", ["r", "s"]),
        ("StorageMaxChargeRate", ["r", "s"]),
        ("StorageMaxDischargeRate", ["r", "s"]),
        ("TechnologyFromStorage", ["r", "t", "s", "m"]),
        ("TechnologyToStorage", ["r", "t", "s", "m"]),
        ("TotalAnnualMaxCapacity", ["r", "t", "y"]),
        ("TotalAnnualMaxCapacityInvestment", ["r", "t", "y"]),
        ("TotalAnnualMinCapacity", ["r", "t", "y"]),
        ("TotalAnnualMinCapacityInvestment", ["r", "t", "y"]),
        ("TotalTechnologyAnnualActivityLowerLimit", ["r", "t", "y"]),
        ("TotalTechnologyAnnualActivityUpperLimit", ["r", "t", "y"]),
        ("TotalTechnologyModelPeriodActivityLowerLimit", ["r", "t"]),
        ("TotalTechnologyModelPeriodActivityUpperLimit", ["r", "t"]),
        ("TradeRoute", ["r", "rr", "f", "y"]),
        ("VariableCost", ["r", "t", "m", "y"]),
        ("YearSplit", ["l", "y"]),
    ]

    index_names = String[]

    for (table, cols) in table_keys
        idx_name = "_tmp_dedup_$(table)"
        col_list = join(cols, ", ")
        SQLite.DBInterface.execute(destdb,
            "CREATE UNIQUE INDEX IF NOT EXISTS $(idx_name) ON $(table) ($(col_list))")
        push!(index_names, idx_name)
    end

    return index_names
end

# BEGIN: Set conversion.
function _convert_osemosys_sets!(srcdb::SQLite.DB, destdb::SQLite.DB,
    src_tables::Vector{String}, quiet::Bool)

    # Simple dimension tables: OSeMOSYS VALUE -> NemoMod val
    simple_sets = ["EMISSION", "FUEL", "MODE_OF_OPERATION", "REGION", "TECHNOLOGY", "TIMESLICE", "YEAR"]

    for setname in simple_sets
        vals = _read_osemosys_set(srcdb, src_tables, setname)

        for v in vals
            SQLite.DBInterface.execute(destdb,
                "INSERT OR IGNORE INTO $(setname) (val) VALUES (?)", [v])
        end

        logmsg("Copied $(length(vals)) values for set $(setname).", quiet)
    end

    # STORAGE: has additional fields in NemoMod
    storage_vals = _read_osemosys_set(srcdb, src_tables, "STORAGE")

    for v in storage_vals
        SQLite.DBInterface.execute(destdb,
            "INSERT OR IGNORE INTO STORAGE (val, netzeroyear, netzerotg1, netzerotg2) VALUES (?, 1, 0, 0)", [v])
    end

    logmsg("Copied $(length(storage_vals)) values for set STORAGE.", quiet)
end  # _convert_osemosys_sets!
# END: Set conversion.

# BEGIN: Time slicing conversion.
function _convert_osemosys_timeslicing!(srcdb::SQLite.DB, destdb::SQLite.DB,
    src_tables::Vector{String}, quiet::Bool)

    has_season = _osemosys_table_exists(src_tables, "SEASON")
    has_daytype = _osemosys_table_exists(src_tables, "DAYTYPE")
    has_conversionls = _osemosys_table_exists(src_tables, "Conversionls")
    has_conversionld = _osemosys_table_exists(src_tables, "Conversionld")
    has_conversionlh = _osemosys_table_exists(src_tables, "Conversionlh")
    has_daysindaytype = _osemosys_table_exists(src_tables, "DaysInDayType")

    # Read seasons
    seasons = has_season ? _read_osemosys_set(srcdb, src_tables, "SEASON") : String[]
    daytypes = has_daytype ? _read_osemosys_set(srcdb, src_tables, "DAYTYPE") : String[]

    # --- TSGROUP1 from SEASON ---
    if !isempty(seasons)
        for (idx, season) in enumerate(sort(seasons, by=s -> (tryparse(Int, s) !== nothing ? 0 : 1, tryparse(Int, s) !== nothing ? parse(Int, s) : 0, s)))
            # Calculate multiplier from DaysInDayType
            multiplier = 1.0

            if has_daysindaytype
                tname = _osemosys_table_name(src_tables, "DaysInDayType")
                did_cols = _get_column_names(srcdb, tname)
                did_season = _resolve_column(did_cols, "SEASON")
                did_year = _resolve_column(did_cols, "YEAR")
                did_value = _resolve_column(did_cols, "VALUE")
                qt = _quote_id(tname)

                if !isnothing(did_season) && !isnothing(did_year) && !isnothing(did_value)
                    df = SQLite.DBInterface.execute(srcdb,
                        "SELECT AVG(yearly_total) as total FROM (
                            SELECT $(_quote_id(did_year)), SUM($(_quote_id(did_value))) as yearly_total FROM $(qt)
                            WHERE $(_quote_id(did_season)) = ? GROUP BY $(_quote_id(did_year))
                        )", [season]) |> DataFrame

                    if size(df, 1) > 0 && !ismissing(df[1, :total])
                        # Days in season / 7 = number of weeks (repetitions)
                        multiplier = df[1, :total] / 7.0
                    end
                end
            end

            SQLite.DBInterface.execute(destdb,
                "INSERT INTO TSGROUP1 (name, [order], multiplier, desc) VALUES (?, ?, ?, ?)",
                [season, idx, multiplier, "Season $(season)"])
        end

        logmsg("Created $(length(seasons)) TSGROUP1 entries from SEASON.", quiet)
    else
        # No seasons: create single default group
        SQLite.DBInterface.execute(destdb,
            "INSERT INTO TSGROUP1 (name, [order], multiplier, desc) VALUES (?, ?, ?, ?)",
            ["1", 1, 52.0, "Default (full year)"])
        logmsg("Created default TSGROUP1 (no SEASON in source).", quiet)
    end

    # --- TSGROUP2 from DAYTYPE ---
    if !isempty(daytypes)
        for (idx, daytype) in enumerate(sort(daytypes, by=d -> (tryparse(Int, d) !== nothing ? 0 : 1, tryparse(Int, d) !== nothing ? parse(Int, d) : 0, d)))
            # Default: equal distribution across day types
            multiplier = 7.0 / length(daytypes)

            # Calculate from DaysInDayType for accuracy
            if has_daysindaytype
                tname_did = _osemosys_table_name(src_tables, "DaysInDayType")
                did_cols = _get_column_names(srcdb, tname_did)
                did_season = _resolve_column(did_cols, "SEASON")
                did_daytype = _resolve_column(did_cols, "DAYTYPE")
                did_year = _resolve_column(did_cols, "YEAR")
                did_value = _resolve_column(did_cols, "VALUE")
                qtname = _quote_id(tname_did)

                if !isnothing(did_season) && !isnothing(did_daytype) && !isnothing(did_year) && !isnothing(did_value)
                    qs = _quote_id(did_season); qy = _quote_id(did_year)
                    qv = _quote_id(did_value); qdt = _quote_id(did_daytype)
                    df = SQLite.DBInterface.execute(srcdb,
                        """SELECT AVG(d.$(qv) * 7.0 / st.season_total) as days_per_week
                           FROM $(qtname) d
                           INNER JOIN (
                               SELECT $(qs), $(qy), SUM($(qv)) as season_total
                               FROM $(qtname)
                               GROUP BY $(qs), $(qy)
                           ) st ON d.$(qs) = st.$(qs) AND d.$(qy) = st.$(qy)
                           WHERE d.$(qdt) = ?""", [daytype]) |> DataFrame

                    if size(df, 1) > 0 && !ismissing(df[1, :days_per_week])
                        multiplier = df[1, :days_per_week]
                    end
                end
            end

            SQLite.DBInterface.execute(destdb,
                "INSERT INTO TSGROUP2 (name, [order], multiplier, desc) VALUES (?, ?, ?, ?)",
                [daytype, idx, multiplier, "Day type $(daytype)"])
        end

        logmsg("Created $(length(daytypes)) TSGROUP2 entries from DAYTYPE.", quiet)
    else
        # No day types: create single default group
        SQLite.DBInterface.execute(destdb,
            "INSERT INTO TSGROUP2 (name, [order], multiplier, desc) VALUES (?, ?, ?, ?)",
            ["1", 1, 7.0, "Default (full week)"])
        logmsg("Created default TSGROUP2 (no DAYTYPE in source).", quiet)
    end

    # --- LTsGroup: map each timeslice to tg1, tg2, and order ---
    timeslices = _read_osemosys_set(srcdb, src_tables, "TIMESLICE")

    for ts in timeslices
        # Find season (tg1) via Conversionls
        tg1 = "1"
        if has_conversionls
            tname = _osemosys_table_name(src_tables, "Conversionls")
            cols = _get_column_names(srcdb, tname)
            season_col = _resolve_column(cols, "SEASON")
            ts_col = _resolve_column(cols, "TIMESLICE")
            val_col = _resolve_column(cols, "VALUE")

            if !isnothing(season_col) && !isnothing(ts_col) && !isnothing(val_col)
                df = SQLite.DBInterface.execute(srcdb,
                    "SELECT $(_quote_id(season_col)) FROM $(_quote_id(tname)) WHERE $(_quote_id(ts_col)) = ? AND $(_quote_id(val_col)) = 1", [ts]) |> DataFrame

                if size(df, 1) > 0
                    tg1 = string(df[1, 1])
                end
            end
        end

        # Find day type (tg2) via Conversionld
        tg2 = "1"
        if has_conversionld
            tname = _osemosys_table_name(src_tables, "Conversionld")
            cols = _get_column_names(srcdb, tname)
            dt_col = _resolve_column(cols, "DAYTYPE")
            ts_col = _resolve_column(cols, "TIMESLICE")
            val_col = _resolve_column(cols, "VALUE")

            if !isnothing(dt_col) && !isnothing(ts_col) && !isnothing(val_col)
                df = SQLite.DBInterface.execute(srcdb,
                    "SELECT $(_quote_id(dt_col)) FROM $(_quote_id(tname)) WHERE $(_quote_id(ts_col)) = ? AND $(_quote_id(val_col)) = 1", [ts]) |> DataFrame

                if size(df, 1) > 0
                    tg2 = string(df[1, 1])
                end
            end
        end

        # Find daily time bracket (lorder) via Conversionlh
        lorder = 1
        if has_conversionlh
            tname = _osemosys_table_name(src_tables, "Conversionlh")
            cols = _get_column_names(srcdb, tname)
            dtb_col = _resolve_column(cols, "DAILYTIMEBRACKET")
            ts_col = _resolve_column(cols, "TIMESLICE")
            val_col = _resolve_column(cols, "VALUE")

            if !isnothing(dtb_col) && !isnothing(ts_col) && !isnothing(val_col)
                df = SQLite.DBInterface.execute(srcdb,
                    "SELECT $(_quote_id(dtb_col)) FROM $(_quote_id(tname)) WHERE $(_quote_id(ts_col)) = ? AND $(_quote_id(val_col)) = 1", [ts]) |> DataFrame

                if size(df, 1) > 0
                    parsed = tryparse(Int, string(df[1, 1]))
                    !isnothing(parsed) && (lorder = parsed)
                end
            end
        end

        SQLite.DBInterface.execute(destdb,
            "INSERT INTO LTsGroup (l, lorder, tg1, tg2) VALUES (?, ?, ?, ?)",
            [ts, lorder, tg1, tg2])
    end

    logmsg("Created $(length(timeslices)) LTsGroup mappings.", quiet)
end  # _convert_osemosys_timeslicing!
# END: Time slicing conversion.

# BEGIN: Compatible parameter copy.
function _copy_osemosys_compatible_params!(srcdb::SQLite.DB, destdb::SQLite.DB,
    src_tables::Vector{String}, quiet::Bool)

    # Each entry: (osemosys_table, nemo_table, [(osemosys_col, nemo_col), ...])
    compatible_params = [
        ("AccumulatedAnnualDemand", "AccumulatedAnnualDemand",
            [("REGION", "r"), ("FUEL", "f"), ("YEAR", "y"), ("VALUE", "val")]),
        ("AnnualEmissionLimit", "AnnualEmissionLimit",
            [("REGION", "r"), ("EMISSION", "e"), ("YEAR", "y"), ("VALUE", "val")]),
        ("AnnualExogenousEmission", "AnnualExogenousEmission",
            [("REGION", "r"), ("EMISSION", "e"), ("YEAR", "y"), ("VALUE", "val")]),
        ("CapacityOfOneTechnologyUnit", "CapacityOfOneTechnologyUnit",
            [("REGION", "r"), ("TECHNOLOGY", "t"), ("YEAR", "y"), ("VALUE", "val")]),
        ("CapacityToActivityUnit", "CapacityToActivityUnit",
            [("REGION", "r"), ("TECHNOLOGY", "t"), ("VALUE", "val")]),
        ("CapitalCost", "CapitalCost",
            [("REGION", "r"), ("TECHNOLOGY", "t"), ("YEAR", "y"), ("VALUE", "val")]),
        ("CapitalCostStorage", "CapitalCostStorage",
            [("REGION", "r"), ("STORAGE", "s"), ("YEAR", "y"), ("VALUE", "val")]),
        ("DepreciationMethod", "DepreciationMethod",
            [("REGION", "r"), ("VALUE", "val")]),
        ("DiscountRate", "DiscountRate",
            [("REGION", "r"), ("VALUE", "val")]),
        ("EmissionActivityRatio", "EmissionActivityRatio",
            [("REGION", "r"), ("TECHNOLOGY", "t"), ("EMISSION", "e"), ("MODE_OF_OPERATION", "m"), ("YEAR", "y"), ("VALUE", "val")]),
        ("EmissionsPenalty", "EmissionsPenalty",
            [("REGION", "r"), ("EMISSION", "e"), ("YEAR", "y"), ("VALUE", "val")]),
        ("FixedCost", "FixedCost",
            [("REGION", "r"), ("TECHNOLOGY", "t"), ("YEAR", "y"), ("VALUE", "val")]),
        ("InputActivityRatio", "InputActivityRatio",
            [("REGION", "r"), ("TECHNOLOGY", "t"), ("FUEL", "f"), ("MODE_OF_OPERATION", "m"), ("YEAR", "y"), ("VALUE", "val")]),
        ("MinStorageCharge", "MinStorageCharge",
            [("REGION", "r"), ("STORAGE", "s"), ("YEAR", "y"), ("VALUE", "val")]),
        ("ModelPeriodEmissionLimit", "ModelPeriodEmissionLimit",
            [("REGION", "r"), ("EMISSION", "e"), ("VALUE", "val")]),
        ("ModelPeriodExogenousEmission", "ModelPeriodExogenousEmission",
            [("REGION", "r"), ("EMISSION", "e"), ("VALUE", "val")]),
        ("OperationalLife", "OperationalLife",
            [("REGION", "r"), ("TECHNOLOGY", "t"), ("VALUE", "val")]),
        ("OperationalLifeStorage", "OperationalLifeStorage",
            [("REGION", "r"), ("STORAGE", "s"), ("VALUE", "val")]),
        ("OutputActivityRatio", "OutputActivityRatio",
            [("REGION", "r"), ("TECHNOLOGY", "t"), ("FUEL", "f"), ("MODE_OF_OPERATION", "m"), ("YEAR", "y"), ("VALUE", "val")]),
        ("RETagTechnology", "RETagTechnology",
            [("REGION", "r"), ("TECHNOLOGY", "t"), ("YEAR", "y"), ("VALUE", "val")]),
        ("ResidualCapacity", "ResidualCapacity",
            [("REGION", "r"), ("TECHNOLOGY", "t"), ("YEAR", "y"), ("VALUE", "val")]),
        ("ResidualStorageCapacity", "ResidualStorageCapacity",
            [("REGION", "r"), ("STORAGE", "s"), ("YEAR", "y"), ("VALUE", "val")]),
        ("SpecifiedAnnualDemand", "SpecifiedAnnualDemand",
            [("REGION", "r"), ("FUEL", "f"), ("YEAR", "y"), ("VALUE", "val")]),
        ("SpecifiedDemandProfile", "SpecifiedDemandProfile",
            [("REGION", "r"), ("FUEL", "f"), ("TIMESLICE", "l"), ("YEAR", "y"), ("VALUE", "val")]),
        ("StorageLevelStart", "StorageLevelStart",
            [("REGION", "r"), ("STORAGE", "s"), ("VALUE", "val")]),
        ("StorageMaxChargeRate", "StorageMaxChargeRate",
            [("REGION", "r"), ("STORAGE", "s"), ("VALUE", "val")]),
        ("StorageMaxDischargeRate", "StorageMaxDischargeRate",
            [("REGION", "r"), ("STORAGE", "s"), ("VALUE", "val")]),
        ("TechnologyFromStorage", "TechnologyFromStorage",
            [("REGION", "r"), ("TECHNOLOGY", "t"), ("STORAGE", "s"), ("MODE_OF_OPERATION", "m"), ("VALUE", "val")]),
        ("TechnologyToStorage", "TechnologyToStorage",
            [("REGION", "r"), ("TECHNOLOGY", "t"), ("STORAGE", "s"), ("MODE_OF_OPERATION", "m"), ("VALUE", "val")]),
        ("TotalAnnualMaxCapacity", "TotalAnnualMaxCapacity",
            [("REGION", "r"), ("TECHNOLOGY", "t"), ("YEAR", "y"), ("VALUE", "val")]),
        ("TotalAnnualMaxCapacityInvestment", "TotalAnnualMaxCapacityInvestment",
            [("REGION", "r"), ("TECHNOLOGY", "t"), ("YEAR", "y"), ("VALUE", "val")]),
        ("TotalAnnualMinCapacity", "TotalAnnualMinCapacity",
            [("REGION", "r"), ("TECHNOLOGY", "t"), ("YEAR", "y"), ("VALUE", "val")]),
        ("TotalAnnualMinCapacityInvestment", "TotalAnnualMinCapacityInvestment",
            [("REGION", "r"), ("TECHNOLOGY", "t"), ("YEAR", "y"), ("VALUE", "val")]),
        ("TotalTechnologyAnnualActivityLowerLimit", "TotalTechnologyAnnualActivityLowerLimit",
            [("REGION", "r"), ("TECHNOLOGY", "t"), ("YEAR", "y"), ("VALUE", "val")]),
        ("TotalTechnologyAnnualActivityUpperLimit", "TotalTechnologyAnnualActivityUpperLimit",
            [("REGION", "r"), ("TECHNOLOGY", "t"), ("YEAR", "y"), ("VALUE", "val")]),
        ("TotalTechnologyModelPeriodActivityLowerLimit", "TotalTechnologyModelPeriodActivityLowerLimit",
            [("REGION", "r"), ("TECHNOLOGY", "t"), ("VALUE", "val")]),
        ("TotalTechnologyModelPeriodActivityUpperLimit", "TotalTechnologyModelPeriodActivityUpperLimit",
            [("REGION", "r"), ("TECHNOLOGY", "t"), ("VALUE", "val")]),
        ("VariableCost", "VariableCost",
            [("REGION", "r"), ("TECHNOLOGY", "t"), ("MODE_OF_OPERATION", "m"), ("YEAR", "y"), ("VALUE", "val")]),
        ("YearSplit", "YearSplit",
            [("TIMESLICE", "l"), ("YEAR", "y"), ("VALUE", "val")]),
    ]

    for (src_table, dest_table, col_mapping) in compatible_params
        # Find the actual table name (case-insensitive)
        actual_name = _osemosys_table_name(src_tables, src_table)
        isnothing(actual_name) && continue

        # Resolve actual column names (case-insensitive)
        actual_cols = _get_column_names(srcdb, actual_name)
        expected_src_cols = [m[1] for m in col_mapping]
        dest_cols = [m[2] for m in col_mapping]

        resolved_cols = [_resolve_column(actual_cols, c) for c in expected_src_cols]
        if any(isnothing, resolved_cols)
            missing_cols = expected_src_cols[isnothing.(resolved_cols)]
            logmsg("Warning: $(actual_name) missing columns $(join(missing_cols, ", ")), skipping.", quiet)
            continue
        end

        local df::DataFrame
        try
            select_cols = join([_quote_id(c) for c in resolved_cols], ", ")
            df = SQLite.DBInterface.execute(srcdb,
                "SELECT $(select_cols) FROM $(_quote_id(actual_name))") |> DataFrame
        catch e
            logmsg("Warning: could not read $(actual_name): $(e)", quiet)
            continue
        end

        size(df, 1) == 0 && continue

        placeholders = join(fill("?", length(dest_cols)), ", ")
        insert_sql = "INSERT OR IGNORE INTO $(dest_table) ($(join(dest_cols, ", "))) VALUES ($(placeholders))"

        stmt = SQLite.Stmt(destdb, insert_sql)
        for row in eachrow(df)
            DBInterface.execute(stmt, [row[Symbol(c)] for c in resolved_cols])
        end
        DBInterface.close!(stmt)

        logmsg("Copied $(size(df, 1)) rows from $(actual_name) to $(dest_table).", quiet)
    end

    # TradeRoute: OSeMOSYS has two region columns but naming varies
    _copy_osemosys_traderoute!(srcdb, destdb, src_tables, quiet)
end  # _copy_osemosys_compatible_params!

function _copy_osemosys_traderoute!(srcdb::SQLite.DB, destdb::SQLite.DB,
    src_tables::Vector{String}, quiet::Bool)

    actual_name = _osemosys_table_name(src_tables, "TradeRoute")
    isnothing(actual_name) && return

    # Introspect column names to handle varying conventions
    colnames = _get_column_names(srcdb, actual_name)

    # Find the two region columns and fuel/year/value columns
    region_cols = filter(c -> uppercase(c) == "REGION", colnames)

    # Some OSeMOSYS databases use REGION and rr or REGION2
    if length(region_cols) >= 2
        r_col = region_cols[1]
        rr_col = region_cols[2]
    elseif !isnothing(_resolve_column(colnames, "REGION")) && !isnothing(_resolve_column(colnames, "rr"))
        r_col = _resolve_column(colnames, "REGION")
        rr_col = _resolve_column(colnames, "rr")
    elseif !isnothing(_resolve_column(colnames, "REGION")) && !isnothing(_resolve_column(colnames, "REGION2"))
        r_col = _resolve_column(colnames, "REGION")
        rr_col = _resolve_column(colnames, "REGION2")
    else
        logmsg("Warning: could not determine TradeRoute region columns, skipping.", quiet)
        return
    end

    f_col = _resolve_column(colnames, "FUEL")
    y_col = _resolve_column(colnames, "YEAR")
    v_col = _resolve_column(colnames, "VALUE")

    if isnothing(f_col) || isnothing(y_col) || isnothing(v_col)
        logmsg("Warning: TradeRoute missing required columns (FUEL, YEAR, or VALUE), skipping.", quiet)
        return
    end

    qtn = _quote_id(actual_name)
    df = SQLite.DBInterface.execute(srcdb,
        "SELECT $(_quote_id(r_col)), $(_quote_id(rr_col)), $(_quote_id(f_col)), $(_quote_id(y_col)), $(_quote_id(v_col)) FROM $(qtn)") |> DataFrame

    for row in eachrow(df)
        SQLite.DBInterface.execute(destdb,
            "INSERT OR IGNORE INTO TradeRoute (r, rr, f, y, val) VALUES (?, ?, ?, ?, ?)",
            [row[1], row[2], row[3], row[4], row[5]])
    end

    logmsg("Copied $(size(df, 1)) rows from $(actual_name) to TradeRoute.", quiet)
end  # _copy_osemosys_traderoute!
# END: Compatible parameter copy.

# BEGIN: Availability factor transformation.
function _transform_osemosys_availability_factor!(srcdb::SQLite.DB, destdb::SQLite.DB,
    src_tables::Vector{String}, quiet::Bool)

    # OSeMOSYS CapacityFactor [REGION, TECHNOLOGY, TIMESLICE, YEAR] -> NemoMod AvailabilityFactor [r, t, l, y]
    cf_name = _osemosys_table_name(src_tables, "CapacityFactor")

    if !isnothing(cf_name)
        cols = _get_column_names(srcdb, cf_name)
        r = _resolve_column(cols, "REGION"); t = _resolve_column(cols, "TECHNOLOGY")
        l = _resolve_column(cols, "TIMESLICE"); y = _resolve_column(cols, "YEAR")
        v = _resolve_column(cols, "VALUE")

        df = SQLite.DBInterface.execute(srcdb,
            "SELECT $(_quote_id(r)), $(_quote_id(t)), $(_quote_id(l)), $(_quote_id(y)), $(_quote_id(v)) FROM $(_quote_id(cf_name))") |> DataFrame

        for row in eachrow(df)
            SQLite.DBInterface.execute(destdb,
                "INSERT OR IGNORE INTO AvailabilityFactor (r, t, l, y, val) VALUES (?, ?, ?, ?, ?)",
                [row[1], row[2], row[3], row[4], row[5]])
        end

        logmsg("Transformed $(size(df, 1)) rows from CapacityFactor to AvailabilityFactor.", quiet)
    end

    # OSeMOSYS AvailabilityFactor [REGION, TECHNOLOGY, YEAR] has no timeslice dimension.
    # Expand across all timeslices, but don't overwrite values from CapacityFactor.
    af_name = _osemosys_table_name(src_tables, "AvailabilityFactor")

    if !isnothing(af_name)
        cols = _get_column_names(srcdb, af_name)
        r = _resolve_column(cols, "REGION"); t = _resolve_column(cols, "TECHNOLOGY")
        y = _resolve_column(cols, "YEAR"); v = _resolve_column(cols, "VALUE")

        df = SQLite.DBInterface.execute(srcdb,
            "SELECT $(_quote_id(r)), $(_quote_id(t)), $(_quote_id(y)), $(_quote_id(v)) FROM $(_quote_id(af_name))") |> DataFrame

        if size(df, 1) > 0
            timeslices = _read_osemosys_set(srcdb, src_tables, "TIMESLICE")
            count = 0

            for row in eachrow(df)
                for ls in timeslices
                    SQLite.DBInterface.execute(destdb,
                        "INSERT OR IGNORE INTO AvailabilityFactor (r, t, l, y, val) VALUES (?, ?, ?, ?, ?)",
                        [row[1], row[2], ls, row[3], row[4]])
                    count += 1
                end
            end

            logmsg("Expanded OSeMOSYS AvailabilityFactor to $(count) rows across timeslices.", quiet)
        end
    end
end  # _transform_osemosys_availability_factor!
# END: Availability factor transformation.

# BEGIN: Reserve margin transformation.
function _transform_osemosys_reserve_margin!(srcdb::SQLite.DB, destdb::SQLite.DB,
    src_tables::Vector{String}, quiet::Bool)

    # OSeMOSYS ReserveMargin [REGION, YEAR] -> NemoMod [r, f, y]
    # OSeMOSYS ReserveMarginTagTechnology [REGION, TECHNOLOGY, YEAR] -> NemoMod [r, t, f, y]
    # OSeMOSYS ReserveMarginTagFuel [REGION, FUEL, YEAR] identifies which fuels are subject to reserve margin

    # Get fuels tagged for reserve margin
    reserve_fuels = Dict{Tuple{String,String}, Vector{String}}()  # (region, year) -> [fuels]

    rmtf_name = _osemosys_table_name(src_tables, "ReserveMarginTagFuel")
    if !isnothing(rmtf_name)
        cols = _get_column_names(srcdb, rmtf_name)
        rc = _resolve_column(cols, "REGION"); fc = _resolve_column(cols, "FUEL")
        yc = _resolve_column(cols, "YEAR"); vc = _resolve_column(cols, "VALUE")

        df = SQLite.DBInterface.execute(srcdb,
            "SELECT $(_quote_id(rc)), $(_quote_id(fc)), $(_quote_id(yc)) FROM $(_quote_id(rmtf_name)) WHERE $(_quote_id(vc)) = 1") |> DataFrame

        for row in eachrow(df)
            key = (string(row[1]), string(row[3]))
            if !haskey(reserve_fuels, key)
                reserve_fuels[key] = String[]
            end
            push!(reserve_fuels[key], string(row[2]))
        end
    end

    # Fallback fuel if no ReserveMarginTagFuel data
    all_fuels = _read_osemosys_set(srcdb, src_tables, "FUEL")

    if isempty(all_fuels) && isempty(reserve_fuels)
        logmsg("Warning: no fuels defined and no ReserveMarginTagFuel data; skipping reserve margin transformation.", quiet)
        return
    end

    default_fuel = isempty(all_fuels) ? String[] : [first(all_fuels)]

    # Transform ReserveMargin
    rm_name = _osemosys_table_name(src_tables, "ReserveMargin")

    if !isnothing(rm_name)
        cols = _get_column_names(srcdb, rm_name)
        rc = _resolve_column(cols, "REGION"); yc = _resolve_column(cols, "YEAR")
        vc = _resolve_column(cols, "VALUE")

        df = SQLite.DBInterface.execute(srcdb,
            "SELECT $(_quote_id(rc)), $(_quote_id(yc)), $(_quote_id(vc)) FROM $(_quote_id(rm_name))") |> DataFrame

        count = 0
        for row in eachrow(df)
            key = (string(row[1]), string(row[2]))
            fuels = get(reserve_fuels, key, default_fuel)

            for f in fuels
                SQLite.DBInterface.execute(destdb,
                    "INSERT OR IGNORE INTO ReserveMargin (r, f, y, val) VALUES (?, ?, ?, ?)",
                    [row[1], f, row[2], row[3]])
                count += 1
            end
        end

        logmsg("Transformed ReserveMargin: $(size(df, 1)) rows -> $(count) rows (with fuel dimension).", quiet)
    end

    # Transform ReserveMarginTagTechnology
    rmtt_name = _osemosys_table_name(src_tables, "ReserveMarginTagTechnology")

    if !isnothing(rmtt_name)
        cols = _get_column_names(srcdb, rmtt_name)
        rc = _resolve_column(cols, "REGION"); tc = _resolve_column(cols, "TECHNOLOGY")
        yc = _resolve_column(cols, "YEAR"); vc = _resolve_column(cols, "VALUE")

        df = SQLite.DBInterface.execute(srcdb,
            "SELECT $(_quote_id(rc)), $(_quote_id(tc)), $(_quote_id(yc)), $(_quote_id(vc)) FROM $(_quote_id(rmtt_name)) WHERE $(_quote_id(vc)) > 0") |> DataFrame

        count = 0
        for row in eachrow(df)
            key = (string(row[1]), string(row[3]))
            fuels = get(reserve_fuels, key, default_fuel)

            for f in fuels
                SQLite.DBInterface.execute(destdb,
                    "INSERT OR IGNORE INTO ReserveMarginTagTechnology (r, t, f, y, val) VALUES (?, ?, ?, ?, ?)",
                    [row[1], row[2], f, row[3], row[4]])
                count += 1
            end
        end

        logmsg("Transformed ReserveMarginTagTechnology: $(size(df, 1)) rows -> $(count) rows.", quiet)
    end
end  # _transform_osemosys_reserve_margin!
# END: Reserve margin transformation.

# BEGIN: RE target transformation.
function _transform_osemosys_re_targets!(srcdb::SQLite.DB, destdb::SQLite.DB,
    src_tables::Vector{String}, quiet::Bool)

    # OSeMOSYS REMinProductionTarget [REGION, YEAR] -> NemoMod [r, f, y]
    # OSeMOSYS RETagFuel [REGION, FUEL, YEAR] identifies which fuels count as renewable

    # Get RE-tagged fuels
    re_fuels = Dict{Tuple{String,String}, Vector{String}}()  # (region, year) -> [fuels]

    rtf_name = _osemosys_table_name(src_tables, "RETagFuel")
    if !isnothing(rtf_name)
        cols = _get_column_names(srcdb, rtf_name)
        rc = _resolve_column(cols, "REGION"); fc = _resolve_column(cols, "FUEL")
        yc = _resolve_column(cols, "YEAR"); vc = _resolve_column(cols, "VALUE")

        df = SQLite.DBInterface.execute(srcdb,
            "SELECT $(_quote_id(rc)), $(_quote_id(fc)), $(_quote_id(yc)) FROM $(_quote_id(rtf_name)) WHERE $(_quote_id(vc)) = 1") |> DataFrame

        for row in eachrow(df)
            key = (string(row[1]), string(row[3]))
            if !haskey(re_fuels, key)
                re_fuels[key] = String[]
            end
            push!(re_fuels[key], string(row[2]))
        end
    end

    # Fallback
    all_fuels = _read_osemosys_set(srcdb, src_tables, "FUEL")

    if isempty(all_fuels) && isempty(re_fuels)
        logmsg("Warning: no fuels defined and no RETagFuel data; skipping RE target transformation.", quiet)
        return
    end

    default_fuel = isempty(all_fuels) ? String[] : [first(all_fuels)]

    # Transform REMinProductionTarget
    rmp_name = _osemosys_table_name(src_tables, "REMinProductionTarget")

    if !isnothing(rmp_name)
        cols = _get_column_names(srcdb, rmp_name)
        rc = _resolve_column(cols, "REGION"); yc = _resolve_column(cols, "YEAR")
        vc = _resolve_column(cols, "VALUE")

        df = SQLite.DBInterface.execute(srcdb,
            "SELECT $(_quote_id(rc)), $(_quote_id(yc)), $(_quote_id(vc)) FROM $(_quote_id(rmp_name))") |> DataFrame

        count = 0
        for row in eachrow(df)
            key = (string(row[1]), string(row[2]))
            fuels = get(re_fuels, key, default_fuel)

            for f in fuels
                SQLite.DBInterface.execute(destdb,
                    "INSERT OR IGNORE INTO REMinProductionTarget (r, f, y, val) VALUES (?, ?, ?, ?)",
                    [row[1], f, row[2], row[3]])
                count += 1
            end
        end

        logmsg("Transformed REMinProductionTarget: $(size(df, 1)) rows -> $(count) rows (with fuel dimension).", quiet)
    end
end  # _transform_osemosys_re_targets!
# END: RE target transformation.
