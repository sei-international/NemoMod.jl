#=
    NEMO: Next Energy Modeling system for Optimization.
    https://github.com/sei-international/NemoMod.jl

    Copyright © 2018: Stockholm Environment Institute U.S.

    File description: Other NEMO functions.
=#

"""
    logmsg(msg::String, suppress=false, dtm=now()::DateTime)

Prints a log message (`msg`) to `STDOUT`. The message is suppressed if `suppress == true`. `dtm`
determines the date and time included in the printed message.

# Examples
```jldoctest
julia> using Dates

julia> logmsg("Test message", false, DateTime(2020))
2020-01-Jan 00:00:00.000 Test message
```
"""
function logmsg(msg::String, suppress=false, dtm=now()::DateTime)
    suppress && return
    println(stdout, Dates.format(dtm, @dateformat_str "YYYY-dd-u HH:MM:SS.sss ") * msg)
end  # logmsg(msg::String)

"""
    getjumpmodelproperties(jumpmodel::JuMP.Model)

    Returns a `Tuple` of `Bool` indicating whether `jumpmodel`:
        1) In in direct mode;
        2) Has bridging enabled.
"""
function getjumpmodelproperties(jumpmodel::JuMP.Model)
    local jumpdirectmode::Bool = (mode(jumpmodel) == JuMP.DIRECT)  # Indicates whether jumpmodel is in direct mode
    local jumpbridges::Bool = (jumpdirectmode ? false : (typeof(backend(jumpmodel).optimizer) <: MathOptInterface.Bridges.LazyBridgeOptimizer))  # Indicates whether bridging is enabled in jumpmodel

    return (jumpdirectmode, jumpbridges)
end  # getjumpmodelproperties(jumpmodel::JuMP.Model)

"""
    check_calcyears(calcyears::Vector{Vector{Int}})

Throws an error if: 1) `calcyears` has more than one element, and one or more of them are empty; or 2) the vectors in `calcyears` overlap or are not in chronological order.
"""
function check_calcyears(calcyears::Vector{Vector{Int}})
    for i = 2:length(calcyears)
        if (i == 2 && length(calcyears[1]) == 0) || length(calcyears[i]) == 0
            error("If calcyears argument includes an empty vector/group of years (which means all years should be calculated), it must be only element in calcyears.")
        end

        for y in calcyears[i]
            y <= maximum(calcyears[i-1]) && error("If calcyears argument includes multiple vectors/groups of years, they must not overlap and must be in chronological order.")
        end
    end
end  # check_calcyears(calcyears::Vector{Vector{Int}})

"""
    filter_calcyears!(db::SQLite.DB, calcyears::Vector{Vector{Int}})

Removes elements from `calcyears` that do not contain any years in the `year` table of `db`.
"""
function filter_calcyears!(db::SQLite.DB, calcyears::Vector{Vector{Int}})
    local all_yrs::Vector{Int} = DataFrame(SQLite.DBInterface.execute(db, "select cast(val as int) as y from year"))[!,:y]  # All years in year table
    filter!(g -> !isdisjoint(g, all_yrs), calcyears)

    if length(calcyears) == 0
        push!(calcyears, Vector{Int}())
    end
end  # filter_calcyears!(db::SQLite.DB, calcyears::Vector{Vector{Int}})

"""
    reset_jumpmodel(jumpmodel::JuMP.Model; direct::Bool=false, bridges::Bool=true,
        quiet::Bool=false)

Returns a new `JuMP.Model` that's initialized with the same solver as `jumpmodel`, whose
use of JuMP's direct mode aligns with `direct`, and whose use of MathOptInterface
bridging aligns with `bridges`. Except for the choice of solver, other model attributes
and solver parameters defined for `jumpmodel` are not preserved in the return value.

# Arguments
- `jumpmodel::JuMP.Model`: Original `JuMP.Model`.
- `direct::Bool`: Indicates whether return value should be in JuMP's direct mode.
- `bridges::Bool`: Indicates whether return value should use MathOptInterface bridging.
    Ignored if `direct` is true.
- `quiet::Bool`: Suppresses low-priority status messages (which are otherwise printed to `STDOUT`).
"""
function reset_jumpmodel(jumpmodel::JuMP.Model; direct::Bool=false, bridges::Bool=true,
    quiet::Bool=false)

    local returnval::JuMP.Model = jumpmodel  # This function's return value

    if direct
        returnval = direct_model(typeof(unsafe_backend(jumpmodel))())
        logmsg("Converted model to use JuMP's direct mode.", quiet)
    else
        returnval = Model(typeof(unsafe_backend(jumpmodel)); add_bridges=bridges)
        logmsg("Converted model to use JuMP's automatic mode $(bridges ? "with" : "without") MathOptInterface bridging.", quiet)
    end

    return returnval
end  # reset_jumpmodel(jumpmodel::JuMP.Model; direct::Bool=false, bridges::Bool=false)

"""
    translatesetabb(a::String)

Translates a set abbreviation into the set's name.

# Examples
```jldoctest
julia> translatesetabb(y)
""YEAR""
```
"""
function translatesetabb(a::String)
    if a == "y"
        return "YEAR"
    elseif a == "t"
        return "TECHNOLOGY"
    elseif a == "f"
        return "FUEL"
    elseif a == "e"
        return "EMISSION"
    elseif a == "m"
        return "MODE_OF_OPERATION"
    elseif a == "r" || a == "rr"
        return "REGION"
    elseif a == "s"
        return "STORAGE"
    elseif a == "l"
        return "TIMESLICE"
    elseif a == "tg1"
        return "TSGROUP1"
    elseif a == "tg2"
        return "TSGROUP2"
    elseif a == "ls"
        return "SEASON"
    elseif a == "ld"
        return "DAYTYPE"
    elseif a == "lh"
        return "DAILYTIMEBRACKET"
    elseif a == "n" || a == "n1" || a == "n2"
        return "NODE"
    elseif a == "tr"
        return "TransmissionLine"
    elseif a == "rg"
        return "REGIONGROUP"
    else
        return a
    end
end  # translatesetabb(a::String)

"""
    keydicts(df::DataFrames.DataFrame, cols::Array{Int, 1})

Generates `Dicts` that can be used to restrict JuMP constraints or variables to selected indices
(rather than all values in their dimensions) at creation. Returns an array of the generated `Dicts`.

# Arguments
- `df::DataFrames.DataFrame`: The results of a query that selects the index values.
- `cols::Array{Int, 1}`: An array of column numbers in the query that identifies the fields included in the `Dicts`.
    `length(cols) - 1` `Dicts` are created in total. Their keys are arrays of the values of key fields,
    and their values are `Sets` of corresponding values in a single value field (all values are taken from `df`).
    Key and value fields are assigned as follows:
        > `Dict` 1: key field = first field in `cols`, value field = second field in `cols`
        > `Dict` 2: key fields = first two fields in `cols`, value field = third field in `cols`
        ...
"""
function keydicts(df::DataFrames.DataFrame, cols::Array{Int, 1})
    local returnval = Array{Dict{Array{String,1},Set{String}},1}()  # Function's return value
    local dictlength::Int = length(cols)-1  # Number of dictionaries in return value
    local prealloc_cols_dict = Dict{Int, Array{Int, 1}}()  # Dictionary mapping dictionary number in return value to slice of cols identifying columns in return value dictionary's keys; defined outside row loop below to increase memory efficiency

    # Set up empty dictionaries in returnval and populate prealloc_cols_dict
    for i in 1:dictlength
        push!(returnval, Dict{Array{String,1},Set{String}}())
        prealloc_cols_dict[i] = cols[1:i]
    end

    # Populate dictionaries using df
    for row in DataFrames.eachrow(df)
        for j in 1:dictlength
            if !haskey(returnval[j], [row[k] for k in prealloc_cols_dict[j]])
                returnval[j][[row[k] for k in prealloc_cols_dict[j]]] = Set{String}()
            end

            push!(returnval[j][[row[k] for k in prealloc_cols_dict[j]]], row[cols[j+1]])
        end
    end

    return returnval
end  # keydicts(df::DataFrames.DataFrame, cols::Array{Int, 1})

"""
    keydicts(df::DataFrames.DataFrame, numdicts::Int)

Generates `Dicts` that can be used to restrict JuMP constraints or variables to selected indices
(rather than all values in their dimensions) at creation. Returns an array of the generated `Dicts`.

# Arguments
- `df::DataFrames.DataFrame`: The results of a query that selects the index values.
- `numdicts::Int`: The number of `Dicts` that should be created.  The first `Dict` is for the first field in
        the query, the second is for the first two fields in the query, and so on.  `Dict` keys are arrays
        of the values of the key fields to which the `Dict` corresponds, and `Dict` values are `Sets` of corresponding
        values in the next field of the query (field #2 for the first `Dict`, field #3 for the second `Dict`, and so on).
"""
function keydicts(df::DataFrames.DataFrame, numdicts::Int)
    return keydicts(df, [i for i=1:numdicts+1])
    
    #= local returnval = Array{Dict{Array{String,1},Set{String}},1}()  # Function return value

    # Set up empty dictionaries in returnval
    for i in 1:numdicts
        push!(returnval, Dict{Array{String,1},Set{String}}())
    end

    # Populate dictionaries using df
    for row in DataFrames.eachrow(df)
        for j in 1:numdicts
            if !haskey(returnval[j], [row[k] for k = 1:j])
                returnval[j][[row[k] for k = 1:j]] = Set{String}()
            end

            push!(returnval[j][[row[k] for k = 1:j]], row[j+1])
        end
    end

    return returnval =#
end  # keydicts(df::DataFrames.DataFrame, numdicts::Int)

"""
    keydicts_threaded(df::DataFrames.DataFrame, cols::Array{Int, 1})

Runs `keydicts` on multiple threads. Uses one thread per 10,000 rows in `df`,
subject to an overall limit of `Threads.nthreads()`.
"""
function keydicts_threaded(df::DataFrames.DataFrame, cols::Array{Int, 1})
    local returnval = Array{Dict{Array{String,1},Set{String}},1}()  # Function return value
    local dfrows::Int = size(df)[1]  # Number of rows in df
    local nt::Int = min(Threads.nthreads(), div(dfrows-1, 10000) + 1)  # Number of threads on which keydicts will be run

    if nt == 1
        # Run keydicts for entire df
        returnval = keydicts(df, cols)
    else
        # Divide operation among multiple threads
        local blockdivrem = divrem(dfrows, nt)  # Quotient and remainder from dividing dfrows by nt; element 1 = quotient, element 2 = remainder
        local results = Array{typeof(returnval), 1}(undef, nt)  # Collection of results from threaded processing

        # Threads.@threads waits for all tasks to finish before proceeding
        Threads.@threads for p=1:nt
            # @info "calling keydicts for p=$p, df rows from $((p-1) * blockdivrem[1] + 1) to $((p) * blockdivrem[1] + (p == nt ? blockdivrem[2] : 0))"
            results[p] = keydicts(deepcopy(df[((p-1) * blockdivrem[1] + 1):((p) * blockdivrem[1] + (p == nt ? blockdivrem[2] : 0)),:]), cols)
            # @info "finished keydicts for p=$p"
        end

        #= @sync(begin
            for p in 1:nt
                Threads.@spawn(begin
                    local r = keydicts($(df[((p-1) * blockdivrem[1] + 1):((p) * blockdivrem[1] + (p == nt ? blockdivrem[2] : 0)),:]), $numdicts)

                    lock(lck) do
                        push!(results, r)
                    end
                end)
            end
        end) =#

        # Merge results from threaded tasks
        for i = 1:length(cols)-1
            push!(returnval, Dict{Array{String,1},Set{String}}())

            for j = 1:nt
                returnval[i] = merge(union, returnval[i], results[j][i])
            end
        end
    end

    return returnval
end  # keydicts_threaded(df::DataFrames.DataFrame, cols::Array{Int, 1})

"""
    keydicts_threaded(df::DataFrames.DataFrame, numdicts::Int)

Runs `keydicts` on multiple threads. Uses one thread per 10,000 rows in `df`,
subject to an overall limit of `Threads.nthreads()`.
"""
function keydicts_threaded(df::DataFrames.DataFrame, numdicts::Int)
    return keydicts_threaded(df, [i for i=1:numdicts+1])
end  # keydicts_threaded(df::DataFrames.DataFrame, numdicts::Int)

"""
    createconstraints(jumpmodel::JuMP.Model, cons::Array{AbstractConstraint, 1})

Adds the constraints in `cons` to `jumpmodel` using `JuMP.add_constraint()`.
"""
function createconstraints(jumpmodel::JuMP.Model, cons::Array{AbstractConstraint, 1})
    for c in cons
        add_constraint(jumpmodel, c)
    end
end  # createconstraints(jumpmodel::JuMP.Model, cons::Array{AbstractConstraint, 1})

"""
    savevarresults_threaded(vars::Array{String,1},
    modelvarindices::Dict{String, Tuple{AbstractArray,Array{String,1}}},
    db::SQLite.DB, solvedtmstr::String, reportzeros::Bool = false, quiet::Bool = false)

Saves model results to a SQLite database using SQL inserts with transaction batching. Uses all available threads
when reading results from memory.

# Arguments
- `vars::Array{String,1}`: Names of model variables for which results will be retrieved and saved to database.
- `modelvarindices::Dict{String, Tuple{AbstractArray,Array{String,1}}}`: Dictionary mapping model variable names
    to tuples of (variable, [index column names]).
- `db::SQLite.DB`: SQLite database.
- `solvedtmstr::String`: String to write into solvedtm field in result tables.
- `reportzeros::Bool`: Indicates whether values equal to 0 should be saved.
- `quiet::Bool = false`: Suppresses low-priority status messages (which are otherwise printed to STDOUT).
"""
function savevarresults_threaded(vars::Array{String,1}, modelvarindices::Dict{String, Tuple{AbstractArray,Array{String,1}}}, db::SQLite.DB, solvedtmstr::String,
    reportzeros::Bool = false, quiet::Bool = false)

    local nt = Threads.nthreads()  # Number of threads used in this function

    for vname in intersect(vars, keys(modelvarindices))
        local v = modelvarindices[vname][1]  # Model variable corresponding to vname (technically, a variable container in JuMP)
        local allindices = Array{Tuple, 1}()  # Array of tuples of all index values for v
        local allvarrefs = Array{VariableRef, 1}()  # Array of all variable references contained in v

        local indices = Array{Array{Tuple}, 1}(undef, nt)  # Mutually exclusive arrays of tuples of index values for v; one array assigned to and processed by each thread
        local vals = Array{Array{Float64}, 1}(undef, nt)  # Mutually exclusive arrays of model results for v; one array populated by each thread

        # BEGIN: Populate allindices and allvarrefs.
        if v isa JuMP.Containers.DenseAxisArray
            for e in Base.product(axes(v)...)  # Ellipsis splats axes into their values for passing to product()
                push!(allindices, e)
            end

            # Preceding product and v.data are in same order
            for e in v.data
                push!(allvarrefs, e)
            end
        elseif v isa JuMP.Containers.SparseAxisArray
            # Again, allindices and allvarrefs are in same order
            allindices = collect(keys(v.data))
            allvarrefs = collect(values(v.data))
        end
        # END: Populate allindices and allvarrefs.

        # BEGIN: Read variable (result) values and populate indices and vals.
        local blockdivrem = divrem(length(allindices), nt)  # Quotient and remainder from dividing length(allindices) by nt; element 1 = quotient, element 2 = remainder

        # Threads.@threads waits for all tasks to finish before proceeding
        Threads.@threads for t=1:nt
            local ind1 = ((t-1) * blockdivrem[1] + 1)  # First index in allindices and allvarrefs assigned to this thread
            local ind2 = ((t) * blockdivrem[1] + (t == nt ? blockdivrem[2] : 0))  # Last index in allindices and allvarrefs assigned to this thread

            indices[t] = allindices[ind1:ind2]
            vals[t] = Array{Float64, 1}()

            for vr in allvarrefs[ind1:ind2]
                push!(vals[t], value(vr))
            end
        end
        # END: Read variable (result) values and populate indices and vals.

        # BEGIN: Wrap database operations in try-catch block to allow rollback on error.
        try
            # Begin SQLite transaction
            SQLite.DBInterface.execute(db, "BEGIN")

            # Create target table for v (drop any existing table for v)
            if !in("y", modelvarindices[vname][2])
                # Replace pre-existing result tables that are not year-specific
                SQLite.DBInterface.execute(db,"drop table if exists " * vname)
            end

            SQLite.DBInterface.execute(db, "create table if not exists '" * vname * "' ('" * join(modelvarindices[vname][2], "' text, '") * "' text, 'val' real, 'solvedtm' text)")

            # Insert data from indices and vals
            for t=1:nt
                for i in 1:length(indices[t])
                    if reportzeros || vals[t][i] != 0.0
                        SQLite.DBInterface.execute(db, "insert into " * vname * " values('" * join(indices[t][i], "', '") * "', '" * string(vals[t][i]) * "', '" * solvedtmstr * "')")
                    end
                end
            end

            # Complete SQLite transaction
            SQLite.DBInterface.execute(db, "COMMIT")
            logmsg("Saved results for " * vname * " to database.", quiet)
        catch
            # Rollback db transaction
            SQLite.DBInterface.execute(db, "ROLLBACK")

            # Proceed with normal Julia error sequence
            rethrow()
        end
        # END: Wrap database operations in try-catch block to allow rollback on error.
    end
end  # savevarresults_threaded(vars::Array{String,1}, modelvarindices::Dict{String, Tuple{AbstractArray,Array{String,1}}}, db::SQLite.DB, solvedtmstr::String)

#= Single-threaded version of savevarresults
function savevarresults(vars::Array{String,1}, modelvarindices::Dict{String, Tuple{AbstractArray,Array{String,1}}}, db::SQLite.DB, solvedtmstr::String,
    reportzeros::Bool = false, quiet::Bool = false)
    for vname in intersect(vars, keys(modelvarindices))
        local v = modelvarindices[vname][1]  # Model variable corresponding to vname (technically, a variable container in JuMP)
        local gvv = value.(v)  # Value of v in model solution
        local indices::Array{Tuple}  # Array of tuples of index values for v
        local vals::Array{Float64}  # Array of model results for v

        # Populate indices and vals
        if v isa JuMP.Containers.DenseAxisArray
            # In this case, indices and vals are parallel multidimensional arrays
            indices = collect(Base.product(gvv.axes...))  # Ellipsis splats axes into its values for passing to product()
            vals = gvv.data
        elseif v isa JuMP.Containers.SparseAxisArray
            # In this case, indices and vals are vectors
            indices = collect(keys(gvv.data))
            vals = collect(values(gvv.data))
        end

        # BEGIN: Wrap database operations in try-catch block to allow rollback on error.
        try
            # Begin SQLite transaction
            SQLite.DBInterface.execute(db, "BEGIN")

            # Create target table for v (drop any existing table for v)
            SQLite.DBInterface.execute(db,"drop table if exists " * vname)

            SQLite.DBInterface.execute(db, "create table '" * vname * "' ('" * join(modelvarindices[vname][2], "' text, '") * "' text, 'val' real, 'solvedtm' text)")

            # Insert data from gvv
            for i in eachindex(indices)
                if reportzeros || vals[i] != 0.0
                    SQLite.DBInterface.execute(db, "insert into " * vname * " values('" * join(indices[i], "', '") * "', '" * string(vals[i]) * "', '" * solvedtmstr * "')")
                end
            end

            # Complete SQLite transaction
            SQLite.DBInterface.execute(db, "COMMIT")
            logmsg("Saved results for " * vname * " to database.", quiet)
        catch
            # Rollback db transaction
            SQLite.DBInterface.execute(db, "ROLLBACK")

            # Proceed with normal Julia error sequence
            rethrow()
        end
        # END: Wrap database operations in try-catch block to allow rollback on error.
    end
end  # savevarresults(vars::Array{String,1}, modelvarindices::Dict{String, Tuple{AbstractArray,Array{String,1}}}, db::SQLite.DB, solvedtmstr::String) =#

"""
    setstartvalues(jumpmodel::JuMP.Model,
        seeddbpath::String,
        quiet::Bool = false;
        selectedvars::Array{String,1} = Array{String,1}()
    )

Sets starting values for variables in `jumpmodel` using results saved in a previously calculated
scenario database.

# Arguments

- `jumpmodel::JuMP.Model`: Model in which to set starting values for variables.
- `seeddbpath::String`: Path to previously calculated scenario database. Results in this
    database are used as starting values for matching variables in `jumpmodel`.
- `quiet::Bool = false`: Suppresses low-priority status messages (which are otherwise printed to STDOUT).
- `selectedvars::Array{String,1}`: Array of names of variables for which starting values should
    be set. If this argument is an empty array, starting values are set for all variables present
    in both `jumpmodel` and the previously calculated scenario database.
"""
function setstartvalues(jumpmodel::JuMP.Model, seeddbpath::String, quiet::Bool = false; selectedvars::Array{String,1} = Array{String,1}())
    # BEGIN: Validate seeddbpath and connect to seed DB.
    if !isfile(seeddbpath)
        logmsg("Could not set variable start values: no file found at $seeddbpath. Continuing with NEMO.")
        return
    end

    seeddb::SQLite.DB = SQLite.DB()

    try
        seeddb = SQLite.DB(seeddbpath)
        SQLite.DBInterface.execute(seeddb, "select 1 from sqlite_master limit 1")  # Verify connectivity
    catch
        logmsg("Could not set variable start values: no scenario database found at $seeddbpath. Continuing with NEMO.")
        return
    end
    # END: Validate seeddbpath and connect to seed DB.

    # BEGIN: Process selected result tables and set start values in jumpmodel.
    for smrow in SQLite.DBInterface.execute(seeddb, "select name from sqlite_master where type = 'table' and name like 'v%'
        $(length(selectedvars) > 0 ? " and name in ('" * join(selectedvars, "','") * "')" : "")")

        local tname = smrow[:name]  # Name of table being processed
        local selectfields::Array{String,1} = Array{String,1}()  # Names of fields to select from table being processed, excluding val
        local excludefields::Array{String,1} = ["solvedtm", "val"]  # Fields that are not added to selectfields in following loop
        local containsvalcol::Bool = false  # Indicates whether table being processed contains a val column

        # Build selectfields
        for row in SQLite.DBInterface.execute(seeddb, "pragma table_info('$tname')")
            if !in(row[:name], excludefields)
                push!(selectfields, row[:name])
            elseif row[:name] == "val"
                containsvalcol = true
            end
        end

        # Skip table if it does not contain a val column
        !containsvalcol && continue

        # Set start values for variables existing in jumpmodel and seeddb
        for row in SQLite.DBInterface.execute(seeddb, "select $(join(selectfields,",")), val from $tname")
            local var = variable_by_name(jumpmodel, "$tname[$(join([row[Symbol(f)] for f in selectfields], ","))]")

            !isnothing(var) && set_start_value(var, row[:val])
        end
    end  # smrow
    # END: Process selected result tables and set start values in jumpmodel.

    logmsg("Set variable start values using values in $(normpath(seeddbpath)).", quiet)
end  # setstartvalues(jumpmodel::JuMP.Model, seeddbpath::String, quiet::Bool = false; selectedvars::Array{String,1} = Array{String,1}())

"""
    convertscenariounits(
        path::String; 
        energy_multiplier::Float64 = 1.0, 
        power_multiplier::Float64 = 1.0, 
        cost_multiplier::Float64 = 1.0, 
        emissions_multiplier::Float64 = 1.0, 
        quiet::Bool = false
    )

Converts units of measure in the scenario database at `path`. Quantities denominated in energy units are
multiplied by `energy_multiplier`, quantities denominated in power units are multiplied by `power_multiplier`, 
quantities denominated in cost units are multiplied by `cost_multiplier`, and quantities denominated in 
emissions units are multiplied by `emissions_multiplier`. The `quiet` argument suppresses non-essential status 
messages.

This function assumes that consistent energy and power units are used across regions, and it converts both
parameter and variable tables. It also converts default values in the `DefaultParams` table.
"""
function convertscenariounits(path::String; energy_multiplier::Float64 = 1.0, power_multiplier::Float64 = 1.0, 
    cost_multiplier::Float64 = 1.0, emissions_multiplier::Float64 = 1.0, quiet::Bool = false)

    # Open SQLite database
    local db::SQLite.DB = SQLite.DB(path)
    logmsg("Opened database at $(path).", quiet)

    # BEGIN: Define arrays of tables requiring simple unit conversions.
    energy_tables::Array{String, 1} = ["AccumulatedAnnualDemand", "MaxAnnualTransmissionNodes", "MinAnnualTransmissionNodes", "ResidualStorageCapacity", "SpecifiedAnnualDemand", "StorageMaxChargeRate", "StorageMaxDischargeRate", "TotalAnnualMaxCapacityStorage", "TotalAnnualMaxCapacityInvestmentStorage", "TotalAnnualMinCapacityStorage", "TotalAnnualMinCapacityInvestmentStorage", "TotalTechnologyAnnualActivityLowerLimit", "TotalTechnologyAnnualActivityUpperLimit", "TotalTechnologyModelPeriodActivityLowerLimit", "TotalTechnologyModelPeriodActivityUpperLimit", "TransmissionCapacityToActivityUnit", "vaccumulatednewstoragecapacity", "vdemandannualnn", "vdemandannualnodal", "vdemandnn", "vdemandnodal", "vgenerationannualnn", "vgenerationannualnodal", "vnewstoragecapacity", "vproductionannualnn", "vproductionannualnodal", "vproductionbytechnology", "vproductionnn", "vproductionnodal", "vrateofactivity", "vrateofactivitynodal", "vrateofdemandnn", "vrateofproduction", "vrateofproductionbytechnologybymodenn", "vrateofproductionbytechnologynn", "vrateofproductionbytechnologynn", "vrateofproductionbytechnologynodal", "vrateofproductionnn", "vrateofproductionnodal", "vrateofstoragechargenn", "vrateofstoragechargenodal", "vrateofstoragedischargenn", "vrateofstoragedischargenodal", "vrateoftotalactivity", "vrateoftotalactivitynodal", "vrateofuse", "vrateofusebytechnologybymodenn", "vrateofusebytechnologynn", "vrateofusebytechnologynodal", "vrateofusenn", "vrateofusenodal", "vregenerationannualnn", "vregenerationannualnodal", "vstorageleveltsendnn", "vstorageleveltsendnodal", "vstorageleveltsgroup1endnn", "vstorageleveltsgroup1endnodal", "vstorageleveltsgroup1startnn", "vstorageleveltsgroup1startnodal", "vstorageleveltsgroup2endnn", "vstorageleveltsgroup2endnodal", "vstorageleveltsgroup2startnn", "vstorageleveltsgroup2startnodal", "vstoragelevelyearendnn", "vstoragelevelyearendnodal", "vstoragelowerlimit", "vstorageupperlimit", "vtotalcapacityinreservemargin", "vtotaltechnologyannualactivity", "vtotaltechnologyannualactivity", "vtotaltechnologymodelperiodactivity", "vtrade", "vtradeannual", "vtransmissionannual", "vtransmissionenergyreceived", "vtransmissionlosses", "vuseannualnn", "vuseannualnodal", "vusebytechnology", "vusebytechnologyannual", "vusenn", "vusenodal"]  # Tables with values in energy unit
    power_tables::Array{String, 1} = ["CapacityOfOneTechnologyUnit", "ResidualCapacity", "TotalAnnualMaxCapacity", "TotalAnnualMaxCapacityInvestment", "TotalAnnualMinCapacity", "TotalAnnualMinCapacityInvestment", "vaccumulatednewcapacity", "vnewcapacity", "vtotalcapacityannual"]  # Tables with values in power unit
    emissions_tables::Array{String, 1} = ["AnnualEmissionLimit", "AnnualExogenousEmission", "ModelPeriodEmissionLimit", "ModelPeriodExogenousEmission", "vannualemissions", "vannualtechnologyemission", "vannualtechnologyemissionbymode", "vmodelperiodemissions"]  # Tables with values in emissions unit
    cost_tables::Array{String, 1} = ["vannualfixedoperatingcost", "vannualtechnologyemissionpenaltybyemission", "vannualtechnologyemissionspenalty", "vannualvariableoperatingcost", "vcapitalinvestment", "vcapitalinvestmentstorage", "vcapitalinvestmenttransmission", "vdiscountedcapitalinvestment", "vdiscountedcapitalinvestmentstorage", "vdiscountedcapitalinvestmenttransmission", "vdiscountedoperatingcost", "vdiscountedoperatingcosttransmission", "vdiscountedsalvagevalue", "vdiscountedsalvagevaluestorage", "vdiscountedsalvagevaluetransmission", "vdiscountedtechnologyemissionspenalty", "vfinancecost", "vfinancecoststorage", "vfinancecosttransmission", "vmodelperiodcostbyregion", "voperatingcost", "voperatingcosttransmission", "vsalvagevalue", "vsalvagevaluestorage", "vsalvagevaluetransmission", "vtotaldiscountedcost", "vtotaldiscountedcostbytechnology", "vtotaldiscountedstoragecost", "vtotaldiscountedtransmissioncostbyregion", "vvariablecosttransmission", "vvariablecosttransmissionbyts"]  # Tables with values in cost unit
    # END: Define arrays of tables requiring simple unit conversions.

    # BEGIN: Wrap database operations in try-catch block to allow rollback on error.
    try
        # BEGIN: SQLite transaction.
        SQLite.DBInterface.execute(db, "BEGIN")

        # BEGIN: Process tables requiring simple unit conversions.
        # Restrict operations to existing tables to avoid database version issues
        for r in SQLite.DBInterface.execute(db,"select tbl_name from sqlite_master where type ='table' and name in (" * "'" * join(energy_tables, "','") * "'" * ")")
            SQLite.DBInterface.execute(db, "update $(r[:tbl_name]) set val = val * $(string(energy_multiplier))")
            SQLite.DBInterface.execute(db, "update DefaultParams set val = val * $(string(energy_multiplier)) where tablename = '$(r[:tbl_name])'")
        end

        for r in SQLite.DBInterface.execute(db,"select tbl_name from sqlite_master where type ='table' and name in (" * "'" * join(power_tables, "','") * "'" * ")")
            SQLite.DBInterface.execute(db, "update $(r[:tbl_name]) set val = val * $(string(power_multiplier))")
            SQLite.DBInterface.execute(db, "update DefaultParams set val = val * $(string(power_multiplier)) where tablename = '$(r[:tbl_name])'")
        end

        for r in SQLite.DBInterface.execute(db,"select tbl_name from sqlite_master where type ='table' and name in (" * "'" * join(emissions_tables, "','") * "'" * ")")
            SQLite.DBInterface.execute(db, "update $(r[:tbl_name]) set val = val * $(string(emissions_multiplier))")
            SQLite.DBInterface.execute(db, "update DefaultParams set val = val * $(string(emissions_multiplier)) where tablename = '$(r[:tbl_name])'")
        end

        for r in SQLite.DBInterface.execute(db,"select tbl_name from sqlite_master where type ='table' and name in (" * "'" * join(cost_tables, "','") * "'" * ")")
            SQLite.DBInterface.execute(db, "update $(r[:tbl_name]) set val = val * $(string(cost_multiplier))")
            SQLite.DBInterface.execute(db, "update DefaultParams set val = val * $(string(cost_multiplier)) where tablename = '$(r[:tbl_name])'")
        end
        # END: Process tables requiring simple unit conversions.

        # BEGIN: Process tables requiring complex unit conversions.
        # CapacityToActivityUnit: energy / (power * year)
        if !SQLite.done(SQLite.DBInterface.execute(db, "select tbl_name from sqlite_master where type ='table' and name = 'CapacityToActivityUnit'"))
            SQLite.DBInterface.execute(db, "update CapacityToActivityUnit set val = val * $(string(energy_multiplier / power_multiplier))")
            SQLite.DBInterface.execute(db, "update DefaultParams set val = val * $(string(energy_multiplier / power_multiplier)) where tablename = 'CapacityToActivityUnit'")
        end

        # CapitalCost and FixedCost: cost/power
        for r in SQLite.DBInterface.execute(db,"select tbl_name from sqlite_master where type ='table' and name in ('CapitalCost', 'FixedCost')")
            SQLite.DBInterface.execute(db, "update $(r[:tbl_name]) set val = val * $(string(cost_multiplier / power_multiplier))")
            SQLite.DBInterface.execute(db, "update DefaultParams set val = val * $(string(cost_multiplier / power_multiplier)) where tablename = '$(r[:tbl_name])'")
        end

        # CapitalCostStorage and VariableCost: cost/energy
        for r in SQLite.DBInterface.execute(db,"select tbl_name from sqlite_master where type ='table' and name in ('CapitalCostStorage', 'VariableCost')")
            SQLite.DBInterface.execute(db, "update $(r[:tbl_name]) set val = val * $(string(cost_multiplier / energy_multiplier))")
            SQLite.DBInterface.execute(db, "update DefaultParams set val = val * $(string(cost_multiplier / energy_multiplier)) where tablename = '$(r[:tbl_name])'")
        end

        # EmissionActivityRatio: emissions/energy
        if !SQLite.done(SQLite.DBInterface.execute(db, "select tbl_name from sqlite_master where type ='table' and name = 'EmissionActivityRatio'"))
            SQLite.DBInterface.execute(db, "update EmissionActivityRatio set val = val * $(string(emissions_multiplier / energy_multiplier))")
            SQLite.DBInterface.execute(db, "update DefaultParams set val = val * $(string(emissions_multiplier / energy_multiplier)) where tablename = 'EmissionActivityRatio'")
        end

        # EmissionsPenalty: cost/emissions
        if !SQLite.done(SQLite.DBInterface.execute(db, "select tbl_name from sqlite_master where type ='table' and name = 'EmissionsPenalty'"))
            SQLite.DBInterface.execute(db, "update EmissionsPenalty set val = val * $(string(cost_multiplier / emissions_multiplier))")
            SQLite.DBInterface.execute(db, "update DefaultParams set val = val * $(string(cost_multiplier / emissions_multiplier)) where tablename = 'EmissionsPenalty'")
        end
        # END: Process tables requiring complex unit conversions.

        SQLite.DBInterface.execute(db, "COMMIT")
        # END: SQLite transaction.

        logmsg("Converted units in database at $(path).", quiet)
    catch
        # Rollback transaction and rethrow error
        SQLite.DBInterface.execute(db, "ROLLBACK")
        rethrow()
    end
    # END: Wrap database operations in try-catch block to allow rollback on error.
end  # convertscenariounits(path::String; energy_multiplier::Float64 = 1.0, power_multiplier::Float64 = 1.0, cost_multiplier::Float64 = 1.0, emissions_multiplier::Float64 = 1.0, quiet::Bool = false)

"""
    find_infeasibilities(m::JuMP.Model,
        silent_solver::Bool=false
    )

Returns a `Vector` of constraint data for constraints in `m` that cause infeasibility.
`silent_solver` suppresses output from the solver for `m`.

# Arguments

- `m::JuMP.Model`: Model to check for infeasibility. Should be a NEMO model created with
    `calculatescenario`.
- `silent_solver::Bool = false`: Suppresses output from the solver for `m`.
"""
function find_infeasibilities(m::JuMP.Model, silent_solver::Bool=false)
    # Declare set of termination status that are considered infeasible
    local infeasible_statuses::Vector{MOI.TerminationStatusCode} = [MOI.INFEASIBLE, MOI.INFEASIBLE_OR_UNBOUNDED, MOI.DUAL_INFEASIBLE, MOI.LOCALLY_INFEASIBLE]

    # BEGIN: Record model's silent attribute and set_silent if silent_sover is true.
    local m_original_silent::Bool = get_attribute(m, MOI.Silent())  # Model's silent attribute when this function was called
    !m_original_silent && silent_solver && set_silent(m)
    # END: Record model's silent attribute and set_silent if silent_sover is true.

    # BEGIN: Check whether m is infeasible.
    @info "Verifying that model is infeasible."

    optimize!(m)

    if !in(termination_status(m), infeasible_statuses)
        @warn "Model is not infeasible. Exiting..."
        !m_original_silent && silent_solver && unset_silent(m)
        return []
    end
    # END: Check whether m is infeasible.

    # BEGIN: Declare additional top-level variables.
    m_total_num_constraints::Int = lastindex(all_constraints(m; include_variable_in_set_constraints=false))  # Total number of constraints originally in m (excluding variable bounds); some constraints may be transferred to constraint_reserve in operations below
    @info "Model contains $(m_total_num_constraints) constraints that will be evaluated for infeasibilities."

    constraint_reserve = []  # Array of constraints that have been temporarily removed from m (populated with constraint data, not ConstraintRef)
    last_ts::MOI.TerminationStatusCode = termination_status(m)  # Termination status from last optimization of m
    last_known_good_ci::Int = 0  # Highest-known constraint index that doesn't lead to infeasibility (i.e., m can be optimized with all constraints originally in m from 1 to last_known_good_ci)
    last_known_inf_ci::Int = m_total_num_constraints  # Highest-known constraint index that leads to infeasibility (i.e., m is infeasible when optimized with all constraints originally in m from 1 to last_known_inf_ci)
    last_ci_in_m::Int = last_known_inf_ci  # Highest constraint index currently in m
    num_cons_to_move::Int = 0  # Number of constraints that will be moved between m and constraint_reserve in next move
    search_complete::Bool = false  # Indicates whether search for infeasibility-causing constraints is complete
    infeasible_constraints = []  # Return value - constraints that cause infeasibility (populated with constraint data, not ConstraintRef)
    # END: Declare additional top-level variables.

    # BEGIN: Change bounds for vtotaldiscountedcost so it's >= 0.
    @info "Changing bounds for vtotaldiscountedcost."

    for vtdc in filter(v -> first(name(v), 21) == "vtotaldiscountedcost[", all_variables(m))
        set_lower_bound(vtdc, 0)
    end
    # END: Change bounds for vtotaldiscountedcost so it's >= 0.

    @info "Beginning infeasibility search."

    while !search_complete
        # BEGIN: Remove constraints from m/add constraints to m until a constraint causing infeasibility is identified.
        while last_known_inf_ci != last_known_good_ci + 1
            num_cons_to_move = ceil(Int, (last_known_inf_ci-last_known_good_ci)/2)  # Number of constraints that will be moved between m and constraint_reserve
    
            if in(last_ts, infeasible_statuses)
                # Remove constraints from m to try to find a feasible point
                remove_constraints!(m, num_cons_to_move, constraint_reserve)
                @info "Temporarily removed $(num_cons_to_move) constraints from model."
                last_ci_in_m = last_ci_in_m - num_cons_to_move
            elseif last_ts == MOI.OPTIMAL
                # Add constraints to m to try to find an infeasible point
                add_constraints!(m, num_cons_to_move, constraint_reserve)
                @info "Added $(num_cons_to_move) constraints back to model."
                last_ci_in_m = last_ci_in_m + num_cons_to_move
            end
            
            # Recalculate m
            optimize!(m)
            last_ts = termination_status(m)
    
            if in(last_ts, infeasible_statuses)
                last_known_inf_ci = last_ci_in_m
            elseif last_ts == MOI.OPTIMAL
                last_known_good_ci = last_ci_in_m
            else
                @warn "While searching for infeasibilities, found a combination of constraints that could not be optimized or proven infeasible. Solver reported following termination status when trying to optimize model with this combination of constraints: $(last_ts). Any infeasibilities found to this point are in return value. Exiting..."
                !m_original_silent && silent_solver && unset_silent(m)
                return infeasible_constraints
            end       
        end
    
        if in(last_ts, infeasible_statuses)
            target_cons::ConstraintRef = last(all_constraints(m; include_variable_in_set_constraints=false))  # Constraint causing infeasibility
            push!(infeasible_constraints, constraint_object(target_cons))
            delete(m, target_cons)
        elseif last_ts == MOI.OPTIMAL
           push!(infeasible_constraints, popfirst!(constraint_reserve))
        end

        @info "Found an infeasibility: $(last(infeasible_constraints)). Saving and continuing search."
        # END: Remove constraints from m/add constraints to m until a constraint causing infeasibility is identified.
        
        # Return all constraints to m and see if entire model is still infeasible
        num_cons_to_move = length(constraint_reserve)
        add_constraints!(m, num_cons_to_move, constraint_reserve)
        @info "Added $(num_cons_to_move) constraints back to model."

        optimize!(m)
        last_ts = termination_status(m)
    
        if in(last_ts, infeasible_statuses)
            # Reset for another iteration
            m_total_num_constraints = lastindex(all_constraints(m; include_variable_in_set_constraints=false))
            last_known_good_ci = 0
            last_known_inf_ci = m_total_num_constraints
            last_ci_in_m = last_known_inf_ci
        elseif last_ts == MOI.OPTIMAL
            search_complete = true
        else
            @warn "While searching for infeasibilities, found a combination of constraints that could not be optimized or proven infeasible. Solver reported following termination status when trying to optimize model with this combination of constraints: $(last_ts). Any infeasibilities found to this point are in return value. Exiting..."
            !m_original_silent && silent_solver && unset_silent(m)
            return infeasible_constraints
        end
    end  # !search_complete

    @info "Finished infeasibility search."
    !m_original_silent && silent_solver && unset_silent(m)
    return infeasible_constraints
end  # find_infeasibilities(m::JuMP.Model, silent_solver::Bool=false)

"""
    remove_constraints!(m::JuMP.Model,
        num_to_remove::Int,
        constraint_reserve::Array{Any, 1}
    )

Removes the last `num_to_remove` constraints from model `m` and puts their data in `constraint_reserve`. Determines which are the last `num_to_remove` constraints in `m` using the order in JuMP's `all_constraints` function. Preserves this constraint order in `constraint_reserve`. Ignores constraints that are variable bounds."""
function remove_constraints!(m::JuMP.Model, num_to_remove::Int, constraint_reserve::Array{Any, 1})
    ac::Vector{ConstraintRef} = all_constraints(m; include_variable_in_set_constraints=false)  # Array of all constraints in m excluding variable bounds
    c_to_move::Vector{ConstraintRef} = ac[lastindex(ac)-num_to_remove+1:lastindex(ac)]  # Constraints to remove from m

    prepend!(constraint_reserve, [constraint_object(c) for c in c_to_move])  # Add constraints to be removed to constraint_reserve
    delete(m, c_to_move)  # Remove constraints from m
end  # remove_constraints!(m::JuMP.Model, num::Int, constraint_reserve::Array{Any, 1})

"""
    add_constraints!(m::JuMP.Model,
        num_to_add::Int,
        constraint_reserve::Array{Any, 1}
    )

Adds the first `num_to_add` constraints in `constraint_reserve` to model `m`. Removes the constraints from `constraint_reserve`."""
function add_constraints!(m::JuMP.Model, num_to_add::Int, constraint_reserve::Array{Any, 1})
    JuMP.add_constraint.(m, splice!(constraint_reserve, 1:num_to_add))

    # Other patterns for adding multiple constraints at once
    # MOI.add_constraints(m.moi_backend, [moi_function(cr) for cr in constraint_reserve], [cr.set for cr in constraint_reserve])
    # broadcast!(JuMP.add_constraint, similar(constraint_reserve), m, constraint_reserve);
end  # add_constraints!(m::JuMP.Model, num::Int, constraint_reserve::Array{Any, 1})