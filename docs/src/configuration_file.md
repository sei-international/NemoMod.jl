```@meta
CurrentModule = NemoMod
```
# [Configuration files](@id configuration_file)

When you calculate a scenario with NEMO, you can optionally provide a configuration file that specifies run-time options. The file should be named `nemo.ini` or `nemo.cfg` and should be available in Julia's working directory. To check the working directory in a Julia session, use the  `pwd` function. To change the working directory, use `cd`.

NEMO configuration files are text files written in `ini` syntax. The following run-time options can be set in a configuration file.

* `calculatescenarioargs` block
  + `varstosave` - Comma-delimited list of output [variables](@ref variables) to save to the [scenario database](@ref scenario_db). NEMO adds values specified in a configuration file to those requested in the `varstosave` argument for [`calculatescenario`](@ref).  
  + `targetprocs` - Comma-delimited list of identifiers of Julia processes that NEMO should use in parallelized operations. NEMO adds values specified in a configuration file to those requested in the `targetprocs` argument for [`calculatescenario`](@ref).
  + `restrictvars` - Indicates whether NEMO should conduct additional data analysis to limit the set of model variables created for the scenario (`true` or `false`). By default, to improve performance, NEMO selectively creates certain variables to avoid combinations of subscripts that do not exist in the scenario's data. This option increases the stringency of this filtering. It requires more processing time as the model is built, but it can substantially reduce the solve time for large models. If this option is specified in a configuration file, it overrides the `restrictvars` argument for [`calculatescenario`](@ref).
  + `reportzeros` - Indicates whether results saved in the scenario database should include values equal to zero (`true` or `false`). Forgoing zeros can substantially improve the performance of large models. If this option is specified in a configuration file, it overrides the `reportzeros` argument for [`calculatescenario`](@ref).
  + `continuoustransmission` - Indicates whether continuous (`true`) or binary (`false`) variables are used to represent investment decisions for candidate [transmission lines](@ref transmissionline). This option can decrease model run-time but reduces the realism of transmission simulations. It is not relevant in scenarios that do not model transmission. If this option is specified in a configuration file, it overrides the `continuoustransmission` argument for [`calculatescenario`](@ref).
  + `quiet` - Indicates whether NEMO should suppress low-priority status messages (which are otherwise printed to `STDOUT`). If this option is specified in a configuration file, it overrides the `quiet` argument for [`calculatescenario`](@ref).
* `includes` block
  + `beforescenariocalc` - Path to a Julia script that should be run before NEMO calculates the scenario. The path should be defined relative to the Julia working directory (e.g., `./my_script.jl`).
  + `customconstraints` - Path to a Julia script that should be run when NEMO builds constraints for the scenario. The script can be used to add [custom constraints](@ref custom_constraints) to the model. The path should be defined relative to the Julia working directory.

NEMO comes with a sample configuration file saved at `utils/nemo.ini` in the NEMO package directory. You can find the NEMO package directory in Julia as follows:

```
julia> using NemoMod
julia> println(normpath(joinpath(pathof(NemoMod), "..", "..")))
```

Here's an example of a configuration file that sets a few of the available options.

```
[calculatescenarioargs]
varstosave=vnewcapacity,vtotalcapacityannual
continuoustransmission=true

[includes]
beforescenariocalc=./before_scenario_script.jl
customconstraints=./custom_constraints.jl
```
