#=
    NEMO: Next-generation Energy Modeling system for Optimization.
    https://github.com/sei-international/NemoMod.jl

    Copyright © 2018: Stockholm Environment Institute U.S.

    File description: NemoMod module.
=#

module NemoMod
export calculatescenario, createnemodb, dropdefaultviews, dropresulttables, logmsg, setparamdefault

#= List of module global variables.
    • csdbpath - dbpath argument in last invocation of calculatescenario()
    • csquiet - quiet argument in last invocation of calculatescenario()
    • csjumpmodel - jumpmodel argument in last invocation of calculatescenario() (only set if a customconstraints include is performed)
=#

# BEGIN: Access other modules and code files.
using JuMP, SQLite, DataFrames, Distributed, Dates, ConfParser
using GLPKMathProgInterface, Cbc  # Open-source solvers

# Proprietary solvers - enclosed in try blocks for users who aren't using NEMO installer
include("solver_support.jl")  # Functions for working with solvers

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

include("nemo_functions.jl")  # Core NEMO functions
include("scenario_calculation.jl")  # Functions for calculating a scenario with NEMO
# END: Access other modules and code files.

end  # module NemoMod
