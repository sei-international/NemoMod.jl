```@meta
CurrentModule = NemoMod
```
# Parameters

NEMO supports a number of parameters that define data and set the terms of constraints for scenarios. As with model [dimensions](@ref dimensions), parameters are specified in a NEMO scenario database. NEMO reads them from the database and uses them to build constraints at run-time. Generally, NEMO does not create separate Julia variables for parameters.

Most parameters are subscripted by one or more dimensions. Parameter tables in a scenario database refer to dimensions by their abbreviation (`r` for [region](@ref region), `t` for [technology](@ref technology), and so on). The abbreviation serves as the name of the dimension's column, and the column should be populated with unique identifiers for the dimension (`val`, `name`, or `id`, depending on the dimension).

## [Accumulated annual demand](@id AccumulatedAnnualDemand)

Description.

#### NEMO database

**Table: `AccumulatedAnnualDemand`**

| Name | Type | Description |
|:--- | :--: |:----------- |
| `id` | integer | Unique identifier for row |
| `r` | text  | Region |
| `f` | text  | Fuel |
| `y` | text  | Year |
| `val` | real  | Parameter value |

## [Annual emission limit](@id AnnualEmissionLimit)

Description.

#### NEMO database

**Table: `AnnualEmissionLimit`**

| Name | Type | Description |
|:--- | :--: |:----------- |
| `id` | integer | Unique identifier for row |
| `r` | text  | Region |
| `e` | text  | Emission |
| `y` | text  | Year |
| `val` | real  | Parameter value |

## [Annual exogenous emission](@id AnnualExogenousEmission)

Description.

#### NEMO database

**Table: `AnnualExogenousEmission`**

| Name | Type | Description |
|:--- | :--: |:----------- |
| `id` | integer | Unique identifier for row |
| `r` | text  | Region |
| `e` | text  | Emission |
| `y` | text  | Year |
| `val` | real  | Parameter value |

## [Availability factor](@id AvailabilityFactor)

Description.

#### NEMO database

**Table: `AvailabilityFactor`**

| Name | Type | Description |
|:--- | :--: |:----------- |
| `id` | integer | Unique identifier for row |
| `r` | text  | Region |
| `t` | text  | Technology |
| `y` | text  | Year |
| `val` | real  | Parameter value |

## [Capacity factor](@id CapacityFactor)

Description.

#### NEMO database

**Table: `CapacityFactor`**

| Name | Type | Description |
|:--- | :--: |:----------- |
| `id` | integer | Unique identifier for row |
| `r` | text  | Region |
| `t` | text  | Technology |
| `l` | text  | Time slice |
| `y` | text  | Year |
| `val` | real  | Parameter value |

## [Capacity of one technology unit](@id CapacityOfOneTechnologyUnit)

Description.

#### NEMO database

**Table: `CapacityOfOneTechnologyUnit`**

| Name | Type | Description |
|:--- | :--: |:----------- |
| `id` | integer | Unique identifier for row |
| `r` | text  | Region |
| `t` | text  | Technology |
| `y` | text  | Year |
| `val` | real  | Parameter value |

## [Capacity to activate unit](@id CapacityToActivateUnit)

Description.

#### NEMO database

**Table: `CapacityToActivateUnit`**

| Name | Type | Description |
|:--- | :--: |:----------- |
| `id` | integer | Unique identifier for row |
| `r` | text  | Region |
| `t` | text  | Technology
| `val` | real  | Parameter value |

## [Capital cost](@id CapitalCost)

Description.

#### NEMO database

**Table: `CapitalCost`**

| Name | Type | Description |
|:--- | :--: |:----------- |
| `id` | integer | Unique identifier for row |
| `r` | text  | Region |
| `t` | text  | Technology |
| `y` | text  | Year |
| `val` | real  | Parameter value |

## [Capital cost storage](@id CapitalCostStorage)

Description.

#### NEMO database

**Table: `CapitalCostStorage`**

| Name | Type | Description |
|:--- | :--: |:----------- |
| `id` | integer | Unique identifier for row |
| `r` | text  | Region |
| `s` | text  | Storage |
| `y` | text  | Year |
| `val` | real  | Parameter value |

## [Default parameters](@id DefaultParams)

Description.

#### NEMO database

**Table: `DefaultParams`**

| Name | Type | Description |
|:--- | :--: |:----------- |
| `id` | integer | Unique identifier for row |
| `tablename` | text  | name of parameter table  |
| `val` | real  | Parameter value |

## [Depreciation method](@id DepreciationMethod)

Description.

#### NEMO database

**Table: `DepreciationMethod`**

| Name | Type | Description |
|:--- | :--: |:----------- |
| `id` | integer | Unique identifier for row |
| `r` | text  | Region |
| `val` | real  | Parameter value |

## [Discount rate](@id DiscountRate)

Description.

#### NEMO database

**Table: `DiscountRate`**

| Name | Type | Description |
|:--- | :--: |:----------- |
| `id` | integer | Unique identifier for row |
| `r` | text  | Region |
| `val` | real  | Parameter value |

## [Emission activity ratio](@id EmissionActivityRatio)

Description.

#### NEMO database

**Table: `EmissionActivityRatio`**

| Name | Type | Description |
|:--- | :--: |:----------- |
| `id` | integer | Unique identifier for row |
| `r` | text  | Region |
| `t` | text  | Technology |
| `e` | text  | Emission |
| `m` | text  | Mode of operation |
| `y` | text  | Year |
| `val` | real  | Parameter value |

## [Emissions penalty](@id EmissionsPenalty)

Description.

#### NEMO database

**Table: `EmissionsPenalty`**

| Name | Type | Description |
|:--- | :--: |:----------- |
| `id` | integer | Unique identifier for row |
| `r` | text  | Region |
| `e` | text  | Emission |
| `y` | text  | Year |
| `val` | real  | Parameter value |

## [Fixed cost](@id FixedCost)

Description.

#### NEMO database

**Table: `FixedCost`**

| Name | Type | Description |
|:--- | :--: |:----------- |
| `id` | integer | Unique identifier for row |
| `r` | text  | Region |
| `t` | text  | Technology |
| `y` | text  | Year |
| `val` | real  | Parameter value |

## [Input activity ratio](@id InputActivityRatio)

Description.

#### NEMO database

**Table: `InputActivityRatio`**

| Name | Type | Description |
|:--- | :--: |:----------- |
| `id` | integer | Unique identifier for row |
| `r` | text  | Region |
| `t` | text  | Technology |
| `f` | text  | Fuel |
| `m` | text  | Mode of operation |
| `y` | text  | Year |
| `val` | real  | Parameter value |

## [Time slice group assignment](@id LTsGroup)

Description.

#### NEMO database

**Table: `LTsGroup`**

| Name | Type | Description |
|:--- | :--: |:----------- |
| `id` | integer | Unique identifier for row |
| `l` | text  | Time slice |
| `lorder` | integer  | |
| `tg2` | text  | Time slice group 2 |
| `tg1` | text  | Time slice group 1 |

## [Minimum storage charge](@id MinStorageCharge)

Description.

#### NEMO database

**Table: `MinStorageCharge`**

| Name | Type | Description |
|:--- | :--: |:----------- |
| `id` | integer | Unique identifier for row |
| `r` | text  | Region |
| `s` | text  | Storage |
| `y` | text  | Year |
| `val` | real  | Parameter value |

## [Model period emission limit](@id ModelPeriodEmissionLimit)

Description.

#### NEMO database

**Table: `ModelPeriodEmissionLimit`**

| Name | Type | Description |
|:--- | :--: |:----------- |
| `id` | integer | Unique identifier for row |
| `r` | text  | Region |
| `e` | text  | Emission |
| `val` | real  | Parameter value |

## [Model period exogenous emission](@id ModelPeriodExogenousEmission)

Description.

#### NEMO database

**Table: `ModelPeriodExogenousEmission`**

| Name | Type | Description |
|:--- | :--: |:----------- |
| `id` | integer | Unique identifier for row |
| `r` | text  | Region |
| `e` | text  | Emission |
| `val` | real  | Parameter value |

## [Nodal distribution demand](@id NodalDistributionDemand)

Description.

#### NEMO database

**Table: `NodalDistributionDemand`**

| Name | Type | Description |
|:--- | :--: |:----------- |
| `id` | integer | Unique identifier for row |
| `n` | text  | Node |
| `f` | text  | Fuel |
| `y` | text  | Year |
| `val` | real  | Parameter value |

## [Nodal distribution storage capacity](@id NodalDistributionStorageCapacity)

Description.

#### NEMO database

**Table: `NodalDistributionStorageCapacity`**

| Name | Type | Description |
|:--- | :--: |:----------- |
| `id` | integer | Unique identifier for row |
| `n` | text  | Node |
| `s` | text  | storage |
| `y` | text  | Year |
| `val` | real  | Parameter value |

## [Nodal distribution technology capacity](@id NodalDistributionTechnologyCapacity)

Description.

#### NEMO database

**Table: `NodalDistributionTechnologyCapacity`**

| Name | Type | Description |
|:--- | :--: |:----------- |
| `id` | integer | Unique identifier for row |
| `n` | text  | Node |
| `t` | text  | Technology |
| `y` | text  | Year |
| `val` | real  | Parameter value |

## [Operational life](@id OperationalLife)

Description.

#### NEMO database

**Table: `OperationalLife`**

| Name | Type | Description |
|:--- | :--: |:----------- |
| `id` | integer | Unique identifier for row |
| `r` | text  | Region |
| `t` | text  | Technology |
| `val` | real  | Parameter value |

## [Operational life storage](@id OperationalLifeStorage)

Description.

#### NEMO database

**Table: `OperationalLifeStorage`**

| Name | Type | Description |
|:--- | :--: |:----------- |
| `id` | integer | Unique identifier for row |
| `r` | text  | Region |
| `s` | text  | Storage |
| `val` | real  | Parameter value |

## [Output activity ratio](@id OutputActivityRatio)

Description.

#### NEMO database

**Table: `OutputActivityRatio`**

| Name | Type | Description |
|:--- | :--: |:----------- |
| `id` | integer | Unique identifier for row |
| `r` | text  | Region |
| `t` | text  | Technology |
| `f` | text  | Fuel |
| `m` | text  | Mode of operation |
| `y` | text  | Year |
| `val` | real  | Parameter value |

## [Renewable energy minimum production target](@id REMinProductionTarget)

Description.

#### NEMO database

**Table: `REMinProductionTarget`**

| Name | Type | Description |
|:--- | :--: |:----------- |
| `id` | integer | Unique identifier for row |
| `r` | text  | Region |
| `y` | text  | Year |
| `val` | real  | Parameter value |

## [Renewable energy tag fuel](@id RETagFuel)

Description.

#### NEMO database

**Table: `RETagFuel`**

| Name | Type | Description |
|:--- | :--: |:----------- |
| `id` | integer | Unique identifier for row |
| `r` | text  | Region |
| `f` | text  | Fuel |
| `y` | text  | Year |
| `val` | real  | Parameter value |

## [Renewable energy tag technology](@id RETagTechnology)

Description.

#### NEMO database

**Table: `RETagTechnology`**

| Name | Type | Description |
|:--- | :--: |:----------- |
| `id` | integer | Unique identifier for row |
| `r` | text  | Region |
| `t` | text  | Technology |
| `y` | text  | Year |
| `val` | real  | Parameter value |

## [Reserve margin](@id ReserveMargin)

Description.

#### NEMO database

**Table: `ReserveMargin`**

| Name | Type | Description |
|:--- | :--: |:----------- |
| `id` | integer | Unique identifier for row |
| `r` | text  | Region |
| `y` | text  | Year |
| `val` | real  | Parameter value |

## [Reserve margin tag fuel](@id ReserveMarginTagFuel)

Description.

#### NEMO database

**Table: `ReserveMarginTagFuel`**

| Name | Type | Description |
|:--- | :--: |:----------- |
| `id` | integer | Unique identifier for row |
| `r` | text  | Region |
| `f` | text  | Fuel |
| `y` | text  | Year |
| `val` | real  | Parameter value |

## [Reserve margin tag technology](@id ReserveMarginTagTechnology)

Description.

#### NEMO database

**Table: `ReserveMarginTagTechnology`**

| Name | Type | Description |
|:--- | :--: |:----------- |
| `id` | integer | Unique identifier for row |
| `r` | text  | Region |
| `t` | text  | Technology |
| `y` | text  | Year |
| `val` | real  | Parameter value |

## [Residual capacity](@id ResidualCapacity)

Description.

#### NEMO database

**Table: `ResidualCapacity`**

| Name | Type | Description |
|:--- | :--: |:----------- |
| `id` | integer | Unique identifier for row |
| `r` | text  | Region |
| `t` | text  | Technology |
| `y` | text  | Year |
| `val` | real  | Parameter value |

## [Residual storage capacity](@id ResidualStorageCapacity)

Description.

#### NEMO database

**Table: `ResidualStorageCapacity`**

| Name | Type | Description |
|:--- | :--: |:----------- |
| `id` | integer | Unique identifier for row |
| `r` | text  | Region |
| `s` | text  | Storage |
| `y` | text  | Year |
| `val` | real  | Parameter value |

## [Specified annual demand](@id SpecifiedAnnualDemand)

Description.

#### NEMO database

**Table: `SpecifiedAnnualDemand`**

| Name | Type | Description |
|:--- | :--: |:----------- |
| `id` | integer | Unique identifier for row |
| `r` | text  | Region |
| `f` | text  | Fuel |
| `y` | text  | Year |
| `val` | real  | Parameter value |

## [Specified demand profile](@id SpecifiedDemandProfile)

Description.

#### NEMO database

**Table: `SpecifiedDemandProfile`**

| Name | Type | Description |
|:--- | :--: |:----------- |
| `id` | integer | Unique identifier for row |
| `r` | text  | Region |
| `f` | text  | Fuel |
| `l` | text  | Time Slice |
| `y` | text  | Year |
| `val` | real  | Parameter value |

## [Storage full load hours](@id StorageFullLoadHours)

Description.

#### NEMO database

**Table: `StorageFullLoadHours`**

| Name | Type | Description |
|:--- | :--: |:----------- |
| `id` | integer | Unique identifier for row |
| `r` | text  | Region |
| `s` | text  | Storage |
| `y` | text  | Year |
| `val` | real  | Parameter value |

## [Storage level start](@id StorageLevelStart)

Description.

#### NEMO database

**Table: `StorageLevelStart`**

| Name | Type | Description |
|:--- | :--: |:----------- |
| `id` | integer | Unique identifier for row |
| `r` | text  | Region |
| `s` | text  | Storage |
| `val` | real  | Parameter value |

## [Storage maximum charge rate](@id StorageMaxChargeRate)

Description.

#### NEMO database

**Table: `StorageMaxChargeRate`**

| Name | Type | Description |
|:--- | :--: |:----------- |
| `id` | integer | Unique identifier for row |
| `r` | text  | Region |
| `s` | text  | Storage |
| `val` | real  | Parameter value |

## [Storage maximum discharge rate](@id StorageMaxDischargeRate)

Description.

#### NEMO database

**Table: `StorageMaxDischargeRate`**

| Name | Type | Description |
|:--- | :--: |:----------- |
| `id` | integer | Unique identifier for row |
| `r` | text  | Region |
| `s` | text  | Storage |
| `val` | real  | Parameter value |

## [Technology to storage](@id TechnologyFromStorage)

Description.

#### NEMO database

**Table: `TechnologyFromStorage`**

| Name | Type | Description |
|:--- | :--: |:----------- |
| `id` | integer | Unique identifier for row |
| `r` | text  | Region |
| `t` | text  | Technology |
| `s` | text  | Storage |
| `m` | text  | Mode of operation |
| `val` | real  | Parameter value |

## [Technology to storage](@id TechnologyToStorage)

Description.

#### NEMO database

**Table: `TechnologyToStorage`**

| Name | Type | Description |
|:--- | :--: |:----------- |
| `id` | integer | Unique identifier for row |
| `r` | text  | Region |
| `t` | text  | Technology |
| `s` | text  | Storage |
| `m` | text  | Mode of operation |
| `val` | real  | Parameter value |

## [Total annual maximum capacity](@id TotalAnnualMaxCapacity)

Description.

#### NEMO database

**Table: `TotalAnnualMaxCapacity`**

| Name | Type | Description |
|:--- | :--: |:----------- |
| `id` | integer | Unique identifier for row |
| `r` | text  | Region |
| `t` | text  | Technology |
| `y` | text  | Year |
| `val` | real  | Parameter value |

## [Total annual maximum capacity investment](@id TotalAnnualMaxCapacityInvestment)

Description.

#### NEMO database

**Table: `TotalAnnualMaxCapacityInvestment`**

| Name | Type | Description |
|:--- | :--: |:----------- |
| `id` | integer | Unique identifier for row |
| `r` | text  | Region |
| `t` | text  | Technology |
| `y` | text  | Year |
| `val` | real  | Parameter value |

## [Total annual maximum capacity investment storage](@id TotalAnnualMaxCapacityInvestmentStorage)

Description.

#### NEMO database

**Table: `TotalAnnualMaxCapacityInvestmentStorage`**

| Name | Type | Description |
|:--- | :--: |:----------- |
| `id` | integer | Unique identifier for row |
| `r` | text  | Region |
| `s` | text  | Storage |
| `y` | text  | Year |
| `val` | real  | Parameter value |

## [Total annual maximum capacity storage](@id TotalAnnualMaxCapacityStorage)

Description.

#### NEMO database

**Table: `TotalAnnualMaxCapacityStorage`**

| Name | Type | Description |
|:--- | :--: |:----------- |
| `id` | integer | Unique identifier for row |
| `r` | text  | Region |
| `s` | text  | Storage |
| `y` | text  | Year |
| `val` | real  | Parameter value |

## [Total annual minimum capacity](@id TotalAnnualMinCapacity)

Description.

#### NEMO database

**Table: `TotalAnnualMinCapacity`**

| Name | Type | Description |
|:--- | :--: |:----------- |
| `id` | integer | Unique identifier for row |
| `r` | text  | Region |
| `t` | text  | Technology |
| `y` | text  | Year |
| `val` | real  | Parameter value |

## [Total annual minimum capacity investment](@id TotalAnnualMinCapacityInvestment)

Description.

#### NEMO database

**Table: `TotalAnnualMinCapacityInvestment`**

| Name | Type | Description |
|:--- | :--: |:----------- |
| `id` | integer | Unique identifier for row |
| `r` | text  | Region |
| `t` | text  | Technology |
| `y` | text  | Year |
| `val` | real  | Parameter value |

## [Total annual minimum capacity investment storage](@id TotalAnnualMinCapacityInvestmentStorage)

Description.

#### NEMO database

**Table: `TotalAnnualMinCapacityInvestmentStorage`**

| Name | Type | Description |
|:--- | :--: |:----------- |
| `id` | integer | Unique identifier for row |
| `r` | text  | Region |
| `s` | text  | Storage |
| `y` | text  | Year |
| `val` | real  | Parameter value |

## [Total annual minimum capacity storage](@id TotalAnnualMinCapacityStorage)

Description.

#### NEMO database

**Table: `TotalAnnualMinCapacityStorage`**

| Name | Type | Description |
|:--- | :--: |:----------- |
| `id` | integer | Unique identifier for row |
| `r` | text  | Region |
| `s` | text  | Storage |
| `y` | text  | Year |
| `val` | real  | Parameter value |

## [Total technology annual activity lower limit](@id TotalTechnologyAnnualActivityLowerLimit)

Description.

#### NEMO database

**Table: `TotalTechnologyAnnualActivityLowerLimit`**

| Name | Type | Description |
|:--- | :--: |:----------- |
| `id` | integer | Unique identifier for row |
| `r` | text  | Region |
| `t` | text  | Technology |
| `y` | text  | Year |
| `val` | real  | Parameter value |

## [Total technology annual activity upper limit](@id TotalTechnologyAnnualActivityUpperLimit)

Description.

#### NEMO database

**Table: `TotalTechnologyAnnualActivityUpperLimit`**

| Name | Type | Description |
|:--- | :--: |:----------- |
| `id` | integer | Unique identifier for row |
| `r` | text  | Region |
| `t` | text  | Technology |
| `y` | text  | Year |
| `val` | real  | Parameter value |

## [Total technology model period activity lower limit](@id TotalTechnologyModelPeriodActivityLowerLimit)

Description.

#### NEMO database

**Table: `TotalTechnologyModelPeriodActivityLowerLimit`**

| Name | Type | Description |
|:--- | :--: |:----------- |
| `id` | integer | Unique identifier for row |
| `r` | text  | Region |
| `t` | text  | Technology|
| `val` | real  | Parameter value |

## [Total technology model period activity upper limit](@id TotalTechnologyModelPeriodActivityUpperLimit)

Description.

#### NEMO database

**Table: `TotalTechnologyModelPeriodActivityUpperLimit`**

| Name | Type | Description |
|:--- | :--: |:----------- |
| `id` | integer | Unique identifier for row |
| `r` | text  | Region |
| `t` | text  | Technology|
| `val` | real  | Parameter value |

## [Trade route](@id TradeRoute)

Description.

#### NEMO database

**Table: `TradeRoute`**

| Name | Type | Description |
|:--- | :--: |:----------- |
| `id` | integer | Unique identifier for row |
| `r` | text  | First region connected by trade route |
| `rr` | text  | Second region connected by trade route |
| `f` | text  | Fuel |
| `y` | text  | Year |
| `val` | real  | Parameter value |

## [Transmission capacity to activity unit](@id TransmissionCapacityToActivityUnit)

Description.

#### NEMO database

**Table: `TransmissionCapacityToActivityUnit`**

| Name | Type | Description |
|:--- | :--: |:----------- |
| `id` | integer | Unique identifier for row |
| `f` | text  | Fuel |
| `val` | real  | Parameter value |

## [Transmission modeling enabled](@id TransmissionModelingEnabled)

Description.

#### NEMO database

**Table: `TransmissionModelingEnabled`**

| Name | Type | Description |
|:--- | :--: |:----------- |
| `id` | integer | Unique identifier for row |
| `r` | text  | Region |
| `f` | text  | Fuel |
| `y` | text  | Year |
| `type` | integer  |  |

## [Variable cost](@id VariableCost)

Description.

#### NEMO database

**Table: `VariableCost`**

| Name | Type | Description |
|:--- | :--: |:----------- |
| `id` | integer | Unique identifier for row |
| `r` | text  | Region |
| `t` | text  | Technology |
| `m` | text  | Mode of operation |
| `y` | text  | Year |
| `val` | real  | Parameter value |

## [Year split](@id )YearSplit

Description.

#### NEMO database

**Table: `YearSplit`**

| Name | Type | Description |
|:--- | :--: |:----------- |
| `id` | integer | Unique identifier for row |
| `l` | text  | Time slice |
| `y` | text  | Year |
| `val` | real  | Parameter value |
|
