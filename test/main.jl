#=
    NEMO: Next Energy Modeling system for Optimization.
    https://github.com/sei-international/NemoMod.jl

    Copyright © 2021: Stockholm Environment Institute U.S.

	File description: Defines functions, package references, and constants used
        to test NemoMod package.
=#

if !@isdefined NemoMod
    using NemoMod
end

using Test, SQLite, DataFrames, JuMP

const TOL = 0.01  # Default tolerance for isapprox() comparisons

try
    using Cbc
catch e
    @info "Error when initializing Cbc. Error message: " * sprint(showerror, e) * "."
    @info "Skipping Cbc tests."
    # Continue
end

try
    using GLPK
catch e
    @info "Error when initializing GLPK. Error message: " * sprint(showerror, e) * "."
    @info "Skipping GLPK tests."
    # Continue
end

try
    using CPLEX
catch e
    @info "Error when initializing CPLEX. Error message: " * sprint(showerror, e) * "."
    @info "Skipping CPLEX tests."
    # Continue
end

try
    using Gurobi
catch e
    @info "Error when initializing Gurobi. Error message: " * sprint(showerror, e) * "."
    @info "Skipping Gurobi tests."
    # Continue
end

try
    using MosekTools
catch e
    @info "Error when initializing Mosek. Error message: " * sprint(showerror, e) * "."
    @info "Skipping Mosek tests."
end

try
    using Xpress
catch e
    @info "Error when initializing Xpress. Error message: " * sprint(showerror, e) * "."
    @info "Skipping Xpress tests."
    # Continue
end

# Functions for solver-specific tests of scenario solution
include(joinpath(@__DIR__, "cbc_tests.jl"))
include(joinpath(@__DIR__, "glpk_tests.jl"))
include(joinpath(@__DIR__, "cplex_tests.jl"))
include(joinpath(@__DIR__, "gurobi_tests.jl"))
include(joinpath(@__DIR__, "mosek_tests.jl"))
include(joinpath(@__DIR__, "xpress_tests.jl"))

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

"""Helper function used in test of writing optimization problem for a scenario. Wrapping
    file creation operation in a function helps ensure Julia releases output file for deletion."""
function write_opt_prob(optprobfile::String, compilation::Bool = false)
    dbfile = joinpath(@__DIR__, "storage_test.sqlite")
    chmod(dbfile, 0o777)  # Make dbfile read-write. Necessary because after Julia 1.0, Pkg.add makes all package files read-only

    # Write output file for optimization problem
    NemoMod.writescenariomodel(dbfile; restrictvars=true, quiet = false, writefilename = optprobfile)

    # Clean up scenario database
    db = SQLite.DB(dbfile)
    NemoMod.dropresulttables(db)
    testqry = SQLite.DBInterface.execute(db, "VACUUM")

    !compilation && @test isfile(optprobfile)
end  # write_opt_prob(optprobfile::String, compilation::Bool = false)

"""Helper function used in test of creating a new NEMO database. Wrapping SQLite
    operations in a function helps ensure Julia releases new DB file for deletion."""
function new_nemo_db(compilation::Bool = false)
    db = NemoMod.createnemodb(joinpath(@__DIR__, "new_nemo.sqlite"))

    !compilation && @test isfile(joinpath(@__DIR__, "new_nemo.sqlite"))
    # Test that AccumulatedAnnualDemand table exists
    !compilation && @test !SQLite.done(SQLite.DBInterface.execute(db, "PRAGMA table_info('AccumulatedAnnualDemand')"))
end  # new_nemo_db(compilation::Bool = false)

# Wrap SQLite operations in a function in order to get Julia to release new DB file for deletion
"""Helper function used in test of setting parameter defaults. Wrapping SQLite
    operations in a function helps ensure Julia releases new DB file for deletion."""
function param_default_db(compilation::Bool = false)
    db = NemoMod.createnemodb(joinpath(@__DIR__, "param_default.sqlite"))
    !compilation && @test SQLite.done(SQLite.DBInterface.execute(db, "SELECT val FROM DefaultParams WHERE tablename = 'VariableCost'"))  # No rows in query result

    NemoMod.setparamdefault(db, "VariableCost", 1.0)

    !compilation && @test DataFrame(SQLite.DBInterface.execute(db, "SELECT val FROM DefaultParams WHERE tablename = 'VariableCost'"))[1,:val] == 1.0
end  # param_default_db(compilation::Bool = false)

"""Runs entire suite of NemoMod tests. If `compilation` is true, does not execute calls to `@test`."""
function all_tests(compilation::Bool = false)
    @testset "Solving a scenario" begin
        cbc_tests(compilation)
        cplex_tests(compilation)
        glpk_tests(compilation)
        gurobi_tests(compilation)
        mosek_tests(compilation)
        xpress_tests(compilation)
    end  # @testset "Solving a scenario"

    @testset "Writing optimization problem for a scenario" begin
        @info "Testing function to write optimization problem for a scenario."
        optprobfile = joinpath(@__DIR__, "storage_test_prob.gz")

        write_opt_prob(optprobfile, compilation)
        GC.gc()

        # Try up to 20 times to delete file
        delete_file(optprobfile, 20)

        !compilation && @test !isfile(optprobfile)
    end  # @testset "Writing optimization problem for a scenario"

    @testset "Other database operations" begin
        @info "Testing other database operations."

        @testset "Create a new NEMO database" begin
            new_nemo_db(compilation)
            GC.gc()

            # Try up to 20 times to delete file
            delete_file(joinpath(@__DIR__, "new_nemo.sqlite"), 20)

            !compilation && @test !isfile(joinpath(@__DIR__, "new_nemo.sqlite"))
        end  # @testset "Create a new NEMO database"

        @testset "Set parameter default" begin
            param_default_db(compilation)
            GC.gc()

            # Try up to 20 times to delete file
            delete_file(joinpath(@__DIR__, "param_default.sqlite"), 20)

            !compilation && @test !isfile(joinpath(@__DIR__, "param_default.sqlite"))
        end  # @testset "Set parameter default"
    end  # @testset "Other database operations"
end  # all_tests(compilation::Bool = false)
