```@meta
CurrentModule = NemoMod
```
# [Release notes](@id release_notes)

This page highlights key changes in NEMO since its initial public release. For a full history of NEMO releases, including the code for each version, see the [Releases page on NEMO's GitHub site](https://github.com/sei-international/NemoMod.jl/releases).

## Version 1.2

  * **Ramp rates:** Added support for modeling technology ramp rates. You can activate this feature with two new parameters - [`RampRate`](@ref RampRate) and [`RampingReset`](@ref RampingReset).

  * **Parallel processing upgrades:** Revised [`calculatescenario`](@ref) so users can take advantage of parallelization without having to invoke Julia's `Distributed` package and add processes manually. Introduced the `numprocs` argument, which lets users specify the number of processes to use for parallelized operations. When `numprocs` is set, NEMO initializes new processes as needed. Refactored the queries in `calculatescenario` to parallelize as many of them as possible.

  * **Xpress solver:** Added Xpress as an officially supported NEMO solver. This includes incorporating Xpress in the Julia system image that's distributed with the [NEMO installer program](@ref installer_program).

  * **Installer program enhancements:** Upgraded the installer program to facilitate installation when the executing user isn't an operating system administrator. Also improved the integration of the installer program with LEAP.

  * **General error handling in `calculatescenario`:** Restructured `calculatescenario` so exceptions are trapped and presented along with information on how to report problems to the NEMO team.

  * **Other changes:** Streamlined NEMO's logic for upgrading legacy database versions in `calculatescenario`. Now the functions that perform upgrades are only called when needed. Removed the `createnemodb_leap` function since LEAP isn't using it.
