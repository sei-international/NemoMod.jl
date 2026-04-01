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
- A path to a directory of otoole CSV files. In this case, `config_path` must also be provided,
  and otoole must be installed and available on the system PATH. The CSV directory will be converted
  to a temporary SQLite database using `otoole convert csv sqlite` before proceeding.

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
  a CSV directory.
"""
function convert_osemosys(osemosys_path::String, nemo_path::String;
    defaults::Dict{String, Float64} = Dict{String, Float64}(),
    quiet::Bool = false,
    config_path::String = "")

    # Determine if osemosys_path is a directory (CSV) or file (SQLite)
    local sqlite_path::String = osemosys_path
    local temp_sqlite::Bool = false

    if isdir(osemosys_path)
        # CSV directory: convert to temporary SQLite using otoole
        isempty(config_path) && error("config_path is required when osemosys_path is a CSV directory.")
        !isfile(config_path) && error("Config file not found: $(config_path)")

        sqlite_path = tempname() * ".sqlite"
        temp_sqlite = true

        logmsg("Converting CSV directory to temporary SQLite using otoole...", quiet)

        local cmd = `otoole convert csv sqlite $(osemosys_path) $(sqlite_path) $(config_path)`

        try
            run(cmd)
        catch e
            rm(sqlite_path; force=true)
            error("Failed to run otoole. Ensure otoole is installed (pip install otoole) and on your PATH. Error: $(e)")
        end

        logmsg("otoole conversion complete: $(sqlite_path)", quiet)
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
    local destdb::SQLite.DB = createnemodb(nemo_path; defaultvals=defaults)
    logmsg("Created NemoMod database at $(nemo_path).", quiet)

    # Get list of tables in source database
    local src_tables::Vector{String} = [r[:name] for r in
        SQLite.DBInterface.execute(srcdb, "SELECT name FROM sqlite_master WHERE type='table'")]

    # BEGIN: Wrap all operations in try-catch for rollback on error.
    try
        SQLite.DBInterface.execute(destdb, "BEGIN")

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

        SQLite.DBInterface.execute(destdb, "COMMIT")
        logmsg("Conversion complete.", quiet)
    catch
        SQLite.DBInterface.execute(destdb, "ROLLBACK")
        rethrow()
    finally
        # Clean up temporary SQLite file if we created one from CSV
        if temp_sqlite
            # Close source database before deleting
            DBInterface.close!(srcdb)
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

    df::DataFrame = SQLite.DBInterface.execute(srcdb, "SELECT * FROM $(tname)") |> DataFrame

    if size(df, 1) == 0
        return String[]
    end

    # OSeMOSYS sets typically have a VALUE column
    if "VALUE" in names(df)
        return string.(df[!, :VALUE])
    elseif "value" in names(df)
        return string.(df[!, :value])
    elseif size(df, 2) == 1
        return string.(df[!, 1])
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
    return SQLite.DBInterface.execute(srcdb, "SELECT * FROM $(tname)") |> DataFrame
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
                df = SQLite.DBInterface.execute(srcdb,
                    "SELECT SUM(VALUE) as total FROM $(tname) WHERE SEASON = ?", [season]) |> DataFrame

                if size(df, 1) > 0 && !ismissing(df[1, :total])
                    # Days in season / 7 = number of weeks (repetitions)
                    multiplier = df[1, :total] / 7.0
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
            # Estimate multiplier (days per week for this day type)
            if length(daytypes) == 2
                # Common case: weekday/weekend
                multiplier = idx == 1 ? 5.0 : 2.0
            else
                multiplier = 7.0 / length(daytypes)
            end

            # Try to calculate from DaysInDayType for better accuracy
            if has_daysindaytype
                tname_did = _osemosys_table_name(src_tables, "DaysInDayType")
                df = SQLite.DBInterface.execute(srcdb,
                    """SELECT AVG(d.VALUE * 7.0 / st.season_total) as days_per_week
                       FROM $(tname_did) d
                       INNER JOIN (
                           SELECT SEASON, SUM(VALUE) as season_total
                           FROM $(tname_did)
                           GROUP BY SEASON
                       ) st ON d.SEASON = st.SEASON
                       WHERE d.DAYTYPE = ?""", [daytype]) |> DataFrame

                if size(df, 1) > 0 && !ismissing(df[1, :days_per_week])
                    multiplier = df[1, :days_per_week]
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
            df = SQLite.DBInterface.execute(srcdb,
                "SELECT SEASON FROM $(tname) WHERE TIMESLICE = ? AND VALUE = 1", [ts]) |> DataFrame

            if size(df, 1) > 0
                tg1 = string(df[1, :SEASON])
            end
        end

        # Find day type (tg2) via Conversionld
        tg2 = "1"
        if has_conversionld
            tname = _osemosys_table_name(src_tables, "Conversionld")
            df = SQLite.DBInterface.execute(srcdb,
                "SELECT DAYTYPE FROM $(tname) WHERE TIMESLICE = ? AND VALUE = 1", [ts]) |> DataFrame

            if size(df, 1) > 0
                tg2 = string(df[1, :DAYTYPE])
            end
        end

        # Find daily time bracket (lorder) via Conversionlh
        lorder = 1
        if has_conversionlh
            tname = _osemosys_table_name(src_tables, "Conversionlh")
            df = SQLite.DBInterface.execute(srcdb,
                "SELECT DAILYTIMEBRACKET FROM $(tname) WHERE TIMESLICE = ? AND VALUE = 1", [ts]) |> DataFrame

            if size(df, 1) > 0
                parsed = tryparse(Int, string(df[1, :DAILYTIMEBRACKET]))
                !isnothing(parsed) && (lorder = parsed)
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

        src_cols = [m[1] for m in col_mapping]
        dest_cols = [m[2] for m in col_mapping]

        local df::DataFrame
        try
            df = SQLite.DBInterface.execute(srcdb,
                "SELECT $(join(src_cols, ", ")) FROM $(actual_name)") |> DataFrame
        catch e
            logmsg("Warning: could not read $(actual_name): $(e)", quiet)
            continue
        end

        size(df, 1) == 0 && continue

        placeholders = join(fill("?", length(dest_cols)), ", ")
        insert_sql = "INSERT OR IGNORE INTO $(dest_table) ($(join(dest_cols, ", "))) VALUES ($(placeholders))"

        for row in eachrow(df)
            SQLite.DBInterface.execute(destdb, insert_sql, [row[Symbol(c)] for c in src_cols])
        end

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
    local colinfo::DataFrame = SQLite.DBInterface.execute(srcdb,
        "PRAGMA table_info('$(actual_name)')") |> DataFrame

    colnames = colinfo[!, :name]

    # Find the two region columns and fuel/year/value columns
    region_cols = filter(c -> uppercase(c) == "REGION", colnames)

    # Some OSeMOSYS databases use REGION and rr or REGION2
    if length(region_cols) >= 2
        r_col = region_cols[1]
        rr_col = region_cols[2]
    elseif any(c -> uppercase(c) == "REGION", colnames) && any(c -> lowercase(c) == "rr", colnames)
        r_col = colnames[findfirst(c -> uppercase(c) == "REGION", colnames)]
        rr_col = colnames[findfirst(c -> lowercase(c) == "rr", colnames)]
    elseif any(c -> uppercase(c) == "REGION", colnames) && any(c -> uppercase(c) == "REGION2", colnames)
        r_col = colnames[findfirst(c -> uppercase(c) == "REGION", colnames)]
        rr_col = colnames[findfirst(c -> uppercase(c) == "REGION2", colnames)]
    else
        logmsg("Warning: could not determine TradeRoute region columns, skipping.", quiet)
        return
    end

    f_col = colnames[findfirst(c -> uppercase(c) == "FUEL", colnames)]
    y_col = colnames[findfirst(c -> uppercase(c) == "YEAR", colnames)]
    v_col = colnames[findfirst(c -> uppercase(c) == "VALUE", colnames)]

    df = SQLite.DBInterface.execute(srcdb,
        "SELECT $(r_col), $(rr_col), $(f_col), $(y_col), $(v_col) FROM $(actual_name)") |> DataFrame

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
        df = SQLite.DBInterface.execute(srcdb,
            "SELECT REGION, TECHNOLOGY, TIMESLICE, YEAR, VALUE FROM $(cf_name)") |> DataFrame

        for row in eachrow(df)
            SQLite.DBInterface.execute(destdb,
                "INSERT OR IGNORE INTO AvailabilityFactor (r, t, l, y, val) VALUES (?, ?, ?, ?, ?)",
                [row[:REGION], row[:TECHNOLOGY], row[:TIMESLICE], row[:YEAR], row[:VALUE]])
        end

        logmsg("Transformed $(size(df, 1)) rows from CapacityFactor to AvailabilityFactor.", quiet)
    end

    # OSeMOSYS AvailabilityFactor [REGION, TECHNOLOGY, YEAR] has no timeslice dimension.
    # Expand across all timeslices, but don't overwrite values from CapacityFactor.
    af_name = _osemosys_table_name(src_tables, "AvailabilityFactor")

    if !isnothing(af_name)
        df = SQLite.DBInterface.execute(srcdb,
            "SELECT REGION, TECHNOLOGY, YEAR, VALUE FROM $(af_name)") |> DataFrame

        if size(df, 1) > 0
            timeslices = _read_osemosys_set(srcdb, src_tables, "TIMESLICE")
            count = 0

            for row in eachrow(df)
                for l in timeslices
                    SQLite.DBInterface.execute(destdb,
                        "INSERT OR IGNORE INTO AvailabilityFactor (r, t, l, y, val) VALUES (?, ?, ?, ?, ?)",
                        [row[:REGION], row[:TECHNOLOGY], l, row[:YEAR], row[:VALUE]])
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
        df = SQLite.DBInterface.execute(srcdb,
            "SELECT REGION, FUEL, YEAR FROM $(rmtf_name) WHERE VALUE = 1") |> DataFrame

        for row in eachrow(df)
            key = (string(row[:REGION]), string(row[:YEAR]))
            if !haskey(reserve_fuels, key)
                reserve_fuels[key] = String[]
            end
            push!(reserve_fuels[key], string(row[:FUEL]))
        end
    end

    # Fallback fuel if no ReserveMarginTagFuel data
    all_fuels = _read_osemosys_set(srcdb, src_tables, "FUEL")
    default_fuel = isempty(all_fuels) ? "ELC" : first(all_fuels)

    # Transform ReserveMargin
    rm_name = _osemosys_table_name(src_tables, "ReserveMargin")

    if !isnothing(rm_name)
        df = SQLite.DBInterface.execute(srcdb,
            "SELECT REGION, YEAR, VALUE FROM $(rm_name)") |> DataFrame

        count = 0
        for row in eachrow(df)
            key = (string(row[:REGION]), string(row[:YEAR]))
            fuels = get(reserve_fuels, key, [default_fuel])

            for f in fuels
                SQLite.DBInterface.execute(destdb,
                    "INSERT OR IGNORE INTO ReserveMargin (r, f, y, val) VALUES (?, ?, ?, ?)",
                    [row[:REGION], f, row[:YEAR], row[:VALUE]])
                count += 1
            end
        end

        logmsg("Transformed ReserveMargin: $(size(df, 1)) rows -> $(count) rows (with fuel dimension).", quiet)
    end

    # Transform ReserveMarginTagTechnology
    rmtt_name = _osemosys_table_name(src_tables, "ReserveMarginTagTechnology")

    if !isnothing(rmtt_name)
        df = SQLite.DBInterface.execute(srcdb,
            "SELECT REGION, TECHNOLOGY, YEAR, VALUE FROM $(rmtt_name) WHERE VALUE > 0") |> DataFrame

        count = 0
        for row in eachrow(df)
            key = (string(row[:REGION]), string(row[:YEAR]))
            fuels = get(reserve_fuels, key, [default_fuel])

            for f in fuels
                SQLite.DBInterface.execute(destdb,
                    "INSERT OR IGNORE INTO ReserveMarginTagTechnology (r, t, f, y, val) VALUES (?, ?, ?, ?, ?)",
                    [row[:REGION], row[:TECHNOLOGY], f, row[:YEAR], row[:VALUE]])
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
        df = SQLite.DBInterface.execute(srcdb,
            "SELECT REGION, FUEL, YEAR FROM $(rtf_name) WHERE VALUE = 1") |> DataFrame

        for row in eachrow(df)
            key = (string(row[:REGION]), string(row[:YEAR]))
            if !haskey(re_fuels, key)
                re_fuels[key] = String[]
            end
            push!(re_fuels[key], string(row[:FUEL]))
        end
    end

    # Fallback
    all_fuels = _read_osemosys_set(srcdb, src_tables, "FUEL")
    default_fuel = isempty(all_fuels) ? "ELC" : first(all_fuels)

    # Transform REMinProductionTarget
    rmp_name = _osemosys_table_name(src_tables, "REMinProductionTarget")

    if !isnothing(rmp_name)
        df = SQLite.DBInterface.execute(srcdb,
            "SELECT REGION, YEAR, VALUE FROM $(rmp_name)") |> DataFrame

        count = 0
        for row in eachrow(df)
            key = (string(row[:REGION]), string(row[:YEAR]))
            fuels = get(re_fuels, key, [default_fuel])

            for f in fuels
                SQLite.DBInterface.execute(destdb,
                    "INSERT OR IGNORE INTO REMinProductionTarget (r, f, y, val) VALUES (?, ?, ?, ?)",
                    [row[:REGION], f, row[:YEAR], row[:VALUE]])
                count += 1
            end
        end

        logmsg("Transformed REMinProductionTarget: $(size(df, 1)) rows -> $(count) rows (with fuel dimension).", quiet)
    end
end  # _transform_osemosys_re_targets!
# END: RE target transformation.
