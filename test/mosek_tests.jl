#=
    NEMO: Next Energy Modeling system for Optimization.
    https://github.com/sei-international/NemoMod.jl

    Copyright © 2019: Stockholm Environment Institute U.S.

	File description: Tests of NemoMod package using Mosek solver.
=#

try
    using MosekTools
catch e
    @info "Error when initializing Mosek. Error message: " * sprint(showerror, e) * "."
    @info "Skipping Mosek tests."
end

# Tests will be skipped if MosekTools package is not installed.
# Note: As of Mosek 9.3, Mosek does not seem to produce reliable results with NEMO unless forcemip=true
# Note: Mosek's performance in JuMP direct mode is spotty; thus reg_jumpmode is not used in these tests
if @isdefined MosekTools
    @info "Testing scenario solution with Mosek."

    @testset "Solving storage_test with Mosek" begin
        testnumber = 0  # Counter used in @info messages
        dbfile = joinpath(dbfile_path, "storage_test.sqlite")
        chmod(dbfile, 0o777)  # Make dbfile read-write. Necessary because after Julia 1.0, Pkg.add makes all package files read-only

        # Test with default outputs
        testnumber += 1
        @info "Running Mosek test $(testnumber) on storage_test.sqlite: default outputs."
        NemoMod.calculatescenario(dbfile; jumpmodel = Model(Mosek.Optimizer), restrictvars=false, forcemip=true, quiet = calculatescenario_quiet)

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
        end

        # Test with optional outputs
        testnumber += 1
        @info "Running Mosek test $(testnumber) on storage_test.sqlite: optional outputs."
        NemoMod.calculatescenario(dbfile; jumpmodel = Model(Mosek.Optimizer),
            varstosave =
                "vrateofproductionbytechnologybymode, vrateofusebytechnologybymode, vrateofdemand, vproductionbytechnology, vtotaltechnologyannualactivity, "
                * "vtotaltechnologymodelperiodactivity, vusebytechnology, vmodelperiodcostbyregion, vannualtechnologyemissionpenaltybyemission, "
                * "vtotaldiscountedcost",
            restrictvars=false, forcemip=true, quiet = calculatescenario_quiet)

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
        end

        # Test with restrictvars
        testnumber += 1
        @info "Running Mosek test $(testnumber) on storage_test.sqlite: restrictvars."
        NemoMod.calculatescenario(dbfile; jumpmodel = Model(Mosek.Optimizer),
            varstosave = "vrateofproductionbytechnologybymode, vrateofusebytechnologybymode, vproductionbytechnology, vusebytechnology, "
                * "vtotaldiscountedcost",
            restrictvars = true, forcemip=true, quiet = calculatescenario_quiet)

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
        end

        # Test with restrictvars and non time sliced fuels
        testnumber += 1
        @info "Running Mosek test $(testnumber) on storage_test.sqlite: restrictvars and non time sliced fuels."

        try
            SQLite.DBInterface.execute(db, "update FUEL set timesliced = 0 where val <> 'electricity'")

            NemoMod.calculatescenario(dbfile; jumpmodel = Model(Mosek.Optimizer),
                varstosave = "vproductionbytechnology, vusebytechnology, vtotaldiscountedcost, vdemandannualnn, vdemandnn, vproductionbytechnology, vproductionnn, vrateofactivity, vrateofdemandnn, vrateofproduction, vrateofproductionbytechnologybymodenn, vrateofproductionbytechnologynn, vrateofproductionnn, vrateoftotalactivity, vrateofuse, vrateofusebytechnologybymodenn, vrateofusebytechnologynn, vrateofusenn, vtotalcapacityinreservemargin, vusebytechnology, vusenn", restrictvars = true, forcemip = true,quiet = calculatescenario_quiet)

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
        @info "Running Mosek test $(testnumber) on storage_test.sqlite: storage net zero constraints."

        try
            SQLite.DBInterface.execute(db, "update STORAGE set netzeroyear = 1")
            NemoMod.calculatescenario(dbfile; jumpmodel = Model(Mosek.Optimizer), restrictvars=false, quiet = calculatescenario_quiet)
    
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
    
                @test isapprox(testqry[1,:val], 3840.94023817785; atol=TOL)
                @test isapprox(testqry[2,:val], 459.294938424824; atol=TOL)
                @test isapprox(testqry[3,:val], 437.423750880721; atol=TOL)
                @test isapprox(testqry[4,:val], 416.59194032216; atol=TOL)
                @test isapprox(testqry[5,:val], 396.756236626635; atol=TOL)
                @test isapprox(testqry[6,:val], 377.863082501456; atol=TOL)
                @test isapprox(testqry[7,:val], 359.869602382347; atol=TOL)
                @test isapprox(testqry[8,:val], 342.732954649844; atol=TOL)
                @test isapprox(testqry[9,:val], 326.412337761761; atol=TOL)
                @test isapprox(testqry[10,:val], 310.868893106428; atol=TOL)
            end
        finally
            SQLite.DBInterface.execute(db, "update STORAGE set netzeroyear = 0")        
        end

        # Test with calcyears
        testnumber += 1
        @info "Running Mosek test $(testnumber) on storage_test.sqlite: calcyears."
        NemoMod.calculatescenario(dbfile; jumpmodel = Model(Mosek.Optimizer), restrictvars=true, forcemip=true,
            calcyears=[2020,2029], quiet = calculatescenario_quiet)

        if !compilation
            testqry = SQLite.DBInterface.execute(db, "select * from vtotaldiscountedcost") |> DataFrame

            @test testqry[1,:y] == "2020"
            @test testqry[2,:y] == "2029"

            @test isapprox(testqry[1,:val], 3840.93779774689; atol=TOL)
            @test isapprox(testqry[2,:val], 3427.79849864389; atol=TOL)
        end

        # Test with calcyears and non time sliced fuels
        testnumber += 1
        @info "Running Mosek test $(testnumber) on storage_test.sqlite: calcyears and non time sliced fuels."

        try
            SQLite.DBInterface.execute(db, "update FUEL set timesliced = 0 where val <> 'electricity'")

            NemoMod.calculatescenario(dbfile; jumpmodel = Model(Mosek.Optimizer), varstosave = "vproductionbytechnology, vusebytechnology, vtotaldiscountedcost, vdemandannualnn, vdemandnn, vproductionbytechnology, vproductionnn, vrateofactivity, vrateofdemandnn, vrateofproduction, vrateofproductionbytechnologybymodenn, vrateofproductionbytechnologynn, vrateofproductionnn, vrateoftotalactivity, vrateofuse, vrateofusebytechnologybymodenn, vrateofusebytechnologynn, vrateofusenn, vtotalcapacityinreservemargin, vusebytechnology, vusenn", restrictvars=true, forcemip=true, calcyears=[2020,2029], quiet = calculatescenario_quiet)

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
        @info "Running Mosek test $(testnumber) on storage_test.sqlite: minimum utilization."

        try
            SQLite.DBInterface.execute(db, "insert into MinimumUtilization select ROWID, '1', 'gas', val, 2025, 0.5 from TIMESLICE")
            NemoMod.calculatescenario(dbfile; jumpmodel = Model(Mosek.Optimizer), varstosave="vproductionbytechnologyannual", forcemip=true, quiet = calculatescenario_quiet)
    
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
    end  # "Solving storage_test with Mosek"

    @testset "Solving storage_transmission_test with Mosek" begin
        testnumber = 0  # Counter used in @info messages
        dbfile = joinpath(dbfile_path, "storage_transmission_test.sqlite")
        chmod(dbfile, 0o777)  # Make dbfile read-write. Necessary because after Julia 1.0, Pkg.add makes all package files read-only

        # Test with default outputs
        testnumber += 1
        @info "Running Mosek test $(testnumber) on storage_transmission_test.sqlite: default outputs."
        NemoMod.calculatescenario(dbfile; jumpmodel = Model(Mosek.Optimizer),
            varstosave =
                "vdemandnn, vnewcapacity, vtotalcapacityannual, vproductionbytechnologyannual, vproductionnn, vusebytechnologyannual, vusenn, vtotaldiscountedcost, "
                * "vtransmissionbuilt, vtransmissionexists, vtransmissionbyline, vtransmissionannual",
            quiet = calculatescenario_quiet)

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
        end

        # Test with non time sliced fuels
        testnumber += 1
        @info "Running Mosek test $(testnumber) on storage_transmission_test.sqlite: non time sliced fuels."

        try
            SQLite.DBInterface.execute(db, "update FUEL set timesliced = 0 where val <> 'electricity'")

            NemoMod.calculatescenario(dbfile; jumpmodel = Model(Mosek.Optimizer),
                varstosave = "vdemandannualnn, vdemandnn, vproductionbytechnology, vproductionnn, vrateofactivity, vrateofdemandnn, vrateofproduction, vrateofproductionbytechnologybymodenn, vrateofproductionbytechnologynn, vrateofproductionnn, vrateoftotalactivity, vrateofuse, vrateofusebytechnologybymodenn, vrateofusebytechnologynn, vrateofusenn, vtotalcapacityinreservemargin, vusebytechnology, vusenn, vdemandannualnodal, vdemandnodal, vgenerationannualnodal, vproductionannualnodal, vproductionnodal, vrateofactivitynodal, vrateofproductionbytechnologynodal, vrateofproductionnodal, vrateoftotalactivitynodal, vrateofusebytechnologynodal, vrateofusenodal, vregenerationannualnodal, vuseannualnodal, vusenodal, vnewcapacity, vtotalcapacityannual, vproductionbytechnologyannual, vusebytechnologyannual, vtotaldiscountedcost, vtransmissionbuilt, vtransmissionexists, vtransmissionbyline, vtransmissionannual",
                quiet = calculatescenario_quiet)

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

                @test isapprox(testqry[1,:val], 9786.56626042587; atol=TOL)
                @test isapprox(testqry[2,:val], 239.495064739257; atol=TOL)
                @test isapprox(testqry[3,:val], 228.090641826873; atol=TOL)
                @test isapprox(testqry[4,:val], 217.229273833058; atol=TOL)
                @test isapprox(testqry[5,:val], 206.884786725342; atol=TOL)
                @test isapprox(testqry[6,:val], 197.033272788862; atol=TOL)
                @test isapprox(testqry[7,:val], 187.650830607229; atol=TOL)
                @test isapprox(testqry[8,:val], 178.714951753762; atol=TOL)
                @test isapprox(testqry[9,:val], 170.204748803116; atol=TOL)
                @test isapprox(testqry[10,:val], 162.099761418328; atol=TOL)
            end
        finally
            SQLite.DBInterface.execute(db, "update FUEL set timesliced = 1 where val <> 'electricity'")
        end

        # Test MinimumUtilization
        testnumber += 1
        @info "Running Mosek test $(testnumber) on storage_transmission_test.sqlite: minimum utilization."

        try
            SQLite.DBInterface.execute(db, "insert into MinimumUtilization select ROWID, '1', 'gas', val, 2025, 0.2 from TIMESLICE")
            NemoMod.calculatescenario(dbfile; jumpmodel = Model(Mosek.Optimizer), varstosave="vproductionbytechnologyannual", calcyears=[2020,2025,2029], quiet = calculatescenario_quiet)
    
            if !compilation
                testqry = SQLite.DBInterface.execute(db, "select * from vproductionbytechnologyannual where t = 'gas' and y = 2025") |> DataFrame
    
                @test isapprox(testqry[1,:val], 16.3149963697108; atol=TOL)
            end
        finally
            SQLite.DBInterface.execute(db, "delete from MinimumUtilization")
        end

        # Test interest rates
        testnumber += 1
        @info "Running Mosek test $(testnumber) on storage_transmission_test.sqlite: interest rates."

        try
            SQLite.DBInterface.execute(db, "insert into InterestRateStorage select rowid, 1, 'storage1', y.val, 0.05 from year y")
            SQLite.DBInterface.execute(db, "insert into InterestRateTechnology select rowid, 1, 'solar', y.val, 0.05 from year y")
            SQLite.DBInterface.execute(db, "update TransmissionLine set interestrate = 0.05 where id = 2")
            NemoMod.calculatescenario(dbfile; jumpmodel = Model(Mosek.Optimizer), varstosave="vtotaldiscountedcost", calcyears=[2020,2025,2029], quiet = calculatescenario_quiet)
    
            if !compilation
                testqry = SQLite.DBInterface.execute(db, "select * from vtotaldiscountedcost") |> DataFrame
    
                @test testqry[1,:y] == "2020"
                @test testqry[2,:y] == "2025"
                @test testqry[3,:y] == "2029"
    
                @test isapprox(testqry[1,:val], 12672.8114730171; atol=TOL)
                @test isapprox(testqry[2,:val], 2510.44589185654; atol=TOL)
                @test isapprox(testqry[3,:val], 1611.02255483292; atol=TOL)
            end
        finally
            SQLite.DBInterface.execute(db, "delete from InterestRateStorage")
            SQLite.DBInterface.execute(db, "delete from InterestRateTechnology")
            SQLite.DBInterface.execute(db, "update TransmissionLine set interestrate = null where id = 2")
        end

        # Test transshipment power flow
        testnumber += 1
        @info "Running Mosek test $(testnumber) on storage_transmission_test.sqlite: transshipment power flow."

        try
            SQLite.DBInterface.execute(db, "update TransmissionModelingEnabled set type = 3")
            SQLite.DBInterface.execute(db, "update TransmissionLine set efficiency = 1.0")
            NemoMod.calculatescenario(dbfile; jumpmodel = Model(Mosek.Optimizer), varstosave="vtotaldiscountedcost", calcyears=[2020,2025,2029], quiet = calculatescenario_quiet)
    
            if !compilation
                testqry = SQLite.DBInterface.execute(db, "select * from vtotaldiscountedcost") |> DataFrame
    
                @test testqry[1,:y] == "2020"
                @test testqry[2,:y] == "2025"
                @test testqry[3,:y] == "2029"
    
                @test isapprox(testqry[1,:val], 4649.69110419447; atol=TOL)
                @test isapprox(testqry[2,:val], 2932.95931815835; atol=TOL)
                @test isapprox(testqry[3,:val], 1882.16116899065; atol=TOL)
            end
        finally
            SQLite.DBInterface.execute(db, "update TransmissionModelingEnabled set type = 2")
            SQLite.DBInterface.execute(db, "update TransmissionLine set efficiency = null")
        end

        # Test transmission line availability
        testnumber += 1
        @info "Running Mosek test $(testnumber) on storage_transmission_test.sqlite: transmission line availability."

        try
            SQLite.DBInterface.execute(db, "insert into TransmissionAvailabilityFactor values (null, 1, 'winterwe8', 2025, 0.2)")
            NemoMod.calculatescenario(dbfile; jumpmodel = Model(Mosek.Optimizer), varstosave="vtransmissionbyline", calcyears=[2020,2025,2029], quiet = calculatescenario_quiet)
    
            if !compilation
                testqry = SQLite.DBInterface.execute(db, "select * from vtransmissionbyline where tr = 1 and l = 'winterwe8' and y = 2025") |> DataFrame
                @test abs(testqry[1,:val]) <= 50.0 + TOL
            end
        finally
            SQLite.DBInterface.execute(db, "delete from TransmissionAvailabilityFactor")
        end

        # Test limited foresight optimization
        testnumber += 1
        @info "Running Mosek test $(testnumber) on storage_transmission_test.sqlite: limited foresight optimization."
        NemoMod.calculatescenario(dbfile; jumpmodel = Model(Mosek.Optimizer), varstosave="vtotaldiscountedcost", calcyears=[[2021,2022],[2025,2029]], continuoustransmission = true, quiet = calculatescenario_quiet)

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
        @info "Running Mosek test $(testnumber) on storage_transmission_test.sqlite: limited foresight optimization with non time sliced fuels."

        try
            SQLite.DBInterface.execute(db, "update FUEL set timesliced = 0 where val <> 'electricity'")

            NemoMod.calculatescenario(dbfile; jumpmodel = Model(Mosek.Optimizer), varstosave="vdemandannualnn, vdemandnn, vproductionbytechnology, vproductionnn, vrateofactivity, vrateofdemandnn, vrateofproduction, vrateofproductionbytechnologybymodenn, vrateofproductionbytechnologynn, vrateofproductionnn, vrateoftotalactivity, vrateofuse, vrateofusebytechnologybymodenn, vrateofusebytechnologynn, vrateofusenn, vtotalcapacityinreservemargin, vusebytechnology, vusenn, vdemandannualnodal, vdemandnodal, vgenerationannualnodal, vproductionannualnodal, vproductionnodal, vrateofactivitynodal, vrateofproductionbytechnologynodal, vrateofproductionnodal, vrateoftotalactivitynodal, vrateofusebytechnologynodal, vrateofusenodal, vregenerationannualnodal, vuseannualnodal, vusenodal, vnewcapacity, vtotalcapacityannual, vproductionbytechnologyannual, vusebytechnologyannual, vtotaldiscountedcost, vtransmissionbuilt, vtransmissionexists, vtransmissionbyline, vtransmissionannual", calcyears=[[2021,2022],[2025,2029]], continuoustransmission = true, quiet = calculatescenario_quiet)

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
        @info "Running Mosek test $(testnumber) on storage_transmission_test.sqlite: TransmissionAnnualMaxCapacityInvestment."

        try
            SQLite.DBInterface.execute(db, "insert into TransmissionAnnualMaxCapacityInvestment values (null, 2, 2020, 250.0)")
            
            NemoMod.calculatescenario(dbfile; jumpmodel = Model(Mosek.Optimizer),
                varstosave =
                    "vdemandnn, vnewcapacity, vtotalcapacityannual, vproductionbytechnologyannual, vproductionnn, vusebytechnologyannual, vusenn, vtotaldiscountedcost, "
                    * "vtransmissionbuilt, vtransmissionexists, vtransmissionbyline, vtransmissionannual",
                continuoustransmission=true, quiet = calculatescenario_quiet)

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
    end  # "Solving storage_transmission_test with Mosek"

    @testset "Solving ramp_test with Mosek" begin
        testnumber = 0  # Counter used in @info messages
        dbfile = joinpath(dbfile_path, "ramp_test.sqlite")
        chmod(dbfile, 0o777)  # Make dbfile read-write. Necessary because after Julia 1.0, Pkg.add makes all package files read-only

        # Test with default outputs
        testnumber += 1
        @info "Running Mosek test $(testnumber) on ramp_test.sqlite: default outputs."
        NemoMod.calculatescenario(dbfile; jumpmodel = Model(Mosek.Optimizer), restrictvars=false, forcemip=true, quiet = calculatescenario_quiet)

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
            @test isapprox(testqry[6,:val], 1321.27164305297; atol=TOL)
            @test isapprox(testqry[7,:val], 1258.35996962756; atol=TOL)
            @test isapprox(testqry[8,:val], 1198.44067149609; atol=TOL)
            @test isapprox(testqry[9,:val], 1141.373808485; atol=TOL)
            @test isapprox(testqry[10,:val], 1084.83956451882; atol=TOL)
        end

        # Delete test results and re-compact test database
        NemoMod.dropresulttables(db)
        testqry = SQLite.DBInterface.execute(db, "VACUUM")
    end  # "Solving ramp_test with Mosek"

    @testset "Solving subsidy_test with Mosek" begin
        testnumber = 0  # Counter used in @info messages
        dbfile = joinpath(dbfile_path, "subsidy_test.sqlite")
        chmod(dbfile, 0o777)  # Make dbfile read-write. Necessary because after Julia 1.0, Pkg.add makes all package files read-only

        # Test with default outputs
        testnumber += 1
        @info "Running Mosek test $(testnumber) on subsidy_test.sqlite: default outputs."
        NemoMod.calculatescenario(dbfile; jumpmodel = Model(Mosek.Optimizer), quiet = calculatescenario_quiet, reportzeros=true)

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
        @info "Running Mosek test $(testnumber) on subsidy_test.sqlite: subsidies."

        try
            SQLite.DBInterface.execute(db, "insert into TechnologySubsidy select null, 1, 'wind', val, 3800.0 from year")

            NemoMod.calculatescenario(dbfile; jumpmodel = Model(Mosek.Optimizer), quiet = calculatescenario_quiet, reportzeros=true, varstosave="vproductionbytechnologyannual, vsubsidybyregion")
            
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

            NemoMod.calculatescenario(dbfile; jumpmodel = Model(Mosek.Optimizer), quiet = calculatescenario_quiet, reportzeros=true, varstosave="vproductionbytechnologyannual, vsubsidybyregion")

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
    end  # "Solving subsidy_test with Mosek"

    GC.gc()
end  # @isdefined MosekTools
