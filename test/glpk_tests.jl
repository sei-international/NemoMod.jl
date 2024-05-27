#=
    NEMO: Next Energy Modeling system for Optimization.
    https://github.com/sei-international/NemoMod.jl

    Copyright © 2019: Stockholm Environment Institute U.S.

	File description: Tests of NemoMod package using GLPK solver.
=#

try
    using GLPK
catch e
    @info "Error when initializing GLPK. Error message: " * sprint(showerror, e) * "."
    @info "Skipping GLPK tests."
    # Continue
end

# Tests will be skipped if GLPK package is not installed.
if @isdefined GLPK
    @info "Testing scenario solution with GLPK."

    @testset "Solving storage_test with GLPK" begin
        dbfile = joinpath(@__DIR__, "storage_test.sqlite")
        #dbfile = "c:/temp/storage_test.sqlite"
        chmod(dbfile, 0o777)  # Make dbfile read-write. Necessary because after Julia 1.0, Pkg.add makes all package files read-only

        # Test with default outputs
        @info "Running GLPK test 1 on storage_test.sqlite: default outputs."
        NemoMod.calculatescenario(dbfile; jumpmodel=(reg_jumpmode ? Model(optimizer_with_attributes(GLPK.Optimizer, "presolve" => true)) : direct_model(optimizer_with_attributes(GLPK.Optimizer, "presolve" => true))), restrictvars=true, quiet = calculatescenario_quiet)

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
        @info "Running GLPK test 2 on storage_test.sqlite: optional outputs."
        NemoMod.calculatescenario(dbfile; jumpmodel=(reg_jumpmode ? Model(optimizer_with_attributes(GLPK.Optimizer, "presolve" => true)) : direct_model(optimizer_with_attributes(GLPK.Optimizer, "presolve" => true))),
            varstosave = "vrateofproductionbytechnologybymode, vrateofusebytechnologybymode, vrateofdemand, vproductionbytechnology, vtotaltechnologyannualactivity, "
            * "vtotaltechnologymodelperiodactivity, vusebytechnology, vmodelperiodcostbyregion, vannualtechnologyemissionpenaltybyemission, "
            * "vtotaldiscountedcost", restrictvars=true, quiet = calculatescenario_quiet)

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
        @info "Running GLPK test 3 on storage_test.sqlite: restrictvars."
        NemoMod.calculatescenario(dbfile; jumpmodel=(reg_jumpmode ? Model(optimizer_with_attributes(GLPK.Optimizer, "presolve" => true)) : direct_model(optimizer_with_attributes(GLPK.Optimizer, "presolve" => true))),
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
        @info "Running GLPK test 4 on storage_test.sqlite: storage net zero constraints."
        SQLite.DBInterface.execute(db, "update STORAGE set netzeroyear = 1")
        NemoMod.calculatescenario(dbfile; jumpmodel=(reg_jumpmode ? Model(optimizer_with_attributes(GLPK.Optimizer, "presolve" => true)) : direct_model(optimizer_with_attributes(GLPK.Optimizer, "presolve" => true))), restrictvars=false, quiet = calculatescenario_quiet)

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
        end

        SQLite.DBInterface.execute(db, "update STORAGE set netzeroyear = 0")

        # Test with calcyears
        @info "Running GLPK test 5 on storage_test.sqlite: calcyears."
        NemoMod.calculatescenario(dbfile; jumpmodel = (reg_jumpmode ? Model(optimizer_with_attributes(GLPK.Optimizer, "presolve" => true)) : direct_model(optimizer_with_attributes(GLPK.Optimizer, "presolve" => true))), restrictvars=true, calcyears=[2020,2029], quiet = calculatescenario_quiet)

        if !compilation
            testqry = SQLite.DBInterface.execute(db, "select * from vtotaldiscountedcost") |> DataFrame

            @test testqry[1,:y] == "2020"
            @test testqry[2,:y] == "2029"

            @test isapprox(testqry[1,:val], 3840.94023817782; atol=TOL)
            @test isapprox(testqry[2,:val], 3427.81584479179; atol=TOL)
        end

        # Test MinimumUtilization
        @info "Running GLPK test 6 on storage_test.sqlite: minimum utilization."
        SQLite.DBInterface.execute(db, "insert into MinimumUtilization select ROWID, '1', 'gas', val, 2025, 0.5 from TIMESLICE")
        NemoMod.calculatescenario(dbfile; jumpmodel = (reg_jumpmode ? Model(optimizer_with_attributes(GLPK.Optimizer, "presolve" => true)) : direct_model(optimizer_with_attributes(GLPK.Optimizer, "presolve" => true))), varstosave="vproductionbytechnologyannual", quiet = calculatescenario_quiet)

        if !compilation
            testqry = SQLite.DBInterface.execute(db, "select * from vproductionbytechnologyannual where t = 'gas' and y = 2025") |> DataFrame

            @test isapprox(testqry[1,:val], 15.768; atol=TOL)
        end

        SQLite.DBInterface.execute(db, "delete from MinimumUtilization")

        # Delete test results and re-compact test database
        NemoMod.dropresulttables(db)
        testqry = SQLite.DBInterface.execute(db, "VACUUM")
    end  # "Solving storage_test with GLPK"

    @testset "Solving storage_transmission_test with GLPK" begin
        dbfile = joinpath(@__DIR__, "storage_transmission_test.sqlite")
        #dbfile = "c:/temp/storage_transmission_test.sqlite"
        chmod(dbfile, 0o777)  # Make dbfile read-write. Necessary because after Julia 1.0, Pkg.add makes all package files read-only

        @info "Running GLPK test 1 on storage_transmission_test.sqlite: default outputs."
        NemoMod.calculatescenario(dbfile; jumpmodel=(reg_jumpmode ? Model(optimizer_with_attributes(GLPK.Optimizer, "presolve" => true)) : direct_model(optimizer_with_attributes(GLPK.Optimizer, "presolve" => true))),
            varstosave = "vdemandnn, vnewcapacity, vtotalcapacityannual, vproductionbytechnologyannual, vproductionnn, vusebytechnologyannual, vusenn, vtotaldiscountedcost, "
                * "vtransmissionbuilt, vtransmissionexists, vtransmissionbyline, vtransmissionannual",
            restrictvars=true, calcyears=[2020,2025,2029], quiet = calculatescenario_quiet)

        db = SQLite.DB(dbfile)

        if !compilation
            testqry = SQLite.DBInterface.execute(db, "select * from vtotaldiscountedcost") |> DataFrame

            @test testqry[1,:y] == "2020"
            @test testqry[2,:y] == "2025"
            @test testqry[3,:y] == "2029"

            @test isapprox(testqry[1,:val], 9774.87377127422; atol=TOL)
            @test isapprox(testqry[2,:val], 2510.44571676115; atol=TOL)
            @test isapprox(testqry[3,:val], 1611.02249720726; atol=TOL)
        end

        # Test transshipment power flow
        @info "Running GLPK test 2 on storage_transmission_test.sqlite: transshipment power flow."
        SQLite.DBInterface.execute(db, "update TransmissionModelingEnabled set type = 3")
        NemoMod.calculatescenario(dbfile; jumpmodel = (reg_jumpmode ? Model(optimizer_with_attributes(GLPK.Optimizer, "presolve" => true)) : direct_model(optimizer_with_attributes(GLPK.Optimizer, "presolve" => true))), varstosave="vtotaldiscountedcost", calcyears=[2020,2025], continuoustransmission=true, quiet = calculatescenario_quiet)

        if !compilation
            testqry = SQLite.DBInterface.execute(db, "select * from vtotaldiscountedcost") |> DataFrame
            @test testqry[1,:y] == "2020"
            @test testqry[2,:y] == "2025"

            @test isapprox(testqry[1,:val], 4302.73264852276; atol=TOL)
            @test isapprox(testqry[2,:val], 2721.12570685235; atol=TOL)
        end

        SQLite.DBInterface.execute(db, "update TransmissionModelingEnabled set type = 2")

        # Delete test results and re-compact test database
        NemoMod.dropresulttables(db)
        testqry = SQLite.DBInterface.execute(db, "VACUUM")
    end  # "Solving storage_transmission_test with GLPK"

    GC.gc()
end  # @isdefined GLPK
