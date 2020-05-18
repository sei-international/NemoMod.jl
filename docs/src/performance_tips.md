```@meta
CurrentModule = NemoMod
```
# [Performance tips](@id performance_tips)

NEMO is designed to provide robust performance for a wide variety of models and scenarios. However, it is certainly possible to build a NEMO model that calculates slowly. Most often, this is due to a long solve time (i.e., the solver takes a long time to find a solution), which is in turn driven by model complexity.

If your model isn't calculating as quickly as you'd like, there are several steps to consider.

  * **Only save the output variables you need.** Saving unnecessary variables [variables](@ref variables) increases disk operations and may result in a longer solve time (because additional constraints are needed to calculate the variables).

  * **Don't save zeros.** If you set the `reportzeros` argument for [`calculatescenario`](@ref) to `false` (the default), NEMO won't take the time to save output variables with a value of zero. You can then assume a zero value for variables that are defined in the scenario but not reported.

  * **Check `restrictvars`.** The `restrictvars` argument for [`calculatescenario`](@ref) can have a significant impact on performance. This option tells NEMO to make a greater effort to eliminate unnecessary variables from the model it provides to the solver. This filtering process requires a little time, but it can considerably reduce solve time. In general, the trade-off is advisable for large models (you should set `restrictvars` to `true` in these cases) but may not be for very small models (set `restrictvars` to `false` in these cases).

  * **Use parallel processing.** NEMO can parallelize certain operations, reducing their run time by spreading the load across multiple processes. To enable parallelization, use Julia's `Distributed` package in conjunction with NEMO. The basic steps are to initialize additional Julia processes, load the NEMO package on those processes, and tell NEMO to use the processes in [`calculatescenario`](@ref) (via the `targetprocs` argument). For example:

  ```
  julia> using Distributed

  julia> addprocs(3)
  3-element Array{Int64,1}:
    2
    3
    4

  julia> @everywhere using NemoMod

  julia> NemoMod.calculatescenario("c:/temp/scenario_db.sqlite"; restrictvars=true, targetprocs=[1,2,3,4])
  ```

  In this case, `using Distributed` enables access to the `Distributed` package, `addprocs` initializes three new Julia processes, and `@everywhere using NemoMod` loads the NEMO package on all processes (the default process and the three new ones). The `targetprocs` argument for `calculatescenario` then tells NEMO to run on all four processes. The decision to use four processes is illustrative; in reality, the number of processes should be based on the available hardware. Julia also supports starting and using processes on multiple physical computers - see [Julia's documentation](https://docs.julialang.org/) for more details (search on "distributed").

  The above steps will enable parallelization in NEMO's code. For maximum performance with large models, it is also helpful to use a solver that supports parallelization, such as CPLEX, Gurobi, or Cbc.

  * **Simplify the scenario.** Substantial performance gains can be realized by reducing the number of [dimensions](@ref dimensions) in a scenario - for example, decreasing the number of [regions](@ref region), [technologies](@ref technology), [time slices](@ref timeslice), [years](@ref year), or [nodes](@ref node). You can also speed up calculations by forgoing nodal transmission modeling. Of course, this approach generally requires trade-offs: a simpler model may not respond as well to the analytic questions you are asking. The goal is to find a reasonable balance between your model's realism and its performance.

  * **Relax the transmission simulation.** If you're simulating transmission, there are some other performance tuning options to consider beyond reducing your model's dimensions. You can change the simulation method with the [`TransmissionModelingEnabled`](@ref TransmissionModelingEnabled) parameter or use this parameter to model transmission only in selected [years](@ref year). The [`calculatescenario`](@ref) function also has an argument that determines whether endogenous 


  * **Try a different solver.** The open-source solvers delivered with NEMO (GLPK and Cbc) may struggle with sizeable models. If you have access to one of the commercial solvers NEMO supports (currently, CPLEX, Gurobi, and Mosek), it will usually be a better option. If you're choosing between Cbc and GLPK, test both of them to see which performs better for your scenario.
