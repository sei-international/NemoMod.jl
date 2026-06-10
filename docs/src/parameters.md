```@meta
CurrentModule = NemoMod
```
# [Parameters](@id parameters)

NEMO includes a number of parameters that define data and set the terms for constraints. As with model [dimensions](@ref dimensions), parameters are specified in a NEMO [scenario database](@ref scenario_db). NEMO reads them from the database and uses them to build constraints at run-time. Generally, NEMO does not create separate Julia variables for parameters.

Most parameters are subscripted by one or more dimensions. Parameter tables in a scenario database refer to dimensions by their abbreviation (`r` for [region](@ref region), `t` for [technology](@ref technology), and so on). The abbreviation serves as the name of the dimension's column, and the column should be populated with unique identifiers for the dimension (`val`, `name`, or `id`, depending on the dimension).

Documentation for individual parameters is organized into the following pages by modeling topic.

| Page | Parameters covered |
|:--- |:--- |
| [Demand parameters](@ref parameters_demands) | 3 |
| [Technology performance and operation parameters](@ref parameters_technology) | 10 |
| [Cost, financing, and subsidy parameters](@ref parameters_costs) | 10 |
| [Capacity and investment limit parameters](@ref parameters_capacity_limits) | 12 |
| [Activity limit and production share parameters](@ref parameters_activity_limits) | 9 |
| [Emission parameters](@ref parameters_emissions) | 6 |
| [Reserve margin parameters](@ref parameters_reserve_margins) | 2 |
| [Storage parameters](@ref parameters_storage) | 15 |
| [Transmission, node, and trade parameters](@ref parameters_transmission) | 11 |
| [Model structure and grouping parameters](@ref parameters_structure) | 5 |

## [Parameter index](@id parameter_index)

The table below lists all NEMO parameters alphabetically, with the name of the corresponding scenario database table and a link to the parameter's documentation.

| Parameter | Scenario database table | Page |
|:--- |:--- |:--- |
| [Accumulated annual demand](@ref AccumulatedAnnualDemand) | `AccumulatedAnnualDemand` | [Demands](@ref parameters_demands) |
| [Annual emission limit](@ref AnnualEmissionLimit) | `AnnualEmissionLimit` | [Emissions](@ref parameters_emissions) |
| [Annual exogenous emission](@ref AnnualExogenousEmission) | `AnnualExogenousEmission` | [Emissions](@ref parameters_emissions) |
| [Availability factor](@ref AvailabilityFactor) | `AvailabilityFactor` | [Technology performance and operation](@ref parameters_technology) |
| [Capacity of one technology unit](@ref CapacityOfOneTechnologyUnit) | `CapacityOfOneTechnologyUnit` | [Technology performance and operation](@ref parameters_technology) |
| [Capacity to activity unit](@ref CapacityToActivityUnit) | `CapacityToActivityUnit` | [Technology performance and operation](@ref parameters_technology) |
| [Capital cost](@ref CapitalCost) | `CapitalCost` | [Costs, financing, and subsidies](@ref parameters_costs) |
| [Capital cost storage](@ref CapitalCostStorage) | `CapitalCostStorage` | [Storage](@ref parameters_storage) |
| [Default parameters](@ref DefaultParams) | `DefaultParams` | [Model structure and groupings](@ref parameters_structure) |
| [Depreciation method](@ref DepreciationMethod) | `DepreciationMethod` | [Costs, financing, and subsidies](@ref parameters_costs) |
| [Discount rate](@ref DiscountRate) | `DiscountRate` | [Costs, financing, and subsidies](@ref parameters_costs) |
| [Emission penalty](@ref EmissionsPenalty) | `EmissionsPenalty` | [Emissions](@ref parameters_emissions) |
| [Emissions activity ratio](@ref EmissionActivityRatio) | `EmissionActivityRatio` | [Emissions](@ref parameters_emissions) |
| [Fixed cost](@ref FixedCost) | `FixedCost` | [Costs, financing, and subsidies](@ref parameters_costs) |
| [Interest rate storage](@ref InterestRateStorage) | `InterestRateStorage` | [Storage](@ref parameters_storage) |
| [Interest rate technology](@ref InterestRateTechnology) | `InterestRateTechnology` | [Costs, financing, and subsidies](@ref parameters_costs) |
| [Input activity ratio](@ref InputActivityRatio) | `InputActivityRatio` | [Technology performance and operation](@ref parameters_technology) |
| [Maximum annual transmission between nodes](@ref MaxAnnualTransmissionNodes) | `MaxAnnualTransmissionNodes` | [Transmission, nodes, and trade](@ref parameters_transmission) |
| [Maximum production share](@ref MaxShareProduction) | `MaxShareProduction` | [Activity limits and production shares](@ref parameters_activity_limits) |
| [Maximum subsidies per technology](@ref MaxSubsidyPerTechnology) | `MaxSubsidyPerTechnology` | [Costs, financing, and subsidies](@ref parameters_costs) |
| [Maximum subsidies per technology group](@ref MaxSubsidyPerTechnologyGroup) | `MaxSubsidyPerTechnologyGroup` | [Costs, financing, and subsidies](@ref parameters_costs) |
| [Maximum subsidies per region](@ref MaxSubsidyPerRegion) | `MaxSubsidyPerRegion` | [Costs, financing, and subsidies](@ref parameters_costs) |
| [Minimum annual transmission between nodes](@ref MinAnnualTransmissionNodes) | `MinAnnualTransmissionNodes` | [Transmission, nodes, and trade](@ref parameters_transmission) |
| [Minimum production share](@ref MinShareProduction) | `MinShareProduction` | [Activity limits and production shares](@ref parameters_activity_limits) |
| [Minimum storage charge](@ref MinStorageCharge) | `MinStorageCharge` | [Storage](@ref parameters_storage) |
| [Minimum utilization](@ref MinimumUtilization) | `MinimumUtilization` | [Technology performance and operation](@ref parameters_technology) |
| [Model period emission limit](@ref ModelPeriodEmissionLimit) | `ModelPeriodEmissionLimit` | [Emissions](@ref parameters_emissions) |
| [Model period exogenous emission](@ref ModelPeriodExogenousEmission) | `ModelPeriodExogenousEmission` | [Emissions](@ref parameters_emissions) |
| [Nodal distribution demand](@ref NodalDistributionDemand) | `NodalDistributionDemand` | [Transmission, nodes, and trade](@ref parameters_transmission) |
| [Nodal distribution storage capacity](@ref NodalDistributionStorageCapacity) | `NodalDistributionStorageCapacity` | [Transmission, nodes, and trade](@ref parameters_transmission) |
| [Nodal distribution technology capacity](@ref NodalDistributionTechnologyCapacity) | `NodalDistributionTechnologyCapacity` | [Transmission, nodes, and trade](@ref parameters_transmission) |
| [Operational life](@ref OperationalLife) | `OperationalLife` | [Technology performance and operation](@ref parameters_technology) |
| [Operational life storage](@ref OperationalLifeStorage) | `OperationalLifeStorage` | [Storage](@ref parameters_storage) |
| [Output activity ratio](@ref OutputActivityRatio) | `OutputActivityRatio` | [Technology performance and operation](@ref parameters_technology) |
| [Ramp rate](@ref RampRate) | `RampRate` | [Technology performance and operation](@ref parameters_technology) |
| [Ramping reset](@ref RampingReset) | `RampingReset` | [Technology performance and operation](@ref parameters_technology) |
| [Region group assignment](@ref RRGroup) | `RRGroup` | [Model structure and groupings](@ref parameters_structure) |
| [Renewable energy minimum production target (by region)](@ref REMinProductionTarget) | `REMinProductionTarget` | [Activity limits and production shares](@ref parameters_activity_limits) |
| [Renewable energy minimum production target (by region group)](@ref REMinProductionTargetRG) | `REMinProductionTargetRG` | [Activity limits and production shares](@ref parameters_activity_limits) |
| [Renewable energy tag technology](@ref RETagTechnology) | `RETagTechnology` | [Activity limits and production shares](@ref parameters_activity_limits) |
| [Reserve margin](@ref ReserveMargin) | `ReserveMargin` | [Reserve margins](@ref parameters_reserve_margins) |
| [Reserve margin tag technology](@ref ReserveMarginTagTechnology) | `ReserveMarginTagTechnology` | [Reserve margins](@ref parameters_reserve_margins) |
| [Residual capacity](@ref ResidualCapacity) | `ResidualCapacity` | [Technology performance and operation](@ref parameters_technology) |
| [Residual storage capacity](@ref ResidualStorageCapacity) | `ResidualStorageCapacity` | [Storage](@ref parameters_storage) |
| [Specified annual demand](@ref SpecifiedAnnualDemand) | `SpecifiedAnnualDemand` | [Demands](@ref parameters_demands) |
| [Specified demand profile](@ref SpecifiedDemandProfile) | `SpecifiedDemandProfile` | [Demands](@ref parameters_demands) |
| [Storage full load hours](@ref StorageFullLoadHours) | `StorageFullLoadHours` | [Storage](@ref parameters_storage) |
| [Storage maximum charge rate](@ref StorageMaxChargeRate) | `StorageMaxChargeRate` | [Storage](@ref parameters_storage) |
| [Storage maximum discharge rate](@ref StorageMaxDischargeRate) | `StorageMaxDischargeRate` | [Storage](@ref parameters_storage) |
| [Storage start level](@ref StorageLevelStart) | `StorageLevelStart` | [Storage](@ref parameters_storage) |
| [Technology from storage](@ref TechnologyFromStorage) | `TechnologyFromStorage` | [Storage](@ref parameters_storage) |
| [Technology group assignment](@ref TTGroup) | `TTGroup` | [Model structure and groupings](@ref parameters_structure) |
| [Technology subsidy](@ref TechnologySubsidy) | `TechnologySubsidy` | [Costs, financing, and subsidies](@ref parameters_costs) |
| [Technology to storage](@ref TechnologyToStorage) | `TechnologyToStorage` | [Storage](@ref parameters_storage) |
| [Time slice group assignment](@ref LTsGroup) | `LTsGroup` | [Model structure and groupings](@ref parameters_structure) |
| [Total annual maximum capacity](@ref TotalAnnualMaxCapacity) | `TotalAnnualMaxCapacity` | [Capacity and investment limits](@ref parameters_capacity_limits) |
| [Total annual maximum capacity investment](@ref TotalAnnualMaxCapacityInvestment) | `TotalAnnualMaxCapacityInvestment` | [Capacity and investment limits](@ref parameters_capacity_limits) |
| [Total annual maximum capacity (by region group)](@ref TotalAnnualMaxCapacityRG) | `TotalAnnualMaxCapacityRG` | [Capacity and investment limits](@ref parameters_capacity_limits) |
| [Total annual maximum capacity investment (by region group)](@ref TotalAnnualMaxCapacityInvestmentRG) | `TotalAnnualMaxCapacityInvestmentRG` | [Capacity and investment limits](@ref parameters_capacity_limits) |
| [Total annual maximum capacity (by technology group)](@ref TotalAnnualMaxCapacityTG) | `TotalAnnualMaxCapacityTG` | [Capacity and investment limits](@ref parameters_capacity_limits) |
| [Total annual maximum capacity investment (by technology group)](@ref TotalAnnualMaxCapacityInvestmentTG) | `TotalAnnualMaxCapacityInvestmentTG` | [Capacity and investment limits](@ref parameters_capacity_limits) |
| [Total annual maximum capacity storage](@ref TotalAnnualMaxCapacityStorage) | `TotalAnnualMaxCapacityStorage` | [Storage](@ref parameters_storage) |
| [Total annual maximum capacity investment storage](@ref TotalAnnualMaxCapacityInvestmentStorage) | `TotalAnnualMaxCapacityInvestmentStorage` | [Storage](@ref parameters_storage) |
| [Total annual minimum capacity](@ref TotalAnnualMinCapacity) | `TotalAnnualMinCapacity` | [Capacity and investment limits](@ref parameters_capacity_limits) |
| [Total annual minimum capacity investment](@ref TotalAnnualMinCapacityInvestment) | `TotalAnnualMinCapacityInvestment` | [Capacity and investment limits](@ref parameters_capacity_limits) |
| [Total annual minimum capacity (by region group)](@ref TotalAnnualMinCapacityRG) | `TotalAnnualMinCapacityRG` | [Capacity and investment limits](@ref parameters_capacity_limits) |
| [Total annual minimum capacity investment (by region group)](@ref TotalAnnualMinCapacityInvestmentRG) | `TotalAnnualMinCapacityInvestmentRG` | [Capacity and investment limits](@ref parameters_capacity_limits) |
| [Total annual minimum capacity (by technology group)](@ref TotalAnnualMinCapacityTG) | `TotalAnnualMinCapacityTG` | [Capacity and investment limits](@ref parameters_capacity_limits) |
| [Total annual minimum capacity investment (by technology group)](@ref TotalAnnualMinCapacityInvestmentTG) | `TotalAnnualMinCapacityInvestmentTG` | [Capacity and investment limits](@ref parameters_capacity_limits) |
| [Total annual minimum capacity storage](@ref TotalAnnualMinCapacityStorage) | `TotalAnnualMinCapacityStorage` | [Storage](@ref parameters_storage) |
| [Total annual minimum capacity investment storage](@ref TotalAnnualMinCapacityInvestmentStorage) | `TotalAnnualMinCapacityInvestmentStorage` | [Storage](@ref parameters_storage) |
| [Total technology annual activity lower limit](@ref TotalTechnologyAnnualActivityLowerLimit) | `TotalTechnologyAnnualActivityLowerLimit` | [Activity limits and production shares](@ref parameters_activity_limits) |
| [Total technology annual activity upper limit](@ref TotalTechnologyAnnualActivityUpperLimit) | `TotalTechnologyAnnualActivityUpperLimit` | [Activity limits and production shares](@ref parameters_activity_limits) |
| [Total technology model period activity lower limit](@ref TotalTechnologyModelPeriodActivityLowerLimit) | `TotalTechnologyModelPeriodActivityLowerLimit` | [Activity limits and production shares](@ref parameters_activity_limits) |
| [Total technology model period activity upper limit](@ref TotalTechnologyModelPeriodActivityUpperLimit) | `TotalTechnologyModelPeriodActivityUpperLimit` | [Activity limits and production shares](@ref parameters_activity_limits) |
| [Trade route](@ref TradeRoute) | `TradeRoute` | [Transmission, nodes, and trade](@ref parameters_transmission) |
| [Transmission availability factor](@ref TransmissionAvailabilityFactor) | `TransmissionAvailabilityFactor` | [Transmission, nodes, and trade](@ref parameters_transmission) |
| [Transmission capacity to activity unit](@ref TransmissionCapacityToActivityUnit) | `TransmissionCapacityToActivityUnit` | [Transmission, nodes, and trade](@ref parameters_transmission) |
| [Transmission maximum annual capacity investment](@ref TransmissionAnnualMaxCapacityInvestment) | `TransmissionAnnualMaxCapacityInvestment` | [Transmission, nodes, and trade](@ref parameters_transmission) |
| [Transmission minimum annual capacity investment](@ref TransmissionAnnualMinCapacityInvestment) | `TransmissionAnnualMinCapacityInvestment` | [Transmission, nodes, and trade](@ref parameters_transmission) |
| [Transmission modeling enabled](@ref TransmissionModelingEnabled) | `TransmissionModelingEnabled` | [Transmission, nodes, and trade](@ref parameters_transmission) |
| [Variable cost](@ref VariableCost) | `VariableCost` | [Costs, financing, and subsidies](@ref parameters_costs) |
| [Year split](@ref YearSplit) | `YearSplit` | [Model structure and groupings](@ref parameters_structure) |
