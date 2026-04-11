#=
    NEMO: Next Energy Modeling system for Optimization.
    https://github.com/sei-international/NemoMod.jl

    Copyright © 2024: Stockholm Environment Institute U.S.

    File description: Tests for OSeMOSYS to NemoMod converter.
=#

"""Creates a minimal OSeMOSYS SQLite database for testing at the given path."""
function _create_test_osemosys_db(path::String)
    isfile(path) && rm(path; force=true)
    db = SQLite.DB(path)

    # --- Dimension/Set tables ---
    SQLite.DBInterface.execute(db, "CREATE TABLE REGION (VALUE TEXT)")
    SQLite.DBInterface.execute(db, "INSERT INTO REGION VALUES ('R1'), ('R2')")

    SQLite.DBInterface.execute(db, "CREATE TABLE TECHNOLOGY (VALUE TEXT)")
    SQLite.DBInterface.execute(db, "INSERT INTO TECHNOLOGY VALUES ('TECH1'), ('TECH2')")

    SQLite.DBInterface.execute(db, "CREATE TABLE FUEL (VALUE TEXT)")
    SQLite.DBInterface.execute(db, "INSERT INTO FUEL VALUES ('ELC'), ('GAS')")

    SQLite.DBInterface.execute(db, "CREATE TABLE EMISSION (VALUE TEXT)")
    SQLite.DBInterface.execute(db, "INSERT INTO EMISSION VALUES ('CO2')")

    SQLite.DBInterface.execute(db, "CREATE TABLE MODE_OF_OPERATION (VALUE TEXT)")
    SQLite.DBInterface.execute(db, "INSERT INTO MODE_OF_OPERATION VALUES ('1'), ('2')")

    SQLite.DBInterface.execute(db, "CREATE TABLE TIMESLICE (VALUE TEXT)")
    SQLite.DBInterface.execute(db, "INSERT INTO TIMESLICE VALUES ('SD'), ('SN'), ('WD')")

    SQLite.DBInterface.execute(db, "CREATE TABLE YEAR (VALUE TEXT)")
    SQLite.DBInterface.execute(db, "INSERT INTO YEAR VALUES ('2020'), ('2025'), ('2030')")

    SQLite.DBInterface.execute(db, "CREATE TABLE STORAGE (VALUE TEXT)")
    SQLite.DBInterface.execute(db, "INSERT INTO STORAGE VALUES ('DAM')")

    # --- Time slicing tables ---
    SQLite.DBInterface.execute(db, "CREATE TABLE SEASON (VALUE TEXT)")
    SQLite.DBInterface.execute(db, "INSERT INTO SEASON VALUES ('S'), ('W')")

    SQLite.DBInterface.execute(db, "CREATE TABLE DAYTYPE (VALUE TEXT)")
    SQLite.DBInterface.execute(db, "INSERT INTO DAYTYPE VALUES ('1')")

    # DaysInDayType: Season S has 182.5 days, Season W has 182.5 days
    SQLite.DBInterface.execute(db, "CREATE TABLE DaysInDayType (SEASON TEXT, DAYTYPE TEXT, YEAR TEXT, VALUE REAL)")
    for y in ["2020", "2025", "2030"]
        SQLite.DBInterface.execute(db, "INSERT INTO DaysInDayType VALUES ('S', '1', '$(y)', 182.5)")
        SQLite.DBInterface.execute(db, "INSERT INTO DaysInDayType VALUES ('W', '1', '$(y)', 182.5)")
    end

    # Conversionls: SD->S, SN->S, WD->W
    SQLite.DBInterface.execute(db, "CREATE TABLE Conversionls (TIMESLICE TEXT, SEASON TEXT, VALUE REAL)")
    SQLite.DBInterface.execute(db, "INSERT INTO Conversionls VALUES ('SD', 'S', 1), ('SN', 'S', 1), ('WD', 'W', 1)")

    # Conversionld: all timeslices -> daytype 1
    SQLite.DBInterface.execute(db, "CREATE TABLE Conversionld (TIMESLICE TEXT, DAYTYPE TEXT, VALUE REAL)")
    SQLite.DBInterface.execute(db, "INSERT INTO Conversionld VALUES ('SD', '1', 1), ('SN', '1', 1), ('WD', '1', 1)")

    # Conversionlh: SD->1, SN->2, WD->1
    SQLite.DBInterface.execute(db, "CREATE TABLE Conversionlh (TIMESLICE TEXT, DAILYTIMEBRACKET TEXT, VALUE REAL)")
    SQLite.DBInterface.execute(db, "INSERT INTO Conversionlh VALUES ('SD', '1', 1), ('SN', '2', 1), ('WD', '1', 1)")

    # --- Compatible parameter tables ---
    SQLite.DBInterface.execute(db, "CREATE TABLE CapitalCost (REGION TEXT, TECHNOLOGY TEXT, YEAR TEXT, VALUE REAL)")
    SQLite.DBInterface.execute(db, "INSERT INTO CapitalCost VALUES ('R1', 'TECH1', '2020', 1000.0)")
    SQLite.DBInterface.execute(db, "INSERT INTO CapitalCost VALUES ('R1', 'TECH1', '2025', 900.0)")
    SQLite.DBInterface.execute(db, "INSERT INTO CapitalCost VALUES ('R1', 'TECH2', '2020', 500.0)")

    SQLite.DBInterface.execute(db, "CREATE TABLE DiscountRate (REGION TEXT, VALUE REAL)")
    SQLite.DBInterface.execute(db, "INSERT INTO DiscountRate VALUES ('R1', 0.05), ('R2', 0.08)")

    SQLite.DBInterface.execute(db, "CREATE TABLE InputActivityRatio (REGION TEXT, TECHNOLOGY TEXT, FUEL TEXT, MODE_OF_OPERATION TEXT, YEAR TEXT, VALUE REAL)")
    SQLite.DBInterface.execute(db, "INSERT INTO InputActivityRatio VALUES ('R1', 'TECH1', 'GAS', '1', '2020', 1.5)")
    SQLite.DBInterface.execute(db, "INSERT INTO InputActivityRatio VALUES ('R1', 'TECH1', 'GAS', '1', '2025', 1.4)")

    SQLite.DBInterface.execute(db, "CREATE TABLE OutputActivityRatio (REGION TEXT, TECHNOLOGY TEXT, FUEL TEXT, MODE_OF_OPERATION TEXT, YEAR TEXT, VALUE REAL)")
    SQLite.DBInterface.execute(db, "INSERT INTO OutputActivityRatio VALUES ('R1', 'TECH1', 'ELC', '1', '2020', 1.0)")

    SQLite.DBInterface.execute(db, "CREATE TABLE YearSplit (TIMESLICE TEXT, YEAR TEXT, VALUE REAL)")
    SQLite.DBInterface.execute(db, "INSERT INTO YearSplit VALUES ('SD', '2020', 0.25), ('SN', '2020', 0.25), ('WD', '2020', 0.5)")

    SQLite.DBInterface.execute(db, "CREATE TABLE SpecifiedAnnualDemand (REGION TEXT, FUEL TEXT, YEAR TEXT, VALUE REAL)")
    SQLite.DBInterface.execute(db, "INSERT INTO SpecifiedAnnualDemand VALUES ('R1', 'ELC', '2020', 100.0)")

    SQLite.DBInterface.execute(db, "CREATE TABLE OperationalLife (REGION TEXT, TECHNOLOGY TEXT, VALUE REAL)")
    SQLite.DBInterface.execute(db, "INSERT INTO OperationalLife VALUES ('R1', 'TECH1', 30)")

    # --- TradeRoute with two REGION columns ---
    SQLite.DBInterface.execute(db, "CREATE TABLE TradeRoute (REGION TEXT, rr TEXT, FUEL TEXT, YEAR TEXT, VALUE REAL)")
    SQLite.DBInterface.execute(db, "INSERT INTO TradeRoute VALUES ('R1', 'R2', 'ELC', '2020', 1.0)")
    SQLite.DBInterface.execute(db, "INSERT INTO TradeRoute VALUES ('R2', 'R1', 'ELC', '2020', 1.0)")

    # --- Transformation: CapacityFactor (4D) ---
    SQLite.DBInterface.execute(db, "CREATE TABLE CapacityFactor (REGION TEXT, TECHNOLOGY TEXT, TIMESLICE TEXT, YEAR TEXT, VALUE REAL)")
    SQLite.DBInterface.execute(db, "INSERT INTO CapacityFactor VALUES ('R1', 'TECH1', 'SD', '2020', 0.9)")
    SQLite.DBInterface.execute(db, "INSERT INTO CapacityFactor VALUES ('R1', 'TECH1', 'SN', '2020', 0.3)")
    SQLite.DBInterface.execute(db, "INSERT INTO CapacityFactor VALUES ('R1', 'TECH1', 'WD', '2020', 0.7)")

    # --- Transformation: AvailabilityFactor (3D, no timeslice) ---
    SQLite.DBInterface.execute(db, "CREATE TABLE AvailabilityFactor (REGION TEXT, TECHNOLOGY TEXT, YEAR TEXT, VALUE REAL)")
    # TECH2 has no CapacityFactor entries, so AvailabilityFactor should expand across all timeslices
    SQLite.DBInterface.execute(db, "INSERT INTO AvailabilityFactor VALUES ('R1', 'TECH2', '2020', 0.85)")
    # TECH1 already has CapacityFactor for 2020 - INSERT OR IGNORE should preserve CapacityFactor values
    SQLite.DBInterface.execute(db, "INSERT INTO AvailabilityFactor VALUES ('R1', 'TECH1', '2020', 0.95)")

    # --- Transformation: ReserveMargin ---
    SQLite.DBInterface.execute(db, "CREATE TABLE ReserveMargin (REGION TEXT, YEAR TEXT, VALUE REAL)")
    SQLite.DBInterface.execute(db, "INSERT INTO ReserveMargin VALUES ('R1', '2020', 1.15)")
    SQLite.DBInterface.execute(db, "INSERT INTO ReserveMargin VALUES ('R1', '2025', 1.20)")

    SQLite.DBInterface.execute(db, "CREATE TABLE ReserveMarginTagFuel (REGION TEXT, FUEL TEXT, YEAR TEXT, VALUE REAL)")
    SQLite.DBInterface.execute(db, "INSERT INTO ReserveMarginTagFuel VALUES ('R1', 'ELC', '2020', 1)")
    SQLite.DBInterface.execute(db, "INSERT INTO ReserveMarginTagFuel VALUES ('R1', 'ELC', '2025', 1)")

    SQLite.DBInterface.execute(db, "CREATE TABLE ReserveMarginTagTechnology (REGION TEXT, TECHNOLOGY TEXT, YEAR TEXT, VALUE REAL)")
    SQLite.DBInterface.execute(db, "INSERT INTO ReserveMarginTagTechnology VALUES ('R1', 'TECH1', '2020', 1.0)")
    SQLite.DBInterface.execute(db, "INSERT INTO ReserveMarginTagTechnology VALUES ('R1', 'TECH2', '2020', 0.5)")

    # --- Transformation: RE targets ---
    SQLite.DBInterface.execute(db, "CREATE TABLE REMinProductionTarget (REGION TEXT, YEAR TEXT, VALUE REAL)")
    SQLite.DBInterface.execute(db, "INSERT INTO REMinProductionTarget VALUES ('R1', '2020', 0.10)")
    SQLite.DBInterface.execute(db, "INSERT INTO REMinProductionTarget VALUES ('R1', '2025', 0.20)")

    SQLite.DBInterface.execute(db, "CREATE TABLE RETagFuel (REGION TEXT, FUEL TEXT, YEAR TEXT, VALUE REAL)")
    SQLite.DBInterface.execute(db, "INSERT INTO RETagFuel VALUES ('R1', 'ELC', '2020', 1)")
    SQLite.DBInterface.execute(db, "INSERT INTO RETagFuel VALUES ('R1', 'ELC', '2025', 1)")

    DBInterface.close!(db)
    return path
end

"""Creates a minimal OSeMOSYS DB without optional time-slicing tables (SEASON, DAYTYPE, etc.)."""
function _create_minimal_osemosys_db(path::String)
    isfile(path) && rm(path; force=true)
    db = SQLite.DB(path)

    SQLite.DBInterface.execute(db, "CREATE TABLE REGION (VALUE TEXT)")
    SQLite.DBInterface.execute(db, "INSERT INTO REGION VALUES ('R1')")

    SQLite.DBInterface.execute(db, "CREATE TABLE TECHNOLOGY (VALUE TEXT)")
    SQLite.DBInterface.execute(db, "INSERT INTO TECHNOLOGY VALUES ('TECH1')")

    SQLite.DBInterface.execute(db, "CREATE TABLE FUEL (VALUE TEXT)")
    SQLite.DBInterface.execute(db, "INSERT INTO FUEL VALUES ('ELC')")

    SQLite.DBInterface.execute(db, "CREATE TABLE EMISSION (VALUE TEXT)")
    SQLite.DBInterface.execute(db, "INSERT INTO EMISSION VALUES ('CO2')")

    SQLite.DBInterface.execute(db, "CREATE TABLE MODE_OF_OPERATION (VALUE TEXT)")
    SQLite.DBInterface.execute(db, "INSERT INTO MODE_OF_OPERATION VALUES ('1')")

    SQLite.DBInterface.execute(db, "CREATE TABLE TIMESLICE (VALUE TEXT)")
    SQLite.DBInterface.execute(db, "INSERT INTO TIMESLICE VALUES ('TS1')")

    SQLite.DBInterface.execute(db, "CREATE TABLE YEAR (VALUE TEXT)")
    SQLite.DBInterface.execute(db, "INSERT INTO YEAR VALUES ('2020')")

    # No SEASON, DAYTYPE, Conversionls, Conversionld, Conversionlh, DaysInDayType

    DBInterface.close!(db)
    return path
end

"""Creates an OSeMOSYS DB with lowercase table names for case-sensitivity testing."""
function _create_lowercase_osemosys_db(path::String)
    isfile(path) && rm(path; force=true)
    db = SQLite.DB(path)

    SQLite.DBInterface.execute(db, "CREATE TABLE region (VALUE TEXT)")
    SQLite.DBInterface.execute(db, "INSERT INTO region VALUES ('R1')")

    SQLite.DBInterface.execute(db, "CREATE TABLE technology (VALUE TEXT)")
    SQLite.DBInterface.execute(db, "INSERT INTO technology VALUES ('TECH1')")

    SQLite.DBInterface.execute(db, "CREATE TABLE fuel (VALUE TEXT)")
    SQLite.DBInterface.execute(db, "INSERT INTO fuel VALUES ('ELC')")

    SQLite.DBInterface.execute(db, "CREATE TABLE emission (VALUE TEXT)")
    SQLite.DBInterface.execute(db, "INSERT INTO emission VALUES ('CO2')")

    SQLite.DBInterface.execute(db, "CREATE TABLE mode_of_operation (VALUE TEXT)")
    SQLite.DBInterface.execute(db, "INSERT INTO mode_of_operation VALUES ('1')")

    SQLite.DBInterface.execute(db, "CREATE TABLE timeslice (VALUE TEXT)")
    SQLite.DBInterface.execute(db, "INSERT INTO timeslice VALUES ('TS1')")

    SQLite.DBInterface.execute(db, "CREATE TABLE year (VALUE TEXT)")
    SQLite.DBInterface.execute(db, "INSERT INTO year VALUES ('2020')")

    DBInterface.close!(db)
    return path
end

# Paths for test databases
const osemosys_src_path = joinpath(dbfile_path, "test_osemosys_src.sqlite")
const nemo_dest_path = joinpath(dbfile_path, "test_osemosys_dest.sqlite")

@info "Testing OSeMOSYS to NemoMod converter."

# ---- Main conversion test: create source DB, convert, then run all checks ----
_create_test_osemosys_db(osemosys_src_path)
destdb = NemoMod.convert_osemosys(osemosys_src_path, nemo_dest_path; quiet=true)

@testset "Basic conversion" begin
    !compilation && @test destdb isa SQLite.DB
    !compilation && @test isfile(nemo_dest_path)
end

@testset "Set conversion" begin
    regions = sort(DataFrame(SQLite.DBInterface.execute(destdb, "SELECT val FROM REGION")).val)
    !compilation && @test regions == ["R1", "R2"]

    techs = sort(DataFrame(SQLite.DBInterface.execute(destdb, "SELECT val FROM TECHNOLOGY")).val)
    !compilation && @test techs == ["TECH1", "TECH2"]

    fuels = sort(DataFrame(SQLite.DBInterface.execute(destdb, "SELECT val FROM FUEL")).val)
    !compilation && @test fuels == ["ELC", "GAS"]

    emissions = DataFrame(SQLite.DBInterface.execute(destdb, "SELECT val FROM EMISSION")).val
    !compilation && @test emissions == ["CO2"]

    modes = sort(DataFrame(SQLite.DBInterface.execute(destdb, "SELECT val FROM MODE_OF_OPERATION")).val)
    !compilation && @test modes == ["1", "2"]

    timeslices = sort(DataFrame(SQLite.DBInterface.execute(destdb, "SELECT val FROM TIMESLICE")).val)
    !compilation && @test timeslices == ["SD", "SN", "WD"]

    years = sort(DataFrame(SQLite.DBInterface.execute(destdb, "SELECT val FROM YEAR")).val)
    !compilation && @test years == ["2020", "2025", "2030"]

    # STORAGE: check val and extra NemoMod fields
    storage_df = DataFrame(SQLite.DBInterface.execute(destdb, "SELECT val, netzeroyear, netzerotg1, netzerotg2 FROM STORAGE"))
    !compilation && @test size(storage_df, 1) == 1
    !compilation && @test storage_df[1, :val] == "DAM"
    !compilation && @test storage_df[1, :netzeroyear] == 1
    !compilation && @test storage_df[1, :netzerotg1] == 0
    !compilation && @test storage_df[1, :netzerotg2] == 0
end

@testset "Time slicing conversion" begin
    # TSGROUP1: 2 seasons (S, W) with multipliers from DaysInDayType
    tg1 = DataFrame(SQLite.DBInterface.execute(destdb, "SELECT name, [order], multiplier FROM TSGROUP1 ORDER BY [order]"))
    !compilation && @test size(tg1, 1) == 2
    !compilation && @test tg1[1, :name] == "S"
    !compilation && @test tg1[2, :name] == "W"
    # DaysInDayType: S has 182.5 days per year, averaged across years -> 182.5 / 7 = 26.07 weeks
    !compilation && @test isapprox(tg1[1, :multiplier], 182.5 / 7.0; atol=0.01)
    !compilation && @test isapprox(tg1[2, :multiplier], 182.5 / 7.0; atol=0.01)

    # TSGROUP2: 1 daytype with multiplier
    # With 1 daytype accounting for all days: 182.5 * 7.0 / 182.5 = 7.0 days per week
    tg2 = DataFrame(SQLite.DBInterface.execute(destdb, "SELECT name, [order], multiplier FROM TSGROUP2 ORDER BY [order]"))
    !compilation && @test size(tg2, 1) == 1
    !compilation && @test tg2[1, :name] == "1"
    !compilation && @test isapprox(tg2[1, :multiplier], 7.0; atol=0.01)

    # LTsGroup: 3 timeslices mapped correctly
    lts = DataFrame(SQLite.DBInterface.execute(destdb, "SELECT l, lorder, tg1, tg2 FROM LTsGroup ORDER BY l"))
    !compilation && @test size(lts, 1) == 3
    # SD -> season S, daytype 1, dailytimebracket 1
    sd_row = filter(r -> r.l == "SD", lts)
    !compilation && @test sd_row[1, :tg1] == "S"
    !compilation && @test sd_row[1, :tg2] == "1"
    !compilation && @test sd_row[1, :lorder] == 1
    # SN -> season S, daytype 1, dailytimebracket 2
    sn_row = filter(r -> r.l == "SN", lts)
    !compilation && @test sn_row[1, :tg1] == "S"
    !compilation && @test sn_row[1, :tg2] == "1"
    !compilation && @test sn_row[1, :lorder] == 2
    # WD -> season W, daytype 1, dailytimebracket 1
    wd_row = filter(r -> r.l == "WD", lts)
    !compilation && @test wd_row[1, :tg1] == "W"
    !compilation && @test wd_row[1, :tg2] == "1"
    !compilation && @test wd_row[1, :lorder] == 1
end

@testset "Compatible parameter copy" begin
    # CapitalCost: 3 rows with column renaming
    cc = DataFrame(SQLite.DBInterface.execute(destdb, "SELECT r, t, y, val FROM CapitalCost ORDER BY r, t, y"))
    !compilation && @test size(cc, 1) == 3
    !compilation && @test cc[1, :r] == "R1"
    !compilation && @test cc[1, :t] == "TECH1"
    !compilation && @test cc[1, :y] == "2020"
    !compilation && @test isapprox(cc[1, :val], 1000.0; atol=0.01)
    !compilation && @test isapprox(cc[2, :val], 900.0; atol=0.01)
    !compilation && @test isapprox(cc[3, :val], 500.0; atol=0.01)

    # DiscountRate: 2-column param (r, val)
    dr = DataFrame(SQLite.DBInterface.execute(destdb, "SELECT r, val FROM DiscountRate ORDER BY r"))
    !compilation && @test size(dr, 1) == 2
    !compilation && @test dr[1, :r] == "R1"
    !compilation && @test isapprox(dr[1, :val], 0.05; atol=0.001)
    !compilation && @test dr[2, :r] == "R2"
    !compilation && @test isapprox(dr[2, :val], 0.08; atol=0.001)

    # InputActivityRatio: 6-column param
    iar = DataFrame(SQLite.DBInterface.execute(destdb, "SELECT r, t, f, m, y, val FROM InputActivityRatio ORDER BY y"))
    !compilation && @test size(iar, 1) == 2
    !compilation && @test iar[1, :f] == "GAS"
    !compilation && @test iar[1, :m] == "1"
    !compilation && @test isapprox(iar[1, :val], 1.5; atol=0.01)
    !compilation && @test isapprox(iar[2, :val], 1.4; atol=0.01)

    # YearSplit
    ys = DataFrame(SQLite.DBInterface.execute(destdb, "SELECT l, y, val FROM YearSplit ORDER BY l"))
    !compilation && @test size(ys, 1) == 3
    !compilation && @test isapprox(ys[1, :val], 0.25; atol=0.01)

    # OperationalLife
    ol = DataFrame(SQLite.DBInterface.execute(destdb, "SELECT r, t, val FROM OperationalLife"))
    !compilation && @test size(ol, 1) == 1
    !compilation && @test isapprox(ol[1, :val], 30.0; atol=0.01)
end

@testset "TradeRoute conversion" begin
    tr = DataFrame(SQLite.DBInterface.execute(destdb, "SELECT r, rr, f, y, val FROM TradeRoute ORDER BY r"))
    !compilation && @test size(tr, 1) == 2
    !compilation && @test tr[1, :r] == "R1"
    !compilation && @test tr[1, :rr] == "R2"
    !compilation && @test tr[1, :f] == "ELC"
    !compilation && @test isapprox(tr[1, :val], 1.0; atol=0.01)
    !compilation && @test tr[2, :r] == "R2"
    !compilation && @test tr[2, :rr] == "R1"
end

@testset "AvailabilityFactor transformation" begin
    af = DataFrame(SQLite.DBInterface.execute(destdb,
        "SELECT r, t, l, y, val FROM AvailabilityFactor ORDER BY t, l"))

    # CapacityFactor gave 3 rows for TECH1 (SD, SN, WD at 2020)
    # AvailabilityFactor also has TECH1/2020 but INSERT OR IGNORE should deduplicate
    tech1_rows = filter(r -> r.t == "TECH1", af)
    !compilation && @test size(tech1_rows, 1) == 3  # exactly 3, not 6

    # Check CapacityFactor values are preserved (not overwritten by AvailabilityFactor)
    tech1_sd = filter(r -> r.t == "TECH1" && r.l == "SD" && r.y == "2020", af)
    !compilation && @test size(tech1_sd, 1) == 1
    !compilation && @test isapprox(tech1_sd[1, :val], 0.9; atol=0.01)  # from CapacityFactor

    tech1_sn = filter(r -> r.t == "TECH1" && r.l == "SN" && r.y == "2020", af)
    !compilation && @test size(tech1_sn, 1) == 1
    !compilation && @test isapprox(tech1_sn[1, :val], 0.3; atol=0.01)  # from CapacityFactor

    tech1_wd = filter(r -> r.t == "TECH1" && r.l == "WD" && r.y == "2020", af)
    !compilation && @test size(tech1_wd, 1) == 1
    !compilation && @test isapprox(tech1_wd[1, :val], 0.7; atol=0.01)  # from CapacityFactor

    # TECH2: expanded from 3D AvailabilityFactor (0.85) across all timeslices
    tech2_rows = filter(r -> r.t == "TECH2", af)
    !compilation && @test size(tech2_rows, 1) == 3  # 3 timeslices
    for row in eachrow(tech2_rows)
        !compilation && @test isapprox(row.val, 0.85; atol=0.01)
    end
end

@testset "Reserve margin transformation" begin
    # ReserveMargin: R1/2020 and R1/2025, each with fuel ELC from ReserveMarginTagFuel
    rm = DataFrame(SQLite.DBInterface.execute(destdb,
        "SELECT r, f, y, val FROM ReserveMargin ORDER BY y"))
    !compilation && @test size(rm, 1) == 2
    !compilation && @test rm[1, :r] == "R1"
    !compilation && @test rm[1, :f] == "ELC"
    !compilation && @test rm[1, :y] == "2020"
    !compilation && @test isapprox(rm[1, :val], 1.15; atol=0.01)
    !compilation && @test rm[2, :y] == "2025"
    !compilation && @test isapprox(rm[2, :val], 1.20; atol=0.01)

    # ReserveMarginTagTechnology: TECH1 (val=1.0) and TECH2 (val=0.5), both with fuel ELC
    rmtt = DataFrame(SQLite.DBInterface.execute(destdb,
        "SELECT r, t, f, y, val FROM ReserveMarginTagTechnology ORDER BY t"))
    !compilation && @test size(rmtt, 1) == 2
    !compilation && @test rmtt[1, :t] == "TECH1"
    !compilation && @test rmtt[1, :f] == "ELC"
    !compilation && @test isapprox(rmtt[1, :val], 1.0; atol=0.01)
    !compilation && @test rmtt[2, :t] == "TECH2"
    !compilation && @test isapprox(rmtt[2, :val], 0.5; atol=0.01)
end

@testset "RE target transformation" begin
    re = DataFrame(SQLite.DBInterface.execute(destdb,
        "SELECT r, f, y, val FROM REMinProductionTarget ORDER BY y"))
    !compilation && @test size(re, 1) == 2
    !compilation && @test re[1, :r] == "R1"
    !compilation && @test re[1, :f] == "ELC"
    !compilation && @test re[1, :y] == "2020"
    !compilation && @test isapprox(re[1, :val], 0.10; atol=0.001)
    !compilation && @test re[2, :y] == "2025"
    !compilation && @test isapprox(re[2, :val], 0.20; atol=0.001)
end

# Clean up main test databases
finalize(destdb); destdb = nothing; GC.gc()
delete_file(nemo_dest_path, 20)
delete_file(osemosys_src_path, 20)

!compilation && @test !isfile(nemo_dest_path)
!compilation && @test !isfile(osemosys_src_path)

# ---- Defaults test ----
@testset "Defaults" begin
    src_path = joinpath(dbfile_path, "test_osemosys_defaults_src.sqlite")
    dest_path = joinpath(dbfile_path, "test_osemosys_defaults_dest.sqlite")

    _create_minimal_osemosys_db(src_path)
    db = NemoMod.convert_osemosys(src_path, dest_path;
        defaults=Dict("VariableCost" => 0.5), quiet=true)

    dp = DataFrame(SQLite.DBInterface.execute(db,
        "SELECT tablename, val FROM DefaultParams WHERE tablename = 'VariableCost'"))
    !compilation && @test size(dp, 1) == 1
    !compilation && @test isapprox(dp[1, :val], 0.5; atol=0.001)

    finalize(db); db = nothing; GC.gc()
    delete_file(dest_path, 20)
    delete_file(src_path, 20)
end

# ---- Edge cases ----
@testset "Missing optional time-slicing tables" begin
    src_path = joinpath(dbfile_path, "test_osemosys_minimal_src.sqlite")
    dest_path = joinpath(dbfile_path, "test_osemosys_minimal_dest.sqlite")

    _create_minimal_osemosys_db(src_path)
    db = NemoMod.convert_osemosys(src_path, dest_path; quiet=true)

    # Should get default TSGROUP1 with name="1", multiplier=52.0
    tg1 = DataFrame(SQLite.DBInterface.execute(db, "SELECT name, multiplier FROM TSGROUP1"))
    !compilation && @test size(tg1, 1) == 1
    !compilation && @test tg1[1, :name] == "1"
    !compilation && @test isapprox(tg1[1, :multiplier], 52.0; atol=0.01)

    # Should get default TSGROUP2 with name="1", multiplier=7.0
    tg2 = DataFrame(SQLite.DBInterface.execute(db, "SELECT name, multiplier FROM TSGROUP2"))
    !compilation && @test size(tg2, 1) == 1
    !compilation && @test tg2[1, :name] == "1"
    !compilation && @test isapprox(tg2[1, :multiplier], 7.0; atol=0.01)

    # LTsGroup: 1 timeslice with defaults tg1="1", tg2="1"
    lts = DataFrame(SQLite.DBInterface.execute(db, "SELECT l, tg1, tg2 FROM LTsGroup"))
    !compilation && @test size(lts, 1) == 1
    !compilation && @test lts[1, :l] == "TS1"
    !compilation && @test lts[1, :tg1] == "1"
    !compilation && @test lts[1, :tg2] == "1"

    finalize(db); db = nothing; GC.gc()
    delete_file(dest_path, 20)
    delete_file(src_path, 20)
end

@testset "Case-insensitive table names" begin
    src_path = joinpath(dbfile_path, "test_osemosys_lcase_src.sqlite")
    dest_path = joinpath(dbfile_path, "test_osemosys_lcase_dest.sqlite")

    _create_lowercase_osemosys_db(src_path)
    db = NemoMod.convert_osemosys(src_path, dest_path; quiet=true)

    regions = DataFrame(SQLite.DBInterface.execute(db, "SELECT val FROM REGION")).val
    !compilation && @test regions == ["R1"]

    techs = DataFrame(SQLite.DBInterface.execute(db, "SELECT val FROM TECHNOLOGY")).val
    !compilation && @test techs == ["TECH1"]

    fuels = DataFrame(SQLite.DBInterface.execute(db, "SELECT val FROM FUEL")).val
    !compilation && @test fuels == ["ELC"]

    finalize(db); db = nothing; GC.gc()
    delete_file(dest_path, 20)
    delete_file(src_path, 20)
end

@testset "Empty parameter tables" begin
    src_path = joinpath(dbfile_path, "test_osemosys_empty_src.sqlite")
    dest_path = joinpath(dbfile_path, "test_osemosys_empty_dest.sqlite")

    # Create DB with empty CapitalCost table
    srcdb_temp = SQLite.DB(src_path)
    SQLite.DBInterface.execute(srcdb_temp, "CREATE TABLE REGION (VALUE TEXT)")
    SQLite.DBInterface.execute(srcdb_temp, "INSERT INTO REGION VALUES ('R1')")
    SQLite.DBInterface.execute(srcdb_temp, "CREATE TABLE TECHNOLOGY (VALUE TEXT)")
    SQLite.DBInterface.execute(srcdb_temp, "INSERT INTO TECHNOLOGY VALUES ('TECH1')")
    SQLite.DBInterface.execute(srcdb_temp, "CREATE TABLE FUEL (VALUE TEXT)")
    SQLite.DBInterface.execute(srcdb_temp, "INSERT INTO FUEL VALUES ('ELC')")
    SQLite.DBInterface.execute(srcdb_temp, "CREATE TABLE EMISSION (VALUE TEXT)")
    SQLite.DBInterface.execute(srcdb_temp, "CREATE TABLE MODE_OF_OPERATION (VALUE TEXT)")
    SQLite.DBInterface.execute(srcdb_temp, "INSERT INTO MODE_OF_OPERATION VALUES ('1')")
    SQLite.DBInterface.execute(srcdb_temp, "CREATE TABLE TIMESLICE (VALUE TEXT)")
    SQLite.DBInterface.execute(srcdb_temp, "INSERT INTO TIMESLICE VALUES ('TS1')")
    SQLite.DBInterface.execute(srcdb_temp, "CREATE TABLE YEAR (VALUE TEXT)")
    SQLite.DBInterface.execute(srcdb_temp, "INSERT INTO YEAR VALUES ('2020')")
    # Empty CapitalCost - exists but has no rows
    SQLite.DBInterface.execute(srcdb_temp, "CREATE TABLE CapitalCost (REGION TEXT, TECHNOLOGY TEXT, YEAR TEXT, VALUE REAL)")
    DBInterface.close!(srcdb_temp)

    db = NemoMod.convert_osemosys(src_path, dest_path; quiet=true)

    cc = DataFrame(SQLite.DBInterface.execute(db, "SELECT * FROM CapitalCost"))
    !compilation && @test size(cc, 1) == 0

    finalize(db); db = nothing; GC.gc()
    delete_file(dest_path, 20)
    delete_file(src_path, 20)
end

@testset "TradeRoute with missing columns" begin
    src_path = joinpath(dbfile_path, "test_osemosys_tr_src.sqlite")
    dest_path = joinpath(dbfile_path, "test_osemosys_tr_dest.sqlite")

    srcdb_temp = SQLite.DB(src_path)
    SQLite.DBInterface.execute(srcdb_temp, "CREATE TABLE REGION (VALUE TEXT)")
    SQLite.DBInterface.execute(srcdb_temp, "INSERT INTO REGION VALUES ('R1')")
    SQLite.DBInterface.execute(srcdb_temp, "CREATE TABLE TECHNOLOGY (VALUE TEXT)")
    SQLite.DBInterface.execute(srcdb_temp, "INSERT INTO TECHNOLOGY VALUES ('TECH1')")
    SQLite.DBInterface.execute(srcdb_temp, "CREATE TABLE FUEL (VALUE TEXT)")
    SQLite.DBInterface.execute(srcdb_temp, "INSERT INTO FUEL VALUES ('ELC')")
    SQLite.DBInterface.execute(srcdb_temp, "CREATE TABLE EMISSION (VALUE TEXT)")
    SQLite.DBInterface.execute(srcdb_temp, "CREATE TABLE MODE_OF_OPERATION (VALUE TEXT)")
    SQLite.DBInterface.execute(srcdb_temp, "INSERT INTO MODE_OF_OPERATION VALUES ('1')")
    SQLite.DBInterface.execute(srcdb_temp, "CREATE TABLE TIMESLICE (VALUE TEXT)")
    SQLite.DBInterface.execute(srcdb_temp, "INSERT INTO TIMESLICE VALUES ('TS1')")
    SQLite.DBInterface.execute(srcdb_temp, "CREATE TABLE YEAR (VALUE TEXT)")
    SQLite.DBInterface.execute(srcdb_temp, "INSERT INTO YEAR VALUES ('2020')")
    # TradeRoute with missing FUEL column — should skip gracefully
    SQLite.DBInterface.execute(srcdb_temp, "CREATE TABLE TradeRoute (REGION TEXT, rr TEXT, YEAR TEXT, VALUE REAL)")
    SQLite.DBInterface.execute(srcdb_temp, "INSERT INTO TradeRoute VALUES ('R1', 'R1', '2020', 1.0)")
    DBInterface.close!(srcdb_temp)

    db = NemoMod.convert_osemosys(src_path, dest_path; quiet=true)

    tr = DataFrame(SQLite.DBInterface.execute(db, "SELECT * FROM TradeRoute"))
    !compilation && @test size(tr, 1) == 0  # skipped due to missing column

    finalize(db); db = nothing; GC.gc()
    delete_file(dest_path, 20)
    delete_file(src_path, 20)
end

@testset "Lowercase column names" begin
    src_path = joinpath(dbfile_path, "test_osemosys_lcol_src.sqlite")
    dest_path = joinpath(dbfile_path, "test_osemosys_lcol_dest.sqlite")

    srcdb_temp = SQLite.DB(src_path)
    SQLite.DBInterface.execute(srcdb_temp, "CREATE TABLE region (value TEXT)")
    SQLite.DBInterface.execute(srcdb_temp, "INSERT INTO region VALUES ('R1')")
    SQLite.DBInterface.execute(srcdb_temp, "CREATE TABLE technology (value TEXT)")
    SQLite.DBInterface.execute(srcdb_temp, "INSERT INTO technology VALUES ('TECH1')")
    SQLite.DBInterface.execute(srcdb_temp, "CREATE TABLE fuel (value TEXT)")
    SQLite.DBInterface.execute(srcdb_temp, "INSERT INTO fuel VALUES ('ELC')")
    SQLite.DBInterface.execute(srcdb_temp, "CREATE TABLE emission (value TEXT)")
    SQLite.DBInterface.execute(srcdb_temp, "INSERT INTO emission VALUES ('CO2')")
    SQLite.DBInterface.execute(srcdb_temp, "CREATE TABLE mode_of_operation (value TEXT)")
    SQLite.DBInterface.execute(srcdb_temp, "INSERT INTO mode_of_operation VALUES ('1')")
    SQLite.DBInterface.execute(srcdb_temp, "CREATE TABLE timeslice (value TEXT)")
    SQLite.DBInterface.execute(srcdb_temp, "INSERT INTO timeslice VALUES ('TS1')")
    SQLite.DBInterface.execute(srcdb_temp, "CREATE TABLE year (value TEXT)")
    SQLite.DBInterface.execute(srcdb_temp, "INSERT INTO year VALUES ('2020')")
    # Lowercase column names in parameter table
    SQLite.DBInterface.execute(srcdb_temp, "CREATE TABLE capitalcost (region TEXT, technology TEXT, year TEXT, value REAL)")
    SQLite.DBInterface.execute(srcdb_temp, "INSERT INTO capitalcost VALUES ('R1', 'TECH1', '2020', 500.0)")
    DBInterface.close!(srcdb_temp)

    db = NemoMod.convert_osemosys(src_path, dest_path; quiet=true)

    cc = DataFrame(SQLite.DBInterface.execute(db, "SELECT r, t, y, val FROM CapitalCost"))
    !compilation && @test size(cc, 1) == 1
    !compilation && @test cc[1, :r] == "R1"
    !compilation && @test isapprox(cc[1, :val], 500.0; atol=0.01)

    finalize(db); db = nothing; GC.gc()
    delete_file(dest_path, 20)
    delete_file(src_path, 20)
end

# ---- Error handling ----
@testset "Error handling" begin
    # Invalid source path
    !compilation && @test_throws ErrorException NemoMod.convert_osemosys(
        joinpath(dbfile_path, "nonexistent.sqlite"),
        joinpath(dbfile_path, "test_err_dest.sqlite");
        quiet=true)

    # CSV directory without config_path
    test_dir = joinpath(dbfile_path, "test_csv_dir")
    mkdir(test_dir)
    !compilation && @test_throws ErrorException NemoMod.convert_osemosys(
        test_dir,
        joinpath(dbfile_path, "test_err_dest.sqlite");
        quiet=true)
    rm(test_dir)

    # CSV directory with nonexistent config_path
    test_dir2 = joinpath(dbfile_path, "test_csv_dir2")
    mkdir(test_dir2)
    !compilation && @test_throws ErrorException NemoMod.convert_osemosys(
        test_dir2,
        joinpath(dbfile_path, "test_err_dest2.sqlite");
        quiet=true,
        config_path="/nonexistent/config.yaml")
    rm(test_dir2)

    # Clean up any dest files that might have been partially created
    delete_file(joinpath(dbfile_path, "test_err_dest.sqlite"), 5)
    delete_file(joinpath(dbfile_path, "test_err_dest2.sqlite"), 5)
end
