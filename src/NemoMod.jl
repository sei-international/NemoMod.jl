#=
    |nemo: Next-generation Energy Modeling system for Optimization.
    https://github.com/sei-international/NemoMod.jl

    Copyright © 2018: Stockholm Environment Institute U.S.

    File description: NemoMod module.
=#

module NemoMod

# BEGIN: Access other modules and code files.
using JuMP, SQLite, DataFrames, Distributed, Dates
using GLPKMathProgInterface  # Default solver

include("nemo_functions.jl")  # Core |nemo functions
include("scenario_calculation.jl")  # Functions for calculating a scenario with |nemo
# END: Access other modules and code files.

end  # module NemoMod
