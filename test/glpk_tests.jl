#=
    NEMO: Next Energy Modeling system for Optimization.
    https://github.com/sei-international/NemoMod.jl

    Copyright © 2019: Stockholm Environment Institute U.S.

	File description: Tests of NemoMod package using GLPK solver.
=#

function glpk_tests(compilation::Bool=false)
    # Tests will be skipped if GLPK package is not installed.
    if @isdefined GLPK
        @info "Testing scenario solution with GLPK."

        @testset "Solving storage_test with GLPK" begin
            dbfile = joinpath(@__DIR__, "storage_test.sqlite")
            #dbfile = "c:/temp/storage_test.sqlite"
            chmod(dbfile, 0o777)  # Make dbfile read-write. Necessary because after Julia 1.0, Pkg.add makes all package files read-only

            # Test with default outputs
            NemoMod.calculatescenario(dbfile; jumpmodel=Model(optimizer_with_attributes(GLPK.Optimizer, "presolve" => true)), restrictvars=true, quiet = false)

            db = SQLite.DB(dbfile)
            testqry = SQLite.DBInterface.execute(db, "select * from vtotaldiscountedcost") |> DataFrame

            !compilation && @test testqry[1,:y] == "2020"
            !compilation && @test testqry[2,:y] == "2021"
            !compilation && @test testqry[3,:y] == "2022"
            !compilation && @test testqry[4,:y] == "2023"
            !compilation && @test testqry[5,:y] == "2024"
            !compilation && @test testqry[6,:y] == "2025"
            !compilation && @test testqry[7,:y] == "2026"
            !compilation && @test testqry[8,:y] == "2027"
            !compilation && @test testqry[9,:y] == "2028"
            !compilation && @test testqry[10,:y] == "2029"

            !compilation && @test isapprox(testqry[1,:val], 3845.15711985937; atol=TOL)
            !compilation && @test isapprox(testqry[2,:val], 146.552326874185; atol=TOL)
            !compilation && @test isapprox(testqry[3,:val], 139.573639845721; atol=TOL)
            !compilation && @test isapprox(testqry[4,:val], 132.927276043543; atol=TOL)
            !compilation && @test isapprox(testqry[5,:val], 126.597405755756; atol=TOL)
            !compilation && @test isapprox(testqry[6,:val], 120.568957862625; atol=TOL)
            !compilation && @test isapprox(testqry[7,:val], 114.827578916785; atol=TOL)
            !compilation && @test isapprox(testqry[8,:val], 109.359598968367; atol=TOL)
            !compilation && @test isapprox(testqry[9,:val], 104.151999017492; atol=TOL)
            !compilation && @test isapprox(testqry[10,:val], 99.1923800166593; atol=TOL)

            # Test with optional outputs
            NemoMod.calculatescenario(dbfile; jumpmodel=Model(optimizer_with_attributes(GLPK.Optimizer, "presolve" => true)),
                varstosave = "vrateofproductionbytechnologybymode, vrateofusebytechnologybymode, vrateofdemand, vproductionbytechnology, vtotaltechnologyannualactivity, "
                * "vtotaltechnologymodelperiodactivity, vusebytechnology, vmodelperiodcostbyregion, vannualtechnologyemissionpenaltybyemission, "
                * "vtotaldiscountedcost", restrictvars=true, quiet = false)

            testqry = SQLite.DBInterface.execute(db, "select * from vtotaldiscountedcost") |> DataFrame

            !compilation && @test testqry[1,:y] == "2020"
            !compilation && @test testqry[2,:y] == "2021"
            !compilation && @test testqry[3,:y] == "2022"
            !compilation && @test testqry[4,:y] == "2023"
            !compilation && @test testqry[5,:y] == "2024"
            !compilation && @test testqry[6,:y] == "2025"
            !compilation && @test testqry[7,:y] == "2026"
            !compilation && @test testqry[8,:y] == "2027"
            !compilation && @test testqry[9,:y] == "2028"
            !compilation && @test testqry[10,:y] == "2029"

            !compilation && @test isapprox(testqry[1,:val], 3845.15711985937; atol=TOL)
            !compilation && @test isapprox(testqry[2,:val], 146.552326874185; atol=TOL)
            !compilation && @test isapprox(testqry[3,:val], 139.573639845721; atol=TOL)
            !compilation && @test isapprox(testqry[4,:val], 132.927276043543; atol=TOL)
            !compilation && @test isapprox(testqry[5,:val], 126.597405755756; atol=TOL)
            !compilation && @test isapprox(testqry[6,:val], 120.568957862625; atol=TOL)
            !compilation && @test isapprox(testqry[7,:val], 114.827578916785; atol=TOL)
            !compilation && @test isapprox(testqry[8,:val], 109.359598968367; atol=TOL)
            !compilation && @test isapprox(testqry[9,:val], 104.151999017492; atol=TOL)
            !compilation && @test isapprox(testqry[10,:val], 99.1923800166593; atol=TOL)

            # Test with restrictvars
            NemoMod.calculatescenario(dbfile; jumpmodel=Model(optimizer_with_attributes(GLPK.Optimizer, "presolve" => true)),
                varstosave = "vrateofproductionbytechnologybymode, vrateofusebytechnologybymode, vproductionbytechnology, vusebytechnology, "
                * "vtotaldiscountedcost",
                restrictvars = true, quiet = false)

            testqry = SQLite.DBInterface.execute(db, "select * from vtotaldiscountedcost") |> DataFrame

            !compilation && @test testqry[1,:y] == "2020"
            !compilation && @test testqry[2,:y] == "2021"
            !compilation && @test testqry[3,:y] == "2022"
            !compilation && @test testqry[4,:y] == "2023"
            !compilation && @test testqry[5,:y] == "2024"
            !compilation && @test testqry[6,:y] == "2025"
            !compilation && @test testqry[7,:y] == "2026"
            !compilation && @test testqry[8,:y] == "2027"
            !compilation && @test testqry[9,:y] == "2028"
            !compilation && @test testqry[10,:y] == "2029"

            !compilation && @test isapprox(testqry[1,:val], 3845.15711985937; atol=TOL)
            !compilation && @test isapprox(testqry[2,:val], 146.552326874185; atol=TOL)
            !compilation && @test isapprox(testqry[3,:val], 139.573639845721; atol=TOL)
            !compilation && @test isapprox(testqry[4,:val], 132.927276043543; atol=TOL)
            !compilation && @test isapprox(testqry[5,:val], 126.597405755756; atol=TOL)
            !compilation && @test isapprox(testqry[6,:val], 120.568957862625; atol=TOL)
            !compilation && @test isapprox(testqry[7,:val], 114.827578916785; atol=TOL)
            !compilation && @test isapprox(testqry[8,:val], 109.359598968367; atol=TOL)
            !compilation && @test isapprox(testqry[9,:val], 104.151999017492; atol=TOL)
            !compilation && @test isapprox(testqry[10,:val], 99.1923800166593; atol=TOL)

            # Test with storage net zero constraints
            SQLite.DBInterface.execute(db, "update STORAGE set netzeroyear = 1")
            NemoMod.calculatescenario(dbfile; jumpmodel=Model(optimizer_with_attributes(GLPK.Optimizer, "presolve" => true)), restrictvars=false)
            testqry = SQLite.DBInterface.execute(db, "select * from vtotaldiscountedcost") |> DataFrame

            !compilation && @test testqry[1,:y] == "2020"
            !compilation && @test testqry[2,:y] == "2021"
            !compilation && @test testqry[3,:y] == "2022"
            !compilation && @test testqry[4,:y] == "2023"
            !compilation && @test testqry[5,:y] == "2024"
            !compilation && @test testqry[6,:y] == "2025"
            !compilation && @test testqry[7,:y] == "2026"
            !compilation && @test testqry[8,:y] == "2027"
            !compilation && @test testqry[9,:y] == "2028"
            !compilation && @test testqry[10,:y] == "2029"

            !compilation && @test isapprox(testqry[1,:val], 3840.94032304097; atol=TOL)
            !compilation && @test isapprox(testqry[2,:val], 459.294966842956; atol=TOL)
            !compilation && @test isapprox(testqry[3,:val], 437.423777945669; atol=TOL)
            !compilation && @test isapprox(testqry[4,:val], 416.594074233972; atol=TOL)
            !compilation && @test isapprox(testqry[5,:val], 396.756261175212; atol=TOL)
            !compilation && @test isapprox(testqry[6,:val], 377.863105881154; atol=TOL)
            !compilation && @test isapprox(testqry[7,:val], 359.869624648718; atol=TOL)
            !compilation && @test isapprox(testqry[8,:val], 342.732975855922; atol=TOL)
            !compilation && @test isapprox(testqry[9,:val], 326.412357958021; atol=TOL)
            !compilation && @test isapprox(testqry[10,:val], 310.868912340972; atol=TOL)

            SQLite.DBInterface.execute(db, "update STORAGE set netzeroyear = 0")

            # Test with calcyears
            NemoMod.calculatescenario(dbfile; jumpmodel = Model(optimizer_with_attributes(GLPK.Optimizer, "presolve" => true)), restrictvars=true,
                calcyears=[2020,2029])
            testqry = SQLite.DBInterface.execute(db, "select * from vtotaldiscountedcost") |> DataFrame

            !compilation && @test testqry[1,:y] == "2020"
            !compilation && @test testqry[2,:y] == "2029"

            !compilation && @test isapprox(testqry[1,:val], 3840.94023817782; atol=TOL)
            !compilation && @test isapprox(testqry[2,:val], 3427.81584479179; atol=TOL)

            # Test MinimumUtilization
            SQLite.DBInterface.execute(db, "insert into MinimumUtilization select ROWID, '1', 'gas', val, 2025, 0.5 from TIMESLICE")
            NemoMod.calculatescenario(dbfile; jumpmodel = Model(optimizer_with_attributes(GLPK.Optimizer, "presolve" => true)), varstosave="vproductionbytechnologyannual")
            testqry = SQLite.DBInterface.execute(db, "select * from vproductionbytechnologyannual where t = 'gas' and y = 2025") |> DataFrame

            !compilation && @test isapprox(testqry[1,:val], 15.768; atol=TOL)

            SQLite.DBInterface.execute(db, "delete from MinimumUtilization")

            # Delete test results and re-compact test database
            NemoMod.dropresulttables(db)
            testqry = SQLite.DBInterface.execute(db, "VACUUM")
        end  # "Solving storage_test with GLPK"

        @testset "Solving storage_transmission_test with GLPK" begin
            dbfile = joinpath(@__DIR__, "storage_transmission_test.sqlite")
            #dbfile = "c:/temp/storage_transmission_test.sqlite"
            chmod(dbfile, 0o777)  # Make dbfile read-write. Necessary because after Julia 1.0, Pkg.add makes all package files read-only

            NemoMod.calculatescenario(dbfile; jumpmodel=Model(optimizer_with_attributes(GLPK.Optimizer, "presolve" => true)),
                varstosave = "vdemandnn, vnewcapacity, vtotalcapacityannual, vproductionbytechnologyannual, vproductionnn, vusebytechnologyannual, vusenn, vtotaldiscountedcost, "
                    * "vtransmissionbuilt, vtransmissionexists, vtransmissionbyline, vtransmissionannual",
                restrictvars=true, quiet = false)

            db = SQLite.DB(dbfile)
            testqry = SQLite.DBInterface.execute(db, "select * from vtotaldiscountedcost") |> DataFrame

            !compilation && @test testqry[1,:y] == "2020"
            !compilation && @test testqry[2,:y] == "2021"
            !compilation && @test testqry[3,:y] == "2022"
            !compilation && @test testqry[4,:y] == "2023"
            !compilation && @test testqry[5,:y] == "2024"
            !compilation && @test testqry[6,:y] == "2025"
            !compilation && @test testqry[7,:y] == "2026"
            !compilation && @test testqry[8,:y] == "2027"
            !compilation && @test testqry[9,:y] == "2028"
            !compilation && @test testqry[10,:y] == "2029"

            !compilation && @test isapprox(testqry[1,:val], 9786.56610437941; atol=TOL)
            !compilation && @test isapprox(testqry[2,:val], 239.495268121409; atol=TOL)
            !compilation && @test isapprox(testqry[3,:val], 228.090669080493; atol=TOL)
            !compilation && @test isapprox(testqry[4,:val], 217.229187314711; atol=TOL)
            !compilation && @test isapprox(testqry[5,:val], 206.884940299725; atol=TOL)
            !compilation && @test isapprox(testqry[6,:val], 197.033276475929; atol=TOL)
            !compilation && @test isapprox(testqry[7,:val], 187.650739500884; atol=TOL)
            !compilation && @test isapprox(testqry[8,:val], 178.714990000842; atol=TOL)
            !compilation && @test isapprox(testqry[9,:val], 170.204752381754; atol=TOL)
            !compilation && @test isapprox(testqry[10,:val], 162.099764173099; atol=TOL)

            # Test MinimumUtilization
            SQLite.DBInterface.execute(db, "insert into MinimumUtilization select ROWID, '1', 'gas', val, 2025, 0.2 from TIMESLICE")
            NemoMod.calculatescenario(dbfile; jumpmodel = jumpmodel=Model(optimizer_with_attributes(GLPK.Optimizer, "presolve" => true)), varstosave="vproductionbytechnologyannual", calcyears=[2020,2025,2029])
            testqry = SQLite.DBInterface.execute(db, "select * from vproductionbytechnologyannual where t = 'gas' and y = 2025") |> DataFrame

            !compilation && @test isapprox(testqry[1,:val], 16.3149963697108; atol=TOL)

            SQLite.DBInterface.execute(db, "delete from MinimumUtilization")

            # Test interest rates
            SQLite.DBInterface.execute(db, "insert into InterestRateStorage select rowid, 1, 'storage1', y.val, 0.05 from year y")
            SQLite.DBInterface.execute(db, "insert into InterestRateTechnology select rowid, 1, 'solar', y.val, 0.05 from year y")
            SQLite.DBInterface.execute(db, "update TransmissionLine set interestrate = 0.05 where id = 2")
            NemoMod.calculatescenario(dbfile; jumpmodel = Model(optimizer_with_attributes(GLPK.Optimizer, "presolve" => true)), varstosave="vtotaldiscountedcost", calcyears=[2020,2025,2029])
            testqry = SQLite.DBInterface.execute(db, "select * from vtotaldiscountedcost") |> DataFrame

            !compilation && @test testqry[1,:y] == "2020"
            !compilation && @test testqry[2,:y] == "2025"
            !compilation && @test testqry[3,:y] == "2029"

            !compilation && @test isapprox(testqry[1,:val], 12672.8117352623; atol=TOL)
            !compilation && @test isapprox(testqry[2,:val], 2510.44571676115; atol=TOL)
            !compilation && @test isapprox(testqry[3,:val], 1611.02249720726; atol=TOL)

            SQLite.DBInterface.execute(db, "delete from InterestRateStorage")
            SQLite.DBInterface.execute(db, "delete from InterestRateTechnology")
            SQLite.DBInterface.execute(db, "update TransmissionLine set interestrate = null where id = 2")

            # Delete test results and re-compact test database
            NemoMod.dropresulttables(db)
            testqry = SQLite.DBInterface.execute(db, "VACUUM")
        end  # "Solving storage_transmission_test with GLPK"

        GC.gc()
    end  # @isdefined GLPK
end  # glpk_tests(compilation::Bool=false)
