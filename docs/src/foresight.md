```@meta
CurrentModule = NemoMod
```
# [Perfect foresight vs. limited foresight](@id foresight)

When calculating a scenario in NEMO, you can choose to optimize with perfect or limited foresight.

- With *perfect foresight*, NEMO optimizes all modeled [years](@ref year) at the same time (in one objective function and one solver call). The optimization calculation finds the energy system configuration that yields the lowest possible discounted costs across the modeled years.

- For *limited foresight*, you divide the modeled years into groups, which must not overlap. NEMO then optimizes the groups in chronological order. Within each group, NEMO minimizes discounted costs for the years in the group - i.e., it uses perfect foresight optimization for those years only. Results from the group then provide starting conditions for the next group. The starting conditions taken from prior groups include [technology](@ref technology), [storage](@ref storage), and [transmission](@ref transmissionline) capacity deployed; model period cost, emissions, and technology activity totals; and the amount of energy in storage.

In both paradigms, you can elect to [calculate selected years only](@ref selected_years) rather than all years in your [scenario's database](@ref scenario_db). This means the years you specify for perfect foresight optimization or in the groups of years for limited foresight optimization can be sparse. In this case, NEMO makes adjustments to minimize distortions in the results compared to calculating all years.

## Advantages and disadvantages of each approach

When choosing between perfect and limited foresight optimization, you should consider several factors. Neither approach is best for all models and NEMO analyses.

The main advantage of perfect foresight is it returns a globally optimal solution - the least-cost way to configure the energy system for the years being studied. This is of course an idealization, but it can be a useful one for decision making. The principal downside to perfect foresight optimization is performance. Models formulated with perfect foresight are more complex from a solver's perspective and take longer to solve. The impact on performance can scale in a non-linear fashion with the number of years included in the perfect foresight calculation.

Limited foresight optimization can substantially decrease model calculation times by dividing the modeling period into smaller intervals. This breaks up the scenario's optimization problem into several smaller problems, each of which is easier to solve than if all years were taken together. Limited foresight doesn't provide a global optimum, but this can be acceptable for some analyses. In addition, limited foresight may more realistically simulate the way some energy-system decisions are made (i.e., looking only a few years into the future, rather than decades ahead).

## Syntax

You can indicate whether to use perfect or limited foresight optimization when calling NEMO's [`calculatescenario`](@ref scenario_calc) function. For the function's `calcyears` argument, you can pass a simple vector (array) of years or a vector of vectors of years. If you provide one vector of years, NEMO optimizes those years with perfect foresight. If you supply multiple vectors (in a vector of vectors), NEMO takes each as a group of years for limited foresight optimization. When passing multiple vectors of years to `calcyears`, be sure they do not overlap and they are in chronological order. If you don't provide a value for `calcyears`, NEMO optimizes all years in the scenario database with perfect foresight.

Here are a few examples, assuming you have a scenario whose years cover 2025 to 2050.

```julia
# Optimize all years with perfect foresight
NemoMod.calculatescenario("my_scenario.sqlite"; jumpmodel=direct_model(Xpress.Optimizer()), 
    calcyears=[[2025,2026,2027,2028,2029,2030,2031,2032,2033,2034,2035,2036,2037,2038,2039,2040,2041,2042,2043,2044,2045,2046,2047,2048,2049,2050]])

# Optimize all years with perfect foresight (calcyears argument omitted)
NemoMod.calculatescenario("my_scenario.sqlite"; jumpmodel=direct_model(Xpress.Optimizer()))

# Optimize selected years with perfect foresight
NemoMod.calculatescenario("my_scenario.sqlite"; jumpmodel=direct_model(Xpress.Optimizer()), 
    calcyears=[[2025,2030,2035,2040,2045,2050]])

# Limited foresight optimization in three parts:
#   optimize 2025-2034 with perfect foresight, 
#   then optimize 2035-2044 with perfect foresight,
#   then optimize 2045-2050 with perfect foresight
NemoMod.calculatescenario("my_scenario.sqlite"; jumpmodel=direct_model(Xpress.Optimizer()), 
    calcyears=[[2025,2026,2027,2028,2029,2030,2031,2032,2033,2034], 
    [2035,2036,2037,2038,2039,2040,2041,2042,2043,2044], 
    [2045,2046,2047,2048,2049,2050]])  

# Limited foresight optimization in three parts (calculating selected years only): 
#   optimize 2025, 2030, and 2034 with perfect foresight; 
#   then optimize 2035, 2040, and 2044 with perfect foresight; 
#   then optimize 2045 and 2050 with perfect foresight
NemoMod.calculatescenario("my_scenario.sqlite"; jumpmodel=direct_model(Xpress.Optimizer()), 
    calcyears=[[2025,2030,2034], [2035,2040,2044], [2045,2050]])  

# Limited foresight optimization: optimize each year individually
NemoMod.calculatescenario("my_scenario.sqlite"; jumpmodel=direct_model(Xpress.Optimizer()), 
    calcyears=[[2025],[2026],[2027],[2028],[2029],[2030],[2031],[2032],[2033],[2034],[2035],[2036],[2037],[2038],[2039],[2040],[2041],[2042],[2043],[2044],[2045],[2046],[2047],[2048],[2049],[2050]])
```

You can also specify `calcyears` in a [NEMO configuration file](@ref configuration_file). In that case, you separate groups of years with commas and years within a group with vertical bars (|). The following block reproduces the above examples in configuration file syntax.

```ini
[calculatescenarioargs]
; Optimize all years with perfect foresight
calcyears=2025|2026|2027|2028|2029|2030|2031|2032|2033|2034|2035|2036|2037|2038|2039|2040|2041|2042|2043|2044|2045|2046|2047|2048|2049|2050

[calculatescenarioargs]
; Optimize selected years with perfect foresight
calcyears=2025|2030|2035|2040|2045|2050

[calculatescenarioargs]
; Limited foresight optimization in three parts:
;   optimize 2025-2034 with perfect foresight,
;   then optimize 2035-2044 with perfect foresight,
;   then optimize 2045-2050 with perfect foresight
calcyears=2025|2026|2027|2028|2029|2030|2031|2032|2033|2034,2035|2036|2037|2038|2039|2040|2041|2042|2043|2044,2045|2046|2047|2048|2049|2050

[calculatescenarioargs]
; Limited foresight optimization in three parts (calculating selected years only):
;   optimize 2025, 2030, and 2034 with perfect foresight;
;   then optimize 2035, 2040, and 2044 with perfect foresight;
;   then optimize 2045 and 2050 with perfect foresight
calcyears=2025|2030|2034,2035|2040|2044,2045|2050

[calculatescenarioargs]
; Limited foresight optimization: optimize each year individually
calcyears=2025,2026,2027,2028,2029,2030,2031,2032,2033,2034,2035,2036,2037,2038,2039,2040,2041,2042,2043,2044,2045,2046,2047,2048,2049,2050
```