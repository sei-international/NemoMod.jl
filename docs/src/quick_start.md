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

   julia> NemoMod.calculatescenario(dbpath; jumpmodel=Model(solver=CbcSolver()))
   ```

   The first command activates the Julia packages for NEMO, JuMP (an optimization toolkit that NEMO uses), and Cbc (a solver). The next two commands locate the test scenario's [database](@ref scenario_db) and ensure this file is writable (so NEMO can save scenario results). The final command calculates the scenario. You should see output like the following:

   ```
   2020-09-Sep 15:12:17.164 Started scenario calculation.
   2020-09-Sep 15:12:17.165 Validated run-time arguments.
   2020-09-Sep 15:12:17.226 0 specified for numprocs argument. Using 8 processes for parallelized operations.
   2020-09-Sep 15:13:15.411 Loaded NEMO on parallel processes 1, 2, 3, 4, 5, 6, 7, 8.
   2020-09-Sep 15:13:15.411 Connected to scenario database. Path = c:/temp/storage_test.sqlite.
   2020-09-Sep 15:13:16.035 Dropped pre-existing result tables from database.
   2020-09-Sep 15:13:16.037 Verified that transmission modeling is not enabled.
   2020-09-Sep 15:13:16.299 Created parameter views and indices.
   2020-09-Sep 15:13:16.321 Created temporary tables.
   2020-09-Sep 15:13:18.459 Executed core database queries.
   2020-09-Sep 15:13:18.613 Defined dimensions.
   2020-09-Sep 15:13:18.626 Defined demand variables.
   2020-09-Sep 15:13:18.628 Defined storage variables.
   2020-09-Sep 15:13:18.629 Defined capacity variables.
   2020-09-Sep 15:13:18.873 Defined activity variables.
   2020-09-Sep 15:13:18.874 Defined costing variables.
   2020-09-Sep 15:13:18.875 Defined reserve margin variables.
   2020-09-Sep 15:13:18.882 Defined renewable energy target variables.
   2020-09-Sep 15:13:18.883 Defined emissions variables.
   2020-09-Sep 15:13:18.883 Defined combined nodal and non-nodal variables.
   2020-09-Sep 15:13:18.884 Finished defining model variables.
   2020-09-Sep 15:13:18.908 Created constraint CAa1_TotalNewCapacity.
   2020-09-Sep 15:13:18.920 Created constraint CAa2_TotalAnnualCapacity.
   2020-09-Sep 15:13:18.931 Created constraint CAa3_TotalActivityOfEachTechnology.
   2020-09-Sep 15:13:18.964 Created constraint CAa4_Constraint_Capacity.
   2020-09-Sep 15:13:18.978 Created constraint EBa2_RateOfFuelProduction2.
   2020-09-Sep 15:13:19.003 Created constraint EBa3_RateOfFuelProduction3.
   2020-09-Sep 15:13:19.006 Created constraint VRateOfProduction1.
   2020-09-Sep 15:13:19.012 Created constraint EBa5_RateOfFuelUse2.
   2020-09-Sep 15:13:19.022 Created constraint EBa6_RateOfFuelUse3.
   2020-09-Sep 15:13:19.032 Created constraint VRateOfUse1.
   2020-09-Sep 15:13:19.052 Created constraint EBa7_EnergyBalanceEachTS1.
   2020-09-Sep 15:13:19.056 Created constraint EBa8_EnergyBalanceEachTS2.
   2020-09-Sep 15:13:19.065 Created constraint EBa9_EnergyBalanceEachTS3.
   2020-09-Sep 15:13:19.073 Created constraint EBa10_EnergyBalanceEachTS4.
   2020-09-Sep 15:13:19.092 Created constraint EBa11_EnergyBalanceEachTS5.
   2020-09-Sep 15:13:19.098 Created constraint EBb0_EnergyBalanceEachYear.
   2020-09-Sep 15:13:19.100 Created constraint EBb1_EnergyBalanceEachYear.
   2020-09-Sep 15:13:19.101 Created constraint EBb2_EnergyBalanceEachYear.
   2020-09-Sep 15:13:19.103 Created constraint EBb3_EnergyBalanceEachYear.
   2020-09-Sep 15:13:19.114 Created constraint EBb5_EnergyBalanceEachYear.
   2020-09-Sep 15:13:19.150 Created constraint Acc3_AverageAnnualRateOfActivity.
   2020-09-Sep 15:13:19.157 Created constraint NS1_RateOfStorageCharge.
   2020-09-Sep 15:13:19.163 Created constraint NS2_RateOfStorageDischarge.
   2020-09-Sep 15:13:19.350 Created constraint NS3_StorageLevelTsGroup1Start.
   2020-09-Sep 15:13:19.350 Created constraint NS4_StorageLevelTsGroup2Start.
   2020-09-Sep 15:13:19.351 Created constraint NS5_StorageLevelTimesliceEnd.
   2020-09-Sep 15:13:19.353 Created constraint NS6_StorageLevelTsGroup2End.
   2020-09-Sep 15:13:19.362 Created constraint NS7_StorageLevelTsGroup1End.
   2020-09-Sep 15:13:19.409 Created constraint NS8_StorageLevelYearEnd.
   2020-09-Sep 15:13:19.410 Created constraint SI1_StorageUpperLimit.
   2020-09-Sep 15:13:19.410 Created constraint SI2_StorageLowerLimit.
   2020-09-Sep 15:13:19.411 Created constraint SI3_TotalNewStorage.
   2020-09-Sep 15:13:19.415 Created constraint NS9a_StorageLevelTsLowerLimit.
   2020-09-Sep 15:13:19.416 Created constraint NS9b_StorageLevelTsUpperLimit.
   2020-09-Sep 15:13:19.419 Created constraint NS10_StorageChargeLimit.
   2020-09-Sep 15:13:19.423 Created constraint NS11_StorageDischargeLimit.
   2020-09-Sep 15:13:19.433 Created constraint NS12a_StorageLevelTsGroup2LowerLimit.
   2020-09-Sep 15:13:19.433 Created constraint NS12b_StorageLevelTsGroup2UpperLimit.
   2020-09-Sep 15:13:19.434 Created constraint NS13a_StorageLevelTsGroup1LowerLimit.
   2020-09-Sep 15:13:19.434 Created constraint NS13b_StorageLevelTsGroup1UpperLimit.
   2020-09-Sep 15:13:19.445 Created constraint NS18_FullLoadHours.
   2020-09-Sep 15:13:19.446 Created constraint SI4_UndiscountedCapitalInvestmentStorage.
   2020-09-Sep 15:13:19.454 Created constraint SI5_DiscountingCapitalInvestmentStorage.
   2020-09-Sep 15:13:19.539 Created constraint SI8_SalvageValueStorageAtEndOfPeriod3.
   2020-09-Sep 15:13:19.541 Created constraint SI9_SalvageValueStorageDiscountedToStartYear.
   2020-09-Sep 15:13:19.541 Created constraint SI10_TotalDiscountedCostByStorage.
   2020-09-Sep 15:13:19.542 Created constraint CC1_UndiscountedCapitalInvestment.
   2020-09-Sep 15:13:19.546 Created constraint CC2_DiscountingCapitalInvestment.
   2020-09-Sep 15:13:19.605 Created constraint SV1_SalvageValueAtEndOfPeriod1.
   2020-09-Sep 15:13:19.608 Created constraint SV4_SalvageValueDiscountedToStartYear.
   2020-09-Sep 15:13:19.609 Created constraint OC1_OperatingCostsVariable.
   2020-09-Sep 15:13:19.610 Created constraint OC2_OperatingCostsFixedAnnual.
   2020-09-Sep 15:13:19.611 Created constraint OC3_OperatingCostsTotalAnnual.
   2020-09-Sep 15:13:19.613 Created constraint OC4_DiscountedOperatingCostsTotalAnnual.
   2020-09-Sep 15:13:19.614 Created constraint TDC1_TotalDiscountedCostByTechnology.
   2020-09-Sep 15:13:19.614 Created constraint TDC2_TotalDiscountedCost.
   2020-09-Sep 15:13:19.615 Created constraint TCC1_TotalAnnualMaxCapacityConstraint.
   2020-09-Sep 15:13:19.616 Created constraint NCC1_TotalAnnualMaxNewCapacityConstraint.
   2020-09-Sep 15:13:19.622 Created constraint RM1_ReserveMargin_TechnologiesIncluded_In_Activity_Units.
   2020-09-Sep 15:13:19.637 Created constraint RM2_ReserveMargin_FuelsIncluded.
   2020-09-Sep 15:13:19.648 Created constraint RM3_ReserveMargin_Constraint.
   2020-09-Sep 15:13:19.657 Created constraint RE1_FuelProductionByTechnologyAnnual.
   2020-09-Sep 15:13:19.664 Created constraint FuelUseByTechnologyAnnual.
   2020-09-Sep 15:13:19.669 Created constraint E5_DiscountedEmissionsPenaltyByTechnology.
   2020-09-Sep 15:13:19.673 Defined model objective.
   2020-09-Sep 15:13:27.161 Solved model. Solver status = Optimal.
   2020-09-Sep 15:13:27.368 Saved results for vdemandnn to database.
   2020-09-Sep 15:13:27.501 Saved results for vnewcapacity to database.
   2020-09-Sep 15:13:27.517 Saved results for vtotalcapacityannual to database.
   2020-09-Sep 15:13:27.897 Saved results for vproductionbytechnologyannual to database.
   2020-09-Sep 15:13:27.921 Saved results for vproductionnn to database.
   2020-09-Sep 15:13:27.942 Saved results for vusebytechnologyannual to database.
   2020-09-Sep 15:13:27.968 Saved results for vusenn to database.
   2020-09-Sep 15:13:28.091 Saved results for vtotaldiscountedcost to database.
   2020-09-Sep 15:13:28.091 Finished saving results to database.
   2020-09-Sep 15:13:28.107 Dropped temporary tables.
   2020-09-Sep 15:13:28.108 Finished scenario calculation.
   :Optimal
   ```

   Selected results are now saved in the database.

   !!! tip
       To change which results are saved and set other run-time options, see [Calculating a scenario](@ref scenario_calc).

For a better understanding of what happens in scenario calculations - and guidance on building your own model - look through the rest of the documentation, particularly [Model concept](@ref model_concept) and the sections on Inputs and Outputs.
