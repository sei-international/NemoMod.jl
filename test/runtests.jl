#=
    NEMO: Next-generation Energy Modeling system for Optimization.
    https://github.com/sei-international/NemoMod.jl

    Copyright © 2018: Stockholm Environment Institute U.S.

    Release 0.1: Julia version of OSeMOSYS version 2017_11_08.  http://www.osemosys.org/

	File description: Tests for NemoMod package.
=#

using NemoMod
using Test, SQLite, DataFrames, Pkg

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
    @testset "Solving UTOPIA with GLPK" begin
        dbfile = joinpath(@__DIR__, "utopia.sqlite")

        NemoMod.calculatescenario(dbfile; solver = "GLPK")

        db = SQLite.DB(dbfile)
        testqry = SQLite.query(db, "select * from vtotaldiscountedcost")

        @test testqry[1,:y] == "1990"
        @test testqry[2,:y] == "1991"
        @test testqry[3,:y] == "1992"
        @test testqry[4,:y] == "1993"
        @test testqry[5,:y] == "1994"
        @test testqry[6,:y] == "1995"
        @test testqry[7,:y] == "1996"
        @test testqry[8,:y] == "1997"
        @test testqry[9,:y] == "1998"
        @test testqry[10,:y] == "1999"
        @test testqry[11,:y] == "2000"
        @test testqry[12,:y] == "2001"
        @test testqry[13,:y] == "2002"
        @test testqry[14,:y] == "2003"
        @test testqry[15,:y] == "2004"
        @test testqry[16,:y] == "2005"
        @test testqry[17,:y] == "2006"
        @test testqry[18,:y] == "2007"
        @test testqry[19,:y] == "2008"
        @test testqry[20,:y] == "2009"
        @test testqry[21,:y] == "2010"

        @test isapprox(testqry[1,:val], 7078.726833; atol=TOL)
        @test isapprox(testqry[2,:val], 1376.094496; atol=TOL)
        @test isapprox(testqry[3,:val], 1424.622928; atol=TOL)
        @test isapprox(testqry[4,:val], 1299.845856; atol=TOL)
        @test isapprox(testqry[5,:val], 1341.383291; atol=TOL)
        @test isapprox(testqry[6,:val], 1214.807617; atol=TOL)
        @test isapprox(testqry[7,:val], 1196.944055; atol=TOL)
        @test isapprox(testqry[8,:val], 1207.676216; atol=TOL)
        @test isapprox(testqry[9,:val], 1098.252384; atol=TOL)
        @test isapprox(testqry[10,:val], 1117.595158; atol=TOL)
        @test isapprox(testqry[11,:val], 1047.769294; atol=TOL)
        @test isapprox(testqry[12,:val], 1125.578368; atol=TOL)
        @test isapprox(testqry[13,:val], 1047.590383; atol=TOL)
        @test isapprox(testqry[14,:val], 1023.135753; atol=TOL)
        @test isapprox(testqry[15,:val], 937.081597; atol=TOL)
        @test isapprox(testqry[16,:val], 2029.877355; atol=TOL)
        @test isapprox(testqry[17,:val], 885.294875; atol=TOL)
        @test isapprox(testqry[18,:val], 838.923596; atol=TOL)
        @test isapprox(testqry[19,:val], 777.346299; atol=TOL)
        @test isapprox(testqry[20,:val], 718.732469; atol=TOL)
        @test isapprox(testqry[21,:val], 659.805869; atol=TOL)

        # Delete test results and re-compact test database
        NemoMod.dropresulttables(db)
        testqry = SQLite.query(db, "VACUUM")
    end  # "Solving UTOPIA with GLPK"

    if haskey(Pkg.installed(), "CPLEX")
        @testset "Solving UTOPIA with CPLEX" begin
            dbfile = joinpath(@__DIR__, "utopia.sqlite")

            NemoMod.calculatescenario(dbfile; solver = "CPLEX")

            db = SQLite.DB(dbfile)
            testqry = SQLite.query(db, "select * from vtotaldiscountedcost")

            @test testqry[1,:y] == "1990"
            @test testqry[2,:y] == "1991"
            @test testqry[3,:y] == "1992"
            @test testqry[4,:y] == "1993"
            @test testqry[5,:y] == "1994"
            @test testqry[6,:y] == "1995"
            @test testqry[7,:y] == "1996"
            @test testqry[8,:y] == "1997"
            @test testqry[9,:y] == "1998"
            @test testqry[10,:y] == "1999"
            @test testqry[11,:y] == "2000"
            @test testqry[12,:y] == "2001"
            @test testqry[13,:y] == "2002"
            @test testqry[14,:y] == "2003"
            @test testqry[15,:y] == "2004"
            @test testqry[16,:y] == "2005"
            @test testqry[17,:y] == "2006"
            @test testqry[18,:y] == "2007"
            @test testqry[19,:y] == "2008"
            @test testqry[20,:y] == "2009"
            @test testqry[21,:y] == "2010"

            @test isapprox(testqry[1,:val], 7078.726833; atol=TOL)
            @test isapprox(testqry[2,:val], 1376.094496; atol=TOL)
            @test isapprox(testqry[3,:val], 1424.622928; atol=TOL)
            @test isapprox(testqry[4,:val], 1299.845856; atol=TOL)
            @test isapprox(testqry[5,:val], 1341.383291; atol=TOL)
            @test isapprox(testqry[6,:val], 1214.807617; atol=TOL)
            @test isapprox(testqry[7,:val], 1196.944055; atol=TOL)
            @test isapprox(testqry[8,:val], 1207.676216; atol=TOL)
            @test isapprox(testqry[9,:val], 1098.252384; atol=TOL)
            @test isapprox(testqry[10,:val], 1117.595158; atol=TOL)
            @test isapprox(testqry[11,:val], 1047.769294; atol=TOL)
            @test isapprox(testqry[12,:val], 1125.578368; atol=TOL)
            @test isapprox(testqry[13,:val], 1047.590383; atol=TOL)
            @test isapprox(testqry[14,:val], 1023.135753; atol=TOL)
            @test isapprox(testqry[15,:val], 937.081597; atol=TOL)
            @test isapprox(testqry[16,:val], 2029.877355; atol=TOL)
            @test isapprox(testqry[17,:val], 885.294875; atol=TOL)
            @test isapprox(testqry[18,:val], 838.923596; atol=TOL)
            @test isapprox(testqry[19,:val], 777.346299; atol=TOL)
            @test isapprox(testqry[20,:val], 718.539524; atol=TOL)
            @test isapprox(testqry[21,:val], 659.775231; atol=TOL)

            # Delete test results and re-compact test database
            NemoMod.dropresulttables(db)
            testqry = SQLite.query(db, "VACUUM")
        end  # "Solving UTOPIA with CPLEX"
    end  # haskey(Pkg.installed(), "CPLEX")
end  # @testset "Solving a scenario"

@testset "Other database operations" begin
    # setparamdefault(db::SQLite.DB, table::String, val::Float64)
    @testset "Create a new NEMO database" begin
        db = NemoMod.createnemodb(joinpath(@__DIR__, "new_nemo.sqlite"))

        @test isfile(joinpath(@__DIR__, "new_nemo.sqlite"))
        # Test that there are rows in AccumulatedAnnualDemand table
        @test size(SQLite.query(db, "PRAGMA table_info('AccumulatedAnnualDemand')"))[1] > 0

        # BEGIN: Delete new database file.
        # Get Julia to release file
        finalize(db); db = nothing; GC.gc()

        # Try up to 20 times to delete file
        delete_dbfile(joinpath(@__DIR__, "new_nemo.sqlite"), 20)

        @test !isfile(joinpath(@__DIR__, "new_nemo.sqlite"))
        # END: Delete new database file.
    end  # @testset "Create a new NEMO database"

    @testset "Set parameter default" begin
        db = NemoMod.createnemodb(joinpath(@__DIR__, "param_default.sqlite"))
        @test ismissing(SQLite.query(db, "PRAGMA table_info('VariableCost')")[6,:dflt_value])

        NemoMod.setparamdefault(db, "VariableCost", 1.0)
        @test SQLite.query(db, "PRAGMA table_info('VariableCost')")[6,:dflt_value] == "1.0"

        # BEGIN: Delete new database file.
        # Get Julia to release file
        finalize(db); db = nothing; GC.gc()

        # Try up to 20 times to delete file
        delete_dbfile(joinpath(@__DIR__, "param_default.sqlite"), 20)

        @test !isfile(joinpath(@__DIR__, "param_default.sqlite"))
        # END: Delete new database file.
    end  # @testset "Set parameter default"
end  # @testset "Other database operations"
