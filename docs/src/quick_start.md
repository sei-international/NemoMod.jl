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
   2020-18-May 16:11:35.568 Started scenario calculation.
   2020-18-May 16:11:35.572 Validated run-time arguments.
   2020-18-May 16:11:35.573 Connected to scenario database. Path = C:\Users\Jason\.julia\packages\NemoMod\Pq841\test\storage_test.sqlite.
   2020-18-May 16:11:35.575 Dropped pre-existing result tables from database.
   2020-18-May 16:11:35.581 Verified that transmission modeling is not enabled.
   2020-18-May 16:11:35.621 Created parameter views and indices.
   2020-18-May 16:11:35.624 Defined dimensions.
   2020-18-May 16:11:35.625 Defined demand variables.
   2020-18-May 16:11:35.628 Defined storage variables.
   2020-18-May 16:11:35.632 Defined capacity variables.
   2020-18-May 16:11:35.799 Defined activity variables.
   2020-18-May 16:11:35.800 Defined costing variables.
   2020-18-May 16:11:35.801 Defined reserve margin variables.
   2020-18-May 16:11:35.805 Defined renewable energy target variables.
   2020-18-May 16:11:35.806 Defined emissions variables.
   2020-18-May 16:11:35.807 Defined combined nodal and non-nodal variables.
   2020-18-May 16:11:35.807 Finished defining model variables.
   2020-18-May 16:11:35.809 Created constraint CAa1_TotalNewCapacity.
   2020-18-May 16:11:35.809 Created constraint CAa2_TotalAnnualCapacity.
   2020-18-May 16:11:35.818 Created constraint CAa3_TotalActivityOfEachTechnology.
   2020-18-May 16:11:35.845 Created constraint CAa4_Constraint_Capacity.
   2020-18-May 16:11:35.949 Created constraint EBa2_RateOfFuelProduction2.
   2020-18-May 16:11:35.959 Created constraint EBa3_RateOfFuelProduction3.
   2020-18-May 16:11:35.962 Created constraint VRateOfProduction1.
   2020-18-May 16:11:35.971 Created constraint EBa5_RateOfFuelUse2.
   2020-18-May 16:11:35.977 Created constraint EBa6_RateOfFuelUse3.
   2020-18-May 16:11:35.982 Created constraint VRateOfUse1.
   2020-18-May 16:11:36.000 Created constraint EBa7_EnergyBalanceEachTS1.
   2020-18-May 16:11:36.001 Created constraint EBa8_EnergyBalanceEachTS2.
   2020-18-May 16:11:36.012 Created constraint EBa9_EnergyBalanceEachTS3.
   2020-18-May 16:11:36.016 Created constraint EBa10_EnergyBalanceEachTS4.
   2020-18-May 16:11:36.036 Created constraint EBa11_EnergyBalanceEachTS5.
   2020-18-May 16:11:36.038 Created constraint EBb0_EnergyBalanceEachYear.
   2020-18-May 16:11:36.040 Created constraint EBb1_EnergyBalanceEachYear.
   2020-18-May 16:11:36.041 Created constraint EBb2_EnergyBalanceEachYear.
   2020-18-May 16:11:36.043 Created constraint EBb3_EnergyBalanceEachYear.
   2020-18-May 16:11:36.048 Created constraint EBb5_EnergyBalanceEachYear.
   2020-18-May 16:11:36.084 Created constraint Acc3_AverageAnnualRateOfActivity.
   2020-18-May 16:11:36.092 Created constraint NS1_RateOfStorageCharge.
   2020-18-May 16:11:36.099 Created constraint NS2_RateOfStorageDischarge.
   2020-18-May 16:11:36.107 Created constraint NS3_StorageLevelTsGroup1Start.
   2020-18-May 16:11:36.108 Created constraint NS4_StorageLevelTsGroup2Start.
   2020-18-May 16:11:36.113 Created constraint NS5_StorageLevelTimesliceEnd.
   2020-18-May 16:11:36.116 Created constraint NS6_StorageLevelTsGroup2End.
   2020-18-May 16:11:36.117 Created constraint NS7_StorageLevelTsGroup1End.
   2020-18-May 16:11:36.127 Created constraint NS8_StorageLevelYearEnd.
   2020-18-May 16:11:36.127 Created constraint SI1_StorageUpperLimit.
   2020-18-May 16:11:36.128 Created constraint SI2_StorageLowerLimit.
   2020-18-May 16:11:36.129 Created constraint SI3_TotalNewStorage.
   2020-18-May 16:11:36.133 Created constraint NS9a_StorageLevelTsLowerLimit.
   2020-18-May 16:11:36.134 Created constraint NS9b_StorageLevelTsUpperLimit.
   2020-18-May 16:11:36.138 Created constraint NS10_StorageChargeLimit.
   2020-18-May 16:11:36.144 Created constraint NS11_StorageDischargeLimit.
   2020-18-May 16:11:36.145 Created constraint NS12a_StorageLevelTsGroup2LowerLimit.
   2020-18-May 16:11:36.146 Created constraint NS12b_StorageLevelTsGroup2UpperLimit.
   2020-18-May 16:11:36.147 Created constraint NS13a_StorageLevelTsGroup1LowerLimit.
   2020-18-May 16:11:36.147 Created constraint NS13b_StorageLevelTsGroup1UpperLimit.
   2020-18-May 16:11:36.148 Created constraint NS18_FullLoadHours.
   2020-18-May 16:11:36.153 Created constraint SI4_UndiscountedCapitalInvestmentStorage.
   2020-18-May 16:11:36.154 Created constraint SI5_DiscountingCapitalInvestmentStorage.
   2020-18-May 16:11:36.156 Created constraint SI8_SalvageValueStorageAtEndOfPeriod3.
   2020-18-May 16:11:36.157 Created constraint SI9_SalvageValueStorageDiscountedToStartYear.
   2020-18-May 16:11:36.157 Created constraint SI10_TotalDiscountedCostByStorage.
   2020-18-May 16:11:36.158 Created constraint CC1_UndiscountedCapitalInvestment.
   2020-18-May 16:11:36.161 Created constraint CC2_DiscountingCapitalInvestment.
   2020-18-May 16:11:36.169 Created constraint SV1_SalvageValueAtEndOfPeriod1.
   2020-18-May 16:11:36.173 Created constraint SV4_SalvageValueDiscountedToStartYear.
   2020-18-May 16:11:36.173 Created constraint OC1_OperatingCostsVariable.
   2020-18-May 16:11:36.174 Created constraint OC2_OperatingCostsFixedAnnual.
   2020-18-May 16:11:36.175 Created constraint OC3_OperatingCostsTotalAnnual.
   2020-18-May 16:11:36.183 Created constraint OC4_DiscountedOperatingCostsTotalAnnual.
   2020-18-May 16:11:36.184 Created constraint TDC1_TotalDiscountedCostByTechnology.
   2020-18-May 16:11:36.184 Created constraint TDC2_TotalDiscountedCost.
   2020-18-May 16:11:36.185 Created constraint TCC1_TotalAnnualMaxCapacityConstraint.
   2020-18-May 16:11:36.185 Created constraint NCC1_TotalAnnualMaxNewCapacityConstraint.
   2020-18-May 16:11:36.186 Created constraint RM1_ReserveMargin_TechnologiesIncluded_In_Activity_Units.
   2020-18-May 16:11:36.191 Created constraint RM2_ReserveMargin_FuelsIncluded.
   2020-18-May 16:11:36.197 Created constraint RM3_ReserveMargin_Constraint.
   2020-18-May 16:11:36.204 Created constraint RE1_FuelProductionByTechnologyAnnual.
   2020-18-May 16:11:36.210 Created constraint FuelUseByTechnologyAnnual.
   2020-18-May 16:11:36.217 Created constraint E5_DiscountedEmissionsPenaltyByTechnology.
   2020-18-May 16:11:36.221 Defined model objective.
   2020-18-May 16:11:43.500 Solved model. Solver status = Optimal.
   2020-18-May 16:11:43.524 Saved results for vdemandnn to database.
   2020-18-May 16:11:43.542 Saved results for vnewcapacity to database.
   2020-18-May 16:11:43.557 Saved results for vtotalcapacityannual to database.
   2020-18-May 16:11:43.575 Saved results for vproductionbytechnologyannual to database.
   2020-18-May 16:11:43.601 Saved results for vproductionnn to database.
   2020-18-May 16:11:43.616 Saved results for vusebytechnologyannual to database.
   2020-18-May 16:11:43.638 Saved results for vusenn to database.
   2020-18-May 16:11:43.652 Saved results for vtotaldiscountedcost to database.
   2020-18-May 16:11:43.654 Finished saving results to database.
   2020-18-May 16:11:43.654 Finished scenario calculation.
   :Optimal
   ```

   Selected results are now saved in the database.

   !!! tip
       To change which results are saved and set other run-time options, see [Calculating a scenario](@ref scenario_calc).

For a better understanding of what happens in scenario calculations - and guidance on building your own model - look through the rest of the documentation, particularly [Model concept](@ref model_concept) and the sections on Inputs and Outputs.
