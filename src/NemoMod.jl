#=
    |nemo: Next-generation Energy Modeling system for Optimization.
    https://github.com/sei-international/NemoMod.jl

    Copyright © 2018: Stockholm Environment Institute U.S.

    File description: NemoMod module.
=#

module NemoMod

#= List of module global variables.
    • csdbpath - dbpath argument in last invocation of calculatescenario()
    • csquiet - quiet argument in last invocation of calculatescenario()
    • csjumpmodel - jumpmodel argument in last invocation of calculatescenario() (only set if a customconstraints include is performed)
=#

# BEGIN: Access other modules and code files.
using JuMP, SQLite, DataFrames, Distributed, Dates, ConfParser
using GLPKMathProgInterface, Cbc  # Default solvers

include("nemo_functions.jl")  # Core |nemo functions
include("scenario_calculation.jl")  # Functions for calculating a scenario with |nemo
# END: Access other modules and code files.

end  # module NemoMod
