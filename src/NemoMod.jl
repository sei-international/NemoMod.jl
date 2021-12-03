#=
    NEMO: Next Energy Modeling system for Optimization.
    https://github.com/sei-international/NemoMod.jl

    Copyright © 2018: Stockholm Environment Institute U.S.

    File description: NemoMod module.
=#

module NemoMod
export calculatescenario, createnemodb, dropdefaultviews, dropresulttables, logmsg, setparamdefault

#= List of module global variables.
    • csdbpath - dbpath argument in most recent invocation of calculatescenario() or modelscenario()
    • csquiet - quiet argument in most recent invocation of calculatescenario() or modelscenario()
    • csrestrictyears - indicates whether most recent invocation of calculatescenario() or modelscenario() is for a selected set of years
    • csinyears - SQL in clause predicate indicating which years are selected in most recent invocation of calculatescenario() or modelscenario()
    • csjumpmodel - jumpmodel argument in most recent invocation of calculatescenario() or modelscenario() (only set if a customconstraints include is performed)
=#

# BEGIN: Access other modules and code files.
using JuMP, SQLite, DataFrames, Dates, ConfParser, MathOptInterface
using GLPK, Cbc  # Open-source solvers

# Proprietary solvers - enclosed in try blocks for users who aren't using NEMO installer
try
    using CPLEX
catch
    # Just continue
end

try
    using Gurobi
catch
    # Just continue
end

try
    using Mosek
catch
    # Just continue
end

# Do not load Xpress since it throws an unrecoverable error when loaded in a package on a machine without an Xpress license

include("db_structure.jl")  # Functions for manipulating structure of scenario databases
include("other_functions.jl")  # Core NEMO functions
include("scenario_calculation.jl")  # Functions for calculating a scenario with NEMO
# END: Access other modules and code files.

end  # module NemoMod
