#=
    NEMO: Next Energy Modeling system for Optimization.
    https://github.com/sei-international/NemoMod.jl

    Copyright © 2019: Stockholm Environment Institute U.S.

	File description: Tests for NemoMod package. Running full suite of tests requires
        GLPK, Cbc, CPLEX, Gurobi, Mosek, and Xpress solvers. However, this file is configured
        so that tests for Cbc and proprietary solvers are skipped if solvers are not present.
=#

if !@isdefined NemoMod
    using NemoMod
end

using Test, SQLite, DataFrames, JuMP, Distributed

const TOL = 1e-4  # Default tolerance for isapprox() comparisons

"""Helper function for deleting a file after Julia has been told to release it (e.g.,
    with finalize(db); db = nothing; GC.gc())."""
function delete_file(path::String, max_del_attempts::Int)
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
end  # delete_file(path::String)

@testset "Solving a scenario" begin
    include(joinpath(@__DIR__, "glpk_tests.jl"))
    include(joinpath(@__DIR__, "cbc_tests.jl"))
    include(joinpath(@__DIR__, "cplex_tests.jl"))
    include(joinpath(@__DIR__, "gurobi_tests.jl"))
    include(joinpath(@__DIR__, "mosek_tests.jl"))
    include(joinpath(@__DIR__, "xpress_tests.jl"))
end  # @testset "Solving a scenario"

@testset "Writing optimization problem for a scenario" begin
    optprobfile = joinpath(@__DIR__, "storage_test_prob.gz")

    # Wrap file creation operation in a function to ensure Julia releases output file for deletion
    function write_opt_prob()
        dbfile = joinpath(@__DIR__, "storage_test.sqlite")
        chmod(dbfile, 0o777)  # Make dbfile read-write. Necessary because after Julia 1.0, Pkg.add makes all package files read-only

        # Write output file for optimization problem
        NemoMod.writescenariomodel(dbfile; numprocs=1, restrictvars=false, quiet = false, writefilename = optprobfile)

        # Clean up scenario database
        db = SQLite.DB(dbfile)
        NemoMod.dropresulttables(db)
        testqry = SQLite.DBInterface.execute(db, "VACUUM")

        @test isfile(optprobfile)
    end  # write_opt_prob()

    write_opt_prob()
    GC.gc()

    # Try up to 20 times to delete file
    delete_file(optprobfile, 20)

    @test !isfile(optprobfile)
end  # @testset "Writing optimization problem for a scenario"

@testset "Other database operations" begin
    @info "Running tests of other database operations."

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
        delete_file(joinpath(@__DIR__, "new_nemo.sqlite"), 20)

        @test !isfile(joinpath(@__DIR__, "new_nemo.sqlite"))
    end  # @testset "Create a new NEMO database"

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
        delete_file(joinpath(@__DIR__, "param_default.sqlite"), 20)

        @test !isfile(joinpath(@__DIR__, "param_default.sqlite"))
    end  # @testset "Set parameter default"
end  # @testset "Other database operations"
