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
        testnumber = 0  # Counter used in @info messages
        dbfile = joinpath(dbfile_path, "storage_test.sqlite")
        chmod(dbfile, 0o777)  # Make dbfile read-write. Necessary because after Julia 1.0, Pkg.add makes all package files read-only

        # Test with default outputs
        testnumber += 1
        @info "Running Cbc test $(testnumber) on storage_test.sqlite: default outputs."
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
        testnumber += 1
        @info "Running Cbc test $(testnumber) on storage_test.sqlite: optional outputs."
        NemoMod.calculatescenario(dbfile; jumpmodel = Model(optimizer_with_attributes(Cbc.Optimizer, "presolve" => "on", "logLevel" => 1), add_bridges=reg_jumpmode),
            varstosave =
                "vrateofdemand, vproductionbytechnology, vtotaltechnologyannualactivity, "
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
        testnumber += 1
        @info "Running Cbc test $(testnumber) on storage_test.sqlite: restrictvars."
        NemoMod.calculatescenario(dbfile; jumpmodel = Model(optimizer_with_attributes(Cbc.Optimizer, "presolve" => "on", "logLevel" => 1), add_bridges=reg_jumpmode),
            varstosave = "vproductionbytechnology, vusebytechnology, vtotaldiscountedcost",
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

        # Test with restrictvars and non time sliced fuels
        testnumber += 1
        @info "Running Cbc test $(testnumber) on storage_test.sqlite: restrictvars and non time sliced fuels."

        try
            SQLite.DBInterface.execute(db, "update FUEL set timesliced = 0 where val <> 'electricity'")

            NemoMod.calculatescenario(dbfile; jumpmodel = Model(optimizer_with_attributes(Cbc.Optimizer, "presolve" => "on", "logLevel" => 1), add_bridges=reg_jumpmode),
                varstosave = "vproductionbytechnology, vusebytechnology, vtotaldiscountedcost, vdemandannualnn, vdemandnn, vproductionbytechnology, vproductionnn, vrateofactivity, vrateofdemandnn, vrateofproduction, vrateofproductionbytechnologybymodenn, vrateofproductionbytechnologynn, vrateofproductionnn, vrateoftotalactivity, vrateofuse, vrateofusebytechnologybymodenn, vrateofusebytechnologynn, vrateofusenn, vtotalcapacityinreservemargin, vusebytechnology, vusenn", restrictvars = true, quiet = calculatescenario_quiet)

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

                @test isapprox(testqry[1,:val], 3845.15703585078; atol=TOL)
                @test isapprox(testqry[2,:val], 146.55231044248; atol=TOL)
                @test isapprox(testqry[3,:val], 139.573628992838; atol=TOL)
                @test isapprox(testqry[4,:val], 132.927265707465; atol=TOL)
                @test isapprox(testqry[5,:val], 126.597395911871; atol=TOL)
                @test isapprox(testqry[6,:val], 120.568948487496; atol=TOL)
                @test isapprox(testqry[7,:val], 114.827569869287; atol=TOL)
                @test isapprox(testqry[8,:val], 109.359590464849; atol=TOL)
                @test isapprox(testqry[9,:val], 104.151990918904; atol=TOL)
                @test isapprox(testqry[10,:val], 99.1923723037182; atol=TOL)
            end
        finally
            SQLite.DBInterface.execute(db, "update FUEL set timesliced = 1 where val <> 'electricity'")
        end

        # Test with storage net zero constraints
        testnumber += 1
        @info "Running Cbc test $(testnumber) on storage_test.sqlite: storage net zero constraints."

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
        testnumber += 1
        @info "Running Cbc test $(testnumber) on storage_test.sqlite: calcyears."
        NemoMod.calculatescenario(dbfile; jumpmodel = Model(optimizer_with_attributes(Cbc.Optimizer, "presolve" => "on", "logLevel" => 1), add_bridges=reg_jumpmode), restrictvars=true, calcyears=[2020,2029], quiet = calculatescenario_quiet)

        if !compilation
            testqry = SQLite.DBInterface.execute(db, "select * from vtotaldiscountedcost") |> DataFrame

            @test testqry[1,:y] == "2020"
            @test testqry[2,:y] == "2029"

            @test isapprox(testqry[1,:val], 3840.94023817782; atol=TOL)
            @test isapprox(testqry[2,:val], 3427.81584479179; atol=TOL)
        end

        # Test with calcyears and non time sliced fuels
        testnumber += 1
        @info "Running Cbc test $(testnumber) on storage_test.sqlite: calcyears and non time sliced fuels."

        try
            SQLite.DBInterface.execute(db, "update FUEL set timesliced = 0 where val <> 'electricity'")

            NemoMod.calculatescenario(dbfile; jumpmodel = Model(optimizer_with_attributes(Cbc.Optimizer, "presolve" => "on", "logLevel" => 1), add_bridges=reg_jumpmode),
                varstosave = "vproductionbytechnology, vusebytechnology, vtotaldiscountedcost, vdemandannualnn, vdemandnn, vproductionbytechnology, vproductionnn, vrateofactivity, vrateofdemandnn, vrateofproduction, vrateofproductionbytechnologybymodenn, vrateofproductionbytechnologynn, vrateofproductionnn, vrateoftotalactivity, vrateofuse, vrateofusebytechnologybymodenn, vrateofusebytechnologynn, vrateofusenn, vtotalcapacityinreservemargin, vusebytechnology, vusenn", restrictvars = true, calcyears=[2020,2029], quiet = calculatescenario_quiet)

            if !compilation
                testqry = SQLite.DBInterface.execute(db, "select * from vtotaldiscountedcost") |> DataFrame

                @test testqry[1,:y] == "2020"
                @test testqry[2,:y] == "2029"

                @test isapprox(testqry[1,:val], 3840.94023817782; atol=TOL)
                @test isapprox(testqry[2,:val], 3427.81584479179; atol=TOL)
            end
        finally
            SQLite.DBInterface.execute(db, "update FUEL set timesliced = 1 where val <> 'electricity'")
        end

        # Test MinimumUtilization
        testnumber += 1
        @info "Running Cbc test $(testnumber) on storage_test.sqlite: minimum utilization."
        
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
        testnumber = 0  # Counter used in @info messages
        dbfile = joinpath(dbfile_path, "storage_transmission_test.sqlite")
        chmod(dbfile, 0o777)  # Make dbfile read-write. Necessary because after Julia 1.0, Pkg.add makes all package files read-only

        # Test with default outputs
        testnumber += 1
        @info "Running Cbc test $(testnumber) on storage_transmission_test.sqlite: default outputs."
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

        # Test with non time sliced fuels
        testnumber += 1
        @info "Running Cbc test $(testnumber) on storage_transmission_test.sqlite: non time sliced fuels."
        try
            SQLite.DBInterface.execute(db, "update FUEL set timesliced = 0 where val <> 'electricity'")

            NemoMod.calculatescenario(dbfile; jumpmodel = JuMP.Model(Cbc.Optimizer, add_bridges=reg_jumpmode),
                varstosave =
                    "vdemandannualnn, vdemandnn, vproductionbytechnology, vproductionnn, vrateofactivity, vrateofdemandnn, vrateofproduction, vrateofproductionbytechnologybymodenn, vrateofproductionbytechnologynn, vrateofproductionnn, vrateoftotalactivity, vrateofuse, vrateofusebytechnologybymodenn, vrateofusebytechnologynn, vrateofusenn, vtotalcapacityinreservemargin, vusebytechnology, vusenn, vdemandannualnodal, vdemandnodal, vgenerationannualnodal, vproductionannualnodal, vproductionnodal, vrateofactivitynodal, vrateofproductionbytechnologynodal, vrateofproductionnodal, vrateoftotalactivitynodal, vrateofusebytechnologynodal, vrateofusenodal, vregenerationannualnodal, vuseannualnodal, vusenodal,
                    vnewcapacity, vtotalcapacityannual, vproductionbytechnologyannual, vusebytechnologyannual, vtotaldiscountedcost, vtransmissionbuilt, vtransmissionexists, vtransmissionbyline, vtransmissionannual",
                calcyears=[2020,2025], continuoustransmission=true, quiet = calculatescenario_quiet)

            if !compilation
                testqry = SQLite.DBInterface.execute(db, "select * from vtotaldiscountedcost") |> DataFrame

                @test testqry[1,:y] == "2020"
                @test testqry[2,:y] == "2025"

                @test isapprox(testqry[1,:val], 4568.83860468524; atol=TOL)
                @test isapprox(testqry[2,:val], 4726.36171732706; atol=TOL)
            end

        finally
            SQLite.DBInterface.execute(db, "update FUEL set timesliced = 1 where val <> 'electricity'")
        end

        # Test transshipment power flow
        testnumber += 1
        @info "Running Cbc test $(testnumber) on storage_transmission_test.sqlite: transshipment power flow."
        
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
        testnumber += 1
        @info "Running Cbc test $(testnumber) on storage_transmission_test.sqlite: limited foresight optimization."
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

        # Test limited foresight optimization with non time sliced fuels
        testnumber += 1
        @info "Running Cbc test $(testnumber) on storage_transmission_test.sqlite: limited foresight optimization with non time sliced fuels."

        try
            SQLite.DBInterface.execute(db, "update FUEL set timesliced = 0 where val <> 'electricity'")

            NemoMod.calculatescenario(dbfile; jumpmodel = Model(Cbc.Optimizer, add_bridges=reg_jumpmode), varstosave="vdemandannualnn, vdemandnn, vproductionbytechnology, vproductionnn, vrateofactivity, vrateofdemandnn, vrateofproduction, vrateofproductionbytechnologybymodenn, vrateofproductionbytechnologynn, vrateofproductionnn, vrateoftotalactivity, vrateofuse, vrateofusebytechnologybymodenn, vrateofusebytechnologynn, vrateofusenn, vtotalcapacityinreservemargin, vusebytechnology, vusenn, vdemandannualnodal, vdemandnodal, vgenerationannualnodal, vproductionannualnodal, vproductionnodal, vrateofactivitynodal, vrateofproductionbytechnologynodal, vrateofproductionnodal, vrateoftotalactivitynodal, vrateofusebytechnologynodal, vrateofusenodal, vregenerationannualnodal, vuseannualnodal, vusenodal, vnewcapacity, vtotalcapacityannual, vproductionbytechnologyannual, vusebytechnologyannual, vtotaldiscountedcost, vtransmissionbuilt, vtransmissionexists, vtransmissionbyline, vtransmissionannual", calcyears=[[2021,2022],[2025,2029]], continuoustransmission=true, quiet = calculatescenario_quiet)

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
        finally
            SQLite.DBInterface.execute(db, "update FUEL set timesliced = 1 where val <> 'electricity'")
        end

        # Test TransmissionAnnualMaxCapacityInvestment
        testnumber += 1
        @info "Running Cbc test $(testnumber) on storage_transmission_test.sqlite: TransmissionAnnualMaxCapacityInvestment."

        try
            SQLite.DBInterface.execute(db, "insert into TransmissionAnnualMaxCapacityInvestment values (null, 2, 2020, 250.0)")
            
            NemoMod.calculatescenario(dbfile; jumpmodel = JuMP.Model(Cbc.Optimizer, add_bridges=reg_jumpmode),
                varstosave =
                    "vdemandnn, vnewcapacity, vtotalcapacityannual, vproductionbytechnologyannual, vproductionnn, vusebytechnologyannual, vusenn, vtotaldiscountedcost, "
                    * "vtransmissionbuilt, vtransmissionexists, vtransmissionbyline, vtransmissionannual",
                calcyears=[2020,2025], continuoustransmission=true, quiet = calculatescenario_quiet)

            if !compilation
                testqry = SQLite.DBInterface.execute(db, "select * from vtransmissionbuilt order by y") |> DataFrame
                @test testqry[1,:y] == "2020"
                @test isapprox(testqry[1,:val], 0.5; atol=0.01)
            end
        finally
            SQLite.DBInterface.execute(db, "delete from TransmissionAnnualMaxCapacityInvestment")
        end

        # Delete test results and re-compact test database
        NemoMod.dropresulttables(db)
        testqry = SQLite.DBInterface.execute(db, "VACUUM")
    end  # "Solving storage_transmission_test with Cbc"

    @testset "Solving ramp_test with Cbc" begin
        testnumber = 0  # Counter used in @info messages
        dbfile = joinpath(dbfile_path, "ramp_test.sqlite")
        chmod(dbfile, 0o777)  # Make dbfile read-write. Necessary because after Julia 1.0, Pkg.add makes all package files read-only

        # Test with default outputs
        testnumber += 1
        @info "Running Cbc test $(testnumber) on ramp_test.sqlite: default outputs."
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

    @testset "Solving subsidy_test with Cbc" begin
        testnumber = 0  # Counter used in @info messages
        dbfile = joinpath(dbfile_path, "subsidy_test.sqlite")
        chmod(dbfile, 0o777)  # Make dbfile read-write. Necessary because after Julia 1.0, Pkg.add makes all package files read-only

        # Test with default outputs
        testnumber += 1
        @info "Running Cbc test $(testnumber) on subsidy_test.sqlite: default outputs."
        NemoMod.calculatescenario(dbfile; jumpmodel = JuMP.Model(Cbc.Optimizer, add_bridges=reg_jumpmode), quiet = calculatescenario_quiet, reportzeros=true)

        db = SQLite.DB(dbfile)

        if !compilation
            testqry = SQLite.DBInterface.execute(db, "select * from vproductionbytechnologyannual where f = 'electricity' and y in (2020, 2029) order by y, t") |> DataFrame

            @test testqry[1,:y] == "2020"
            @test testqry[2,:y] == "2020"
            @test testqry[3,:y] == "2020"
            @test testqry[4,:y] == "2020"
            @test testqry[5,:y] == "2029"
            @test testqry[6,:y] == "2029"
            @test testqry[7,:y] == "2029"
            @test testqry[8,:y] == "2029"

            @test testqry[1,:t] == "gas"
            @test testqry[2,:t] == "solar"
            @test testqry[3,:t] == "storage1"
            @test testqry[4,:t] == "wind"
            @test testqry[5,:t] == "gas"
            @test testqry[6,:t] == "solar"
            @test testqry[7,:t] == "storage1"
            @test testqry[8,:t] == "wind"            

            @test isapprox(testqry[1,:val], 1.13; atol=TOL)
            @test isapprox(testqry[2,:val], 34.10; atol=TOL)
            @test isapprox(testqry[3,:val], 14.64; atol=TOL)
            @test isapprox(testqry[4,:val], 0.0; atol=TOL)
            @test isapprox(testqry[5,:val], 0.0; atol=TOL)
            @test isapprox(testqry[6,:val], 35.45; atol=TOL)
            @test isapprox(testqry[7,:val], 15.77; atol=TOL)
            @test isapprox(testqry[8,:val], 0.0; atol=TOL)
        end

        # Test with subsidies
        testnumber += 1
        @info "Running Cbc test $(testnumber) on subsidy_test.sqlite: subsidies."

        try
            SQLite.DBInterface.execute(db, "insert into TechnologySubsidy select null, 1, 'wind', val, 3800.0 from year")

            NemoMod.calculatescenario(dbfile; jumpmodel = JuMP.Model(Cbc.Optimizer, add_bridges=reg_jumpmode), quiet = calculatescenario_quiet, reportzeros=true, varstosave="vproductionbytechnologyannual, vsubsidybyregion")

            if !compilation
                testqry = SQLite.DBInterface.execute(db, "select * from vproductionbytechnologyannual where f = 'electricity' and y in (2020, 2029) order by y, t") |> DataFrame

                @test testqry[1,:y] == "2020"
                @test testqry[2,:y] == "2020"
                @test testqry[3,:y] == "2020"
                @test testqry[4,:y] == "2020"
                @test testqry[5,:y] == "2029"
                @test testqry[6,:y] == "2029"
                @test testqry[7,:y] == "2029"
                @test testqry[8,:y] == "2029"

                @test testqry[1,:t] == "gas"
                @test testqry[2,:t] == "solar"
                @test testqry[3,:t] == "storage1"
                @test testqry[4,:t] == "wind"
                @test testqry[5,:t] == "gas"
                @test testqry[6,:t] == "solar"
                @test testqry[7,:t] == "storage1"
                @test testqry[8,:t] == "wind"            

                @test isapprox(testqry[1,:val], 0.0; atol=TOL)
                @test isapprox(testqry[2,:val], 0.0; atol=TOL)
                @test isapprox(testqry[3,:val], 1.21; atol=TOL)
                @test isapprox(testqry[4,:val], 31.84; atol=TOL)
                @test isapprox(testqry[5,:val], 0.0; atol=TOL)
                @test isapprox(testqry[6,:val], 0.0; atol=TOL)
                @test isapprox(testqry[7,:val], 1.21; atol=TOL)
                @test isapprox(testqry[8,:val], 31.84; atol=TOL)

                testqry = SQLite.DBInterface.execute(db, "select * from vsubsidybyregion where r = 1 and y = 2020") |> DataFrame
                @test isapprox(testqry[1,:val], 32270.65; atol=TOL)
            end

            SQLite.DBInterface.execute(db, "insert into MaxSubsidyPerTechnologyGroup select null, 1, 1, val, 30000.0 from year")

            NemoMod.calculatescenario(dbfile; jumpmodel = JuMP.Model(Cbc.Optimizer, add_bridges=reg_jumpmode), quiet = calculatescenario_quiet, reportzeros=true, varstosave="vproductionbytechnologyannual, vsubsidybyregion")

            if !compilation
                testqry = SQLite.DBInterface.execute(db, "select * from vsubsidybyregion where r = 1 and y = 2020") |> DataFrame
                @test isapprox(testqry[1,:val], 30000.00; atol=TOL)
            end
        finally
            SQLite.DBInterface.execute(db, "delete from TechnologySubsidy")
            SQLite.DBInterface.execute(db, "delete from MaxSubsidyPerTechnologyGroup")
        end

        # Delete test results and re-compact test database
        NemoMod.dropresulttables(db)
        testqry = SQLite.DBInterface.execute(db, "VACUUM")
    end  # "Solving subsidy_test with Cbc"

    GC.gc()
end  # @isdefined Cbc
