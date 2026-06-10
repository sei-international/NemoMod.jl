```@meta
CurrentModule = NemoMod
```
# [Model structure and grouping parameters](@id parameters_structure)

These parameters define structural features of a scenario, including default values for other parameters, membership in [region groups](@ref regiongroup) and [technology groups](@ref technologygroup), time slice widths, and the assignment of [time slices](@ref timeslice) to time slice groups.

## [Default parameters](@id DefaultParams)

Default value for the parameter identified by `tablename`.

#### Scenario database

**Table: `DefaultParams`**

| Name | Type | Description |
|:--- | :--: |:----------- |
| `id` | integer | Unique identifier for row |
| `tablename` | text  | Name of parameter table  |
| `val` | real  | Default value |

## [Region group assignment](@id RRGroup)

Map of [regions](@ref region) to [region groups](@ref regiongroup). A region can belong to zero or more groups.

#### Scenario database

**Table: `RRGroup`**

| Name | Type | Description |
|:--- | :--: |:----------- |
| `id` | integer | Unique identifier for row |
| `rg` | text  | Region group |
| `r` | text  | Region |

## [Technology group assignment](@id TTGroup)

Map of [technologies](@ref technology) to [technology groups](@ref technologygroup). A technology can belong to zero or more groups.

#### Scenario database

**Table: `TTGroup`**

| Name | Type | Description |
|:--- | :--: |:----------- |
| `id` | integer | Unique identifier for row |
| `tg` | text  | Technology group |
| `t` | text  | Technology |

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
