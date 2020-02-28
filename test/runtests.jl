#=
    NEMO: Next-generation Energy Modeling system for Optimization.
    https://github.com/sei-international/NemoMod.jl

    Copyright © 2019: Stockholm Environment Institute U.S.

	File description: Tests for NemoMod package. Running full suite of tests requires
        GLPK, Cbc, CPLEX, Gurobi, and Mosek solvers. However, this file is configured
        so that tests for proprietary solvers are skipped if solvers are not present.
=#

using NemoMod
using Test, SQLite, DataFrames, JuMP

const TOL = 1e-4  # Default tolerance for isapprox() comparisons

"""Helper function for deleting a SQLite database file after Julia has been told to release it (e.g.,
    with finalize(db); db = nothing; GC.gc())."""
function delete_dbfile(path::String, max_del_attempts::Int)
    del_attempts::Int = 0  # Number of deletions that have been attempted

    while isfile(path) && del_attempts < max_del_attempts
        try
            del_attempts += 1
            rm(path; force = true)
            sleep(0.5)  # Without this, the next isfile() test sometimes throws an I/O error
        catch
            # Wait and continue
            sleep(0.5)
        end
    end
end  # delete_dbfile(path::String)

@testset "Solving a scenario" begin
    include(joinpath(@__DIR__, "glpk_tests.jl"))
    include(joinpath(@__DIR__, "cbc_tests.jl"))
    include(joinpath(@__DIR__, "cplex_tests.jl"))
    include(joinpath(@__DIR__, "gurobi_tests.jl"))
    include(joinpath(@__DIR__, "mosek_tests.jl"))
end  # @testset "Solving a scenario"

@testset "Other database operations" begin
    @testset "Create a new NEMO database" begin
        # Wrap SQLite operations in a function in order to get Julia to release new DB file for deletion
        function new_nemo_db()
            db = NemoMod.createnemodb(joinpath(@__DIR__, "new_nemo.sqlite"))

            @test isfile(joinpath(@__DIR__, "new_nemo.sqlite"))
            # Test that AccumulatedAnnualDemand table exists
            @test !SQLite.done(SQLite.DBInterface.execute(db, "PRAGMA table_info('AccumulatedAnnualDemand')"))
        end  # new_nemo_db()

        new_nemo_db()
        GC.gc()

        # Try up to 20 times to delete file
        delete_dbfile(joinpath(@__DIR__, "new_nemo.sqlite"), 20)

        @test !isfile(joinpath(@__DIR__, "new_nemo.sqlite"))
        # END: Delete new database file.
    end  # @testset "Create a new NEMO database"

    @testset "Create a new NEMO database with LEAP parameter defaults" begin
        # Wrap SQLite operations in a function in order to get Julia to release new DB file for deletion
        function new_nemo_leap_db()
            db = NemoMod.createnemodb_leap(joinpath(@__DIR__, "new_nemo_leap.sqlite"))

            @test isfile(joinpath(@__DIR__, "new_nemo_leap.sqlite"))
            # Test that AccumulatedAnnualDemand table exists
            @test !SQLite.done(SQLite.DBInterface.execute(db, "PRAGMA table_info('AccumulatedAnnualDemand')"))
            # Look for default value for AccumulatedAnnualDemand parameter
            @test DataFrame(SQLite.DBInterface.execute(db, "SELECT val FROM DefaultParams WHERE tablename = 'AccumulatedAnnualDemand'"))[1,:val] == 0.0
        end  # new_nemo_leap_db()

        new_nemo_leap_db()
        GC.gc()

        # Try up to 20 times to delete file
        delete_dbfile(joinpath(@__DIR__, "new_nemo_leap.sqlite"), 20)

        @test !isfile(joinpath(@__DIR__, "new_nemo_leap.sqlite"))
        # END: Delete new database file.
    end  # @testset "Create a new NEMO database with LEAP parameter defaults"

    @testset "Set parameter default" begin
        # Wrap SQLite operations in a function in order to get Julia to release new DB file for deletion
        function param_default_db()
            db = NemoMod.createnemodb(joinpath(@__DIR__, "param_default.sqlite"))
            @test SQLite.done(SQLite.DBInterface.execute(db, "SELECT val FROM DefaultParams WHERE tablename = 'VariableCost'"))  # No rows in query result

            NemoMod.setparamdefault(db, "VariableCost", 1.0)

            @test DataFrame(SQLite.DBInterface.execute(db, "SELECT val FROM DefaultParams WHERE tablename = 'VariableCost'"))[1,:val] == 1.0
        end  # param_default_db()

        param_default_db()
        GC.gc()

        # Try up to 20 times to delete file
        delete_dbfile(joinpath(@__DIR__, "param_default.sqlite"), 20)

        @test !isfile(joinpath(@__DIR__, "param_default.sqlite"))
        # END: Delete new database file.
    end  # @testset "Set parameter default"
end  # @testset "Other database operations"
