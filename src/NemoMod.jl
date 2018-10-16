#=
    NEMO: Next-generation Energy Modeling system for Optimization.
    https://github.com/sei-international/NemoMod.jl

    Copyright © 2018: Stockholm Environment Institute U.S.

    Release 0.1: Julia version of OSeMOSYS version 2017_11_08.  http://www.osemosys.org/

    File description: NemoMod module.
=#

module NemoMod

# BEGIN: Access other modules and code files.
using JuMP, SQLite, DataFrames, Distributed, Dates, GLPKMathProgInterface
# CPLEX, Cbc - not yet available for Julia 0.7
include("nemo_functions.jl")  # Core NEMO functions
include("scenario_calculation.jl")  # Functions for calculating a scenario with NEMO
# END: Access other modules and code files.

end  # module NemoMod
