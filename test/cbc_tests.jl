#=
    NEMO: Next Energy Modeling system for Optimization.
    https://github.com/sei-international/NemoMod.jl

    Copyright © 2019: Stockholm Environment Institute U.S.

	File description: Tests of NemoMod package using Cbc solver.
=#

try
    using Cbc
catch e
    @info "Error when initializing Cbc. Error message: " * sprint(showerror, e) * "."
    @info "Skipping Cbc tests."
    # Continue
end

# Tests will be skipped if Cbc package is not installed.
if @isdefined Cbc
    @info "Testing scenario solution with Cbc."

    @testset "Solving storage_test with Cbc" begin
        dbfile = joinpath(@__DIR__, "storage_test.sqlite")
        #dbfile = "c:/temp/storage_test.sqlite"
        chmod(dbfile, 0o777)  # Make dbfile read-write. Necessary because after Julia 1.0, Pkg.add makes all package files read-only

        # Test with default outputs
        @info "Running Cbc test 1 on storage_test.sqlite: default outputs."
        if reg_jumpmode
            NemoMod.calculatescenario(dbfile; restrictvars=false, quiet = calculatescenario_quiet)  # Cbc is NEMO's default solver
        else
            NemoMod.calculatescenario(dbfile; jumpmodel=Model(Cbc.Optimizer, add_bridges=false), restrictvars=false, quiet = calculatescenario_quiet)  # Cbc isn't compatible with direct mode
        end

        db = SQLite.DB(dbfile)

        if !compilation
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
        end

        # Test with optional outputs
        @info "Running Cbc test 2 on storage_test.sqlite: optional outputs."
        NemoMod.calculatescenario(dbfile; jumpmodel = Model(optimizer_with_attributes(Cbc.Optimizer, "presolve" => "on", "logLevel" => 1), add_bridges=reg_jumpmode),
            varstosave =
                "vrateofproductionbytechnologybymode, vrateofusebytechnologybymode, vrateofdemand, vproductionbytechnology, vtotaltechnologyannualactivity, "
                * "vtotaltechnologymodelperiodactivity, vusebytechnology, vmodelperiodcostbyregion, vannualtechnologyemissionpenaltybyemission, "
                * "vtotaldiscountedcost",
            restrictvars=false, quiet = calculatescenario_quiet)

        if !compilation
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
        end

        # Test with restrictvars
        @info "Running Cbc test 3 on storage_test.sqlite: restrictvars."
        NemoMod.calculatescenario(dbfile; jumpmodel = Model(optimizer_with_attributes(Cbc.Optimizer, "presolve" => "on", "logLevel" => 1), add_bridges=reg_jumpmode),
            varstosave = "vrateofproductionbytechnologybymode, vrateofusebytechnologybymode, vproductionbytechnology, vusebytechnology, "
                * "vtotaldiscountedcost",
            restrictvars = true, quiet = calculatescenario_quiet)

        if !compilation
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
        end

        # Test with storage net zero constraints
        @info "Running Cbc test 4 on storage_test.sqlite: storage net zero constraints."
        SQLite.DBInterface.execute(db, "update STORAGE set netzeroyear = 1")
        NemoMod.calculatescenario(dbfile; jumpmodel = Model(optimizer_with_attributes(Cbc.Optimizer, "presolve" => "on", "logLevel" => 1), add_bridges=reg_jumpmode), restrictvars=false, quiet = calculatescenario_quiet)

        if !compilation
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
        end

        SQLite.DBInterface.execute(db, "update STORAGE set netzeroyear = 0")

        # Test with calcyears
        @info "Running Cbc test 5 on storage_test.sqlite: calcyears."
        NemoMod.calculatescenario(dbfile; jumpmodel = Model(optimizer_with_attributes(Cbc.Optimizer, "presolve" => "on", "logLevel" => 1), add_bridges=reg_jumpmode), restrictvars=true,
            calcyears=[2020,2029], quiet = calculatescenario_quiet)

        if !compilation
            testqry = SQLite.DBInterface.execute(db, "select * from vtotaldiscountedcost") |> DataFrame

            @test testqry[1,:y] == "2020"
            @test testqry[2,:y] == "2029"

            @test isapprox(testqry[1,:val], 3840.94023817782; atol=TOL)
            @test isapprox(testqry[2,:val], 3427.81584479179; atol=TOL)
        end

        # Test MinimumUtilization
        @info "Running Cbc test 6 on storage_test.sqlite: minimum utilization."
        SQLite.DBInterface.execute(db, "insert into MinimumUtilization select ROWID, '1', 'gas', val, 2025, 0.5 from TIMESLICE")
        NemoMod.calculatescenario(dbfile; jumpmodel = Model(Cbc.Optimizer, add_bridges=reg_jumpmode), varstosave="vproductionbytechnologyannual", quiet = calculatescenario_quiet)

        if !compilation
            testqry = SQLite.DBInterface.execute(db, "select * from vproductionbytechnologyannual where t = 'gas' and y = 2025") |> DataFrame

            @test isapprox(testqry[1,:val], 15.768; atol=TOL)
        end

        SQLite.DBInterface.execute(db, "delete from MinimumUtilization")

        # Delete test results and re-compact test database
        NemoMod.dropresulttables(db)
        testqry = SQLite.DBInterface.execute(db, "VACUUM")
    end  # "Solving storage_test with Cbc"

    @testset "Solving storage_transmission_test with Cbc" begin
        dbfile = joinpath(@__DIR__, "storage_transmission_test.sqlite")
        #dbfile = "c:/temp/storage_transmission_test.sqlite"
        chmod(dbfile, 0o777)  # Make dbfile read-write. Necessary because after Julia 1.0, Pkg.add makes all package files read-only

        @info "Running Cbc test 1 on storage_transmission_test.sqlite: default outputs."
        NemoMod.calculatescenario(dbfile; jumpmodel = JuMP.Model(Cbc.Optimizer, add_bridges=reg_jumpmode),
            varstosave =
                "vdemandnn, vnewcapacity, vtotalcapacityannual, vproductionbytechnologyannual, vproductionnn, vusebytechnologyannual, vusenn, vtotaldiscountedcost, "
                * "vtransmissionbuilt, vtransmissionexists, vtransmissionbyline, vtransmissionannual",
            restrictvars=true, calcyears=[2025], quiet = calculatescenario_quiet)

        db = SQLite.DB(dbfile)

        if !compilation
            testqry = SQLite.DBInterface.execute(db, "select * from vtotaldiscountedcost") |> DataFrame

            @test testqry[1,:y] == "2025"

            @test isapprox(testqry[1,:val], 8547.93213319885; atol=TOL)
        end

        # Test MinimumUtilization
        @info "Running Cbc test 2 on storage_transmission_test.sqlite: minimum utilization."
        SQLite.DBInterface.execute(db, "insert into MinimumUtilization select ROWID, '1', 'gas', val, 2025, 0.2 from TIMESLICE")
        NemoMod.calculatescenario(dbfile; jumpmodel = Model(Cbc.Optimizer, add_bridges=reg_jumpmode), varstosave="vproductionbytechnologyannual", calcyears=[2025], quiet = calculatescenario_quiet)

        if !compilation
            testqry = SQLite.DBInterface.execute(db, "select * from vproductionbytechnologyannual where t = 'gas' and y = 2025") |> DataFrame

            @test isapprox(testqry[1,:val], 16.3149963697108; atol=TOL)
        end

        SQLite.DBInterface.execute(db, "delete from MinimumUtilization")

        # Test interest rates
        @info "Running Cbc test 3 on storage_transmission_test.sqlite: interest rates."
        SQLite.DBInterface.execute(db, "insert into InterestRateStorage select rowid, 1, 'storage1', y.val, 0.05 from year y")
        SQLite.DBInterface.execute(db, "insert into InterestRateTechnology select rowid, 1, 'solar', y.val, 0.05 from year y")
        SQLite.DBInterface.execute(db, "update TransmissionLine set interestrate = 0.05 where id = 2")
        NemoMod.calculatescenario(dbfile; jumpmodel = Model(Cbc.Optimizer, add_bridges=reg_jumpmode), varstosave="vtotaldiscountedcost", calcyears=[2025], quiet = calculatescenario_quiet)

        if !compilation
            testqry = SQLite.DBInterface.execute(db, "select * from vtotaldiscountedcost") |> DataFrame

            @test testqry[1,:y] == "2025"

            @test isapprox(testqry[1,:val], 10333.624520329; atol=TOL)
        end

        SQLite.DBInterface.execute(db, "delete from InterestRateStorage")
        SQLite.DBInterface.execute(db, "delete from InterestRateTechnology")
        SQLite.DBInterface.execute(db, "update TransmissionLine set interestrate = null where id = 2")

        # Test transshipment power flow
        @info "Running Cbc test 4 on storage_transmission_test.sqlite: transshipment power flow."
        SQLite.DBInterface.execute(db, "update TransmissionModelingEnabled set type = 3")
        SQLite.DBInterface.execute(db, "update TransmissionLine set efficiency = 0.9")
        NemoMod.calculatescenario(dbfile; jumpmodel = Model(Cbc.Optimizer, add_bridges=reg_jumpmode), varstosave="vtotaldiscountedcost", calcyears=[2025], continuoustransmission=true, 
            quiet = calculatescenario_quiet)

        if !compilation
            testqry = SQLite.DBInterface.execute(db, "select * from vtotaldiscountedcost") |> DataFrame
            @test testqry[1,:y] == "2025"

            @test isapprox(testqry[1,:val], 5727.36840492231; atol=TOL)
        end

        SQLite.DBInterface.execute(db, "update TransmissionModelingEnabled set type = 2")
        SQLite.DBInterface.execute(db, "update TransmissionLine set efficiency = null")

        # Test transmission line availability
        @info "Running Cbc test 5 on storage_transmission_test.sqlite: transmission line availability."
        SQLite.DBInterface.execute(db, "insert into TransmissionAvailabilityFactor values (null, 1, 'winterwe8', 2025, 0.2)")
        NemoMod.calculatescenario(dbfile; jumpmodel = Model(Cbc.Optimizer, add_bridges=reg_jumpmode), varstosave="vtransmissionbyline", calcyears=[2025], quiet = calculatescenario_quiet)

        if !compilation
            testqry = SQLite.DBInterface.execute(db, "select * from vtransmissionbyline where tr = 1 and l = 'winterwe8' and y = 2025") |> DataFrame
            @test abs(testqry[1,:val]) <= 50.0 + TOL
        end

        SQLite.DBInterface.execute(db, "delete from TransmissionAvailabilityFactor")

        # Delete test results and re-compact test database
        NemoMod.dropresulttables(db)
        testqry = SQLite.DBInterface.execute(db, "VACUUM")
    end  # "Solving storage_transmission_test with Cbc"

    @testset "Solving ramp_test with Cbc" begin
        dbfile = joinpath(@__DIR__, "ramp_test.sqlite")
        #dbfile = "c:/temp/ramp_test.sqlite"
        chmod(dbfile, 0o777)  # Make dbfile read-write. Necessary because after Julia 1.0, Pkg.add makes all package files read-only

        @info "Running Cbc test 1 on ramp_test.sqlite: default outputs."
        NemoMod.calculatescenario(dbfile; jumpmodel = JuMP.Model(Cbc.Optimizer, add_bridges=reg_jumpmode), quiet = calculatescenario_quiet)

        db = SQLite.DB(dbfile)

        if !compilation
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
            @test isapprox(testqry[6,:val], 1321.27499367017; atol=TOL)
            @test isapprox(testqry[7,:val], 1258.35713682873; atol=TOL)
            @test isapprox(testqry[8,:val], 1198.43536840832; atol=TOL)
            @test isapprox(testqry[9,:val], 1141.36701753173; atol=TOL)
            @test isapprox(testqry[10,:val], 1084.83029580609; atol=TOL)
        end

        # Delete test results and re-compact test database
        NemoMod.dropresulttables(db)
        testqry = SQLite.DBInterface.execute(db, "VACUUM")
    end  # "Solving ramp_test with Cbc"

    GC.gc()
end  # @isdefined Cbc
