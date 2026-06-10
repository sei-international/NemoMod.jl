```@meta
CurrentModule = NemoMod
```
# [Technology performance and operation parameters](@id parameters_technology)

These parameters characterize the performance and operation of [technologies](@ref technology), including their availability, lifetime, pre-existing capacity, input-output relationships, and operating restrictions.

## [Availability factor](@id AvailabilityFactor)

Fraction of time a [technology](@ref technology) is available to operate.

#### Scenario database

**Table: `AvailabilityFactor`**

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

!!! note
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

## [Minimum utilization](@id MinimumUtilization)

Minimum fraction of a [technology's](@ref technology) available capacity that must be utilized (dispatched) in a [region](@ref region), [time slice](@ref timeslice), and [year](@ref year). NEMO calculates available capacity by multiplying installed capacity by the applicable [availability factor](@ref AvailabilityFactor) parameter. If the technology is involved in nodal transmission modeling, the minimum utilization rule applies equally to all [nodes](@ref node) in the region.

!!! tip
    It is not necessary to specify 0 for this parameter. NEMO assumes the minimum utilization is 0 if the parameter is not set.

#### Scenario database

**Table: `MinimumUtilization`**

| Name | Type | Description |
|:--- | :--: |:----------- |
| `id` | integer | Unique identifier for row |
| `r` | text  | Region |
| `t` | text  | Technology |
| `l` | text  | Time slice |
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
