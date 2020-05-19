```@meta
CurrentModule = NemoMod
```

# [Scenario databases](@id scenario_db)

Scenario databases store inputs and outputs for a NEMO model scenario, including dimensions, parameters, and calculated result variables. Each scenario has its own database. To calculate a scenario, you pass its database to the [`calculatescenario`](@ref) function. NEMO then reads inputs from the database and writes results back to it.

!!! tip
    For examples of scenario databases, look in the `test` directory for the NEMO Julia package. You can find this directory as follows.

    ```julia
    julia> using NemoMod

    julia> println(normpath(joinpath(pathof(NemoMod), "..", "..", "test")))
    ```

## Tables

Scenario databases include tables for [dimensions](@ref dimensions), [parameters](@ref parameters), and [calculated variables](@ref variables), all described in other parts of this documentation. There is also a table called `Version` that indicates the NEMO data dictionary version with which the database is compatible.

## Views and indices

When NEMO calculates a scenario, it automatically builds views and indices in the database that are needed for the run. You shouldn't have to modify them. The views show default values for parameters as specified in the [`DefaultParams`](@ref DefaultParams) table. There is a view for each parameter the includes all values given in the parameter's table plus the default value (assuming there is one) for combinations of dimensions not represented in the table.

## Database platform

NEMO uses [SQLite](https://www.sqlite.org/) version 3 as its database platform. You can access a scenario database with any SQLite client, such as [DB Browser for SQLite](https://sqlitebrowser.org/). To work with a scenario database in Julia, use the [SQLite package](https://juliadatabases.github.io/SQLite.jl/stable/).

## Utility functions

NEMO provides a few functions for working with scenario databases in Julia.

- [`createnemodb`](@ref) - Creates a new, empty scenario database.
- [`dropdefaultviews`](@ref) - Drops views showing default values for parameters.
- [`dropresulttables`](@ref) - Drops all tables for calculated variables (i.e., scenario results).
- [`setparamdefault`](@ref) - Sets the default value for a parameter.
