```@meta
CurrentModule = NemoMod
```
# [Activity limit and production share parameters](@id parameters_activity_limits)

These parameters restrict the activity of [technologies](@ref technology) and the shares of production met by particular technologies or renewable sources.

## [Maximum production share](@id MaxShareProduction)

For the specified [region](@ref region), [fuel](@ref fuel), and [year](@ref year), maximum fraction of production (excluding production from [storage](@ref storage)) that may be delivered by the indicated [technology](@ref technology).

#### Scenario database

**Table: `MaxShareProduction`**

| Name | Type | Description |
|:--- | :--: |:----------- |
| `id` | integer | Unique identifier for row |
| `r` | text  | Region |
| `t` | text  | Technology |
| `f` | text  | Fuel |
| `y` | text  | Year |
| `val` | real  | Fraction (0 to 1) |

## [Minimum production share](@id MinShareProduction)

For the specified [region](@ref region), [fuel](@ref fuel), and [year](@ref year), minimum fraction of production (excluding production from [storage](@ref storage)) that must be delivered by the indicated [technology](@ref technology).

#### Scenario database

**Table: `MinShareProduction`**

| Name | Type | Description |
|:--- | :--: |:----------- |
| `id` | integer | Unique identifier for row |
| `r` | text  | Region |
| `t` | text  | Technology |
| `f` | text  | Fuel |
| `y` | text  | Year |
| `val` | real  | Fraction (0 to 1) |

## [Renewable energy minimum production target (by region)](@id REMinProductionTarget)

For the specified [region](@ref region), [fuel](@ref fuel), and [year](@ref year), fraction of production that must be from renewable sources. The renewability of production is determined by [`RETagTechnology`](@ref RETagTechnology): this parameter defines what fraction of a [technology's](@ref technology) production counts as renewable.

!!! note
    NEMO ignores production from [storage](@ref storage) when calculating target and actual levels of renewable production.

#### Scenario database

**Table: `REMinProductionTarget`**

| Name | Type | Description |
|:--- | :--: |:----------- |
| `id` | integer | Unique identifier for row |
| `r` | text  | Region |
| `f` | text  | Fuel |
| `y` | text  | Year |
| `val` | real  | Fraction (0 to 1) |

## [Renewable energy minimum production target (by region group)](@id REMinProductionTargetRG)

For the specified [region group](@ref regiongroup), [fuel](@ref fuel), and [year](@ref year), fraction of production that must be from renewable sources. The renewability of production is determined by [`RETagTechnology`](@ref RETagTechnology): this parameter defines what fraction of a [technology's](@ref technology) production counts as renewable.

!!! note
    NEMO ignores production from [storage](@ref storage) when calculating target and actual levels of renewable production.

#### Scenario database

**Table: `REMinProductionTargetRG`**

| Name | Type | Description |
|:--- | :--: |:----------- |
| `id` | integer | Unique identifier for row |
| `rg` | text  | Region group |
| `f` | text  | Fuel |
| `y` | text  | Year |
| `val` | real  | Fraction (0 to 1) |

## [Renewable energy tag technology](@id RETagTechnology)

Fraction of a [technology's](@ref technology) production that counts as renewable.

#### Scenario database

**Table: `RETagTechnology`**

| Name | Type | Description |
|:--- | :--: |:----------- |
| `id` | integer | Unique identifier for row |
| `r` | text  | Region |
| `t` | text  | Technology |
| `y` | text  | Year |
| `val` | real  | Fraction (0 to 1) |

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

Minimum nominal energy produced by a [technology](@ref technology) over the modeling period (i.e., the period bounded by the first and last [years](@ref year) defined in the scenario database). Nominal energy is calculated by multiplying dispatched capacity by the length of time it is dispatched. Only specify this parameter if you want to enforce a particular limit (other than 0, which NEMO assumes by default).

#### Scenario database

**Table: `TotalTechnologyModelPeriodActivityLowerLimit`**

| Name | Type | Description |
|:--- | :--: |:----------- |
| `id` | integer | Unique identifier for row |
| `r` | text  | Region |
| `t` | text  | Technology|
| `val` | real  | Nominal energy (region's energy [unit](@ref uoms)) |

## [Total technology model period activity upper limit](@id TotalTechnologyModelPeriodActivityUpperLimit)

Maximum nominal energy produced by a [technology](@ref technology) over the modeling period (i.e., the period bounded by the first and last [years](@ref year) defined in the scenario database). Nominal energy is calculated by multiplying dispatched capacity by the length of time it is dispatched. Only specify this parameter if you want to enforce a particular limit.

#### Scenario database

**Table: `TotalTechnologyModelPeriodActivityUpperLimit`**

| Name | Type | Description |
|:--- | :--: |:----------- |
| `id` | integer | Unique identifier for row |
| `r` | text  | Region |
| `t` | text  | Technology|
| `val` | real  | Nominal energy (region's energy [unit](@ref uoms)) |
