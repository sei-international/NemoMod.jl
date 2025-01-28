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
   2025-27-Jan 17:25:09.319 Started modeling scenario. NEMO version = 2.2.0, solver = COIN Branch-and-Cut (Cbc).
   2025-27-Jan 17:25:09.319 Validated run-time arguments.
   2025-27-Jan 17:25:09.319 Connected to scenario database. Path = C:\ProgramData\NEMO\depot\packages\NemoMod\e8Kos\test\storage_test.sqlite.
   2025-27-Jan 17:25:09.876 Dropped pre-existing result tables from database.
   2025-27-Jan 17:25:10.108 Created parameter views and indices.
   2025-27-Jan 17:25:10.109 Created temporary tables.
   2025-27-Jan 17:25:14.892 Started optimizing all years for scenario.
   2025-27-Jan 17:25:14.899 Verified that transmission modeling is not enabled.
   2025-27-Jan 17:25:15.125 Defined dimensions.
   2025-27-Jan 17:25:16.026 Executed core database queries.
   2025-27-Jan 17:25:17.043 Defined demand variables.
   2025-27-Jan 17:25:17.453 Defined storage variables.
   2025-27-Jan 17:25:17.512 Defined capacity variables.
   2025-27-Jan 17:25:19.077 Defined activity variables.
   2025-27-Jan 17:25:19.277 Defined costing variables.
   2025-27-Jan 17:25:19.299 Defined reserve margin variables.
   2025-27-Jan 17:25:19.402 Defined emissions variables.
   2025-27-Jan 17:25:19.402 Defined combined nodal and non-nodal variables.
   2025-27-Jan 17:25:19.402 Finished defining model variables.
   2025-27-Jan 17:25:19.402 Scheduled task to add constraints to model.
   2025-27-Jan 17:25:19.467 Queued constraint CAa1_TotalNewCapacity for creation.
   2025-27-Jan 17:25:19.469 Queued constraint CAa2_TotalAnnualCapacity for creation.
   2025-27-Jan 17:25:19.469 Queued constraint VRateOfActivity1 for creation.
   2025-27-Jan 17:25:19.469 Queued constraint RampRate for creation.
   2025-27-Jan 17:25:19.471 Queued constraint CAa3_TotalActivityOfEachTechnology for creation.
   2025-27-Jan 17:25:19.473 Queued constraint CAa4_Constraint_Capacity for creation.
   2025-27-Jan 17:25:19.473 Queued constraint MinimumTechnologyUtilization for creation.
   2025-27-Jan 17:25:19.474 Queued constraint EBa2_RateOfFuelProduction2 for creation.
   2025-27-Jan 17:25:19.474 Queued constraint GenerationAnnualNN for creation.
   2025-27-Jan 17:25:19.474 Queued constraint ReGenerationAnnualNN for creation.
   2025-27-Jan 17:25:19.475 Queued constraint EBa3_RateOfFuelProduction3 for creation.
   2025-27-Jan 17:25:19.476 Queued constraint EBa7_EnergyBalanceEachTS1 for creation.
   2025-27-Jan 17:25:19.477 Queued constraint VRateOfProduction1 for creation.
   2025-27-Jan 17:25:19.478 Queued constraint EBa5_RateOfFuelUse2 for creation.
   2025-27-Jan 17:25:19.479 Queued constraint EBa6_RateOfFuelUse3 for creation.
   2025-27-Jan 17:25:19.480 Queued constraint EBa8_EnergyBalanceEachTS2 for creation.
   2025-27-Jan 17:25:19.480 Queued constraint VRateOfUse1 for creation.
   2025-27-Jan 17:25:20.901 Queued constraint EBa9_EnergyBalanceEachTS3 for creation.
   2025-27-Jan 17:25:20.901 Queued constraint EBa11_EnergyBalanceEachTS5 for creation.
   2025-27-Jan 17:25:20.901 Queued constraint EBb0_EnergyBalanceEachYear for creation.
   2025-27-Jan 17:25:20.901 Queued constraint EBb1_EnergyBalanceEachYear for creation.
   2025-27-Jan 17:25:20.901 Queued constraint EBb2_EnergyBalanceEachYear for creation.
   2025-27-Jan 17:25:21.524 Queued constraint EBb3_EnergyBalanceEachYear for creation.
   2025-27-Jan 17:25:21.524 Queued constraint EBb5_EnergyBalanceEachYear for creation.
   2025-27-Jan 17:25:21.524 Queued constraint Acc3_AverageAnnualRateOfActivity for creation.
   2025-27-Jan 17:25:21.524 Queued constraint NS1_RateOfStorageCharge for creation.
   2025-27-Jan 17:25:21.539 Queued constraint NS2_RateOfStorageDischarge for creation.
   2025-27-Jan 17:25:21.539 Queued constraint NS3_StorageLevelTsGroup1Start for creation.
   2025-27-Jan 17:25:21.539 Queued constraint NS4_StorageLevelTsGroup2Start for creation.
   2025-27-Jan 17:25:21.539 Queued constraint NS5_StorageLevelTimesliceEnd for creation.
   2025-27-Jan 17:25:21.539 Queued constraint NS6_StorageLevelTsGroup2End for creation.
   2025-27-Jan 17:25:21.540 Queued constraint NS6a_StorageLevelTsGroup2NetZero for creation.
   2025-27-Jan 17:25:21.540 Queued constraint NS7_StorageLevelTsGroup1End for creation.
   2025-27-Jan 17:25:21.540 Queued constraint NS7a_StorageLevelTsGroup1NetZero for creation.
   2025-27-Jan 17:25:21.540 Queued constraint NS8_StorageLevelYearEnd for creation.
   2025-27-Jan 17:25:22.176 Queued constraint NS8a_StorageLevelYearEndNetZero for creation.
   2025-27-Jan 17:25:22.176 Queued constraint SI1_StorageUpperLimit for creation.
   2025-27-Jan 17:25:22.176 Queued constraint SI2_StorageLowerLimit for creation.
   2025-27-Jan 17:25:22.176 Queued constraint SI3_TotalNewStorage for creation.
   2025-27-Jan 17:25:22.176 Queued constraint NS9a_StorageLevelTsLowerLimit for creation.
   2025-27-Jan 17:25:22.176 Queued constraint NS9b_StorageLevelTsUpperLimit for creation.
   2025-27-Jan 17:25:22.191 Queued constraint NS10_StorageChargeLimit for creation.
   2025-27-Jan 17:25:22.191 Queued constraint NS11_StorageDischargeLimit for creation.
   2025-27-Jan 17:25:22.191 Queued constraint NS12a_StorageLevelTsGroup2LowerLimit for creation.
   2025-27-Jan 17:25:22.191 Queued constraint NS12b_StorageLevelTsGroup2UpperLimit for creation.
   2025-27-Jan 17:25:22.191 Queued constraint NS13a_StorageLevelTsGroup1LowerLimit for creation.
   2025-27-Jan 17:25:22.191 Queued constraint NS13b_StorageLevelTsGroup1UpperLimit for creation.
   2025-27-Jan 17:25:22.191 Queued constraint NS14_MaxStorageCapacity for creation.
   2025-27-Jan 17:25:22.191 Queued constraint NS15_MinStorageCapacity for creation.
   2025-27-Jan 17:25:22.326 Queued constraint NS16_MaxStorageCapacityInvestment for creation.
   2025-27-Jan 17:25:22.326 Queued constraint NS17_MinStorageCapacityInvestment for creation.
   2025-27-Jan 17:25:22.326 Queued constraint NS18_FullLoadHours for creation.
   2025-27-Jan 17:25:22.326 Queued constraint SI4a_FinancingStorage for creation.
   2025-27-Jan 17:25:22.326 Queued constraint SI4_UndiscountedCapitalInvestmentStorage for creation.
   2025-27-Jan 17:25:22.326 Queued constraint SI5_DiscountingCapitalInvestmentStorage for creation.
   2025-27-Jan 17:25:22.326 Queued constraint SI6_SalvageValueStorageAtEndOfPeriod1 for creation.
   2025-27-Jan 17:25:22.326 Queued constraint SI7_SalvageValueStorageAtEndOfPeriod2 for creation.
   2025-27-Jan 17:25:22.328 Queued constraint SI8_SalvageValueStorageAtEndOfPeriod3 for creation.
   2025-27-Jan 17:25:22.328 Queued constraint SI9_SalvageValueStorageDiscountedToStartYear for creation.
   2025-27-Jan 17:25:22.328 Queued constraint SI10_TotalDiscountedCostByStorage for creation.
   2025-27-Jan 17:25:22.457 Queued constraint CC1a_FinancingTechnology for creation.
   2025-27-Jan 17:25:22.457 Queued constraint CC1_UndiscountedCapitalInvestment for creation.
   2025-27-Jan 17:25:22.457 Queued constraint CC2_DiscountingCapitalInvestment for creation.
   2025-27-Jan 17:25:22.457 Queued constraint SV1_SalvageValueAtEndOfPeriod1 for creation.
   2025-27-Jan 17:25:22.457 Queued constraint SV2_SalvageValueAtEndOfPeriod2 for creation.
   2025-27-Jan 17:25:22.565 Queued constraint SV3_SalvageValueAtEndOfPeriod3 for creation.
   2025-27-Jan 17:25:22.565 Queued constraint SV4_SalvageValueDiscountedToStartYear for creation.
   2025-27-Jan 17:25:22.565 Queued constraint OC1_OperatingCostsVariable for creation.
   2025-27-Jan 17:25:22.565 Queued constraint OC2_OperatingCostsFixedAnnual for creation.
   2025-27-Jan 17:25:22.565 Queued constraint OC3_OperatingCostsTotalAnnual for creation.
   2025-27-Jan 17:25:22.758 Queued constraint OC4_DiscountedOperatingCostsTotalAnnual for creation.
   2025-27-Jan 17:25:22.758 Queued constraint TDC1_TotalDiscountedCostByTechnology for creation.
   2025-27-Jan 17:25:22.760 Queued constraint TDC2_TotalDiscountedCost for creation.
   2025-27-Jan 17:25:23.116 Queued constraint TCC1_TotalAnnualMaxCapacityConstraint for creation.
   2025-27-Jan 17:25:23.116 Queued constraint TCC2_TotalAnnualMinCapacityConstraint for creation.
   2025-27-Jan 17:25:23.116 Queued constraint NCC1_TotalAnnualMaxNewCapacityConstraint for creation.
   2025-27-Jan 17:25:23.116 Queued constraint NCC2_TotalAnnualMinNewCapacityConstraint for creation.
   2025-27-Jan 17:25:23.116 Queued constraint AAC1_TotalAnnualTechnologyActivity for creation.
   2025-27-Jan 17:25:23.119 Queued constraint AAC2_TotalAnnualTechnologyActivityUpperLimit for creation.
   2025-27-Jan 17:25:23.119 Queued constraint TAC1_TotalModelHorizonTechnologyActivity for creation.
   2025-27-Jan 17:25:23.121 Queued constraint TAC2_TotalModelHorizonTechnologyActivityUpperLimit for creation.
   2025-27-Jan 17:25:23.121 Queued constraint RM1_TotalCapacityInReserveMargin for creation.
   2025-27-Jan 17:25:23.240 Queued constraint RM2_ReserveMargin for creation.
   2025-27-Jan 17:25:23.242 Queued constraint RE1_FuelProductionByTechnologyAnnual for creation.
   2025-27-Jan 17:25:23.242 Queued constraint FuelUseByTechnologyAnnual for creation.
   2025-27-Jan 17:25:23.619 Queued constraint RE2_ProductionTarget for creation.
   2025-27-Jan 17:25:23.619 Queued constraint RE3_ProductionTargetRG for creation.
   2025-27-Jan 17:25:23.619 Queued constraint MinShareProduction for creation.
   2025-27-Jan 17:25:23.619 Queued constraint E2a_AnnualEmissionProduction for creation.
   2025-27-Jan 17:25:23.619 Queued constraint E2b_AnnualEmissionProduction for creation.
   2025-27-Jan 17:25:23.619 Queued constraint E4_EmissionsPenaltyByTechnology for creation.
   2025-27-Jan 17:25:23.629 Queued constraint E5_DiscountedEmissionsPenaltyByTechnology for creation.
   2025-27-Jan 17:25:23.629 Queued constraint E6_EmissionsAccounting1 for creation.
   2025-27-Jan 17:25:23.629 Queued constraint E7_EmissionsAccounting2 for creation.
   2025-27-Jan 17:25:23.629 Queued constraint E8_AnnualEmissionsLimit for creation.
   2025-27-Jan 17:25:23.631 Queued constraint E9_ModelPeriodEmissionsLimit for creation.
   2025-27-Jan 17:25:23.631 Queued 96 standard constraints for creation.
   2025-27-Jan 17:25:24.123 Finished scheduled task to add constraints to model.
   2025-27-Jan 17:25:24.123 Added 96 standard constraints to model.
   2025-27-Jan 17:25:24.633 Defined model objective.
   Presolve 10228 (-37342) rows, 6820 (-35865) columns and 39688 (-92498) elements
   0  Obj 0 Primal inf 6487.7369 (970) Dual inf 8.5145975e+13 (1650)
   Perturbing problem by 0.001% of 3.6447106e+08 - largest nonzero change 0.38417053 ( 0.15875796%) - largest zero change 0
   276  Obj 186.27609 Primal inf 6046.4562 (1002) Dual inf 9.4640788e+13 (1670)
   552  Obj 475.87217 Primal inf 5222.1136 (997) Dual inf 2.586304e+08 (2463)
   828  Obj 1063.8873 Primal inf 4148.1789 (974) Dual inf 1.6838158e+08 (2317)
   1104  Obj 1458.7195 Primal inf 3500.5169 (975) Dual inf 1.3598288e+08 (2455)
   1380  Obj 1458.7195 Primal inf 3500.3187 (974) Dual inf 1.2080351e+08 (2780)
   1656  Obj 7202.321 Primal inf 3113.9073 (904) Dual inf 3.1519397e+08 (2867)
   1932  Obj 7202.321 Primal inf 3104.3759 (851) Dual inf 3.1039866e+08 (2838)
   2208  Obj 11808.89 Primal inf 2889.8035 (739) Dual inf 69595534 (1803)
   2484  Obj 13485.971 Primal inf 2578.8605 (653) Dual inf 64776935 (1726)
   2760  Obj 16272.205 Primal inf 2227.0354 (597) Dual inf 60934379 (1836)
   3037  Obj 18242.759 Primal inf 1504.3665 (526) Dual inf 1.5731063e+08 (1709)
   3313  Obj 19824.654 Primal inf 723.86728 (485) Dual inf 35439596 (1929)
   3589  Obj 19832.872 Primal inf 527.79549 (381) Dual inf 47961935 (1548)
   3874  Obj 22169.16 Primal inf 279.05023 (288) Dual inf 1.0149285e+08 (1556)
   4156  Obj 21364.089 Primal inf 72.536748 (148) Dual inf 1.1626931e+08 (1484)
   4435  Obj 20744.822 Primal inf 4.8251511 (37) Dual inf 1806070.3 (1200)
   4711  Obj 16683.758 Dual inf 22642.601 (732)
   4987  Obj 8374.4102 Dual inf 13305.05 (662)
   5194  Obj 8276.7194 Dual inf 20792.502 (753)
   5422  Obj 6311.8798 Dual inf 23387.805 (687)
   5601  Obj 5459.6061 Dual inf 32254.725 (601)
   5799  Obj 5136.3211 Dual inf 67681.878 (395)
   6001  Obj 4952.6229 Dual inf 7914.4501 (383)
   6277  Obj 4939.5663 Dual inf 2235.8158 (260)
   6497  Obj 4939.5569
   6497  Obj 4938.908 Primal inf 0.00012448052 (22)
   6634  Obj 4938.9081
   Optimal - objective value 4938.9081
   After Postsolve, objective 4938.9081, infeasibilities - dual 0 (0), primal 8.6351389e-06 (10)
   Presolved model was optimal, full model needs cleaning up
   0  Obj 4938.9081 Primal inf 168.12036 (28)
   18  Obj 4938.9081
   Optimal - objective value 4938.9081
   Optimal objective 4938.908111 - 6652 iterations time 0.442, Presolve 0.05
   2025-27-Jan 17:25:26.446 Solved model. Solver status = OPTIMAL.
   2025-27-Jan 17:25:26.677 Saved results for vdemandnn to database.
   2025-27-Jan 17:25:26.717 Saved results for vnewcapacity to database.
   2025-27-Jan 17:25:26.717 Saved results for vtotalcapacityannual to database.
   2025-27-Jan 17:25:26.811 Saved results for vproductionbytechnologyannual to database.
   2025-27-Jan 17:25:26.825 Saved results for vproductionnn to database.
   2025-27-Jan 17:25:26.827 Saved results for vusebytechnologyannual to database.
   2025-27-Jan 17:25:26.869 Saved results for vusenn to database.
   2025-27-Jan 17:25:26.896 Saved results for vtotaldiscountedcost to database.
   2025-27-Jan 17:25:26.896 Finished saving results to database.
   2025-27-Jan 17:25:26.896 Finished optimizing all years for scenario.
   2025-27-Jan 17:25:26.900 Dropped temporary tables.
   2025-27-Jan 17:25:26.900 Finished modeling scenario.
   ```

   Selected results are now saved in the database.

   !!! tip
       To change which results are saved and set other run-time options, see [Calculating a scenario](@ref scenario_calc).

For a better understanding of what happens in scenario calculations - and guidance on building your own model - look through the rest of the documentation, particularly [Modeling concept](@ref modeling_concept) and the sections on Inputs and Outputs.
