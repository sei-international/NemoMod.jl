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
        dbfile = joinpath(dbfile_path, "storage_test.sqlite")

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

        try
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
        finally
            SQLite.DBInterface.execute(db, "update STORAGE set netzeroyear = 0")
        end

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
        
        try
            SQLite.DBInterface.execute(db, "insert into MinimumUtilization select ROWID, '1', 'gas', val, 2025, 0.5 from TIMESLICE")
            NemoMod.calculatescenario(dbfile; jumpmodel = Model(Cbc.Optimizer, add_bridges=reg_jumpmode), varstosave="vproductionbytechnologyannual", quiet = calculatescenario_quiet)
    
            if !compilation
                testqry = SQLite.DBInterface.execute(db, "select * from vproductionbytechnologyannual where t = 'gas' and y = 2025") |> DataFrame
    
                @test isapprox(testqry[1,:val], 15.768; atol=TOL)
            end
        finally
            SQLite.DBInterface.execute(db, "delete from MinimumUtilization")
        end

        # Delete test results and re-compact test database
        NemoMod.dropresulttables(db)
        testqry = SQLite.DBInterface.execute(db, "VACUUM")
    end  # "Solving storage_test with Cbc"

    @testset "Solving storage_transmission_test with Cbc" begin
        dbfile = joinpath(dbfile_path, "storage_transmission_test.sqlite")
        chmod(dbfile, 0o777)  # Make dbfile read-write. Necessary because after Julia 1.0, Pkg.add makes all package files read-only

        @info "Running Cbc test 1 on storage_transmission_test.sqlite: default outputs."
        NemoMod.calculatescenario(dbfile; jumpmodel = JuMP.Model(Cbc.Optimizer, add_bridges=reg_jumpmode),
            varstosave =
                "vdemandnn, vnewcapacity, vtotalcapacityannual, vproductionbytechnologyannual, vproductionnn, vusebytechnologyannual, vusenn, vtotaldiscountedcost, "
                * "vtransmissionbuilt, vtransmissionexists, vtransmissionbyline, vtransmissionannual",
            calcyears=[2020,2025], continuoustransmission=true, quiet = calculatescenario_quiet)

        db = SQLite.DB(dbfile)

        if !compilation
            testqry = SQLite.DBInterface.execute(db, "select * from vtotaldiscountedcost") |> DataFrame

            @test testqry[1,:y] == "2020"
            @test testqry[2,:y] == "2025"

            @test isapprox(testqry[1,:val], 4568.83852603898; atol=TOL)
            @test isapprox(testqry[2,:val], 4726.36172102931; atol=TOL)
        end

        # Test transshipment power flow
        @info "Running Cbc test 2 on storage_transmission_test.sqlite: transshipment power flow."
        
        try
            SQLite.DBInterface.execute(db, "update TransmissionModelingEnabled set type = 3")
            NemoMod.calculatescenario(dbfile; jumpmodel = Model(Cbc.Optimizer, add_bridges=reg_jumpmode), varstosave="vtotaldiscountedcost", calcyears=[2020,2025,2029], continuoustransmission=true, quiet = calculatescenario_quiet)
    
            if !compilation
                testqry = SQLite.DBInterface.execute(db, "select * from vtotaldiscountedcost") |> DataFrame
                @test testqry[1,:y] == "2020"
                @test testqry[2,:y] == "2025"
                @test testqry[3,:y] == "2029"
    
                @test isapprox(testqry[1,:val], 4303.25529142096; atol=TOL)
                @test isapprox(testqry[2,:val], 2720.73287425466; atol=TOL)
                @test isapprox(testqry[3,:val], 1745.96958622336; atol=TOL)
            end
        finally
            SQLite.DBInterface.execute(db, "update TransmissionModelingEnabled set type = 2")
        end

        # Test limited foresight optimization
        @info "Running Cbc test 3 on storage_transmission_test.sqlite: limited foresight optimization."
        NemoMod.calculatescenario(dbfile; jumpmodel = Model(Cbc.Optimizer, add_bridges=reg_jumpmode), varstosave="vtotaldiscountedcost", calcyears=[[2021,2022],[2025,2029]], continuoustransmission=true, quiet = calculatescenario_quiet)

        if !compilation
            testqry = SQLite.DBInterface.execute(db, "select * from vtotaldiscountedcost") |> DataFrame
            @test testqry[1,:y] == "2021"
            @test testqry[2,:y] == "2022"
            @test testqry[3,:y] == "2025"
            @test testqry[4,:y] == "2029"

            @test isapprox(testqry[1,:val], 4846.62588143849; atol=TOL)
            @test isapprox(testqry[2,:val], 305.484279868528; atol=TOL)
            @test isapprox(testqry[3,:val], 1363.8650852295; atol=TOL)
            @test isapprox(testqry[4,:val], 1848.0889114236; atol=TOL)
        end

        # Delete test results and re-compact test database
        NemoMod.dropresulttables(db)
        testqry = SQLite.DBInterface.execute(db, "VACUUM")
    end  # "Solving storage_transmission_test with Cbc"

    @testset "Solving ramp_test with Cbc" begin
        dbfile = joinpath(dbfile_path, "ramp_test.sqlite")
        chmod(dbfile, 0o777)  # Make dbfile read-write. Necessary because after Julia 1.0, Pkg.add makes all package files read-only

        @info "Running Cbc test 1 on ramp_test.sqlite: default outputs."
        NemoMod.calculatescenario(dbfile; jumpmodel = JuMP.Model(Cbc.Optimizer, add_bridges=reg_jumpmode), calcyears=[2020,2025,2029], quiet = calculatescenario_quiet)

        db = SQLite.DB(dbfile)

        if !compilation
            testqry = SQLite.DBInterface.execute(db, "select * from vtotaldiscountedcost") |> DataFrame

            @test testqry[1,:y] == "2020"
            @test testqry[2,:y] == "2025"
            @test testqry[3,:y] == "2029"

            @test isapprox(testqry[1,:val], 4298.58260191924; atol=TOL)
            @test isapprox(testqry[2,:val], 7353.02752280618; atol=TOL)
            @test isapprox(testqry[3,:val], 4718.4125358277; atol=TOL)
        end

        # Delete test results and re-compact test database
        NemoMod.dropresulttables(db)
        testqry = SQLite.DBInterface.execute(db, "VACUUM")
    end  # "Solving ramp_test with Cbc"

    GC.gc()
end  # @isdefined Cbc
