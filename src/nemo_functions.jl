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

Loads run-time arguments for `calculatescenario()` from a configuration file.

# Arguments
- `configfile::ConfParse`: Configuration file. This argument is not changed by the function.
- `varstosavearr::Array{String,1}`: Array representation of `calculatescenario()` `varstosave` argument.
    New values in configuration file are added to this array.
- `targetprocs::Array{Int,1}`: `calculatescenario()` `targetprocs` argument. New values in configuration
    file are added to this array.
- `bools::Array{Bool,1}`: Array of Boolean arguments for `calculatescenario()`: `restrictvars`, `reportzeros`,
    `continuoustransmission`, and `quiet`, in that order. New values in configuration file overwrite values
    in this array.
- `ints::Array{Int,1}`: Array of `Int` arguments for `calculatescenario()`: `numprocs`. New values in
    configuration file overwrite values in this array.
- `quiet::Bool = false`: Suppresses low-priority status messages (which are otherwise printed to `STDOUT`).
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
    SQLite.DBInterface.execute(db,"drop table if exists RampRate")
    SQLite.DBInterface.execute(db,"drop table if exists RampingReset")
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
    #   - 5: Added RampRate and RampingReset
    SQLite.DBInterface.execute(db, "CREATE TABLE `Version` (`version` INTEGER, PRIMARY KEY(`version`))")
    SQLite.DBInterface.execute(db, "INSERT INTO Version VALUES(5)")

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
    SQLite.DBInterface.execute(db, "CREATE TABLE IF NOT EXISTS `RampingReset` (`id` INTEGER NOT NULL UNIQUE, `r` TEXT, `val` INTEGER, PRIMARY KEY(`id`)" * (foreignkeys ? ", FOREIGN KEY(`r`) REFERENCES `REGION`(`val`)" : "") * " )")
    SQLite.DBInterface.execute(db, "CREATE TABLE IF NOT EXISTS `RampRate` (`id` INTEGER NOT NULL UNIQUE, `r` TEXT, `t` TEXT, `y` TEXT, `l` TEXT, `val` REAL, PRIMARY KEY(`id`)" * (foreignkeys ? ", FOREIGN KEY(`r`) REFERENCES `REGION`(`val`), FOREIGN KEY(`t`) REFERENCES `TECHNOLOGY`(`val`), FOREIGN KEY(`y`) REFERENCES `YEAR`(`val`), FOREIGN KEY(`l`) REFERENCES `TIMESLICE`(`val`)" : "") * " )")
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
    create_temp_tables(db::SQLite.DB)

Creates temporary tables needed when NEMO is calculating a scenario. These tables are not created as SQLite temporary tables
    in order to make them simultaneously visible to multiple Julia processes."""
function create_temp_tables(db::SQLite.DB)
    try
        # BEGIN: SQLite transaction.
        SQLite.DBInterface.execute(db, "BEGIN")

        SQLite.DBInterface.execute(db, "DROP TABLE IF EXISTS nodalstorage")

        # nodalstorage is used as a filter in nodal and non-nodal storage modeling
        SQLite.DBInterface.execute(db, "create table nodalstorage as
        select distinct n.r as r, nsc.n as n, nsc.s as s, nsc.y as y, nsc.val as val
        from NodalDistributionStorageCapacity_def nsc, node n,
            NodalDistributionTechnologyCapacity_def ntc, TransmissionModelingEnabled tme,
            (select r, t, f, m, y from OutputActivityRatio_def
            where val <> 0
            union
            select r, t, f, m, y from InputActivityRatio_def
            where val <> 0) ar,
            (select r, t, s, m from TechnologyFromStorage_def where val = 1
            union
            select r, t, s, m from TechnologyToStorage_def where val = 1) ts
        where nsc.val > 0
        and n.val = nsc.n
        and ntc.val > 0 and ntc.n = nsc.n and ntc.t = ar.t and ntc.y = nsc.y
        and tme.r = n.r and tme.f = ar.f and tme.y = nsc.y
        and ar.r = n.r and ar.y = nsc.y
        and ts.r = n.r and ts.t = ntc.t and ts.s = nsc.s and ts.m = ar.m")

        SQLite.DBInterface.execute(db, "COMMIT")
        # END: SQLite transaction.
    catch
        # Rollback transaction and rethrow error
        SQLite.DBInterface.execute(db, "ROLLBACK")
        rethrow()
    end
end  # create_temp_tables(db::SQLite.DB)

"""
    drop_temp_tables(db::SQLite.DB)

Drops temporary tables created in `create_temp_tables()`."""
function drop_temp_tables(db::SQLite.DB)
    # BEGIN: SQLite transaction.
    SQLite.DBInterface.execute(db, "BEGIN")

    SQLite.DBInterface.execute(db, "DROP TABLE IF EXISTS nodalstorage")

    SQLite.DBInterface.execute(db, "COMMIT")
    # END: SQLite transaction.
end  # drop_temp_tables(db::SQLite.DB)

"""
    savevarresults(vars::Array{String,1},
    modelvarindices::Dict{String, Tuple{AbstractArray,Array{String,1}}},
    db::SQLite.DB, solvedtmstr::String, reportzeros::Bool = false, quiet::Bool = false)

Saves model results to a SQLite database using SQL inserts with transaction batching.

# Arguments
- `vars::Array{String,1}`: Names of model variables for which results will be retrieved and saved to database.
- `modelvarindices::Dict{String, Tuple{AbstractArray,Array{String,1}}}`: Dictionary mapping model variable names
    to tuples of (variable, [index column names]).
- `db::SQLite.DB`: SQLite database.
- `solvedtmstr::String`: String to write into solvedtm field in result tables.
- `reportzeros::Bool`: Indicates whether values equal to 0 should be saved.
- `quiet::Bool = false`: Suppresses low-priority status messages (which are otherwise printed to STDOUT).
"""
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
end  # savevarresults(vars::Array{String,1}, modelvarindices::Dict{String, Tuple{AbstractArray,Array{String,1}}}, db::SQLite.DB, solvedtmstr::String)

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
    scenario_calc_queries(dbpath::String, transmissionmodeling::Bool, vproductionbytechnologysaved::Bool,
        vusebytechnologysaved::Bool)

Returns a `Dict` of query commands used in NEMO's `calculatescenario` function. Each key in the return value is
    a query name, and each value is a `Tuple` where:
        - Element 1 = path to NEMO scenario database in which to execute query (taken from `dbpath` argument)
        - Element 2 = query's SQL statement
    The function's Boolean arguments restrict the set of returned query commands as noted below.

# Arguments
- `dbpath::String`: Path to NEMO scenario database in which query commands should be executed.
- `transmissionmodeling::Bool`: Indicates whether transmission modeling is enabled in `calculatescenario`.
    Additional query commands are included in results when transmission modeling is enabled.
- `vproductionbytechnologysaved::Bool`: Indicates whether output variable `vproductionbytechnology`
    will be saved in `calculatescenario`. Additional query commands are included in results when this argument
    and `transmissionmodeling` are true.
- `vusebytechnologysaved::Bool`: Indicates whether output variable `vusebytechnology`
    will be saved in `calculatescenario`. Additional query commands are included in results when this argument
    and `transmissionmodeling` are true."""
function scenario_calc_queries(dbpath::String, transmissionmodeling::Bool, vproductionbytechnologysaved::Bool,
    vusebytechnologysaved::Bool)

    return_val::Dict{String, Tuple{String, String}} = Dict{String, Tuple{String, String}}()  # Return value for this function; map of query names
    #   to tuples of (DB path, SQL command)

    return_val["queryvrateofproductionbytechnologybymodenn"] = (dbpath, "select r.val as r, ys.l as l, t.val as t, m.val as m, f.val as f, y.val as y,
    cast(oar.val as real) as oar
    from region r, YearSplit_def ys, technology t, MODE_OF_OPERATION m, fuel f, year y, OutputActivityRatio_def oar
    left join TransmissionModelingEnabled tme on tme.r = r.val and tme.f = f.val and tme.y = y.val
    where oar.r = r.val and oar.t = t.val and oar.f = f.val and oar.m = m.val and oar.y = y.val
    and oar.val <> 0
    and ys.y = y.val
    and tme.id is null
    order by r.val, ys.l, t.val, f.val, y.val")

    return_val["queryvrateofproductionbytechnologynn"] = (dbpath, "select r.val as r, ys.l as l, t.val as t, f.val as f, y.val as y, cast(ys.val as real) as ys
    from region r, YearSplit_def ys, technology t, fuel f, year y,
    (select distinct r, t, f, y
    from OutputActivityRatio_def
    where val <> 0) oar
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
    where val <> 0) oar
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
    where val <> 0) oar
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
    order by r.val, ys.l, t.val, f.val, y.val")

    return_val["queryvrateofusebytechnologynn"] = (dbpath, "select
    r.val as r, ys.l as l, t.val as t, f.val as f, y.val as y, cast(ys.val as real) as ys
    from region r, YearSplit_def ys, technology t, fuel f, year y,
    (select distinct r, t, f, y from InputActivityRatio_def where val <> 0) iar
    left join TransmissionModelingEnabled tme on tme.r = r.val and tme.f = f.val and tme.y = y.val
    where iar.r = r.val and iar.t = t.val and iar.f = f.val and iar.y = y.val
    and ys.y = y.val
    and tme.id is null
    order by r.val, ys.l, f.val, y.val")

    return_val["queryvusebytechnologyannual"] = (dbpath, "select * from (
    select r.val as r, t.val as t, f.val as f, y.val as y, null as n, ys.l as l,
    cast(ys.val as real) as ys
    from region r, technology t, fuel f, year y, YearSplit_def ys,
    (select distinct r, t, f, y from InputActivityRatio_def where val <> 0) iar
    left join TransmissionModelingEnabled tme on tme.r = r.val and tme.f = f.val and tme.y = y.val
    where iar.r = r.val and iar.t = t.val and iar.f = f.val and iar.y = y.val
    and ys.y = y.val
    and tme.id is null
    union all
    select n.r as r, ntc.t as t, iar.f as f, ntc.y as y, ntc.n as n, ys.l as l,
    cast(ys.val as real) as ys
    from NodalDistributionTechnologyCapacity_def ntc, NODE n,
    TransmissionModelingEnabled tme, YearSplit_def ys,
    (select distinct r, t, f, y from InputActivityRatio_def where val <> 0) iar
    where ntc.val > 0
    and ntc.n = n.val
    and tme.r = n.r and tme.f = iar.f and tme.y = ntc.y
    and iar.r = n.r and iar.t = ntc.t and iar.y = ntc.y
    and ntc.y = ys.y
    )
    order by r, t, f, y")

    return_val["querycaa5_totalnewcapacity"] = (dbpath, "select cot.r as r, cot.t as t, cot.y as y, cast(cot.val as real) as cot
    from CapacityOfOneTechnologyUnit_def cot where cot.val <> 0")

    if transmissionmodeling
        return_val["queryvrateofactivitynodal"] = (dbpath, "select ntc.n as n, l.val as l, ntc.t as t, ar.m as m, ntc.y as y
        from NodalDistributionTechnologyCapacity_def ntc, node n,
        	TransmissionModelingEnabled tme, TIMESLICE l,
        (select r, t, f, m, y from OutputActivityRatio_def
        where val <> 0
        union
        select r, t, f, m, y from InputActivityRatio_def
        where val <> 0) ar
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
        where val <> 0) oar
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
        where val <> 0) iar
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
            where val <> 0) oar
            where ntc.val > 0
            and ntc.y = ys.y
            and ntc.n = n.val
            and tme.r = n.r and tme.f = oar.f and tme.y = ntc.y
            and oar.r = n.r and oar.t = ntc.t and oar.y = ntc.y")
        end

        if vusebytechnologysaved
            return_val["queryvusebytechnologyindices_nodalpart"] = (dbpath, "select distinct n.r as r, ys.l as l, ntc.t as t, iar.f as f, ntc.y as y, null as ys
            from NodalDistributionTechnologyCapacity_def ntc, YearSplit_def ys, NODE n,
            TransmissionModelingEnabled tme,
            (select distinct r, t, f, y
            from InputActivityRatio_def
            where val <> 0) iar
            where ntc.val > 0
            and ntc.y = ys.y
            and ntc.n = n.val
            and tme.r = n.r and tme.f = iar.f and tme.y = ntc.y
            and iar.r = n.r and iar.t = ntc.t and iar.y = ntc.y")
        end

        return_val["queryvtransmissionbyline"] = (dbpath, "select tl.id as tr, ys.l as l, tl.f as f, tme1.y as y, tl.n1 as n1, tl.n2 as n2,
    	tl.reactance as reactance, tme1.type as type, tl.maxflow as maxflow,
        cast(tl.VariableCost as real) as vc, cast(ys.val as real) as ys,
        cast(tl.fixedcost as real) as fc, cast(tcta.val as real) as tcta
        from TransmissionLine tl, NODE n1, NODE n2, TransmissionModelingEnabled tme1,
        TransmissionModelingEnabled tme2, YearSplit_def ys, TransmissionCapacityToActivityUnit_def tcta
        where
        tl.n1 = n1.val and tl.n2 = n2.val
        and tme1.r = n1.r and tme1.f = tl.f
        and tme2.r = n2.r and tme2.f = tl.f
        and tme1.y = tme2.y and tme1.type = tme2.type
    	and ys.y = tme1.y
    	and tl.f = tcta.f
        order by tl.id, tme1.y")

        return_val["queryvstorageleveltsgroup1"] = (dbpath, "select ns.n as n, ns.s as s, tg1.name as tg1, ns.y as y
        from nodalstorage ns, TSGROUP1 tg1")

        return_val["queryvstorageleveltsgroup2"] = (dbpath, "select ns.n as n, ns.s as s, tg1.name as tg1, tg2.name as tg2, ns.y as y
        from nodalstorage ns, TSGROUP1 tg1, TSGROUP2 tg2")

        return_val["queryvstoragelevelts"] = (dbpath, "select ns.n as n, ns.s as s, l.val as l, ns.y as y
        from nodalstorage ns, TIMESLICE l")
    end  # transmissionmodeling

    return return_val
end  # scenario_calc_queries(dbpath::String)

"""
    run_qry(qtpl::Tuple{String, String})

Runs the SQLite database query specified in `qtpl` and returns the result as a DataFrame.
    Element 1 in `qtpl` should be the path to the SQLite database, and element 2 should be the query's
    SQL command. Designed to work with the output of `scenario_calc_queries` in a `map` or `pmap` call."""
function run_qry(qtpl::Tuple{String, String})
    return SQLite.DBInterface.execute(SQLite.DB(qtpl[1]), qtpl[2]) |> DataFrame
end  # run_qry(qtpl::Tuple{String, String, String})

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

# Upgrades NEMO database from version 4 to version 5 by adding RampRate and RampingReset.
function db_v4_to_v5(db::SQLite.DB; quiet::Bool = false)
    # BEGIN: Wrap database operations in try-catch block to allow rollback on error.
    try
        # BEGIN: SQLite transaction.
        SQLite.DBInterface.execute(db, "BEGIN")
        dbchanged::Bool = false  # Indicates whether db has been modified in this function

        qry::SQLite.Query = SQLite.DBInterface.execute(db, "PRAGMA table_info('RampRate')")

        if SQLite.done(qry)
            SQLite.DBInterface.execute(db, "CREATE TABLE `RampRate` (`id` INTEGER NOT NULL UNIQUE, `r` TEXT, `t` TEXT, `y` TEXT, `l` TEXT, `val` REAL, PRIMARY KEY(`id`))")
            dbchanged = true
        end

        qry = SQLite.DBInterface.execute(db, "PRAGMA table_info('RampingReset')")

        if SQLite.done(qry)
            SQLite.DBInterface.execute(db, "CREATE TABLE `RampingReset` (`id` INTEGER NOT NULL UNIQUE, `r` TEXT, `val` INTEGER, PRIMARY KEY(`id`))")
            dbchanged = true
        end

        SQLite.DBInterface.execute(db, "update version set version = 5")

        SQLite.DBInterface.execute(db, "COMMIT")
        # END: SQLite transaction.

        dbchanged && logmsg("Upgraded database to version 5.", quiet)
    catch
        # Rollback transaction and rethrow error
        SQLite.DBInterface.execute(db, "ROLLBACK")
        rethrow()
    end
    # END: Wrap database operations in try-catch block to allow rollback on error.
end  # db_v4_to_v5(db::SQLite.DB; quiet::Bool = false)
