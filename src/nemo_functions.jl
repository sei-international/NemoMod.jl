#=
    NEMO: Next-generation Energy Modeling system for Optimization.
    https://github.com/sei-international/NemoMod.jl

    Copyright © 2018: Stockholm Environment Institute U.S.

    Release 0.1.2: NEMO-OSeMOSYS.

    File description: Main function library for NEMO.
=#

"""Prints a log message (msg) to STDOUT. The message is suppressed if suppress = true."""
function logmsg(msg::String, suppress=false, dtm=now()::DateTime)
    suppress && return
    println(stdout, Dates.format(dtm, @dateformat_str "YYYY-dd-u HH:MM:SS.sss ") * msg)
end  # logmsg(msg::String)

"""Translates an OSeMOSYS set abbreviation (a) into the set's name."""
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
    elseif a == "ls"
        return "SEASON"
    elseif a == "ld"
        return "DAYTYPE"
    elseif a == "lh"
        return "DAILYTIMEBRACKET"
    elseif a == "s"
        return "STORAGE"
    elseif a == "l"
        return "TIMESLICE"
    else
        return a
    end
end  # translatesetabb(a::String)

"""Generates Dicts that can be used to restrict JuMP constraints or variables to selected indices
(rather than all values in their dimensions) at creation. Requires two arguments:
    1) df - The results of a query that selects the index values.
    2) numdicts - The number of Dicts that should be created.  The first Dict is for the first field in
        the query, the second is for the first two fields in the query, and so on.  Dict keys are arrays
        of the values of the key fields to which the Dict corresponds, and Dict values are Sets of corresponding
        values in the next field of the query (field #2 for the first Dict, field #3 for the second Dict, and so on).
Returns an array of the generated Dicts."""
function keydicts(df::DataFrames.DataFrame, numdicts::Int)
    local returnval = Array{Dict{Array{String,1},Set{String}},1}()  # Function return value

    # Set up empty dictionaries in returnval
    for i in 1:numdicts
        push!(returnval, Dict{Array{String,1},Set{String}}())
    end

    # Populate dictionaries using df
    for row in eachrow(df)
        for j in 1:numdicts
            if !haskey(returnval[j], [row[k] for k = 1:j])
                returnval[j][[row[k] for k = 1:j]] = Set{String}()
            end

            push!(returnval[j][[row[k] for k = 1:j]], row[j+1])
        end
    end

    return returnval
end  # keydicts(df::DataFrames.DataFrame, numdicts::Int)

"""Runs keydicts using parallel processes identified in targetprocs. If there are not at least 10,000 rows in df for each
target process, resorts to running keydicts on process that called keydicts_parallel."""
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
        local results = Array{typeof(returnval), 1}(np)  # Collection of results from async processing

        # Dispatch async tasks in main process, each of which performs a remotecall_fetch on an available process. Wrap in sync block to wait until all async processes
        #   finish before proceeding.
        @sync begin
            for p=1:np
                @async begin
                    # Pass each process a block of rows from df
                    results[p] = remotecall_fetch(keydicts, availprocs[p], df[((p-1) * blockdivrem[1] + 1):((p) * blockdivrem[1] + (p == np ? blockdivrem[2] : 0)),:], numdicts)
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
createconstraint(m, "TestConstraint", abc, eachrow(SQLite.query(db, "select t.val as t from technology t limit 10")), ["t"], "vtest[t]", ">=", "0")
=#

"""Creates an empty NEMO SQLite database. Arguments:
    • path - Full path to database, including database name.
    • defaultvals - Dictionary of table names and default values for val column.
If specified database already exists, drops and recreates NEMO tables in database."""
function createnemodb(path::String, defaultvals::Dict{String, Float64} = Dict{String, Float64}())
    # Open SQLite database
    local db::SQLite.DB = SQLite.DB(path)
    logmsg("Opened SQLite database at " * path * ".")

    # BEGIN: DDL operations in an SQLite transaction.
    SQLite.execute!(db, "BEGIN")

    # BEGIN: Drop any existing NEMO tables.
    SQLite.execute!(db,"drop table if exists AccumulatedAnnualDemand")
    SQLite.execute!(db,"drop table if exists AnnualEmissionLimit")
    SQLite.execute!(db,"drop table if exists AnnualExogenousEmission")
    SQLite.execute!(db,"drop table if exists AvailabilityFactor")
    SQLite.execute!(db,"drop table if exists CapacityFactor")
    SQLite.execute!(db,"drop table if exists CapacityOfOneTechnologyUnit")
    SQLite.execute!(db,"drop table if exists CapacityToActivityUnit")
    SQLite.execute!(db,"drop table if exists CapitalCost")
    SQLite.execute!(db,"drop table if exists CapitalCostStorage")
    SQLite.execute!(db,"drop table if exists Conversionld")
    SQLite.execute!(db,"drop table if exists Conversionlh")
    SQLite.execute!(db,"drop table if exists Conversionls")
    SQLite.execute!(db,"drop table if exists DaySplit")
    SQLite.execute!(db,"drop table if exists DaysInDayType")
    SQLite.execute!(db,"drop table if exists DepreciationMethod")
    SQLite.execute!(db,"drop table if exists DiscountRate")
    SQLite.execute!(db,"drop table if exists DiscountRateStorage")
    SQLite.execute!(db,"drop table if exists EmissionActivityRatio")
    SQLite.execute!(db,"drop table if exists EmissionsPenalty")
    SQLite.execute!(db,"drop table if exists FixedCost")
    SQLite.execute!(db,"drop table if exists InputActivityRatio")
    SQLite.execute!(db,"drop table if exists MinStorageCharge")
    SQLite.execute!(db,"drop table if exists ModelPeriodEmissionLimit")
    SQLite.execute!(db,"drop table if exists ModelPeriodExogenousEmission")
    SQLite.execute!(db,"drop table if exists OperationalLife")
    SQLite.execute!(db,"drop table if exists OperationalLifeStorage")
    SQLite.execute!(db,"drop table if exists OutputActivityRatio")
    SQLite.execute!(db,"drop table if exists REMinProductionTarget")
    SQLite.execute!(db,"drop table if exists RETagFuel")
    SQLite.execute!(db,"drop table if exists RETagTechnology")
    SQLite.execute!(db,"drop table if exists ReserveMargin")
    SQLite.execute!(db,"drop table if exists ReserveMarginTagFuel")
    SQLite.execute!(db,"drop table if exists ReserveMarginTagTechnology")
    SQLite.execute!(db,"drop table if exists ResidualCapacity")
    SQLite.execute!(db,"drop table if exists ResidualStorageCapacity")
    SQLite.execute!(db,"drop table if exists SpecifiedAnnualDemand")
    SQLite.execute!(db,"drop table if exists SpecifiedDemandProfile")
    SQLite.execute!(db,"drop table if exists StorageLevelStart")
    SQLite.execute!(db,"drop table if exists StorageMaxChargeRate")
    SQLite.execute!(db,"drop table if exists StorageMaxDischargeRate")
    SQLite.execute!(db,"drop table if exists TechWithCapacityNeededToMeetPeakTS")
    SQLite.execute!(db,"drop table if exists TechnologyFromStorage")
    SQLite.execute!(db,"drop table if exists TechnologyToStorage")
    SQLite.execute!(db,"drop table if exists TotalAnnualMaxCapacity")
    SQLite.execute!(db,"drop table if exists TotalAnnualMaxCapacityInvestment")
    SQLite.execute!(db,"drop table if exists TotalAnnualMinCapacity")
    SQLite.execute!(db,"drop table if exists TotalAnnualMinCapacityInvestment")
    SQLite.execute!(db,"drop table if exists TotalTechnologyAnnualActivityLowerLimit")
    SQLite.execute!(db,"drop table if exists TotalTechnologyAnnualActivityUpperLimit")
    SQLite.execute!(db,"drop table if exists TotalTechnologyModelPeriodActivityLowerLimit")
    SQLite.execute!(db,"drop table if exists TotalTechnologyModelPeriodActivityUpperLimit")
    SQLite.execute!(db,"drop table if exists TradeRoute")
    SQLite.execute!(db,"drop table if exists VariableCost")
    SQLite.execute!(db,"drop table if exists YearSplit")

    SQLite.execute!(db,"drop table if exists DAILYTIMEBRACKET")
    SQLite.execute!(db,"drop table if exists DAYTYPE")
    SQLite.execute!(db,"drop table if exists REGION")
    SQLite.execute!(db,"drop table if exists YEAR")
    SQLite.execute!(db,"drop table if exists TECHNOLOGY")
    SQLite.execute!(db,"drop table if exists TIMESLICE")
    SQLite.execute!(db,"drop table if exists SEASON")
    SQLite.execute!(db,"drop table if exists STORAGE")
    SQLite.execute!(db,"drop table if exists MODE_OF_OPERATION")
    SQLite.execute!(db,"drop table if exists EMISSION")
    SQLite.execute!(db,"drop table if exists FUEL")
    # END: Drop any existing NEMO tables.

    # BEGIN: Add new NEMO tables.
    # No default values for sets/dimensions
    SQLite.execute!(db, "CREATE TABLE IF NOT EXISTS `DAYTYPE` ( `val` TEXT NOT NULL UNIQUE, PRIMARY KEY(`val`) )")
    SQLite.execute!(db, "CREATE TABLE IF NOT EXISTS `DAILYTIMEBRACKET` ( `val` TEXT NOT NULL UNIQUE, PRIMARY KEY(`val`) )")
    SQLite.execute!(db, "CREATE TABLE IF NOT EXISTS `EMISSION` ( `val` TEXT NOT NULL UNIQUE, PRIMARY KEY(`val`) )")
    SQLite.execute!(db, "CREATE TABLE IF NOT EXISTS `FUEL` ( `val` TEXT NOT NULL UNIQUE, PRIMARY KEY(`val`) )")
    SQLite.execute!(db, "CREATE TABLE IF NOT EXISTS `MODE_OF_OPERATION` (`val` TEXT NOT NULL UNIQUE, PRIMARY KEY(`val`))")
    SQLite.execute!(db, "CREATE TABLE IF NOT EXISTS `REGION` (`val` TEXT NOT NULL UNIQUE, PRIMARY KEY(`val`))")
    SQLite.execute!(db, "CREATE TABLE IF NOT EXISTS `SEASON` ( `val` TEXT NOT NULL UNIQUE, PRIMARY KEY(`val`) )")
    SQLite.execute!(db, "CREATE TABLE IF NOT EXISTS `STORAGE` ( `val` TEXT NOT NULL UNIQUE, PRIMARY KEY(`val`) )")
    SQLite.execute!(db, "CREATE TABLE IF NOT EXISTS `TECHNOLOGY` (`val` TEXT NOT NULL UNIQUE, PRIMARY KEY(`val`))")
    SQLite.execute!(db, "CREATE TABLE IF NOT EXISTS `TIMESLICE` (`val` TEXT NOT NULL UNIQUE, PRIMARY KEY(`val`))")
    SQLite.execute!(db, "CREATE TABLE IF NOT EXISTS `YEAR` (`val` TEXT NOT NULL UNIQUE, PRIMARY KEY(`val`))")

    # Parameter tables include any requested default values
    SQLite.execute!(db, "CREATE TABLE IF NOT EXISTS `YearSplit` ( `id` INTEGER NOT NULL UNIQUE, `l` TEXT, `y` TEXT, `val` REAL" * (haskey(defaultvals, "YearSplit") ? " DEFAULT " * string(defaultvals["YearSplit"]) : "") * ", PRIMARY KEY(`id`), FOREIGN KEY(`y`) REFERENCES `YEAR`(`val`), FOREIGN KEY(`l`) REFERENCES `TIMESLICE`(`val`) )")
    SQLite.execute!(db, "CREATE TABLE IF NOT EXISTS `VariableCost` ( `id` INTEGER NOT NULL UNIQUE, `r` TEXT, `t` TEXT, `m` TEXT, `y` TEXT, `val` REAL" * (haskey(defaultvals, "VariableCost") ? " DEFAULT " * string(defaultvals["VariableCost"]) : "") * ", PRIMARY KEY(`id`), FOREIGN KEY(`t`) REFERENCES `TECHNOLOGY`(`val`), FOREIGN KEY(`m`) REFERENCES `MODE_OF_OPERATION`(`val`), FOREIGN KEY(`y`) REFERENCES `YEAR`(`val`), FOREIGN KEY(`r`) REFERENCES `REGION`(`val`) )")
    SQLite.execute!(db, "CREATE TABLE IF NOT EXISTS `TradeRoute` ( `id` INTEGER NOT NULL UNIQUE, `r` TEXT, `rr` TEXT, `f` TEXT, `y` TEXT, `val` REAL" * (haskey(defaultvals, "TradeRoute") ? " DEFAULT " * string(defaultvals["TradeRoute"]) : "") * ", FOREIGN KEY(`r`) REFERENCES `REGION`(`val`), FOREIGN KEY(`rr`) REFERENCES `REGION`(`val`), FOREIGN KEY(`y`) REFERENCES `YEAR`(`val`), PRIMARY KEY(`id`), FOREIGN KEY(`f`) REFERENCES `FUEL`(`val`) )")
    SQLite.execute!(db, "CREATE TABLE IF NOT EXISTS `TotalTechnologyModelPeriodActivityUpperLimit` ( `id` INTEGER NOT NULL UNIQUE, `r` TEXT, `t` TEXT, `val` REAL" * (haskey(defaultvals, "TotalTechnologyModelPeriodActivityUpperLimit") ? " DEFAULT " * string(defaultvals["TotalTechnologyModelPeriodActivityUpperLimit"]) : "") * ", FOREIGN KEY(`t`) REFERENCES `TECHNOLOGY`(`val`), PRIMARY KEY(`id`), FOREIGN KEY(`r`) REFERENCES `REGION`(`val`) )")
    SQLite.execute!(db, "CREATE TABLE IF NOT EXISTS `TotalTechnologyModelPeriodActivityLowerLimit` ( `id` INTEGER NOT NULL UNIQUE, `r` TEXT, `t` TEXT, `val` REAL" * (haskey(defaultvals, "TotalTechnologyModelPeriodActivityLowerLimit") ? " DEFAULT " * string(defaultvals["TotalTechnologyModelPeriodActivityLowerLimit"]) : "") * ", FOREIGN KEY(`t`) REFERENCES `TECHNOLOGY`(`val`), PRIMARY KEY(`id`), FOREIGN KEY(`r`) REFERENCES `REGION`(`val`) )")
    SQLite.execute!(db, "CREATE TABLE IF NOT EXISTS `TotalTechnologyAnnualActivityUpperLimit` ( `id` INTEGER NOT NULL UNIQUE, `r` TEXT, `t` TEXT, `y` TEXT, `val` REAL" * (haskey(defaultvals, "TotalTechnologyAnnualActivityUpperLimit") ? " DEFAULT " * string(defaultvals["TotalTechnologyAnnualActivityUpperLimit"]) : "") * ", PRIMARY KEY(`id`), FOREIGN KEY(`y`) REFERENCES `YEAR`(`val`), FOREIGN KEY(`t`) REFERENCES `TECHNOLOGY`(`val`), FOREIGN KEY(`r`) REFERENCES `REGION`(`val`) )")
    SQLite.execute!(db, "CREATE TABLE IF NOT EXISTS `TotalTechnologyAnnualActivityLowerLimit` ( `id` INTEGER NOT NULL UNIQUE, `r` TEXT, `t` TEXT, `y` TEXT, `val` REAL" * (haskey(defaultvals, "TotalTechnologyAnnualActivityLowerLimit") ? " DEFAULT " * string(defaultvals["TotalTechnologyAnnualActivityLowerLimit"]) : "") * ", FOREIGN KEY(`y`) REFERENCES `YEAR`(`val`), FOREIGN KEY(`t`) REFERENCES `TECHNOLOGY`(`val`), FOREIGN KEY(`r`) REFERENCES `REGION`(`val`), PRIMARY KEY(`id`) )")
    SQLite.execute!(db, "CREATE TABLE IF NOT EXISTS `TotalAnnualMinCapacityInvestment` ( `id` INTEGER NOT NULL UNIQUE, `r` TEXT, `t` TEXT, `y` TEXT, `val` REAL" * (haskey(defaultvals, "TotalAnnualMinCapacityInvestment") ? " DEFAULT " * string(defaultvals["TotalAnnualMinCapacityInvestment"]) : "") * ", FOREIGN KEY(`y`) REFERENCES `YEAR`(`val`), FOREIGN KEY(`r`) REFERENCES `REGION`(`val`), PRIMARY KEY(`id`), FOREIGN KEY(`t`) REFERENCES `TECHNOLOGY`(`val`) )")
    SQLite.execute!(db, "CREATE TABLE IF NOT EXISTS `TotalAnnualMinCapacity` ( `id` INTEGER NOT NULL UNIQUE, `r` TEXT, `t` TEXT, `y` TEXT, `val` REAL" * (haskey(defaultvals, "TotalAnnualMinCapacity") ? " DEFAULT " * string(defaultvals["TotalAnnualMinCapacity"]) : "") * ", FOREIGN KEY(`t`) REFERENCES `TECHNOLOGY`(`val`), FOREIGN KEY(`r`) REFERENCES `REGION`(`val`), FOREIGN KEY(`y`) REFERENCES `YEAR`(`val`), PRIMARY KEY(`id`) )")
    SQLite.execute!(db, "CREATE TABLE IF NOT EXISTS `TotalAnnualMaxCapacityInvestment` ( `id` INTEGER NOT NULL UNIQUE, `r` TEXT, `t` TEXT, `y` TEXT, `val` REAL" * (haskey(defaultvals, "TotalAnnualMaxCapacityInvestment") ? " DEFAULT " * string(defaultvals["TotalAnnualMaxCapacityInvestment"]) : "") * ", FOREIGN KEY(`y`) REFERENCES `YEAR`(`val`), FOREIGN KEY(`r`) REFERENCES `REGION`(`val`), PRIMARY KEY(`id`), FOREIGN KEY(`t`) REFERENCES `TECHNOLOGY`(`val`) )")
    SQLite.execute!(db, "CREATE TABLE IF NOT EXISTS `TotalAnnualMaxCapacity` ( `id` INTEGER NOT NULL UNIQUE, `r` TEXT, `t` TEXT, `y` TEXT, `val` REAL" * (haskey(defaultvals, "TotalAnnualMaxCapacity") ? " DEFAULT " * string(defaultvals["TotalAnnualMaxCapacity"]) : "") * ", FOREIGN KEY(`t`) REFERENCES `TECHNOLOGY`(`val`), FOREIGN KEY(`r`) REFERENCES `REGION`(`val`), PRIMARY KEY(`id`), FOREIGN KEY(`y`) REFERENCES `YEAR`(`val`) )")
    SQLite.execute!(db, "CREATE TABLE IF NOT EXISTS `TechnologyToStorage` ( `id` INTEGER NOT NULL UNIQUE, `r` TEXT, `t` TEXT, `s` TEXT, `m` TEXT, `val` REAL" * (haskey(defaultvals, "TechnologyToStorage") ? " DEFAULT " * string(defaultvals["TechnologyToStorage"]) : "") * ", FOREIGN KEY(`t`) REFERENCES `TECHNOLOGY`(`val`), FOREIGN KEY(`m`) REFERENCES `MODE_OF_OPERATION`(`val`), FOREIGN KEY(`s`) REFERENCES `STORAGE`(`val`), FOREIGN KEY(`r`) REFERENCES `REGION`(`val`), PRIMARY KEY(`id`) )")
    SQLite.execute!(db, "CREATE TABLE IF NOT EXISTS `TechnologyFromStorage` ( `id` INTEGER NOT NULL UNIQUE, `r` TEXT, `t` TEXT, `s` TEXT, `m` TEXT, `val` REAL" * (haskey(defaultvals, "TechnologyFromStorage") ? " DEFAULT " * string(defaultvals["TechnologyFromStorage"]) : "") * ", FOREIGN KEY(`r`) REFERENCES `REGION`(`val`), FOREIGN KEY(`m`) REFERENCES `MODE_OF_OPERATION`(`val`), FOREIGN KEY(`s`) REFERENCES `STORAGE`(`val`), PRIMARY KEY(`id`), FOREIGN KEY(`t`) REFERENCES `TECHNOLOGY`(`val`) )")
    SQLite.execute!(db, "CREATE TABLE IF NOT EXISTS `TechWithCapacityNeededToMeetPeakTS` ( `id` INTEGER NOT NULL UNIQUE, `r` TEXT, `t` TEXT, `val` REAL" * (haskey(defaultvals, "TechWithCapacityNeededToMeetPeakTS") ? " DEFAULT " * string(defaultvals["TechWithCapacityNeededToMeetPeakTS"]) : "") * ", FOREIGN KEY(`r`) REFERENCES `REGION`(`val`), FOREIGN KEY(`t`) REFERENCES `TECHNOLOGY`(`val`), PRIMARY KEY(`id`) )")
    SQLite.execute!(db, "CREATE TABLE IF NOT EXISTS `StorageMaxDischargeRate` ( `id` INTEGER NOT NULL UNIQUE, `r` TEXT, `s` TEXT, `val` REAL" * (haskey(defaultvals, "StorageMaxDischargeRate") ? " DEFAULT " * string(defaultvals["StorageMaxDischargeRate"]) : "") * ", PRIMARY KEY(`id`), FOREIGN KEY(`r`) REFERENCES `REGION`(`val`), FOREIGN KEY(`s`) REFERENCES `STORAGE`(`val`) )")
    SQLite.execute!(db, "CREATE TABLE IF NOT EXISTS `StorageMaxChargeRate` ( `id` INTEGER NOT NULL UNIQUE, `r` TEXT, `s` TEXT, `val` REAL" * (haskey(defaultvals, "StorageMaxChargeRate") ? " DEFAULT " * string(defaultvals["StorageMaxChargeRate"]) : "") * ", PRIMARY KEY(`id`), FOREIGN KEY(`r`) REFERENCES `REGION`(`val`), FOREIGN KEY(`s`) REFERENCES `STORAGE`(`val`) )")
    SQLite.execute!(db, "CREATE TABLE IF NOT EXISTS `StorageLevelStart` ( `id` INTEGER NOT NULL UNIQUE, `r` TEXT, `s` TEXT, `val` REAL" * (haskey(defaultvals, "StorageLevelStart") ? " DEFAULT " * string(defaultvals["StorageLevelStart"]) : "") * ", FOREIGN KEY(`r`) REFERENCES `REGION`(`val`), PRIMARY KEY(`id`), FOREIGN KEY(`s`) REFERENCES `STORAGE`(`val`) )")
    SQLite.execute!(db, "CREATE TABLE IF NOT EXISTS `SpecifiedDemandProfile` ( `id` INTEGER NOT NULL UNIQUE, `r` TEXT, `f` TEXT, `l` TEXT, `y` TEXT, `val` REAL" * (haskey(defaultvals, "SpecifiedDemandProfile") ? " DEFAULT " * string(defaultvals["SpecifiedDemandProfile"]) : "") * ", FOREIGN KEY(`f`) REFERENCES `FUEL`(`val`), FOREIGN KEY(`l`) REFERENCES `TIMESLICE`(`val`), FOREIGN KEY(`y`) REFERENCES `YEAR`(`val`), PRIMARY KEY(`id`), FOREIGN KEY(`r`) REFERENCES `REGION`(`val`) )")
    SQLite.execute!(db, "CREATE TABLE IF NOT EXISTS `SpecifiedAnnualDemand` ( `id` INTEGER NOT NULL UNIQUE, `r` TEXT, `f` TEXT, `y` TEXT, `val` REAL" * (haskey(defaultvals, "SpecifiedAnnualDemand") ? " DEFAULT " * string(defaultvals["SpecifiedAnnualDemand"]) : "") * ", PRIMARY KEY(`id`), FOREIGN KEY(`r`) REFERENCES `REGION`(`val`), FOREIGN KEY(`y`) REFERENCES `YEAR`(`val`), FOREIGN KEY(`f`) REFERENCES `FUEL`(`val`) )")
    SQLite.execute!(db, "CREATE TABLE IF NOT EXISTS `ResidualStorageCapacity` ( `id` INTEGER NOT NULL UNIQUE, `r` TEXT, `s` TEXT, `y` TEXT, `val` REAL" * (haskey(defaultvals, "ResidualStorageCapacity") ? " DEFAULT " * string(defaultvals["ResidualStorageCapacity"]) : "") * ", FOREIGN KEY(`r`) REFERENCES `REGION`(`val`), FOREIGN KEY(`s`) REFERENCES `STORAGE`(`val`), PRIMARY KEY(`id`), FOREIGN KEY(`y`) REFERENCES `YEAR`(`val`) )")
    SQLite.execute!(db, "CREATE TABLE IF NOT EXISTS `ResidualCapacity` ( `id` INTEGER NOT NULL UNIQUE, `r` TEXT, `t` TEXT, `y` TEXT, `val` REAL" * (haskey(defaultvals, "ResidualCapacity") ? " DEFAULT " * string(defaultvals["ResidualCapacity"]) : "") * ", FOREIGN KEY(`r`) REFERENCES `REGION`(`val`), PRIMARY KEY(`id`), FOREIGN KEY(`t`) REFERENCES `TECHNOLOGY`(`val`), FOREIGN KEY(`y`) REFERENCES `YEAR`(`val`) )")
    SQLite.execute!(db, "CREATE TABLE IF NOT EXISTS `ReserveMarginTagTechnology` ( `id` INTEGER NOT NULL UNIQUE, `r` TEXT, `t` TEXT, `y` TEXT, `val` REAL" * (haskey(defaultvals, "ReserveMarginTagTechnology") ? " DEFAULT " * string(defaultvals["ReserveMarginTagTechnology"]) : "") * ", FOREIGN KEY(`r`) REFERENCES `REGION`(`val`), FOREIGN KEY(`y`) REFERENCES `YEAR`(`val`), PRIMARY KEY(`id`), FOREIGN KEY(`t`) REFERENCES `TECHNOLOGY`(`val`) )")
    SQLite.execute!(db, "CREATE TABLE IF NOT EXISTS `ReserveMarginTagFuel` ( `id` INTEGER NOT NULL UNIQUE, `r` TEXT, `f` TEXT, `y` TEXT, `val` REAL" * (haskey(defaultvals, "ReserveMarginTagFuel") ? " DEFAULT " * string(defaultvals["ReserveMarginTagFuel"]) : "") * ", FOREIGN KEY(`f`) REFERENCES `FUEL`(`val`), FOREIGN KEY(`r`) REFERENCES `REGION`(`val`), PRIMARY KEY(`id`), FOREIGN KEY(`y`) REFERENCES `YEAR`(`val`) )")
    SQLite.execute!(db, "CREATE TABLE IF NOT EXISTS `ReserveMargin` ( `id` INTEGER NOT NULL UNIQUE, `r` TEXT, `y` TEXT, `val` REAL" * (haskey(defaultvals, "ReserveMargin") ? " DEFAULT " * string(defaultvals["ReserveMargin"]) : "") * ", PRIMARY KEY(`id`), FOREIGN KEY(`r`) REFERENCES `REGION`(`val`), FOREIGN KEY(`y`) REFERENCES `YEAR`(`val`) )")
    SQLite.execute!(db, "CREATE TABLE IF NOT EXISTS `RETagTechnology` ( `id` INTEGER NOT NULL UNIQUE, `r` TEXT, `t` TEXT, `y` TEXT, `val` REAL" * (haskey(defaultvals, "RETagTechnology") ? " DEFAULT " * string(defaultvals["RETagTechnology"]) : "") * ", FOREIGN KEY(`r`) REFERENCES `REGION`(`val`), PRIMARY KEY(`id`), FOREIGN KEY(`y`) REFERENCES `YEAR`(`val`), FOREIGN KEY(`t`) REFERENCES `TECHNOLOGY`(`val`) )")
    SQLite.execute!(db, "CREATE TABLE IF NOT EXISTS `RETagFuel` ( `id` INTEGER NOT NULL UNIQUE, `r` TEXT, `f` TEXT, `y` TEXT, `val` REAL" * (haskey(defaultvals, "RETagFuel") ? " DEFAULT " * string(defaultvals["RETagFuel"]) : "") * ", FOREIGN KEY(`y`) REFERENCES `YEAR`(`val`), FOREIGN KEY(`f`) REFERENCES `FUEL`(`val`), FOREIGN KEY(`r`) REFERENCES `REGION`(`val`), PRIMARY KEY(`id`) )")
    SQLite.execute!(db, "CREATE TABLE IF NOT EXISTS `REMinProductionTarget` ( `id` INTEGER NOT NULL UNIQUE, `r` TEXT, `y` TEXT, `val` REAL" * (haskey(defaultvals, "REMinProductionTarget") ? " DEFAULT " * string(defaultvals["REMinProductionTarget"]) : "") * ", PRIMARY KEY(`id`), FOREIGN KEY(`y`) REFERENCES `YEAR`(`val`), FOREIGN KEY(`r`) REFERENCES `REGION`(`val`) )")
    SQLite.execute!(db, "CREATE TABLE IF NOT EXISTS `OutputActivityRatio` ( `id` INTEGER NOT NULL UNIQUE, `r` TEXT, `t` TEXT, `f` TEXT, `m` TEXT, `y` TEXT, `val` REAL" * (haskey(defaultvals, "OutputActivityRatio") ? " DEFAULT " * string(defaultvals["OutputActivityRatio"]) : "") * ", FOREIGN KEY(`m`) REFERENCES `MODE_OF_OPERATION`(`val`), FOREIGN KEY(`t`) REFERENCES `TECHNOLOGY`(`val`), FOREIGN KEY(`f`) REFERENCES `FUEL`(`val`), PRIMARY KEY(`id`), FOREIGN KEY(`r`) REFERENCES `REGION`(`val`), FOREIGN KEY(`y`) REFERENCES `YEAR`(`val`) )")
    SQLite.execute!(db, "CREATE TABLE IF NOT EXISTS `OperationalLifeStorage` ( `id` INTEGER NOT NULL UNIQUE, `r` TEXT, `s` TEXT, `val` REAL" * (haskey(defaultvals, "OperationalLifeStorage") ? " DEFAULT " * string(defaultvals["OperationalLifeStorage"]) : "") * ", FOREIGN KEY(`s`) REFERENCES `STORAGE`(`val`), PRIMARY KEY(`id`), FOREIGN KEY(`r`) REFERENCES `REGION`(`val`) )")
    SQLite.execute!(db, "CREATE TABLE IF NOT EXISTS `OperationalLife` ( `id` INTEGER NOT NULL UNIQUE, `r` TEXT, `t` TEXT, `val` REAL" * (haskey(defaultvals, "OperationalLife") ? " DEFAULT " * string(defaultvals["OperationalLife"]) : "") * ", PRIMARY KEY(`id`), FOREIGN KEY(`t`) REFERENCES `TECHNOLOGY`(`val`), FOREIGN KEY(`r`) REFERENCES `REGION`(`val`) )")
    SQLite.execute!(db, "CREATE TABLE IF NOT EXISTS `ModelPeriodExogenousEmission` ( `id` INTEGER NOT NULL UNIQUE, `r` TEXT, `e` TEXT, `val` REAL" * (haskey(defaultvals, "ModelPeriodExogenousEmission") ? " DEFAULT " * string(defaultvals["ModelPeriodExogenousEmission"]) : "") * ", FOREIGN KEY(`e`) REFERENCES `EMISSION`(`val`), FOREIGN KEY(`r`) REFERENCES `REGION`(`val`), PRIMARY KEY(`id`) )")
    SQLite.execute!(db, "CREATE TABLE IF NOT EXISTS `ModelPeriodEmissionLimit` ( `id` INTEGER NOT NULL UNIQUE, `r` TEXT, `e` TEXT, `val` REAL" * (haskey(defaultvals, "ModelPeriodEmissionLimit") ? " DEFAULT " * string(defaultvals["ModelPeriodEmissionLimit"]) : "") * ", FOREIGN KEY(`e`) REFERENCES `EMISSION`(`val`), FOREIGN KEY(`r`) REFERENCES `REGION`(`val`), PRIMARY KEY(`id`) )")
    SQLite.execute!(db, "CREATE TABLE IF NOT EXISTS `MinStorageCharge` ( `id` INTEGER NOT NULL UNIQUE, `r` TEXT, `s` TEXT, `y` TEXT, `val` REAL" * (haskey(defaultvals, "MinStorageCharge") ? " DEFAULT " * string(defaultvals["MinStorageCharge"]) : "") * ", FOREIGN KEY(`r`) REFERENCES `REGION`(`val`), PRIMARY KEY(`id`), FOREIGN KEY(`s`) REFERENCES `STORAGE`(`val`), FOREIGN KEY(`y`) REFERENCES `YEAR`(`val`) )")
    SQLite.execute!(db, "CREATE TABLE IF NOT EXISTS `InputActivityRatio` ( `id` INTEGER NOT NULL UNIQUE, `r` TEXT, `t` TEXT, `f` TEXT, `m` TEXT, `y` TEXT, `val` REAL" * (haskey(defaultvals, "InputActivityRatio") ? " DEFAULT " * string(defaultvals["InputActivityRatio"]) : "") * ", FOREIGN KEY(`y`) REFERENCES `YEAR`(`val`), FOREIGN KEY(`m`) REFERENCES `MODE_OF_OPERATION`(`val`), FOREIGN KEY(`f`) REFERENCES `FUEL`(`val`), FOREIGN KEY(`t`) REFERENCES `TECHNOLOGY`(`val`), PRIMARY KEY(`id`), FOREIGN KEY(`r`) REFERENCES `REGION`(`val`) )")
    SQLite.execute!(db, "CREATE TABLE IF NOT EXISTS `FixedCost` ( `id` INTEGER NOT NULL UNIQUE, `r` TEXT, `t` TEXT, `y` TEXT, `val` REAL" * (haskey(defaultvals, "FixedCost") ? " DEFAULT " * string(defaultvals["FixedCost"]) : "") * ", FOREIGN KEY(`t`) REFERENCES `TECHNOLOGY`(`val`), PRIMARY KEY(`id`), FOREIGN KEY(`r`) REFERENCES `REGION`(`val`), FOREIGN KEY(`y`) REFERENCES `YEAR`(`val`) )")
    SQLite.execute!(db, "CREATE TABLE IF NOT EXISTS `EmissionsPenalty` ( `id` INTEGER NOT NULL UNIQUE, `r` TEXT, `e` TEXT, `y` TEXT, `val` REAL" * (haskey(defaultvals, "EmissionsPenalty") ? " DEFAULT " * string(defaultvals["EmissionsPenalty"]) : "") * ", PRIMARY KEY(`id`), FOREIGN KEY(`r`) REFERENCES `REGION`(`val`), FOREIGN KEY(`y`) REFERENCES `YEAR`(`val`), FOREIGN KEY(`e`) REFERENCES `EMISSION`(`val`) )")
    SQLite.execute!(db, "CREATE TABLE IF NOT EXISTS `EmissionActivityRatio` ( `id` INTEGER NOT NULL UNIQUE, `r` TEXT, `t` TEXT, `e` TEXT, `m` TEXT, `y` TEXT, `val` REAL" * (haskey(defaultvals, "EmissionActivityRatio") ? " DEFAULT " * string(defaultvals["EmissionActivityRatio"]) : "") * ", PRIMARY KEY(`id`), FOREIGN KEY(`r`) REFERENCES `REGION`(`val`), FOREIGN KEY(`t`) REFERENCES `TECHNOLOGY`(`val`), FOREIGN KEY(`y`) REFERENCES `YEAR`(`val`), FOREIGN KEY(`m`) REFERENCES `MODE_OF_OPERATION`(`val`), FOREIGN KEY(`e`) REFERENCES `EMISSION`(`val`) )")
    SQLite.execute!(db, "CREATE TABLE IF NOT EXISTS `DiscountRateStorage` ( `id` INTEGER NOT NULL UNIQUE, `val` REAL" * (haskey(defaultvals, "DiscountRateStorage") ? " DEFAULT " * string(defaultvals["DiscountRateStorage"]) : "") * ", PRIMARY KEY(`id`) )")
    SQLite.execute!(db, "CREATE TABLE IF NOT EXISTS `DiscountRate` ( `id` INTEGER NOT NULL UNIQUE, `r` TEXT, `val` REAL" * (haskey(defaultvals, "DiscountRate") ? " DEFAULT " * string(defaultvals["DiscountRate"]) : "") * ", FOREIGN KEY(`r`) REFERENCES `REGION`(`val`), PRIMARY KEY(`id`) )")
    SQLite.execute!(db, "CREATE TABLE IF NOT EXISTS `DepreciationMethod` ( `id` INTEGER NOT NULL UNIQUE, `r` TEXT, `val` REAL" * (haskey(defaultvals, "DepreciationMethod") ? " DEFAULT " * string(defaultvals["DepreciationMethod"]) : "") * ", PRIMARY KEY(`id`), FOREIGN KEY(`r`) REFERENCES `REGION`(`val`) )")
    SQLite.execute!(db, "CREATE TABLE IF NOT EXISTS `DaysInDayType` ( `id` INTEGER NOT NULL UNIQUE, `ls` TEXT, `ld` TEXT, `y` TEXT, `val` REAL" * (haskey(defaultvals, "DaysInDayType") ? " DEFAULT " * string(defaultvals["DaysInDayType"]) : "") * ", PRIMARY KEY(`id`), FOREIGN KEY(`ld`) REFERENCES `DAYTYPE`(`val`), FOREIGN KEY(`ls`) REFERENCES `SEASON`(`val`), FOREIGN KEY(`y`) REFERENCES `YEAR`(`val`) )")
    SQLite.execute!(db, "CREATE TABLE IF NOT EXISTS `DaySplit` ( `id` INTEGER NOT NULL UNIQUE, `lh` TEXT, `y` TEXT, `val` REAL" * (haskey(defaultvals, "DaySplit") ? " DEFAULT " * string(defaultvals["DaySplit"]) : "") * ", FOREIGN KEY(`lh`) REFERENCES `DAILYTIMEBRACKET`(`val`), PRIMARY KEY(`id`), FOREIGN KEY(`y`) REFERENCES `YEAR`(`val`) )")
    SQLite.execute!(db, "CREATE TABLE IF NOT EXISTS `Conversionls` ( `id` INTEGER NOT NULL UNIQUE, `l` TEXT, `ls` TEXT, `val` REAL" * (haskey(defaultvals, "Conversionls") ? " DEFAULT " * string(defaultvals["Conversionls"]) : "") * ", PRIMARY KEY(`id`), FOREIGN KEY(`ls`) REFERENCES `SEASON`(`val`), FOREIGN KEY(`l`) REFERENCES `TIMESLICE`(`val`) )")
    SQLite.execute!(db, "CREATE TABLE IF NOT EXISTS `Conversionlh` ( `id` INTEGER NOT NULL UNIQUE, `l` TEXT, `lh` TEXT, `val` REAL" * (haskey(defaultvals, "Conversionlh") ? " DEFAULT " * string(defaultvals["Conversionlh"]) : "") * ", PRIMARY KEY(`id`), FOREIGN KEY(`lh`) REFERENCES `DAILYTIMEBRACKET`(`val`), FOREIGN KEY(`l`) REFERENCES `TIMESLICE`(`val`) )")
    SQLite.execute!(db, "CREATE TABLE IF NOT EXISTS `Conversionld` ( `id` INTEGER NOT NULL UNIQUE, `l` TEXT, `ld` TEXT, `val` REAL" * (haskey(defaultvals, "Conversionld") ? " DEFAULT " * string(defaultvals["Conversionld"]) : "") * ", FOREIGN KEY(`ld`) REFERENCES `DAYTYPE`(`val`), PRIMARY KEY(`id`), FOREIGN KEY(`l`) REFERENCES `TIMESLICE`(`val`) )")
    SQLite.execute!(db, "CREATE TABLE IF NOT EXISTS `CapitalCostStorage` ( `id` INTEGER NOT NULL UNIQUE, `r` TEXT, `s` TEXT, `y` TEXT, `val` REAL" * (haskey(defaultvals, "CapitalCostStorage") ? " DEFAULT " * string(defaultvals["CapitalCostStorage"]) : "") * ", PRIMARY KEY(`id`), FOREIGN KEY(`s`) REFERENCES `STORAGE`(`val`), FOREIGN KEY(`r`) REFERENCES `REGION`(`val`), FOREIGN KEY(`y`) REFERENCES `YEAR`(`val`) )")
    SQLite.execute!(db, "CREATE TABLE IF NOT EXISTS `CapitalCost` ( `id` INTEGER NOT NULL UNIQUE, `r` TEXT, `t` TEXT, `y` TEXT, `val` REAL" * (haskey(defaultvals, "CapitalCost") ? " DEFAULT " * string(defaultvals["CapitalCost"]) : "") * ", FOREIGN KEY(`t`) REFERENCES `TECHNOLOGY`(`val`), PRIMARY KEY(`id`), FOREIGN KEY(`y`) REFERENCES `YEAR`(`val`), FOREIGN KEY(`r`) REFERENCES `REGION`(`val`) )")
    SQLite.execute!(db, "CREATE TABLE IF NOT EXISTS `CapacityToActivityUnit` ( `id` INTEGER NOT NULL UNIQUE, `r` TEXT, `t` TEXT, `val` REAL" * (haskey(defaultvals, "CapacityToActivityUnit") ? " DEFAULT " * string(defaultvals["CapacityToActivityUnit"]) : "") * ", FOREIGN KEY(`t`) REFERENCES `TECHNOLOGY`(`val`), PRIMARY KEY(`id`), FOREIGN KEY(`r`) REFERENCES `REGION`(`val`) )")
    SQLite.execute!(db, "CREATE TABLE IF NOT EXISTS `CapacityOfOneTechnologyUnit` ( `id` INTEGER NOT NULL UNIQUE, `r` TEXT, `t` TEXT, `y` TEXT, `val` REAL" * (haskey(defaultvals, "CapacityOfOneTechnologyUnit") ? " DEFAULT " * string(defaultvals["CapacityOfOneTechnologyUnit"]) : "") * ", FOREIGN KEY(`r`) REFERENCES `REGION`(`val`), FOREIGN KEY(`y`) REFERENCES `YEAR`(`val`), FOREIGN KEY(`t`) REFERENCES `TECHNOLOGY`(`val`), PRIMARY KEY(`id`) )")
    SQLite.execute!(db, "CREATE TABLE IF NOT EXISTS `CapacityFactor` ( `id` INTEGER NOT NULL UNIQUE, `r` TEXT, `t` TEXT, `l` TEXT, `y` TEXT, `val` REAL" * (haskey(defaultvals, "CapacityFactor") ? " DEFAULT " * string(defaultvals["CapacityFactor"]) : "") * ", FOREIGN KEY(`y`) REFERENCES `YEAR`(`val`), FOREIGN KEY(`r`) REFERENCES `REGION`(`val`), FOREIGN KEY(`t`) REFERENCES `TECHNOLOGY`(`val`), FOREIGN KEY(`l`) REFERENCES `TIMESLICE`(`val`), PRIMARY KEY(`id`) )")
    SQLite.execute!(db, "CREATE TABLE IF NOT EXISTS `AvailabilityFactor` ( `id` INTEGER NOT NULL UNIQUE, `r` TEXT, `t` TEXT, `y` TEXT, `val` REAL" * (haskey(defaultvals, "AvailabilityFactor") ? " DEFAULT " * string(defaultvals["AvailabilityFactor"]) : "") * ", FOREIGN KEY(`y`) REFERENCES `YEAR`(`val`), PRIMARY KEY(`id`), FOREIGN KEY(`r`) REFERENCES `REGION`(`val`), FOREIGN KEY(`t`) REFERENCES `TECHNOLOGY`(`val`) )")
    SQLite.execute!(db, "CREATE TABLE IF NOT EXISTS `AnnualExogenousEmission` ( `id` INTEGER NOT NULL UNIQUE, `r` TEXT, `e` TEXT, `y` TEXT, `val` REAL" * (haskey(defaultvals, "AnnualExogenousEmission") ? " DEFAULT " * string(defaultvals["AnnualExogenousEmission"]) : "") * ", FOREIGN KEY(`r`) REFERENCES `REGION`(`val`), FOREIGN KEY(`y`) REFERENCES `YEAR`(`val`), PRIMARY KEY(`id`), FOREIGN KEY(`e`) REFERENCES `EMISSION`(`val`) )")
    SQLite.execute!(db, "CREATE TABLE IF NOT EXISTS `AnnualEmissionLimit` ( `id` INTEGER NOT NULL UNIQUE, `r` TEXT, `e` TEXT, `y` TEXT, `val` REAL" * (haskey(defaultvals, "AnnualEmissionLimit") ? " DEFAULT " * string(defaultvals["AnnualEmissionLimit"]) : "") * ", FOREIGN KEY(`y`) REFERENCES `YEAR`(`val`), FOREIGN KEY(`e`) REFERENCES `EMISSION`(`val`), FOREIGN KEY(`r`) REFERENCES `REGION`(`val`), PRIMARY KEY(`id`) )")
    SQLite.execute!(db, "CREATE TABLE IF NOT EXISTS `AccumulatedAnnualDemand` ( `id` INTEGER NOT NULL UNIQUE, `r` TEXT, `f` TEXT, `y` TEXT, `val` REAL" * (haskey(defaultvals, "AccumulatedAnnualDemand") ? " DEFAULT " * string(defaultvals["AccumulatedAnnualDemand"]) : "") * ", PRIMARY KEY(`id`), FOREIGN KEY(`f`) REFERENCES `FUEL`(`val`), FOREIGN KEY(`y`) REFERENCES `YEAR`(`val`), FOREIGN KEY(`r`) REFERENCES `REGION`(`val`) )")
    # END: Add new NEMO tables.

    SQLite.execute!(db, "COMMIT")
    SQLite.execute!(db, "VACUUM")

    logmsg("Added NEMO structure to SQLite database at " * path * ".")
    # END: DDL operations in an SQLite transaction.

    # Return configured database
    return db
end  # createnemodb(path::String, defaultvals::Dict{String, Float64} = Dict{String, Float64}())

"""Creates an empty NEMO SQLite database with parameter defaults set to values used in LEAP. Arguments:
    • path - Full path to database, including database name.
If specified database already exists, drops and recreates NEMO tables in database."""
function createnemodb_leap(path::String)
    # BEGIN: Specify default parameter values.
    defaultvals::Dict{String, Float64} = Dict{String, Float64}()  # Default values to be passed to createnemodb

    defaultvals["VariableCost"] = 0.0
    defaultvals["TradeRoute"] = 0.0
    defaultvals["TotalTechnologyModelPeriodActivityUpperLimit"] = 10000000000.0
    defaultvals["TotalTechnologyModelPeriodActivityLowerLimit"] = 0.0
    defaultvals["TotalTechnologyAnnualActivityUpperLimit"] = 10000000000.0
    defaultvals["TotalTechnologyAnnualActivityLowerLimit"] = 0.0
    defaultvals["TotalAnnualMinCapacityInvestment"] = 0.0
    defaultvals["TotalAnnualMinCapacity"] = 0.0
    defaultvals["TotalAnnualMaxCapacityInvestment"] = 10000000000.0
    defaultvals["TotalAnnualMaxCapacity"] = 10000000000.0
    defaultvals["TechnologyToStorage"] = 0.0
    defaultvals["TechnologyFromStorage"] = 0.0
    defaultvals["TechWithCapacityNeededToMeetPeakTS"] = 0.0
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
    defaultvals["DiscountRateStorage"] = 0.0
    defaultvals["DiscountRate"] = 0.05
    defaultvals["DepreciationMethod"] = 1.0
    defaultvals["DaysInDayType"] = 7.0
    defaultvals["DaySplit"] = 0.00137
    defaultvals["Conversionls"] = 0.0
    defaultvals["Conversionlh"] = 0.0
    defaultvals["Conversionld"] = 0.0
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
    createnemodb(path, defaultvals)
end  # createnemodb_leap(path::String)

"""Sets the default value for a parameter table. Requires three arguments:
    1) db - SQLite database containing parameter table.
    2) table - Table name (case-sensitive).
    3) val - Parameter value (must be a floating-point number).
Implements logic described at https://www.sqlite.org/lang_altertable.html."""
function setparamdefault(db::SQLite.DB, table::String, val::Float64)
    try
        # BEGIN: SQLite transaction.
        SQLite.execute!(db, "BEGIN")
        schemaversion::Int = SQLite.query(db, "PRAGMA schema_version")[1,1]  # Starting schema version in db
        SQLite.execute!(db, "PRAGMA writable_schema = ON")

        sql::String = SQLite.query(db, "select sql from sqlite_master where type = 'table' and name = '" * table * "'")[1,1]  # Original SQL for table
        sql_parts::Tuple{String, String} = (sql[1:last(findfirst(r"`*val`*\s+real"i, sql))],
            sql[first(findnext(r"[,)]", sql, last(findfirst(r"`*val`*\s+real"i, sql)))):length(sql)])  # First element - original SQL up through data type for val column; second element - original SQL from comma following data type for val column

        SQLite.execute!(db, "update sqlite_master set sql = '" * sql_parts[1] * " DEFAULT " * string(val) * sql_parts[2] * "' where type = 'table' and name = '" * table * "'")

        SQLite.execute!(db, "PRAGMA schema_version = " * string(schemaversion + 1))
        SQLite.execute!(db, "PRAGMA writable_schema = OFF")
        SQLite.execute!(db, "COMMIT")
        # END: SQLite transaction.

        # Update view showing default values for table
        SQLite.execute!(db, "VACUUM")  # Appears to be necessary to make default visible in current Julia session
        createviewwithdefaults(db, [table])
        logmsg("Updated default value for parameter " * table * ". New default = " * string(val) * ".")
    catch
        # Rollback transaction and rethrow error
        SQLite.execute!(db, "ROLLBACK")
        rethrow()
    end
end  # setparamdefault(db::SQLite.DB, table::String, val::Float64)

# Demonstration function - performance is too poor for production use
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

"""For each OSeMOSYS parameter table identified in tables, creates a view that explicitly shows the default value for the val
column, if one is available. View name = [table name]  * "_def"."""
function createviewwithdefaults(db::SQLite.DB, tables::Array{String,1})
    for t in tables
        local hasdefault::Bool = false  # Indicates whether val column in t has a default value
        local defaultval  # Default value for val column in t, if column has a default value
        local pks::Array{String,1} = Array{String,1}()  # Names of foreign key fields in t
        local createviewstmt::String  # Create view SQL statement that will be executed for t

        # Delete view if existing already
        SQLite.query(db,"drop view if exists " * t * "_def")

        # BEGIN: Extract foreign key fields and default value from t.
        for row in eachrow(SQLite.query(db, "PRAGMA table_info('" * t *"')"))
            local rowname::String = row[:name]  # Value in name field for row

            if rowname == "id"
                continue
            elseif rowname == "val"
                if !ismissing(row[:dflt_value])
                    defaultval = row[:dflt_value]

                    # Some special handling here to avoid creating large views where they're not necessary, given OSeMOSYS's logic
                    if (t == "OutputActivityRatio" || t == "InputActivityRatio") && defaultval == "0"
                        # OutputActivityRatio and InputActivityRatio are only used when != 0, so can ignore a default value of 0
                        hasdefault = false
                    else
                        hasdefault = true
                    end
                end
            else
                push!(pks,rowname)
            end
        end
        # END: Extract foreign key fields and default value from t.

        # BEGIN: Create unique index on t for foreign key fields.
        # This step significantly improves performance for many queries on new view for t
        SQLite.query(db,"drop index if exists " * t * "_fks_unique")
        SQLite.query(db,"create unique index " * t * "_fks_unique on " * t * " (" * join(pks, ",") * ")")
        # END: Create unique index on t for foreign key fields.

        if hasdefault
            # Join to primary key tables with default specified
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
        SQLite.query(db, createviewstmt)
    end
end  # createviewwithdefaults(tables::Array{String,1})

"""Saves model results to a SQLite database using SQL inserts with transaction batching. Has five arguments:
    1) vars - Names of model variables for which results will be retrieved and saved to database.
    2) modelvarindices - Dictionary mapping model variable names to tuples of (variable, [index column names]).
    3) db - SQLite database.
    4) solvedtmstr - String to write into solvedtm field in result tables.
    5) quiet - Suppresses low-priority status messages (which are otherwise printed to STDOUT)."""
function savevarresults(vars::Array{String,1}, modelvarindices::Dict{String, Tuple{JuMP.JuMPContainer,Array{String,1}}}, db::SQLite.DB, solvedtmstr::String,
    quiet::Bool = false)
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
            SQLite.execute!(db, "BEGIN")

            # Create target table for v (drop any existing table for v)
            SQLite.query(db,"drop table if exists " * vname)

            SQLite.execute!(db, "create table '" * vname * "' ('" * join(modelvarindices[vname][2], "' text, '") * "' text, 'val' real, 'solvedtm' text)")

            # Insert data from gvv
            for i = 1:length(vals)
                SQLite.execute!(db, "insert into " * vname * " values('" * join(indices[i], "', '") * "', '" * string(vals[i]) * "', '" * solvedtmstr * "')")
            end

            # Complete SQLite transaction
            SQLite.execute!(db, "COMMIT")
            logmsg("Saved results for " * vname * " to database.", quiet)
        catch
            # Rollback db transaction
            SQLite.execute!(db, "ROLLBACK")

            # Proceed with normal Julia error sequence
            rethrow()
        end
        # END: Wrap database operations in try-catch block to allow rollback on error.
    end
end  # savevarresults(vars::Array{String,1}, modelvarindices::Dict{String, Tuple{JuMP.JuMPContainer,Array{String,1}}}, db::SQLite.DB, solvedtmstr::String)

"""Drops all tables in db whose name begins with "v" or "sqlite_stat" (both case-sensitive)."""
function dropresulttables(db::SQLite.DB)
    for row in eachrow(SQLite.tables(db))
        local name = row[:name]

        if name[1:1] == "v" || (length(name) >= 11 && name[1:11] == "sqlite_stat")
            SQLite.execute!(db, "drop table " * name)
            logmsg("Dropped table " * name * ".")
        end
    end
end  # dropresulttables(db::SQLite.DB)

"""Returns an array of model variables corresponding to the names in varnames. Excludes any variables not convertible to
    JuMP.JuMPContainer."""
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

"""This function is deprecated."""
function startnemo(dbpath::String, solver::String = "Cbc", numprocs::Int = Sys.CPU_THREADS)
    # Note: Sys.CPU_THREADS was Sys.CPU_CORES in Julia 0.6

    # Sample paths
    # dbpath = "C:\\temp\\TEMBA_datafile.sl3"
    # dbpath = "C:\\temp\\TEMBA_datafile_2010_only.sl3"
    # dbpath = "C:\\temp\\SAMBA_datafile.sl3"
    # dbpath = "C:\\temp\\utopia_2015_08_27.sl3"

    # BEGIN: Parameter validation.
    if !ispath(dbpath)
        error("dbpath must refer to a valid file system path.")
    end

    if uppercase(solver) == "CPLEX"
        solver = "CPLEX"
    elseif uppercase(solver) == "CBC"
        solver = "Cbc"
    else
        error("Requested solver (" * solver * ") is not supported.")
    end

    if numprocs < 1
        error("numprocs must be >= 1.")
    end
    # END: Parameter validation.

    # BEGIN: Add worker processes.
    while nprocs() < numprocs
        addprocs(1)
    end
    # END: Add worker processes.

    # BEGIN: Call main function for NEMO.
    @everywhere include(joinpath(Pkg.dir(), "NemoMod\\src\\NemoMod.jl"))  # Note that @everywhere loads file in Main module on all processes

    @time NemoMod.nemomain(dbpath, solver)
    # END: Call main function for NEMO.
end  # startnemo(dbpath::String, solver::String = "Cbc", numprocs::Int = Sys.CPU_CORES)
