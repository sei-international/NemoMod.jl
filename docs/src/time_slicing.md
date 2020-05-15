```@meta
CurrentModule = NemoMod
```
# [Time slicing](@id time_slicing)

NEMO provides a flexible mechanism for dividing [years](@ref year) into sub-annual periods and modeling energy demand and supply in those periods. This approach can allow a more realistic simulation of [fuels](@ref fuel) for which the timing of demand and supply is critical (e.g., electricity). The subannual periods are called [time slices](@ref timeslice), and they're one of several [dimensions](@ref dimensions) in a NEMO model.

## Time slice widths

The width of time slices as a fraction of a year is set with the [`YearSplit`](@ref YearSplit) [parameter](@ref parameters). Within a given year, the sum of all time slice widths should be 1.

## Enabling time-sliced modeling of a fuel

You can specify whether the modeling of a fuel is time-sliced through NEMO's demand parameters. If you define a demand with [`AccumulatedAnnualDemand`](@ref AccumulatedAnnualDemand), NEMO will model it at the annual level - that is, it will assume the demand must be met in the indicated year, but the timing of supply within the year doesn't matter. Conversely, if you set up a demand with [`SpecifiedAnnualDemand`](@ref SpecifiedAnnualDemand) and [`SpecifiedDemandProfile`](@ref SpecifiedDemandProfile), the demand is assigned to particular time slices and must be fulfilled in those slices.

## Storage and time slice grouping

Time-sliced modeling is also crucial for simulating energy [storage](@ref storage). In this case, both the width and the *chronology, or ordering,* of time slices are important. Chronology counts because the energy available in storage depends on the sequencing of prior charging and discharging.

NEMO addresses the issue of chronology by using three parameters to translate from time slices to an ordered set of hours within a year: [`TSGROUP1`](@ref tsgroup1), [`TSGROUP2`](@ref tsgroup2), and [`LTsGroup`](@ref LTsGroup). `TSGROUP1` and `TSGROUP2` are hierarchical groupings of time slices, and `LTsGroup` assigns slices to `TSGroup1` and `TSGroup2`.

* `TSGROUP1` - These groups are nested within years - i.e., they are major divisions of a year, such as seasons or months. The `order` field of `TSGROUP1` defines their chronological order. The first `TSGROUP1` in a year should have an `order` of 1, and the `order` should be incremented by 1 for each subsequent group.

* `TSGROUP2` - These groups are nested within `TSGROUP1`. They represent divisions of `TSGROUP1` such as days of the week. `TSGROUP2` also has an `order` field to define the chronological order within each `TSGROUP1`. The first `TSGROUP2` should have an `order` of 1, and the `order` should be incremented by 1 for each subsequent group.

* `LTsGroup` - This parameter maps time slices to `TSGROUP1` and `TSGROUP2`. To enable storage modeling in NEMO, you must use `LTsGroup` to assign each time slice to one `TSGROUP2` within one `TSGROUP1`. The `lorder` field defines the ordering of time slices within each combination of `TSGROUP1` and `TSGROUP2` (e.g., for a month and day of the week).

`TSGROUP1` and `TSGROUP2` also have a `multiplier` attribute that NEMO uses when constructing an ordered set of hours within a year. The application of the multipliers rests on an essential characteristic of NEMO: for any storage, the rate of net charging is constant within a time slice (i.e., over all hours of the time slice).[^1] This design allows NEMO to build up a set of ordered hours from the group and timeslice orders and the group multipliers. In plain language, the process is as follows.

1. Start with the first `TSGROUP1` and the first `TSGROUP2` within it.
2. Take the first hour of each time slice in the `TSGROUP1` and `TSGROUP2` (in the order specified in `LTsGroup`).
3. Assume this block of hours repeats `TSGROUP2.multiplier` times.
4. Move to the next `TSGROUP2` within the `TSGROUP1`, and repeat steps 2-3. Continue through all `TSGROUP2` within the `TSGROUP1`.
5. Assume the set of hours constructed in steps 1-4 repeats `TSGROUP1.multiplier` times.
6. Repeat the preceding steps for each subsequent `TSGROUP1`.

This approach means the following identity should hold.

``\sum^{tg1}[\sum^{tg2}[[\sum^{l_{tg1,tg2}}1] \times multiplier_{tg2}] \times multiplier_{tg1}] = 8760``

The multipliers for `TSGROUP1` and `TSGROUP2` should be set accordingly. For example, suppose that:

* `TSGROUP1` represents two seasons (each covering half of the year).
* `TSGROUP2` represents weekend and weekday periods (in a calendar with two-day weekends).
* There are 96 time slices, representing the 24 hours of a weekday and the 24 hours of a weekend day in each season.

In this case, the multiplier for the weekend period should be 2, the multiplier for the weekday period should be 5, and the multiplier for each season should be ``\frac{8760}{2 \times 7 \times 24}`` ≈ 26.07.

[^1]: This principle also holds for energy production, consumption, and demand, when time-sliced: the rate at which each of these occurs does not vary within a time slice.
