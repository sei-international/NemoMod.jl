#=
    NEMO: Next Energy Modeling system for Optimization.
    https://github.com/sei-international/NemoMod.jl

    Copyright © 2019: Stockholm Environment Institute U.S.

	File description: Tests of NemoMod package using Mosek solver.
=#

# Tests will be skipped if MosekTools package is not installed.
try
    using MosekTools
catch e
    @info "Error when initializing Mosek. Error message: " * sprint(showerror, e) * "."
    @info "Skipping Mosek tests."
end

if @isdefined MosekTools
    @info "Testing scenario solution with Mosek."

    @testset "Solving storage_test with Mosek" begin
        dbfile = joinpath(@__DIR__, "storage_test.sqlite")
        #dbfile = "c:/temp/storage_test.sqlite"
        chmod(dbfile, 0o777)  # Make dbfile read-write. Necessary because after Julia 1.0, Pkg.add makes all package files read-only

        # Test with default outputs
        NemoMod.calculatescenario(dbfile; jumpmodel = JuMP.Model(Mosek.Optimizer),
            restrictvars=false, quiet = false)

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

        @test isapprox(testqry[1,:val], 3845.15702798338; atol=TOL)
        @test isapprox(testqry[2,:val], 146.552320420142; atol=TOL)
        @test isapprox(testqry[3,:val], 139.573628995129; atol=TOL)
        @test isapprox(testqry[4,:val], 132.927265707472; atol=TOL)
        @test isapprox(testqry[5,:val], 126.597395911861; atol=TOL)
        @test isapprox(testqry[6,:val], 120.568948035628; atol=TOL)
        @test isapprox(testqry[7,:val], 114.827569988096; atol=TOL)
        @test isapprox(testqry[8,:val], 109.359590464853; atol=TOL)
        @test isapprox(testqry[9,:val], 104.151990918907; atol=TOL)
        @test isapprox(testqry[10,:val], 99.1907267770023; atol=TOL)

        # Test with optional outputs
        NemoMod.calculatescenario(dbfile; jumpmodel = JuMP.Model(Mosek.Optimizer),
            varstosave =
                "vrateofproductionbytechnologybymode, vrateofusebytechnologybymode, vrateofdemand, vproductionbytechnology, vtotaltechnologyannualactivity, "
                * "vtotaltechnologymodelperiodactivity, vusebytechnology, vmodelperiodcostbyregion, vannualtechnologyemissionpenaltybyemission, "
                * "vtotaldiscountedcost",
            restrictvars=false, quiet = false)

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

        @test isapprox(testqry[1,:val], 3845.15702798338; atol=TOL)
        @test isapprox(testqry[2,:val], 146.552320420142; atol=TOL)
        @test isapprox(testqry[3,:val], 139.573628995129; atol=TOL)
        @test isapprox(testqry[4,:val], 132.927265707472; atol=TOL)
        @test isapprox(testqry[5,:val], 126.597395911861; atol=TOL)
        @test isapprox(testqry[6,:val], 120.568948035628; atol=TOL)
        @test isapprox(testqry[7,:val], 114.827569988096; atol=TOL)
        @test isapprox(testqry[8,:val], 109.359590464853; atol=TOL)
        @test isapprox(testqry[9,:val], 104.151990918907; atol=TOL)
        @test isapprox(testqry[10,:val], 99.1907267770023; atol=TOL)

        # Test with restrictvars
        NemoMod.calculatescenario(dbfile; jumpmodel = JuMP.Model(Mosek.Optimizer),
            varstosave = "vrateofproductionbytechnologybymode, vrateofusebytechnologybymode, vproductionbytechnology, vusebytechnology, "
                * "vtotaldiscountedcost",
            restrictvars = true, quiet = false)

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

        @test isapprox(testqry[1,:val], 3845.15702798338; atol=TOL)
        @test isapprox(testqry[2,:val], 146.552320420142; atol=TOL)
        @test isapprox(testqry[3,:val], 139.573628995129; atol=TOL)
        @test isapprox(testqry[4,:val], 132.927265707472; atol=TOL)
        @test isapprox(testqry[5,:val], 126.597395911861; atol=TOL)
        @test isapprox(testqry[6,:val], 120.568948035628; atol=TOL)
        @test isapprox(testqry[7,:val], 114.827569988096; atol=TOL)
        @test isapprox(testqry[8,:val], 109.359590464853; atol=TOL)
        @test isapprox(testqry[9,:val], 104.151990918907; atol=TOL)
        @test isapprox(testqry[10,:val], 99.1907267770023; atol=TOL)

        # Test with storage net zero constraints
        SQLite.DBInterface.execute(db, "update STORAGE set netzeroyear = 1")
        NemoMod.calculatescenario(dbfile; jumpmodel = JuMP.Model(Mosek.Optimizer), restrictvars=false)
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

        @test isapprox(testqry[1,:val], 3840.94023817774; atol=TOL)
        @test isapprox(testqry[2,:val], 459.292614204884; atol=TOL)
        @test isapprox(testqry[3,:val], 437.421537337638; atol=TOL)
        @test isapprox(testqry[4,:val], 416.59194032216; atol=TOL)
        @test isapprox(testqry[5,:val], 396.754228877952; atol=TOL)
        @test isapprox(testqry[6,:val], 377.861170359965; atol=TOL)
        @test isapprox(testqry[7,:val], 359.867781295205; atol=TOL)
        @test isapprox(testqry[8,:val], 342.731220281158; atol=TOL)
        @test isapprox(testqry[9,:val], 326.410685982046; atol=TOL)
        @test isapprox(testqry[10,:val], 310.8673199829; atol=TOL)

        SQLite.DBInterface.execute(db, "update STORAGE set netzeroyear = 0")

        # Test with calcyears
        NemoMod.calculatescenario(dbfile; jumpmodel = Model(Mosek.Optimizer), restrictvars=true,
            calcyears=[2020,2029])
        testqry = SQLite.DBInterface.execute(db, "select * from vtotaldiscountedcost") |> DataFrame

        @test testqry[1,:y] == "2020"
        @test testqry[2,:y] == "2029"

        @test isapprox(testqry[1,:val], 3840.93779774689; atol=TOL)
        @test isapprox(testqry[2,:val], 3427.79849864389; atol=TOL)

        # Test MinimumUtilization
        SQLite.DBInterface.execute(db, "insert into MinimumUtilization select ROWID, '1', 'gas', val, 2025, 0.5 from TIMESLICE")
        NemoMod.calculatescenario(dbfile; jumpmodel = Model(Mosek.Optimizer), varstosave="vproductionbytechnologyannual")
        testqry = SQLite.DBInterface.execute(db, "select * from vproductionbytechnologyannual where t = 'gas' and y = 2025") |> DataFrame

        @test isapprox(testqry[1,:val], 15.768; atol=TOL)

        SQLite.DBInterface.execute(db, "delete from MinimumUtilization")

        # Delete test results and re-compact test database
        NemoMod.dropresulttables(db)
        testqry = SQLite.DBInterface.execute(db, "VACUUM")
    end  # "Solving storage_test with Mosek"

    @testset "Solving storage_transmission_test with Mosek" begin
        dbfile = joinpath(@__DIR__, "storage_transmission_test.sqlite")
        #dbfile = "c:/temp/storage_transmission_test.sqlite"
        chmod(dbfile, 0o777)  # Make dbfile read-write. Necessary because after Julia 1.0, Pkg.add makes all package files read-only

        NemoMod.calculatescenario(dbfile; jumpmodel = JuMP.Model(Mosek.Optimizer),
            varstosave =
                "vdemandnn, vnewcapacity, vtotalcapacityannual, vproductionbytechnologyannual, vproductionnn, vusebytechnologyannual, vusenn, vtotaldiscountedcost, "
                * "vtransmissionbuilt, vtransmissionexists, vtransmissionbyline, vtransmissionannual",
            restrictvars=false, quiet = false)

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

        @test isapprox(testqry[1,:val], 9786.56609769189; atol=TOL)
        @test isapprox(testqry[2,:val], 239.495174532817; atol=TOL)
        @test isapprox(testqry[3,:val], 228.090642412206; atol=TOL)
        @test isapprox(testqry[4,:val], 217.22918324972; atol=TOL)
        @test isapprox(testqry[5,:val], 206.88494534077; atol=TOL)
        @test isapprox(testqry[6,:val], 197.033272788862; atol=TOL)
        @test isapprox(testqry[7,:val], 187.650797384118; atol=TOL)
        @test isapprox(testqry[8,:val], 178.714986656564; atol=TOL)
        @test isapprox(testqry[9,:val], 170.204749196728; atol=TOL)
        @test isapprox(testqry[10,:val], 162.099761139741; atol=TOL)

        # Test MinimumUtilization
        SQLite.DBInterface.execute(db, "insert into MinimumUtilization select ROWID, '1', 'gas', val, 2025, 0.2 from TIMESLICE")
        NemoMod.calculatescenario(dbfile; jumpmodel = Model(Mosek.Optimizer), varstosave="vproductionbytechnologyannual", calcyears=[2020,2025,2029])
        testqry = SQLite.DBInterface.execute(db, "select * from vproductionbytechnologyannual where t = 'gas' and y = 2025") |> DataFrame

        @test isapprox(testqry[1,:val], 16.3149963697108; atol=TOL)

        SQLite.DBInterface.execute(db, "delete from MinimumUtilization")

        # Test interest rates
        SQLite.DBInterface.execute(db, "insert into InterestRateStorage select rowid, 1, 'storage1', y.val, 0.05 from year y")
        SQLite.DBInterface.execute(db, "insert into InterestRateTechnology select rowid, 1, 'solar', y.val, 0.05 from year y")
        SQLite.DBInterface.execute(db, "update TransmissionLine set interestrate = 0.05 where id = 2")
        NemoMod.calculatescenario(dbfile; jumpmodel = Model(Mosek.Optimizer), varstosave="vtotaldiscountedcost", calcyears=[2020,2025,2029])
        testqry = SQLite.DBInterface.execute(db, "select * from vtotaldiscountedcost") |> DataFrame

        @test testqry[1,:y] == "2020"
        @test testqry[2,:y] == "2025"
        @test testqry[3,:y] == "2029"

        @test isapprox(testqry[1,:val], 12672.8114730171; atol=TOL)
        @test isapprox(testqry[2,:val], 2510.44589185654; atol=TOL)
        @test isapprox(testqry[3,:val], 1611.02255483292; atol=TOL)

        SQLite.DBInterface.execute(db, "delete from InterestRateStorage")
        SQLite.DBInterface.execute(db, "delete from InterestRateTechnology")
        SQLite.DBInterface.execute(db, "update TransmissionLine set interestrate = null where id = 2")

        # Test transshipment power flow
        SQLite.DBInterface.execute(db, "update TransmissionModelingEnabled set type = 3")
        SQLite.DBInterface.execute(db, "update TransmissionLine set efficiency = 0.9")
        NemoMod.calculatescenario(dbfile; jumpmodel = Model(Mosek.Optimizer), varstosave="vtotaldiscountedcost", calcyears=[2020,2025,2029])
        testqry = SQLite.DBInterface.execute(db, "select * from vtotaldiscountedcost") |> DataFrame
        @test testqry[1,:y] == "2020"
        @test testqry[2,:y] == "2025"
        @test testqry[3,:y] == "2029"

        @test isapprox(testqry[1,:val], 4855.79076447287; atol=TOL)
        @test isapprox(testqry[2,:val], 2687.29032799192; atol=TOL)
        @test isapprox(testqry[3,:val], 1738.34669443912; atol=TOL)

        SQLite.DBInterface.execute(db, "update TransmissionModelingEnabled set type = 2")
        SQLite.DBInterface.execute(db, "update TransmissionLine set efficiency = null")

        # Delete test results and re-compact test database
        NemoMod.dropresulttables(db)
        testqry = SQLite.DBInterface.execute(db, "VACUUM")
    end  # "Solving storage_transmission_test with Mosek"

    @testset "Solving ramp_test with Mosek" begin
        dbfile = joinpath(@__DIR__, "ramp_test.sqlite")
        #dbfile = "c:/temp/ramp_test.sqlite"
        chmod(dbfile, 0o777)  # Make dbfile read-write. Necessary because after Julia 1.0, Pkg.add makes all package files read-only

        NemoMod.calculatescenario(dbfile; jumpmodel = JuMP.Model(Mosek.Optimizer),
            restrictvars=false, quiet = false)

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

        @test isapprox(testqry[1,:val], 4163.77771390785; atol=TOL)
        @test isapprox(testqry[2,:val], 1606.0180127748; atol=TOL)
        @test isapprox(testqry[3,:val], 1529.54096454743; atol=TOL)
        @test isapprox(testqry[4,:val], 1456.70568052136; atol=TOL)
        @test isapprox(testqry[5,:val], 1387.33874335368; atol=TOL)
        @test isapprox(testqry[6,:val], 1321.27164305297; atol=TOL)
        @test isapprox(testqry[7,:val], 1258.35996962756; atol=TOL)
        @test isapprox(testqry[8,:val], 1198.44067149609; atol=TOL)
        @test isapprox(testqry[9,:val], 1141.373808485; atol=TOL)
        @test isapprox(testqry[10,:val], 1084.83956451882; atol=TOL)

        # Delete test results and re-compact test database
        NemoMod.dropresulttables(db)
        testqry = SQLite.DBInterface.execute(db, "VACUUM")
    end  # "Solving ramp_test with Mosek"

    GC.gc()
end  # @isdefined MosekTools
