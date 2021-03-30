```@meta
CurrentModule = NemoMod
```
# [Calculating selected years](@id selected_years)

You can limit scenario calculation in NEMO to certain [years](@ref year) with the `calcyears` argument for [`calculatescenario`](@ref scenario_calc). When you specify a value for `calcyears`, NEMO restricts the optimization problem for the scenario to the years you selected (provided they are defined in the [scenario's database](@ref scenario_db)). The problem's objective is to minimize discounted costs in those years. If you don't supply a value for `calcyears`, all years in the scenario database are included in the calculation.

Calculating selected years offers a way quickly to generate results from large, complex models. While the results may not be identical to what you would get if you calculated all years, NEMO takes several steps to ensure they are a reasonable approximation. Specifically, when `calcyears` is invoked, NEMO:

* Calculates discounted investment costs for [technologies](@ref technology) and [storage](@ref storage) by distributing the costs over modeled (selected) and non-modeled years. Each modeled year is taken as the endpoint of an interval that starts after the prior modeled year (or the beginning of the first year in the scenario database, if there is no prior modeled year). For discounting purposes, investment costs incurred in a modeled year are assumed to be spread equally over the year's interval. NEMO's output [variables](@ref variables) for discounted technology and storage investment costs ([`vdiscountedcapitalinvestment`](@ref vdiscountedcapitalinvestment) and [`vdiscountedcapitalinvestmentstorage`](@ref vdiscountedcapitalinvestmentstorage)) reflect this adjustment.

* Calculates discounted [transmission](@ref transmissionline) investment costs in the same way as discounted technology/storage investment costs if the `continuoustransmission` argument for `calculatescenario` is `true`. In this case, the output variable [`vdiscountedcapitalinvestmenttransmission`](@ref vdiscountedcapitalinvestmenttransmission) includes the adjustment.

* Estimates discounted operation and maintenance costs for technologies in non-modeled years. Fixed costs are estimated by assuming that capacity changes in a linear fashion between modeled years (or, if a modeled year's interval begins with the first year in the scenario database, that there is a linear change from the [residual capacity](@ref ResidualCapacity) in that year to the capacity in the modeled year). Variable costs are computed by assuming activity changes in a linear fashion between modeled years (or, if a modeled year's interval begins with the first year in the scenario database, that the activity in the modeled year recurs in other years in the interval). The output variable [`vdiscountedoperatingcost`](@ref vdiscountedoperatingcost) includes these adjustments.

* 




- Annual capacity addition limits
- No carryover of energy in storage between non-continguous years
- Model period technology activity and emission limits not enforced
- Change in definition of vmodelperiodcostbyregion, vmodelperiodemissions, vtotaltechnologymodelperiodactivity - reflect selected years only
