```@meta
CurrentModule = NemoMod
```
# [Parameters](@id parameters)

NEMO includes a number of parameters that define data and set the terms of constraints for scenarios. As with model [dimensions](@ref dimensions), parameters are specified in a NEMO [scenario database](@ref scenario_db). NEMO reads them from the database and uses them to build constraints at run-time. Generally, NEMO does not create separate Julia variables for parameters.

Most parameters are subscripted by one or more dimensions. Parameter tables in a scenario database refer to dimensions by their abbreviation (`r` for [region](@ref region), `t` for [technology](@ref technology), and so on). The abbreviation serves as the name of the dimension's column, and the column should be populated with unique identifiers for the dimension (`val`, `name`, or `id`, depending on the dimension).

## [Accumulated annual demand](@id AccumulatedAnnualDemand)

Exogenous demand that is not time sliced. NEMO ensures the demand is met, but it may be met at any point in the specified [year](@ref year).

#### Scenario database

**Table: `AccumulatedAnnualDemand`**

| Name | Type | Description |
|:--- | :--: |:----------- |
| `id` | integer | Unique identifier for row |
| `r` | text  | Region |
| `f` | text  | Fuel |
| `y` | text  | Year |
| `val` | real  | Demand (region's energy [unit](@ref uoms)) |

## [Annual emission limit](@id AnnualEmissionLimit)

Maximum emissions allowed in the specified [year](@ref year).

#### Scenario database

**Table: `AnnualEmissionLimit`**

| Name | Type | Description |
|:--- | :--: |:----------- |
| `id` | integer | Unique identifier for row |
| `r` | text  | Region |
| `e` | text  | Emission |
| `y` | text  | Year |
| `val` | real  | Amount of emissions (scenario's emissions [unit](@ref uoms)) |

## [Annual exogenous emission](@id AnnualExogenousEmission)

Exogenously specified emissions, assumed to occur regardless of what else is happening in the energy system.

#### Scenario database

**Table: `AnnualExogenousEmission`**

| Name | Type | Description |
|:--- | :--: |:----------- |
| `id` | integer | Unique identifier for row |
| `r` | text  | Region |
| `e` | text  | Emission |
| `y` | text  | Year |
| `val` | real  | Amount of emissions (scenario's emissions [unit](@ref uoms)) |

## [Availability factor](@id AvailabilityFactor)

*Not currently used.*

## [Capacity factor](@id CapacityFactor)

Fraction of time a [technology](@ref technology) is available to operate.

#### Scenario database

**Table: `CapacityFactor`**

| Name | Type | Description |
|:--- | :--: |:----------- |
| `id` | integer | Unique identifier for row |
| `r` | text  | Region |
| `t` | text  | Technology |
| `l` | text  | Time slice |
| `y` | text  | Year |
| `val` | real  | Fraction (0 to 1) |

## [Capacity of one technology unit](@id CapacityOfOneTechnologyUnit)

Increment in which endogenously determined capacity is added for a [technology](@ref technology).

!!! warning
    If this parameter is defined, NEMO uses an integer variable to solve for the technology's endogenous capacity. This can substantially increase model run-time. If the parameter is not defined, a continuous variable is used instead.

#### Scenario database

**Table: `CapacityOfOneTechnologyUnit`**

| Name | Type | Description |
|:--- | :--: |:----------- |
| `id` | integer | Unique identifier for row |
| `r` | text  | Region |
| `t` | text  | Technology |
| `y` | text  | Year |
| `val` | real  | Increment for endogenous capacity additions (region's power [unit](@ref uoms)) |

## [Capacity to activity unit](@id CapacityToActivityUnit)

Factor relating a [region's](@ref region) power unit to its energy unit. See [Units of measure](@ref uoms).

#### Scenario database

**Table: `CapacityToActivityUnit`**

| Name | Type | Description |
|:--- | :--: |:----------- |
| `id` | integer | Unique identifier for row |
| `r` | text  | Region |
| `t` | text  | Technology
| `val` | real  | Factor value (region's energy [unit](@ref uoms) / (power unit * year)) |

## [Capital cost](@id CapitalCost)

Cost to build a unit of capacity for the specified [technology](@ref technology).

#### Scenario database

**Table: `CapitalCost`**

| Name | Type | Description |
|:--- | :--: |:----------- |
| `id` | integer | Unique identifier for row |
| `r` | text  | Region |
| `t` | text  | Technology |
| `y` | text  | Year |
| `val` | real  | Cost (scenario's cost [unit](@ref uoms) / region's power unit) |

## [Capital cost storage](@id CapitalCostStorage)

Cost to build a unit of capacity for the specified [storage](@ref storage).

!!! tip
    Since storage is typically linked to charging and discharging [technologies](@ref technology) (see [`TechnologyToStorage`](@ref TechnologyToStorage) and [`TechnologyFromStorage`](@ref TechnologyFromStorage)), and capital costs are typically defined for those technologies, it may not be necessary to use this parameter. If it is used, the costs specified by `CapitalCostStorage` are added to the technology costs.

#### Scenario database

**Table: `CapitalCostStorage`**

| Name | Type | Description |
|:--- | :--: |:----------- |
| `id` | integer | Unique identifier for row |
| `r` | text  | Region |
| `s` | text  | Storage |
| `y` | text  | Year |
| `val` | real  | Cost (scenario's cost [unit](@ref uoms) / region's energy unit) |

!!! note
    Note that capacity for storage is denominated in energy terms.

## [Default parameters](@id DefaultParams)

Default value for the parameter identified by `tablename`.

#### Scenario database

**Table: `DefaultParams`**

| Name | Type | Description |
|:--- | :--: |:----------- |
| `id` | integer | Unique identifier for row |
| `tablename` | text  | Name of parameter table  |
| `val` | real  | Default value |

## [Depreciation method](@id DepreciationMethod)

Method for calculating the salvage value of [technology](@ref technology), [storage](@ref storage), and [transmission line](@ref transmissionline) capacity existing at the end of the modeling period.

* 1: Sinking fund depreciation (assuming the [`DiscountRate`](@ref DiscountRate) is not 0; if it is, straight line depreciation is used instead)

* 2: Straight line depreciation

#### Scenario database

**Table: `DepreciationMethod`**

| Name | Type | Description |
|:--- | :--: |:----------- |
| `id` | integer | Unique identifier for row |
| `r` | text  | Region |
| `val` | real  | Depreciation method (1 or 2) |

## [Discount rate](@id DiscountRate)

Rate used to discount costs in a [region](@ref region).

#### Scenario database

**Table: `DiscountRate`**

| Name | Type | Description |
|:--- | :--: |:----------- |
| `id` | integer | Unique identifier for row |
| `r` | text  | Region |
| `val` | real  | Rate (0 to 1) |

## [Emission penalty](@id EmissionsPenalty)

Cost of emissions.

#### Scenario database

**Table: `EmissionsPenalty`**

| Name | Type | Description |
|:--- | :--: |:----------- |
| `id` | integer | Unique identifier for row |
| `r` | text  | Region |
| `e` | text  | Emission |
| `y` | text  | Year |
| `val` | real  | Cost (scenario's cost [unit](@ref uoms) / scenario's emissions unit) |

## [Emissions activity ratio](@id EmissionActivityRatio)

Emission factor for the indicated [technology](@ref technology) and [mode](@ref mode_of_operation).

#### Scenario database

**Table: `EmissionActivityRatio`**

| Name | Type | Description |
|:--- | :--: |:----------- |
| `id` | integer | Unique identifier for row |
| `r` | text  | Region |
| `t` | text  | Technology |
| `e` | text  | Emission |
| `m` | text  | Mode of operation |
| `y` | text  | Year |
| `val` | real  | Factor (scenario's emissions [unit](@ref uoms) / region's energy unit) |

## [Fixed cost](@id FixedCost)

Fixed operation and maintenance costs for a [technology](@ref technology).

#### Scenario database

**Table: `FixedCost`**

| Name | Type | Description |
|:--- | :--: |:----------- |
| `id` | integer | Unique identifier for row |
| `r` | text  | Region |
| `t` | text  | Technology |
| `y` | text  | Year |
| `val` | real  | Cost (scenario's cost [unit](@ref uoms) / region's power unit) |

## [Input activity ratio](@id InputActivityRatio)

Factor multiplied by dispatched capacity to determine the use (input) of the specified [fuel](@ref fuel). `InputActivityRatio` is used in conjunction with [`OutputActivityRatio`](@ref OutputActivityRatio). A common approach is to:

1. Set the `InputActivityRatio` for input fuels to the reciprocal of the [technology's](@ref technology) efficiency.
2. Set the `OutputActivityRatio` for output fuels to 1.

For example, if a technology had an efficiency of 80%, the `InputActivityRatio` for inputs would be 1.25, and the `OutputActivityRatio` for outputs would be 1.0.

!!! note
    NEMO will not simulate activity for a [region](@ref region), technology, [mode of operation](@ref mode_of_operation), and [year](@ref year) unless you define a corresponding non-zero `OutputActivityRatio` or `InputActivityRatio`. In other words, activity is only simulated when it produces or consumes a fuel.

#### Scenario database

**Table: `InputActivityRatio`**

| Name | Type | Description |
|:--- | :--: |:----------- |
| `id` | integer | Unique identifier for row |
| `r` | text  | Region |
| `t` | text  | Technology |
| `f` | text  | Fuel |
| `m` | text  | Mode of operation |
| `y` | text  | Year |
| `val` | real  | Factor |

## [Minimum storage charge](@id MinStorageCharge)

Minimum fraction of a [storage's](@ref storage) capacity that must be charged. NEMO ensures the charge never drops below this level.

!!! note
    When this parameter is set, NEMO assumes that new storage capacity (endogenous and exogenous) is delivered with the minimum charge.

!!! warning
    If you set a minimum storage charge, make sure the corresponding [storage start level](@ref StorageLevelStart) is at least as large as the minimum. Otherwise your model will be infeasible.

#### Scenario database

**Table: `MinStorageCharge`**

| Name | Type | Description |
|:--- | :--: |:----------- |
| `id` | integer | Unique identifier for row |
| `r` | text  | Region |
| `s` | text  | Storage |
| `y` | text  | Year |
| `val` | real  | Fraction (0 to 1) |

## [Model period emission limit](@id ModelPeriodEmissionLimit)

Maximum emissions allowed in the modeling period (i.e., over all [years](@ref year)).

#### Scenario database

**Table: `ModelPeriodEmissionLimit`**

| Name | Type | Description |
|:--- | :--: |:----------- |
| `id` | integer | Unique identifier for row |
| `r` | text  | Region |
| `e` | text  | Emission |
| `val` | real  | Amount of emissions (scenario's emissions [unit](@ref uoms)) |

## [Model period exogenous emission](@id ModelPeriodExogenousEmission)

Exogenously specified emissions, counted toward the [model period emission limit](@ref ModelPeriodEmissionLimit) regardless of what else is happening in the energy system.

#### Scenario database

**Table: `ModelPeriodExogenousEmission`**

| Name | Type | Description |
|:--- | :--: |:----------- |
| `id` | integer | Unique identifier for row |
| `r` | text  | Region |
| `e` | text  | Emission |
| `val` | real  | Amount of emissions (scenario's emissions [unit](@ref uoms)) |

## [Nodal distribution demand](@id NodalDistributionDemand)

For the specified [node](@ref node) and the [region](@ref region) containing it, fraction of the region's exogenously defined demand for the specified [fuel](@ref fuel) that is assigned to the node. If in a given [year](@ref year) transmission modeling is enabled for a fuel and region (see [`TransmissionModelingEnabled`](@ref TransmissionModelingEnabled)), and the fuel has exogenous demands in the region, the sum of `NodalDistributionDemand` across the nodes in the region should be 1.

#### Scenario database

**Table: `NodalDistributionDemand`**

| Name | Type | Description |
|:--- | :--: |:----------- |
| `id` | integer | Unique identifier for row |
| `n` | text  | Node |
| `f` | text  | Fuel |
| `y` | text  | Year |
| `val` | real  | Fraction (0 to 1) |

## [Nodal distribution storage capacity](@id NodalDistributionStorageCapacity)

For the specified [node](@ref node) and the [region](@ref region) containing it, fraction of the specified [storage's](@ref storage) capacity in the region that is assigned to the node.

#### Scenario database

**Table: `NodalDistributionStorageCapacity`**

| Name | Type | Description |
|:--- | :--: |:----------- |
| `id` | integer | Unique identifier for row |
| `n` | text  | Node |
| `s` | text  | storage |
| `y` | text  | Year |
| `val` | real  | Fraction (0 to 1) |

## [Nodal distribution technology capacity](@id NodalDistributionTechnologyCapacity)

For the specified [node](@ref node) and the [region](@ref region) containing it, fraction of the specified [technology's](@ref technology) capacity in the region that is assigned to the node.

#### Scenario database

**Table: `NodalDistributionTechnologyCapacity`**

| Name | Type | Description |
|:--- | :--: |:----------- |
| `id` | integer | Unique identifier for row |
| `n` | text  | Node |
| `t` | text  | Technology |
| `y` | text  | Year |
| `val` | real  | Fraction (0 to 1) |

## [Operational life](@id OperationalLife)

Lifetime of a [technology](@ref technology) in years. NEMO uses this parameter to:

1. Retire endogenously determined capacity. If a unit of capacity is built endogenously in [year](@ref year) `y`, NEMO will retire the capacity in year `y + OperationalLife`.
2. Calculate the salvage value of endogenously determined capacity remaining at the end of the modeling period (see [`DepreciationMethod`](@ref DepreciationMethod)).

In this way, the parameter serves as both an operational and an economic lifetime.

!!! note
    NEMO does not automatically retire exogenously specified technology capacity, which is defined by [`ResidualCapacity`](@ref ResidualCapacity). It is up to you to do so in the values you provide for `ResidualCapacity`.

#### Scenario database

**Table: `OperationalLife`**

| Name | Type | Description |
|:--- | :--: |:----------- |
| `id` | integer | Unique identifier for row |
| `r` | text  | Region |
| `t` | text  | Technology |
| `val` | real  | Lifetime (years) |

## [Operational life storage](@id OperationalLifeStorage)

Lifetime of a [storage](@ref storage) in years. NEMO uses this parameter to:

1. Retire endogenously determined capacity. If a unit of capacity is built endogenously in [year](@ref year) `y`, NEMO will retire the capacity in year `y + OperationalLife`.
2. Calculate the salvage value of endogenously determined capacity remaining at the end of the modeling period (see [`DepreciationMethod`](@ref DepreciationMethod)).

In this way, the parameter serves as both an operational and an economic lifetime.

!!! note
    NEMO does not automatically retire exogenously specified storage capacity, which is defined by [`ResidualStorageCapacity`](@ref ResidualStorageCapacity). It is up to you to do so in the values you provide for `ResidualStorageCapacity`.

#### Scenario database

**Table: `OperationalLifeStorage`**

| Name | Type | Description |
|:--- | :--: |:----------- |
| `id` | integer | Unique identifier for row |
| `r` | text  | Region |
| `s` | text  | Storage |
| `val` | real  | Lifetime (years) |

## [Output activity ratio](@id OutputActivityRatio)

Factor multiplied by dispatched capacity to determine the production (output) of the specified [fuel](@ref fuel). `OutputActivityRatio` is used in conjunction with [`InputActivityRatio`](@ref InputActivityRatio). A common approach is to:

1. Set the `InputActivityRatio` for input fuels to the reciprocal of the [technology's](@ref technology) efficiency; and
2. Set the `OutputActivityRatio` for output fuels to 1.

For example, if a technology had an efficiency of 80%, the `InputActivityRatio` for inputs would be 1.25, and the `OutputActivityRatio` for outputs would be 1.0.

!!! note
    NEMO will not simulate activity for a [region](@ref region), technology, [mode of operation](@ref mode_of_operation), and [year](@ref year) unless you define a corresponding non-zero `OutputActivityRatio` or `InputActivityRatio`. In other words, activity is only simulated when it produces or consumes a fuel.

#### Scenario database

**Table: `OutputActivityRatio`**

| Name | Type | Description |
|:--- | :--: |:----------- |
| `id` | integer | Unique identifier for row |
| `r` | text  | Region |
| `t` | text  | Technology |
| `f` | text  | Fuel |
| `m` | text  | Mode of operation |
| `y` | text  | Year |
| `val` | real  | Factor |

## [Ramp rate](@id RampRate)

Fraction of a [technology's](@ref technology) available capacity that can be brought online or taken offline in a [time slice](@ref timeslice) and [year](@ref year). Ramp rates determine how quickly a technology's utilization can change. NEMO ignores ramp rates of 1.0 (i.e., 100%) since they effectively don't impose a limit.

#### Scenario database

**Table: `RampRate`**

| Name | Type | Description |
|:--- | :--: |:----------- |
| `id` | integer | Unique identifier for row |
| `r` | text  | Region |
| `t` | text  | Technology |
| `y` | text  | Year |
| `l` | text  | Time slice |
| `val` | real  | Fraction (0 to 1) |

## [Ramping reset](@id RampingReset)

Indicator that determines which [time slices](@ref timeslice) are exempt from [ramp rate](@ref RampRate) limitations. NEMO can set technology utilization to any level in these time slices. The following values are supported for this parameter:

* 0 - Exempts the first time slice in each [year](@ref year).
* 1 - Exempts the first time slice in each [time slice group 1](@ref tsgroup1) and year.
* 2 - Exempts the first time slice in each [time slice group 2](@ref tsgroup2), time slice group 1, and year.

Note that because of the way time slices and groups are configured in NEMO, these values build on one another. For example, the first time slice in each year is exempted in all cases, and the first slice in each group 1 and year is exempted when the value is 2. If you don't specify a value for this parameter, NEMO assumes the value is 2.

#### Scenario database

**Table: `RampingReset`**

| Name | Type | Description |
|:--- | :--: |:----------- |
| `id` | integer | Unique identifier for row |
| `r` | text  | Region |
| `val` | integer  | 0, 1, or 2 |

## [Renewable energy minimum production target](@id REMinProductionTarget)

Fraction of production of [fuels](@ref fuel) tagged with [`RETagFuel`](@ref RETagFuel) that constitutes a renewable energy target. NEMO ensures that production by [technologies](@ref technology) tagged with [`RETagTechnology`](@ref RETagTechnology) meets or exceeds the target, pro-rating each technology's production by its `RETagTechnology`. To take a specific example, suppose that in a given [region](@ref region) and [year](@ref year),

* There is one fuel - electricity - whose `RETagFuel` is 1;

* Total electricity production is 100 (in the region's energy [unit](@ref uoms));

* `REMinProductionTarget` is 0.5; and

* There are two technologies, `t1` with an `RETagTechnology` of 0.75 and `t2` with an `RETagTechnology` of 0.5.

Then NEMO will make sure that 75% of `t1`'s production + 50% of `t2`'s production is at least 50 energy units.

#### Scenario database

**Table: `REMinProductionTarget`**

| Name | Type | Description |
|:--- | :--: |:----------- |
| `id` | integer | Unique identifier for row |
| `r` | text  | Region |
| `y` | text  | Year |
| `val` | real  | Fraction (0 to 1) |

## [Renewable energy tag fuel](@id RETagFuel)

Indicator of whether a fuel is included when calculating the [renewable energy minimum production target](@ref REMinProductionTarget).

#### Scenario database

**Table: `RETagFuel`**

| Name | Type | Description |
|:--- | :--: |:----------- |
| `id` | integer | Unique identifier for row |
| `r` | text  | Region |
| `f` | text  | Fuel |
| `y` | text  | Year |
| `val` | real  | Indicator (0 for no, 1 for yes) |

!!! tip
    It is not necessary to populate zeros in `RETagFuel` for fuels that are excluded from the renewable energy minimum production target. NEMO assumes exclusion if a fuel isn't represented in the table.

## [Renewable energy tag technology](@id RETagTechnology)

Fraction of a [technology's](@ref technology) production that counts toward meeting the [renewable energy minimum production target](@ref REMinProductionTarget).

#### Scenario database

**Table: `RETagTechnology`**

| Name | Type | Description |
|:--- | :--: |:----------- |
| `id` | integer | Unique identifier for row |
| `r` | text  | Region |
| `t` | text  | Technology |
| `y` | text  | Year |
| `val` | real  | Fraction (0 to 1) |

## [Reserve margin](@id ReserveMargin)

Multiplier that causes NEMO to deploy extra [technology](@ref technology) capacity as a reserve. In each [year](@ref year) and [time slice](@ref timeslice), NEMO ensures that the capacity of [technologies](@ref technology) tagged with [`ReserveMarginTagTechnology`](@ref ReserveMarginTagTechnology) is at least `ReserveMargin` times the rate of production of [fuels](@ref fuel) tagged with [`ReserveMarginTagFuel`](@ref ReserveMarginTagFuel). Technology capacity is pro-rated by `ReserveMarginTagTechnology` in these calculations.

#### Scenario database

**Table: `ReserveMargin`**

| Name | Type | Description |
|:--- | :--: |:----------- |
| `id` | integer | Unique identifier for row |
| `r` | text  | Region |
| `y` | text  | Year |
| `val` | real  | Multiplier (typically > 0; e.g., 1.15 for a 15% reserve margin) |

## [Reserve margin tag fuel](@id ReserveMarginTagFuel)

Indicator of whether a fuel is included in [reserve margin](@ref ReserveMargin) calculations.

#### Scenario database

**Table: `ReserveMarginTagFuel`**

| Name | Type | Description |
|:--- | :--: |:----------- |
| `id` | integer | Unique identifier for row |
| `r` | text  | Region |
| `f` | text  | Fuel |
| `y` | text  | Year |
| `val` | real  | Indicator (0 for no, 1 for yes) |

!!! tip
    It is not necessary to populate zeros in `ReserveMarginTagFuel` for fuels that are excluded from reserve margin calculations. NEMO assumes exclusion if a fuel isn't represented in the table.

## [Reserve margin tag technology](@id ReserveMarginTagTechnology)

Fraction of a [technology's](@ref technology) capacity that counts toward the [reserve margin](@ref ReserveMargin).

#### Scenario database

**Table: `ReserveMarginTagTechnology`**

| Name | Type | Description |
|:--- | :--: |:----------- |
| `id` | integer | Unique identifier for row |
| `r` | text  | Region |
| `t` | text  | Technology |
| `y` | text  | Year |
| `val` | real  | Fraction (0 to 1) |

## [Residual capacity](@id ResidualCapacity)

Exogenously specified capacity for a [technology](@ref technology). Note that NEMO does not automatically retire this capacity; it is up to you to do so in the values you provide for `ResidualCapacity`.

#### Scenario database

**Table: `ResidualCapacity`**

| Name | Type | Description |
|:--- | :--: |:----------- |
| `id` | integer | Unique identifier for row |
| `r` | text  | Region |
| `t` | text  | Technology |
| `y` | text  | Year |
| `val` | real  | Capacity (region's power [unit](@ref uoms)) |

## [Residual storage capacity](@id ResidualStorageCapacity)

Exogenously specified capacity for a [storage](@ref storage). Note that NEMO does not automatically retire this capacity; it is up to you to do so in the values you provide for `ResidualStorageCapacity`.

#### Scenario database

**Table: `ResidualStorageCapacity`**

| Name | Type | Description |
|:--- | :--: |:----------- |
| `id` | integer | Unique identifier for row |
| `r` | text  | Region |
| `s` | text  | Storage |
| `y` | text  | Year |
| `val` | real  | Capacity (region's energy [unit](@ref uoms)) |

## [Specified annual demand](@id SpecifiedAnnualDemand)

Time-sliced exogenous demand. Use this parameter to specify the total demand in a [year](@ref year), and [`SpecifiedDemandProfile`](@ref SpecifiedDemandProfile) to assign the demand to [time slices](@ref timeslice). NEMO ensures the demand is met in each time slice.

#### Scenario database

**Table: `SpecifiedAnnualDemand`**

| Name | Type | Description |
|:--- | :--: |:----------- |
| `id` | integer | Unique identifier for row |
| `r` | text  | Region |
| `f` | text  | Fuel |
| `y` | text  | Year |
| `val` | real  | Demand (region's energy [unit](@ref uoms)) |

## [Specified demand profile](@id SpecifiedDemandProfile)

Fraction of [specified annual demand](@ref SpecifiedAnnualDemand) assigned to a [time slice](@ref timeslice). For a given [fuel](@ref fuel) and [year](@ref year), the sum of `SpecifiedDemandProfile` across time slices should be 1.

#### Scenario database

**Table: `SpecifiedDemandProfile`**

| Name | Type | Description |
|:--- | :--: |:----------- |
| `id` | integer | Unique identifier for row |
| `r` | text  | Region |
| `f` | text  | Fuel |
| `l` | text  | Time Slice |
| `y` | text  | Year |
| `val` | real  | Fraction (0 to 1) |

## [Storage full load hours](@id StorageFullLoadHours)

Factor relating endogenously determined capacity for a [storage](@ref storage) and [technologies](@ref technology) that discharge it (see [TechnologyFromStorage](@ref TechnologyFromStorage)). When this parameter is specified, each unit of endogenous discharging capacity is accompanied by enough endogenous storage capacity to power it for the full load hours.

#### Scenario database

**Table: `StorageFullLoadHours`**

| Name | Type | Description |
|:--- | :--: |:----------- |
| `id` | integer | Unique identifier for row |
| `r` | text  | Region |
| `s` | text  | Storage |
| `y` | text  | Year |
| `val` | real  | Hours |

## [Storage maximum charge rate](@id StorageMaxChargeRate)

Maximum charging rate for a [storage](@ref storage).

!!! tip
    When storage is linked to charging [technologies](@ref technology) (see [`TechnologyToStorage`](@ref TechnologyToStorage)), the capacity of these technologies also limits the charging rate of the storage. This can obviate `StorageMaxChargeRate` in many cases.

#### Scenario database

**Table: `StorageMaxChargeRate`**

| Name | Type | Description |
|:--- | :--: |:----------- |
| `id` | integer | Unique identifier for row |
| `r` | text  | Region |
| `s` | text  | Storage |
| `val` | real  | Charging rate (region's energy [unit](@ref uoms) / year) |

## [Storage maximum discharge rate](@id StorageMaxDischargeRate)

Maximum discharging rate for a [storage](@ref storage).

!!! tip
    When storage is linked to discharging [technologies](@ref technology) (see [`TechnologyFromStorage`](@ref TechnologyFromStorage)), the capacity of these technologies also limits the discharging rate of the storage. This can obviate `StorageMaxDischargeRate` in many cases.

#### Scenario database

**Table: `StorageMaxDischargeRate`**

| Name | Type | Description |
|:--- | :--: |:----------- |
| `id` | integer | Unique identifier for row |
| `r` | text  | Region |
| `s` | text  | Storage |
| `val` | real  | Discharging rate (region's energy [unit](@ref uoms) / year) |

## [Storage start level](@id StorageLevelStart)

Fraction of exogenous [storage](@ref storage) capacity that is charged at the start of the modeling period.

#### Scenario database

**Table: `StorageLevelStart`**

| Name | Type | Description |
|:--- | :--: |:----------- |
| `id` | integer | Unique identifier for row |
| `r` | text  | Region |
| `s` | text  | Storage |
| `val` | real  | Fraction (0 to 1) |

## [Technology from storage](@id TechnologyFromStorage)

Indicator of whether a [technology](@ref technology) can discharge a [storage](@ref storage).

#### Scenario database

**Table: `TechnologyFromStorage`**

| Name | Type | Description |
|:--- | :--: |:----------- |
| `id` | integer | Unique identifier for row |
| `r` | text  | Region |
| `t` | text  | Technology |
| `s` | text  | Storage |
| `m` | text  | Mode of operation |
| `val` | real  | Indicator (0 for no, 1 for yes) |

!!! tip
    It is not necessary to populate zeros in `TechnologyFromStorage` for technologies that aren't connected to a storage. NEMO assumes no connection if a technology isn't represented in the table.

## [Technology to storage](@id TechnologyToStorage)

Indicator of whether a [technology](@ref technology) can charge a [storage](@ref storage).

#### Scenario database

**Table: `TechnologyToStorage`**

| Name | Type | Description |
|:--- | :--: |:----------- |
| `id` | integer | Unique identifier for row |
| `r` | text  | Region |
| `t` | text  | Technology |
| `s` | text  | Storage |
| `m` | text  | Mode of operation |
| `val` | real  | Indicator (0 for no, 1 for yes) |

!!! tip
    It is not necessary to populate zeros in `TechnologyToStorage` for technologies that aren't connected to a storage. NEMO assumes no connection if a technology isn't represented in the table.

## [Time slice group assignment](@id LTsGroup)

Map of [time slices](@ref timeslice) to time slice groups. Each time slice must belong to one [time slice 1](@ref tsgroup1) and one [time slice group 2](@ref tsgroup2).

#### Scenario database

**Table: `LTsGroup`**

| Name | Type | Description |
|:--- | :--: |:----------- |
| `id` | integer | Unique identifier for row |
| `l` | text  | Time slice |
| `lorder` | integer | Order of time slice within time slice group 2 (1 for first time slice, incremented by 1 for each succeeding time slice) |
| `tg2` | text  | Time slice group 2 |
| `tg1` | text  | Time slice group 1 |

## [Total annual maximum capacity](@id TotalAnnualMaxCapacity)

Maximum capacity for a [technology](@ref technology) in a [year](@ref year) (including both exogenous and endogenous capacity). Only specify this parameter if you want to enforce a particular limit.

#### Scenario database

**Table: `TotalAnnualMaxCapacity`**

| Name | Type | Description |
|:--- | :--: |:----------- |
| `id` | integer | Unique identifier for row |
| `r` | text  | Region |
| `t` | text  | Technology |
| `y` | text  | Year |
| `val` | real  | Capacity (region's power [unit](@ref uoms)) |

## [Total annual maximum capacity investment](@id TotalAnnualMaxCapacityInvestment)

Maximum addition of endogenously determined capacity for a [technology](@ref technology) in a [year](@ref year). Only specify this parameter if you want to enforce a particular limit.

#### Scenario database

**Table: `TotalAnnualMaxCapacityInvestment`**

| Name | Type | Description |
|:--- | :--: |:----------- |
| `id` | integer | Unique identifier for row |
| `r` | text  | Region |
| `t` | text  | Technology |
| `y` | text  | Year |
| `val` | real  | Capacity (region's power [unit](@ref uoms)) |

## [Total annual maximum capacity storage](@id TotalAnnualMaxCapacityStorage)

Maximum capacity for a [storage](@ref storage) in a [year](@ref year) (including both exogenous and endogenous capacity). Only specify this parameter if you want to enforce a particular limit.

#### Scenario database

**Table: `TotalAnnualMaxCapacityStorage`**

| Name | Type | Description |
|:--- | :--: |:----------- |
| `id` | integer | Unique identifier for row |
| `r` | text  | Region |
| `s` | text  | Storage |
| `y` | text  | Year |
| `val` | real  | Capacity (region's energy [unit](@ref uoms)) |

## [Total annual maximum capacity investment storage](@id TotalAnnualMaxCapacityInvestmentStorage)

Maximum addition of endogenously determined capacity for a [storage](@ref storage) in a [year](@ref year). Only specify this parameter if you want to enforce a particular limit.

#### Scenario database

**Table: `TotalAnnualMaxCapacityInvestmentStorage`**

| Name | Type | Description |
|:--- | :--: |:----------- |
| `id` | integer | Unique identifier for row |
| `r` | text  | Region |
| `s` | text  | Storage |
| `y` | text  | Year |
| `val` | real  | Capacity (region's energy [unit](@ref uoms)) |

## [Total annual minimum capacity](@id TotalAnnualMinCapacity)

Minimum capacity for a [technology](@ref technology) in a [year](@ref year) (including both exogenous and endogenous capacity). Only specify this parameter if you want to enforce a particular limit (other than 0, which NEMO assumes by default).

#### Scenario database

**Table: `TotalAnnualMinCapacity`**

| Name | Type | Description |
|:--- | :--: |:----------- |
| `id` | integer | Unique identifier for row |
| `r` | text  | Region |
| `t` | text  | Technology |
| `y` | text  | Year |
| `val` | real  | Capacity (region's power [unit](@ref uoms)) |

## [Total annual minimum capacity investment](@id TotalAnnualMinCapacityInvestment)

Minimum addition of endogenously determined capacity for a [technology](@ref technology) in a [year](@ref year). Only specify this parameter if you want to enforce a particular limit (other than 0, which NEMO assumes by default).

#### Scenario database

**Table: `TotalAnnualMinCapacityInvestment`**

| Name | Type | Description |
|:--- | :--: |:----------- |
| `id` | integer | Unique identifier for row |
| `r` | text  | Region |
| `t` | text  | Technology |
| `y` | text  | Year |
| `val` | real  | Capacity (region's power [unit](@ref uoms)) |

## [Total annual minimum capacity storage](@id TotalAnnualMinCapacityStorage)

Minimum capacity for a [storage](@ref storage) in a [year](@ref year) (including both exogenous and endogenous capacity). Only specify this parameter if you want to enforce a particular limit (other than 0, which NEMO assumes by default).

#### Scenario database

**Table: `TotalAnnualMinCapacityStorage`**

| Name | Type | Description |
|:--- | :--: |:----------- |
| `id` | integer | Unique identifier for row |
| `r` | text  | Region |
| `s` | text  | Storage |
| `y` | text  | Year |
| `val` | real  | Capacity (region's energy [unit](@ref uoms)) |

## [Total annual minimum capacity investment storage](@id TotalAnnualMinCapacityInvestmentStorage)

Minimum addition of endogenously determined capacity for a [storage](@ref storage) in a [year](@ref year). Only specify this parameter if you want to enforce a particular limit (other than 0, which NEMO assumes by default).

#### Scenario database

**Table: `TotalAnnualMinCapacityInvestmentStorage`**

| Name | Type | Description |
|:--- | :--: |:----------- |
| `id` | integer | Unique identifier for row |
| `r` | text  | Region |
| `s` | text  | Storage |
| `y` | text  | Year |
| `val` | real  | Capacity (region's energy [unit](@ref uoms)) |

## [Total technology annual activity lower limit](@id TotalTechnologyAnnualActivityLowerLimit)

Minimum nominal energy produced by a [technology](@ref technology) in a [year](@ref year). Nominal energy is calculated by multiplying dispatched capacity by the length of time it is dispatched. Only specify this parameter if you want to enforce a particular limit (other than 0, which NEMO assumes by default).

#### Scenario database

**Table: `TotalTechnologyAnnualActivityLowerLimit`**

| Name | Type | Description |
|:--- | :--: |:----------- |
| `id` | integer | Unique identifier for row |
| `r` | text  | Region |
| `t` | text  | Technology |
| `y` | text  | Year |
| `val` | real  | Nominal energy (region's energy [unit](@ref uoms)) |

## [Total technology annual activity upper limit](@id TotalTechnologyAnnualActivityUpperLimit)

Maximum nominal energy produced by a [technology](@ref technology) in a [year](@ref year). Nominal energy is calculated by multiplying dispatched capacity by the length of time it is dispatched. Only specify this parameter if you want to enforce a particular limit.

#### Scenario database

**Table: `TotalTechnologyAnnualActivityUpperLimit`**

| Name | Type | Description |
|:--- | :--: |:----------- |
| `id` | integer | Unique identifier for row |
| `r` | text  | Region |
| `t` | text  | Technology |
| `y` | text  | Year |
| `val` | real  | Nominal energy (region's energy [unit](@ref uoms)) |

## [Total technology model period activity lower limit](@id TotalTechnologyModelPeriodActivityLowerLimit)

Minimum nominal energy produced by a [technology](@ref technology) over the modeling period (i.e., all [years](@ref year)). Nominal energy is calculated by multiplying dispatched capacity by the length of time it is dispatched. Only specify this parameter if you want to enforce a particular limit (other than 0, which NEMO assumes by default).

#### Scenario database

**Table: `TotalTechnologyModelPeriodActivityLowerLimit`**

| Name | Type | Description |
|:--- | :--: |:----------- |
| `id` | integer | Unique identifier for row |
| `r` | text  | Region |
| `t` | text  | Technology|
| `val` | real  | Nominal energy (region's energy [unit](@ref uoms)) |

## [Total technology model period activity upper limit](@id TotalTechnologyModelPeriodActivityUpperLimit)

Maximum nominal energy produced by a [technology](@ref technology) over the modeling period (i.e., all [years](@ref year)). Nominal energy is calculated by multiplying dispatched capacity by the length of time it is dispatched. Only specify this parameter if you want to enforce a particular limit.

#### Scenario database

**Table: `TotalTechnologyModelPeriodActivityUpperLimit`**

| Name | Type | Description |
|:--- | :--: |:----------- |
| `id` | integer | Unique identifier for row |
| `r` | text  | Region |
| `t` | text  | Technology|
| `val` | real  | Nominal energy (region's energy [unit](@ref uoms)) |

## [Trade route](@id TradeRoute)

Indicator of whether [region](@ref region) `r` can trade a [fuel](@ref fuel) with region `rr`.

#### Scenario database

**Table: `TradeRoute`**

| Name | Type | Description |
|:--- | :--: |:----------- |
| `id` | integer | Unique identifier for row |
| `r` | text  | First region connected by trade route |
| `rr` | text  | Second region connected by trade route |
| `f` | text  | Fuel |
| `y` | text  | Year |
| `val` | real  | Indicator (0 for no, 1 for yes) |

!!! note
    To enable trade between two regions, only one row in `TradeRoute` is needed. Either region can be assigned to `r`, and the second region should be assigned to `rr`. Be sure to set `val` to 1.

!!! tip
    It is not necessary to populate zeros in `TradeRoute` for cases where trade is disallowed. NEMO assumes trade is not allowed unless a route is explicitly defined in the table.

## [Transmission capacity to activity unit](@id TransmissionCapacityToActivityUnit)

Multiplier to convert 1 megawatt-year to a [region's](@ref region) energy [unit](@ref uoms) (e.g., 0.031536 if the energy unit is petajoules). This parameter is required if transmission modeling is enabled (see [TransmissionModelingEnabled](@ref TransmissionModelingEnabled)).

#### Scenario database

**Table: `TransmissionCapacityToActivityUnit`**

| Name | Type | Description |
|:--- | :--: |:----------- |
| `id` | integer | Unique identifier for row |
| `r` | text  | Region |
| `f` | text  | Fuel |
| `val` | real  | Multiplier |

## [Transmission modeling enabled](@id TransmissionModelingEnabled)

Indicator of whether transmission modeling is enabled for a [region](@ref region), [fuel](@ref fuel), and [year](@ref year). The `type` field specifies the approach to simulating energy flow:

* 1 - Direct current optimized power flow (DCOPF) (classical formulation).[^1]
* 2 - DCOPF with a disjunctive relaxation.[^2]
* 3 - Pipeline flow. This approach treats [transmission lines](@ref transmissionline) as pipelines whose flow is limited only by their maximum flow and efficiency.

!!! note
    If you choose type 1, NEMO will add a quadratic term to the optimization problem for your scenario. This will make the scenario incompatible with linear programming (LP)-only solvers such as GLPK and Cbc. To use DCOPF with an LP-only solver, choose type 2. This type produces equivalent results to type 1 but implements DCOPF with linear constraints.

!!! note
    At present, NEMO does not endogenously simulate line losses for types 1 and 2.

#### Scenario database

**Table: `TransmissionModelingEnabled`**

| Name | Type | Description |
|:--- | :--: |:----------- |
| `id` | integer | Unique identifier for row |
| `r` | text  | Region |
| `f` | text  | Fuel |
| `y` | text  | Year |
| `type` | integer  | Indicator (1, 2, or 3) |

!!! warning
    You should not put rows in `TransmissionModelingEnabled` for regions/fuels/years for which you don't want to model transmission. NEMO does not support a type 0 for this parameter.

## [Variable cost](@id VariableCost)

Running cost for a [technology](@ref technology), defined in terms of cost per unit of nominal energy produced. Nominal energy is calculated by multiplying dispatched capacity by the length of time it is dispatched.

#### Scenario database

**Table: `VariableCost`**

| Name | Type | Description |
|:--- | :--: |:----------- |
| `id` | integer | Unique identifier for row |
| `r` | text  | Region |
| `t` | text  | Technology |
| `m` | text  | Mode of operation |
| `y` | text  | Year |
| `val` | real  | Cost (scenario's cost [unit](@ref uoms) / region's energy unit) |

## [Year split](@id YearSplit)

Width of a [time slice](@ref timeslice) as a fraction of the specified [year](@ref year).

#### Scenario database

**Table: `YearSplit`**

| Name | Type | Description |
|:--- | :--: |:----------- |
| `id` | integer | Unique identifier for row |
| `l` | text  | Time slice |
| `y` | text  | Year |
| `val` | real  | Fraction (0 to 1) |

[^1]: See, e.g., Krishnan, V., Ho, J., Hobbs, B. F., Liu, A. L., McCalley, J. D., Shahidehpour, M. and Zheng, Q. P. (2016). Co-optimization of electricity transmission and generation resources for planning and policy analysis: review of concepts and modeling approaches. *Energy Systems*, 7(2). 297–332. DOI:10.1007/s12667-015-0158-4.

[^2]: Hui Zhang, Heydt, G. T., Vittal, V. and Mittelmann, H. D. (2012). Transmission expansion planning using an ac model: Formulations and possible relaxations. *2012 IEEE Power and Energy Society General Meeting* 1–8. Proceedings of the 2012 IEEE Power & Energy Society General Meeting. New Energy Horizons - Opportunities and Challenges, San Diego, CA. IEEE. DOI:10.1109/PESGM.2012.6345410.
