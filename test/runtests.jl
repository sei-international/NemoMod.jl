#=
    |nemo: Next-generation Energy Modeling system for Optimization.
    https://github.com/sei-international/NemoMod.jl

    Copyright © 2019: Stockholm Environment Institute U.S.

	File description: Tests for NemoMod package.
=#

using NemoMod
using Test, SQLite, DataFrames, JuMP, Cbc

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
    @testset "Solving storage_test with GLPK" begin
        dbfile = joinpath(@__DIR__, "storage_test.sqlite")

        # Test with default outputs
        NemoMod.calculatescenario(dbfile; quiet = false)  # GLPK is default solver

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

        @test isapprox(testqry[1,:val], 3845.15711985937; atol=TOL)
        @test isapprox(testqry[2,:val], 146.552326874185; atol=TOL)
        @test isapprox(testqry[3,:val], 139.573639845721; atol=TOL)
        @test isapprox(testqry[4,:val], 132.927276043543; atol=TOL)
        @test isapprox(testqry[5,:val], 126.597405755756; atol=TOL)
        @test isapprox(testqry[6,:val], 120.568957862625; atol=TOL)
        @test isapprox(testqry[7,:val], 114.827578916785; atol=TOL)
        @test isapprox(testqry[8,:val], 109.359598968367; atol=TOL)
        @test isapprox(testqry[9,:val], 104.151999017492; atol=TOL)
        @test isapprox(testqry[10,:val], 99.1923800166593; atol=TOL)

        # Test with optional outputs
        NemoMod.calculatescenario(dbfile; varstosave =
            "vrateofproductionbytechnologybymode, vrateofusebytechnologybymode, vrateofdemand, vproductionbytechnology, vtotaltechnologyannualactivity, "
            * "vtotaltechnologymodelperiodactivity, vusebytechnology, vmodelperiodcostbyregion, vannualtechnologyemissionpenaltybyemission, "
            * "vtotaldiscountedcost", quiet = false)

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

        @test isapprox(testqry[1,:val], 3845.15711985937; atol=TOL)
        @test isapprox(testqry[2,:val], 146.552326874185; atol=TOL)
        @test isapprox(testqry[3,:val], 139.573639845721; atol=TOL)
        @test isapprox(testqry[4,:val], 132.927276043543; atol=TOL)
        @test isapprox(testqry[5,:val], 126.597405755756; atol=TOL)
        @test isapprox(testqry[6,:val], 120.568957862625; atol=TOL)
        @test isapprox(testqry[7,:val], 114.827578916785; atol=TOL)
        @test isapprox(testqry[8,:val], 109.359598968367; atol=TOL)
        @test isapprox(testqry[9,:val], 104.151999017492; atol=TOL)
        @test isapprox(testqry[10,:val], 99.1923800166593; atol=TOL)

        # Test with restrictvars
        NemoMod.calculatescenario(dbfile; varstosave =
            "vrateofproductionbytechnologybymode, vrateofusebytechnologybymode, vproductionbytechnology, vusebytechnology, "
            * "vtotaldiscountedcost", restrictvars = true, targetprocs = Array{Int, 1}([1]), quiet = false)

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

        @test isapprox(testqry[1,:val], 3845.15711985937; atol=TOL)
        @test isapprox(testqry[2,:val], 146.552326874185; atol=TOL)
        @test isapprox(testqry[3,:val], 139.573639845721; atol=TOL)
        @test isapprox(testqry[4,:val], 132.927276043543; atol=TOL)
        @test isapprox(testqry[5,:val], 126.597405755756; atol=TOL)
        @test isapprox(testqry[6,:val], 120.568957862625; atol=TOL)
        @test isapprox(testqry[7,:val], 114.827578916785; atol=TOL)
        @test isapprox(testqry[8,:val], 109.359598968367; atol=TOL)
        @test isapprox(testqry[9,:val], 104.151999017492; atol=TOL)
        @test isapprox(testqry[10,:val], 99.1923800166593; atol=TOL)

        # Delete test results and re-compact test database
        NemoMod.dropresulttables(db)
        testqry = SQLite.query(db, "VACUUM")
    end  # "Solving storage_test with GLPK"

    @testset "Solving storage_test with Cbc" begin
        dbfile = joinpath(@__DIR__, "storage_test.sqlite")

        # Test with default outputs
        NemoMod.calculatescenario(dbfile; jumpmodel = Model(solver = CbcSolver(logLevel=1, presolve="on")),
            quiet = false)

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

        @test isapprox(testqry[1,:val], 3845.15711985937; atol=TOL)
        @test isapprox(testqry[2,:val], 146.552326874185; atol=TOL)
        @test isapprox(testqry[3,:val], 139.573639845721; atol=TOL)
        @test isapprox(testqry[4,:val], 132.927276043543; atol=TOL)
        @test isapprox(testqry[5,:val], 126.597405755756; atol=TOL)
        @test isapprox(testqry[6,:val], 120.568957862625; atol=TOL)
        @test isapprox(testqry[7,:val], 114.827578916785; atol=TOL)
        @test isapprox(testqry[8,:val], 109.359598968367; atol=TOL)
        @test isapprox(testqry[9,:val], 104.151999017492; atol=TOL)
        @test isapprox(testqry[10,:val], 99.1923800166593; atol=TOL)

        # Test with optional outputs
        NemoMod.calculatescenario(dbfile; jumpmodel = Model(solver = CbcSolver(logLevel=1, presolve="on")),
            varstosave =
                "vrateofproductionbytechnologybymode, vrateofusebytechnologybymode, vrateofdemand, vproductionbytechnology, vtotaltechnologyannualactivity, "
                * "vtotaltechnologymodelperiodactivity, vusebytechnology, vmodelperiodcostbyregion, vannualtechnologyemissionpenaltybyemission, "
                * "vtotaldiscountedcost",
            quiet = false)

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

        @test isapprox(testqry[1,:val], 3845.15711985937; atol=TOL)
        @test isapprox(testqry[2,:val], 146.552326874185; atol=TOL)
        @test isapprox(testqry[3,:val], 139.573639845721; atol=TOL)
        @test isapprox(testqry[4,:val], 132.927276043543; atol=TOL)
        @test isapprox(testqry[5,:val], 126.597405755756; atol=TOL)
        @test isapprox(testqry[6,:val], 120.568957862625; atol=TOL)
        @test isapprox(testqry[7,:val], 114.827578916785; atol=TOL)
        @test isapprox(testqry[8,:val], 109.359598968367; atol=TOL)
        @test isapprox(testqry[9,:val], 104.151999017492; atol=TOL)
        @test isapprox(testqry[10,:val], 99.1923800166593; atol=TOL)

        # Test with restrictvars
        NemoMod.calculatescenario(dbfile; jumpmodel = Model(solver = CbcSolver(logLevel=1, presolve="on")),
            varstosave = "vrateofproductionbytechnologybymode, vrateofusebytechnologybymode, vproductionbytechnology, vusebytechnology, "
                * "vtotaldiscountedcost",
            restrictvars = true, targetprocs = Array{Int, 1}([1]), quiet = false)

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

        @test isapprox(testqry[1,:val], 3845.15711985937; atol=TOL)
        @test isapprox(testqry[2,:val], 146.552326874185; atol=TOL)
        @test isapprox(testqry[3,:val], 139.573639845721; atol=TOL)
        @test isapprox(testqry[4,:val], 132.927276043543; atol=TOL)
        @test isapprox(testqry[5,:val], 126.597405755756; atol=TOL)
        @test isapprox(testqry[6,:val], 120.568957862625; atol=TOL)
        @test isapprox(testqry[7,:val], 114.827578916785; atol=TOL)
        @test isapprox(testqry[8,:val], 109.359598968367; atol=TOL)
        @test isapprox(testqry[9,:val], 104.151999017492; atol=TOL)
        @test isapprox(testqry[10,:val], 99.1923800166593; atol=TOL)

        # Delete test results and re-compact test database
        NemoMod.dropresulttables(db)
        testqry = SQLite.query(db, "VACUUM")
    end  # "Solving storage_test with Cbc"
end  # @testset "Solving a scenario"

@testset "Other database operations" begin
    @testset "Create a new |nemo database" begin
        db = NemoMod.createnemodb(joinpath(@__DIR__, "new_nemo.sqlite"))

        @test isfile(joinpath(@__DIR__, "new_nemo.sqlite"))
        # Test that AccumulatedAnnualDemand table exists
        @test size(SQLite.query(db, "PRAGMA table_info('AccumulatedAnnualDemand')"))[1] > 0

        # BEGIN: Delete new database file.
        # Get Julia to release file
        finalize(db); db = nothing; GC.gc()

        # Try up to 20 times to delete file
        delete_dbfile(joinpath(@__DIR__, "new_nemo.sqlite"), 20)

        @test !isfile(joinpath(@__DIR__, "new_nemo.sqlite"))
        # END: Delete new database file.
    end  # @testset "Create a new |nemo database"

    @testset "Create a new |nemo database with LEAP parameter defaults" begin
        db = NemoMod.createnemodb_leap(joinpath(@__DIR__, "new_nemo_leap.sqlite"))

        @test isfile(joinpath(@__DIR__, "new_nemo_leap.sqlite"))
        # Test that AccumulatedAnnualDemand table exists
        @test size(SQLite.query(db, "PRAGMA table_info('AccumulatedAnnualDemand')"))[1] > 0
        # Look for default value for AccumulatedAnnualDemand parameter
        @test SQLite.query(db, "SELECT val FROM DefaultParams WHERE tablename = 'AccumulatedAnnualDemand'")[1,:val] == 0.0

        # BEGIN: Delete new database file.
        # Get Julia to release file
        finalize(db); db = nothing; GC.gc()

        # Try up to 20 times to delete file
        delete_dbfile(joinpath(@__DIR__, "new_nemo_leap.sqlite"), 20)

        @test !isfile(joinpath(@__DIR__, "new_nemo_leap.sqlite"))
        # END: Delete new database file.
    end  # @testset "Create a new |nemo database with LEAP parameter defaults"

    @testset "Set parameter default" begin
        db = NemoMod.createnemodb(joinpath(@__DIR__, "param_default.sqlite"))
        @test size(SQLite.query(db, "SELECT val FROM DefaultParams WHERE tablename = 'VariableCost'"))[1] == 0  # No rows in query result

        NemoMod.setparamdefault(db, "VariableCost", 1.0)

        @test SQLite.query(db, "SELECT val FROM DefaultParams WHERE tablename = 'VariableCost'")[1,:val] == 1.0

        # BEGIN: Delete new database file.
        # Get Julia to release file
        finalize(db); db = nothing; GC.gc()

        # Try up to 20 times to delete file
        delete_dbfile(joinpath(@__DIR__, "param_default.sqlite"), 20)

        @test !isfile(joinpath(@__DIR__, "param_default.sqlite"))
        # END: Delete new database file.
    end  # @testset "Set parameter default"
end  # @testset "Other database operations"
