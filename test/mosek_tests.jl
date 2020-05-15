#=
    NEMO: Next-generation Energy Modeling system for Optimization.
    https://github.com/sei-international/NemoMod.jl

    Copyright © 2019: Stockholm Environment Institute U.S.

	File description: Tests of NemoMod package using Mosek solver.
=#

# Tests will be skipped if Mosek package is not installed.
try
    using Mosek
catch
    @info "Skipping Mosek tests."
end

if @isdefined Mosek
    @info "Running Mosek tests."

    @testset "Solving storage_test with Mosek" begin
        dbfile = joinpath(@__DIR__, "storage_test.sqlite")
        chmod(dbfile, 0o777)  # Make dbfile read-write. Necessary because after Julia 1.0, Pkg.add makes all package files read-only

        # Test with default outputs
        NemoMod.calculatescenario(dbfile; jumpmodel = JuMP.Model(solver = solver=MosekSolver()), restrictvars=false, quiet = false)

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

        @test isapprox(testqry[1,:val], 3845.15703404259; atol=TOL)
        @test isapprox(testqry[2,:val], 146.55227050539; atol=TOL)
        @test isapprox(testqry[3,:val], 139.57362837926; atol=TOL)
        @test isapprox(testqry[4,:val], 132.927266053843; atol=TOL)
        @test isapprox(testqry[5,:val], 126.597396376304; atol=TOL)
        @test isapprox(testqry[6,:val], 120.568948487497; atol=TOL)
        @test isapprox(testqry[7,:val], 114.827569988092; atol=TOL)
        @test isapprox(testqry[8,:val], 109.35959046485; atol=TOL)
        @test isapprox(testqry[9,:val], 104.151990918904; atol=TOL)
        @test isapprox(testqry[10,:val], 99.1923723037184; atol=TOL)

        # Test with optional outputs
        NemoMod.calculatescenario(dbfile; jumpmodel = JuMP.Model(solver = solver=MosekSolver()),
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

        @test isapprox(testqry[1,:val], 3845.15703404259; atol=TOL)
        @test isapprox(testqry[2,:val], 146.55227050539; atol=TOL)
        @test isapprox(testqry[3,:val], 139.57362837926; atol=TOL)
        @test isapprox(testqry[4,:val], 132.927266053843; atol=TOL)
        @test isapprox(testqry[5,:val], 126.597396376304; atol=TOL)
        @test isapprox(testqry[6,:val], 120.568948487497; atol=TOL)
        @test isapprox(testqry[7,:val], 114.827569988092; atol=TOL)
        @test isapprox(testqry[8,:val], 109.35959046485; atol=TOL)
        @test isapprox(testqry[9,:val], 104.151990918904; atol=TOL)
        @test isapprox(testqry[10,:val], 99.1923723037184; atol=TOL)

        # Test with restrictvars
        NemoMod.calculatescenario(dbfile; jumpmodel = JuMP.Model(solver = solver=MosekSolver()),
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

        @test isapprox(testqry[1,:val], 3845.15703404259; atol=TOL)
        @test isapprox(testqry[2,:val], 146.55227050539; atol=TOL)
        @test isapprox(testqry[3,:val], 139.57362837926; atol=TOL)
        @test isapprox(testqry[4,:val], 132.927266053843; atol=TOL)
        @test isapprox(testqry[5,:val], 126.597396376304; atol=TOL)
        @test isapprox(testqry[6,:val], 120.568948487497; atol=TOL)
        @test isapprox(testqry[7,:val], 114.827569988092; atol=TOL)
        @test isapprox(testqry[8,:val], 109.35959046485; atol=TOL)
        @test isapprox(testqry[9,:val], 104.151990918904; atol=TOL)
        @test isapprox(testqry[10,:val], 99.1923723037184; atol=TOL)

        # Test with storage net zero constraints
        SQLite.DBInterface.execute(db, "update STORAGE set netzeroyear = 1")
        NemoMod.calculatescenario(dbfile; jumpmodel = Model(solver = MosekSolver()), restrictvars=false)
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
    end  # "Solving storage_test with Mosek"

    @testset "Solving storage_transmission_test with Mosek" begin
        dbfile = joinpath(@__DIR__, "storage_transmission_test.sqlite")
        chmod(dbfile, 0o777)  # Make dbfile read-write. Necessary because after Julia 1.0, Pkg.add makes all package files read-only

        NemoMod.calculatescenario(dbfile; jumpmodel = JuMP.Model(solver = MosekSolver()),
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

        @test isapprox(testqry[1,:val], 9786.566268055; atol=TOL)
        @test isapprox(testqry[2,:val], 239.495185664255; atol=TOL)
        @test isapprox(testqry[3,:val], 228.090642412206; atol=TOL)
        @test isapprox(testqry[4,:val], 217.22918324972; atol=TOL)
        @test isapprox(testqry[5,:val], 206.884936428305; atol=TOL)
        @test isapprox(testqry[6,:val], 197.033272788861; atol=TOL)
        @test isapprox(testqry[7,:val], 187.650735989392; atol=TOL)
        @test isapprox(testqry[8,:val], 178.714986656564; atol=TOL)
        @test isapprox(testqry[9,:val], 170.204749196728; atol=TOL)
        @test isapprox(testqry[10,:val], 162.099761139741; atol=TOL)

        # Delete test results and re-compact test database
        NemoMod.dropresulttables(db)
        testqry = SQLite.DBInterface.execute(db, "VACUUM")
    end  # "Solving storage_transmission_test with Mosek"
end  # @isdefined Mosek
