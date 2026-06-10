```@meta
CurrentModule = NemoMod
```
# [Reserve margin parameters](@id parameters_reserve_margins)

These parameters define reserve margin requirements and the [technologies](@ref technology) that can provide reserves.

## [Reserve margin](@id ReserveMargin)

Multiplier that defines the level of reserve production capacity for a [region](@ref region), [fuel](@ref fuel), and [year](@ref year) - i.e., capacity beyond what is needed to meet production requirements. When a reserve margin is specified, NEMO ensures the total capacity of [technologies](@ref technology) tagged with [`ReserveMarginTagTechnology`](@ref ReserveMarginTagTechnology) (for the region, fuel, and year) is at least the margin times the rate of production of the fuel in each [time slice](@ref timeslice). Technology capacity is pro-rated by `ReserveMarginTagTechnology` in these calculations, allowing technologies to qualify differentially toward the reserve.

#### Scenario database

**Table: `ReserveMargin`**

| Name | Type | Description |
|:--- | :--: |:----------- |
| `id` | integer | Unique identifier for row |
| `r` | text  | Region |
| `f` | text  | Fuel |
| `y` | text  | Year |
| `val` | real  | Multiplier (e.g., 1.15 for a 15% reserve margin) |

!!! note
    If a reserve margin is set for a fuel, the fuel must be time-sliced (`FUEL.timesliced` = `1`).

## [Reserve margin tag technology](@id ReserveMarginTagTechnology)

Fraction of a [technology's](@ref technology) installed capacity that counts toward the [reserve margin](@ref ReserveMargin).

#### Scenario database

**Table: `ReserveMarginTagTechnology`**

| Name | Type | Description |
|:--- | :--: |:----------- |
| `id` | integer | Unique identifier for row |
| `r` | text  | Region |
| `t` | text  | Technology |
| `f` | text  | Fuel |
| `y` | text  | Year |
| `val` | real  | Fraction (0 to 1) |
