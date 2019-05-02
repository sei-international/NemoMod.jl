#=
    |nemo: Next-generation Energy Modeling system for Optimization.
    https://github.com/sei-international/NemoMod.jl

    Copyright © 2019: Stockholm Environment Institute U.S.

	File description: A test of NemoMod package using CPLEX solver. This file is provided for users wishing
        to native compile NEMO with support for CPLEX.
=#

using NemoMod
using Test, SQLite, DataFrames, JuMP, CPLEX

const TOL = 1e-4  # Default tolerance for isapprox() comparisons

@testset "Solving a scenario" begin
    @testset "Solving storage_test with CPLEX" begin
        dbfile = joinpath(@__DIR__, "storage_test.sqlite")

        NemoMod.calculatescenario(dbfile; jumpmodel = JuMP.Model(solver = CplexSolver()))

        db = SQLite.DB(dbfile)
        testqry = SQLite.query(db, "select * from vtotaldiscountedcost")

        @test testqry[1,:y] == "2020"
        @test testqry[2,:y] == "2021"
        @test testqry[3,:y] == "2022"
        @test testqry[4,:y] == "2023"
        @test testqry[5,:y] == "2024"
        @test testqry[6,:y] == "2025"
        @test testqry[7,:y] == "2026"
        @test testqry[8,:y] == "2027"
        @test testqry[9,:y] == "2028"
        @test testqry[10,:y] == "2029"

        @test isapprox(testqry[1,:val], 3845.15703404259; atol=TOL)
        @test isapprox(testqry[2,:val], 146.55227050539; atol=TOL)
        @test isapprox(testqry[3,:val], 139.57362837926; atol=TOL)
        @test isapprox(testqry[4,:val], 132.927266053843; atol=TOL)
        @test isapprox(testqry[5,:val], 126.597396376304; atol=TOL)
        @test isapprox(testqry[6,:val], 120.568948487497; atol=TOL)
        @test isapprox(testqry[7,:val], 114.827569988092; atol=TOL)
        @test isapprox(testqry[8,:val], 109.35959046485; atol=TOL)
        @test isapprox(testqry[9,:val], 104.151990918904; atol=TOL)
        @test isapprox(testqry[10,:val], 99.1923723037184; atol=TOL)

        # Delete test results and re-compact test database
        NemoMod.dropresulttables(db)
        testqry = SQLite.query(db, "VACUUM")
    end  # "Solving storage_test with CPLEX"
end  # @testset "Solving a scenario"
