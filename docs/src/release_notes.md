```@meta
CurrentModule = NemoMod
```
# [Release notes](@id release_notes)

This page highlights key changes in NEMO since its initial public release. For a full history of NEMO releases, including the code for each version, see the [Releases page on NEMO's GitHub site](https://github.com/sei-international/NemoMod.jl/releases).

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

  * **Writing NEMO models:** Added a function to write an output file representing the NEMO optimization problem for a scenario ([`writescenariomodel`](@ref)). This function supports common solver file formats including MPS and LP and can compress its output with Gzip or BZip2. Results from the function can be used as an input to solver performance tuning programs, such as Gurobi's [parameter tuning tool](https://www.gurobi.com/documentation/9.1/refman/parameter_tuning_tool.html) and CPLEX's [tuning tool](https://www.ibm.com/support/knowledgecenter/SSSA5P_20.1.0/ilog.odms.cplex.help/CPLEX/UsrMan/topics/progr_consid/tuning/01_tune_title_synopsis.html).

  * **Calculating selected years:** Added functionality to calculate selected years of a scenario. You can invoke this feature with a new `calcyears` argument for [`calculatescenario`](@ref scenario_calc) (and [`writescenariomodel`](@ref)). Calculating selected years can quickly provide results for large models. The results may not be identical to what you would get if you calculated all years, but NEMO uses several methods to reduce discrepancies between the two cases. See [Calculating selected years](@ref selected_years) for details.

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
