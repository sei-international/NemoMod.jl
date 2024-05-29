#=
    NEMO: Next Energy Modeling system for Optimization.
    https://github.com/sei-international/NemoMod.jl

    Copyright © 2019: Stockholm Environment Institute U.S.

	File description: Tests for NemoMod package. Running full suite of tests requires
        GLPK, Cbc, CPLEX, Gurobi, Mosek, and Xpress solvers. However, testing procedure
        is configured so that tests for a particular solver are skipped if solver is
        not present.
=#

if !@isdefined NemoMod
    using NemoMod
end

using Test, SQLite, DataFrames, JuMP

const TOL = 0.1  # Default tolerance for isapprox() comparisons

if !@isdefined compilation  # Flag that turns off @test calls
    compilation = false
end

if !@isdefined reg_jumpmode  # If reg_jumpmode is false, disables JuMP bridging or turns on JuMP's direct mode (depending on the solver) in solver-specific tests
    reg_jumpmode = true
end

if !@isdefined calculatescenario_quiet  # quiet argument passed to calculatescenario calls
    calculatescenario_quiet = true
end

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
function write_opt_prob(optprobfile::String)
    dbfile = joinpath(@__DIR__, "storage_test.sqlite")
    chmod(dbfile, 0o777)  # Make dbfile read-write. Necessary because after Julia 1.0, Pkg.add makes all package files read-only

    # Write output file for optimization problem
    NemoMod.writescenariomodel(dbfile; restrictvars=true, quiet = false, writefilename = optprobfile)

    # Clean up scenario database
    db = SQLite.DB(dbfile)
    NemoMod.dropresulttables(db)
    testqry = SQLite.DBInterface.execute(db, "VACUUM")

    !compilation && @test isfile(optprobfile)
end  # write_opt_prob(optprobfile::String)

"""Helper function used in test of precalcresultspath logic. Wrapping file creation operations
    in a function helps ensure Julia releases new files for modification/deletion."""
function precalcresultspath_setup(testpath::String, db1name::String, db2name::String)
    mkdir(testpath)

    # Create two empty scenario databases, one used to test passing a directory path to precalcresultspath and one used to test passing a file path to precalcresultspath
    NemoMod.createnemodb(joinpath(testpath, db1name))
    !compilation && @test isfile(joinpath(testpath, db1name))

    NemoMod.createnemodb(joinpath(testpath, db2name))
    !compilation && @test isfile(joinpath(testpath, db2name))
end  # precalcresultspath_setup(testpath::String, db1name::String, db2name::String)

"""Helper function used in test of creating a new NEMO database. Wrapping SQLite
    operations in a function helps ensure Julia releases new DB file for deletion."""
function new_nemo_db()
    db = NemoMod.createnemodb(joinpath(@__DIR__, "new_nemo.sqlite"))

    !compilation && @test isfile(joinpath(@__DIR__, "new_nemo.sqlite"))
    # Test that AccumulatedAnnualDemand table exists
    !compilation && @test !SQLite.done(SQLite.DBInterface.execute(db, "PRAGMA table_info('AccumulatedAnnualDemand')"))
end  # new_nemo_db()

# Wrap SQLite operations in a function in order to get Julia to release new DB file for deletion
"""Helper function used in test of setting parameter defaults. Wrapping SQLite
    operations in a function helps ensure Julia releases new DB file for deletion."""
function param_default_db()
    db = NemoMod.createnemodb(joinpath(@__DIR__, "param_default.sqlite"))
    !compilation && @test SQLite.done(SQLite.DBInterface.execute(db, "SELECT val FROM DefaultParams WHERE tablename = 'VariableCost'"))  # No rows in query result

    NemoMod.setparamdefault(db, "VariableCost", 1.0)

    !compilation && @test DataFrame(SQLite.DBInterface.execute(db, "SELECT val FROM DefaultParams WHERE tablename = 'VariableCost'"))[1,:val] == 1.0
end  # param_default_db()

@testset "Solving a scenario" begin
    include(joinpath(@__DIR__, "cbc_tests.jl"))
    include(joinpath(@__DIR__, "cplex_tests.jl"))
    include(joinpath(@__DIR__, "gurobi_tests.jl"))
    include(joinpath(@__DIR__, "highs_tests.jl"))
    include(joinpath(@__DIR__, "mosek_tests.jl"))
    include(joinpath(@__DIR__, "xpress_tests.jl"))
    include(joinpath(@__DIR__, "glpk_tests.jl"))
end  # @testset "Solving a scenario"

@testset "JuMP direct mode and bridging" begin
    # Tests will be skipped if HiGHS package is not installed.
    if @isdefined HiGHS
        @info "Testing options to control JuMP direct mode and bridging."
        dbfile = joinpath(@__DIR__, "storage_test.sqlite")
        chmod(dbfile, 0o777)  # Make dbfile read-write. Necessary because after Julia 1.0, Pkg.add makes all package files read-only

        configfile = joinpath(pwd(), "nemo.ini")  # Config file used to access options for controlling direct mode and bridging
        delete_file(configfile, 20)

        open(configfile, "w") do io
            write(io, "[calculatescenarioargs]\r\n")
            write(io, "jumpbridges=false\r\n")
        end

        NemoMod.calculatescenario(dbfile; jumpmodel = JuMP.Model(HiGHS.Optimizer), quiet = calculatescenario_quiet)
        db = SQLite.DB(dbfile)

        if !compilation
            @test DataFrame(SQLite.DBInterface.execute(db, "select count(*) from vtotaldiscountedcost"))[1,1] > 0
        end

        open(configfile, "a") do io
            write(io, "jumpdirectmode=true\r\n")
        end

        NemoMod.calculatescenario(dbfile; jumpmodel = JuMP.Model(HiGHS.Optimizer), quiet = calculatescenario_quiet)

        if !compilation
            @test DataFrame(SQLite.DBInterface.execute(db, "select count(*) from vtotaldiscountedcost"))[1,1] > 0
        end

        # Delete config file
        delete_file(configfile, 20)

        # Delete test results and re-compact test database
        NemoMod.dropresulttables(db)
        testqry = SQLite.DBInterface.execute(db, "VACUUM")
    else
        @info "Skipping tests of options to control JuMP direct mode and bridging as HiGHS is not initialized."
    end
end  # @testset "JuMP direct mode and bridging"

@testset "Writing optimization problem for a scenario" begin
    @info "Testing function to write optimization problem for a scenario."
    optprobfile = joinpath(@__DIR__, "storage_test_prob.gz")

    write_opt_prob(optprobfile)
    GC.gc()

    # Try up to 20 times to delete file
    delete_file(optprobfile, 20)

    !compilation && @test !isfile(optprobfile)
end  # @testset "Writing optimization problem for a scenario"

@testset "Testing precalcresultspath logic" begin
    @info "Testing precalcresultspath logic."

    testpath = joinpath(@__DIR__, "precalctest")
    db1name = "storage_test.sqlite"
    db2name = "precalctest.sqlite"
    precalcresultspath_setup(testpath, db1name, db2name)
    GC.gc()

    db1path = joinpath(testpath, db1name)
    db2path = joinpath(testpath, db2name)

    # BEGIN: Test passing a directory path to precalcresultspath.
    # db1 should be overwritten with file in precalcresultspath with same name
    NemoMod.calculatescenario(db1path; precalcresultspath=@__DIR__, quiet = calculatescenario_quiet)

    !compilation && @test isfile(db1path)
    db = SQLite.DB(db1path)
    !compilation && @test !SQLite.done(SQLite.DBInterface.execute(db, "select val from TECHNOLOGY"))

    # Try up to 20 times to delete file
    finalize(db); db = nothing; GC.gc()
    delete_file(db1path, 20)
    !compilation && @test !isfile(db1path)
    # END: Test passing a directory path to precalcresultspath.

    # BEGIN: Test passing a file path to precalcresultspath.
    # db2 should be overwritten with specified file
    NemoMod.calculatescenario(db2path; precalcresultspath=joinpath(@__DIR__, "storage_test.sqlite"), quiet = calculatescenario_quiet)

    !compilation && @test isfile(db2path)
    db = SQLite.DB(db2path)
    !compilation && @test !SQLite.done(SQLite.DBInterface.execute(db, "select val from TECHNOLOGY"))

    # Try up to 20 times to delete file
    finalize(db); db = nothing; GC.gc()
    delete_file(db2path, 20)
    !compilation && @test !isfile(db2path)
    # END: Test passing a file path to precalcresultspath.

    rm(testpath)
    !compilation && @test !ispath(testpath)
end  # @testset "Testing precalcresultspath logic"

@testset "Other database operations" begin
    @info "Testing other database operations."

    @testset "Create a new NEMO database" begin
        new_nemo_db()
        GC.gc()

        # Try up to 20 times to delete file
        delete_file(joinpath(@__DIR__, "new_nemo.sqlite"), 20)

        !compilation && @test !isfile(joinpath(@__DIR__, "new_nemo.sqlite"))
    end  # @testset "Create a new NEMO database"

    @testset "Set parameter default" begin
        param_default_db()
        GC.gc()

        # Try up to 20 times to delete file
        delete_file(joinpath(@__DIR__, "param_default.sqlite"), 20)

        !compilation && @test !isfile(joinpath(@__DIR__, "param_default.sqlite"))
    end  # @testset "Set parameter default"
end  # @testset "Other database operations"
