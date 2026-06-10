```@meta
CurrentModule = NemoMod
```
# [Capacity and investment limit parameters](@id parameters_capacity_limits)

These parameters constrain the total capacity of [technologies](@ref technology) and the capacity additions NEMO endogenously makes for technologies. Counterpart limits for storage and transmission are described in [Storage parameters](@ref parameters_storage) and [Transmission, node, and trade parameters](@ref parameters_transmission).

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

Maximum addition of endogenously determined capacity for a [technology](@ref technology) in a [year](@ref year). Only specify this parameter if you want to enforce a particular limit. This parameter is scaled up to account for non-modeled years when [selected years are calculated](@ref selected_years).

#### Scenario database

**Table: `TotalAnnualMaxCapacityInvestment`**

| Name | Type | Description |
|:--- | :--: |:----------- |
| `id` | integer | Unique identifier for row |
| `r` | text  | Region |
| `t` | text  | Technology |
| `y` | text  | Year |
| `val` | real  | Capacity (region's power [unit](@ref uoms)) |

## [Total annual maximum capacity (by region group)](@id TotalAnnualMaxCapacityRG)

Maximum capacity for a [technology](@ref technology) in a [year](@ref year) and [region group](@ref regiongroup) (including both exogenous and endogenous capacity). Only specify this parameter if you want to enforce a particular limit.

#### Scenario database

**Table: `TotalAnnualMaxCapacityRG`**

| Name | Type | Description |
|:--- | :--: |:----------- |
| `id` | integer | Unique identifier for row |
| `rg` | text  | Region group |
| `t` | text  | Technology |
| `y` | text  | Year |
| `val` | real  | Capacity (region's power [unit](@ref uoms)) |

## [Total annual maximum capacity investment (by region group)](@id TotalAnnualMaxCapacityInvestmentRG)

Maximum addition of endogenously determined capacity for a [technology](@ref technology) in a [year](@ref year) and [region group](@ref regiongroup). Only specify this parameter if you want to enforce a particular limit. This parameter is scaled up to account for non-modeled years when [selected years are calculated](@ref selected_years).

#### Scenario database

**Table: `TotalAnnualMaxCapacityInvestmentRG`**

| Name | Type | Description |
|:--- | :--: |:----------- |
| `id` | integer | Unique identifier for row |
| `rg` | text  | Region group |
| `t` | text  | Technology |
| `y` | text  | Year |
| `val` | real  | Capacity (region's power [unit](@ref uoms)) |

## [Total annual maximum capacity (by technology group)](@id TotalAnnualMaxCapacityTG)

Maximum capacity for a [technology group](@ref technologygroup) in a [year](@ref year) and [region](@ref region) (including both exogenous and endogenous capacity). Only specify this parameter if you want to enforce a particular limit.

#### Scenario database

**Table: `TotalAnnualMaxCapacityTG`**

| Name | Type | Description |
|:--- | :--: |:----------- |
| `id` | integer | Unique identifier for row |
| `r` | text  | Region |
| `tg` | text  | Technology group |
| `y` | text  | Year |
| `val` | real  | Capacity (region's power [unit](@ref uoms)) |

## [Total annual maximum capacity investment (by technology group)](@id TotalAnnualMaxCapacityInvestmentTG)

Maximum addition of endogenously determined capacity for a [technology group](@ref technologygroup) in a [year](@ref year) and [region](@ref region). Only specify this parameter if you want to enforce a particular limit. This parameter is scaled up to account for non-modeled years when [selected years are calculated](@ref selected_years).

#### Scenario database

**Table: `TotalAnnualMaxCapacityInvestmentTG`**

| Name | Type | Description |
|:--- | :--: |:----------- |
| `id` | integer | Unique identifier for row |
| `r` | text  | Region group |
| `tg` | text  | Technology group |
| `y` | text  | Year |
| `val` | real  | Capacity (region's power [unit](@ref uoms)) |

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

Minimum addition of endogenously determined capacity for a [technology](@ref technology) in a [year](@ref year). Only specify this parameter if you want to enforce a particular limit (other than 0, which NEMO assumes by default). This parameter is scaled up to account for non-modeled years when [selected years are calculated](@ref selected_years).

#### Scenario database

**Table: `TotalAnnualMinCapacityInvestment`**

| Name | Type | Description |
|:--- | :--: |:----------- |
| `id` | integer | Unique identifier for row |
| `r` | text  | Region |
| `t` | text  | Technology |
| `y` | text  | Year |
| `val` | real  | Capacity (region's power [unit](@ref uoms)) |

## [Total annual minimum capacity (by region group)](@id TotalAnnualMinCapacityRG)

Minimum capacity for a [technology](@ref technology) in a [year](@ref year) and [region group](@ref regiongroup) (including both exogenous and endogenous capacity). Only specify this parameter if you want to enforce a particular limit (other than 0, which NEMO assumes by default).

#### Scenario database

**Table: `TotalAnnualMinCapacityRG`**

| Name | Type | Description |
|:--- | :--: |:----------- |
| `id` | integer | Unique identifier for row |
| `rg` | text  | Region group |
| `t` | text  | Technology |
| `y` | text  | Year |
| `val` | real  | Capacity (region's power [unit](@ref uoms)) |

## [Total annual minimum capacity investment (by region group)](@id TotalAnnualMinCapacityInvestmentRG)

Minimum addition of endogenously determined capacity for a [technology](@ref technology) in a [year](@ref year) and [region group](@ref regiongroup). Only specify this parameter if you want to enforce a particular limit (other than 0, which NEMO assumes by default). This parameter is scaled up to account for non-modeled years when [selected years are calculated](@ref selected_years).

#### Scenario database

**Table: `TotalAnnualMinCapacityInvestmentRG`**

| Name | Type | Description |
|:--- | :--: |:----------- |
| `id` | integer | Unique identifier for row |
| `rg` | text  | Region group |
| `t` | text  | Technology |
| `y` | text  | Year |
| `val` | real  | Capacity (region's power [unit](@ref uoms)) |

## [Total annual minimum capacity (by technology group)](@id TotalAnnualMinCapacityTG)

Minimum capacity for a [technology group](@ref technologygroup) in a [year](@ref year) and [region](@ref region) (including both exogenous and endogenous capacity). Only specify this parameter if you want to enforce a particular limit (other than 0, which NEMO assumes by default).

#### Scenario database

**Table: `TotalAnnualMinCapacityTG`**

| Name | Type | Description |
|:--- | :--: |:----------- |
| `id` | integer | Unique identifier for row |
| `r` | text  | Region |
| `tg` | text  | Technology group |
| `y` | text  | Year |
| `val` | real  | Capacity (region's power [unit](@ref uoms)) |

## [Total annual minimum capacity investment (by technology group)](@id TotalAnnualMinCapacityInvestmentTG)

Minimum addition of endogenously determined capacity for a [technology group](@ref technologygroup) in a [year](@ref year) and [region](@ref region). Only specify this parameter if you want to enforce a particular limit (other than 0, which NEMO assumes by default). This parameter is scaled up to account for non-modeled years when [selected years are calculated](@ref selected_years).

#### Scenario database

**Table: `TotalAnnualMinCapacityInvestmentTG`**

| Name | Type | Description |
|:--- | :--: |:----------- |
| `id` | integer | Unique identifier for row |
| `r` | text  | Region group |
| `tg` | text  | Technology group |
| `y` | text  | Year |
| `val` | real  | Capacity (region's power [unit](@ref uoms)) |
