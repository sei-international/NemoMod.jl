#=
    NEMO: Next-generation Energy Modeling system for Optimization.
    https://github.com/sei-international/NemoMod.jl

    Copyright © 2019: Stockholm Environment Institute U.S.

	File description: Tests of NemoMod package using GLPK solver (default solver for NEMO).
=#

@testset "Solving storage_test with GLPK" begin
    @info "Running GLPK tests."

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

@testset "Solving storage_transmission_test with GLPK" begin
    dbfile = joinpath(@__DIR__, "storage_transmission_test.sqlite")
    chmod(dbfile, 0o777)  # Make dbfile read-write. Necessary because after Julia 1.0, Pkg.add makes all package files read-only

    NemoMod.calculatescenario(dbfile;
        varstosave =
            "vdemandnn, vnewcapacity, vtotalcapacityannual, vproductionbytechnologyannual, vproductionnn, vusebytechnologyannual, vusenn, vtotaldiscountedcost, "
            * "vtransmissionbuilt, vtransmissionexists, vtransmissionbyline, vtransmissionannual",
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

    @test isapprox(testqry[1,:val], 9786.566266038; atol=TOL)
    @test isapprox(testqry[2,:val], 239.49518743249; atol=TOL)
    @test isapprox(testqry[3,:val], 228.090642412206; atol=TOL)
    @test isapprox(testqry[4,:val], 217.22918324972; atol=TOL)
    @test isapprox(testqry[5,:val], 206.884936428305; atol=TOL)
    @test isapprox(testqry[6,:val], 197.033272788862; atol=TOL)
    @test isapprox(testqry[7,:val], 187.650735989392; atol=TOL)
    @test isapprox(testqry[8,:val], 178.714986656564; atol=TOL)
    @test isapprox(testqry[9,:val], 170.204749196731; atol=TOL)
    @test isapprox(testqry[10,:val], 162.099761139741; atol=TOL)

    # Delete test results and re-compact test database
    NemoMod.dropresulttables(db)
    testqry = SQLite.DBInterface.execute(db, "VACUUM")
end  # "Solving storage_transmission_test with GLPK"
