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

    # Source DB missing a required dimension table (TECHNOLOGY) must error
    # *before* the destination NemoMod DB is created, so no stale file is left behind.
    incomplete_src = joinpath(dbfile_path, "test_incomplete_src.sqlite")
    incomplete_dest = joinpath(dbfile_path, "test_incomplete_dest.sqlite")
    delete_file(incomplete_src, 5)
    delete_file(incomplete_dest, 5)

    let db = SQLite.DB(incomplete_src)
        # Every required dimension except TECHNOLOGY
        SQLite.DBInterface.execute(db, "CREATE TABLE REGION (VALUE TEXT)")
        SQLite.DBInterface.execute(db, "CREATE TABLE FUEL (VALUE TEXT)")
        SQLite.DBInterface.execute(db, "CREATE TABLE YEAR (VALUE TEXT)")
        SQLite.DBInterface.execute(db, "CREATE TABLE TIMESLICE (VALUE TEXT)")
        SQLite.DBInterface.execute(db, "CREATE TABLE MODE_OF_OPERATION (VALUE TEXT)")
        DBInterface.close!(db)
    end

    !compilation && @test_throws ErrorException NemoMod.convert_osemosys(
        incomplete_src, incomplete_dest; quiet=true)
    !compilation && @test !isfile(incomplete_dest)

    delete_file(incomplete_src, 5)

    # Clean up any dest files that might have been partially created
    delete_file(joinpath(dbfile_path, "test_err_dest.sqlite"), 5)
    delete_file(joinpath(dbfile_path, "test_err_dest2.sqlite"), 5)
end

# ---- Roundtrip: storage_test_otoole CSV fixture -> NemoMod ----
# End-to-end exercise of the production CSV-input path of convert_osemosys
# against the storage_test_otoole/ fixture (35 otoole-format CSVs + config.yaml).
# The fixture is a faithful otoole representation of storage_test.sqlite (with
# the documented adaptations in test/storage_test_otoole/README.md), so the
# resulting NemoMod database should match the original modulo those documented
# differences. This testset covers _parse_otoole_config and
# _load_csv_directory_to_sqlite! as well as the entire downstream
# OSeMOSYS->NemoMod converter pipeline.

@testset "storage_test_otoole CSV roundtrip" begin
    otoole_dir = joinpath(dbfile_path, "storage_test_otoole")
    orig_path = joinpath(dbfile_path, "storage_test.sqlite")
    config_path = joinpath(otoole_dir, "config.yaml")
    dest_path = joinpath(dbfile_path, "storage_test_otoole_dest.sqlite")
    delete_file(dest_path, 5)

    destdb_rt = NemoMod.convert_osemosys(otoole_dir, dest_path;
        config_path=config_path, quiet=true)
    origdb_rt = SQLite.DB(orig_path)

    # ---- Sets ----
    for (s, expected) in [
        ("REGION", ["1"]),
        ("YEAR", string.(2020:2029)),
        ("FUEL", ["electricity", "gas", "solar"]),
        ("TECHNOLOGY", ["gas", "gassupply", "solar", "solarsupply", "storage1"]),
        ("MODE_OF_OPERATION", ["1", "2"]),  # integerized vs original 'generate'/'store'
    ]
        vals = sort(DataFrame(SQLite.DBInterface.execute(destdb_rt, "SELECT val FROM $(s)")).val)
        !compilation && @test vals == expected
    end

    # STORAGE: name and netzero* flags. netzeroyear is hardcoded to 1 by the
    # converter even though the original DB has 0; the other flags match.
    storage_df_rt = DataFrame(SQLite.DBInterface.execute(destdb_rt,
        "SELECT val, netzeroyear, netzerotg1, netzerotg2 FROM STORAGE"))
    !compilation && @test size(storage_df_rt, 1) == 1
    !compilation && @test storage_df_rt[1, :val] == "storage1"
    !compilation && @test storage_df_rt[1, :netzeroyear] == 1
    !compilation && @test storage_df_rt[1, :netzerotg1] == 0
    !compilation && @test storage_df_rt[1, :netzerotg2] == 0

    # ---- Time slicing: TSGROUP1 / TSGROUP2 ----
    # Only the (name, multiplier) pairs are compared; the converter
    # reorders alphabetically and uses generic descriptions.
    tg1_rt = DataFrame(SQLite.DBInterface.execute(destdb_rt,
        "SELECT name, multiplier FROM TSGROUP1 ORDER BY name"))
    !compilation && @test size(tg1_rt, 1) == 2
    !compilation && @test sort(tg1_rt.name) == ["summer", "winter"]
    for row in eachrow(tg1_rt)
        !compilation && @test isapprox(row.multiplier, 26.0714; atol=0.01)
    end

    tg2_rt = DataFrame(SQLite.DBInterface.execute(destdb_rt,
        "SELECT name, multiplier FROM TSGROUP2 ORDER BY name"))
    !compilation && @test size(tg2_rt, 1) == 2
    !compilation && @test sort(tg2_rt.name) == ["weekday", "weekend"]
    wd = filter(r -> r.name == "weekday", tg2_rt)
    we = filter(r -> r.name == "weekend", tg2_rt)
    !compilation && @test isapprox(wd[1, :multiplier], 5.0; atol=0.01)
    !compilation && @test isapprox(we[1, :multiplier], 2.0; atol=0.01)

    # LTsGroup: every NemoMod row should reappear identically.
    lts_rt = DataFrame(SQLite.DBInterface.execute(destdb_rt,
        "SELECT l, lorder, tg1, tg2 FROM LTsGroup ORDER BY l"))
    lts_orig = DataFrame(SQLite.DBInterface.execute(origdb_rt,
        "SELECT l, lorder, tg1, tg2 FROM LTsGroup ORDER BY l"))
    !compilation && @test size(lts_rt, 1) == size(lts_orig, 1) == 96
    !compilation && @test lts_rt == lts_orig

    # ---- Direct-copy parameters: row counts and key values ----
    # Helper: row count of a destination table.
    ncount(tbl) = DataFrame(SQLite.DBInterface.execute(destdb_rt,
        "SELECT COUNT(*) AS n FROM $(tbl)"))[1, :n]

    for (tbl, expected_n) in [
        ("CapitalCost", 20),
        ("CapitalCostStorage", 10),
        ("OperationalLife", 5),
        ("OperationalLifeStorage", 1),
        ("InputActivityRatio", 30),
        ("OutputActivityRatio", 50),
        ("VariableCost", 30),
        ("SpecifiedAnnualDemand", 10),
        ("SpecifiedDemandProfile", 960),
        ("ResidualStorageCapacity", 10),
        ("StorageLevelStart", 1),
        ("TechnologyToStorage", 1),
        ("TechnologyFromStorage", 1),
        ("AvailabilityFactor", 960),  # repopulated from CapacityFactor.csv
        ("YearSplit", 960),
    ]
        !compilation && @test ncount(tbl) == expected_n
    end

    # StorageFullLoadHours is dropped on export and should be empty.
    !compilation && @test ncount("StorageFullLoadHours") == 0

    # Spot-check specific values (mode strings are integerized).
    cc_gas = DataFrame(SQLite.DBInterface.execute(destdb_rt,
        "SELECT val FROM CapitalCost WHERE r='1' AND t='gas' AND y='2020'"))
    !compilation && @test isapprox(cc_gas[1, :val], 1000.0; atol=0.01)

    cc_solar = DataFrame(SQLite.DBInterface.execute(destdb_rt,
        "SELECT val FROM CapitalCost WHERE r='1' AND t='solar' AND y='2025'"))
    !compilation && @test isapprox(cc_solar[1, :val], 2000.0; atol=0.01)

    iar_storage = DataFrame(SQLite.DBInterface.execute(destdb_rt,
        "SELECT m, val FROM InputActivityRatio WHERE r='1' AND t='storage1' AND f='electricity' AND y='2020'"))
    !compilation && @test size(iar_storage, 1) == 1
    !compilation && @test iar_storage[1, :m] == "2"  # 'store' -> 2
    !compilation && @test isapprox(iar_storage[1, :val], 1.25; atol=0.001)

    oar_gas = DataFrame(SQLite.DBInterface.execute(destdb_rt,
        "SELECT m, val FROM OutputActivityRatio WHERE r='1' AND t='gas' AND f='electricity' AND y='2020'"))
    !compilation && @test oar_gas[1, :m] == "1"  # 'generate' -> 1
    !compilation && @test isapprox(oar_gas[1, :val], 1.0; atol=0.01)

    tts = DataFrame(SQLite.DBInterface.execute(destdb_rt,
        "SELECT m, val FROM TechnologyToStorage"))
    !compilation && @test tts[1, :m] == "2"
    !compilation && @test isapprox(tts[1, :val], 1.0; atol=0.01)

    tfs = DataFrame(SQLite.DBInterface.execute(destdb_rt,
        "SELECT m, val FROM TechnologyFromStorage"))
    !compilation && @test tfs[1, :m] == "1"
    !compilation && @test isapprox(tfs[1, :val], 1.0; atol=0.01)

    sad = DataFrame(SQLite.DBInterface.execute(destdb_rt,
        "SELECT val FROM SpecifiedAnnualDemand WHERE r='1' AND f='electricity' AND y='2020'"))
    !compilation && @test isapprox(sad[1, :val], 31.536; atol=0.001)

    # AvailabilityFactor: repopulated only for solar (gas/storage1 etc. fall back to default 1.0)
    af_solar = DataFrame(SQLite.DBInterface.execute(destdb_rt,
        "SELECT COUNT(*) AS n FROM AvailabilityFactor WHERE t='solar'"))
    !compilation && @test af_solar[1, :n] == 960

    # ---- ReserveMargin: NemoMod 3D form is rebuilt from 2D + ReserveMarginTagFuel ----
    rm_rt = DataFrame(SQLite.DBInterface.execute(destdb_rt,
        "SELECT r, f, y, val FROM ReserveMargin ORDER BY y"))
    !compilation && @test size(rm_rt, 1) == 10
    !compilation && @test all(rm_rt.f .== "electricity")
    !compilation && @test all(isapprox.(rm_rt.val, 1.25; atol=0.01))

    rmtt_rt = DataFrame(SQLite.DBInterface.execute(destdb_rt,
        "SELECT t, f, val FROM ReserveMarginTagTechnology WHERE y='2020' ORDER BY t"))
    !compilation && @test size(rmtt_rt, 1) == 3
    !compilation && @test all(rmtt_rt.f .== "electricity")
    rmtt_vals = Dict(rmtt_rt.t .=> rmtt_rt.val)
    !compilation && @test isapprox(rmtt_vals["gas"], 1.0; atol=0.01)
    !compilation && @test isapprox(rmtt_vals["solar"], 0.5; atol=0.01)
    !compilation && @test isapprox(rmtt_vals["storage1"], 0.5; atol=0.01)

    # Clean up
    finalize(destdb_rt); destdb_rt = nothing
    finalize(origdb_rt); origdb_rt = nothing
    GC.gc()
    delete_file(dest_path, 20)
    !compilation && @test !isfile(dest_path)
end

# ---- Edge cases for the native CSV directory loader ----
# Direct unit tests of NemoMod._load_csv_directory_to_sqlite! against synthetic
# CSV directories. These cover behaviors the storage_test_otoole roundtrip does
# not exercise because that fixture is rectangular and well-formed.
@testset "CSV directory loader edge cases" begin

    @testset "Quoted fields with commas" begin
        td = mktempdir()
        try
            write(joinpath(td, "config.yaml"), """
            FOO:
              dtype: str
              type: set
            """)
            write(joinpath(td, "FOO.csv"), "VALUE\n\"foo,bar\"\nbaz\n")

            cfg = NemoMod._parse_otoole_config(joinpath(td, "config.yaml"))
            sqlite_path = joinpath(td, "out.sqlite")
            NemoMod._load_csv_directory_to_sqlite!(td, sqlite_path, cfg)

            db = SQLite.DB(sqlite_path)
            df = DataFrame(SQLite.DBInterface.execute(db, "SELECT VALUE FROM FOO"))
            DBInterface.close!(db)

            !compilation && @test size(df, 1) == 2
            !compilation && @test sort(string.(df.VALUE)) == ["baz", "foo,bar"]
        finally
            rm(td; recursive=true, force=true)
        end
    end

    @testset "Ragged rows" begin
        td = mktempdir()
        try
            write(joinpath(td, "config.yaml"), """
            REGION:
              dtype: str
              type: set
            TECHNOLOGY:
              dtype: str
              type: set
            YEAR:
              dtype: int
              type: set
            CapitalCost:
              dtype: float
              type: param
              indices: [REGION, TECHNOLOGY, YEAR]
              default: 0
            """)
            # Header has 4 columns, second body row only has 3 → ragged
            write(joinpath(td, "CapitalCost.csv"),
                "REGION,TECHNOLOGY,YEAR,VALUE\n1,gas,2020,1000.0\n1,solar,2021\n")

            cfg = NemoMod._parse_otoole_config(joinpath(td, "config.yaml"))
            sqlite_path = joinpath(td, "out.sqlite")

            !compilation && @test_throws ErrorException NemoMod._load_csv_directory_to_sqlite!(td, sqlite_path, cfg)
            !compilation && @test !isfile(sqlite_path)  # cleanup on error
        finally
            rm(td; recursive=true, force=true)
        end
    end

    @testset "Empty and header-only files" begin
        td = mktempdir()
        try
            write(joinpath(td, "config.yaml"), """
            REGION:
              dtype: str
              type: set
            FOO:
              dtype: str
              type: set
            """)
            write(joinpath(td, "REGION.csv"), "")          # empty (0 bytes)
            write(joinpath(td, "FOO.csv"), "VALUE\n")       # header-only

            cfg = NemoMod._parse_otoole_config(joinpath(td, "config.yaml"))
            sqlite_path = joinpath(td, "out.sqlite")
            NemoMod._load_csv_directory_to_sqlite!(td, sqlite_path, cfg)

            db = SQLite.DB(sqlite_path)
            tables = sort(DataFrame(SQLite.DBInterface.execute(db,
                "SELECT name FROM sqlite_master WHERE type='table' ORDER BY name")).name)
            n_region = DataFrame(SQLite.DBInterface.execute(db, "SELECT COUNT(*) AS n FROM REGION"))[1, :n]
            n_foo = DataFrame(SQLite.DBInterface.execute(db, "SELECT COUNT(*) AS n FROM FOO"))[1, :n]
            DBInterface.close!(db)

            # Both tables should exist (created from config) but be empty
            !compilation && @test "REGION" in tables
            !compilation && @test "FOO" in tables
            !compilation && @test n_region == 0
            !compilation && @test n_foo == 0
        finally
            rm(td; recursive=true, force=true)
        end
    end

    @testset "Subdirectories and non-CSV files ignored" begin
        td = mktempdir()
        try
            write(joinpath(td, "config.yaml"), """
            FOO:
              dtype: str
              type: set
            """)
            write(joinpath(td, "FOO.csv"), "VALUE\nalpha\n")
            write(joinpath(td, "README.md"), "notes")
            write(joinpath(td, "notes.txt"), "more notes")
            mkdir(joinpath(td, "subdir"))
            write(joinpath(td, "subdir", "ignored.csv"), "VALUE\n999\n")

            cfg = NemoMod._parse_otoole_config(joinpath(td, "config.yaml"))
            sqlite_path = joinpath(td, "out.sqlite")
            NemoMod._load_csv_directory_to_sqlite!(td, sqlite_path, cfg)

            db = SQLite.DB(sqlite_path)
            tables = sort(DataFrame(SQLite.DBInterface.execute(db,
                "SELECT name FROM sqlite_master WHERE type='table' ORDER BY name")).name)
            foo_vals = DataFrame(SQLite.DBInterface.execute(db, "SELECT VALUE FROM FOO")).VALUE
            DBInterface.close!(db)

            !compilation && @test tables == ["FOO"]
            !compilation && @test string.(foo_vals) == ["alpha"]
        finally
            rm(td; recursive=true, force=true)
        end
    end
end
