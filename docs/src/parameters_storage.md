```@meta
CurrentModule = NemoMod
```
# [Storage parameters](@id parameters_storage)

These parameters configure [storage](@ref storage) in a scenario, including storage costs, performance, pre-existing capacity, capacity and investment limits, and connections between storage and [technologies](@ref technology).

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

## [Interest rate storage](@id InterestRateStorage)

Interest rate used to calculate [financing costs](@ref vfinancecoststorage) for endogenously built [storage](@ref storage) capacity.

#### Scenario database

**Table: `InterestRateStorage`**

| Name | Type | Description |
|:--- | :--: |:----------- |
| `id` | integer | Unique identifier for row |
| `r` | text  | Region |
| `s` | text  | Storage |
| `y` | text  | Year |
| `val` | real  | Rate (0 to 1) |

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

Fraction of exogenous [storage](@ref storage) capacity that is charged at the start of the first modeled [year](@ref year).

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

!!! note
    If a technology is connected to storage via `TechnologyFromStorage`, the fuels it produces must be time-sliced (`FUEL.timesliced` = `1`).

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

!!! note
    If a technology is connected to storage via `TechnologyToStorage`, the fuels it consumes must be time-sliced (`FUEL.timesliced` = `1`).

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

Maximum addition of endogenously determined capacity for a [storage](@ref storage) in a [year](@ref year). Only specify this parameter if you want to enforce a particular limit. This parameter is scaled up to account for non-modeled years when [selected years are calculated](@ref selected_years).

#### Scenario database

**Table: `TotalAnnualMaxCapacityInvestmentStorage`**

| Name | Type | Description |
|:--- | :--: |:----------- |
| `id` | integer | Unique identifier for row |
| `r` | text  | Region |
| `s` | text  | Storage |
| `y` | text  | Year |
| `val` | real  | Capacity (region's energy [unit](@ref uoms)) |

## [Total annual minimum capacity storage](@id TotalAnnualMinCapacityStorage)

Minimum capacity for a [storage](@ref storage) in a [year](@ref year) (including both exogenous and endogenous capacity). Only specify this parameter if you want to enforce a particular limit (other than 0, which NEMO assumes by default). This parameter is scaled up to account for non-modeled years when [selected years are calculated](@ref selected_years).

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
