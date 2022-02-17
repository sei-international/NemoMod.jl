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
    ConfParser.parse_line(line::String)

Overload of ConfParser.parse_line() in which quoted key values are returned as-is in their
entirety.
"""
function ConfParser.parse_line(line::String)
    parsed = String[]
    splitted = split(line, ",")

    # BEGIN: Code added to standard parse_line function.
    if occursin(r"^\".*\"$", line)
        m = match(r"^\"(.*)\"$", line)
        push!(parsed, m.captures[1])
        return parsed
    end
    # END: Code added to standard parse_line function.

    for raw = splitted
        if occursin(r"\S+", raw)
            clean = match(r"\S+", raw)
            push!(parsed, clean.match)
        end
    end
    parsed
end

"""
    getconfig(quiet::Bool = false)

Reads in NEMO's configuration file, which should be in the Julia working directory,
in `ini` format, and named `nemo.ini` or `nemo.cfg`. See the sample file in the NEMO
package's `utils` directory for more information.

# Arguments
- `quiet::Bool = false`: Suppresses low-priority status messages (which are otherwise printed to STDOUT).
"""
function getconfig(quiet::Bool = false)
    configpathini::String = joinpath(pwd(), "nemo.ini")
    configpathcfg::String = joinpath(pwd(), "nemo.cfg")
    configpath::String = ""

    if isfile(configpathini)
        configpath = configpathini
    elseif isfile(configpathcfg)
        configpath = configpathcfg
    else
        return nothing
    end

    try
        local conffile::ConfParse = ConfParse(configpath)
        parse_conf!(conffile)
        logmsg("Read NEMO configuration file at " * configpath * ".", quiet)
        return conffile
    catch
        logmsg("Could not parse NEMO configuration file at " * configpath * ". Please verify format.", quiet)
    end
end  # getconfig(quiet::Bool = false)

"""
    getconfigargs!(configfile::ConfParse,
        calcyears::Array{Int,1},
        varstosavearr::Array{String,1},
        bools::Array{Bool,1},
        quiet::Bool)

Loads run-time arguments for `calculatescenario()` from a configuration file.

# Arguments
- `configfile::ConfParse`: Configuration file. This argument is not changed by the function.
- `calcyears::Array{Int,1}`: `calculatescenario()` `calcyears` argument. Values specified
    in the configuration file for `[calculatescenarioargs]/calcyears` (including an empty or null value)
    replace what is in this array.
- `varstosavearr::Array{String,1}`: Array representation of `calculatescenario()` `varstosave` argument.
    Values specified in the configuration file for `[calculatescenarioargs]/varstosave` are added to this array.
- `bools::Array{Bool,1}`: Array of Boolean arguments for `calculatescenario()`: `restrictvars`, `reportzeros`,
    `continuoustransmission`, `forcemip`, and `quiet`, in that order. Values specified in the configuration file
    for `[calculatescenarioargs]/restrictvars`, `[calculatescenarioargs]/reportzeros`,
    `[calculatescenarioargs]/continuoustransmission`, `[calculatescenarioargs]/forcemip`, and `[calculatescenarioargs]/quiet`
    overwrite what is in this array (provided the values can be parsed as `Bool`).
- `quiet::Bool`: Suppresses low-priority status messages (which are otherwise printed to `STDOUT`).
    This argument is not changed by the function.
"""
function getconfigargs!(configfile::ConfParse, calcyears::Array{Int,1}, varstosavearr::Array{String,1},
    bools::Array{Bool,1}, strings::Array{String,1}, quiet::Bool)

    if haskey(configfile, "calculatescenarioargs", "calcyears")
        try
            calcyearsconfig = retrieve(configfile, "calculatescenarioargs", "calcyears")
            calcyearsconfigarr::Array{Int,1} = Array{Int,1}()  # calcyearsconfig converted to an Int array

            if typeof(calcyearsconfig) == String
                calcyearsconfigarr = [Meta.parse(calcyearsconfig)]
            else
                # calcyearsconfig should be an array of strings
                calcyearsconfigarr = [Meta.parse(v) for v in calcyearsconfig]
            end

            # This separate operation is necessary in order to modify calcyears
            empty!(calcyears)
            append!(calcyears, calcyearsconfigarr)
            logmsg("Read calcyears argument from configuration file.", quiet)
        catch e
            logmsg("Could not read calcyears argument from configuration file. Error message: " * sprint(showerror, e) * ". Continuing with NEMO.", quiet)
        end
    end

    if haskey(configfile, "calculatescenarioargs", "varstosave")
        try
            varstosaveconfig = retrieve(configfile, "calculatescenarioargs", "varstosave")

            if typeof(varstosaveconfig) == String
                union!(varstosavearr, [lowercase(varstosaveconfig)])
            else
                # varstosaveconfig should be an array of strings
                union!(varstosavearr, [lowercase(v) for v in varstosaveconfig])
            end

            logmsg("Read varstosave argument from configuration file.", quiet)
        catch e
            logmsg("Could not read varstosave argument from configuration file. Error message: " * sprint(showerror, e) * ". Continuing with NEMO.", quiet)
        end
    end

    if haskey(configfile, "calculatescenarioargs", "restrictvars")
        try
            bools[1] = Meta.parse(lowercase(retrieve(configfile, "calculatescenarioargs", "restrictvars")))
            logmsg("Read restrictvars argument from configuration file.", quiet)
        catch e
            logmsg("Could not read restrictvars argument from configuration file. Error message: " * sprint(showerror, e) * ". Continuing with NEMO.", quiet)
        end
    end

    if haskey(configfile, "calculatescenarioargs", "reportzeros")
        try
            bools[2] = Meta.parse(lowercase(retrieve(configfile, "calculatescenarioargs", "reportzeros")))
            logmsg("Read reportzeros argument from configuration file.", quiet)
        catch e
            logmsg("Could not read reportzeros argument from configuration file. Error message: " * sprint(showerror, e) * ". Continuing with NEMO.", quiet)
        end
    end

    if haskey(configfile, "calculatescenarioargs", "continuoustransmission")
        try
            bools[3] = Meta.parse(lowercase(retrieve(configfile, "calculatescenarioargs", "continuoustransmission")))
            logmsg("Read continuoustransmission argument from configuration file.", quiet)
        catch e
            logmsg("Could not read continuoustransmission argument from configuration file. Error message: " * sprint(showerror, e) * ". Continuing with NEMO.", quiet)
        end
    end

    if haskey(configfile, "calculatescenarioargs", "forcemip")
        try
            bools[4] = Meta.parse(lowercase(retrieve(configfile, "calculatescenarioargs", "forcemip")))
            logmsg("Read forcemip argument from configuration file.", quiet)
        catch e
            logmsg("Could not read forcemip argument from configuration file. Error message: " * sprint(showerror, e) * ". Continuing with NEMO.", quiet)
        end
    end

    if haskey(configfile, "calculatescenarioargs", "startvalsdbpath")
        try
            startvalsdbpathconfig = retrieve(configfile, "calculatescenarioargs", "startvalsdbpath")

            if typeof(startvalsdbpathconfig) == String
                strings[1] = startvalsdbpathconfig
            else
                # startvalsdbpathconfig should be an array of strings
                strings[1] = join(startvalsdbpathconfig, ",")
            end

            logmsg("Read startvalsdbpath argument from configuration file.", quiet)
        catch e
            logmsg("Could not read startvalsdbpath argument from configuration file. Error message: " * sprint(showerror, e) * ". Continuing with NEMO.", quiet)
        end
    end

    if haskey(configfile, "calculatescenarioargs", "startvalsvars")
        try
            startvalsvarsconfig = retrieve(configfile, "calculatescenarioargs", "startvalsvars")

            if typeof(startvalsvarsconfig) == String
                strings[2] = startvalsvarsconfig
            else
                # startvalsdbpathconfig should be an array of strings
                strings[2] = join(startvalsvarsconfig, ",")
            end

            logmsg("Read startvalsvars argument from configuration file.", quiet)
        catch e
            logmsg("Could not read startvalsvars argument from configuration file. Error message: " * sprint(showerror, e) * ". Continuing with NEMO.", quiet)
        end
    end

    if haskey(configfile, "calculatescenarioargs", "precalcresultspath")
        try
            precalcresultspathconfig = retrieve(configfile, "calculatescenarioargs", "precalcresultspath")

            if typeof(precalcresultspathconfig) == String
                strings[3] = precalcresultspathconfig
            else
                # startvalsdbpathconfig should be an array of strings
                strings[3] = join(precalcresultspathconfig, ",")
            end

            logmsg("Read precalcresultspath argument from configuration file.", quiet)
        catch e
            logmsg("Could not read precalcresultspath argument from configuration file. Error message: " * sprint(showerror, e) * ". Continuing with NEMO.", quiet)
        end
    end

    if haskey(configfile, "calculatescenarioargs", "quiet")
        try
            bools[5] = Meta.parse(lowercase(retrieve(configfile, "calculatescenarioargs", "quiet")))
            logmsg("Read quiet argument from configuration file. Value in configuration file will be used from this point forward.", quiet)
        catch e
            logmsg("Could not read quiet argument from configuration file. Error message: " * sprint(showerror, e) * ". Continuing with NEMO.", quiet)
        end
    end
end  # getconfigargs!(configfile::ConfParse, calcyears::Array{Int,1}, varstosavearr::Array{String,1}, bools::Array{Bool,1}, quiet::Bool)

"""
    setsolverparamsfromcfg(configfile::ConfParse, jumpmodel::JuMP.Model, quiet::Bool)

Sets solver parameters specified in a configuration file. Reports which parameters were and were not successfully set.

# Arguments
- `configfile::ConfParse`: Configuration file. Solver parameters should be in `parameters` key within `solver` block,
    specified as follows: `parameter1=value1`, `parameter2=value2`, ...
- `jumpmodel::JuMP.Model`: JuMP model in which solver parameters will be set.
- `quiet::Bool`: Suppresses low-priority status messages (which are otherwise printed to `STDOUT`).
"""
function setsolverparamsfromcfg(configfile::ConfParse, jumpmodel::JuMP.Model, quiet::Bool)
    if haskey(configfile, "solver", "parameters")
        local retrieved_params = retrieve(configfile, "solver", "parameters")  # May be a string (if there's one parameter-value pair) or an array of strings (if there are more than one, comma-delimited parameter-value pairs)
        local params_set::String = ""  # List of parameters that were successfully set; used in status message

        # Add singleton parameters to an array to facilitate processing
        if typeof(retrieved_params) == String
            retrieved_params = [retrieved_params]
        end

        # BEGIN: Process each parameter-value pair in retrieved_params.
        for e in retrieved_params
            local split_p::Array{String,1} = [strip(pp) for pp = split(e, "="; keepempty=false)]  # Current parameter specification split on =; split_p[1] = parameter name, split_p[2] = parameter value

            if length(split_p) != 2
                logmsg("Could not set solver parameter specified in configuration file as " * e * ". Continuing with NEMO.", quiet)
                continue
            end

            local val  # Parsed value for current parameter

            # Int, float, and Boolean values - order is important since an integer value will parse to a float
            for t in [Int, Float64, Bool]
                val = tryparse(t, split_p[2])

                if val != nothing
                    break
                end
            end

            if val == nothing
                # String value
                val = split_p[2]
            end

            # Call set_optimizer_attribute for parameter and value
            try
                set_optimizer_attribute(jumpmodel, split_p[1], val)
                params_set *= split_p[1] * ", "
            catch
                logmsg("Could not set solver parameter specified in configuration file as " * e * ". Continuing with NEMO.", quiet)
            end
        end
        # END: Process each parameter-value pair in retrieved_params.

        # Report parameters that were set
        if length(params_set) != 0
            logmsg("Set following solver parameters using values in configuration file: " * params_set[1:prevind(params_set, lastindex(params_set), 2)] * ".", quiet)
        end
    end  # haskey(configfile, "solver", "parameters")
end  # setsolverparamsfromcfg(configfile::ConfParse, jumpmodel::JuMP.Model, quiet::Bool)

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
    else
        return a
    end
end  # translatesetabb(a::String)

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
    local returnval = Array{Dict{Array{String,1},Set{String}},1}()  # Function return value

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

    return returnval
end  # keydicts(df::DataFrames.DataFrame, numdicts::Int)

#=
"""
    keydicts_parallel(df::DataFrames.DataFrame, numdicts::Int,
    targetprocs::Array{Int,1})

Runs `keydicts` using parallel processes identified in `targetprocs`. If there are not at
least 10,000 rows in `df` for each target process, resorts to running `keydicts` on process
that called `keydicts_parallel`.
"""
function keydicts_parallel(df::DataFrames.DataFrame, numdicts::Int, targetprocs::Array{Int,1})
    local returnval = Array{Dict{Array{String,1},Set{String}},1}()  # Function return value
    local availprocs::Array{Int, 1} = intersect(procs(), targetprocs)  # Targeted processes that actually exist
    local np::Int = length(availprocs)  # Number of targeted processes that actually exist
    local dfrows::Int = size(df)[1]  # Number of rows in df

    if np <= 1 || div(dfrows, np) < 10000
        # Run keydicts for entire df
        returnval = keydicts(df, numdicts)
    else
        # Divide operation among available processes
        local blockdivrem = divrem(dfrows, np)  # Quotient and remainder from dividing dfrows by np; element 1 = quotient, element 2 = remainder
        local results = Array{typeof(returnval), 1}(undef, np)  # Collection of results from async processing

        # Dispatch async tasks in main process, each of which performs a remotecall_fetch on an available process. Wrap in sync block
        #   to wait until all async processes finish before proceeding.
        @sync begin
            for p=1:np
                @async begin
                    # In each process, execute keydicts on a block of rows from df
                    results[p] = remotecall_fetch(NemoMod.keydicts, availprocs[p], df[((p-1) * blockdivrem[1] + 1):((p) * blockdivrem[1] + (p == np ? blockdivrem[2] : 0)),:], numdicts)
                end
            end
        end

        # Merge results from async tasks
        for i = 1:numdicts
            push!(returnval, Dict{Array{String,1},Set{String}}())

            for j = 1:np
                returnval[i] = merge(union, returnval[i], results[j][i])
            end
        end
    end

    return returnval
end  # keydicts_parallel(df::DataFrames.DataFrame, numdicts::Int, targetprocs::Array{Int,1})
=#

"""
    keydicts_threaded(df::DataFrames.DataFrame, numdicts::Int)

Runs `keydicts` on multiple threads. Uses one thread per 10,000 rows in `df`,
subject to an overall limit of `Threads.nthreads()`.
"""
function keydicts_threaded(df::DataFrames.DataFrame, numdicts::Int)
    local returnval = Array{Dict{Array{String,1},Set{String}},1}()  # Function return value
    local dfrows::Int = size(df)[1]  # Number of rows in df
    local nt::Int = min(Threads.nthreads(), div(dfrows-1, 10000) + 1)  # Number of threads on which keydicts will be run

    if nt == 1
        # Run keydicts for entire df
        returnval = keydicts(df, numdicts)
    else
        # Divide operation among multiple threads
        local blockdivrem = divrem(dfrows, nt)  # Quotient and remainder from dividing dfrows by nt; element 1 = quotient, element 2 = remainder
        local results = Array{typeof(returnval), 1}(undef, nt)  # Collection of results from threaded processing

        # Threads.@threads waits for all tasks to finish before proceeding
        Threads.@threads for p=1:nt
            results[p] = keydicts(df[((p-1) * blockdivrem[1] + 1):((p) * blockdivrem[1] + (p == nt ? blockdivrem[2] : 0)),:], numdicts)
        end

        # Merge results from threaded tasks
        for i = 1:numdicts
            push!(returnval, Dict{Array{String,1},Set{String}}())

            for j = 1:nt
                returnval[i] = merge(union, returnval[i], results[j][i])
            end
        end
    end

    return returnval
end  # keydicts_threaded(df::DataFrames.DataFrame, numdicts::Int)

#=
"""
    threadexecute(expr)

If `NemoMod.csmultithreaded` is true, passes `expr` to `Threads.@spawn`.
Otherwise returns `expr`.
"""
macro threadexecute(expr)
    return quote
        if NemoMod.csmultithreaded
            Threads.@spawn $(esc(expr))
        else
            $(esc(expr))
        end
    end
end  # threadexecute(expr) =#

#=
"""
    lockexecute(lck, expr)

If `NemoMod.csmultithreaded` is true, returns `expr` wrapped in a `do` block
that locks and unlocks `lck`. Otherwise returns `expr`.
"""
macro lockexecute(lck, expr)
    return quote
        if NemoMod.csmultithreaded
            lock($(esc(lck))) do
                $(esc(expr))
            end
        else
            $(esc(expr))
        end
    end
end  # lockexecute(lck, expr) =#

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
            SQLite.DBInterface.execute(db,"drop table if exists " * vname)

            SQLite.DBInterface.execute(db, "create table '" * vname * "' ('" * join(modelvarindices[vname][2], "' text, '") * "' text, 'val' real, 'solvedtm' text)")

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
    checkactivityupperlimits(db::SQLite.DB, tolerance::Float64, restrictyears::Bool, inyears::String)

For the scenario specified in `db`, checks whether there are:
    1) Any TotalTechnologyAnnualActivityUpperLimit values that are <= tolerance times the maximum
        annual demand
    2) Any TotalTechnologyModelPeriodActivityUpperLimit values that are <= tolerance times the maximum
        annual demand times the number of years in the scenario
If `restrictyears` is true, the maximum annual demand and the TotalTechnologyAnnualActivityUpperLimit values
are selected from the years in `inyears`. `inyears` should be a comma-delimited list of years in
parentheses, with a space at the beginning and end of the string.

Returns a `Tuple` of Booleans whose first value is the result of the first check, and whose second
    value is the result of the second.
"""
function checkactivityupperlimits(db::SQLite.DB, tolerance::Float64, restrictyears::Bool, inyears::String)
    local annual::Bool = true  # Return value indicating whether there are any TotalTechnologyAnnualActivityUpperLimit
        # values that are <= tolerance x maximum annual demand
    local modelperiod::Bool = true  # Return value indicating whether there are any TotalTechnologyModelPeriodActivityUpperLimit
        # values that are <= tolerance x maximum annual demand x # of years in scenario
    local qry::DataFrame  # Working query
    local maxdemand::Float64  # Maximum annual demand

    qry = SQLite.DBInterface.execute(db, "select max(mv) as mv from
    (select max(val) as mv from AccumulatedAnnualDemand_def $(restrictyears ? "where y in" * inyears : "")
    union
    select max(val) as mv from SpecifiedAnnualDemand_def $(restrictyears ? "where y in" * inyears : ""))") |> DataFrame

    maxdemand = qry[!,1][1]

    qry = SQLite.DBInterface.execute(db, "select tau.val from TotalTechnologyAnnualActivityUpperLimit_def tau
        where tau.val / :v1 <= :v2 $(restrictyears ? "and y in" * inyears : "")", [maxdemand, tolerance]) |> DataFrame

    if size(qry)[1] == 0
        annual = false
    end

    qry = SQLite.DBInterface.execute(db, "select tmu.val from TotalTechnologyModelPeriodActivityUpperLimit_def tmu
      where tmu.val / (:v1 * (select count(val) from year)) <= :v2", [maxdemand, tolerance]) |> DataFrame

    if size(qry)[1] == 0
      modelperiod = false
    end

    return (annual, modelperiod)
end  # checkactivityupperlimits(db::SQLite.DB, tolerance::Float64, restrictyears::Bool, inyears::String)

"""
    scenario_calc_queries(dbpath::String, transmissionmodeling::Bool, vproductionbytechnologysaved::Bool,
        vusebytechnologysaved::Bool, restrictyears::Bool, inyears::String)

Returns a `Dict` of query commands used in NEMO's `modelscenario` function. Each key in the return value is
    a query name, and each value is a `Tuple` where:
        - Element 1 = path to NEMO scenario database in which to execute query (taken from `dbpath` argument)
        - Element 2 = query's SQL statement
    The function's arguments other than `dbpath` delimit the set of returned query commands as noted below.

# Arguments
- `dbpath::String`: Path to NEMO scenario database in which query commands should be executed.
- `transmissionmodeling::Bool`: Indicates whether transmission modeling is enabled in `modelscenario`.
    Additional query commands are included in results when transmission modeling is enabled.
- `vproductionbytechnologysaved::Bool`: Indicates whether output variable `vproductionbytechnology`
    will be saved in `modelscenario`. Additional query commands are included in results when this argument
    and `transmissionmodeling` are `true`.
- `vusebytechnologysaved::Bool`: Indicates whether output variable `vusebytechnology`
    will be saved in `modelscenario`. Additional query commands are included in results when this argument
    and `transmissionmodeling` are `true`.
- `restrictyears::Bool`: Indicates whether `modelscenario` is running for selected years only.
- `inyears::String`: SQL IN clause predicate for years selected for `modelscenario`. When `restrictvars`
    is `true`, this argument is used to include filtering by year in query commands."""
function scenario_calc_queries(dbpath::String, transmissionmodeling::Bool, vproductionbytechnologysaved::Bool,
    vusebytechnologysaved::Bool, restrictyears::Bool, inyears::String)

    return_val::Dict{String, Tuple{String, String}} = Dict{String, Tuple{String, String}}()  # Return value for this function; map of query names
    #   to tuples of (DB path, SQL command)

    return_val["queryvrateofdemandnn"] = (dbpath, "select sdp.r as r, sdp.f as f, sdp.l as l, sdp.y as y,
    cast(sdp.val as real) as specifieddemandprofile, cast(sad.val as real) as specifiedannualdemand,
    cast(ys.val as real) as ys
    from SpecifiedDemandProfile_def sdp, SpecifiedAnnualDemand_def sad, YearSplit_def ys
    left join TransmissionModelingEnabled tme on tme.r = sad.r and tme.f = sad.f and tme.y = sad.y
    where sad.r = sdp.r and sad.f = sdp.f and sad.y = sdp.y
    and ys.l = sdp.l and ys.y = sdp.y
    and sdp.val <> 0 and sad.val <> 0 and ys.val <> 0
    $(restrictyears ? "and sdp.y in" * inyears : "")
    and tme.id is null")

    return_val["queryvrateofactivityvar"] = (dbpath, "with ar as (select r, t, m, y from OutputActivityRatio_def
    where val <> 0 $(restrictyears ? "and y in" * inyears : "")
    union
    select r, t, m, y from InputActivityRatio_def
    where val <> 0 $(restrictyears ? "and y in" * inyears : ""))
    select r.val as r, l.val as l, t.val as t, m.val as m, y.val as y
    from REGION r, TIMESLICE l, TECHNOLOGY t, MODE_OF_OPERATION m, YEAR y, ar
    where ar.r = r.val and ar.t = t.val and ar.m = m.val and ar.y = y.val
    order by r.val, t.val, l.val, y.val")

    return_val["queryvtrade"] = (dbpath, "select r.val as r, rr.val as rr, l.val as l, f.val as f, y.val as y
    from region r, region rr, TIMESLICE l, FUEL f, year y, TradeRoute_def tr
    WHERE
    r.val = tr.r and rr.val = tr.rr and f.val = tr.f and y.val = tr.y
    and tr.r <> tr.rr and tr.val = 1 $(restrictyears ? "and tr.y in" * inyears : "")
    order by r.val, rr.val, f.val, y.val")

    return_val["queryvtradeannual"] = (dbpath, "select r.val as r, rr.val as rr, f.val as f, y.val as y
    from region r, region rr, FUEL f, year y, TradeRoute_def tr
    WHERE
    r.val = tr.r and rr.val = tr.rr and f.val = tr.f and y.val = tr.y
    and tr.r <> tr.rr and tr.val = 1 $(restrictyears ? "and tr.y in" * inyears : "")")

    # fs_t is populated if t produces from storage
    return_val["queryvrateofproductionbytechnologybymodenn"] = (dbpath, "select r.val as r, ys.l as l, t.val as t, m.val as m, f.val as f, y.val as y,
    cast(oar.val as real) as oar, cast(ys.val as real) as ys, fs.t as fs_t, cast(ret.val as real) as ret
    from region r, YearSplit_def ys, technology t, MODE_OF_OPERATION m, fuel f, year y, OutputActivityRatio_def oar
    left join TransmissionModelingEnabled tme on tme.r = r.val and tme.f = f.val and tme.y = y.val
	left join (select DISTINCT tfs.r, tfs.t, tfs.m, y.val as y from TechnologyFromStorage_def tfs, year y
		left join nodalstorage ns on ns.r = tfs.r and ns.s = tfs.s and ns.y = y.val
		where tfs.val > 0 $(restrictyears ? "and y.val in" * inyears : "")
		and ns.r is null) fs on fs.r = r.val and fs.t = t.val and fs.m = m.val and fs.y = y.val
    left join RETagTechnology_def ret on ret.r = r.val and ret.t = t.val and ret.y = y.val
    where oar.r = r.val and oar.t = t.val and oar.f = f.val and oar.m = m.val and oar.y = y.val
    and oar.val <> 0
    and ys.y = y.val
    and tme.id is null
    $(restrictyears ? "and y.val in" * inyears : "")
	order by r.val, f.val, y.val, ys.l, t.val")

    return_val["queryvrateofproductionbytechnologynn"] = (dbpath, "select r.val as r, ys.l as l, t.val as t, f.val as f, y.val as y, cast(ys.val as real) as ys
    from region r, YearSplit_def ys, technology t, fuel f, year y,
    (select distinct r, t, f, y
    from OutputActivityRatio_def
    where val <> 0 $(restrictyears ? "and y in" * inyears : "")) oar
    left join TransmissionModelingEnabled tme on tme.r = r.val and tme.f = f.val and tme.y = y.val
    where oar.r = r.val and oar.t = t.val and oar.f = f.val and oar.y = y.val
    and ys.y = y.val
    and tme.id is null
    order by r.val, ys.l, f.val, y.val")

    return_val["queryvproductionbytechnologyannual"] = (dbpath, "select * from (
    select r.val as r, t.val as t, f.val as f, y.val as y, null as n, ys.l as l,
    cast(ys.val as real) as ys
    from region r, technology t, fuel f, year y, YearSplit_def ys,
    (select distinct r, t, f, y
    from OutputActivityRatio_def
    where val <> 0 $(restrictyears ? "and y in" * inyears : "")) oar
    left join TransmissionModelingEnabled tme on tme.r = r.val and tme.f = f.val and tme.y = y.val
    where oar.r = r.val and oar.t = t.val and oar.f = f.val and oar.y = y.val
    and ys.y = y.val
    and tme.id is null
    union all
    select n.r as r, ntc.t as t, oar.f as f, ntc.y as y, ntc.n as n, ys.l as l,
    cast(ys.val as real) as ys
    from NodalDistributionTechnologyCapacity_def ntc, NODE n,
    TransmissionModelingEnabled tme, YearSplit_def ys,
    (select distinct r, t, f, y
    from OutputActivityRatio_def
    where val <> 0 $(restrictyears ? "and y in" * inyears : "")) oar
    where ntc.val > 0
    and ntc.n = n.val
    and tme.r = n.r and tme.f = oar.f and tme.y = ntc.y
    and oar.r = n.r and oar.t = ntc.t and oar.y = ntc.y
    and ntc.y = ys.y
    )
    order by r, t, f, y")

    return_val["queryvrateofusebytechnologybymodenn"] = (dbpath, "select r.val as r, ys.l as l, t.val as t, m.val as m, f.val as f, y.val as y, cast(iar.val as real) as iar
    from region r, YearSplit_def ys, technology t, MODE_OF_OPERATION m, fuel f, year y, InputActivityRatio_def iar
    left join TransmissionModelingEnabled tme on tme.r = r.val and tme.f = f.val and tme.y = y.val
    where iar.r = r.val and iar.t = t.val and iar.f = f.val and iar.m = m.val and iar.y = y.val
    and iar.val <> 0
    and ys.y = y.val
    and tme.id is null
    $(restrictyears ? "and y.val in" * inyears : "")
    order by r.val, ys.l, t.val, f.val, y.val")

    return_val["queryvrateofusebytechnologynn"] = (dbpath, "select
    r.val as r, ys.l as l, t.val as t, f.val as f, y.val as y, cast(ys.val as real) as ys
    from region r, YearSplit_def ys, technology t, fuel f, year y,
    (select distinct r, t, f, y from InputActivityRatio_def where val <> 0 $(restrictyears ? "and y in" * inyears : "")) iar
    left join TransmissionModelingEnabled tme on tme.r = r.val and tme.f = f.val and tme.y = y.val
    where iar.r = r.val and iar.t = t.val and iar.f = f.val and iar.y = y.val
    and ys.y = y.val
    and tme.id is null
    order by r.val, ys.l, f.val, y.val")

    return_val["queryvusebytechnologyannual"] = (dbpath, "select * from (
    select r.val as r, t.val as t, f.val as f, y.val as y, null as n, ys.l as l,
    cast(ys.val as real) as ys
    from region r, technology t, fuel f, year y, YearSplit_def ys,
    (select distinct r, t, f, y from InputActivityRatio_def where val <> 0 $(restrictyears ? "and y in" * inyears : "")) iar
    left join TransmissionModelingEnabled tme on tme.r = r.val and tme.f = f.val and tme.y = y.val
    where iar.r = r.val and iar.t = t.val and iar.f = f.val and iar.y = y.val
    and ys.y = y.val
    and tme.id is null
    union all
    select n.r as r, ntc.t as t, iar.f as f, ntc.y as y, ntc.n as n, ys.l as l,
    cast(ys.val as real) as ys
    from NodalDistributionTechnologyCapacity_def ntc, NODE n,
    TransmissionModelingEnabled tme, YearSplit_def ys,
    (select distinct r, t, f, y from InputActivityRatio_def where val <> 0 $(restrictyears ? "and y in" * inyears : "")) iar
    where ntc.val > 0
    and ntc.n = n.val
    and tme.r = n.r and tme.f = iar.f and tme.y = ntc.y
    and iar.r = n.r and iar.t = ntc.t and iar.y = ntc.y
    and ntc.y = ys.y
    )
    order by r, t, f, y")

    return_val["querycaa5_totalnewcapacity"] = (dbpath, "select cot.r as r, cot.t as t, cot.y as y, cast(cot.val as real) as cot
    from CapacityOfOneTechnologyUnit_def cot where cot.val <> 0 $(restrictyears ? "and cot.y in" * inyears : "")")

    return_val["queryrtydr"] = (dbpath, "select r.val as r, t.val as t, y.val as y, cast(dr.val as real) as dr
    from region r, technology t, year y, DiscountRate_def dr
    where dr.r = r.val $(restrictyears ? "and y.val in" * inyears : "")")

    return_val["queryvannualtechnologyemissionbymode"] = (dbpath, "select r, t, e, y, m, cast(val as real) as ear
    from EmissionActivityRatio_def ear $(restrictyears ? "where y in" * inyears : "")
    order by r, t, e, y")

    return_val["queryvannualtechnologyemissionpenaltybyemission"] = (dbpath, "select r.val as r, t.val as t, y.val as y, e.val as e, cast(ep.val as real) as ep
    from REGION r, TECHNOLOGY t, EMISSION e, YEAR y
    left join EmissionsPenalty_def ep on ep.r = r.val and ep.e = e.val and ep.y = y.val and ep.val <> 0
    $(restrictyears ? "where y.val in" * inyears : "")
    order by r.val, t.val, y.val")

    return_val["queryvmodelperiodemissions"] = (dbpath, "select r.val as r, e.val as e, cast(mpl.val as real) as mpl
    from region r, emission e, ModelPeriodEmissionLimit_def mpl
    where mpl.r = r.val and mpl.e = e.val")

    if transmissionmodeling
        return_val["queryvrateofactivitynodal"] = (dbpath, "select ntc.n as n, l.val as l, ntc.t as t, ar.m as m, ntc.y as y
        from NodalDistributionTechnologyCapacity_def ntc, node n,
        	TransmissionModelingEnabled tme, TIMESLICE l,
        (select r, t, f, m, y from OutputActivityRatio_def
        where val <> 0 $(restrictyears ? "and y in" * inyears : "")
        union
        select r, t, f, m, y from InputActivityRatio_def
        where val <> 0 $(restrictyears ? "and y in" * inyears : "")) ar
        where ntc.val > 0
        and ntc.n = n.val
        and tme.r = n.r and tme.f = ar.f and tme.y = ntc.y
        and ar.r = n.r and ar.t = ntc.t and ar.y = ntc.y
        order by ntc.n, ntc.t, l.val, ntc.y")

        return_val["queryvrateofproductionbytechnologynodal"] = (dbpath, "select ntc.n as n, ys.l as l, ntc.t as t, oar.f as f, ntc.y as y,
        	cast(ys.val as real) as ys
        from NodalDistributionTechnologyCapacity_def ntc, YearSplit_def ys, NODE n,
    	TransmissionModelingEnabled tme,
        (select distinct r, t, f, y
        from OutputActivityRatio_def
        where val <> 0 $(restrictyears ? "and y in" * inyears : "")) oar
        where ntc.val > 0
        and ntc.y = ys.y
        and ntc.n = n.val
        and tme.r = n.r and tme.f = oar.f and tme.y = ntc.y
    	and oar.r = n.r and oar.t = ntc.t and oar.y = ntc.y
        order by ntc.n, ys.l, oar.f, ntc.y")

        return_val["queryvrateofusebytechnologynodal"] = (dbpath, "select ntc.n as n, ys.l as l, ntc.t as t, iar.f as f, ntc.y as y,
        	cast(ys.val as real) as ys
        from NodalDistributionTechnologyCapacity_def ntc, YearSplit_def ys, NODE n,
    	TransmissionModelingEnabled tme,
        (select distinct r, t, f, y
        from InputActivityRatio_def
        where val <> 0 $(restrictyears ? "and y in" * inyears : "")) iar
        where ntc.val > 0
        and ntc.y = ys.y
        and ntc.n = n.val
        and tme.r = n.r and tme.f = iar.f and tme.y = ntc.y
    	and iar.r = n.r and iar.t = ntc.t and iar.y = ntc.y
        order by ntc.n, ys.l, iar.f, ntc.y")

        if vproductionbytechnologysaved
            return_val["queryvproductionbytechnologyindices_nodalpart"] = (dbpath, "select distinct n.r as r, ys.l as l, ntc.t as t, oar.f as f, ntc.y as y, null as ys
            from NodalDistributionTechnologyCapacity_def ntc, YearSplit_def ys, NODE n,
            TransmissionModelingEnabled tme,
            (select distinct r, t, f, y
            from OutputActivityRatio_def
            where val <> 0 $(restrictyears ? "and y in" * inyears : "")) oar
            where ntc.val > 0
            and ntc.y = ys.y
            and ntc.n = n.val
            and tme.r = n.r and tme.f = oar.f and tme.y = ntc.y
            and oar.r = n.r and oar.t = ntc.t and oar.y = ntc.y")

            return_val["queryvproductionbytechnologynodal"] = (dbpath, "select n.r as r, ntc.n as n, ys.l as l, ntc.t as t, oar.f as f, ntc.y as y,
                cast(ys.val as real) as ys
            from NodalDistributionTechnologyCapacity_def ntc, YearSplit_def ys, NODE n,
            TransmissionModelingEnabled tme,
            (select distinct r, t, f, y
            from OutputActivityRatio_def
            where val <> 0 $(restrictyears ? "and y in" * inyears : "")) oar
            where ntc.val > 0
            and ntc.y = ys.y
            and ntc.n = n.val
            and tme.r = n.r and tme.f = oar.f and tme.y = ntc.y
            and oar.r = n.r and oar.t = ntc.t and oar.y = ntc.y
            order by n.r, ys.l, ntc.t, oar.f, ntc.y")
        end

        if vusebytechnologysaved
            return_val["queryvusebytechnologyindices_nodalpart"] = (dbpath, "select distinct n.r as r, ys.l as l, ntc.t as t, iar.f as f, ntc.y as y, null as ys
            from NodalDistributionTechnologyCapacity_def ntc, YearSplit_def ys, NODE n,
            TransmissionModelingEnabled tme,
            (select distinct r, t, f, y
            from InputActivityRatio_def
            where val <> 0 $(restrictyears ? "and y in" * inyears : "")) iar
            where ntc.val > 0
            and ntc.y = ys.y
            and ntc.n = n.val
            and tme.r = n.r and tme.f = iar.f and tme.y = ntc.y
            and iar.r = n.r and iar.t = ntc.t and iar.y = ntc.y")

            return_val["queryvusebytechnologynodal"] = (dbpath, "select n.r as r, ntc.n as n, ys.l as l, ntc.t as t, iar.f as f, ntc.y as y,
                cast(ys.val as real) as ys
            from NodalDistributionTechnologyCapacity_def ntc, YearSplit_def ys, NODE n,
            TransmissionModelingEnabled tme,
            (select distinct r, t, f, y
            from InputActivityRatio_def
            where val <> 0 $(restrictyears ? "and y in" * inyears : "")) iar
            where ntc.val > 0
            and ntc.y = ys.y
            and ntc.n = n.val
            and tme.r = n.r and tme.f = iar.f and tme.y = ntc.y
            and iar.r = n.r and iar.t = ntc.t and iar.y = ntc.y
            order by n.r, ys.l, ntc.t, iar.f, ntc.y")
        end

        return_val["queryvtransmissionbyline"] = (dbpath, "select tl.id as tr, ys.l as l, tl.f as f, tme1.y as y, tl.n1 as n1, tl.n2 as n2,
    	tl.reactance as reactance, tme1.type as type, tl.maxflow as maxflow,
        cast(tl.VariableCost as real) as vc, cast(ys.val as real) as ys,
        cast(tl.fixedcost as real) as fc, cast(tcta.val as real) as tcta, cast(tl.efficiency as real) as eff
        from TransmissionLine tl, NODE n1, NODE n2, TransmissionModelingEnabled tme1,
        TransmissionModelingEnabled tme2, YearSplit_def ys, TransmissionCapacityToActivityUnit_def tcta
        where
        tl.n1 = n1.val and tl.n2 = n2.val
        and tme1.r = n1.r and tme1.f = tl.f
        and tme2.r = n2.r and tme2.f = tl.f
        and tme1.y = tme2.y and tme1.type = tme2.type
    	and ys.y = tme1.y $(restrictyears ? "and ys.y in" * inyears : "")
    	and tcta.r = n1.r and tl.f = tcta.f
        order by tl.id, tme1.y")

        return_val["queryvtransmissionlosses"] = (dbpath, "select tl.id as tr, tl.n1, tl.n2, ys.l as l, tl.f as f, tme1.y as y
        from TransmissionLine tl, NODE n1, NODE n2, TransmissionModelingEnabled tme1,
        TransmissionModelingEnabled tme2, YearSplit_def ys
        where
        tl.efficiency < 1
        and tl.n1 = n1.val and tl.n2 = n2.val
        and tme1.r = n1.r and tme1.f = tl.f
        and tme2.r = n2.r and tme2.f = tl.f
        and tme1.y = tme2.y and tme1.type = tme2.type and tme1.type = 3
    	and ys.y = tme1.y $(restrictyears ? "and ys.y in" * inyears : "")")

        return_val["queryvstorageleveltsgroup1"] = (dbpath, "select ns.n as n, ns.s as s, tg1.name as tg1, ns.y as y
        from nodalstorage ns, TSGROUP1 tg1 $(restrictyears ? "where ns.y in" * inyears : "")")

        return_val["queryvstorageleveltsgroup2"] = (dbpath, "select ns.n as n, ns.s as s, tg1.name as tg1, tg2.name as tg2, ns.y as y
        from nodalstorage ns, TSGROUP1 tg1, TSGROUP2 tg2 $(restrictyears ? "where ns.y in" * inyears : "")")

        return_val["queryvstoragelevelts"] = (dbpath, "select ns.n as n, ns.s as s, l.val as l, ns.y as y
        from nodalstorage ns, TIMESLICE l $(restrictyears ? "where ns.y in" * inyears : "")")

        return_val["queryvrateofproduse"] = (dbpath, "select r.val as r, l.val as l, f.val as f, y.val as y, tme.id as tme, n.val as n
        from region r, timeslice l, fuel f, year y, YearSplit_def ys
        left join TransmissionModelingEnabled tme on tme.r = r.val and tme.f = f.val and tme.y = y.val
        left join NODE n on n.r = r.val
        where
        ys.l = l.val and ys.y = y.val
        $(restrictyears ? "and y.val in" * inyears : "")
        order by r.val, l.val, f.val, y.val")

        return_val["querytrydr"] = (dbpath, "select tl.id as tr, y.val as y, cast(dr.val as real) as dr
    	from TransmissionLine tl, NODE n, YEAR y, DiscountRate_def dr
        where tl.n1 = n.val
        and dr.r = n.r
    	$(restrictyears ? "and y.val in" * inyears : "")")
    end  # transmissionmodeling

    return return_val
end  # scenario_calc_queries()

"""
    run_queries(querycommands::Dict{String, Tuple{String, String}})

Runs the SQLite database queries specified in `querycommands` and returns a `Dict` that
    maps each query's name to a `DataFrame` of the query's results. Designed to work with
    the output of `scenario_calc_queries`. Uses multiple threads if they are available.
"""
function run_queries(querycommands::Dict{String, Tuple{String, String}})
    return_val = Dict{String, DataFrame}()
    lck = Base.ReentrantLock()

    Threads.@threads for q in collect(keys(querycommands))
        local df::DataFrame = run_qry(querycommands[q])

        lock(lck) do
            return_val[q] = df
        end
    end

    # Code for running queries without multi-threading; no longer used
    # return_val = Dict{String, DataFrame}(keys(querycommands) .=> map(run_qry, values(querycommands)))

    # Code for running queries in distributed processes; no longer used
    # Omitting process 1 from WorkerPool improves performance
    # queries = Dict{String, DataFrame}(keys(querycommands) .=> pmap(run_qry, WorkerPool(setdiff(targetprocs, [1])), values(querycommands)))

    return return_val
end  # run_queries(querycommands::Dict{String, Tuple{String, String}})

"""
    run_qry(qtpl::Tuple{String, String})

Runs the SQLite database query specified in `qtpl` and returns the result as a DataFrame.
    Element 1 in `qtpl` should be the path to the SQLite database, and element 2 should be the query's
    SQL command. Designed to work with the output of `scenario_calc_queries`."""
function run_qry(qtpl::Tuple{String, String})
    return SQLite.DBInterface.execute(SQLite.DB(qtpl[1]), qtpl[2]) |> DataFrame
end  # run_qry(qtpl::Tuple{String, String, String})

"""
    writescenariomodel(dbpath::String;
        calcyears::Array{Int, 1} = Array{Int, 1}(),
        varstosave::String = "vdemandnn, vnewcapacity, vtotalcapacityannual,
            vproductionbytechnologyannual, vproductionnn, vusebytechnologyannual,
            vusenn, vtotaldiscountedcost",
        restrictvars::Bool = true, continuoustransmission::Bool = false,
        forcemip::Bool = false, startvalsdbpath::String = "",
        startvalsvars::String = "", quiet::Bool = false,
        writefilename::String = "nemomodel.bz2",
        writefileformat::MathOptInterface.FileFormats.FileFormat = MathOptInterface.FileFormats.FORMAT_MPS
    )

Writes a file representing the optimization problem for a NEMO scenario. Returns the name of the file.
All arguments except `writefilename` and `writefileformat` function as in
[`calculatescenario`](@ref). `writefilename` and `writefileformat` are described below.

# Arguments

- `writefilename::String`: Name of the output file. If a path is not included in the name,
    the file is written to the Julia working directory. If the name ends in `.gz`, the file
    is compressed with Gzip. If the name ends in `.bz2`, the file is compressed with BZip2.
- `writefileformat::MathOptInterface.FileFormats.FileFormat`: Data format used in the output
    file. Common formats include `MathOptInterface.FileFormats.FORMAT_MPS` (MPS format) and
    `MathOptInterface.FileFormats.FORMAT_LP` (LP format). See the documentation for
    [`MathOptInterface`](https://github.com/jump-dev/MathOptInterface.jl) for additional options.
"""
function writescenariomodel(
    dbpath::String;
    calcyears::Array{Int, 1} = Array{Int, 1}(),
    varstosave::String = "vdemandnn, vnewcapacity, vtotalcapacityannual, vproductionbytechnologyannual, vproductionnn, vusebytechnologyannual, vusenn, vtotaldiscountedcost",
    restrictvars::Bool = true,
    continuoustransmission::Bool = false,
    forcemip = false,
    startvalsdbpath::String = "",
    startvalsvars::String = "",
    quiet::Bool = false,
    writefilename::String = "nemomodel.bz2",
    writefileformat::MathOptInterface.FileFormats.FileFormat = MathOptInterface.FileFormats.FORMAT_MPS
    )

    try
        modelscenario(dbpath; calcyears=calcyears, varstosave=varstosave, restrictvars=restrictvars,
            continuoustransmission=continuoustransmission, forcemip=forcemip, startvalsdbpath=startvalsdbpath,
            startvalsvars=startvalsvars, quiet=quiet, writemodel=true, writefilename=writefilename,
            writefileformat=writefileformat)
    catch e
        println("NEMO encountered an error with the following message: " * sprint(showerror, e) * ".")
        println("To report this issue to the NEMO team, please submit an error report at https://leap.sei.org/support/. Please include in the report a list of steps to reproduce the error and the error message.")
    end
end  # writescenariomodel

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
    SQLite.DBInterface.execute(seeddb, "pragma case_sensitive_like = true")

    for smrow in SQLite.DBInterface.execute(seeddb, "select name from sqlite_master where type = 'table' and name like 'v%'
        $(length(selectedvars) > 0 ? " and name in ('" * join(selectedvars, "','") * "')" : "")")

        local tname = smrow[:name]  # Name of table being processed
        local selectfields::Array{String,1} = Array{String,1}()  # Names of fields to select from table being processed, excluding val
        local excludefields::Array{String,1} = ["solvedtm", "val"]  # Fields that are not added to selectfields in following loop

        # Build selectfields
        for row in SQLite.DBInterface.execute(seeddb, "pragma table_info('$tname')")
            if !in(row[:name], excludefields)
                push!(selectfields, row[:name])
            end
        end

        # Set start values for variables existing in jumpmodel and seeddb
        for row in SQLite.DBInterface.execute(seeddb, "select $(join(selectfields,",")), val from $tname")
            local var = variable_by_name(jumpmodel, "$tname[$(join([row[Symbol(f)] for f in selectfields], ","))]")

            !isnothing(var) && set_start_value(var, row[:val])
        end
    end  # smrow

    SQLite.DBInterface.execute(seeddb,"pragma case_sensitive_like = false")
    # END: Process selected result tables and set start values in jumpmodel.

    logmsg("Set variable start values using values in $(normpath(seeddbpath)).", quiet)
end  # setstartvalues(jumpmodel::JuMP.Model, seeddbpath::String, quiet::Bool = false; selectedvars::Array{String,1} = Array{String,1}())
