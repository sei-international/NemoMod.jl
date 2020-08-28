#=
    NEMO: Next-generation Energy Modeling system for Optimization.
    https://github.com/sei-international/NemoMod.jl

    Copyright © 2018: Stockholm Environment Institute U.S.

    File description: Main function library for NEMO.
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
        varstosavearr::Array{String,1},
        targetprocs::Array{Int,1},
        bools::Array{Bool,1},
        ints::Array{Int,1},
        quiet::Bool)

Loads run-time arguments for calculatescenario() from a configuration file.

# Arguments
- `configfile::ConfParse`: Configuration file. This argument is not changed by the function.
- `varstosavearr::Array{String,1}`: Array representation of calculatescenario() varstosave argument.
    New values in configuration file are added to this array.
- `targetprocs::Array{Int,1}`: calculatescenario() targetprocs argument. New values in configuration
    file are added to this array.
- `bools::Array{Bool,1}`: Array of Boolean arguments for calculatescenario(): restrictvars, reportzeros,
    continuoustransmission, and quiet, in that order. New values in configuration file overwrite values
    in this array.
- `ints::Array{Int,1}`: Array of `Int` arguments for calculatescenario(): numprocs. New values in
    configuration file overwrite values in this array.
- `quiet::Bool = false`: Suppresses low-priority status messages (which are otherwise printed to STDOUT).
    This argument is not changed by the function.
"""
function getconfigargs!(configfile::ConfParse, varstosavearr::Array{String,1}, targetprocs::Array{Int,1},
    bools::Array{Bool,1}, ints::Array{Int,1}, quiet::Bool)

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

    if haskey(configfile, "calculatescenarioargs", "numprocs")
        try
            ints[1] = Meta.parse(lowercase(retrieve(configfile, "calculatescenarioargs", "numprocs")))
            logmsg("Read numprocs argument from configuration file.", quiet)
        catch e
            logmsg("Could not read numprocs argument from configuration file. Error message: " * sprint(showerror, e) * ". Continuing with NEMO.", quiet)
        end
    end

    if haskey(configfile, "calculatescenarioargs", "targetprocs")
        try
            targetprocsconfig = retrieve(configfile, "calculatescenarioargs", "targetprocs")

            if typeof(targetprocsconfig) == String
                union!(targetprocs, [Meta.parse(targetprocsconfig)])
            else
                # targetprocsconfig should be an array of strings
                union!(targetprocs, [Meta.parse(v) for v in targetprocsconfig])
            end

            logmsg("Read targetprocs argument from configuration file.", quiet)
        catch e
            logmsg("Could not read targetprocs argument from configuration file. Error message: " * sprint(showerror, e) * ". Continuing with NEMO.", quiet)
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

    if haskey(configfile, "calculatescenarioargs", "quiet")
        try
            bools[4] = Meta.parse(lowercase(retrieve(configfile, "calculatescenarioargs", "quiet")))
            logmsg("Read quiet argument from configuration file. Value in configuration file will be used from this point forward.", quiet)
        catch e
            logmsg("Could not read quiet argument from configuration file. Error message: " * sprint(showerror, e) * ". Continuing with NEMO.", quiet)
        end
    end
end  # getconfigargs!(configfile::ConfParse, varstosavearr::Array{String,1}, targetprocs::Array{Int,1}, bools::Array{Bool,1}, quiet::Bool)

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

#= Testing code:
using JuMP, SQLite, IterTools, NullableArrays, DataFrames
dbpath = "C:\\temp\\utopia_2015_08_27.sl3"
db = SQLite.DB(dbpath)
stechnology = dropnull(SQLite.query(db, "select val from technology limit 10")[:val])
@constraintref(abc[1:10])
m = Model()
@variable(m, vtest[stechnology])
createconstraint(m, "TestConstraint", abc, DataFrames.eachrow(SQLite.query(db, "select t.val as t from technology t limit 10")), ["t"], "vtest[t]", ">=", "0")
=#

"""
    createnemodb(path::String;
    defaultvals::Dict{String, Float64} = Dict{String, Float64}(),
    foreignkeys::Bool = false)

Creates an empty NEMO scenario database in SQLite. If the specified database already exists, drops and
recreates NEMO tables in the database.

# Arguments
- `path::String`: Full path to the scenario database, including the file name.
- `defaultvals::Dict{String, Float64} = Dict{String, Float64}()`: Dictionary of parameter table names and default values for `val` column.
- `foreignkeys::Bool = false`: Indicates whether to create foreign keys within the database.
"""
function createnemodb(path::String; defaultvals::Dict{String, Float64} = Dict{String, Float64}(),
    foreignkeys::Bool = false)
    # Open SQLite database
    local db::SQLite.DB = SQLite.DB(path)
    logmsg("Opened SQLite database at " * path * ".")

    # BEGIN: DDL operations in an SQLite transaction.
    SQLite.DBInterface.execute(db, "BEGIN")

    # BEGIN: Drop any existing NEMO tables.
    SQLite.DBInterface.execute(db,"drop table if exists AccumulatedAnnualDemand")
    SQLite.DBInterface.execute(db,"drop table if exists AnnualEmissionLimit")
    SQLite.DBInterface.execute(db,"drop table if exists AnnualExogenousEmission")
    SQLite.DBInterface.execute(db,"drop table if exists AvailabilityFactor")
    SQLite.DBInterface.execute(db,"drop table if exists CapacityFactor")
    SQLite.DBInterface.execute(db,"drop table if exists CapacityOfOneTechnologyUnit")
    SQLite.DBInterface.execute(db,"drop table if exists CapacityToActivityUnit")
    SQLite.DBInterface.execute(db,"drop table if exists CapitalCost")
    SQLite.DBInterface.execute(db,"drop table if exists CapitalCostStorage")
    SQLite.DBInterface.execute(db,"drop table if exists Conversionld")
    SQLite.DBInterface.execute(db,"drop table if exists Conversionlh")
    SQLite.DBInterface.execute(db,"drop table if exists Conversionls")
    SQLite.DBInterface.execute(db,"drop table if exists DaySplit")
    SQLite.DBInterface.execute(db,"drop table if exists DaysInDayType")
    SQLite.DBInterface.execute(db,"drop table if exists DepreciationMethod")
    SQLite.DBInterface.execute(db,"drop table if exists DiscountRate")
    SQLite.DBInterface.execute(db,"drop table if exists DiscountRateStorage")
    SQLite.DBInterface.execute(db,"drop table if exists EmissionActivityRatio")
    SQLite.DBInterface.execute(db,"drop table if exists EmissionsPenalty")
    SQLite.DBInterface.execute(db,"drop table if exists FixedCost")
    SQLite.DBInterface.execute(db,"drop table if exists InputActivityRatio")
    SQLite.DBInterface.execute(db,"drop table if exists LTsGroup")
    SQLite.DBInterface.execute(db,"drop table if exists MinStorageCharge")
    SQLite.DBInterface.execute(db,"drop table if exists ModelPeriodEmissionLimit")
    SQLite.DBInterface.execute(db,"drop table if exists ModelPeriodExogenousEmission")
    SQLite.DBInterface.execute(db,"drop table if exists NodalDistributionDemand")
    SQLite.DBInterface.execute(db,"drop table if exists NodalDistributionTechnologyCapacity")
    SQLite.DBInterface.execute(db,"drop table if exists NodalDistributionStorageCapacity")
    SQLite.DBInterface.execute(db,"drop table if exists OperationalLife")
    SQLite.DBInterface.execute(db,"drop table if exists OperationalLifeStorage")
    SQLite.DBInterface.execute(db,"drop table if exists OutputActivityRatio")
    SQLite.DBInterface.execute(db,"drop table if exists REMinProductionTarget")
    SQLite.DBInterface.execute(db,"drop table if exists RETagFuel")
    SQLite.DBInterface.execute(db,"drop table if exists RETagTechnology")
    SQLite.DBInterface.execute(db,"drop table if exists ReserveMargin")
    SQLite.DBInterface.execute(db,"drop table if exists ReserveMarginTagFuel")
    SQLite.DBInterface.execute(db,"drop table if exists ReserveMarginTagTechnology")
    SQLite.DBInterface.execute(db,"drop table if exists ResidualCapacity")
    SQLite.DBInterface.execute(db,"drop table if exists ResidualStorageCapacity")
    SQLite.DBInterface.execute(db,"drop table if exists SpecifiedAnnualDemand")
    SQLite.DBInterface.execute(db,"drop table if exists SpecifiedDemandProfile")
    SQLite.DBInterface.execute(db,"drop table if exists StorageFullLoadHours")
    SQLite.DBInterface.execute(db,"drop table if exists StorageLevelStart")
    SQLite.DBInterface.execute(db,"drop table if exists StorageMaxChargeRate")
    SQLite.DBInterface.execute(db,"drop table if exists StorageMaxDischargeRate")
    SQLite.DBInterface.execute(db,"drop table if exists TechWithCapacityNeededToMeetPeakTS")
    SQLite.DBInterface.execute(db,"drop table if exists TechnologyFromStorage")
    SQLite.DBInterface.execute(db,"drop table if exists TechnologyToStorage")
    SQLite.DBInterface.execute(db,"drop table if exists TotalAnnualMaxCapacity")
    SQLite.DBInterface.execute(db,"drop table if exists TotalAnnualMaxCapacityStorage")
    SQLite.DBInterface.execute(db,"drop table if exists TotalAnnualMaxCapacityInvestment")
    SQLite.DBInterface.execute(db,"drop table if exists TotalAnnualMaxCapacityInvestmentStorage")
    SQLite.DBInterface.execute(db,"drop table if exists TotalAnnualMinCapacity")
    SQLite.DBInterface.execute(db,"drop table if exists TotalAnnualMinCapacityStorage")
    SQLite.DBInterface.execute(db,"drop table if exists TotalAnnualMinCapacityInvestment")
    SQLite.DBInterface.execute(db,"drop table if exists TotalAnnualMinCapacityInvestmentStorage")
    SQLite.DBInterface.execute(db,"drop table if exists TotalTechnologyAnnualActivityLowerLimit")
    SQLite.DBInterface.execute(db,"drop table if exists TotalTechnologyAnnualActivityUpperLimit")
    SQLite.DBInterface.execute(db,"drop table if exists TotalTechnologyModelPeriodActivityLowerLimit")
    SQLite.DBInterface.execute(db,"drop table if exists TotalTechnologyModelPeriodActivityUpperLimit")
    SQLite.DBInterface.execute(db,"drop table if exists TransmissionCapacityToActivityUnit")
    SQLite.DBInterface.execute(db,"drop table if exists TransmissionLine")
    SQLite.DBInterface.execute(db,"drop table if exists TransmissionModelingEnabled")
    SQLite.DBInterface.execute(db,"drop table if exists TradeRoute")
    SQLite.DBInterface.execute(db,"drop table if exists VariableCost")
    SQLite.DBInterface.execute(db,"drop table if exists YearSplit")

    SQLite.DBInterface.execute(db,"drop table if exists DefaultParams")

    SQLite.DBInterface.execute(db,"drop table if exists DAILYTIMEBRACKET")
    SQLite.DBInterface.execute(db,"drop table if exists DAYTYPE")
    SQLite.DBInterface.execute(db,"drop table if exists REGION")
    SQLite.DBInterface.execute(db,"drop table if exists YEAR")
    SQLite.DBInterface.execute(db,"drop table if exists TECHNOLOGY")
    SQLite.DBInterface.execute(db,"drop table if exists TIMESLICE")
    SQLite.DBInterface.execute(db,"drop table if exists SEASON")
    SQLite.DBInterface.execute(db,"drop table if exists STORAGE")
    SQLite.DBInterface.execute(db,"drop table if exists MODE_OF_OPERATION")
    SQLite.DBInterface.execute(db,"drop table if exists EMISSION")
    SQLite.DBInterface.execute(db,"drop table if exists FUEL")
    SQLite.DBInterface.execute(db,"drop table if exists TSGROUP1")
    SQLite.DBInterface.execute(db,"drop table if exists TSGROUP2")
    SQLite.DBInterface.execute(db,"drop table if exists NODE")

    SQLite.DBInterface.execute(db,"drop table if exists Version")
    # END: Drop any existing NEMO tables.

    # BEGIN: Add new NEMO tables.
    # Version table is for NEMO data dictionary version
    #   - 2: Added STORAGE.netzeroyear, STORAGE.netzerotg1, and STORAGE.netzerotg2
    #   - 3: Added TransmissionLine.efficiency
    #   - 4: Added TransmissionCapacityToActivityUnit.r
    SQLite.DBInterface.execute(db, "CREATE TABLE `Version` (`version` INTEGER, PRIMARY KEY(`version`))")
    SQLite.DBInterface.execute(db, "INSERT INTO Version VALUES(4)")

    # No default values for sets/dimensions
    SQLite.DBInterface.execute(db, "CREATE TABLE IF NOT EXISTS `EMISSION` ( `val` TEXT NOT NULL UNIQUE, `desc` TEXT, PRIMARY KEY(`val`) )")
    SQLite.DBInterface.execute(db, "CREATE TABLE IF NOT EXISTS `FUEL` ( `val` TEXT NOT NULL UNIQUE, `desc` TEXT, PRIMARY KEY(`val`) )")
    SQLite.DBInterface.execute(db, "CREATE TABLE IF NOT EXISTS `MODE_OF_OPERATION` (`val` TEXT NOT NULL UNIQUE, `desc` TEXT, PRIMARY KEY(`val`))")
    SQLite.DBInterface.execute(db, "CREATE TABLE IF NOT EXISTS `REGION` (`val` TEXT NOT NULL UNIQUE, `desc` TEXT, PRIMARY KEY(`val`))")
    SQLite.DBInterface.execute(db, "CREATE TABLE IF NOT EXISTS `STORAGE` ( `val` TEXT NOT NULL UNIQUE, `desc` TEXT, `netzeroyear` INTEGER NOT NULL DEFAULT 1, `netzerotg1` INTEGER NOT NULL DEFAULT 0, `netzerotg2` INTEGER NOT NULL DEFAULT 0, PRIMARY KEY(`val`) )")
    SQLite.DBInterface.execute(db, "CREATE TABLE IF NOT EXISTS `TECHNOLOGY` (`val` TEXT NOT NULL UNIQUE, `desc` TEXT, PRIMARY KEY(`val`))")
    SQLite.DBInterface.execute(db, "CREATE TABLE IF NOT EXISTS `TIMESLICE` (`val` TEXT NOT NULL UNIQUE, `desc` TEXT, PRIMARY KEY(`val`))")
    SQLite.DBInterface.execute(db, "CREATE TABLE IF NOT EXISTS `TSGROUP1` (`name` TEXT, `desc` TEXT, `order` INTEGER NOT NULL UNIQUE, `multiplier` REAL NOT NULL DEFAULT 1, PRIMARY KEY(`name`))")
    SQLite.DBInterface.execute(db, "CREATE TABLE IF NOT EXISTS `TSGROUP2` (`name` TEXT, `desc` TEXT, `order` INTEGER NOT NULL UNIQUE, `multiplier` REAL NOT NULL DEFAULT 1, PRIMARY KEY(`name`))")
    SQLite.DBInterface.execute(db, "CREATE TABLE IF NOT EXISTS `YEAR` (`val` TEXT NOT NULL UNIQUE, `desc` TEXT, PRIMARY KEY(`val`))")
    SQLite.DBInterface.execute(db, "CREATE TABLE IF NOT EXISTS `NODE` ( `val` TEXT, `desc` TEXT, `r` TEXT, PRIMARY KEY(`val`)" * (foreignkeys ? ", FOREIGN KEY(`r`) REFERENCES `REGION`(`val`)" : "") * " )")

    # Parameter default table
    SQLite.DBInterface.execute(db, "CREATE TABLE IF NOT EXISTS `DefaultParams` ( `id` INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT, `tablename` TEXT NOT NULL, `val` REAL NOT NULL );")
    SQLite.DBInterface.execute(db, "CREATE UNIQUE INDEX `DefaultParams_tablename_unique` ON `DefaultParams` (`tablename`);")  # Needed for LEAP compatibility

    # Parameter tables
    SQLite.DBInterface.execute(db, "CREATE TABLE IF NOT EXISTS `YearSplit` ( `id` INTEGER NOT NULL UNIQUE, `l` TEXT, `y` TEXT, `val` REAL, PRIMARY KEY(`id`)" * (foreignkeys ? ", FOREIGN KEY(`y`) REFERENCES `YEAR`(`val`), FOREIGN KEY(`l`) REFERENCES `TIMESLICE`(`val`)" : "") * " )")
    SQLite.DBInterface.execute(db, "CREATE TABLE IF NOT EXISTS `VariableCost` ( `id` INTEGER NOT NULL UNIQUE, `r` TEXT, `t` TEXT, `m` TEXT, `y` TEXT, `val` REAL, PRIMARY KEY(`id`)" * (foreignkeys ? ", FOREIGN KEY(`t`) REFERENCES `TECHNOLOGY`(`val`), FOREIGN KEY(`m`) REFERENCES `MODE_OF_OPERATION`(`val`), FOREIGN KEY(`y`) REFERENCES `YEAR`(`val`), FOREIGN KEY(`r`) REFERENCES `REGION`(`val`)" : "") * " )")
    SQLite.DBInterface.execute(db, "CREATE TABLE IF NOT EXISTS `TransmissionModelingEnabled` ( `id` INTEGER, `r` TEXT, `f` TEXT, `y` TEXT, `type` INTEGER DEFAULT 1, PRIMARY KEY(`id`)" * (foreignkeys ? ", FOREIGN KEY(`r`) REFERENCES `REGION`(`val`), FOREIGN KEY(`f`) REFERENCES `FUEL`(`val`), FOREIGN KEY(`y`) REFERENCES `YEAR`(`val`)" : "") * " )")
    SQLite.DBInterface.execute(db, "CREATE TABLE IF NOT EXISTS `TransmissionLine` ( `id` TEXT, `n1` TEXT, `n2` TEXT, `f` TEXT, `maxflow` REAL, `reactance` REAL, `yconstruction` INTEGER, `capitalcost` REAL, `fixedcost` REAL, `variablecost` REAL, `operationallife` INTEGER, `efficiency` REAL, PRIMARY KEY(`id`)" * (foreignkeys ? ", FOREIGN KEY(`n2`) REFERENCES `NODE`(`val`), FOREIGN KEY(`n1`) REFERENCES `NODE`(`val`), FOREIGN KEY(`f`) REFERENCES `FUEL`(`val`)" : "") * " )")
    SQLite.DBInterface.execute(db, "CREATE TABLE IF NOT EXISTS `TransmissionCapacityToActivityUnit` ( `id` INTEGER NOT NULL UNIQUE, `r` TEXT, `f` TEXT, `val` REAL, PRIMARY KEY(`id`)" * (foreignkeys ? ", FOREIGN KEY(`r`) REFERENCES `REGION`(`val`), FOREIGN KEY(`f`) REFERENCES `FUEL`(`val`)" : "") * " )")
    SQLite.DBInterface.execute(db, "CREATE TABLE IF NOT EXISTS `TradeRoute` ( `id` INTEGER NOT NULL UNIQUE, `r` TEXT, `rr` TEXT, `f` TEXT, `y` TEXT, `val` REAL, PRIMARY KEY(`id`)" * (foreignkeys ? ", FOREIGN KEY(`r`) REFERENCES `REGION`(`val`), FOREIGN KEY(`rr`) REFERENCES `REGION`(`val`), FOREIGN KEY(`y`) REFERENCES `YEAR`(`val`), FOREIGN KEY(`f`) REFERENCES `FUEL`(`val`)" : "") * " )")
    SQLite.DBInterface.execute(db, "CREATE TABLE IF NOT EXISTS `TotalTechnologyModelPeriodActivityUpperLimit` ( `id` INTEGER NOT NULL UNIQUE, `r` TEXT, `t` TEXT, `val` REAL, PRIMARY KEY(`id`)" * (foreignkeys ? ", FOREIGN KEY(`t`) REFERENCES `TECHNOLOGY`(`val`), FOREIGN KEY(`r`) REFERENCES `REGION`(`val`)" : "") * " )")
    SQLite.DBInterface.execute(db, "CREATE TABLE IF NOT EXISTS `TotalTechnologyModelPeriodActivityLowerLimit` ( `id` INTEGER NOT NULL UNIQUE, `r` TEXT, `t` TEXT, `val` REAL, PRIMARY KEY(`id`)" * (foreignkeys ? ", FOREIGN KEY(`t`) REFERENCES `TECHNOLOGY`(`val`), FOREIGN KEY(`r`) REFERENCES `REGION`(`val`)" : "") * " )")
    SQLite.DBInterface.execute(db, "CREATE TABLE IF NOT EXISTS `TotalTechnologyAnnualActivityUpperLimit` ( `id` INTEGER NOT NULL UNIQUE, `r` TEXT, `t` TEXT, `y` TEXT, `val` REAL, PRIMARY KEY(`id`)" * (foreignkeys ? ", FOREIGN KEY(`y`) REFERENCES `YEAR`(`val`), FOREIGN KEY(`t`) REFERENCES `TECHNOLOGY`(`val`), FOREIGN KEY(`r`) REFERENCES `REGION`(`val`)" : "") * " )")
    SQLite.DBInterface.execute(db, "CREATE TABLE IF NOT EXISTS `TotalTechnologyAnnualActivityLowerLimit` ( `id` INTEGER NOT NULL UNIQUE, `r` TEXT, `t` TEXT, `y` TEXT, `val` REAL, PRIMARY KEY(`id`)" * (foreignkeys ? ", FOREIGN KEY(`y`) REFERENCES `YEAR`(`val`), FOREIGN KEY(`t`) REFERENCES `TECHNOLOGY`(`val`), FOREIGN KEY(`r`) REFERENCES `REGION`(`val`)" : "") * " )")
    SQLite.DBInterface.execute(db, "CREATE TABLE IF NOT EXISTS `TotalAnnualMinCapacityInvestment` ( `id` INTEGER NOT NULL UNIQUE, `r` TEXT, `t` TEXT, `y` TEXT, `val` REAL, PRIMARY KEY(`id`)" * (foreignkeys ? ", FOREIGN KEY(`y`) REFERENCES `YEAR`(`val`), FOREIGN KEY(`r`) REFERENCES `REGION`(`val`), FOREIGN KEY(`t`) REFERENCES `TECHNOLOGY`(`val`)" : "") * " )")
    SQLite.DBInterface.execute(db, "CREATE TABLE IF NOT EXISTS `TotalAnnualMinCapacityInvestmentStorage` ( `id` INTEGER NOT NULL UNIQUE, `r` TEXT, `s` TEXT, `y` TEXT, `val` REAL, PRIMARY KEY(`id`)" * (foreignkeys ? ", FOREIGN KEY(`y`) REFERENCES `YEAR`(`val`), FOREIGN KEY(`r`) REFERENCES `REGION`(`val`), FOREIGN KEY(`s`) REFERENCES `STORAGE`(`val`)" : "") * " )")
    SQLite.DBInterface.execute(db, "CREATE TABLE IF NOT EXISTS `TotalAnnualMinCapacity` ( `id` INTEGER NOT NULL UNIQUE, `r` TEXT, `t` TEXT, `y` TEXT, `val` REAL, PRIMARY KEY(`id`)" * (foreignkeys ? ", FOREIGN KEY(`t`) REFERENCES `TECHNOLOGY`(`val`), FOREIGN KEY(`r`) REFERENCES `REGION`(`val`), FOREIGN KEY(`y`) REFERENCES `YEAR`(`val`)" : "") * " )")
    SQLite.DBInterface.execute(db, "CREATE TABLE IF NOT EXISTS `TotalAnnualMinCapacityStorage` ( `id` INTEGER NOT NULL UNIQUE, `r` TEXT, `s` TEXT, `y` TEXT, `val` REAL, PRIMARY KEY(`id`)" * (foreignkeys ? ", FOREIGN KEY(`s`) REFERENCES `STORAGE`(`val`), FOREIGN KEY(`r`) REFERENCES `REGION`(`val`), FOREIGN KEY(`y`) REFERENCES `YEAR`(`val`)" : "") * " )")
    SQLite.DBInterface.execute(db, "CREATE TABLE IF NOT EXISTS `TotalAnnualMaxCapacityInvestment` ( `id` INTEGER NOT NULL UNIQUE, `r` TEXT, `t` TEXT, `y` TEXT, `val` REAL, PRIMARY KEY(`id`)" * (foreignkeys ? ", FOREIGN KEY(`y`) REFERENCES `YEAR`(`val`), FOREIGN KEY(`r`) REFERENCES `REGION`(`val`), FOREIGN KEY(`t`) REFERENCES `TECHNOLOGY`(`val`)" : "") * " )")
    SQLite.DBInterface.execute(db, "CREATE TABLE IF NOT EXISTS `TotalAnnualMaxCapacityInvestmentStorage` ( `id` INTEGER NOT NULL UNIQUE, `r` TEXT, `s` TEXT, `y` TEXT, `val` REAL, PRIMARY KEY(`id`)" * (foreignkeys ? ", FOREIGN KEY(`y`) REFERENCES `YEAR`(`val`), FOREIGN KEY(`r`) REFERENCES `REGION`(`val`), FOREIGN KEY(`s`) REFERENCES `STORAGE`(`val`)" : "") * " )")
    SQLite.DBInterface.execute(db, "CREATE TABLE IF NOT EXISTS `TotalAnnualMaxCapacity` ( `id` INTEGER NOT NULL UNIQUE, `r` TEXT, `t` TEXT, `y` TEXT, `val` REAL, PRIMARY KEY(`id`)" * (foreignkeys ? ", FOREIGN KEY(`t`) REFERENCES `TECHNOLOGY`(`val`), FOREIGN KEY(`r`) REFERENCES `REGION`(`val`), FOREIGN KEY(`y`) REFERENCES `YEAR`(`val`)" : "") * " )")
    SQLite.DBInterface.execute(db, "CREATE TABLE IF NOT EXISTS `TotalAnnualMaxCapacityStorage` ( `id` INTEGER NOT NULL UNIQUE, `r` TEXT, `s` TEXT, `y` TEXT, `val` REAL, PRIMARY KEY(`id`)" * (foreignkeys ? ", FOREIGN KEY(`s`) REFERENCES `STORAGE`(`val`), FOREIGN KEY(`r`) REFERENCES `REGION`(`val`), FOREIGN KEY(`y`) REFERENCES `YEAR`(`val`)" : "") * " )")
    SQLite.DBInterface.execute(db, "CREATE TABLE IF NOT EXISTS `TechnologyToStorage` ( `id` INTEGER NOT NULL UNIQUE, `r` TEXT, `t` TEXT, `s` TEXT, `m` TEXT, `val` REAL, PRIMARY KEY(`id`)" * (foreignkeys ? ", FOREIGN KEY(`t`) REFERENCES `TECHNOLOGY`(`val`), FOREIGN KEY(`m`) REFERENCES `MODE_OF_OPERATION`(`val`), FOREIGN KEY(`s`) REFERENCES `STORAGE`(`val`), FOREIGN KEY(`r`) REFERENCES `REGION`(`val`)" : "") * " )")
    SQLite.DBInterface.execute(db, "CREATE TABLE IF NOT EXISTS `TechnologyFromStorage` ( `id` INTEGER NOT NULL UNIQUE, `r` TEXT, `t` TEXT, `s` TEXT, `m` TEXT, `val` REAL, PRIMARY KEY(`id`)" * (foreignkeys ? ", FOREIGN KEY(`r`) REFERENCES `REGION`(`val`), FOREIGN KEY(`m`) REFERENCES `MODE_OF_OPERATION`(`val`), FOREIGN KEY(`s`) REFERENCES `STORAGE`(`val`), FOREIGN KEY(`t`) REFERENCES `TECHNOLOGY`(`val`)" : "") * " )")
    SQLite.DBInterface.execute(db, "CREATE TABLE IF NOT EXISTS `StorageMaxDischargeRate` ( `id` INTEGER NOT NULL UNIQUE, `r` TEXT, `s` TEXT, `val` REAL, PRIMARY KEY(`id`)" * (foreignkeys ? ", FOREIGN KEY(`r`) REFERENCES `REGION`(`val`), FOREIGN KEY(`s`) REFERENCES `STORAGE`(`val`)" : "") * " )")
    SQLite.DBInterface.execute(db, "CREATE TABLE IF NOT EXISTS `StorageMaxChargeRate` ( `id` INTEGER NOT NULL UNIQUE, `r` TEXT, `s` TEXT, `val` REAL, PRIMARY KEY(`id`)" * (foreignkeys ? ", FOREIGN KEY(`r`) REFERENCES `REGION`(`val`), FOREIGN KEY(`s`) REFERENCES `STORAGE`(`val`)" : "") * " )")
    SQLite.DBInterface.execute(db, "CREATE TABLE IF NOT EXISTS `StorageLevelStart` ( `id` INTEGER NOT NULL UNIQUE, `r` TEXT, `s` TEXT, `val` REAL, PRIMARY KEY(`id`)" * (foreignkeys ? ", FOREIGN KEY(`r`) REFERENCES `REGION`(`val`), FOREIGN KEY(`s`) REFERENCES `STORAGE`(`val`)" : "") * " )")
    SQLite.DBInterface.execute(db, "CREATE TABLE IF NOT EXISTS `StorageFullLoadHours` ( `id` INTEGER NOT NULL UNIQUE, `r` TEXT, `s` TEXT, `y` TEXT, `val` REAL, PRIMARY KEY(`id`)" * (foreignkeys ? ", FOREIGN KEY(`r`) REFERENCES `REGION`(`val`), FOREIGN KEY(`s`) REFERENCES `STORAGE`(`val`), FOREIGN KEY(`y`) REFERENCES `YEAR`(`val`)" : "") * " )")
    SQLite.DBInterface.execute(db, "CREATE TABLE IF NOT EXISTS `SpecifiedDemandProfile` ( `id` INTEGER NOT NULL UNIQUE, `r` TEXT, `f` TEXT, `l` TEXT, `y` TEXT, `val` REAL, PRIMARY KEY(`id`)" * (foreignkeys ? ", FOREIGN KEY(`f`) REFERENCES `FUEL`(`val`), FOREIGN KEY(`l`) REFERENCES `TIMESLICE`(`val`), FOREIGN KEY(`y`) REFERENCES `YEAR`(`val`), FOREIGN KEY(`r`) REFERENCES `REGION`(`val`)" : "") * " )")
    SQLite.DBInterface.execute(db, "CREATE TABLE IF NOT EXISTS `SpecifiedAnnualDemand` ( `id` INTEGER NOT NULL UNIQUE, `r` TEXT, `f` TEXT, `y` TEXT, `val` REAL, PRIMARY KEY(`id`)" * (foreignkeys ? ", FOREIGN KEY(`r`) REFERENCES `REGION`(`val`), FOREIGN KEY(`y`) REFERENCES `YEAR`(`val`), FOREIGN KEY(`f`) REFERENCES `FUEL`(`val`)" : "") * " )")
    SQLite.DBInterface.execute(db, "CREATE TABLE IF NOT EXISTS `ResidualStorageCapacity` ( `id` INTEGER NOT NULL UNIQUE, `r` TEXT, `s` TEXT, `y` TEXT, `val` REAL, PRIMARY KEY(`id`)" * (foreignkeys ? ", FOREIGN KEY(`r`) REFERENCES `REGION`(`val`), FOREIGN KEY(`s`) REFERENCES `STORAGE`(`val`), FOREIGN KEY(`y`) REFERENCES `YEAR`(`val`)" : "") * " )")
    SQLite.DBInterface.execute(db, "CREATE TABLE IF NOT EXISTS `ResidualCapacity` ( `id` INTEGER NOT NULL UNIQUE, `r` TEXT, `t` TEXT, `y` TEXT, `val` REAL, PRIMARY KEY(`id`)" * (foreignkeys ? ", FOREIGN KEY(`r`) REFERENCES `REGION`(`val`), FOREIGN KEY(`t`) REFERENCES `TECHNOLOGY`(`val`), FOREIGN KEY(`y`) REFERENCES `YEAR`(`val`)" : "") * " )")
    SQLite.DBInterface.execute(db, "CREATE TABLE IF NOT EXISTS `ReserveMarginTagTechnology` ( `id` INTEGER NOT NULL UNIQUE, `r` TEXT, `t` TEXT, `y` TEXT, `val` REAL, PRIMARY KEY(`id`)" * (foreignkeys ? ", FOREIGN KEY(`r`) REFERENCES `REGION`(`val`), FOREIGN KEY(`y`) REFERENCES `YEAR`(`val`), FOREIGN KEY(`t`) REFERENCES `TECHNOLOGY`(`val`)" : "") * " )")
    SQLite.DBInterface.execute(db, "CREATE TABLE IF NOT EXISTS `ReserveMarginTagFuel` ( `id` INTEGER NOT NULL UNIQUE, `r` TEXT, `f` TEXT, `y` TEXT, `val` REAL, PRIMARY KEY(`id`)" * (foreignkeys ? ", FOREIGN KEY(`f`) REFERENCES `FUEL`(`val`), FOREIGN KEY(`r`) REFERENCES `REGION`(`val`), FOREIGN KEY(`y`) REFERENCES `YEAR`(`val`)" : "") * " )")
    SQLite.DBInterface.execute(db, "CREATE TABLE IF NOT EXISTS `ReserveMargin` ( `id` INTEGER NOT NULL UNIQUE, `r` TEXT, `y` TEXT, `val` REAL, PRIMARY KEY(`id`)" * (foreignkeys ? ", FOREIGN KEY(`r`) REFERENCES `REGION`(`val`), FOREIGN KEY(`y`) REFERENCES `YEAR`(`val`)" : "") * " )")
    SQLite.DBInterface.execute(db, "CREATE TABLE IF NOT EXISTS `RETagTechnology` ( `id` INTEGER NOT NULL UNIQUE, `r` TEXT, `t` TEXT, `y` TEXT, `val` REAL, PRIMARY KEY(`id`)" * (foreignkeys ? ", FOREIGN KEY(`r`) REFERENCES `REGION`(`val`), FOREIGN KEY(`y`) REFERENCES `YEAR`(`val`), FOREIGN KEY(`t`) REFERENCES `TECHNOLOGY`(`val`)" : "") * " )")
    SQLite.DBInterface.execute(db, "CREATE TABLE IF NOT EXISTS `RETagFuel` ( `id` INTEGER NOT NULL UNIQUE, `r` TEXT, `f` TEXT, `y` TEXT, `val` REAL, PRIMARY KEY(`id`)" * (foreignkeys ? ", FOREIGN KEY(`y`) REFERENCES `YEAR`(`val`), FOREIGN KEY(`f`) REFERENCES `FUEL`(`val`), FOREIGN KEY(`r`) REFERENCES `REGION`(`val`)" : "") * " )")
    SQLite.DBInterface.execute(db, "CREATE TABLE IF NOT EXISTS `REMinProductionTarget` ( `id` INTEGER NOT NULL UNIQUE, `r` TEXT, `y` TEXT, `val` REAL, PRIMARY KEY(`id`)" * (foreignkeys ? ", FOREIGN KEY(`y`) REFERENCES `YEAR`(`val`), FOREIGN KEY(`r`) REFERENCES `REGION`(`val`)" : "") * " )")
    SQLite.DBInterface.execute(db, "CREATE TABLE IF NOT EXISTS `OutputActivityRatio` ( `id` INTEGER NOT NULL UNIQUE, `r` TEXT, `t` TEXT, `f` TEXT, `m` TEXT, `y` TEXT, `val` REAL, PRIMARY KEY(`id`)" * (foreignkeys ? ", FOREIGN KEY(`m`) REFERENCES `MODE_OF_OPERATION`(`val`), FOREIGN KEY(`t`) REFERENCES `TECHNOLOGY`(`val`), FOREIGN KEY(`f`) REFERENCES `FUEL`(`val`), FOREIGN KEY(`r`) REFERENCES `REGION`(`val`), FOREIGN KEY(`y`) REFERENCES `YEAR`(`val`)" : "") * " )")
    SQLite.DBInterface.execute(db, "CREATE TABLE IF NOT EXISTS `OperationalLifeStorage` ( `id` INTEGER NOT NULL UNIQUE, `r` TEXT, `s` TEXT, `val` REAL, PRIMARY KEY(`id`)" * (foreignkeys ? ", FOREIGN KEY(`s`) REFERENCES `STORAGE`(`val`), FOREIGN KEY(`r`) REFERENCES `REGION`(`val`)" : "") * " )")
    SQLite.DBInterface.execute(db, "CREATE TABLE IF NOT EXISTS `OperationalLife` ( `id` INTEGER NOT NULL UNIQUE, `r` TEXT, `t` TEXT, `val` REAL, PRIMARY KEY(`id`)" * (foreignkeys ? ", FOREIGN KEY(`t`) REFERENCES `TECHNOLOGY`(`val`), FOREIGN KEY(`r`) REFERENCES `REGION`(`val`)" : "") * " )")
    SQLite.DBInterface.execute(db, "CREATE TABLE IF NOT EXISTS `NodalDistributionTechnologyCapacity` ( `id` INTEGER, `n` TEXT, `t` TEXT, `y` TEXT, `val` REAL, PRIMARY KEY(`id`)" * (foreignkeys ? ", FOREIGN KEY(`t`) REFERENCES `TECHNOLOGY`(`val`), FOREIGN KEY(`y`) REFERENCES `YEAR`(`val`), FOREIGN KEY(`n`) REFERENCES `NODE`(`val`)" : "") * " )")
    SQLite.DBInterface.execute(db, "CREATE TABLE IF NOT EXISTS `NodalDistributionStorageCapacity` ( `id` INTEGER, `n` TEXT, `s` TEXT, `y` TEXT, `val` REAL, PRIMARY KEY(`id`)" * (foreignkeys ? ", FOREIGN KEY(`n`) REFERENCES `NODE`(`val`), FOREIGN KEY(`s`) REFERENCES `STORAGE`(`val`), FOREIGN KEY(`y`) REFERENCES `YEAR`(`val`)" : "") * " )")
    SQLite.DBInterface.execute(db, "CREATE TABLE IF NOT EXISTS `NodalDistributionDemand` ( `id` INTEGER, `n` TEXT, `f` TEXT, `y` TEXT, `val` REAL, PRIMARY KEY(`id`)" * (foreignkeys ? ", FOREIGN KEY(`f`) REFERENCES `FUEL`(`val`), FOREIGN KEY(`y`) REFERENCES `YEAR`(`val`), FOREIGN KEY(`n`) REFERENCES `NODE`(`val`)" : "") * " )")
    SQLite.DBInterface.execute(db, "CREATE TABLE IF NOT EXISTS `ModelPeriodExogenousEmission` ( `id` INTEGER NOT NULL UNIQUE, `r` TEXT, `e` TEXT, `val` REAL, PRIMARY KEY(`id`)" * (foreignkeys ? ", FOREIGN KEY(`e`) REFERENCES `EMISSION`(`val`), FOREIGN KEY(`r`) REFERENCES `REGION`(`val`)" : "") * " )")
    SQLite.DBInterface.execute(db, "CREATE TABLE IF NOT EXISTS `ModelPeriodEmissionLimit` ( `id` INTEGER NOT NULL UNIQUE, `r` TEXT, `e` TEXT, `val` REAL, PRIMARY KEY(`id`)" * (foreignkeys ? ", FOREIGN KEY(`e`) REFERENCES `EMISSION`(`val`), FOREIGN KEY(`r`) REFERENCES `REGION`(`val`)" : "") * " )")
    SQLite.DBInterface.execute(db, "CREATE TABLE IF NOT EXISTS `MinStorageCharge` ( `id` INTEGER NOT NULL UNIQUE, `r` TEXT, `s` TEXT, `y` TEXT, `val` REAL, PRIMARY KEY(`id`)" * (foreignkeys ? ", FOREIGN KEY(`r`) REFERENCES `REGION`(`val`), FOREIGN KEY(`s`) REFERENCES `STORAGE`(`val`), FOREIGN KEY(`y`) REFERENCES `YEAR`(`val`)" : "") * " )")
    SQLite.DBInterface.execute(db, "CREATE TABLE IF NOT EXISTS `LTsGroup` ( `id` INTEGER PRIMARY KEY AUTOINCREMENT, `l` TEXT UNIQUE,	`lorder` INTEGER, `tg2` TEXT, `tg1` TEXT" * (foreignkeys ? ", FOREIGN KEY(`l`) REFERENCES `TIMESLICE`(`val`), FOREIGN KEY(`tg2`) REFERENCES `TSGROUP2`(`name`), FOREIGN KEY(`tg1`) REFERENCES `TSGROUP1`(`name`)" : "") * " )")
    SQLite.DBInterface.execute(db, "CREATE TABLE IF NOT EXISTS `InputActivityRatio` ( `id` INTEGER NOT NULL UNIQUE, `r` TEXT, `t` TEXT, `f` TEXT, `m` TEXT, `y` TEXT, `val` REAL, PRIMARY KEY(`id`)" * (foreignkeys ? ", FOREIGN KEY(`y`) REFERENCES `YEAR`(`val`), FOREIGN KEY(`m`) REFERENCES `MODE_OF_OPERATION`(`val`), FOREIGN KEY(`f`) REFERENCES `FUEL`(`val`), FOREIGN KEY(`t`) REFERENCES `TECHNOLOGY`(`val`), FOREIGN KEY(`r`) REFERENCES `REGION`(`val`)" : "") * " )")
    SQLite.DBInterface.execute(db, "CREATE TABLE IF NOT EXISTS `FixedCost` ( `id` INTEGER NOT NULL UNIQUE, `r` TEXT, `t` TEXT, `y` TEXT, `val` REAL, PRIMARY KEY(`id`)" * (foreignkeys ? ", FOREIGN KEY(`t`) REFERENCES `TECHNOLOGY`(`val`), FOREIGN KEY(`r`) REFERENCES `REGION`(`val`), FOREIGN KEY(`y`) REFERENCES `YEAR`(`val`)" : "") * " )")
    SQLite.DBInterface.execute(db, "CREATE TABLE IF NOT EXISTS `EmissionsPenalty` ( `id` INTEGER NOT NULL UNIQUE, `r` TEXT, `e` TEXT, `y` TEXT, `val` REAL, PRIMARY KEY(`id`)" * (foreignkeys ? ", FOREIGN KEY(`r`) REFERENCES `REGION`(`val`), FOREIGN KEY(`y`) REFERENCES `YEAR`(`val`), FOREIGN KEY(`e`) REFERENCES `EMISSION`(`val`)" : "") * " )")
    SQLite.DBInterface.execute(db, "CREATE TABLE IF NOT EXISTS `EmissionActivityRatio` ( `id` INTEGER NOT NULL UNIQUE, `r` TEXT, `t` TEXT, `e` TEXT, `m` TEXT, `y` TEXT, `val` REAL, PRIMARY KEY(`id`)" * (foreignkeys ? ", FOREIGN KEY(`r`) REFERENCES `REGION`(`val`), FOREIGN KEY(`t`) REFERENCES `TECHNOLOGY`(`val`), FOREIGN KEY(`y`) REFERENCES `YEAR`(`val`), FOREIGN KEY(`m`) REFERENCES `MODE_OF_OPERATION`(`val`), FOREIGN KEY(`e`) REFERENCES `EMISSION`(`val`)" : "") * " )")
    SQLite.DBInterface.execute(db, "CREATE TABLE IF NOT EXISTS `DiscountRate` ( `id` INTEGER NOT NULL UNIQUE, `r` TEXT, `val` REAL, PRIMARY KEY(`id`)" * (foreignkeys ? ", FOREIGN KEY(`r`) REFERENCES `REGION`(`val`)" : "") * " )")
    SQLite.DBInterface.execute(db, "CREATE TABLE IF NOT EXISTS `DepreciationMethod` ( `id` INTEGER NOT NULL UNIQUE, `r` TEXT, `val` REAL, PRIMARY KEY(`id`)" * (foreignkeys ? ", FOREIGN KEY(`r`) REFERENCES `REGION`(`val`)" : "") * " )")
    SQLite.DBInterface.execute(db, "CREATE TABLE IF NOT EXISTS `CapitalCostStorage` ( `id` INTEGER NOT NULL UNIQUE, `r` TEXT, `s` TEXT, `y` TEXT, `val` REAL, PRIMARY KEY(`id`)" * (foreignkeys ? ", FOREIGN KEY(`s`) REFERENCES `STORAGE`(`val`), FOREIGN KEY(`r`) REFERENCES `REGION`(`val`), FOREIGN KEY(`y`) REFERENCES `YEAR`(`val`)" : "") * " )")
    SQLite.DBInterface.execute(db, "CREATE TABLE IF NOT EXISTS `CapitalCost` ( `id` INTEGER NOT NULL UNIQUE, `r` TEXT, `t` TEXT, `y` TEXT, `val` REAL, PRIMARY KEY(`id`)" * (foreignkeys ? ", FOREIGN KEY(`t`) REFERENCES `TECHNOLOGY`(`val`), FOREIGN KEY(`y`) REFERENCES `YEAR`(`val`), FOREIGN KEY(`r`) REFERENCES `REGION`(`val`)" : "") * " )")
    SQLite.DBInterface.execute(db, "CREATE TABLE IF NOT EXISTS `CapacityToActivityUnit` ( `id` INTEGER NOT NULL UNIQUE, `r` TEXT, `t` TEXT, `val` REAL, PRIMARY KEY(`id`)" * (foreignkeys ? ", FOREIGN KEY(`t`) REFERENCES `TECHNOLOGY`(`val`), FOREIGN KEY(`r`) REFERENCES `REGION`(`val`)" : "") * " )")
    SQLite.DBInterface.execute(db, "CREATE TABLE IF NOT EXISTS `CapacityOfOneTechnologyUnit` ( `id` INTEGER NOT NULL UNIQUE, `r` TEXT, `t` TEXT, `y` TEXT, `val` REAL, PRIMARY KEY(`id`)" * (foreignkeys ? ", FOREIGN KEY(`r`) REFERENCES `REGION`(`val`), FOREIGN KEY(`y`) REFERENCES `YEAR`(`val`), FOREIGN KEY(`t`) REFERENCES `TECHNOLOGY`(`val`)" : "") * " )")
    SQLite.DBInterface.execute(db, "CREATE TABLE IF NOT EXISTS `CapacityFactor` ( `id` INTEGER NOT NULL UNIQUE, `r` TEXT, `t` TEXT, `l` TEXT, `y` TEXT, `val` REAL, PRIMARY KEY(`id`)" * (foreignkeys ? ", FOREIGN KEY(`y`) REFERENCES `YEAR`(`val`), FOREIGN KEY(`r`) REFERENCES `REGION`(`val`), FOREIGN KEY(`t`) REFERENCES `TECHNOLOGY`(`val`), FOREIGN KEY(`l`) REFERENCES `TIMESLICE`(`val`)" : "") * " )")
    SQLite.DBInterface.execute(db, "CREATE TABLE IF NOT EXISTS `AvailabilityFactor` ( `id` INTEGER NOT NULL UNIQUE, `r` TEXT, `t` TEXT, `y` TEXT, `val` REAL, PRIMARY KEY(`id`)" * (foreignkeys ? ", FOREIGN KEY(`y`) REFERENCES `YEAR`(`val`), FOREIGN KEY(`r`) REFERENCES `REGION`(`val`), FOREIGN KEY(`t`) REFERENCES `TECHNOLOGY`(`val`)" : "") * " )")
    SQLite.DBInterface.execute(db, "CREATE TABLE IF NOT EXISTS `AnnualExogenousEmission` ( `id` INTEGER NOT NULL UNIQUE, `r` TEXT, `e` TEXT, `y` TEXT, `val` REAL, PRIMARY KEY(`id`)" * (foreignkeys ? ", FOREIGN KEY(`r`) REFERENCES `REGION`(`val`), FOREIGN KEY(`y`) REFERENCES `YEAR`(`val`), FOREIGN KEY(`e`) REFERENCES `EMISSION`(`val`)" : "") * " )")
    SQLite.DBInterface.execute(db, "CREATE TABLE IF NOT EXISTS `AnnualEmissionLimit` ( `id` INTEGER NOT NULL UNIQUE, `r` TEXT, `e` TEXT, `y` TEXT, `val` REAL, PRIMARY KEY(`id`)" * (foreignkeys ? ", FOREIGN KEY(`y`) REFERENCES `YEAR`(`val`), FOREIGN KEY(`e`) REFERENCES `EMISSION`(`val`), FOREIGN KEY(`r`) REFERENCES `REGION`(`val`)" : "") * " )")
    SQLite.DBInterface.execute(db, "CREATE TABLE IF NOT EXISTS `AccumulatedAnnualDemand` ( `id` INTEGER NOT NULL UNIQUE, `r` TEXT, `f` TEXT, `y` TEXT, `val` REAL, PRIMARY KEY(`id`)" * (foreignkeys ? ", FOREIGN KEY(`f`) REFERENCES `FUEL`(`val`), FOREIGN KEY(`y`) REFERENCES `YEAR`(`val`), FOREIGN KEY(`r`) REFERENCES `REGION`(`val`)" : "") * " )")
    # END: Add new NEMO tables.

    # BEGIN: Write default values to DefaultParams.
    for (k, v) in defaultvals
        SQLite.DBInterface.execute(db, "INSERT INTO DefaultParams (tablename, val) values('" * k * "', " * string(v) * ")")
    end
    # END: Write default values to DefaultParams.

    SQLite.DBInterface.execute(db, "COMMIT")
    SQLite.DBInterface.execute(db, "VACUUM")

    logmsg("Added NEMO structure to SQLite database at " * path * ".")
    # END: DDL operations in an SQLite transaction.

    # Return configured database
    return db
end  # createnemodb(path::String, defaultvals::Dict{String, Float64} = Dict{String, Float64}())

"""
    createnemodb_leap(path::String)

Creates an empty NEMO SQLite database with parameter defaults set to values used in LEAP
(and no foreign keys). If specified database already exists, drops and recreates NEMO tables
in database.

# Arguments
- `path::String`: Full path to database, including database name.
"""
function createnemodb_leap(path::String)
    # BEGIN: Specify default parameter values.
    defaultvals::Dict{String, Float64} = Dict{String, Float64}()  # Default values to be passed to createnemodb

    defaultvals["VariableCost"] = 0.0
    defaultvals["TradeRoute"] = 0.0
    defaultvals["TotalAnnualMinCapacityInvestment"] = 0.0
    defaultvals["TotalAnnualMinCapacity"] = 0.0
    defaultvals["TotalAnnualMaxCapacityInvestment"] = 10000000000.0
    defaultvals["TotalAnnualMaxCapacity"] = 10000000000.0
    defaultvals["TechnologyToStorage"] = 0.0
    defaultvals["TechnologyFromStorage"] = 0.0
    defaultvals["StorageMaxDischargeRate"] = 99.0
    defaultvals["StorageMaxChargeRate"] = 99.0
    defaultvals["StorageLevelStart"] = 999.0
    defaultvals["SpecifiedDemandProfile"] = 0.0
    defaultvals["SpecifiedAnnualDemand"] = 0.0
    defaultvals["ResidualStorageCapacity"] = 999.0
    defaultvals["ResidualCapacity"] = 0.0
    defaultvals["ReserveMarginTagTechnology"] = 0.0
    defaultvals["ReserveMarginTagFuel"] = 0.0
    defaultvals["ReserveMargin"] = 0.0
    defaultvals["RETagTechnology"] = 0.0
    defaultvals["RETagFuel"] = 0.0
    defaultvals["REMinProductionTarget"] = 0.0
    defaultvals["OutputActivityRatio"] = 0.0
    defaultvals["OperationalLifeStorage"] = 99.0
    defaultvals["OperationalLife"] = 1.0
    defaultvals["ModelPeriodExogenousEmission"] = 0.0
    defaultvals["ModelPeriodEmissionLimit"] = 1000000000000.0
    defaultvals["MinStorageCharge"] = 0.0
    defaultvals["InputActivityRatio"] = 0.0
    defaultvals["FixedCost"] = 0.0
    defaultvals["EmissionsPenalty"] = 0.0
    defaultvals["EmissionActivityRatio"] = 0.0
    defaultvals["DiscountRate"] = 0.05
    defaultvals["DepreciationMethod"] = 1.0
    defaultvals["CapitalCostStorage"] = 0.0
    defaultvals["CapitalCost"] = 0.0
    defaultvals["CapacityToActivityUnit"] = 31.536
    defaultvals["CapacityOfOneTechnologyUnit"] = 0.0
    defaultvals["CapacityFactor"] = 1.0
    defaultvals["AvailabilityFactor"] = 1.0
    defaultvals["AnnualExogenousEmission"] = 0.0
    defaultvals["AnnualEmissionLimit"] = 10000000000.0
    defaultvals["AccumulatedAnnualDemand"] = 0.0
    # END: Specify default parameter values.

    # Call createnemodb()
    createnemodb(path; defaultvals = defaultvals)
end  # createnemodb_leap(path::String)

"""
    setparamdefault(db::SQLite.DB, table::String, val::Float64)

Sets the default value for a parameter table in a NEMO scenario database.

# Arguments
- `db::SQLite.DB`: Scenario database containing the parameter table.
- `table::String`: Table name (case-sensitive).
- `val::Float64`: Parameter value (must be a floating-point number).
"""
function setparamdefault(db::SQLite.DB, table::String, val::Float64)
    # Add value to DefaultParams table - INSERT OR REPLACE syntax replaces any existing value
    SQLite.DBInterface.execute(db, "INSERT OR REPLACE INTO DefaultParams (tablename, val) values('" * table * "', " * string(val) * ")")

    # Update view showing default values for table
    createviewwithdefaults(db, [table])
    logmsg("Updated default value for parameter " * table * ". New default = " * string(val) * ".")
end  # setparamdefault(db::SQLite.DB, table::String, val::Float64)

# Demonstration function - performance is too poor for production use
#=
function createconstraint(model::JuMP.Model, logname::String, constraintref::Array{JuMP.ConstraintRef,1}, rows::DataFrames.DFRowIterator,
    keyfields::Array{String,1}, lh::String, operator::String, rh::String)

    local constraintnum = 1  # Number of next constraint to be added to constraint array
    global row = Void  # Row in subsequent iteration; needs to be defined as global to be accessible in eval statements

    for rw in rows
        row = rw

        for kf in keyfields
            eval(parse(kf * " = row[:" * kf * "]"))
        end

        if operator == "=="
            constraintref[constraintnum] = @constraint(model, eval(parse(lh)) == eval(parse(rh)))
        elseif operator == "<="
            constraintref[constraintnum] = @constraint(model, eval(parse(lh)) <= eval(parse(rh)))
        elseif operator == ">="
            constraintref[constraintnum] = @constraint(model, eval(parse(lh)) >= eval(parse(rh)))
        end

        constraintnum += 1
    end

    logmsg("Created constraint " * logname * ".")
end  # createconstraint
=#

"""
    createviewwithdefaults(db::SQLite.DB, tables::Array{String,1})

For each parameter table identified in `tables`, creates a view that explicitly shows the default value
for the `val` column, if one is available. View name = [table name]  * "_def". Table names are case-
sensitive."""
function createviewwithdefaults(db::SQLite.DB, tables::Array{String,1})
    try
        # BEGIN: SQLite transaction.
        SQLite.DBInterface.execute(db, "BEGIN")

        for t in tables
            local hasdefault::Bool = false  # Indicates whether val column in t has a default value
            local defaultval  # Default value for val column in t, if column has a default value
            local pks::Array{String,1} = Array{String,1}()  # Names of foreign key fields in t
            local defaultqry::DataFrame  # Query of DefaultParams table for t's default value
            local createviewstmt::String  # Create view SQL statement that will be executed for t

            # Delete view if existing already
            SQLite.DBInterface.execute(db,"drop view if exists " * t * "_def")

            # BEGIN: Determine foreign key fields in t.
            for row in SQLite.DBInterface.execute(db, "PRAGMA table_info('" * t *"')")
                local rowname::String = row[:name]  # Value in name field for row

                if rowname == "id" || rowname == "val"
                    continue
                else
                    push!(pks,rowname)
                end
            end
            # END: Determine foreign key fields in t.

            # BEGIN: Determine default value for t.
            defaultqry = SQLite.DBInterface.execute(db, "select * from DefaultParams where tablename = '" * t * "'") |> DataFrame

            if size(defaultqry)[1] >= 1
                defaultval = defaultqry[!, :val][1]

                # Some special handling here to avoid creating large views where they're not necessary, given NEMO's logic
                if (t == "OutputActivityRatio" || t == "InputActivityRatio") && defaultval == 0.0
                    # OutputActivityRatio and InputActivityRatio are only used when != 0, so can ignore a default value of 0
                    hasdefault = false
                else
                    hasdefault = true
                end
            end
            # END: Determine default value for t.

            # BEGIN: Create unique index on t for foreign key fields.
            # This step significantly improves performance for many queries on new view for t
            SQLite.DBInterface.execute(db,"drop index if exists " * t * "_fks_unique")
            SQLite.DBInterface.execute(db,"create unique index " * t * "_fks_unique on " * t * " (" * join(pks, ",") * ")")
            # END: Create unique index on t for foreign key fields.

            if hasdefault
                # Join to foreign key tables with default specified
                local outerfieldsclause::String = ""  # Dynamic fields clause for create view outer select
                local innerfieldsclause::String = ""  # Dynamic fields clause for create view inner select
                local fromclause::String = ""  # Dynamic from clause for create view inner select
                local leftjoinclause::String = ""  # Dynamic left join criteria for create view inner select

                for f in pks
                    outerfieldsclause = outerfieldsclause * f * ", "
                    innerfieldsclause = innerfieldsclause * f * "_tab.val as " * f * ", "
                    fromclause = fromclause * translatesetabb(f) * " as " * f * "_tab, "
                    leftjoinclause = leftjoinclause * "t." * f * " = " * f * "_tab.val and "
                end

                innerfieldsclause = innerfieldsclause * "t.val as val "
                fromclause = fromclause[1:end-2] * " "
                leftjoinclause = leftjoinclause[1:end-4]

                createviewstmt = "create view " * t * "_def as select " * outerfieldsclause * "ifnull(val," * string(defaultval) * ") as val from (select " * innerfieldsclause * "from " * fromclause * "left join " * t * " t on " * leftjoinclause * ")"
            else
                # No default value, so view with defaults is a simple copy of t
                createviewstmt = "create view " * t * "_def as select * from " * t
            end

            # println("createviewstmt = " * createviewstmt)
            SQLite.DBInterface.execute(db, createviewstmt)
        end

        SQLite.DBInterface.execute(db, "COMMIT")
        # END: SQLite transaction.
    catch
        # Rollback transaction and rethrow error
        SQLite.DBInterface.execute(db, "ROLLBACK")
        rethrow()
    end
end  # createviewwithdefaults(db::SQLite.DB, tables::Array{String,1})

"""
    dropdefaultviews(db::SQLite.DB)

Drops all views in `db` whose name ends with ""_def""."""
function dropdefaultviews(db::SQLite.DB)
    try
        # BEGIN: SQLite transaction.
        SQLite.DBInterface.execute(db, "BEGIN")

        for row in SQLite.DBInterface.execute(db, "select name from sqlite_master where type = 'view'")
            if endswith(row[:name], "_def")
                SQLite.DBInterface.execute(db, "DROP VIEW " * row[:name])
            end
        end

        SQLite.DBInterface.execute(db, "COMMIT")
        SQLite.DBInterface.execute(db, "VACUUM")
        # END: SQLite transaction.
    catch
        # Rollback transaction and rethrow error
        SQLite.DBInterface.execute(db, "ROLLBACK")
        rethrow()
    end
end  # dropdefaultviews(db::SQLite.DB)

"""
    create_other_nemo_indices(db::SQLite.DB)

Creates miscellaneous indices needed by NEMO."""
function create_other_nemo_indices(db::SQLite.DB)
    try
        # BEGIN: SQLite transaction.
        SQLite.DBInterface.execute(db, "BEGIN")

        SQLite.DBInterface.execute(db, "CREATE UNIQUE INDEX IF NOT EXISTS `TransmissionModelingEnabled_fks_unique` ON `TransmissionModelingEnabled` ( `r`, `f`, `y` )")

        SQLite.DBInterface.execute(db, "COMMIT")
        # END: SQLite transaction.
    catch
        # Rollback transaction and rethrow error
        SQLite.DBInterface.execute(db, "ROLLBACK")
        rethrow()
    end
end  # create_other_nemo_indices(db::SQLite.DB)

"""
    savevarresults(vars::Array{String,1},
    modelvarindices::Dict{String, Tuple{JuMP.JuMPContainer,Array{String,1}}},
    db::SQLite.DB, solvedtmstr::String, quiet::Bool = false)

Saves model results to a SQLite database using SQL inserts with transaction batching.

# Arguments
- `vars::Array{String,1}`: Names of model variables for which results will be retrieved and saved to database.
- `modelvarindices::Dict{String, Tuple{JuMP.JuMPContainer,Array{String,1}}}`: Dictionary mapping model variable names
    to tuples of (variable, [index column names]).
- `db::SQLite.DB`: SQLite database.
- `solvedtmstr::String`: String to write into solvedtm field in result tables.
- `reportzeros::Bool`: Indicates whether values equal to 0 should be saved.
- `quiet::Bool = false`: Suppresses low-priority status messages (which are otherwise printed to STDOUT).
"""
function savevarresults(vars::Array{String,1}, modelvarindices::Dict{String, Tuple{JuMP.JuMPContainer,Array{String,1}}}, db::SQLite.DB, solvedtmstr::String,
    reportzeros::Bool = false, quiet::Bool = false)
    for vname in intersect(vars, keys(modelvarindices))
        local v = modelvarindices[vname][1]  # Model variable corresponding to vname
        local gvv = JuMP.getvalue(v)  # Value of v in model solution
        local indices::Array{Tuple}  # Array of tuples of index values for v
        local vals::Array{Float64}  # Array of model results for v

        # Populate indices and vals
        if v isa JuMP.JuMPArray
            indices = collect(Base.product(gvv.indexsets...))  # Ellipsis splices indexsets into its values for passing to product()
            vals = gvv.innerArray
        elseif v isa JuMP.JuMPDict
            indices = collect(keys(gvv.tupledict))
            vals = collect(values(gvv.tupledict))
        end

        # BEGIN: Wrap database operations in try-catch block to allow rollback on error.
        try
            # Begin SQLite transaction
            SQLite.DBInterface.execute(db, "BEGIN")

            # Create target table for v (drop any existing table for v)
            SQLite.DBInterface.execute(db,"drop table if exists " * vname)

            SQLite.DBInterface.execute(db, "create table '" * vname * "' ('" * join(modelvarindices[vname][2], "' text, '") * "' text, 'val' real, 'solvedtm' text)")

            # Insert data from gvv
            for i = 1:length(vals)
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
end  # savevarresults(vars::Array{String,1}, modelvarindices::Dict{String, Tuple{JuMP.JuMPContainer,Array{String,1}}}, db::SQLite.DB, solvedtmstr::String)

"""
    dropresulttables(db::SQLite.DB, quiet::Bool = true)

Drops all tables in `db` whose name begins with ""v"" or ""sqlite_stat"" (both case-sensitive).
    The `quiet` parameter determines whether most status messages are suppressed.
"""
function dropresulttables(db::SQLite.DB, quiet::Bool = true)
    # BEGIN: Wrap database operations in try-catch block to allow rollback on error.
    try
        # Begin SQLite transaction
        SQLite.DBInterface.execute(db, "BEGIN")

        for tname in SQLite.tables(db).name
            if tname[1:1] == "v" || (length(tname) >= 11 && tname[1:11] == "sqlite_stat")
                SQLite.DBInterface.execute(db, "drop table " * tname)
                logmsg("Dropped table " * tname * ".", quiet)
            end
        end

        # Complete SQLite transaction
        SQLite.DBInterface.execute(db, "COMMIT")
    catch
        # Rollback db transaction
        SQLite.DBInterface.execute(db, "ROLLBACK")

        # Proceed with normal Julia error sequence
        rethrow()
    end
    # END: Wrap database operations in try-catch block to allow rollback on error.
end  # dropresulttables(db::SQLite.DB)

"""
    getvars(varnames::Array{String, 1})

Returns an array of model variables corresponding to the names in `varnames`. Excludes any variables not convertible to
    `JuMP.JuMPContainer`.
"""
function getvars(varnames::Array{String, 1})
    local returnval::Array{JuMP.JuMPContainer, 1} = Array{JuMP.JuMPContainer, 1}()  # Function's return value

    for v in varnames
        try
            push!(returnval, Core.eval(@__MODULE__, Symbol(v)))
        catch ex
            throw(ex)
        end
    end

    return returnval
end  # getvars(varnames::Array{String, 1})

"""
    checkactivityupperlimits(db::SQLite.DB, tolerance::Float64)

For the scenario specified in `db`, checks whether there are:
    1) Any TotalTechnologyAnnualActivityUpperLimit values that are <= tolerance times the maximum
        annual demand
    2) Any TotalTechnologyModelPeriodActivityUpperLimit values that are <= tolerance times the maximum
        annual demand times the number of years in the scenario
Returns a `Tuple` of Booleans whose first value is the result of the first check, and whose second
    value is the result of the second.
"""
function checkactivityupperlimits(db::SQLite.DB, tolerance::Float64)
    local annual::Bool = true  # Return value indicating whether there are any TotalTechnologyAnnualActivityUpperLimit
        # values that are <= tolerance x maximum annual demand in scenario
    local modelperiod::Bool = true  # Return value indicating whether there are any TotalTechnologyModelPeriodActivityUpperLimit
        # values that are <= tolerance x maximum annual demand x # of years in scenario
    local qry::DataFrame  # Working query
    local maxdemand::Float64  # Maximum annual demand in scenario

    qry = SQLite.DBInterface.execute(db, "select max(mv) as mv from
    (select max(val) as mv from AccumulatedAnnualDemand_def
    union
    select max(val) as mv from SpecifiedAnnualDemand_def)") |> DataFrame

    maxdemand = qry[!,1][1]

    qry = SQLite.DBInterface.execute(db, "select tau.val from TotalTechnologyAnnualActivityUpperLimit_def tau
        where tau.val / :v1 <= :v2", [maxdemand, tolerance]) |> DataFrame

    if size(qry)[1] == 0
        annual = false
    end

    qry = SQLite.DBInterface.execute(db, "select tmu.val from TotalTechnologyModelPeriodActivityUpperLimit_def tmu
      where tmu.val / (:v1 * (select count(val) from year)) <= :v2", [maxdemand, tolerance]) |> DataFrame

    if size(qry)[1] == 0
      modelperiod = false
    end

    return (annual, modelperiod)
end  # checkactivityupperlimits(db::SQLite.DB, tolerance::Float64)

"""
    scenario_calc_queries()

Returns a `Dict` of query commands used in NEMO's `calculatescenario` function. Each key in the return value is
    a query name, and each value is a `Tuple` whose first element is the query's SQL command and whose second
    element is the query's type in `calculatescenario`. Two types are supported: `"query"` for `SQLite.Query`
    objects and `"dataframe"` for `DataFrames.DataFrame` objects."""
function scenario_calc_queries()
    return_val::Dict{String, Tuple{String, String}} = Dict{String, Tuple{String, String}}()  # Return value for this function; map of query names
    #   tuples of (SQL command, type). Type can be "query" for SQLite.Query or "dataframe" for DataFrames.DataFrame.

    return_val["queryannualactivitylowerlimit"] = ("select r, t, y, cast(val as real) as amn
    from TotalTechnologyAnnualActivityLowerLimit_def
    where val > 0", "query")

    return_val["querymodelperiodactivitylowerlimit"] = ("select r, t, cast(val as real) as mmn
    from TotalTechnologyModelPeriodActivityLowerLimit_def
    where val > 0", "query")

    return_val["technology"] = ("select val, desc from technology", "dataframe")

    return_val["timeslice"] = ("select val, desc from timeslice", "dataframe")

    return return_val
end  # scenario_calc_queries()

function run_qry(qtpl)
    local result = SQLite.DBInterface.execute(SQLite.DB(csdbpath), qtpl[1])

    if qtpl[2] == "dataframe"
        result = result |> DataFrame
    end

    return result
end  # run_qry(query_string)



# Upgrades NEMO database from version 2 to version 3 by adding TransmissionLine.efficiency.
function db_v2_to_v3(db::SQLite.DB; quiet::Bool = false)
    # BEGIN: Wrap database operations in try-catch block to allow rollback on error.
    try
        # BEGIN: SQLite transaction.
        SQLite.DBInterface.execute(db, "BEGIN")

        qry::DataFrame = SQLite.DBInterface.execute(db, "PRAGMA table_info('TransmissionLine')") |> DataFrame
        updatetl::Bool = !in("efficiency", qry.name)

        if updatetl
            SQLite.DBInterface.execute(db, "alter table TransmissionLine rename to TransmissionLine_old")
            SQLite.DBInterface.execute(db, "CREATE TABLE IF NOT EXISTS `TransmissionLine` ( `id` TEXT, `n1` TEXT, `n2` TEXT, `f` TEXT, `maxflow` REAL, `reactance` REAL, `yconstruction` INTEGER, `capitalcost` REAL, `fixedcost` REAL, `variablecost` REAL, `operationallife` INTEGER, `efficiency` REAL, PRIMARY KEY(`id`) )")
            SQLite.DBInterface.execute(db, "insert into TransmissionLine select id, n1, n2, f, maxflow, reactance, yconstruction, capitalcost, fixedcost, variablecost, operationallife, 1.0 from TransmissionLine_old")
            SQLite.DBInterface.execute(db, "drop table TransmissionLine_old")
            SQLite.DBInterface.execute(db, "update version set version = 3")
        end

        SQLite.DBInterface.execute(db, "COMMIT")
        # END: SQLite transaction.

        updatetl && logmsg("Upgraded database to version 3.", quiet)
    catch
        # Rollback transaction and rethrow error
        SQLite.DBInterface.execute(db, "ROLLBACK")
        rethrow()
    end
    # END: Wrap database operations in try-catch block to allow rollback on error.
end  # db_v2_to_v3(db::SQLite.DB; quiet::Bool = false)

# Upgrades NEMO database from version 3 to version 4 by adding TransmissionCapacityToActivityUnit.r.
function db_v3_to_v4(db::SQLite.DB; quiet::Bool = false)
    # BEGIN: Wrap database operations in try-catch block to allow rollback on error.
    try
        # BEGIN: SQLite transaction.
        SQLite.DBInterface.execute(db, "BEGIN")

        qry::DataFrame = SQLite.DBInterface.execute(db, "PRAGMA table_info('TransmissionCapacityToActivityUnit')") |> DataFrame
        updatetcta::Bool = !in("r", qry.name)

        if updatetcta
            SQLite.DBInterface.execute(db, "alter table TransmissionCapacityToActivityUnit rename to TransmissionCapacityToActivityUnit_old")
            SQLite.DBInterface.execute(db, "CREATE TABLE IF NOT EXISTS `TransmissionCapacityToActivityUnit` ( `id` INTEGER NOT NULL UNIQUE, `r` TEXT, `f` TEXT, `val` REAL, PRIMARY KEY(`id`) )")
            SQLite.DBInterface.execute(db, "insert into TransmissionCapacityToActivityUnit select tcta.id, r.val, tcta.f, tcta.val from TransmissionCapacityToActivityUnit_old tcta, REGION r")
            SQLite.DBInterface.execute(db, "drop table TransmissionCapacityToActivityUnit_old")
            SQLite.DBInterface.execute(db, "update version set version = 4")
        end

        SQLite.DBInterface.execute(db, "COMMIT")
        # END: SQLite transaction.

        updatetcta && logmsg("Upgraded database to version 4.", quiet)
    catch
        # Rollback transaction and rethrow error
        SQLite.DBInterface.execute(db, "ROLLBACK")
        rethrow()
    end
    # END: Wrap database operations in try-catch block to allow rollback on error.
end  # db_v3_to_v4(db::SQLite.DB; quiet::Bool = false)
