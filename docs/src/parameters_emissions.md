```@meta
CurrentModule = NemoMod
```
# [Emission parameters](@id parameters_emissions)

These parameters define [emissions](@ref emission) in a scenario, including emission intensities of technology activity, exogenous emissions, emission limits, and emission penalties.

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

!!! note
    Emission factors can be negative, and if you specify a negative emission factor for a pollutant with an [externality cost](@ref EmissionsPenalty), your scenario may result in [negative emission penalties](@ref vannualtechnologyemissionspenalty). In this case, you may need to constrain the associated technology's operation to avoid an unbounded (infeasible) optimization problem. For example, if a technology can generate negative emissions of a pollutant with an externality cost, the cost of building and running the technology is lower than the externality value, and there are no limits on the technology's deployment and use, the optimization problem will be unbounded.

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

## [Model period emission limit](@id ModelPeriodEmissionLimit)

Maximum emissions allowed in the modeling period (i.e., the period bounded by the first and last [years](@ref year) defined in the scenario database).

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
