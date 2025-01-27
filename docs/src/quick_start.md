```@meta
CurrentModule = NemoMod
```
# Quick start

NEMO includes a number of features and options, so it's worth familiarizing yourself with the documentation before starting to work with it. To set up NEMO and run it through a first test, however, you can follow these steps.

1. Install NEMO using the instructions in [Installation](@ref installation).

2. Try calculating a test scenario distributed with the tool. This scenario simulates a simple energy system with electricity demand, generation, and storage. Open a Julia prompt and enter the following commands:

   ```julia
   julia> using NemoMod, JuMP, Cbc

   julia> dbpath = normpath(joinpath(pathof(NemoMod), "..", "..", "test", "storage_test.sqlite"))

   julia> chmod(dbpath, 0o777)

   julia> NemoMod.calculatescenario(dbpath; jumpmodel=Model(Cbc.Optimizer))
   ```

   The first command activates the Julia packages for NEMO, JuMP (an optimization toolkit that NEMO uses), and Cbc (a solver). The next two commands locate the test scenario's [database](@ref scenario_db) and ensure this file is writable (so NEMO can save scenario results). The final command calculates the scenario. You should see output like the following:

   ```
   2022-18-Feb 13:54:56.035 Started modeling scenario.
   2022-18-Feb 13:54:56.037 Validated run-time arguments.
   2022-18-Feb 13:54:56.045 Connected to scenario database. Path = C:\Users\Jason\.julia\packages\NemoMod\o4yhG\test\storage_test.sqlite.
   2022-18-Feb 13:54:56.465 Dropped pre-existing result tables from database.
   2022-18-Feb 13:54:56.468 Verified that transmission modeling is not enabled.
   2022-18-Feb 13:54:56.901 Created parameter views and indices.
   2022-18-Feb 13:54:56.922 Created temporary tables.
   2022-18-Feb 13:55:00.179 Executed core database queries.
   2022-18-Feb 13:55:00.512 Defined dimensions.
   2022-18-Feb 13:55:01.029 Defined demand variables.
   2022-18-Feb 13:55:01.273 Defined storage variables.
   2022-18-Feb 13:55:01.275 Defined capacity variables.
   2022-18-Feb 13:55:03.343 Defined activity variables.
   2022-18-Feb 13:55:03.357 Defined costing variables.
   2022-18-Feb 13:55:03.357 Defined reserve margin variables.
   2022-18-Feb 13:55:03.359 Defined emissions variables.
   2022-18-Feb 13:55:03.359 Defined combined nodal and non-nodal variables.
   2022-18-Feb 13:55:03.359 Finished defining model variables.
   2022-18-Feb 13:55:03.359 Scheduled task to add constraints to model.
   2022-18-Feb 13:55:03.453 Queued constraint CAa1_TotalNewCapacity for creation.
   2022-18-Feb 13:55:03.454 Queued constraint CAa2_TotalAnnualCapacity for creation.
   2022-18-Feb 13:55:03.454 Queued constraint VRateOfActivity1 for creation.
   2022-18-Feb 13:55:03.454 Queued constraint RampRate for creation.
   2022-18-Feb 13:55:03.454 Queued constraint CAa3_TotalActivityOfEachTechnology for creation.
   2022-18-Feb 13:55:03.460 Queued constraint CAa4_Constraint_Capacity for creation.
   2022-18-Feb 13:55:03.460 Queued constraint MinimumTechnologyUtilization for creation.
   2022-18-Feb 13:55:03.460 Queued constraint EBa2_RateOfFuelProduction2 for creation.
   2022-18-Feb 13:55:03.460 Queued constraint GenerationAnnualNN for creation.
   2022-18-Feb 13:55:03.461 Queued constraint ReGenerationAnnualNN for creation.
   2022-18-Feb 13:55:03.461 Queued constraint EBa3_RateOfFuelProduction3 for creation.
   2022-18-Feb 13:55:05.901 Queued constraint VRateOfProduction1 for creation.
   2022-18-Feb 13:55:05.902 Queued constraint EBa5_RateOfFuelUse2 for creation.
   2022-18-Feb 13:55:05.902 Queued constraint EBa6_RateOfFuelUse3 for creation.
   2022-18-Feb 13:55:05.902 Queued constraint VRateOfUse1 for creation.
   2022-18-Feb 13:55:05.903 Queued constraint EBa7_EnergyBalanceEachTS1 for creation.
   2022-18-Feb 13:55:05.909 Queued constraint EBa8_EnergyBalanceEachTS2 for creation.
   2022-18-Feb 13:55:05.909 Queued constraint EBa9_EnergyBalanceEachTS3 for creation.
   2022-18-Feb 13:55:07.286 Queued constraint EBa11_EnergyBalanceEachTS5 for creation.
   2022-18-Feb 13:55:07.289 Queued constraint EBb0_EnergyBalanceEachYear for creation.
   2022-18-Feb 13:55:07.289 Queued constraint EBb1_EnergyBalanceEachYear for creation.
   2022-18-Feb 13:55:07.291 Queued constraint EBb2_EnergyBalanceEachYear for creation.
   2022-18-Feb 13:55:07.296 Queued constraint EBb3_EnergyBalanceEachYear for creation.
   2022-18-Feb 13:55:07.297 Queued constraint EBb5_EnergyBalanceEachYear for creation.
   2022-18-Feb 13:55:07.297 Queued constraint Acc3_AverageAnnualRateOfActivity for creation.
   2022-18-Feb 13:55:07.297 Queued constraint NS1_RateOfStorageCharge for creation.
   2022-18-Feb 13:55:08.166 Queued constraint NS2_RateOfStorageDischarge for creation.
   2022-18-Feb 13:55:08.174 Queued constraint NS3_StorageLevelTsGroup1Start for creation.
   2022-18-Feb 13:55:08.174 Queued constraint NS4_StorageLevelTsGroup2Start for creation.
   2022-18-Feb 13:55:08.174 Queued constraint NS5_StorageLevelTimesliceEnd for creation.
   2022-18-Feb 13:55:08.181 Queued constraint NS6_StorageLevelTsGroup2End for creation.
   2022-18-Feb 13:55:08.182 Queued constraint NS6a_StorageLevelTsGroup2NetZero for creation.
   2022-18-Feb 13:55:08.182 Queued constraint NS7_StorageLevelTsGroup1End for creation.
   2022-18-Feb 13:55:08.182 Queued constraint NS7a_StorageLevelTsGroup1NetZero for creation.
   2022-18-Feb 13:55:08.182 Queued constraint NS8_StorageLevelYearEnd for creation.
   2022-18-Feb 13:55:08.183 Queued constraint NS8a_StorageLevelYearEndNetZero for creation.
   2022-18-Feb 13:55:08.183 Queued constraint SI1_StorageUpperLimit for creation.
   2022-18-Feb 13:55:08.183 Queued constraint SI2_StorageLowerLimit for creation.
   2022-18-Feb 13:55:08.184 Queued constraint SI3_TotalNewStorage for creation.
   2022-18-Feb 13:55:08.306 Queued constraint NS9a_StorageLevelTsLowerLimit for creation.
   2022-18-Feb 13:55:08.310 Queued constraint NS9b_StorageLevelTsUpperLimit for creation.
   2022-18-Feb 13:55:08.310 Queued constraint NS10_StorageChargeLimit for creation.
   2022-18-Feb 13:55:08.940 Queued constraint NS11_StorageDischargeLimit for creation.
   2022-18-Feb 13:55:08.940 Queued constraint NS12a_StorageLevelTsGroup2LowerLimit for creation.
   2022-18-Feb 13:55:08.941 Queued constraint NS12b_StorageLevelTsGroup2UpperLimit for creation.
   2022-18-Feb 13:55:08.941 Queued constraint NS13a_StorageLevelTsGroup1LowerLimit for creation.
   2022-18-Feb 13:55:09.037 Queued constraint NS13b_StorageLevelTsGroup1UpperLimit for creation.
   2022-18-Feb 13:55:09.038 Queued constraint NS14_MaxStorageCapacity for creation.
   2022-18-Feb 13:55:09.062 Queued constraint NS15_MinStorageCapacity for creation.
   2022-18-Feb 13:55:09.062 Queued constraint NS16_MaxStorageCapacityInvestment for creation.
   2022-18-Feb 13:55:09.125 Queued constraint NS17_MinStorageCapacityInvestment for creation.
   2022-18-Feb 13:55:09.164 Queued constraint NS18_FullLoadHours for creation.
   2022-18-Feb 13:55:09.356 Queued constraint SI4a_FinancingStorage for creation.
   2022-18-Feb 13:55:09.358 Queued constraint SI4_UndiscountedCapitalInvestmentStorage for creation.
   2022-18-Feb 13:55:09.358 Queued constraint SI5_DiscountingCapitalInvestmentStorage for creation.
   2022-18-Feb 13:55:09.359 Queued constraint SI6_SalvageValueStorageAtEndOfPeriod1 for creation.
   2022-18-Feb 13:55:09.365 Queued constraint SI7_SalvageValueStorageAtEndOfPeriod2 for creation.
   2022-18-Feb 13:55:09.365 Queued constraint SI8_SalvageValueStorageAtEndOfPeriod3 for creation.
   2022-18-Feb 13:55:09.681 Queued constraint SI9_SalvageValueStorageDiscountedToStartYear for creation.
   2022-18-Feb 13:55:09.681 Queued constraint SI10_TotalDiscountedCostByStorage for creation.
   2022-18-Feb 13:55:09.681 Queued constraint CC1a_FinancingTechnology for creation.
   2022-18-Feb 13:55:09.681 Queued constraint CC1_UndiscountedCapitalInvestment for creation.
   2022-18-Feb 13:55:09.682 Queued constraint CC2_DiscountingCapitalInvestment for creation.
   2022-18-Feb 13:55:09.688 Queued constraint SV1_SalvageValueAtEndOfPeriod1 for creation.
   2022-18-Feb 13:55:09.688 Queued constraint SV2_SalvageValueAtEndOfPeriod2 for creation.
   2022-18-Feb 13:55:09.688 Queued constraint SV3_SalvageValueAtEndOfPeriod3 for creation.
   2022-18-Feb 13:55:09.887 Queued constraint SV4_SalvageValueDiscountedToStartYear for creation.
   2022-18-Feb 13:55:09.887 Queued constraint OC1_OperatingCostsVariable for creation.
   2022-18-Feb 13:55:09.887 Queued constraint OC2_OperatingCostsFixedAnnual for creation.
   2022-18-Feb 13:55:09.887 Queued constraint OC3_OperatingCostsTotalAnnual for creation.
   2022-18-Feb 13:55:09.978 Queued constraint OC4_DiscountedOperatingCostsTotalAnnual for creation.
   2022-18-Feb 13:55:09.982 Queued constraint TDC1_TotalDiscountedCostByTechnology for creation.
   2022-18-Feb 13:55:09.982 Queued constraint TDC2_TotalDiscountedCost for creation.
   2022-18-Feb 13:55:10.686 Queued constraint TCC1_TotalAnnualMaxCapacityConstraint for creation.
   2022-18-Feb 13:55:10.688 Queued constraint TCC2_TotalAnnualMinCapacityConstraint for creation.
   2022-18-Feb 13:55:10.688 Queued constraint NCC1_TotalAnnualMaxNewCapacityConstraint for creation.
   2022-18-Feb 13:55:10.689 Queued constraint NCC2_TotalAnnualMinNewCapacityConstraint for creation.
   2022-18-Feb 13:55:10.694 Queued constraint RM1_ReserveMargin_TechnologiesIncluded_In_Activity_Units for creation.
   2022-18-Feb 13:55:10.694 Queued constraint RM2_ReserveMargin_FuelsIncluded for creation.
   2022-18-Feb 13:55:10.695 Queued constraint RM3_ReserveMargin_Constraint for creation.
   2022-18-Feb 13:55:11.079 Queued constraint RE1_FuelProductionByTechnologyAnnual for creation.
   2022-18-Feb 13:55:11.079 Queued constraint FuelUseByTechnologyAnnual for creation.
   2022-18-Feb 13:55:11.079 Queued constraint RE2_ProductionTarget for creation.
   2022-18-Feb 13:55:11.080 Queued constraint MinShareProduction for creation.
   2022-18-Feb 13:55:11.080 Queued constraint E2a_AnnualEmissionProduction for creation.
   2022-18-Feb 13:55:11.839 Queued constraint E2b_AnnualEmissionProduction for creation.
   2022-18-Feb 13:55:11.840 Queued constraint E4_EmissionsPenaltyByTechnology for creation.
   2022-18-Feb 13:55:11.840 Queued constraint E5_DiscountedEmissionsPenaltyByTechnology for creation.
   2022-18-Feb 13:55:11.841 Queued constraint E6_EmissionsAccounting1 for creation.
   2022-18-Feb 13:55:11.841 Queued constraint E7_EmissionsAccounting2 for creation.
   2022-18-Feb 13:55:11.841 Queued constraint E8_AnnualEmissionsLimit for creation.
   2022-18-Feb 13:55:11.841 Queued constraint E9_ModelPeriodEmissionsLimit for creation.
   2022-18-Feb 13:55:12.352 Queued 92 standard constraints for creation.
   2022-18-Feb 13:55:12.627 Finished scheduled task to add constraints to model.
   2022-18-Feb 13:55:12.630 Added 92 standard constraints to model.
   2022-18-Feb 13:55:12.673 Defined model objective.
   Welcome to the CBC MILP Solver
   Version: 2.10.3
   Build Date: Jan  1 1970

   command line - Cbc_C_Interface -solve -quit (default strategy 1)
   Presolve 9284 (-39116) rows, 5881 (-37689) columns and 31378 (-97748) elements
   Perturbing problem by 0.001% of 9783.528 - largest nonzero change 0.00099798061 ( 0.096361773%) - largest zero change 0.00098831517
   0  Obj 0.17460989 Primal inf 19624.801 (2390)
   260  Obj 4.4154306 Primal inf 17789.093 (1842)
   520  Obj 2532.6631 Primal inf 13655.244 (1493)
   780  Obj 2532.8283 Primal inf 14898.296 (1354)
   1040  Obj 2917.775 Primal inf 13192.724 (1231)
   1300  Obj 3406.5858 Primal inf 11837.385 (1230)
   1560  Obj 3744.7415 Primal inf 10651.018 (1129)
   1820  Obj 4059.7009 Primal inf 9479.8923 (1087)
   2080  Obj 4097.6195 Primal inf 5202.1479 (904)
   2340  Obj 4097.6655 Primal inf 5990.9476 (1250)
   2600  Obj 4097.7009 Primal inf 2482.7417 (864)
   2860  Obj 4097.7399 Primal inf 5633.2536 (908)
   3120  Obj 4825.3122 Primal inf 6732.3767 (651)
   3380  Obj 4825.3466 Primal inf 4134.8617 (812)
   3640  Obj 4839.8777 Primal inf 1666.9188 (271)
   3890  Obj 4940.458 Primal inf 182.88383 (106)
   4105  Obj 4940.621
   4105  Obj 4938.9081 Dual inf 0.013919411 (6)
   4111  Obj 4938.9081
   Optimal - objective value 4938.9081
   After Postsolve, objective 4938.9081, infeasibilities - dual 3.5273716e-06 (7), primal 0.00050747243 (11)
   Presolved model was optimal, full model needs cleaning up
   0  Obj 2988.4607 Primal inf 9.138411e+11 (2122) Dual inf 1.3032895e-05 (6)
   58  Obj 4938.9081 Primal inf 3.6777458e-05 (16)
   Optimal - objective value 4938.9081
   Optimal objective 4938.908089 - 4169 iterations time 0.402, Presolve 0.08
   Total time (CPU seconds):       0.42   (Wallclock seconds):       0.42

   2022-18-Feb 13:55:21.953 Solved model. Solver status = OPTIMAL.
   2022-18-Feb 13:55:22.315 Saved results for vdemandnn to database.
   2022-18-Feb 13:55:22.372 Saved results for vnewcapacity to database.
   2022-18-Feb 13:55:22.395 Saved results for vtotalcapacityannual to database.
   2022-18-Feb 13:55:22.546 Saved results for vproductionbytechnologyannual to database.
   2022-18-Feb 13:55:22.589 Saved results for vproductionnn to database.
   2022-18-Feb 13:55:22.616 Saved results for vusebytechnologyannual to database.
   2022-18-Feb 13:55:22.651 Saved results for vusenn to database.
   2022-18-Feb 13:55:22.707 Saved results for vtotaldiscountedcost to database.
   2022-18-Feb 13:55:22.708 Finished saving results to database.
   2022-18-Feb 13:55:22.729 Dropped temporary tables.
   2022-18-Feb 13:55:22.730 Finished modeling scenario.
   OPTIMAL::TerminationStatusCode = 1
   ```

   Selected results are now saved in the database.

   !!! tip
       To change which results are saved and set other run-time options, see [Calculating a scenario](@ref scenario_calc).

For a better understanding of what happens in scenario calculations - and guidance on building your own model - look through the rest of the documentation, particularly [Modeling concept](@ref modeling_concept) and the sections on Inputs and Outputs.
