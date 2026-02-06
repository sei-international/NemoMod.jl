```@meta
CurrentModule = NemoMod
```
# [Release notes](@id release_notes)

This page highlights key changes in NEMO since its initial public release. For a full history of NEMO releases, including the code for each version, see the [Releases page on NEMO's GitHub site](https://github.com/sei-international/NemoMod.jl/releases).

## Version 2.3

  * **Julia platform upgrade:** Updated NEMO to use Julia 1.12.4 and the latest releases of various Julia packages, including JuMP and solver wrappers. This change adds support for the most recent versions of several solvers, among them Gurobi 13, HiGHS 1.13, Mosek 11, and Xpress 9.8.

## Version 2.2

  * **Limited foresight optimization:** Enabled limited foresight optimization - see [Perfect foresight vs. limited foresight](@ref foresight) for details.

  * **Unit of measure conversions:** Added a function for converting units of measure in scenario databases ([`convertscenariounits`](@ref convertscenariounits)). 

  * **Tool for finding sources of infeasibility:** Provided a way to identify constraints that cause a NEMO model to be infeasible. See [`Troubleshooting infeasibility`](@ref infeasibility) for more information.

  * **Full error tracing when calculating a scenario:** Added a `traperrors` argument to [`calculatescenario`](@ref scenario_calc). By default, `traperrors` is `true`, which means any errors in `calculatescenario` are caught and communicated in a standard error message. The message contains an abbreviated description of the underlying problem and directs users to report the problem to the NEMO team. If `traperrors` is `false`, errors are not caught, and Julia reports them with full error tracing.

  * **Other changes:** Removed the `numprocs` and `targetprocs` arguments for `calculatescenario`. Fixed a bug that was preventing NEMO from properly applying [default values](@ref DefaultParams) for the [ReserveMargin](@ref ReserveMargin) parameter. Removed the `writescenariomodel` function (to write the optimization problem for a scenario, use `calculatescenario` with the `writefilename` and `writefileformat` arguments).

## Version 2.1

  * **Enabled model period technology activity limits when calculating selected years:** Revised NEMO to allow the use of model period technology activity limits ([`TotalTechnologyModelPeriodActivityUpperLimit`](@ref TotalTechnologyModelPeriodActivityUpperLimit) and [`TotalTechnologyModelPeriodActivityLowerLimit`](@ref TotalTechnologyModelPeriodActivityLowerLimit)) when calculating selected years. See [Calculating selected years](@ref selected_years) for details.

  * **Enabled model period emission limits when calculating selected years:** Revised NEMO to allow the use of model period emission limits ([`ModelPeriodEmissionLimit`](@ref ModelPeriodEmissionLimit)) when calculating selected years. See [Calculating selected years](@ref selected_years) for details.

  * **Minimum and maximum annual transmission between nodes:** Added two parameters, [`MinAnnualTransmissionNodes`](@ref MinAnnualTransmissionNodes) and [`MaxAnnualTransmissionNodes`](@ref MaxAnnualTransmissionNodes), that allow you to specify the minimum and maximum amount of a fuel transmitted from one node to another in a year (i.e., delivered to the receiving node via transmission from the sending node). Among other things, these parameters can be used to recreate historical transmission and simulate power purchase agreements.

  * **Use of nodal fuels by non-nodal technologies:** Updated NEMO so technologies that are not simulated at the nodal level (i.e., that are not assigned to nodes in [`NodalDistributionTechnologyCapacity`](@ref NodalDistributionTechnologyCapacity)) can use fuels for which [transmission modeling is enabled](@ref TransmissionModelingEnabled). Any such use is distributed to nodes using [`NodalDistributionDemand`](@ref NodalDistributionDemand) and is reflected in the following variables: [vrateofusebytechnologybymodenn](@ref vrateofusebytechnologybymodenn), [vrateofusebytechnologynn](@ref vrateofusebytechnologynn), [vrateofusenn](@ref vrateofusenn), [vusenn](@ref vusenn), [vuseannualnn](@ref vuseannualnn), [vrateofuse](@ref vrateofuse), [vusebytechnology](@ref vusebytechnology), and [vusebytechnologyannual](@ref vusebytechnologyannual).

!!! note
    This enhancement is necessary for compatibility with LEAP versions 2024.1.0.1 and higher. If you are using NEMO with LEAP 2024.1.0.1 or higher, you should upgrade to NEMO 2.1.
  
## Version 2.0

  * **Julia platform upgrade:** Updated NEMO to use Julia 1.9.3 and newer releases of the Julia packages for the Cbc, CPLEX, GLPK, Gurobi, HiGHS, Mosek, and Xpress solvers. These packages add support for new versions of several solvers, including Gurobi 10.0 and 11.0, HiGHS 1.6, and Mosek 10.1.

  * **Fuel-specific reserve margins:** Refactored NEMO's reserve margin calculations to allow a different margin for each fuel, region, and year. Added a fuel subscript to the [`ReserveMargin`](@ref ReserveMargin) parameter, the [`ReserveMarginTagTechnology`](@ref ReserveMarginTagTechnology) parameter, and the [`vtotalcapacityinreservemargin`](@ref vtotalcapacityinreservemargin) output variable. Removed the `ReserveMarginTagFuel` parameter and `vdemandneedingreservemargin` output variable.

  * **Availability factors for transmission lines:** Added a parameter that defines time-sliced availability factors for transmission lines ([`TransmissionAvailabilityFactor`](@ref TransmissionAvailabilityFactor)). It allows you to simulate times when lines are unavailable or at reduced capacity. This parameter must be used when modeling transmission - if you don't want to represent reduced availability for lines, set a default of 1.0 for `TransmissionAvailabilityFactor` in the [default parameters table](@ref DefaultParams) or by using the [`setparamdefault`](@ref) function.

  * **After scenario calculation event:** Added an option to have NEMO run a custom Julia script after scenario calculation. To use this feature, create a NEMO [configuration file](@ref configuration_file) and specify the path to the script in the `afterscenariocalc` key (within the `include` block).

  * **Saving suboptimal solutions:** Added support for saving suboptimal solutions when calculating a scenario. These include solutions where optimization results in one of the following `MathOptInterface` termination statuses: `LOCALLY_SOLVED`, `ALMOST_OPTIMAL`, `ITERATION_LIMIT`, `TIME_LIMIT`, `NODE_LIMIT`, `SOLUTION_LIMIT`, `MEMORY_LIMIT`, `OBJECTIVE_LIMIT`, `NORM_LIMIT`, `OTHER_LIMIT`. In these cases, the solution is saved to the [scenario database](@ref scenario_db), and NEMO issues a warning.

  * **Bug fix - warm starts:** Fixed a bug in NEMO's warm starting functionality that was caused by a recent release of the Julia SQLite package. This bug led to the following error when performing a warm start without specifying `startvalsvars`: `SQLite.SQLiteException("no such column: val")`.

  * **Other database changes:** Deleted the unused `AvailabilityFactor` parameter and renamed `CapacityFactor` to [`AvailabilityFactor`](@ref AvailabilityFactor). The revised name more clearly describes the parameter's purpose.

!!! tip
    If you have a pre-existing scenario database that was created with NEMO 1.9, you can upgrade it to NEMO 2.0 using the `db_v9_to_v10` function. See [https://github.com/sei-international/NemoMod.jl/blob/master/src/db_structure.jl](https://github.com/sei-international/NemoMod.jl/blob/master/src/db_structure.jl) for details. Note that `db_v9_to_v10` sets a default of 1.0 for `TransmissionAvailabilityFactor`.

  * **Other enhancements:** Better aligned solver invocation in NEMO's test cases with how solvers are called when using NEMO with LEAP. This change should improve performance for most LEAP-NEMO users. Added logic to mitigate database locking errors when running NEMO on multiple threads. 

## Version 1.9

  * **HiGHS solver:** Added [HiGHS](https://highs.dev/) as an officially supported NEMO solver. HiGHS is a high-performance, open-source solver that works with linear programming, mixed-integer programming, and quadratic programming models. This enhancement includes incorporating HiGHS in the Julia system image that's distributed with the [NEMO installer program](@ref installer_program).

  * **Microarchitecture-specific optimizations:** Introduced microarchitecture-specific optimizations in the Julia system image delivered by the NEMO installer. This enhancement can reduce NEMO’s start-up and calculation time on many computers. Currently, optimizations for Skylake, Cannon Lake, Ice Lake, Rocket Lake, Tiger Lake, and Alder Lake microarchitectures are included in the installer.

  * **Bug fix - renewable energy targets with transmission:** Fixed a bug in how NEMO handles renewable energy minimum production targets for fuels for which transmission modeling is enabled.

  * **Controlling JuMP direct mode and bridging from configuration files:** Added two configuration file options that control whether NEMO uses JuMP's direct mode and bridging features when calculating a scenario. Both options are in the `calculatescenarioargs` block: `jumpdirectmode` enables/disables direct mode, while `jumpbridges` enables/disables bridging. These switches override the selection of direct mode and bridging specified in calls to [`calculatescenario`](@ref scenario_calc) - i.e., in the `jumpmodel` passed to `calculatescenario`. If you enable direct mode or turn off bridging, NEMO bypasses default behavior of JuMP that enhances solver compatibility at the expense of performance. This can substantially reduce memory use and solve time, but it may lead to solver errors. See [the documentation on configuration files](@ref configuration_file), [Performance tips](@ref performance_tips), and [JuMP's documentation](https://jump.dev/JuMP.jl/stable/) for more details.

  * **Region groups:** Added a new [dimension](@ref dimensions) for [groups of regions](@ref regiongroup) and parameters to assign regions to groups ([`RRGroup`](@ref RRGroup)) and to enforce renewable energy production targets for groups ([`REMinProductionTargetRG`](@ref REMinProductionTargetRG)). Each region can belong to zero or more groups.  When renewable energy targets are applied at the group level, NEMO finds the least-cost way to distribute renewable production across the grouped regions.

  * **JuMP upgrade:** Updated NEMO to use JuMP 1.2.0, MathOptInterface 1.7.0, and the latest versions of the Julia interfaces (packages) for the Cbc, Gurobi, and Mosek solvers.

  * **Other enhancements:** Implemented miscellaneous robustness improvements for multithreading in NEMO. Updated NEMO to use the latest versions of some other Julia packages on which it depends, including SQLite and DataFrames.

## Version 1.8

!!! note
    To use NEMO 1.8 with LEAP, please ensure you are running LEAP version **2020.1.0.65** or higher.

  * **Julia platform upgrade:** Updated NEMO to run on Julia 1.7.2, JuMP 1.0.0, and new versions of the Julia interfaces (packages) for the Cbc, CPLEX, GLPK, Gurobi, Mosek, and Xpress solvers. With this enhancement, NEMO can now be used with Gurobi 9.5, CPLEX 22.1, and Xpress 8.10-8.13, among other solver versions. See [Solver compatibility](@ref solver_compatibility) for full details on compatible solvers.

## Version 1.7

!!! note
    To use NEMO 1.7 with LEAP, please ensure you are running LEAP version **2020.1.0.57** or higher.

  * **Multi-threading:** Implemented a new paradigm for parallel processing in NEMO - replaced distributed Julia processes with multi-threading. In addition to streamlining operations that were already parallelized, this change allowed parallelization of constraint creation and results saving in [`calculatescenario`](@ref scenario_calc). It should reduce run-time and memory use for most models. Deprecated the `numprocs` and `targetprocs` arguments for `calculatescenario` and `writescenariomodel`; they were used to select distributed Julia processes and are no longer needed. When parallel processing, NEMO uses as many threads as are available in the Julia session. This in turn is controlled by a command line argument or environment variable provided when invoking Julia (see [Julia's documentation](https://docs.julialang.org/) for details).

  * **Improved functionality for renewable energy targets:** Increased the flexibility and simplicity of NEMO's renewable energy target calculations. Added fuel as a dimension for [`REMinProductionTarget`](@ref REMinProductionTarget), so this parameter now describes the fraction of a fuel's production in a region and year that must be by renewable technologies. As in earlier versions of NEMO, the [`RETagTechnology`](@ref RETagTechnology) parameter determines the renewability of technologies. Modified the logic for verifying compliance with `REMinProductionTarget` to exclude production from storage. Removed the `RETagFuel` parameter and `vtotalreproductionannual` and `vretotalproductionoftargetfuelannual` output variables since the new calculation method made them superfluous.

  * **Variables for generation and renewable generation:** Added output variables for annual generation (i.e., production excluding production from storage) and annual generation from renewable technologies. See [`vgenerationannualnn`](@ref vgenerationannualnn), [`vgenerationannualnodal`](@ref vgenerationannualnodal), [`vregenerationannualnn`](@ref vregenerationannualnn), and [`vregenerationannualnodal`](@ref vregenerationannualnodal).

  * **Minimum production share:** Added [`MinShareProduction`](@ref MinShareProduction), a parameter that specifies a technology's minimum share of production of a fuel in a given region and year (excluding production from storage).

  * **Warm starts:** Added two arguments to `calculatescenario` and `writescenariomodel` to enable warm starting optimization. NEMO's approach to warm starting is to take starting values for model output (decision) variables from a previously calculated scenario database. You specify the path to the previously calculated database with the `startvalsdbpath` argument; and you can optionally control which variables get starting values with the `startvalsvars` argument. These arguments can be provided either on the command line or through a NEMO [configuration file](@ref configuration_file). See the [documentation for `calculatescenario`](@ref scenario_calc) for more details.

  * **Bypassing optimization when results have already been calculated:** Added an argument to `calculatescenario`, `precalcresultspath`, that allows you to identify a previously calculated scenario database that should be used in lieu of optimizing the main scenario database passed to the function (i.e., the database named in the `dbpath` argument). If you specify a previously calculated database with `precalcresultspath`, NEMO copies it over the database at `dbpath`. This feature is intended for users who are calling NEMO through LEAP and want to compile results from multiple scenarios (which may have been calculated on different machines) in one LEAP area. You can use `precalcresultspath` either on the command line or through a NEMO configuration file. See the [documentation for `calculatescenario`](@ref scenario_calc) for more details.

  * **Bug fix - transmission line efficiency:** Corrected an error in how NEMO calculates transmission energy losses and variable costs when the transmission modeling type is 3 (pipeline flow; see [`TransmissionModelingEnabled`](@ref TransmissionModelingEnabled)) and line efficiency is less than 1. The calculations now properly account for bidirectional flow through lines. As part of this fix, removed the `vtransmissionbylineannual` output variable and added two variables for transmission variable costs: [`vvariablecosttransmission`](@ref vvariablecosttransmission) and [`vvariablecosttransmissionbyts`](@ref vvariablecosttransmissionbyts).

  * **Windows installer enhancements for multi-user environments:** Revised the NEMO Windows installer program to facilitate installations in multi-user environments (i.e., when the installer is run by one Windows user, but NEMO will be run by different Windows users). Among other changes, the new installer program installs Julia for all users. As usual, it is not necessary to uninstall older versions of NEMO before running the installer.

  * **Other improvements:** Revised NEMO's documentation to note that nodal storage modeling requires transmission modeling to be enabled for a storage's input and output fuels. See [`NodalDistributionStorageCapacity`](@ref NodalDistributionStorageCapacity).

## Version 1.6

  * **Interest rates for technologies, storage, and transmission lines:** Added parameters for interest rates for technologies ([`InterestRateTechnology`](@ref InterestRateTechnology)), storage ([`InterestRateStorage`](@ref InterestRateStorage)), and transmission lines (`interestrate` property of [`TransmissionLine`](@ref transmissionline)). If you specify an interest rate, NEMO uses it to calculate financing costs for new endogenous capacity, assuming the capital costs are financed at the interest rate and repaid in equal installments over the life of the capacity. The financing costs are reported in three new output variables ([`vfinancecost`](@ref vfinancecost), [`vfinancecoststorage`](@ref vfinancecoststorage), and [`vfinancecosttransmission`](@ref vfinancecosttransmission)) and enter into NEMO's cost minimization objective. They are also considered when calculating salvage values for technologies, storage, and transmission lines.

  * **Negative emissions:** Revised NEMO to accommodate negative emissions from technologies. You can activate this feature by specifying a negative emission factor ([`EmissionActivityRatio`](@ref EmissionActivityRatio)). If a technology has a negative emission factor for a pollutant with an externality cost ([`EmissionsPenalty`](@ref EmissionsPenalty)), it can generate negative emission penalties ([`vannualtechnologyemissionspenalty`](@ref vannualtechnologyemissionspenalty) / [`vannualtechnologyemissionpenaltybyemission`](@ref vannualtechnologyemissionpenaltybyemission)), lowering total system costs. In this case, you may need to constrain the technology's operation to avoid an unbounded (infeasible) optimization problem. For example, if a technology can generate negative emissions of a pollutant with an externality cost, the cost of building and running the technology is lower than the externality value, and there are no limits on the technology's deployment and use, the optimization problem will be unbounded.

  * **Deprecation of technology, storage, and transmission-specific discount rates:** Based on discussions with users, retired this functionality that was introduced in NEMO 1.5.

  * **Other performance improvements:** Improved the robustness of the [`createnemodb`](@ref) function.

## Version 1.5

  * **Technology, storage, and transmission-specific discount rates:** Revised NEMO so users can specify a different discount rate for each technology and region, storage and region, and transmission line. Technology and storage-specific rates are set with the new `DiscountRateTechnology` and `DiscountRateStorage` parameters. Rates for transmission lines are defined as part of the [transmission line dimension](@ref transmissionline). The [`DiscountRate`](@ref DiscountRate) parameter continues to provide the default discount rate for each region.

  * **Minimum utilization:** Added a parameter - [`MinimumUtilization`](@ref MinimumUtilization) - that enforces minimum utilization rates for technology capacity.

  * **Other performance improvements:** Streamlined logic for scenario database upgrades.

## Version 1.4

  * **Writing NEMO models:** Added a function to write an output file representing the NEMO optimization problem for a scenario (`writescenariomodel`). This function supports common solver file formats including MPS and LP and can compress its output with Gzip or BZip2. Results from the function can be used as an input to solver performance tuning programs, such as Gurobi's [parameter tuning tool](https://www.gurobi.com/documentation/9.1/refman/parameter_tuning_tool.html) and CPLEX's [tuning tool](https://www.ibm.com/support/knowledgecenter/SSSA5P_20.1.0/ilog.odms.cplex.help/CPLEX/UsrMan/topics/progr_consid/tuning/01_tune_title_synopsis.html).

  * **Calculating selected years:** Added functionality to calculate selected years of a scenario. You can invoke this feature with a new `calcyears` argument for [`calculatescenario`](@ref scenario_calc) (and `writescenariomodel`). Calculating selected years can quickly provide results for large models. The results may not be identical to what you would get if you calculated all years, but NEMO uses several methods to reduce discrepancies between the two cases. See [Calculating selected years](@ref selected_years) for details.

  * **New default solver - Cbc:** Changed the default solver for `calculatescenario` to Cbc. Since NEMO version 1.3, Cbc generally offers better performance than GLPK for NEMO models.

  * **Simplified parameters for inter-regional trading:** Trading between two [regions](@ref region) can now be enabled with a single row linking the regions in [`TradeRoute`](@ref TradeRoute).

  * **New output variable - vtransmissionbylineannual:** Added a variable that reports annual transmission through a transmission line in energy terms.

  * **Bug fix - exogenous emissions:** Revised [`vannualemissions`](@ref vannualemissions) so it includes any exogenously specified annual emissions ([`AnnualExogenousEmission`](@ref AnnualExogenousEmission)), and [`vmodelperiodemissions`](@ref vmodelperiodemissions) so it includes any exogenously specified annual and model period emissions ([`AnnualExogenousEmission`](@ref AnnualExogenousEmission) and [`ModelPeriodExogenousEmission`](@ref ModelPeriodExogenousEmission)).

  * **Other performance improvements:** Implemented various enhancements to improve NEMO's performance for large models, particularly those with multiple regions.

## Version 1.3.1

  * **Solver parameters in NEMO configuration files:** Added support for setting solver parameters via a NEMO configuration file. Users can activate this feature by assigning a comma-delimited list of parameter name-value pairs to the `parameters` key in a configuration file's `solver` block. The pairs should be in this form: parameter1=value1, parameter2=value2, .... See the documentation for [configuration files](@ref configuration_file) for more information.

  * **Forcing mixed-integer optimization problems:** Added an option that forces NEMO to formulate a mixed-integer optimization problem when calculating a scenario. This can improve performance with some solvers. The option can be invoked as an argument passed to `calculatescenario` (`forcemip`) or in a NEMO configuration file (`forcemip` key in `calculatescenarioargs` block). See the documentation for [`calculatescenario`](@ref scenario_calc) and [configuration files](@ref configuration_file) for more information.

## Version 1.3

  * **Julia and JuMP upgrade:** Updated NEMO to run on Julia 1.5.3 and JuMP 0.21.6. The new version of JuMP includes support for the most recent versions of key solvers, among them Cbc (2.10), CPLEX (12.10 and 20.1), and Gurobi (9.0 and 9.1). Note that this version of JuMP also uses a new solver abstraction layer, [`MathOptInterface`](https://github.com/jump-dev/MathOptInterface.jl), which changes how solvers are referenced when creating a JuMP model. See the documentation for [`calculatescenario`](@ref scenario_calc) for more information and examples.

## Version 1.2

  * **Ramp rates:** Added support for modeling technology ramp rates. You can activate this feature with two new parameters - [`RampRate`](@ref RampRate) and [`RampingReset`](@ref RampingReset).

  * **Parallel processing upgrades:** Revised [`calculatescenario`](@ref scenario_calc) so users can take advantage of parallelization without having to invoke Julia's `Distributed` package and add processes manually. Introduced the `numprocs` argument, which lets users specify the number of processes to use for parallelized operations. When `numprocs` is set, NEMO initializes new processes as needed. Refactored the queries in `calculatescenario` to parallelize as many of them as possible.

  * **Xpress solver:** Added Xpress as an officially supported NEMO solver. This includes incorporating Xpress in the Julia system image that's distributed with the [NEMO installer program](@ref installer_program).

  * **Installer program enhancements:** Upgraded the installer program to facilitate installation when the executing user isn't an operating system administrator. Also improved the integration of the installer program with LEAP.

  * **General error handling in `calculatescenario`:** Restructured `calculatescenario` so exceptions are trapped and presented along with information on how to report problems to the NEMO team.

  * **Other changes:** Streamlined NEMO's logic for upgrading legacy database versions in `calculatescenario`. Now the functions that perform upgrades are only called when needed. Removed the `createnemodb_leap` function since LEAP isn't using it.
