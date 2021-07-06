```@meta
CurrentModule = NemoMod
```
# [Configuration files](@id configuration_file)

When you calculate a scenario with NEMO, you can provide a configuration file that specifies run-time options. The file should be named `nemo.ini` or `nemo.cfg` and should be available in Julia's working directory. To check the working directory in a Julia session, use the `pwd` function. To change the working directory, use `cd`.

NEMO configuration files are text files written in `ini` syntax. The following run-time options can be set in a configuration file.

* `calculatescenarioargs` block
  + `calcyears` - Comma-delimited list of [`years`](@ref year) to include in the scenario calculation. If this option is specified in a configuration file, it overrides the `calcyears` argument for [`calculatescenario`](@ref).
  + `varstosave` - Comma-delimited list of output [variables](@ref variables) (Julia variable names) to save to the [scenario database](@ref scenario_db). NEMO adds values specified in a configuration file to those requested in the `varstosave` argument for [`calculatescenario`](@ref).
  + `numprocs` - Number of Julia processes to use for parallelized operations (a positive integer or 0 for half the number of logical processors on the executing machine). If this option is specified in a configuration file, it overrides the `numprocs` argument for [`calculatescenario`](@ref).
  + `targetprocs` - Comma-delimited list of identifiers of Julia processes that NEMO should use in parallelized operations. NEMO adds values specified in a configuration file to those requested in the `targetprocs` argument for [`calculatescenario`](@ref).
  + `restrictvars` - Indicates whether NEMO should conduct additional data analysis to limit the set of model variables created for the scenario (`true` or `false`). By default, to improve performance, NEMO selectively creates certain variables to avoid combinations of subscripts that do not exist in the scenario's data. This option increases the stringency of this filtering. It requires more processing time as the model is built, but it can substantially reduce the solve time for large models. If this option is specified in a configuration file, it overrides the `restrictvars` argument for [`calculatescenario`](@ref).
  + `reportzeros` - Indicates whether results saved in the scenario database should include values equal to zero (`true` or `false`). Forgoing zeros can substantially improve the performance of large models. If this option is specified in a configuration file, it overrides the `reportzeros` argument for [`calculatescenario`](@ref).
  + `continuoustransmission` - Indicates whether continuous (`true`) or binary (`false`) variables are used to represent investment decisions for candidate [transmission lines](@ref transmissionline). Continuous decision variables can decrease model run-time but may reduce the realism of transmission simulations. This option is not relevant in scenarios that do not model transmission. If it is specified in a configuration file, it overrides the `continuoustransmission` argument for [`calculatescenario`](@ref).
  + `forcemip` - Indicates whether NEMO is forced to formulate a mixed-integer optimization problem for the scenario (`true` or `false`). Activating this option can improve performance with some solvers (e.g., CPLEX). If this option is specified in a configuration file, it overrides the `forcemip` argument for [`calculatescenario`](@ref). If you do not activate `forcemip` (in a configuration file or as an argument for `calculatescenario`), the input parameters in your [scenario database](@ref scenario_db) determine whether the optimization problem for the scenario is mixed-integer. See the note under [Solver compatibility](@ref solver_compatibility) for more information.
  + `quiet` - Indicates whether NEMO should suppress low-priority status messages (which are otherwise printed to `STDOUT`). If this option is specified in a configuration file, it overrides the `quiet` argument for [`calculatescenario`](@ref).
* `solver` block
  + `parameters` - Comma-delimited list of solver run-time parameters. Format: parameter1=value1, parameter2=value2, ...
* `includes` block
  + `beforescenariocalc` - Path to a Julia script that should be run before NEMO calculates the scenario. The path should be defined relative to the Julia working directory (e.g., `./my_script.jl`).
  + `customconstraints` - Path to a Julia script that should be run when NEMO builds constraints for the scenario. The script can be used to add custom constraints to the model. The path should be defined relative to the Julia working directory.

NEMO comes with a sample configuration file saved at `utils/nemo.ini` in the NEMO package directory. You can find the NEMO package directory in Julia as follows:

```julia
julia> using NemoMod

julia> println(normpath(joinpath(pathof(NemoMod), "..", "..")))
```

Here's an example of a configuration file that sets a few of the available options.

```
[calculatescenarioargs]
varstosave=vnewcapacity,vtotalcapacityannual
continuoustransmission=true

[solver]
parameters=CPX_PARAM_DEPIND=-1,CPXPARAM_LPMethod=1  ; Parameters for CPLEX solver

[includes]
beforescenariocalc=./before_scenario_script.jl
customconstraints=./custom_constraints.jl
```

## Including a configuration file in a LEAP-NEMO model

If you're running NEMO through LEAP, you can include a NEMO configuration file in your LEAP model to have it used at calculation time. Options set in the file will override or add to the NEMO options LEAP would otherwise choose (see above for details on which options override defaults and which add to them).

Here are the steps to follow:

1. Create the configuration file and name it `nemo.cfg`.
2. Close your model in LEAP.
3. Locate the LEAP areas repository on your computer. The areas repository is a folder where LEAP saves all models installed on a computer; typically, it is in your Windows user's Documents folder and is named "LEAP Areas". As of LEAP version 2020.1.0.37, you can find the path to the LEAP areas repository within LEAP by looking at Settings -> Folders -> Areas.
   ![LEAP folder settings](assets/leap_folders.png)
4. Copy the configuration file to your model's folder in the LEAP areas repository. This folder will have the same name as your model.
5. Open the model in LEAP and calculate a scenario that optimizes with NEMO. If the configuration file is successfully used in the calculation, you should see output in the NEMO window that indicates the file was read (unless you set the `quiet` option in the configuration file to `true` - this suppresses the output).

!!! note
    When modifying a existing NEMO configuration file in a LEAP-NEMO model, be sure to close the model in LEAP first. Otherwise your changes may not be applied correctly.
