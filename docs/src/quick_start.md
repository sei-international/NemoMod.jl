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
   2021-04-Feb 11:39:37.467 Started scenario calculation.
   2021-04-Feb 11:39:37.467 Validated run-time arguments.
   2021-04-Feb 11:39:37.468 0 specified for numprocs argument. Using 8 processes for parallelized operations.
   2021-04-Feb 11:39:37.475 Loaded NEMO on parallel processes 1, 2, 3, 4, 5, 6, 7, 8.
   2021-04-Feb 11:39:37.476 Connected to scenario database. Path = C:\Users\Jason\.julia\packages\NemoMod\rIAZV\test\storage_test.sqlite.
   2021-04-Feb 11:39:37.478 Dropped pre-existing result tables from database.
   2021-04-Feb 11:39:37.479 Verified that transmission modeling is not enabled.
   2021-04-Feb 11:39:37.520 Created parameter views and indices.
   2021-04-Feb 11:39:37.538 Created temporary tables.
   2021-04-Feb 11:39:37.568 Executed core database queries.
   2021-04-Feb 11:39:37.570 Defined dimensions.
   2021-04-Feb 11:39:37.572 Defined demand variables.
   2021-04-Feb 11:39:37.573 Defined storage variables.
   2021-04-Feb 11:39:37.574 Defined capacity variables.
   2021-04-Feb 11:39:37.659 Defined activity variables.
   2021-04-Feb 11:39:37.659 Defined costing variables.
   2021-04-Feb 11:39:37.660 Defined reserve margin variables.
   2021-04-Feb 11:39:37.661 Defined renewable energy target variables.
   2021-04-Feb 11:39:37.664 Defined emissions variables.
   2021-04-Feb 11:39:37.664 Defined combined nodal and non-nodal variables.
   2021-04-Feb 11:39:37.664 Finished defining model variables.
   2021-04-Feb 11:39:37.891 Created constraint CAa1_TotalNewCapacity.
   2021-04-Feb 11:39:37.892 Created constraint CAa2_TotalAnnualCapacity.
   2021-04-Feb 11:39:37.901 Created constraint CAa3_TotalActivityOfEachTechnology.
   2021-04-Feb 11:39:37.964 Created constraint CAa4_Constraint_Capacity.
   2021-04-Feb 11:39:37.985 Created constraint EBa2_RateOfFuelProduction2.
   2021-04-Feb 11:39:37.995 Created constraint EBa3_RateOfFuelProduction3.
   2021-04-Feb 11:39:37.999 Created constraint VRateOfProduction1.
   2021-04-Feb 11:39:38.012 Created constraint EBa5_RateOfFuelUse2.
   2021-04-Feb 11:39:38.019 Created constraint EBa6_RateOfFuelUse3.
   2021-04-Feb 11:39:38.022 Created constraint VRateOfUse1.
   2021-04-Feb 11:39:38.041 Created constraint EBa7_EnergyBalanceEachTS1.
   2021-04-Feb 11:39:38.042 Created constraint EBa8_EnergyBalanceEachTS2.
   2021-04-Feb 11:39:38.049 Created constraint EBa9_EnergyBalanceEachTS3.
   2021-04-Feb 11:39:38.052 Created constraint EBa10_EnergyBalanceEachTS4.
   2021-04-Feb 11:39:38.135 Created constraint EBa11_EnergyBalanceEachTS5.
   2021-04-Feb 11:39:38.136 Created constraint EBb0_EnergyBalanceEachYear.
   2021-04-Feb 11:39:38.137 Created constraint EBb1_EnergyBalanceEachYear.
   2021-04-Feb 11:39:38.139 Created constraint EBb2_EnergyBalanceEachYear.
   2021-04-Feb 11:39:38.140 Created constraint EBb3_EnergyBalanceEachYear.
   2021-04-Feb 11:39:38.141 Created constraint EBb5_EnergyBalanceEachYear.
   2021-04-Feb 11:39:38.187 Created constraint Acc3_AverageAnnualRateOfActivity.
   2021-04-Feb 11:39:38.195 Created constraint NS1_RateOfStorageCharge.
   2021-04-Feb 11:39:38.203 Created constraint NS2_RateOfStorageDischarge.
   2021-04-Feb 11:39:38.212 Created constraint NS3_StorageLevelTsGroup1Start.
   2021-04-Feb 11:39:38.212 Created constraint NS4_StorageLevelTsGroup2Start.
   2021-04-Feb 11:39:38.212 Created constraint NS5_StorageLevelTimesliceEnd.
   2021-04-Feb 11:39:38.215 Created constraint NS6_StorageLevelTsGroup2End.
   2021-04-Feb 11:39:38.218 Created constraint NS7_StorageLevelTsGroup1End.
   2021-04-Feb 11:39:38.228 Created constraint NS8_StorageLevelYearEnd.
   2021-04-Feb 11:39:38.231 Created constraint SI1_StorageUpperLimit.
   2021-04-Feb 11:39:38.232 Created constraint SI2_StorageLowerLimit.
   2021-04-Feb 11:39:38.233 Created constraint SI3_TotalNewStorage.
   2021-04-Feb 11:39:38.238 Created constraint NS9a_StorageLevelTsLowerLimit.
   2021-04-Feb 11:39:38.238 Created constraint NS9b_StorageLevelTsUpperLimit.
   2021-04-Feb 11:39:38.243 Created constraint NS10_StorageChargeLimit.
   2021-04-Feb 11:39:38.248 Created constraint NS11_StorageDischargeLimit.
   2021-04-Feb 11:39:38.249 Created constraint NS12a_StorageLevelTsGroup2LowerLimit.
   2021-04-Feb 11:39:38.250 Created constraint NS12b_StorageLevelTsGroup2UpperLimit.
   2021-04-Feb 11:39:38.250 Created constraint NS13a_StorageLevelTsGroup1LowerLimit.
   2021-04-Feb 11:39:38.251 Created constraint NS13b_StorageLevelTsGroup1UpperLimit.
   2021-04-Feb 11:39:38.252 Created constraint NS18_FullLoadHours.
   2021-04-Feb 11:39:38.252 Created constraint SI4_UndiscountedCapitalInvestmentStorage.
   2021-04-Feb 11:39:38.254 Created constraint SI5_DiscountingCapitalInvestmentStorage.
   2021-04-Feb 11:39:38.256 Created constraint SI8_SalvageValueStorageAtEndOfPeriod3.
   2021-04-Feb 11:39:38.259 Created constraint SI9_SalvageValueStorageDiscountedToStartYear.
   2021-04-Feb 11:39:38.259 Created constraint SI10_TotalDiscountedCostByStorage.
   2021-04-Feb 11:39:38.260 Created constraint CC1_UndiscountedCapitalInvestment.
   2021-04-Feb 11:39:38.263 Created constraint CC2_DiscountingCapitalInvestment.
   2021-04-Feb 11:39:38.266 Created constraint SV1_SalvageValueAtEndOfPeriod1.
   2021-04-Feb 11:39:38.269 Created constraint SV4_SalvageValueDiscountedToStartYear.
   2021-04-Feb 11:39:38.272 Created constraint OC1_OperatingCostsVariable.
   2021-04-Feb 11:39:38.272 Created constraint OC2_OperatingCostsFixedAnnual.
   2021-04-Feb 11:39:38.273 Created constraint OC3_OperatingCostsTotalAnnual.
   2021-04-Feb 11:39:38.275 Created constraint OC4_DiscountedOperatingCostsTotalAnnual.
   2021-04-Feb 11:39:38.276 Created constraint TDC1_TotalDiscountedCostByTechnology.
   2021-04-Feb 11:39:38.276 Created constraint TDC2_TotalDiscountedCost.
   2021-04-Feb 11:39:38.277 Created constraint TCC1_TotalAnnualMaxCapacityConstraint.
   2021-04-Feb 11:39:38.277 Created constraint NCC1_TotalAnnualMaxNewCapacityConstraint.
   2021-04-Feb 11:39:38.278 Created constraint RM1_ReserveMargin_TechnologiesIncluded_In_Activity_Units.
   2021-04-Feb 11:39:38.284 Created constraint RM2_ReserveMargin_FuelsIncluded.
   2021-04-Feb 11:39:38.289 Created constraint RM3_ReserveMargin_Constraint.
   2021-04-Feb 11:39:38.298 Created constraint RE1_FuelProductionByTechnologyAnnual.
   2021-04-Feb 11:39:38.304 Created constraint FuelUseByTechnologyAnnual.
   2021-04-Feb 11:39:38.309 Created constraint E5_DiscountedEmissionsPenaltyByTechnology.
   2021-04-Feb 11:39:38.332 Defined model objective.
   Welcome to the CBC MILP Solver
   Version: 2.10.3
   Build Date: Jan  1 1970

   command line - Cbc_C_Interface -solve -quit (default strategy 1)
   Presolve 9293 (-41997) rows, 5890 (-44330) columns and 31399 (-107297) elements
   Perturbing problem by 0.001% of 7521.1615 - largest nonzero change 0.00097678552 ( 0.10012424%) - largest zero change 0.00096270583
   0  Obj 0.17904845 Primal inf 18452.21 (2370)
   260  Obj 0.39471165 Primal inf 13588.46 (1538)
   520  Obj 2532.6086 Primal inf 9707.3537 (1340)
   780  Obj 2532.749 Primal inf 11146.306 (1311)
   1040  Obj 3038.723 Primal inf 9676.7641 (1349)
   1300  Obj 3597.6499 Primal inf 8472.5415 (1392)
   1560  Obj 3871.9152 Primal inf 8061.2059 (1402)
   1820  Obj 4097.3639 Primal inf 5934.2015 (1213)
   2080  Obj 4097.4172 Primal inf 5157.4707 (982)
   2340  Obj 4097.4617 Primal inf 3092.8969 (944)
   2600  Obj 4097.494 Primal inf 6083.789 (868)
   2860  Obj 4097.53 Primal inf 3320.2749 (759)
   3120  Obj 4825.1161 Primal inf 6950.1275 (894)
   3380  Obj 4825.1487 Primal inf 3965.5744 (604)
   3640  Obj 4827.3542 Primal inf 1802.1487 (468)
   3863  Obj 4874.8066 Primal inf 92243.681 (595)
   4012  Obj 4940.2696 Primal inf 513.05983 (165)
   4200  Obj 4940.4196
   4200  Obj 4938.9081 Dual inf 3.4058312e-06 (3)
   Optimal - objective value 4938.9081
   After Postsolve, objective 4938.9081, infeasibilities - dual 8.4347676e-05 (27), primal 0.00066659824 (22)
   Presolved model was optimal, full model needs cleaning up
   0  Obj 4938.9081 Primal inf 435.30667 (73) Dual inf 1.7372787e-05 (51)
   0  Obj 4938.9081 Primal inf 435.30667 (73) Dual inf 3.1074001e+14 (2431)
   200  Obj 4938.9081 Dual inf 83.775128 (376)
   262  Obj 4938.9081
   Optimal - objective value 4938.9081
   Optimal objective 4938.90811 - 4462 iterations time 0.472, Presolve 0.09
   Total time (CPU seconds):       0.48   (Wallclock seconds):       0.48

   2021-04-Feb 11:39:43.160 Solved model. Solver status = OPTIMAL.
   2021-04-Feb 11:39:43.228 Saved results for vdemandnn to database.
   2021-04-Feb 11:39:43.244 Saved results for vnewcapacity to database.
   2021-04-Feb 11:39:43.262 Saved results for vtotalcapacityannual to database.
   2021-04-Feb 11:39:43.282 Saved results for vproductionbytechnologyannual to database.
   2021-04-Feb 11:39:43.314 Saved results for vproductionnn to database.
   2021-04-Feb 11:39:43.331 Saved results for vusebytechnologyannual to database.
   2021-04-Feb 11:39:43.358 Saved results for vusenn to database.
   2021-04-Feb 11:39:43.383 Saved results for vtotaldiscountedcost to database.
   2021-04-Feb 11:39:43.384 Finished saving results to database.
   2021-04-Feb 11:39:43.399 Dropped temporary tables.
   2021-04-Feb 11:39:43.400 Finished scenario calculation.
   OPTIMAL::TerminationStatusCode = 1
   ```

   Selected results are now saved in the database.

   !!! tip
       To change which results are saved and set other run-time options, see [Calculating a scenario](@ref scenario_calc).

For a better understanding of what happens in scenario calculations - and guidance on building your own model - look through the rest of the documentation, particularly [Model concept](@ref model_concept) and the sections on Inputs and Outputs.
