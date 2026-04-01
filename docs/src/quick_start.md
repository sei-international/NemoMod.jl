```@meta
CurrentModule = NemoMod
```
# Quick start

NEMO includes a number of features and options, so it's worth familiarizing yourself with the documentation before starting to work with it. To set up NEMO and run it through a first test, however, you can follow these steps.

1. Install NEMO using the instructions in [Installation](@ref installation).

2. Try calculating a test scenario distributed with the tool. This scenario simulates a simple energy system with electricity demand, generation, and storage. First, find [the database for the test scenario](@ref scenario_db) by going to the [NEMO package directory](@ref nemo_package_directory), opening the subdirectory named `test`, and looking for the file named `storage_test.sqlite`. Note the path to this file.

   Open a Julia prompt and enter the following commands:

   ```julia
   julia> using NemoMod

   julia> dbpath = "[full path to storage_test.sqlite]"  # On Windows, use / or \\ as the path separator - e.g., C:/ProgramData/NEMO/depot/packages/NemoMod/E1niV/test/storage_test.sqlite

   julia> chmod(dbpath, 0o777)

   julia> NemoMod.calculatescenario(dbpath)
   ```

   The first command activates the Julia package for NEMO, and the next ensures the test scenario's database is writable (so NEMO can save results to it). The final command calculates the scenario. You should see output like the following:

   ```
    2026-25-Mar 11:38:03.770 Started modeling scenario. Solver = COIN Branch-and-Cut (Cbc).
    2026-25-Mar 11:38:03.771 Validated run-time arguments.
    2026-25-Mar 11:38:03.771 Connected to scenario database. Path = C:\ProgramData\NEMO\depot\packages\NemoMod\E1niV\test\storage_test.sqlite.
    2026-25-Mar 11:38:03.774 Dropped pre-existing result tables from database.
    2026-25-Mar 11:38:03.789 Created parameter views and indices.
    2026-25-Mar 11:38:03.794 Created temporary tables.
    2026-25-Mar 11:38:03.795 Started optimizing all years for scenario.
    2026-25-Mar 11:38:03.796 Verified that transmission modeling is not enabled.
    2026-25-Mar 11:38:03.797 Defined dimensions.
    2026-25-Mar 11:38:03.909 Executed core database queries.
    2026-25-Mar 11:38:03.942 Defined demand variables.
    2026-25-Mar 11:38:03.943 Defined storage variables.
    2026-25-Mar 11:38:03.944 Defined capacity variables.
    2026-25-Mar 11:38:04.006 Defined activity variables.
    2026-25-Mar 11:38:04.007 Defined costing variables.
    2026-25-Mar 11:38:04.008 Defined reserve margin variables.
    2026-25-Mar 11:38:04.008 Defined emissions variables.
    2026-25-Mar 11:38:04.009 Defined combined nodal and non-nodal variables.
    2026-25-Mar 11:38:04.009 Finished defining model variables.
    2026-25-Mar 11:38:04.009 Scheduled task to add constraints to model.
    2026-25-Mar 11:38:04.009 Queued constraint CAa1_TotalNewCapacity for creation.
    2026-25-Mar 11:38:04.009 Queued constraint CAa2_TotalAnnualCapacity for creation.
    2026-25-Mar 11:38:04.009 Queued constraint VRateOfActivity1 for creation.
    2026-25-Mar 11:38:04.009 Queued constraint RampRate for creation.
    2026-25-Mar 11:38:04.009 Queued constraint CAa3_TotalActivityOfEachTechnology for creation.
    2026-25-Mar 11:38:04.009 Queued constraint CAa4_Constraint_Capacity for creation.
    2026-25-Mar 11:38:04.010 Queued constraint MinimumTechnologyUtilization for creation.
    2026-25-Mar 11:38:04.010 Queued constraint EBa2_RateOfFuelProduction2 for creation.
    2026-25-Mar 11:38:04.010 Queued constraint GenerationAnnualNN for creation.
    2026-25-Mar 11:38:04.010 Queued constraint ReGenerationAnnualNN for creation.
    2026-25-Mar 11:38:04.010 Queued constraint EBa3_RateOfFuelProduction3 for creation.
    2026-25-Mar 11:38:04.010 Queued constraint EBa7_EnergyBalanceEachTS1 for creation.
    2026-25-Mar 11:38:04.011 Queued constraint VRateOfProduction1 for creation.
    2026-25-Mar 11:38:04.011 Queued constraint EBa5_RateOfFuelUse2 for creation.
    2026-25-Mar 11:38:04.011 Queued constraint EBa6_RateOfFuelUse3 for creation.
    2026-25-Mar 11:38:04.011 Queued constraint EBa8_EnergyBalanceEachTS2 for creation.
    2026-25-Mar 11:38:04.016 Queued constraint VRateOfUse1 for creation.
    2026-25-Mar 11:38:04.016 Queued constraint EBa9_EnergyBalanceEachTS3 for creation.
    2026-25-Mar 11:38:04.017 Queued constraint EBa11_EnergyBalanceEachTS5 for creation.
    2026-25-Mar 11:38:04.017 Queued constraint EBb0_EnergyBalanceEachYear for creation.
    2026-25-Mar 11:38:04.018 Queued constraint EBb1_EnergyBalanceEachYear for creation.
    2026-25-Mar 11:38:04.018 Queued constraint EBb2_EnergyBalanceEachYear for creation.
    2026-25-Mar 11:38:04.018 Queued constraint EBb3_EnergyBalanceEachYear for creation.
    2026-25-Mar 11:38:04.018 Queued constraint EBb5_EnergyBalanceEachYear for creation.
    2026-25-Mar 11:38:04.018 Queued constraint Acc3_AverageAnnualRateOfActivity for creation.
    2026-25-Mar 11:38:04.018 Queued constraint NS1_RateOfStorageCharge for creation.
    2026-25-Mar 11:38:04.018 Queued constraint NS2_RateOfStorageDischarge for creation.
    2026-25-Mar 11:38:04.018 Queued constraint NS3_StorageLevelTsGroup1Start for creation.
    2026-25-Mar 11:38:04.044 Queued constraint NS4_StorageLevelTsGroup2Start for creation.
    2026-25-Mar 11:38:04.044 Queued constraint NS5_StorageLevelTimesliceEnd for creation.
    2026-25-Mar 11:38:04.045 Queued constraint NS6_StorageLevelTsGroup2End for creation.
    2026-25-Mar 11:38:04.045 Queued constraint NS6a_StorageLevelTsGroup2NetZero for creation.
    2026-25-Mar 11:38:04.046 Queued constraint NS7_StorageLevelTsGroup1End for creation.
    2026-25-Mar 11:38:04.046 Queued constraint NS7a_StorageLevelTsGroup1NetZero for creation.
    2026-25-Mar 11:38:04.046 Queued constraint NS8_StorageLevelYearEnd for creation.
    2026-25-Mar 11:38:04.046 Queued constraint NS8a_StorageLevelYearEndNetZero for creation.
    2026-25-Mar 11:38:04.047 Queued constraint SI1_StorageUpperLimit for creation.
    2026-25-Mar 11:38:04.048 Queued constraint SI2_StorageLowerLimit for creation.
    2026-25-Mar 11:38:04.048 Queued constraint SI3_TotalNewStorage for creation.
    2026-25-Mar 11:38:04.048 Queued constraint NS9a_StorageLevelTsLowerLimit for creation.
    2026-25-Mar 11:38:04.048 Queued constraint NS9b_StorageLevelTsUpperLimit for creation.
    2026-25-Mar 11:38:04.048 Queued constraint NS10_StorageChargeLimit for creation.
    2026-25-Mar 11:38:04.048 Queued constraint NS11_StorageDischargeLimit for creation.
    2026-25-Mar 11:38:04.048 Queued constraint NS12a_StorageLevelTsGroup2LowerLimit for creation.
    2026-25-Mar 11:38:04.048 Queued constraint NS12b_StorageLevelTsGroup2UpperLimit for creation.
    2026-25-Mar 11:38:04.048 Queued constraint NS13a_StorageLevelTsGroup1LowerLimit for creation.
    2026-25-Mar 11:38:04.048 Queued constraint NS13b_StorageLevelTsGroup1UpperLimit for creation.
    2026-25-Mar 11:38:04.048 Queued constraint NS14_MaxStorageCapacity for creation.
    2026-25-Mar 11:38:04.081 Queued constraint NS15_MinStorageCapacity for creation.
    2026-25-Mar 11:38:04.081 Queued constraint NS16_MaxStorageCapacityInvestment for creation.
    2026-25-Mar 11:38:04.081 Queued constraint NS17_MinStorageCapacityInvestment for creation.
    2026-25-Mar 11:38:04.081 Queued constraint NS18_FullLoadHours for creation.
    2026-25-Mar 11:38:04.081 Queued constraint SI4a_FinancingStorage for creation.
    2026-25-Mar 11:38:04.081 Queued constraint SI4_UndiscountedCapitalInvestmentStorage for creation.
    2026-25-Mar 11:38:04.081 Queued constraint SI5_DiscountingCapitalInvestmentStorage for creation.
    2026-25-Mar 11:38:04.081 Queued constraint SI6_SalvageValueStorageAtEndOfPeriod1 for creation.
    2026-25-Mar 11:38:04.081 Queued constraint SI7_SalvageValueStorageAtEndOfPeriod2 for creation.
    2026-25-Mar 11:38:04.081 Queued constraint SI8_SalvageValueStorageAtEndOfPeriod3 for creation.
    2026-25-Mar 11:38:04.081 Queued constraint SI9_SalvageValueStorageDiscountedToStartYear for creation.
    2026-25-Mar 11:38:04.081 Queued constraint SI10_TotalDiscountedCostByStorage for creation.
    2026-25-Mar 11:38:04.081 Queued constraint CC1a_FinancingTechnology for creation.
    2026-25-Mar 11:38:04.081 Queued constraint CC1_UndiscountedCapitalInvestment for creation.
    2026-25-Mar 11:38:04.081 Queued constraint CC2_DiscountingCapitalInvestment for creation.
    2026-25-Mar 11:38:04.082 Queued constraint SV1_SalvageValueAtEndOfPeriod1 for creation.
    2026-25-Mar 11:38:04.082 Queued constraint SV2_SalvageValueAtEndOfPeriod2 for creation.
    2026-25-Mar 11:38:04.082 Queued constraint SV3_SalvageValueAtEndOfPeriod3 for creation.
    2026-25-Mar 11:38:04.082 Queued constraint SV4_SalvageValueDiscountedToStartYear for creation.
    2026-25-Mar 11:38:04.082 Queued constraint OC1_OperatingCostsVariable for creation.
    2026-25-Mar 11:38:04.082 Queued constraint OC2_OperatingCostsFixedAnnual for creation.
    2026-25-Mar 11:38:04.082 Queued constraint OC3_OperatingCostsTotalAnnual for creation.
    2026-25-Mar 11:38:04.082 Queued constraint OC4_DiscountedOperatingCostsTotalAnnual for creation.
    2026-25-Mar 11:38:04.082 Queued constraint TDC1_TotalDiscountedCostByTechnology for creation.
    2026-25-Mar 11:38:04.082 Queued constraint TDC2_TotalDiscountedCost for creation.
    2026-25-Mar 11:38:04.082 Queued constraint TCC1_TotalAnnualMaxCapacityConstraint for creation.
    2026-25-Mar 11:38:04.082 Queued constraint TCC2_TotalAnnualMinCapacityConstraint for creation.
    2026-25-Mar 11:38:04.082 Queued constraint NCC1_TotalAnnualMaxNewCapacityConstraint for creation.
    2026-25-Mar 11:38:04.083 Queued constraint NCC2_TotalAnnualMinNewCapacityConstraint for creation.
    2026-25-Mar 11:38:04.083 Queued constraint RM1_TotalCapacityInReserveMargin for creation.
    2026-25-Mar 11:38:04.083 Queued constraint RM2_ReserveMargin for creation.
    2026-25-Mar 11:38:04.083 Queued constraint RE1_FuelProductionByTechnologyAnnual for creation.
    2026-25-Mar 11:38:04.083 Queued constraint FuelUseByTechnologyAnnual for creation.
    2026-25-Mar 11:38:04.083 Queued constraint RE2_ProductionTarget for creation.
    2026-25-Mar 11:38:04.083 Queued constraint RE3_ProductionTargetRG for creation.
    2026-25-Mar 11:38:04.083 Queued constraint MinShareProduction for creation.
    2026-25-Mar 11:38:04.084 Queued constraint E2a_AnnualEmissionProduction for creation.
    2026-25-Mar 11:38:04.084 Queued constraint E2b_AnnualEmissionProduction for creation.
    2026-25-Mar 11:38:04.084 Queued constraint E4_EmissionsPenaltyByTechnology for creation.
    2026-25-Mar 11:38:04.084 Queued constraint E5_DiscountedEmissionsPenaltyByTechnology for creation.
    2026-25-Mar 11:38:04.084 Queued constraint E6_EmissionsAccounting1 for creation.
    2026-25-Mar 11:38:04.084 Queued constraint E7_EmissionsAccounting2 for creation.
    2026-25-Mar 11:38:04.084 Queued constraint E8_AnnualEmissionsLimit for creation.
    2026-25-Mar 11:38:04.084 Queued constraint E9_ModelPeriodEmissionsLimit for creation.
    2026-25-Mar 11:38:04.084 Queued 92 standard constraints for creation.
    2026-25-Mar 11:38:04.153 Finished scheduled task to add constraints to model.
    2026-25-Mar 11:38:04.153 Added 92 standard constraints to model.
    2026-25-Mar 11:38:04.155 Defined model objective.
    Presolve 8606 (-38754) rows, 5775 (-36855) columns and 29985 (-97141) elements
    0  Obj 0 Primal inf 6666.7332 (970) Dual inf 1.0456445e+14 (1650)
    Perturbing problem by 0.001% of 3.396816 - largest nonzero change 9.9974941e-05 ( 0.021951956%) - largest zero change 0
    247  Obj 6782.5924 Primal inf 5358.1773 (991) Dual inf 1.0169671e+14 (1665)
    494  Obj 7016.7643 Primal inf 4717.9243 (960) Dual inf 2.3221409e+11 (1583)
    741  Obj 7655.4677 Primal inf 3704.7151 (944) Dual inf 1.7106913e+11 (1470)
    988  Obj 6939.1929 Primal inf 3479.1613 (933) Dual inf 1.5516073e+11 (1698)
    1235  Obj 6943.7657 Primal inf 3220.501 (960) Dual inf 1.5532974e+11 (1799)
    1482  Obj 6602.9533 Primal inf 2938.1258 (862) Dual inf 1.3583906e+11 (1866)
    1729  Obj 7877.6647 Primal inf 2604.8149 (811) Dual inf 1.2696655e+11 (1855)
    1978  Obj 11851.551 Primal inf 1563.7269 (622) Dual inf 1.6146373e+11 (1681)
    2229  Obj 12518.713 Primal inf 807.2539 (511) Dual inf 1.6631126e+11 (1590)
    2476  Obj 12545.005 Primal inf 389.11289 (286) Dual inf 2.678797e+11 (1358)
    2726  Obj 10391.367 Primal inf 171.94791 (149) Dual inf 1.9065784e+10 (1243)
    2979  Obj 11756.968 Primal inf 25.550303 (48) Dual inf 3.9853802e+09 (998)
    3226  Obj 8925.1264 Dual inf 30465.236 (564)
    3426  Obj 8352.7966 Dual inf 18413.196 (601)
    3635  Obj 6051.9397 Dual inf 78275.978 (654)
    3882  Obj 5522.9005 Dual inf 22034.938 (660)
    4054  Obj 5246.1783 Dual inf 61551.528 (462)
    4227  Obj 4938.9883 Dual inf 21969.244 (536)
    4474  Obj 4938.9464 Dual inf 4362.3556 (235)
    4483  Obj 4938.9437
    4483  Obj 4938.908 Primal inf 7.8660903e-05 (61)
    4543  Obj 4938.9082 Primal inf 0.00057967941 (61) Dual inf 4.7458134e-13 (12)
    4790  Obj 4938.9083 Primal inf 9.7710674e-05 (2)
    4830  Obj 4938.9083
    After Postsolve, objective 4938.9081, infeasibilities - dual 2.6370688e-05 (25), primal 0.00052934789 (14)
    Presolved model was optimal, full model needs cleaning up
    0  Obj 4938.9081 Primal inf 3.7147786e-05 (11) Dual inf 3.1000753e+14 (1534)
    End of values pass after 1 iterations
    1  Obj 4938.9081 Primal inf 3.7147786e-05 (11) Dual inf 3.1000753e+14 (1534)
    201  Obj 4938.9081 Dual inf 592.35781 (152)
    234  Obj 4938.9081
    Optimal - objective value 4938.9081
    Optimal objective 4938.90811 - 5064 iterations time 0.362, Presolve 0.06
    2026-25-Mar 11:38:05.056 Solved model. Solver status = OPTIMAL.
    2026-25-Mar 11:38:05.120 Saved results for vdemandnn to database.
    2026-25-Mar 11:38:05.125 Saved results for vnewcapacity to database.
    2026-25-Mar 11:38:05.128 Saved results for vtotalcapacityannual to database.
    2026-25-Mar 11:38:05.132 Saved results for vproductionbytechnologyannual to database.
    2026-25-Mar 11:38:05.144 Saved results for vproductionnn to database.
    2026-25-Mar 11:38:05.149 Saved results for vusebytechnologyannual to database.
    2026-25-Mar 11:38:05.158 Saved results for vusenn to database.
    2026-25-Mar 11:38:05.162 Saved results for vtotaldiscountedcost to database.
    2026-25-Mar 11:38:05.162 Finished saving results to database.
    2026-25-Mar 11:38:05.162 Finished optimizing all years for scenario.
    2026-25-Mar 11:38:05.166 Dropped temporary tables.
    OPTIMAL::TerminationStatusCode = 1
   ```

   Selected results are now saved in the database.

   !!! tip
       To change which results are saved and set other run-time options, see [Calculating a scenario](@ref scenario_calc).

For a better understanding of what happens in scenario calculations - and guidance on building your own model - look through the rest of the documentation, particularly [Modeling concept](@ref modeling_concept) and the sections on Inputs and Outputs.
