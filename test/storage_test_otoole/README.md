# storage_test_otoole

OSeMOSYS [otoole](https://github.com/OSeMOSYS/otoole)-format CSV equivalent of
NemoMod's `test/storage_test.sqlite` example dataset. Used by the roundtrip
testset in `test/osemosys_converter_tests.jl` to exercise the CSV-directory
input path of `NemoMod.convert_osemosys`.

## Model summary

A single-region, 10-year (2020–2029), 96-timeslice model with one battery:

- 1 region (`1`)
- 3 fuels: `electricity`, `gas`, `solar`
- 5 technologies: `gas`, `solar`, `gassupply`, `solarsupply`, `storage1`
- 1 storage facility (`storage1`)
- 96 timeslices: `{summer,winter}{wd,we}{0..23}` — summer/winter × weekday/weekend × 24 hourly brackets
- Annual electricity demand of 31.536 (per region, per year)

## Differences from `storage_test.sqlite`

These are deliberate adaptations to fit the standard OSeMOSYS schema. They are
the only places where the roundtrip through `NemoMod.convert_osemosys` will not
reproduce the original byte-for-byte:

- **`MODE_OF_OPERATION`** — NemoMod uses the strings `generate` and `store`;
  this dataset integerizes them to `1` (generate) and `2` (store) as is
  conventional in OSeMOSYS. Mode references in `InputActivityRatio`,
  `OutputActivityRatio`, `VariableCost`, `TechnologyToStorage`, and
  `TechnologyFromStorage` are updated accordingly.
- **`StorageFullLoadHours` is dropped.** This is a NemoMod-specific extension
  that constrains storage energy capacity to a multiple of the connected
  technology's power capacity. There is no direct OSeMOSYS equivalent, so it
  is omitted. After roundtripping back to NemoMod the resulting database will
  have an empty `StorageFullLoadHours` table.
- **Time slicing is reshaped.** NemoMod's `TSGROUP1`/`TSGROUP2`/`LTsGroup`
  hierarchy becomes the standard OSeMOSYS `SEASON` + `DAYTYPE` +
  `DAILYTIMEBRACKET` triple plus `Conversionls`/`Conversionld`/`Conversionlh`
  and `DaysInDayType`/`DaySplit`/`YearSplit`. The original `YearSplit` values
  are preserved verbatim.
- **`AvailabilityFactor` (NemoMod 4D) → `CapacityFactor` (OSeMOSYS 4D).**
  NemoMod stores the hourly availability profile in `AvailabilityFactor`
  (dimensioned by region, technology, timeslice, year). OSeMOSYS uses
  `CapacityFactor` for that purpose and reserves `AvailabilityFactor` for an
  annual-average value (3D). The solar profile from the source therefore
  ships as `CapacityFactor.csv`. On import the converter will repopulate
  NemoMod's `AvailabilityFactor` from `CapacityFactor`.
- **`ReserveMargin` is reduced from NemoMod's 3D form (region, fuel, year) to
  OSeMOSYS's 2D form (region, year)**, with the implicit fuel assignment moved
  into `ReserveMarginTagFuel.csv`. Likewise, `ReserveMarginTagTechnology` is
  reduced from NemoMod's 4D form (region, technology, fuel, year) to OSeMOSYS's
  3D form (region, technology, year). All entries reference the
  `electricity` fuel.
- **`STORAGE.netzeroyear`** — the original DB has `0`; on roundtrip the
  converter will set this to `1` because that field is hardcoded in
  `_convert_osemosys_sets!`. The other `netzero*` flags are unchanged.
- **`TSGROUP1`/`TSGROUP2` ordering and descriptions** — when the converter
  rebuilds these tables it sorts season and day-type names alphabetically and
  uses generic descriptions (`"Season summer"`, `"Day type weekday"`, …).
  This affects the `[order]` and `desc` columns only; the `name` and
  `multiplier` values match the original.

All other parameters and dimension members roundtrip exactly.

## Defaults

`config.yaml` carries default values for every parameter in the dataset. The
defaults are taken from the `DefaultParams` table of `storage_test.sqlite` so
that the converted NemoMod database keeps the same fallback behaviour as the
original.

## Converting back to NemoMod

```julia
using NemoMod
NemoMod.convert_osemosys(
    joinpath(@__DIR__, "storage_test_otoole"),
    "storage_test_roundtrip.sqlite";
    config_path = joinpath(@__DIR__, "storage_test_otoole", "config.yaml"),
)
```

When invoked on a CSV directory, `convert_osemosys` shells out to
`otoole convert csv sqlite ...` to build a temporary OSeMOSYS SQLite database,
then populates the NemoMod schema from it. This requires an
[otoole](https://github.com/OSeMOSYS/otoole) version that still ships the
SQLite backend (the SQLite target was removed in otoole 1.0). The roundtrip
testset in `test/osemosys_converter_tests.jl` does not depend on otoole at
all — it loads these CSVs into a temporary OSeMOSYS-format SQLite directly
and feeds that to `convert_osemosys` via its SQLite-input path, exercising
the same data-handling code regardless of the installed otoole version.
