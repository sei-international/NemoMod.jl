```@meta
CurrentModule = NemoMod
```
# [Troubleshooting infeasibility](@id infeasibility)

NEMO models can be complicated, involving many interrelated parameters, decision variables, and constraints. Because of this complexity, it's not hard to define a NEMO scenario that's infeasible - for which an optimal solution can't be found. For example, you might inadvertently specify that a [technology's](@ref technology) [minimum capacity](@ref TotalAnnualMinCapacity) is greater than its [maximum capacity](@ref TotalAnnualMaxCapacity), or that [annual exogenous emissions](@ref AnnualExogenousEmission) of a pollutant exceed the pollutant's [annual emission limit](@ref AnnualEmissionLimit). A scenario with these inputs doesn't have a solution, and if you try to calculate it, the solver will report that the problem is infeasible.

Identifying the source(s) of infeasibility in a NEMO model (or any large optimization model) can be daunting, potentially requiring the evaluation of thousands or millions of inputs to find which are problematic. If your NEMO model is infeasible, it's best to start by thinking through the scenario you're modeling. Did you change a parameter that might have triggered the problem? What case or situation is the scenario testing - is it logically coherent? Questions like these may help you to recognize and rectify the issue.

## Using `find_infeasibilities`

Often, however, the source of infeasibility isn't clear. In this case, it can be helpful to use a tool that looks for causes of infeasibility in your model. NEMO provides such a tool in its [`find_infeasibilities`](@ref find_infeasbilities) function. Given an infeasible `JuMP` model created by calculating a NEMO scenario (with the [`calculatescenario`](@ref calculatescenario) function), `find_infeasibilities` returns an array of constraints that make the model infeasible (i.e., the model becomes feasible when these constraints are removed). You can use this information to determine how to modify the model's inputs to avoid infeasibility.

If you're starting with a [NEMO scenario database](@ref scenario_db), you can apply `find_infeasibilities` as follows:

* Create a `JuMP` model
* Call `calculatescenario` for the scenario database, passing it the `JuMP` model in the `jumpmodel` argument
* Call `find_infeasibilities` for the `JuMP` model

Here's an example:

```julia
julia> using NemoMod, JuMP, HiGHS

julia> m = direct_model(HiGHS.Optimizer())
A JuMP Model
Feasibility problem with:
Variables: 0
Model mode: DIRECT
Solver name: HiGHS

julia> NemoMod.calculatescenario("c:/temp/storage_test_infeasible.sqlite"; jumpmodel=m)
2025-17-Feb 17:38:27.023 Started modeling scenario. NEMO version = 2.2.0, solver = HiGHS.
2025-17-Feb 17:38:27.051 Read NEMO configuration file at C:\Users\jwvey\Dropbox\Research\Next Gen Modeling\Julia\NemoMod\nemo.ini.
2025-17-Feb 17:38:27.062 Read jumpdirectmode argument from configuration file.
2025-17-Feb 17:38:27.062 Read jumpbridges argument from configuration file.
2025-17-Feb 17:38:27.062 Validated run-time arguments.
2025-17-Feb 17:38:27.064 Connected to scenario database. Path = c:\temp\storage_test_infeasible.sqlite.
2025-17-Feb 17:38:27.699 Dropped pre-existing result tables from database.
2025-17-Feb 17:38:27.935 Created parameter views and indices.
2025-17-Feb 17:38:27.940 Created temporary tables.
2025-17-Feb 17:38:27.945 Started optimizing all years for scenario.
2025-17-Feb 17:38:27.947 Verified that transmission modeling is not enabled.
2025-17-Feb 17:38:28.178 Defined dimensions.
2025-17-Feb 17:38:29.259 Executed core database queries.
Running HiGHS 1.6.0: Copyright (c) 2023 HiGHS under MIT licence terms
2025-17-Feb 17:38:29.429 Defined demand variables.
2025-17-Feb 17:38:29.828 Defined storage variables.
2025-17-Feb 17:38:29.896 Defined capacity variables.
2025-17-Feb 17:38:31.535 Defined activity variables.
2025-17-Feb 17:38:31.795 Defined costing variables.
2025-17-Feb 17:38:31.817 Defined reserve margin variables.
2025-17-Feb 17:38:31.912 Defined emissions variables.
2025-17-Feb 17:38:31.912 Defined combined nodal and non-nodal variables.
2025-17-Feb 17:38:31.912 Finished defining model variables.
2025-17-Feb 17:38:31.912 Scheduled task to add constraints to model.
2025-17-Feb 17:38:31.978 Queued constraint CAa1_TotalNewCapacity for creation.
2025-17-Feb 17:38:31.979 Queued constraint CAa2_TotalAnnualCapacity for creation.
2025-17-Feb 17:38:31.979 Queued constraint VRateOfActivity1 for creation.
2025-17-Feb 17:38:31.979 Queued constraint RampRate for creation.
2025-17-Feb 17:38:31.979 Queued constraint CAa3_TotalActivityOfEachTechnology for creation.
2025-17-Feb 17:38:31.980 Queued constraint CAa4_Constraint_Capacity for creation.
2025-17-Feb 17:38:31.980 Queued constraint MinimumTechnologyUtilization for creation.
2025-17-Feb 17:38:31.980 Queued constraint EBa2_RateOfFuelProduction2 for creation.
2025-17-Feb 17:38:31.980 Queued constraint GenerationAnnualNN for creation.
2025-17-Feb 17:38:31.980 Queued constraint ReGenerationAnnualNN for creation.
2025-17-Feb 17:38:31.980 Queued constraint EBa3_RateOfFuelProduction3 for creation.
2025-17-Feb 17:38:31.980 Queued constraint EBa7_EnergyBalanceEachTS1 for creation.
2025-17-Feb 17:38:31.980 Queued constraint VRateOfProduction1 for creation.
2025-17-Feb 17:38:31.980 Queued constraint EBa5_RateOfFuelUse2 for creation.
2025-17-Feb 17:38:31.984 Queued constraint EBa6_RateOfFuelUse3 for creation.
2025-17-Feb 17:38:31.984 Queued constraint EBa8_EnergyBalanceEachTS2 for creation.
2025-17-Feb 17:38:31.986 Queued constraint VRateOfUse1 for creation.
2025-17-Feb 17:38:33.474 Queued constraint EBa9_EnergyBalanceEachTS3 for creation.
2025-17-Feb 17:38:33.474 Queued constraint EBa11_EnergyBalanceEachTS5 for creation.
2025-17-Feb 17:38:33.474 Queued constraint EBb0_EnergyBalanceEachYear for creation.
2025-17-Feb 17:38:33.474 Queued constraint EBb1_EnergyBalanceEachYear for creation.
2025-17-Feb 17:38:33.474 Queued constraint EBb2_EnergyBalanceEachYear for creation.
2025-17-Feb 17:38:33.474 Queued constraint EBb3_EnergyBalanceEachYear for creation.
2025-17-Feb 17:38:33.474 Queued constraint EBb5_EnergyBalanceEachYear for creation.
2025-17-Feb 17:38:33.474 Queued constraint Acc3_AverageAnnualRateOfActivity for creation.
2025-17-Feb 17:38:33.474 Queued constraint NS1_RateOfStorageCharge for creation.
2025-17-Feb 17:38:33.751 Queued constraint NS2_RateOfStorageDischarge for creation.
2025-17-Feb 17:38:33.751 Queued constraint NS3_StorageLevelTsGroup1Start for creation.
2025-17-Feb 17:38:33.751 Queued constraint NS4_StorageLevelTsGroup2Start for creation.
2025-17-Feb 17:38:33.751 Queued constraint NS5_StorageLevelTimesliceEnd for creation.
2025-17-Feb 17:38:33.751 Queued constraint NS6_StorageLevelTsGroup2End for creation.
2025-17-Feb 17:38:33.751 Queued constraint NS6a_StorageLevelTsGroup2NetZero for creation.
2025-17-Feb 17:38:33.751 Queued constraint NS7_StorageLevelTsGroup1End for creation.
2025-17-Feb 17:38:33.751 Queued constraint NS7a_StorageLevelTsGroup1NetZero for creation.
2025-17-Feb 17:38:33.751 Queued constraint NS8_StorageLevelYearEnd for creation.
2025-17-Feb 17:38:33.751 Queued constraint NS8a_StorageLevelYearEndNetZero for creation.
2025-17-Feb 17:38:33.751 Queued constraint SI1_StorageUpperLimit for creation.
2025-17-Feb 17:38:34.372 Queued constraint SI2_StorageLowerLimit for creation.
2025-17-Feb 17:38:34.372 Queued constraint SI3_TotalNewStorage for creation.
2025-17-Feb 17:38:34.372 Queued constraint NS9a_StorageLevelTsLowerLimit for creation.
2025-17-Feb 17:38:34.372 Queued constraint NS9b_StorageLevelTsUpperLimit for creation.
2025-17-Feb 17:38:34.372 Queued constraint NS10_StorageChargeLimit for creation.
2025-17-Feb 17:38:34.372 Queued constraint NS11_StorageDischargeLimit for creation.
2025-17-Feb 17:38:34.372 Queued constraint NS12a_StorageLevelTsGroup2LowerLimit for creation.
2025-17-Feb 17:38:34.372 Queued constraint NS12b_StorageLevelTsGroup2UpperLimit for creation.
2025-17-Feb 17:38:34.372 Queued constraint NS13a_StorageLevelTsGroup1LowerLimit for creation.
2025-17-Feb 17:38:34.372 Queued constraint NS13b_StorageLevelTsGroup1UpperLimit for creation.
2025-17-Feb 17:38:34.372 Queued constraint NS14_MaxStorageCapacity for creation.
2025-17-Feb 17:38:34.372 Queued constraint NS15_MinStorageCapacity for creation.
2025-17-Feb 17:38:34.372 Queued constraint NS16_MaxStorageCapacityInvestment for creation.
2025-17-Feb 17:38:34.456 Queued constraint NS17_MinStorageCapacityInvestment for creation.
2025-17-Feb 17:38:34.456 Queued constraint NS18_FullLoadHours for creation.
2025-17-Feb 17:38:34.456 Queued constraint SI4a_FinancingStorage for creation.
2025-17-Feb 17:38:34.456 Queued constraint SI4_UndiscountedCapitalInvestmentStorage for creation.
2025-17-Feb 17:38:34.558 Queued constraint SI5_DiscountingCapitalInvestmentStorage for creation.
2025-17-Feb 17:38:34.558 Queued constraint SI6_SalvageValueStorageAtEndOfPeriod1 for creation.
2025-17-Feb 17:38:34.558 Queued constraint SI7_SalvageValueStorageAtEndOfPeriod2 for creation.
2025-17-Feb 17:38:34.558 Queued constraint SI8_SalvageValueStorageAtEndOfPeriod3 for creation.
2025-17-Feb 17:38:34.558 Queued constraint SI9_SalvageValueStorageDiscountedToStartYear for creation.
2025-17-Feb 17:38:34.714 Queued constraint SI10_TotalDiscountedCostByStorage for creation.
2025-17-Feb 17:38:34.714 Queued constraint CC1a_FinancingTechnology for creation.
2025-17-Feb 17:38:34.714 Queued constraint CC1_UndiscountedCapitalInvestment for creation.
2025-17-Feb 17:38:34.714 Queued constraint CC2_DiscountingCapitalInvestment for creation.
2025-17-Feb 17:38:34.714 Queued constraint SV1_SalvageValueAtEndOfPeriod1 for creation.
2025-17-Feb 17:38:34.714 Queued constraint SV2_SalvageValueAtEndOfPeriod2 for creation.
2025-17-Feb 17:38:34.714 Queued constraint SV3_SalvageValueAtEndOfPeriod3 for creation.
2025-17-Feb 17:38:34.714 Queued constraint SV4_SalvageValueDiscountedToStartYear for creation.
2025-17-Feb 17:38:34.834 Queued constraint OC1_OperatingCostsVariable for creation.
2025-17-Feb 17:38:34.836 Queued constraint OC2_OperatingCostsFixedAnnual for creation.
2025-17-Feb 17:38:35.009 Queued constraint OC3_OperatingCostsTotalAnnual for creation.
2025-17-Feb 17:38:35.009 Queued constraint OC4_DiscountedOperatingCostsTotalAnnual for creation.
2025-17-Feb 17:38:35.009 Queued constraint TDC1_TotalDiscountedCostByTechnology for creation.
2025-17-Feb 17:38:35.009 Queued constraint TDC2_TotalDiscountedCost for creation.
2025-17-Feb 17:38:35.009 Queued constraint TCC1_TotalAnnualMaxCapacityConstraint for creation.
2025-17-Feb 17:38:35.009 Queued constraint TCC2_TotalAnnualMinCapacityConstraint for creation.
2025-17-Feb 17:38:35.011 Queued constraint NCC1_TotalAnnualMaxNewCapacityConstraint for creation.
2025-17-Feb 17:38:35.042 Queued constraint NCC2_TotalAnnualMinNewCapacityConstraint for creation.
2025-17-Feb 17:38:35.042 Queued constraint AAC1_TotalAnnualTechnologyActivity for creation.
2025-17-Feb 17:38:35.042 Queued constraint AAC2_TotalAnnualTechnologyActivityUpperLimit for creation.
2025-17-Feb 17:38:35.043 Queued constraint RM1_TotalCapacityInReserveMargin for creation.
2025-17-Feb 17:38:35.270 Queued constraint RM2_ReserveMargin for creation.
2025-17-Feb 17:38:35.270 Queued constraint RE1_FuelProductionByTechnologyAnnual for creation.
2025-17-Feb 17:38:35.272 Queued constraint FuelUseByTechnologyAnnual for creation.
2025-17-Feb 17:38:35.272 Queued constraint RE2_ProductionTarget for creation.
2025-17-Feb 17:38:35.272 Queued constraint RE3_ProductionTargetRG for creation.
2025-17-Feb 17:38:35.272 Queued constraint MinShareProduction for creation.
2025-17-Feb 17:38:35.679 Queued constraint E2a_AnnualEmissionProduction for creation.
2025-17-Feb 17:38:35.679 Queued constraint E2b_AnnualEmissionProduction for creation.
2025-17-Feb 17:38:35.679 Queued constraint E4_EmissionsPenaltyByTechnology for creation.
2025-17-Feb 17:38:35.679 Queued constraint E5_DiscountedEmissionsPenaltyByTechnology for creation.
2025-17-Feb 17:38:35.679 Queued constraint E6_EmissionsAccounting1 for creation.
2025-17-Feb 17:38:35.679 Queued constraint E7_EmissionsAccounting2 for creation.
2025-17-Feb 17:38:35.679 Queued constraint E8_AnnualEmissionsLimit for creation.
2025-17-Feb 17:38:35.679 Queued constraint E9_ModelPeriodEmissionsLimit for creation.
2025-17-Feb 17:38:35.679 Queued 94 standard constraints for creation.
2025-17-Feb 17:38:36.153 Finished scheduled task to add constraints to model.
2025-17-Feb 17:38:36.153 Added 94 standard constraints to model.
2025-17-Feb 17:38:36.153 Defined model objective.
Presolving model
12326 rows, 10436 cols, 42450 nonzeros
9962 rows, 8003 cols, 37363 nonzeros
8985 rows, 5682 cols, 31783 nonzeros
8514 rows, 5210 cols, 30362 nonzeros
Presolve : Reductions: rows 8514(-38897); columns 5210(-37470); elements 30362(-101615)
Solving the presolved LP
Using EKK dual simplex solver - serial
  Iteration        Objective     Infeasibilities num(sum)
          0     0.0000000000e+00 Pr: 970(1220.33) 0s
       2080     3.9383739235e+03 0s
Model   status      : Infeasible
Simplex   iterations: 2080
Objective value     :  3.9383153013e+03
HiGHS run time      :          0.11
ERROR:   No LP invertible representation for getDualRay
2025-17-Feb 17:38:36.264 Solved model. Solver status = INFEASIBLE.
2025-17-Feb 17:38:36.299 Solver did not find a solution for model. No results will be saved to database.
2025-17-Feb 17:38:36.300 Finished optimizing all years for scenario.
2025-17-Feb 17:38:36.303 Dropped temporary tables.
INFEASIBLE::TerminationStatusCode = 2

julia> NemoMod.find_infeasibilities(m, true)
[ Info: Verifying that model is infeasible.
[ Info: Model contains 47411 constraints that will be evaluated for infeasibilities.
[ Info: Changing bounds for vtotaldiscountedcost.
[ Info: Beginning infeasibility search.
[ Info: Temporarily removed 23706 constraints from model.
[ Info: Added 11853 constraints back to model.
[ Info: Added 5927 constraints back to model.
[ Info: Added 2963 constraints back to model.
[ Info: Added 1482 constraints back to model.
[ Info: Added 741 constraints back to model.
[ Info: Temporarily removed 371 constraints from model.
[ Info: Added 186 constraints back to model.
[ Info: Temporarily removed 93 constraints from model.
[ Info: Added 47 constraints back to model.
[ Info: Added 23 constraints back to model.
[ Info: Temporarily removed 12 constraints from model.
[ Info: Temporarily removed 6 constraints from model.
[ Info: Added 3 constraints back to model.
[ Info: Added 2 constraints back to model.
[ Info: Found an infeasibility: ScalarConstraint{AffExpr, MathOptInterface.LessThan{Float64}}(vtotaltechnologyannualactivity[1,gassupply,2020], MathOptInterface.LessThan{Float64}(0.0)). Saving and continuing search.
[ Info: Added 960 constraints back to model.
[ Info: Finished infeasibility search.
1-element Vector{Any}:
 ScalarConstraint{AffExpr, MathOptInterface.LessThan{Float64}}(vtotaltechnologyannualactivity[1,gassupply,2020], MathOptInterface.LessThan{Float64}(0.0))
```

As this example shows, interpreting the output from `find_infeasbilities` requires some familiarity with NEMO's [dimensions](@ref dimensions), [variables](@ref variables), and [parameters](@ref parameters). In this particular case, there's an unreasonable [total technology annual activity upper limit](@ref TotalTechnologyAnnualActivityUpperLimit) (0) specified for a technology (`gassupply`); without some gas in 2020, the scenario is infeasible. In general, when evaluating output from `find_infeasibilities`, consider the definitions of variables and think about how variables connect to the parameters that are defined in the scenario database. You can also look directly at [NEMO's code](https://github.com/sei-international/NemoMod.jl) to see how variables are used in different constraints.

!!! tip
    If you're using NEMO with LEAP, you can retrieve a copy of the NEMO database for one of your LEAP model's scenarios as follows:

    * Go to Settings -> Optimization in LEAP and check "Keep Intermediate Results".
    * Calculate the scenario in LEAP and save the results.
    * Open the LEAP areas folder (you can find the path to this folder under Settings -> Folders in LEAP), and go into the folder corresponding to your LEAP model.
    * The NEMO database for the scenario should be in this folder and named "NEMO_X.sqlite", where "X" is the LEAP ID number for the scenario. To determine the LEAP ID number for a scenario, see LEAP's help.

## Solver-specific tools

In addition to what NEMO provides, some solvers come with tools or functions for tracking down sources of infeasibility in a model. For example, Gurobi offers [a suite of functions for infeasibility analysis and diagnosis](https://docs.gurobi.com/projects/optimizer/en/current/features/infeasibility.html). Tools like these may require you to convert your model into a solver-specific format before searching for causes of infeasibility. Consult your solver's documentation for more information.