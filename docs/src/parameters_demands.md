```@meta
CurrentModule = NemoMod
```
# [Demand parameters](@id parameters_demands)

These parameters define exogenous demands in a scenario. Demands can be specified on an annual basis or distributed across [time slices](@ref timeslice).

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

!!! note
    If you define specified annual demand for a non time-sliced [fuel](@ref fuel), NEMO treats it as analogous to [accumulated annual demand](@ref AccumulatedAnnualDemand) (i.e., as demand at the annual level, ignoring the [specified demand profile](@ref SpecifiedDemandProfile)).

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
