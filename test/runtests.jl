#=
    NEMO: Next Energy Modeling system for Optimization.
    https://github.com/sei-international/NemoMod.jl

    Copyright © 2019: Stockholm Environment Institute U.S.

	File description: Tests for NemoMod package. Running full suite of tests requires
        GLPK, Cbc, CPLEX, Gurobi, Mosek, and Xpress solvers. However, testing procedure
        is configured so that tests for a particular solver are skipped if solver is
        not present.
=#

include(joinpath(@__DIR__, "main.jl"))
all_tests()
