```@meta
CurrentModule = NemoMod
```
# [Transmission, node, and trade parameters](@id parameters_transmission)

These parameters support nodal transmission modeling and trade between [regions](@ref region). They include controls for enabling transmission modeling, transmission line performance and investment limits, the distribution of demand and capacity across [nodes](@ref node), and trade routes.

## [Maximum annual transmission between nodes](@id MaxAnnualTransmissionNodes)

For the indicated [fuel](@ref fuel) and [year](@ref year), maximum energy that can be received at the second [node](@ref node) (`n2`) via transmission from the first node (`n1`). Energy received is net of any transmission losses.

!!! note
    To use this parameter, make sure `n1` and `n2` are in [regions](@ref region) that have the same energy [unit](@ref uoms).

#### Scenario database

**Table: `MaxAnnualTransmissionNodes`**

| Name | Type | Description |
|:--- | :--: |:----------- |
| `id` | integer | Unique identifier for row |
| `n1` | text  | Node sending energy |
| `n2` | text  | Node receiving energy |
| `f` | text  | Fuel |
| `y` | text  | Year |
| `val` | real  | Energy (energy unit for regions containing `n1` and `n2`) |

## [Minimum annual transmission between nodes](@id MinAnnualTransmissionNodes)

For the indicated [fuel](@ref fuel) and [year](@ref year), minimum energy that must be received at the second [node](@ref node) (`n2`) via transmission from the first node (`n1`). Energy received is net of any transmission losses.

!!! note
    To use this parameter, make sure `n1` and `n2` are in [regions](@ref region) that have the same energy [unit](@ref uoms).

#### Scenario database

**Table: `MinAnnualTransmissionNodes`**

| Name | Type | Description |
|:--- | :--: |:----------- |
| `id` | integer | Unique identifier for row |
| `n1` | text  | Node sending energy |
| `n2` | text  | Node receiving energy |
| `f` | text  | Fuel |
| `y` | text  | Year |
| `val` | real  | Energy (energy unit for regions containing `n1` and `n2`) |

## [Nodal distribution demand](@id NodalDistributionDemand)

For the specified [node](@ref node) and the [region](@ref region) containing it, fraction of the region's exogenously defined demands for the specified [fuel](@ref fuel) that is assigned to the node. Exogenously defined demands include [specified annual demand](@ref SpecifiedAnnualDemand) and [accumulated annual demand](@ref AccumulatedAnnualDemand).

If in a given [year](@ref year) transmission modeling is enabled for a fuel and region (see [`TransmissionModelingEnabled`](@ref TransmissionModelingEnabled)), and the fuel has exogenous demands in the region, the sum of `NodalDistributionDemand` across the nodes in the region should be 1.

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

!!! note
    To enable nodal modeling for a storage, you must define `NodalDistributionStorageCapacity` and activate transmission modeling for the storage's input and output [fuels](@ref fuel). Use the [TransmissionModelingEnabled](@ref TransmissionModelingEnabled) parameter to activate transmission modeling.

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

## [Trade route](@id TradeRoute)

Indicator of whether [region](@ref region) `r` can export a [fuel](@ref fuel) to region `rr`. Trade routes establish export pathways that are not capacity-limited (for capacity-limited trading of fuels, use [transmission lines](@ref transmissionline)).

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
    To enable two-way trade between two regions, two rows in `TradeRoute` are required. Each region should be `r` in one of the rows and `rr` in the other. Be sure to set `val` to 1 in both rows.
 
!!! tip
    It is not necessary to populate zeros in `TradeRoute` for cases where trade is disallowed. NEMO assumes trade is not allowed unless a route is explicitly defined in the table.

## [Transmission availability factor](@id TransmissionAvailabilityFactor)

Fraction of time a [transmission line](@ref transmissionline) is available to operate.

#### Scenario database

**Table: `TransmissionAvailabilityFactor`**

| Name | Type | Description |
|:--- | :--: |:----------- |
| `tr` | text | Transmission line |
| `l` | text  | Time slice |
| `y` | text  | Year |
| `val` | real  | Fraction (0 to 1) |

!!! note
    This parameter must be used when modeling transmission. If you don't want to represent reduced availability for lines, set a default of 1.0 for `TransmissionAvailabilityFactor` in the [default parameters table](@ref DefaultParams) or by using the [`setparamdefault`](@ref) function.

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

## [Transmission maximum annual capacity investment](@id TransmissionAnnualMaxCapacityInvestment)

Maximum addition of endogenously determined capacity for a [transmission line](@ref transmissionline) in a [year](@ref year). This parameter is scaled up to account for non-modeled years when [selected years are calculated](@ref selected_years). It only applies to candidate transmission lines (lines without an exogenously specified construction date).

#### Scenario database

**Table: `TransmissionAnnualMaxCapacityInvestment`**

| Name | Type | Description |
|:--- | :--: |:----------- |
| `id` | integer | Unique identifier for row |
| `tr` | text  | Transmission line |
| `y` | text  | Year |
| `val` | real  | Capacity (MW) |

!!! warning
    If a candidate transmission line's `TransmissionAnnualMaxCapacityInvestment` is less than its `maxflow` and you call [`calculatescenario`](@ref) with `continuoustransmission = false`, the line will never be built.

## [Transmission minimum annual capacity investment](@id TransmissionAnnualMinCapacityInvestment)

Minimum addition of endogenously determined capacity for a [transmission line](@ref transmissionline) in a [year](@ref year). This parameter is **_not_** scaled up to account for non-modeled years when [selected years are calculated](@ref selected_years). It only applies to candidate transmission lines (lines without an exogenously specified construction date).

#### Scenario database

**Table: `TransmissionAnnualMinCapacityInvestment`**

| Name | Type | Description |
|:--- | :--: |:----------- |
| `id` | integer | Unique identifier for row |
| `tr` | text  | Transmission line |
| `y` | text  | Year |
| `val` | real  | Capacity (MW) |

!!! note
    If you set `TransmissionAnnualMinCapacityInvestment` for a candidate transmission line and year and call [`calculatescenario`](@ref) with `continuoustransmission = false`, the line will be built in its entirety in the specified year.
    
!!! warning
    If you set `TransmissionAnnualMinCapacityInvestment` for a candidate transmission line in more than one year and call `calculatescenario` with `continuoustransmission = false`, your model will be infeasible.

!!! warning
    If you set `TransmissionAnnualMinCapacityInvestment` for a candidate transmission line in more than one year and call `calculatescenario` with `continuoustransmission = true`, your model will be infeasible if the total minimum additions exceed the line's `maxflow`.

## [Transmission modeling enabled](@id TransmissionModelingEnabled)

Indicator of whether transmission modeling is enabled for a [region](@ref region), [fuel](@ref fuel), and [year](@ref year). The `type` field specifies the approach to simulating energy flow:

* 1 - Direct current optimized power flow (DCOPF) (classical formulation).[^1]
* 2 - DCOPF with a disjunctive relaxation.[^2]
* 3 - Pipeline flow. This approach treats [transmission lines](@ref transmissionline) as pipelines whose flow is limited only by their maximum flow and efficiency.

!!! note
    If you choose type 1, NEMO will add a quadratic term to the optimization problem for your scenario. This will make the scenario incompatible with linear programming (LP)-only solvers such as GLPK and Cbc. To use DCOPF with an LP-only solver, choose type 2. This type produces equivalent results to type 1 but implements DCOPF with linear constraints.

!!! note
    At present, NEMO does not endogenously simulate line losses for types 1 and 2.

!!! note
    If transmission modeling is enabled for a fuel, the fuel must be time-sliced (`FUEL.timesliced` = `1`).

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

[^1]: See, e.g., Krishnan, V., Ho, J., Hobbs, B. F., Liu, A. L., McCalley, J. D., Shahidehpour, M. and Zheng, Q. P. (2016). Co-optimization of electricity transmission and generation resources for planning and policy analysis: review of concepts and modeling approaches. *Energy Systems*, 7(2). 297–332. DOI:10.1007/s12667-015-0158-4.

[^2]: Hui Zhang, Heydt, G. T., Vittal, V. and Mittelmann, H. D. (2012). Transmission expansion planning using an ac model: Formulations and possible relaxations. *2012 IEEE Power and Energy Society General Meeting* 1–8. Proceedings of the 2012 IEEE Power & Energy Society General Meeting. New Energy Horizons - Opportunities and Challenges, San Diego, CA. IEEE. DOI:10.1109/PESGM.2012.6345410.