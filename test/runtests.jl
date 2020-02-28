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
        chmod(dbfile, 0o777)  # Make dbfile read-write. Necessary because after Julia 1.0, Pkg.add makes all package files read-only

        # Test with default outputs
        NemoMod.calculatescenario(dbfile; quiet = false)  # GLPK is default solver

        db = SQLite.DB(dbfile)
        testqry = SQLite.DBInterface.execute(db, "select * from vtotaldiscountedcost") |> DataFrame

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

        testqry = SQLite.DBInterface.execute(db, "select * from vtotaldiscountedcost") |> DataFrame

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

        testqry = SQLite.DBInterface.execute(db, "select * from vtotaldiscountedcost") |> DataFrame

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

        # Test with storage net zero constraints
        SQLite.DBInterface.execute(db, "update STORAGE set netzeroyear = 1")
        NemoMod.calculatescenario(dbfile)
        testqry = SQLite.DBInterface.execute(db, "select * from vtotaldiscountedcost") |> DataFrame

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

        @test isapprox(testqry[1,:val], 3840.94032304097; atol=TOL)
        @test isapprox(testqry[2,:val], 459.294966842956; atol=TOL)
        @test isapprox(testqry[3,:val], 437.423777945669; atol=TOL)
        @test isapprox(testqry[4,:val], 416.594074233972; atol=TOL)
        @test isapprox(testqry[5,:val], 396.756261175212; atol=TOL)
        @test isapprox(testqry[6,:val], 377.863105881154; atol=TOL)
        @test isapprox(testqry[7,:val], 359.869624648718; atol=TOL)
        @test isapprox(testqry[8,:val], 342.732975855922; atol=TOL)
        @test isapprox(testqry[9,:val], 326.412357958021; atol=TOL)
        @test isapprox(testqry[10,:val], 310.868912340972; atol=TOL)

        SQLite.DBInterface.execute(db, "update STORAGE set netzeroyear = 0")

        # Delete test results and re-compact test database
        NemoMod.dropresulttables(db)
        testqry = SQLite.DBInterface.execute(db, "VACUUM")
    end  # "Solving storage_test with GLPK"

    @testset "Solving storage_test with Cbc" begin
        dbfile = joinpath(@__DIR__, "storage_test.sqlite")

        # Test with default outputs
        NemoMod.calculatescenario(dbfile; jumpmodel = Model(solver = CbcSolver(logLevel=1, presolve="on")),
            quiet = false)

        db = SQLite.DB(dbfile)
        testqry = SQLite.DBInterface.execute(db, "select * from vtotaldiscountedcost") |> DataFrame

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

        testqry = SQLite.DBInterface.execute(db, "select * from vtotaldiscountedcost") |> DataFrame

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

        testqry = SQLite.DBInterface.execute(db, "select * from vtotaldiscountedcost") |> DataFrame

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

        # Test with storage net zero constraints
        SQLite.DBInterface.execute(db, "update STORAGE set netzeroyear = 1")
        NemoMod.calculatescenario(dbfile; jumpmodel = Model(solver = CbcSolver(logLevel=1, presolve="on")))
        testqry = SQLite.DBInterface.execute(db, "select * from vtotaldiscountedcost") |> DataFrame

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

        @test isapprox(testqry[1,:val], 3840.94023817782; atol=TOL)
        @test isapprox(testqry[2,:val], 459.29493842479; atol=TOL)
        @test isapprox(testqry[3,:val], 437.423750880753; atol=TOL)
        @test isapprox(testqry[4,:val], 416.59404845786; atol=TOL)
        @test isapprox(testqry[5,:val], 396.756236626533; atol=TOL)
        @test isapprox(testqry[6,:val], 377.86308250146; atol=TOL)
        @test isapprox(testqry[7,:val], 359.8696023823438; atol=TOL)
        @test isapprox(testqry[8,:val], 342.73295464985; atol=TOL)
        @test isapprox(testqry[9,:val], 326.412337761762; atol=TOL)
        @test isapprox(testqry[10,:val], 310.86889310644; atol=TOL)

        SQLite.DBInterface.execute(db, "update STORAGE set netzeroyear = 0")

        # Delete test results and re-compact test database
        NemoMod.dropresulttables(db)
        testqry = SQLite.DBInterface.execute(db, "VACUUM")
    end  # "Solving storage_test with Cbc"
end  # @testset "Solving a scenario"

@testset "Other database operations" begin
    @testset "Create a new |nemo database" begin
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
    end  # @testset "Create a new |nemo database"

    @testset "Create a new |nemo database with LEAP parameter defaults" begin
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
    end  # @testset "Create a new |nemo database with LEAP parameter defaults"

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
