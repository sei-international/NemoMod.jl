```@meta
CurrentModule = NemoMod
```
# [Julia syntax for calculating a scenario](@id scenario_calc)

To calculate a scenario with NEMO, you use the `calculatescenario` function. The only required argument is `dbpath`; NEMO provides a default value for all other arguments.

```@docs
calculatescenario
```

To access `calculatescenario` within Julia, you must first tell Julia you want to use NEMO. This is done with the `using` command.

```julia
julia> using NemoMod

julia> NemoMod.calculatescenario("c:/temp/scenario_db.sqlite")
```

If you want to provide a value for the `jumpmodel` argument, make sure to include `JuMP` and your solver's Julia package in the `using` command. For example:

```julia
julia> using NemoMod, JuMP, CPLEX

julia> NemoMod.calculatescenario("c:/temp/scenario_db.sqlite"; jumpmodel = Model(CPLEX.Optimizer), forcemip = true)
```
