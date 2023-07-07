#=
    NEMO: Next Energy Modeling system for Optimization.
    https://github.com/sei-international/NemoMod.jl

    Copyright © 2021: Stockholm Environment Institute U.S.

    File description: NEMO functions for manipulating the structure of scenario databases.
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

    # Drop any default parameter views (function encloses operation in a separate SQLite transaction)
    dropdefaultviews(db::SQLite.DB)

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
    SQLite.DBInterface.execute(db,"drop table if exists DiscountRateTechnology")
    SQLite.DBInterface.execute(db,"drop table if exists EmissionActivityRatio")
    SQLite.DBInterface.execute(db,"drop table if exists EmissionsPenalty")
    SQLite.DBInterface.execute(db,"drop table if exists FixedCost")
    SQLite.DBInterface.execute(db,"drop table if exists InputActivityRatio")
    SQLite.DBInterface.execute(db,"drop table if exists InterestRateStorage")
    SQLite.DBInterface.execute(db,"drop table if exists InterestRateTechnology")
    SQLite.DBInterface.execute(db,"drop table if exists LTsGroup")
    SQLite.DBInterface.execute(db,"drop table if exists MinShareProduction")
    SQLite.DBInterface.execute(db,"drop table if exists MinStorageCharge")
    SQLite.DBInterface.execute(db,"drop table if exists MinimumUtilization")
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
    SQLite.DBInterface.execute(db,"drop table if exists REMinProductionTargetRG")
    SQLite.DBInterface.execute(db,"drop table if exists RETagFuel")
    SQLite.DBInterface.execute(db,"drop table if exists RETagTechnology")
    SQLite.DBInterface.execute(db,"drop table if exists ReserveMargin")
    SQLite.DBInterface.execute(db,"drop table if exists ReserveMarginTagFuel")
    SQLite.DBInterface.execute(db,"drop table if exists ReserveMarginTagTechnology")
    SQLite.DBInterface.execute(db,"drop table if exists ResidualCapacity")
    SQLite.DBInterface.execute(db,"drop table if exists ResidualStorageCapacity")
    SQLite.DBInterface.execute(db,"drop table if exists RRGroup")
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
    SQLite.DBInterface.execute(db,"drop table if exists REGIONGROUP")
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
    #   - 6: Added MinimumUtilization, DiscountRateStorage, DiscountRateTechnology, TransmissionLine.discountrate
    #   - 7: Removed DiscountRateStorage, DiscountRateTechnology, TransmissionLine.discountrate. Added InterestRateStorage, InterestRateTechnology, TransmissionLine.interestrate
    #   - 8: Removed RETagFuel. Added REMinProductionTarget.f and MinShareProduction.
    #   - 9: Added REGIONGROUP, RRGroup, REMinProductionTargetRG.
    #   - 10: Added ReserveMargin.f and ReserveMarginTagTechnology.f. Deprecated ReserveMarginTagFuel.
    SQLite.DBInterface.execute(db, "CREATE TABLE `Version` (`version` INTEGER, PRIMARY KEY(`version`))")
    SQLite.DBInterface.execute(db, "INSERT INTO Version VALUES(10)")

    # No defaults in DefaultParams for sets/dimensions
    SQLite.DBInterface.execute(db, "CREATE TABLE IF NOT EXISTS `EMISSION` ( `val` TEXT NOT NULL UNIQUE, `desc` TEXT, PRIMARY KEY(`val`) )")
    SQLite.DBInterface.execute(db, "CREATE TABLE IF NOT EXISTS `FUEL` ( `val` TEXT NOT NULL UNIQUE, `desc` TEXT, PRIMARY KEY(`val`) )")
    SQLite.DBInterface.execute(db, "CREATE TABLE IF NOT EXISTS `MODE_OF_OPERATION` (`val` TEXT NOT NULL UNIQUE, `desc` TEXT, PRIMARY KEY(`val`))")
    SQLite.DBInterface.execute(db, "CREATE TABLE IF NOT EXISTS `REGION` (`val` TEXT NOT NULL UNIQUE, `desc` TEXT, PRIMARY KEY(`val`))")
    SQLite.DBInterface.execute(db, "CREATE TABLE IF NOT EXISTS `REGIONGROUP` (`val` TEXT NOT NULL UNIQUE, `desc` TEXT, PRIMARY KEY(`val`))")
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
    SQLite.DBInterface.execute(db, "CREATE TABLE IF NOT EXISTS `TransmissionLine` ( `id` TEXT, `n1` TEXT, `n2` TEXT, `f` TEXT, `maxflow` REAL, `reactance` REAL, `yconstruction` INTEGER, `capitalcost` REAL, `fixedcost` REAL, `variablecost` REAL, `operationallife` INTEGER, `efficiency` REAL, `interestrate` REAL, PRIMARY KEY(`id`)" * (foreignkeys ? ", FOREIGN KEY(`n2`) REFERENCES `NODE`(`val`), FOREIGN KEY(`n1`) REFERENCES `NODE`(`val`), FOREIGN KEY(`f`) REFERENCES `FUEL`(`val`)" : "") * " )")
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
    SQLite.DBInterface.execute(db, "CREATE TABLE IF NOT EXISTS `RRGroup` ( `id` INTEGER PRIMARY KEY NOT NULL, `rg` TEXT, `r` TEXT, UNIQUE(`rg`, `r`)" * (foreignkeys ? ", FOREIGN KEY(`rg`) REFERENCES `REGIONGROUP`(`val`), FOREIGN KEY(`r`) REFERENCES `REGION`(`val`)" : "") * " )")
    SQLite.DBInterface.execute(db, "CREATE TABLE IF NOT EXISTS `ResidualStorageCapacity` ( `id` INTEGER NOT NULL UNIQUE, `r` TEXT, `s` TEXT, `y` TEXT, `val` REAL, PRIMARY KEY(`id`)" * (foreignkeys ? ", FOREIGN KEY(`r`) REFERENCES `REGION`(`val`), FOREIGN KEY(`s`) REFERENCES `STORAGE`(`val`), FOREIGN KEY(`y`) REFERENCES `YEAR`(`val`)" : "") * " )")
    SQLite.DBInterface.execute(db, "CREATE TABLE IF NOT EXISTS `ResidualCapacity` ( `id` INTEGER NOT NULL UNIQUE, `r` TEXT, `t` TEXT, `y` TEXT, `val` REAL, PRIMARY KEY(`id`)" * (foreignkeys ? ", FOREIGN KEY(`r`) REFERENCES `REGION`(`val`), FOREIGN KEY(`t`) REFERENCES `TECHNOLOGY`(`val`), FOREIGN KEY(`y`) REFERENCES `YEAR`(`val`)" : "") * " )")
    SQLite.DBInterface.execute(db, "CREATE TABLE IF NOT EXISTS `ReserveMarginTagTechnology` ( `id` INTEGER NOT NULL UNIQUE, `r` TEXT, `t` TEXT, `f` TEXT, `y` TEXT, `val` REAL, PRIMARY KEY(`id`)" * (foreignkeys ? ", FOREIGN KEY(`r`) REFERENCES `REGION`(`val`), FOREIGN KEY(`y`) REFERENCES `YEAR`(`val`), FOREIGN KEY(`t`) REFERENCES `TECHNOLOGY`(`val`), FOREIGN KEY(`f`) REFERENCES `FUEL`(`val`)" : "") * " )")
    SQLite.DBInterface.execute(db, "CREATE TABLE IF NOT EXISTS `ReserveMargin` ( `id` INTEGER NOT NULL UNIQUE, `r` TEXT, `f` TEXT, `y` TEXT, `val` REAL, PRIMARY KEY(`id`)" * (foreignkeys ? ", FOREIGN KEY(`r`) REFERENCES `REGION`(`val`), FOREIGN KEY(`f`) REFERENCES `FUEL`(`val`), FOREIGN KEY(`y`) REFERENCES `YEAR`(`val`)" : "") * " )")
    SQLite.DBInterface.execute(db, "CREATE TABLE IF NOT EXISTS `RETagTechnology` ( `id` INTEGER NOT NULL UNIQUE, `r` TEXT, `t` TEXT, `y` TEXT, `val` REAL, PRIMARY KEY(`id`)" * (foreignkeys ? ", FOREIGN KEY(`r`) REFERENCES `REGION`(`val`), FOREIGN KEY(`y`) REFERENCES `YEAR`(`val`), FOREIGN KEY(`t`) REFERENCES `TECHNOLOGY`(`val`)" : "") * " )")
    SQLite.DBInterface.execute(db, "CREATE TABLE IF NOT EXISTS `REMinProductionTargetRG` ( `id` INTEGER PRIMARY KEY NOT NULL, `rg` TEXT, `f` TEXT, `y` TEXT, `val` REAL" * (foreignkeys ? ", FOREIGN KEY(`y`) REFERENCES `YEAR`(`val`), FOREIGN KEY(`f`) REFERENCES `FUEL`(`val`), FOREIGN KEY(`rg`) REFERENCES `REGIONGROUP`(`val`)" : "") * " )")
    SQLite.DBInterface.execute(db, "CREATE TABLE IF NOT EXISTS `REMinProductionTarget` ( `id` INTEGER NOT NULL UNIQUE, `r` TEXT, `f` TEXT, `y` TEXT, `val` REAL, PRIMARY KEY(`id`)" * (foreignkeys ? ", FOREIGN KEY(`y`) REFERENCES `YEAR`(`val`), FOREIGN KEY(`f`) REFERENCES `FUEL`(`val`), FOREIGN KEY(`r`) REFERENCES `REGION`(`val`)" : "") * " )")
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
    SQLite.DBInterface.execute(db, "CREATE TABLE IF NOT EXISTS `MinimumUtilization` ( `id` INTEGER NOT NULL UNIQUE, `r` TEXT, `t` TEXT, `l` TEXT, `y` TEXT, `val` REAL, PRIMARY KEY(`id`)" * (foreignkeys ? ", FOREIGN KEY(`y`) REFERENCES `YEAR`(`val`), FOREIGN KEY(`r`) REFERENCES `REGION`(`val`), FOREIGN KEY(`t`) REFERENCES `TECHNOLOGY`(`val`), FOREIGN KEY(`l`) REFERENCES `TIMESLICE`(`val`)" : "") * " )")
    SQLite.DBInterface.execute(db, "CREATE TABLE IF NOT EXISTS `MinStorageCharge` ( `id` INTEGER NOT NULL UNIQUE, `r` TEXT, `s` TEXT, `y` TEXT, `val` REAL, PRIMARY KEY(`id`)" * (foreignkeys ? ", FOREIGN KEY(`r`) REFERENCES `REGION`(`val`), FOREIGN KEY(`s`) REFERENCES `STORAGE`(`val`), FOREIGN KEY(`y`) REFERENCES `YEAR`(`val`)" : "") * " )")
    SQLite.DBInterface.execute(db, "CREATE TABLE IF NOT EXISTS `MinShareProduction` ( `id` INTEGER NOT NULL UNIQUE, `r` TEXT, `t` TEXT, `f` TEXT, `y` TEXT, `val` REAL, PRIMARY KEY(`id`)" * (foreignkeys ? ", FOREIGN KEY(`r`) REFERENCES `REGION`(`val`), FOREIGN KEY(`t`) REFERENCES `TECHNOLOGY`(`val`), FOREIGN KEY(`f`) REFERENCES `FUEL`(`val`), FOREIGN KEY(`y`) REFERENCES `YEAR`(`val`)" : "") * " )")
    SQLite.DBInterface.execute(db, "CREATE TABLE IF NOT EXISTS `LTsGroup` ( `id` INTEGER PRIMARY KEY AUTOINCREMENT, `l` TEXT UNIQUE,	`lorder` INTEGER, `tg2` TEXT, `tg1` TEXT" * (foreignkeys ? ", FOREIGN KEY(`l`) REFERENCES `TIMESLICE`(`val`), FOREIGN KEY(`tg2`) REFERENCES `TSGROUP2`(`name`), FOREIGN KEY(`tg1`) REFERENCES `TSGROUP1`(`name`)" : "") * " )")
    SQLite.DBInterface.execute(db, "CREATE TABLE IF NOT EXISTS `InterestRateTechnology` ( `id` INTEGER NOT NULL UNIQUE, `r` TEXT, `t` TEXT, `y` TEXT, `val` REAL, PRIMARY KEY(`id`)" * (foreignkeys ? ", FOREIGN KEY(`t`) REFERENCES `TECHNOLOGY`(`val`), FOREIGN KEY(`r`) REFERENCES `REGION`(`val`), FOREIGN KEY(`y`) REFERENCES `YEAR`(`val`)" : "") * " )")
    SQLite.DBInterface.execute(db, "CREATE TABLE IF NOT EXISTS `InterestRateStorage` ( `id` INTEGER NOT NULL UNIQUE, `r` TEXT, `s` TEXT, `y` TEXT, `val` REAL, PRIMARY KEY(`id`)" * (foreignkeys ? ", FOREIGN KEY(`s`) REFERENCES `STORAGE`(`val`), FOREIGN KEY(`r`) REFERENCES `REGION`(`val`), FOREIGN KEY(`y`) REFERENCES `YEAR`(`val`)" : "") * " )")
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

        qry::SQLite.Query = SQLite.DBInterface.execute(db, "PRAGMA table_info('RampRate')")

        if SQLite.done(qry)
            SQLite.DBInterface.execute(db, "CREATE TABLE `RampRate` (`id` INTEGER NOT NULL UNIQUE, `r` TEXT, `t` TEXT, `y` TEXT, `l` TEXT, `val` REAL, PRIMARY KEY(`id`))")
        end

        qry = SQLite.DBInterface.execute(db, "PRAGMA table_info('RampingReset')")

        if SQLite.done(qry)
            SQLite.DBInterface.execute(db, "CREATE TABLE `RampingReset` (`id` INTEGER NOT NULL UNIQUE, `r` TEXT, `val` INTEGER, PRIMARY KEY(`id`))")
        end

        SQLite.DBInterface.execute(db, "update version set version = 5")

        SQLite.DBInterface.execute(db, "COMMIT")
        # END: SQLite transaction.

        logmsg("Upgraded database to version 5.", quiet)
    catch
        # Rollback transaction and rethrow error
        SQLite.DBInterface.execute(db, "ROLLBACK")
        rethrow()
    end
    # END: Wrap database operations in try-catch block to allow rollback on error.
end  # db_v4_to_v5(db::SQLite.DB; quiet::Bool = false)

# Upgrades NEMO database from version 5 to version 6 by adding MinimumUtilization, DiscountRateStorage, DiscountRateTechnology, TransmissionLine.discountrate.
function db_v5_to_v6(db::SQLite.DB; quiet::Bool = false)
    # BEGIN: Wrap database operations in try-catch block to allow rollback on error.
    try
        # BEGIN: SQLite transaction.
        SQLite.DBInterface.execute(db, "BEGIN")

        qry::SQLite.Query = SQLite.DBInterface.execute(db, "PRAGMA table_info('MinimumUtilization')")

        if SQLite.done(qry)
            SQLite.DBInterface.execute(db, "CREATE TABLE `MinimumUtilization` ( `id` INTEGER NOT NULL UNIQUE, `r` TEXT, `t` TEXT, `l` TEXT, `y` TEXT, `val` REAL, PRIMARY KEY(`id`))")
        end

        qry = SQLite.DBInterface.execute(db, "PRAGMA table_info('DiscountRateStorage')")

        if SQLite.done(qry)
            SQLite.DBInterface.execute(db, "CREATE TABLE IF NOT EXISTS `DiscountRateStorage` ( `id` INTEGER NOT NULL UNIQUE, `r` TEXT, `s` TEXT, `val` REAL, PRIMARY KEY(`id`))")
        end

        qry = SQLite.DBInterface.execute(db, "PRAGMA table_info('DiscountRateTechnology')")

        if SQLite.done(qry)
            SQLite.DBInterface.execute(db, "CREATE TABLE IF NOT EXISTS `DiscountRateTechnology` ( `id` INTEGER NOT NULL UNIQUE, `r` TEXT, `t` TEXT, `val` REAL, PRIMARY KEY(`id`))")
        end

        qrydf::DataFrame = SQLite.DBInterface.execute(db, "PRAGMA table_info('TransmissionLine')") |> DataFrame
        updatetl::Bool = !in("discountrate", qrydf.name)

        if updatetl
            SQLite.DBInterface.execute(db, "alter table TransmissionLine rename to TransmissionLine_old")
            SQLite.DBInterface.execute(db, "CREATE TABLE IF NOT EXISTS `TransmissionLine` ( `id` TEXT, `n1` TEXT, `n2` TEXT, `f` TEXT, `maxflow` REAL, `reactance` REAL, `yconstruction` INTEGER, `capitalcost` REAL, `fixedcost` REAL, `variablecost` REAL, `operationallife` INTEGER, `efficiency` REAL, `discountrate` REAL, PRIMARY KEY(`id`))")
            SQLite.DBInterface.execute(db, "insert into TransmissionLine select id, n1, n2, f, maxflow, reactance, yconstruction, capitalcost, fixedcost, variablecost, operationallife, efficiency, null from TransmissionLine_old")
            SQLite.DBInterface.execute(db, "drop table TransmissionLine_old")
        end

        SQLite.DBInterface.execute(db, "update version set version = 6")

        SQLite.DBInterface.execute(db, "COMMIT")
        # END: SQLite transaction.

        logmsg("Upgraded database to version 6.", quiet)
    catch
        # Rollback transaction and rethrow error
        SQLite.DBInterface.execute(db, "ROLLBACK")
        rethrow()
    end
    # END: Wrap database operations in try-catch block to allow rollback on error.
end  # db_v5_to_v6(db::SQLite.DB; quiet::Bool = false)

# Upgrades NEMO database from version 6 to version 7 by: removing DiscountRateStorage, DiscountRateTechnology, TransmissionLine.discountrate; and adding InterestRateStorage, InterestRateTechnology, TransmissionLine.interestrate
function db_v6_to_v7(db::SQLite.DB; quiet::Bool = false)
    # BEGIN: Wrap database operations in try-catch block to allow rollback on error.
    try
        # BEGIN: SQLite transaction.
        SQLite.DBInterface.execute(db, "BEGIN")

        SQLite.DBInterface.execute(db,"drop view if exists DiscountRateStorage_def")
        SQLite.DBInterface.execute(db,"drop table if exists DiscountRateStorage")
        SQLite.DBInterface.execute(db,"drop view if exists DiscountRateTechnology_def")
        SQLite.DBInterface.execute(db,"drop table if exists DiscountRateTechnology")

        qry::SQLite.Query = SQLite.DBInterface.execute(db, "PRAGMA table_info('InterestRateStorage')")

        if SQLite.done(qry)
            SQLite.DBInterface.execute(db, "CREATE TABLE IF NOT EXISTS `InterestRateStorage` ( `id` INTEGER NOT NULL UNIQUE, `r` TEXT, `s` TEXT, `y` TEXT, `val` REAL, PRIMARY KEY(`id`))")
        end

        qry = SQLite.DBInterface.execute(db, "PRAGMA table_info('InterestRateTechnology')")

        if SQLite.done(qry)
            SQLite.DBInterface.execute(db, "CREATE TABLE IF NOT EXISTS `InterestRateTechnology` ( `id` INTEGER NOT NULL UNIQUE, `r` TEXT, `t` TEXT, `y` TEXT, `val` REAL, PRIMARY KEY(`id`))")
        end

        SQLite.DBInterface.execute(db, "alter table TransmissionLine rename to TransmissionLine_old")
        SQLite.DBInterface.execute(db, "CREATE TABLE IF NOT EXISTS `TransmissionLine` ( `id` TEXT, `n1` TEXT, `n2` TEXT, `f` TEXT, `maxflow` REAL, `reactance` REAL, `yconstruction` INTEGER, `capitalcost` REAL, `fixedcost` REAL, `variablecost` REAL, `operationallife` INTEGER, `efficiency` REAL, `interestrate` REAL, PRIMARY KEY(`id`))")
        SQLite.DBInterface.execute(db, "insert into TransmissionLine select id, n1, n2, f, maxflow, reactance, yconstruction, capitalcost, fixedcost, variablecost, operationallife, efficiency, null from TransmissionLine_old")
        SQLite.DBInterface.execute(db, "drop table TransmissionLine_old")

        SQLite.DBInterface.execute(db, "update version set version = 7")

        SQLite.DBInterface.execute(db, "COMMIT")
        # END: SQLite transaction.

        logmsg("Upgraded database to version 7.", quiet)
    catch
        # Rollback transaction and rethrow error
        SQLite.DBInterface.execute(db, "ROLLBACK")
        rethrow()
    end
    # END: Wrap database operations in try-catch block to allow rollback on error.
end  # db_v6_to_v7(db::SQLite.DB; quiet::Bool = false)

# Upgrades NEMO database from version 7 to version 8 by: removing RETagFuel; adding REMinProductionTarget.f and MinShareProduction.
function db_v7_to_v8(db::SQLite.DB; quiet::Bool = false)
    # BEGIN: Wrap database operations in try-catch block to allow rollback on error.
    try
        # Ensure views with defaults for REMinProductionTarget and RETagFuel exist
        createviewwithdefaults(db, ["REMinProductionTarget", "RETagFuel"])

        # BEGIN: SQLite transaction.
        SQLite.DBInterface.execute(db, "BEGIN")

        SQLite.DBInterface.execute(db, "alter table REMinProductionTarget rename to REMinProductionTarget_old")
        SQLite.DBInterface.execute(db, "CREATE TABLE IF NOT EXISTS `REMinProductionTarget` ( `id` INTEGER NOT NULL UNIQUE, `r` TEXT, `f` TEXT, `y` TEXT, `val` REAL, PRIMARY KEY(`id`))")
        SQLite.DBInterface.execute(db, "insert into REMinProductionTarget select count(*) OVER (rows unbounded PRECEDING) as id, rmp.r, rtf.f, rmp.y, rmp.val
            from REMinProductionTarget_def rmp, RETagFuel_def rtf
            where rmp.r = rtf.r
            and rmp.y = rtf.y
            and rtf.val = 1
            and rmp.val > 0")
        SQLite.DBInterface.execute(db, "drop view REMinProductionTarget_def")
        SQLite.DBInterface.execute(db, "drop table REMinProductionTarget_old")

        SQLite.DBInterface.execute(db, "drop view if exists RETagFuel_def")
        SQLite.DBInterface.execute(db, "drop table if exists RETagFuel")

        # Remove old default values since they no longer operate in same way, and their old operation is encapsulated in data in REMinProductionTarget
        SQLite.DBInterface.execute(db, "delete from DefaultParams where tablename in ('REMinProductionTarget', 'RETagFuel')")

        SQLite.DBInterface.execute(db, "CREATE TABLE IF NOT EXISTS `MinShareProduction` ( `id` INTEGER NOT NULL UNIQUE, `r` TEXT, `t` TEXT, `f` TEXT, `y` TEXT, `val` REAL, PRIMARY KEY(`id`) )")

        SQLite.DBInterface.execute(db, "update version set version = 8")

        SQLite.DBInterface.execute(db, "COMMIT")
        # END: SQLite transaction.

        logmsg("Upgraded database to version 8.", quiet)
    catch
        # Rollback transaction and rethrow error
        SQLite.DBInterface.execute(db, "ROLLBACK")
        rethrow()
    end
    # END: Wrap database operations in try-catch block to allow rollback on error.
end  # db_v7_to_v8(db::SQLite.DB; quiet::Bool = false)

# Upgrades NEMO database from version 8 to version 7 by: adding REGIONGROUP, REMinProductionTargetRG, and RRGroup.
function db_v8_to_v9(db::SQLite.DB; quiet::Bool = false)
    # BEGIN: Wrap database operations in try-catch block to allow rollback on error.
    try
        # BEGIN: SQLite transaction.
        SQLite.DBInterface.execute(db, "BEGIN")

        SQLite.DBInterface.execute(db, "CREATE TABLE IF NOT EXISTS `REGIONGROUP` (`val` TEXT NOT NULL UNIQUE, `desc` TEXT, PRIMARY KEY(`val`))")
        SQLite.DBInterface.execute(db, "CREATE TABLE IF NOT EXISTS `REMinProductionTargetRG` ( `id` INTEGER PRIMARY KEY NOT NULL, `rg` TEXT, `f` TEXT, `y` TEXT, `val` REAL )")
        SQLite.DBInterface.execute(db, "CREATE TABLE IF NOT EXISTS `RRGroup` ( `id` INTEGER PRIMARY KEY NOT NULL, `rg` TEXT, `r` TEXT, UNIQUE(`rg`, `r`) )")

        SQLite.DBInterface.execute(db, "update version set version = 9")

        SQLite.DBInterface.execute(db, "COMMIT")
        # END: SQLite transaction.

        logmsg("Upgraded database to version 9.", quiet)
    catch
        # Rollback transaction and rethrow error
        SQLite.DBInterface.execute(db, "ROLLBACK")
        rethrow()
    end
    # END: Wrap database operations in try-catch block to allow rollback on error.
end  # db_v8_to_v9(db::SQLite.DB; quiet::Bool = false)

# Upgrades NEMO database from version 9 to version 10 by: adding ReserveMargin.f and ReserveMarginTagTechnology.f; migrating information in ReserveMarginTagFuel to ReserveMargin and ReserveMarginTagTechnology if possible; and dropping ReserveMarginTagFuel.
function db_v9_to_v10(db::SQLite.DB; quiet::Bool = false)
    # BEGIN: Wrap database operations in try-catch block to allow rollback on error.
    try
        # Ensure required views with defaults exist
        createviewwithdefaults(db, ["ReserveMargin", "ReserveMarginTagTechnology", "ReserveMarginTagFuel"])

        # BEGIN: SQLite transaction.
        SQLite.DBInterface.execute(db, "BEGIN")

        SQLite.DBInterface.execute(db, "alter table ReserveMargin rename to ReserveMargin_old")
        SQLite.DBInterface.execute(db, "CREATE TABLE IF NOT EXISTS `ReserveMargin` ( `id` INTEGER NOT NULL UNIQUE, `r` TEXT, `f` TEXT, `y` TEXT, `val` REAL, PRIMARY KEY(`id`))")
        SQLite.DBInterface.execute(db,"insert into ReserveMargin select null, rm.r, rmf.f, rm.y, rm.val from ReserveMargin_def rm, 
            (select r, f, y from 
            (select r, f, y, count(f) over (partition by r, y rows between UNBOUNDED PRECEDING and UNBOUNDED FOLLOWING) as cnt
            from ReserveMarginTagFuel_def
            where val = 1)
            where cnt = 1) rmf
            WHERE
            rm.r =  rmf.r
            and rm.y = rmf.y")
    
        SQLite.DBInterface.execute(db, "alter table ReserveMarginTagTechnology rename to ReserveMarginTagTechnology_old")
        SQLite.DBInterface.execute(db, "CREATE TABLE IF NOT EXISTS `ReserveMarginTagTechnology` ( `id` INTEGER NOT NULL UNIQUE, `r` TEXT, `t` TEXT, `f` TEXT, `y` TEXT, `val` REAL, PRIMARY KEY(`id`))")
        SQLite.DBInterface.execute(db, "insert into ReserveMarginTagTechnology select null, rmt.r, rmt.t, rmf.f, rmt.y, rmt.val from ReserveMarginTagTechnology_def rmt, 
            (select r, f, y from 
            (select r, f, y, count(f) over (partition by r, y rows between UNBOUNDED PRECEDING and UNBOUNDED FOLLOWING) as cnt
            from ReserveMarginTagFuel_def
            where val = 1)
            where cnt = 1) rmf
            WHERE
            rmt.r =  rmf.r
            and rmt.y = rmf.y
            and rmt.val > 0")

        if DataFrame(SQLite.DBInterface.execute(db, "select count(*) from ReserveMargin"))[1,1] != DataFrame(SQLite.DBInterface.execute(db, "select count(*) from ReserveMargin_def"))[1,1]
            @warn "Could not migrate some reserve margin data when upgrading database to version 10. Please verify data in ReserveMargin and ReserveMarginTagTechnology tables."
        end
        
        SQLite.DBInterface.execute(db, "drop view if exists ReserveMarginTagFuel_def")
        SQLite.DBInterface.execute(db, "drop table if exists ReserveMarginTagFuel")
        SQLite.DBInterface.execute(db, "drop view if exists ReserveMarginTagTechnology_def")
        SQLite.DBInterface.execute(db, "drop table if exists ReserveMarginTagTechnology_old")
        SQLite.DBInterface.execute(db, "drop view if exists ReserveMargin_def")
        SQLite.DBInterface.execute(db, "drop table if exists ReserveMargin_old")

        # Remove old default values since they no longer operate in same way, and their old operation is encapsulated in data in ReserveMargin and ReserveMarginTagTechnology
        SQLite.DBInterface.execute(db, "delete from DefaultParams where tablename in ('ReserveMargin', 'ReserveMarginTagTechnology', 'ReserveMarginTagFuel')")

        SQLite.DBInterface.execute(db, "update version set version = 10")

        SQLite.DBInterface.execute(db, "COMMIT")
        # END: SQLite transaction.

        logmsg("Upgraded database to version 10.", quiet)
    catch
        # Rollback transaction and rethrow error
        SQLite.DBInterface.execute(db, "ROLLBACK")
        rethrow()
    end
    # END: Wrap database operations in try-catch block to allow rollback on error.
end  # db_v9_to_v10(db::SQLite.DB; quiet::Bool = false)

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
    dropresulttables(db::SQLite.DB, quiet::Bool = true)

Drops all tables in `db` whose name begins with ""v"" or ""sqlite_stat"" (both case-sensitive).
    The `quiet` parameter determines whether most status messages are suppressed.
"""
function dropresulttables(db::SQLite.DB, quiet::Bool = true)
    # BEGIN: Wrap database operations in try-catch block to allow rollback on error.
    try
        # Begin SQLite transaction
        SQLite.DBInterface.execute(db, "BEGIN")

        for t in SQLite.tables(db)
            local tname = t.name

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
