```@meta
CurrentModule = NemoMod
```
# [Custom constraints](@id custom_constraints)

NEMO includes a mechanism for defining custom constraints that are added to a model when a scenario is calculated. To take advantage of this feature, you must write a Julia script that creates the constraints and point to the script in your model's NEMO [configuration file](@ref configuration_file). Use the `customconstraints` key in the configuration file's `includes` block to specify the path to your custom constraints script.

Custom constraints scripts typically consist of a function that builds constraints and a call to the function. The function's arguments generally include several global variables that NEMO makes available for custom constraints:

* `csjumpmodel` (`JuMP.Model`): The JuMP optimization model for the scenario that is calculating. New constraints should be added to this object.

* `csdbpath` (`String`): The path to the scenario's database.

* `csquiet` (`Bool`): The `quiet` argument specified when initiating the scenario calculation (via [`calculatescenario`](@ref) or [`writescenariomodel`](@ref)).

* `csrestrictyears` (`Bool`): Indicates whether the scenario calculation is for selected years as opposed to all years in the scenario database.

* `csinyears` (`String`): If `csrestrictyears` is true, a comma-delimited list of the years included in the scenario calculation. The list is enclosed in parentheses, and the string begins and ends with a space. For instance: `" (2020, 2030, 2040, 2050) "`. This variable can be used to filter query results when creating custom constraints.

Here's an example of a simple custom constraints script. It creates constraints that define an annual emission limit that applies to multiple regions as a group. Custom constraints are needed in this case because NEMO's [`AnnualEmissionLimit`](@ref AnnualEmissionLimit) parameter is region-specific.

```julia
#= This script builds custom constraints for NEMO. It is meant to be included in NEMO's
    customconstraints event (calculatescenario/writescenariomodel function). =#

using SQLite, JuMP

# BEGIN: Custom constraints to include in all scenarios.
function build_constraints(db::SQLite.DB, jumpmodel::JuMP.Model, quiet::Bool,
    restrictyears::Bool, inyears::String)
    # BEGIN: Custom constraints enforcing multi-region annual emission limit.
    multiregionemissionlimit::Array{ConstraintRef, 1}
        = Array{ConstraintRef, 1}()  # Array of custom constraints added to jumpmodel

    # Apply restrictyears and inyears to limit to constraints to selected years
    for row in SQLite.DBInterface.execute(db, "select val from YEAR
        $(restrictyears ? "where val in" * inyears : "")")

        local y = row[:val]

        # Target regions have IDs R2 and R3; target emission has ID E2
        # Since model variables are not in scope, reference them with variable_by_name()
        push!(multiregionemissionlimit, @constraint(jumpmodel,
            variable_by_name(jumpmodel, "vannualemissions[R2,E2,$y]")
            + variable_by_name(jumpmodel, "vannualemissions[R3,E2,$y]") <= 50000000))
    end

    # Can log array of custom constraints to inspect function's results
    # length(multiregionemissionlimit) > 0
    #    && logmsg(string(multiregionemissionlimit), quiet)

    length(multiregionemissionlimit) > 0
        && logmsg("Created custom constraint enforcing multi-region annual emission limit.",
            quiet)
    # END: Custom constraints enforcing multi-region annual emission limit.
end  # build_constraints
# END: Custom constraints to include in all scenarios.

# Call build_constraints referencing NEMO global variables
build_constraints(SQLite.DB(csdbpath), csjumpmodel, csquiet, csrestrictyears, csinyears)
```

Note how the script uses the global variables, and also how it refers to NEMO [output variables](@ref variables) with the JuMP function `variable_by_name`. The calls to `variable_by_name` are necessary because the output variables are not in scope.

Another good practice in this script is that it writes a message to `STDOUT` if it creates any new constraints. NEMO's [`logmsg`](@ref) function is invoked for this purpose.

!!! note
    If you define a custom constraints script for a model and optimize the model with [limited foresight](@ref foresight), NEMO executes the script for each group of years in the limited foresight calculation. You must make sure your code is compatible with this procedure.

## Custom constraints in LEAP-NEMO models

For the most part, adding custom constraints to a LEAP-NEMO model is just a matter of following the procedure laid out above. There are a few additional steps, however, which are needed to ensure that at run-time, LEAP copies the custom constraints script and NEMO configuration file to the Julia working directory it uses with NEMO.

1. Turn off LEAP.
2. Name your custom constraints script with a `.txt` extension (e.g., `customconstraints.txt`), and save it in the LEAP Areas folder for your model. To find this folder, go to Settings -> Folders in LEAP, and make note of the path in the Areas field. The LEAP Areas folder for your model is a subdirectory in this path with the same name as the model.
3. Add a NEMO configuration file named `nemo.cfg` in the LEAP Areas folder for your model. In this file, set the `customconstraints` key in the `includes` block to `./[name of your custom constraints script]`. For example:

```
[includes]
customconstraints=./customconstraints.txt
```

!!! note
    Another point to remember when adding custom constraints to a LEAP-NEMO model is that the constraints must properly account for the model's [units of measure](@ref uoms). When LEAP runs NEMO, it uses petajoules as the energy unit, gigawatts for power, million $ for costs, and metric tonnes for emissions.
