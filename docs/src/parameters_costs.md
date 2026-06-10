```@meta
CurrentModule = NemoMod
```
# [Cost, financing, and subsidy parameters](@id parameters_costs)

These parameters define costs for [technologies](@ref technology), scenario-wide financial assumptions, and subsidies. Costs for storage are described in [Storage parameters](@ref parameters_storage); costs for transmission lines are part of the [transmission line](@ref transmissionline) dimension.

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

## [Depreciation method](@id DepreciationMethod)

Method for calculating the salvage value of [technology](@ref technology), [storage](@ref storage), and [transmission line](@ref transmissionline) capacity existing at the end of the modeling period.

* 1: Sinking fund depreciation (assuming the applicable discount rate is not 0; if it is, straight line depreciation is used instead)

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

## [Interest rate technology](@id InterestRateTechnology)

Interest rate used to calculate [financing costs](@ref vfinancecost) for endogenously built [technology](@ref technology) capacity.

#### Scenario database

**Table: `InterestRateTechnology`**

| Name | Type | Description |
|:--- | :--: |:----------- |
| `id` | integer | Unique identifier for row |
| `r` | text  | Region |
| `t` | text  | Technology |
| `y` | text  | Year |
| `val` | real  | Rate (0 to 1) |

## [Maximum subsidies per technology](@id MaxSubsidyPerTechnology)

Maximum subsidies that can be disbursed for a [technology](@ref technology) in a [region](@ref region) and [year](@ref year). Subsidies can be applied to new endogenously built technology capacity if the [`TechnologySubsidy`](@ref TechnologySubsidy) parameter is defined. They function like a discount on [capital costs](@ref CapitalCost), lowering capital investment and financing requirements.

#### Scenario database

**Table: `MaxSubsidyPerTechnology`**

| Name | Type | Description |
|:--- | :--: |:----------- |
| `id` | integer | Unique identifier for row |
| `r` | text  | Region |
| `t` | text  | Technology |
| `y` | text  | Year |
| `val` | real  | Maximum subsidies (scenario's cost [unit](@ref uoms)) |

## [Maximum subsidies per technology group](@id MaxSubsidyPerTechnologyGroup)

Maximum subsidies that can be disbursed for a [technology group](@ref technologygroup) in a [region](@ref region) and [year](@ref year). Subsidies can be applied to new endogenously built technology capacity if the [`TechnologySubsidy`](@ref TechnologySubsidy) parameter is defined. They function like a discount on [capital costs](@ref CapitalCost), lowering capital investment and financing requirements.

#### Scenario database

**Table: `MaxSubsidyPerTechnologyGroup`**

| Name | Type | Description |
|:--- | :--: |:----------- |
| `id` | integer | Unique identifier for row |
| `r` | text  | Region |
| `tg` | text  | Technology group |
| `y` | text  | Year |
| `val` | real  | Maximum subsidies (scenario's cost [unit](@ref uoms)) |

## [Maximum subsidies per region](@id MaxSubsidyPerRegion)

Maximum [technology](@ref technology) subsidies that can be disbursed in a [region](@ref region) and [year](@ref year). Subsidies can be applied to new endogenously built technology capacity if the [`TechnologySubsidy`](@ref TechnologySubsidy) parameter is defined. They function like a discount on [capital costs](@ref CapitalCost), lowering capital investment and financing requirements.

#### Scenario database

**Table: `MaxSubsidyPerRegion`**

| Name | Type | Description |
|:--- | :--: |:----------- |
| `id` | integer | Unique identifier for row |
| `r` | text  | Region |
| `y` | text  | Year |
| `val` | real  | Maximum technology subsidies (scenario's cost [unit](@ref uoms)) |

## [Technology subsidy](@id TechnologySubsidy)

Maximum permissible subsidy amount per unit of endogenously built [technology](@ref technology) capacity. Subsidies function like a discount on technology [capital costs](@ref CapitalCost), lowering capital investment and financing requirements.

#### Scenario database

**Table: `TechnologySubsidy`**

| Name | Type | Description |
|:--- | :--: |:----------- |
| `id` | integer | Unique identifier for row |
| `r` | text  | Region |
| `t` | text  | Technology |
| `y` | text  | Year |
| `val` | real  | Maximum permissible subsidy (scenario's cost [unit](@ref uoms) / region's power unit) |

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
