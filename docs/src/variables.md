```@meta
CurrentModule = NemoMod
```
# [Variables](@id variables)

Variables are the outputs from calculating a scenario. They show the decisions taken to solve the optimization problem. When you calculate a scenario, you can choose which variables to output (see the `varstosave` argument of [`calculatescenario`](@ref)). NEMO will then save the selected variables in the [scenario database](@ref scenario_db). Each saved variable gets its own table with columns for its [dimensions](@ref dimensions) (labeled with NEMO's standard abbreviations - e.g., `r` for [region](@ref region)), a value column (`val`), and a column indicating the date and time the scenario was solved (`solvedtm`).

## [Nodal vs. non-nodal variables](@id nodal_def)

Many NEMO outputs have "nodal" and "non-nodal" variants. **Nodal** variables show results for regions, [fuels](@ref fuel), [technologies](@ref technology), [storage](@ref storage), and [years](@ref year) involved in transmission modeling - i.e., for cases where capacity, demand, and supply are simulated in a nodal network. To enable transmission modeling, you must define several dimensions and [parameters](@ref parameters): [nodes](@ref node), [transmission lines](@ref transmissionline), [TransmissionModelingEnabled](@ref TransmissionModelingEnabled), [TransmissionCapacityToActivityUnit](@ref TransmissionCapacityToActivityUnit), [NodalDistributionDemand](@ref NodalDistributionDemand), [NodalDistributionStorageCapacity](@ref NodalDistributionStorageCapacity), and [NodalDistributionTechnologyCapacity](@ref NodalDistributionTechnologyCapacity). **Non-nodal** variables show results for cases where transmission modeling is not enabled.

## Activity

### [Annual nodal generation](@id vgenerationannualnodal)

Total annual [nodal](@ref nodal_def) production of a [fuel](@ref fuel) excluding production from [storage](@ref storage). Unit: region's energy [unit](@ref uoms).

#### Julia code

* Variable in JuMP model: `vgenerationannualnodal[n,f,y]`

### [Annual renewable nodal generation](@id vregenerationannualnodal)

Total annual [nodal](@ref nodal_def) production of a [fuel](@ref fuel) from renewable sources, excluding production from [storage](@ref storage). The renewability of production is determined by the [RETagTechnology](@ref RETagTechnology) parameter. Unit: region's energy [unit](@ref uoms).

#### Julia code

* Variable in JuMP model: `vregenerationannualnodal[n,f,y]`

### [Annual nodal production](@id vproductionannualnodal)

Total annual [nodal](@ref nodal_def) production of a [fuel](@ref fuel) from all sources. Unit: region's energy [unit](@ref uoms).

#### Julia code

* Variable in JuMP model: `vproductionannualnodal[n,f,y]`

### [Annual nodal use](@id vuseannualnodal)

Total annual [nodal](@ref nodal_def) use of a [fuel](@ref fuel). Unit: region's energy [unit](@ref uoms).

#### Julia code

* Variable in JuMP model: `vuseannualnodal[n,l,f,y]`

### [Annual non-nodal generation](@id vgenerationannualnn)

Total annual [non-nodal](@ref nodal_def) production of a [fuel](@ref fuel) excluding production from [storage](@ref storage). Unit: region's energy [unit](@ref uoms).

#### Julia code

* Variable in JuMP model: `vgenerationannualnn[r,f,y]`

### [Annual renewable non-nodal generation](@id vregenerationannualnn)

Total annual [non-nodal](@ref nodal_def) production of a [fuel](@ref fuel) from renewable sources, excluding production from [storage](@ref storage). The renewability of production is determined by the [RETagTechnology](@ref RETagTechnology) parameter. Unit: region's energy [unit](@ref uoms).

#### Julia code

* Variable in JuMP model: `vregenerationannualnn[r,f,y]`

### [Annual non-nodal production](@id vproductionannualnn)

Total annual [non-nodal](@ref nodal_def) production of a [fuel](@ref fuel) from all sources. Unit: region's energy [unit](@ref uoms).

#### Julia code

* Variable in JuMP model: `vproductionannualnn[r,f,y]`

### [Annual non-nodal use](@id vuseannualnn)

Total annual [non-nodal](@ref nodal_def) use of a [fuel](@ref fuel). Unit: region's energy [unit](@ref uoms).

#### Julia code

* Variable in JuMP model: `vuseannualnn[r,f,y]`

### [Annual production by technology](@id vproductionbytechnologyannual)

Total annual production of a [fuel](@ref fuel) by a [technology](@ref technology), combining [nodal and non-nodal](@ref nodal_def) production. Unit: region's energy [unit](@ref uoms).

#### Julia code

* Variable in JuMP model: `vproductionbytechnologyannual[r,t,f,y]`

### [Annual trade](@id vtradeannual)

Annual trade of a [fuel](@ref fuel) from [region](@ref region) `r` to region `rr`. Unit: region's energy [unit](@ref uoms).

#### Julia code

* Variable in JuMP model: `vtradeannual[r,rr,f,y]`

### [Annual use by technology](@id vusebytechnologyannual)

Annual use of a [fuel](@ref fuel) by a [technology](@ref technology). Unit: region's energy [unit](@ref uoms).

#### Julia code

* Variable in JuMP model: `vusebytechnologyannual[r,t,f,y]`

### [Nodal production](@id vproductionnodal)

Total [nodal](@ref nodal_def) production of a [fuel](@ref fuel) in a [time slice](@ref timeslice), combining all [technologies](@ref technology). Unit: region's energy [unit](@ref uoms).

#### Julia code

* Variable in JuMP model: `vproductionnodal[n,l,f,y]`

### [Nodal rate of activity](@id vrateofactivitynodal)

Amount of a [technology's](@ref technology) capacity in use in a [time slice](@ref timeslice) and [node](@ref nodal_def). NEMO multiplies the rate of activity by [input activity ratios](@ref InputActivityRatio) and [output activity ratios](@ref OutputActivityRatio) to determine [fuel](@ref fuel) use and production, respectively. Unit: region's energy [unit](@ref uoms) / year.

#### Julia code

* Variable in JuMP model: `vrateofactivitynodal[n,l,t,m,y]`

### [Nodal rate of production by technology](@id vrateofproductionbytechnologynodal)

Rate of time-sliced [nodal](@ref nodal_def) production of a [fuel](@ref fuel) by a [technology](@ref technology). Unit: region's energy [unit](@ref uoms) / year.

#### Julia code

* Variable in JuMP model: `vrateofproductionbytechnologynodal[n,l,t,f,y]`

### [Nodal rate of production](@id vrateofproductionnodal)

Rate of total [nodal](@ref nodal_def) production of a [fuel](@ref fuel) in a [time slice](@ref timeslice), combining all [technologies](@ref technology). Unit: region's energy [unit](@ref uoms) / year.

#### Julia code

* Variable in JuMP model: `vrateofproductionnodal[n,l,f,y]`

### [Nodal rate of total activity](@id vrateoftotalactivitynodal)

[Nodal rate of activity](@ref vrateofactivitynodal) summed across [modes of operation](@ref mode_of_operation). Unit: region's energy [unit](@ref uoms) / year.

#### Julia code

* Variable in JuMP model: `vrateoftotalactivitynodal[n,t,l,y]`

### [Nodal rate of use by technology](@id vrateofusebytechnologynodal)

Rate of time-sliced [nodal](@ref nodal_def) use of a [fuel](@ref fuel) by a [technology](@ref technology). Unit: region's energy [unit](@ref uoms) / year.

#### Julia code

* Variable in JuMP model: `vrateofusebytechnologynodal[n,l,t,f,y]`

### [Nodal rate of use](@id vrateofusenodal)

Rate of total [nodal](@ref nodal_def) use of a [fuel](@ref fuel) in a [time slice](@ref timeslice), combining all [technologies](@ref technology). Unit: region's energy [unit](@ref uoms) / year.

#### Julia code

* Variable in JuMP model: `vrateofusenodal[n,l,f,y]`

### [Nodal use](@id vusenodal)

Total [nodal](@ref nodal_def) use of a [fuel](@ref fuel) in a [time slice](@ref timeslice), combining all [technologies](@ref technology). Unit: region's energy [unit](@ref uoms).

#### Julia code

* Variable in JuMP model: `vusenodal[n,l,f,y]`

### [Non-nodal production](@id vproductionnn)

Total [non-nodal](@ref nodal_def) production of a [fuel](@ref fuel) in a [time slice](@ref timeslice), combining all [technologies](@ref technology). Unit: region's energy [unit](@ref uoms).

#### Julia code

* Variable in JuMP model: `vproductionnn[r,l,f,y]`

### [Non-nodal rate of production by technology by mode](@id vrateofproductionbytechnologybymodenn)

Rate of time-sliced [non-nodal](@ref nodal_def) production of a [fuel](@ref fuel) by a [technology](@ref technology) operating in a [mode](@ref mode_of_operation). Unit: region's energy [unit](@ref uoms) / year.

#### Julia code

* Variable in JuMP model: `vrateofproductionbytechnologybymodenn[r,l,t,m,f,y]`

### [Non-nodal rate of production by technology](@id vrateofproductionbytechnologynn)

Rate of time-sliced [non-nodal](@ref nodal_def) production of a [fuel](@ref fuel) by a [technology](@ref technology). Unit: region's energy [unit](@ref uoms) / year.

#### Julia code

* Variable in JuMP model: `vrateofproductionbytechnologynn[r,l,t,f,y]`

### [Non-nodal rate of production](@id vrateofproductionnn)

Rate of total [non-nodal](@ref nodal_def) production of a [fuel](@ref fuel) in a [time slice](@ref timeslice), combining all [technologies](@ref technology). Unit: region's energy [unit](@ref uoms) / year.

#### Julia code

* Variable in JuMP model: `vrateofproductionnn[r,l,f,y]`

### [Non-nodal rate of use by technology by mode](@id vrateofusebytechnologybymodenn)

Rate of time-sliced [non-nodal](@ref nodal_def) use of a [fuel](@ref fuel) by a [technology](@ref technology) operating in a [mode](@ref mode_of_operation). Unit: region's energy [unit](@ref uoms) / year.

#### Julia code

* Variable in JuMP model: `vrateofusebytechnologybymodenn[r,l,t,m,f,y]`

### [Non-nodal rate of use by technology](@id vrateofusebytechnologynn)

Rate of time-sliced [non-nodal](@ref nodal_def) use of a [fuel](@ref fuel) by a [technology](@ref technology). Unit: region's energy [unit](@ref uoms) / year.

#### Julia code

* Variable in JuMP model: `vrateofusebytechnologynn[r,l,t,f,y]`

### [Non-nodal rate of use](@id vrateofusenn)

Rate of total [non-nodal](@ref nodal_def) use of a [fuel](@ref fuel) in a [time slice](@ref timeslice), combining all [technologies](@ref technology). Unit: region's energy [unit](@ref uoms) / year.

#### Julia code

* Variable in JuMP model: `vrateofusenn[r,l,f,y]`

### [Non-nodal use](@id vusenn)

Total [non-nodal](@ref nodal_def) use of a [fuel](@ref fuel) in a [time slice](@ref timeslice), combining all [technologies](@ref technology). Unit: region's energy [unit](@ref uoms).

#### Julia code

* Variable in JuMP model: `vusenn[r,l,f,y]`

### [Production by technology](@id vproductionbytechnology)

Production of a [fuel](@ref fuel) by a [technology](@ref technology) in a [time slice](@ref timeslice), combining [nodal and non-nodal](@ref nodal_def) production. Unit: region's energy [unit](@ref uoms).

#### Julia code

* Variable in JuMP model: `vproductionbytechnology[r,l,t,f,y]`

### [Rate of activity](@id vrateofactivity)

Amount of a [technology's](@ref technology) capacity in use in a [time slice](@ref timeslice) (considering both [nodal and non-nodal](@ref nodal_def) activity). NEMO multiplies the rate of activity by [input activity ratios](@ref InputActivityRatio) and [output activity ratios](@ref OutputActivityRatio) to determine [fuel](@ref fuel) use and production, respectively. Unit: region's energy [unit](@ref uoms) / year.

#### Julia code

* Variable in JuMP model: `vrateofactivity[r,l,t,m,y]`

### [Rate of production](@id vrateofproduction)

Rate of total production of a [fuel](@ref fuel) in a [time slice](@ref timeslice), combining all [technologies](@ref technology) and [nodal and non-nodal](@ref nodal_def) production. Unit: region's energy [unit](@ref uoms) / year.

#### Julia code

* Variable in JuMP model: `vrateofproduction[r,l,f,y]`

### [Rate of total activity](@id vrateoftotalactivity)

[Rate of activity](@ref vrateofactivity) summed across [modes of operation](@ref mode_of_operation). Unit: region's energy [unit](@ref uoms) / year.

#### Julia code

* Variable in JuMP model: `vrateoftotalactivity[r,t,l,y]`

### [Rate of use](@id vrateofuse)

Rate of total use of a [fuel](@ref fuel) in a [time slice](@ref timeslice), combining all [technologies](@ref technology) and [nodal and non-nodal](@ref nodal_def) production. Unit: region's energy [unit](@ref uoms) / year.

#### Julia code

* Variable in JuMP model: `vrateofuse[r,l,f,y]`

### [Total technology annual activity by mode](@id vtotalannualtechnologyactivitybymode)

Nominal energy produced by a [technology](@ref technology) in a [year](@ref year) when operating in the specified [mode](@ref mode_of_operation). Nominal energy is calculated by multiplying dispatched capacity by the length of time it is dispatched. This variable combines nominal energy due to both [nodal and non-nodal](@ref nodal_def) activity. Unit: region's energy [unit](@ref uoms).

#### Julia code

* Variable in JuMP model: `vtotalannualtechnologyactivitybymode[r,t,m,y]`

### [Total technology annual activity](@id vtotaltechnologyannualactivity)

Nominal energy produced by a [technology](@ref technology) in a [year](@ref year). Nominal energy is calculated by multiplying dispatched capacity by the length of time it is dispatched. This variable combines nominal energy due to both [nodal and non-nodal](@ref nodal_def) activity. Unit: region's energy [unit](@ref uoms).

#### Julia code

* Variable in JuMP model: `vtotaltechnologyannualactivity[r,t,y]`

### [Total technology model period activity](@id vtotaltechnologymodelperiodactivity)

Nominal energy produced by a [technology](@ref technology) during all modeled [years](@ref year). Nominal energy is calculated by multiplying dispatched capacity by the length of time it is dispatched. This variable combines nominal energy due to both [nodal and non-nodal](@ref nodal_def) activity. Unit: region's energy [unit](@ref uoms).

#### Julia code

* Variable in JuMP model: `vtotaltechnologymodelperiodactivity[r,t]`

### [Trade](@id vtrade)

Time-sliced trade of a [fuel](@ref fuel) from [region](@ref region) `r` to region `rr`. Unit: region's energy [unit](@ref uoms).

#### Julia code

* Variable in JuMP model: `vtrade[r,rr,l,f,y]`

### [Use by technology](@id vusebytechnology)

Use of a [fuel](@ref fuel) by a [technology](@ref technology) in a [time slice](@ref timeslice), combining [nodal and non-nodal](@ref nodal_def) use. Unit: region's energy [unit](@ref uoms).

#### Julia code

* Variable in JuMP model: `vusebytechnology[r,l,t,f,y]`

## Costs

### [Capital investment](@id vcapitalinvestment)

Undiscounted investment in new endogenously determined [technology](@ref technology) capacity, including capital and [financing costs](@ref vfinancecost). Unit: scenario's cost [unit](@ref uoms).

#### Julia code

* Variable in JuMP model: `vcapitalinvestment[r,t,y]`

### [Capital investment storage](@id vcapitalinvestmentstorage)

Undiscounted investment in new endogenously determined [storage](@ref storage) capacity, including capital and [financing costs](@ref vfinancecoststorage). Unit: scenario's cost [unit](@ref uoms).

#### Julia code

* Variable in JuMP model: `vcapitalinvestmentstorage[r,s,y]`

### [Capital investment transmission](@id vcapitalinvestmenttransmission)

Undiscounted investment in new endogenously determined [transmission](@ref transmissionline) capacity, including capital and [financing costs](@ref vfinancecosttransmission). Unit: scenario's cost [unit](@ref uoms).

#### Julia code

* Variable in JuMP model: `vcapitalinvestmenttransmission[tr,y]`

### [Discounted capital investment](@id vdiscountedcapitalinvestment)

Discounted investment in new endogenously determined [technology](@ref technology) capacity, including capital and [financing costs](@ref vfinancecost). NEMO discounts the investment to the first [year](@ref year) in the scenario's database using the associated [region's](@ref region) [discount rate](@ref DiscountRate). This variable includes adjustments to account for non-modeled years when the `calcyears` argument of [`calculatescenario`](@ref scenario_calc) or [`writescenariomodel`](@ref) is invoked. See [Calculating selected years](@ref selected_years) for details. Unit: scenario's cost [unit](@ref uoms).

#### Julia code

* Variable in JuMP model: `vdiscountedcapitalinvestment[r,t,y]`

### [Discounted capital investment storage](@id vdiscountedcapitalinvestmentstorage)

Discounted investment in new endogenously determined [storage](@ref storage) capacity, including capital and [financing costs](@ref vfinancecoststorage). NEMO discounts the investment to the first [year](@ref year) in the scenario's database using the associated [region's](@ref region) [discount rate](@ref DiscountRate). This variable includes adjustments to account for non-modeled years when the `calcyears` argument of [`calculatescenario`](@ref scenario_calc) or [`writescenariomodel`](@ref) is invoked. See [Calculating selected years](@ref selected_years) for details. Unit: scenario's cost [unit](@ref uoms).

#### Julia code

* Variable in JuMP model: `vdiscountedcapitalinvestmentstorage[r,s,y]`

### [Discounted capital investment transmission](@id vdiscountedcapitalinvestmenttransmission)

Discounted investment in new endogenously determined [transmission](@ref transmissionline) capacity, including capital and [financing costs](@ref vfinancecosttransmission). NEMO discounts the investment to the first [year](@ref year) in the scenario's database using the [discount rate](@ref DiscountRate) for the [region](@ref region) containing the transmission line's first [node](@ref node). This variable includes adjustments to account for non-modeled years when the `calcyears` argument of [`calculatescenario`](@ref scenario_calc) or [`writescenariomodel`](@ref) is invoked. See [Calculating selected years](@ref selected_years) for details. Unit: scenario's cost [unit](@ref uoms).

#### Julia code

* Variable in JuMP model: `vdiscountedcapitalinvestmenttransmission[tr,y]`

### [Emission penalty by emission](@id vannualtechnologyemissionpenaltybyemission)

Undiscounted cost of [annual technology emissions](@ref vannualtechnologyemission). Unit: scenario's cost [unit](@ref uoms).

#### Julia code

* Variable in JuMP model: `vannualtechnologyemissionpenaltybyemission[r,t,e,y]`

### [Emission penalty](@id vannualtechnologyemissionspenalty)

Undiscounted total emission costs associated with a [technology](@ref technology) (i.e., summing across [emissions](@ref emission)). Unit: scenario's cost [unit](@ref uoms).

#### Julia code

* Variable in JuMP model: `vannualtechnologyemissionspenalty[r,t,y]`

### [Discounted emission penalty](@id vdiscountedtechnologyemissionspenalty)

Discounted total emission costs associated with a [technology](@ref technology) (i.e., summing across [emissions](@ref emission)). NEMO discounts the costs to the first [year](@ref year) in the scenario's database using the associated [region's](@ref region) [discount rate](@ref DiscountRate). This variable includes adjustments to account for non-modeled years when the `calcyears` argument of [`calculatescenario`](@ref scenario_calc) or [`writescenariomodel`](@ref) is invoked. See [Calculating selected years](@ref selected_years) for details. Unit: scenario's cost [unit](@ref uoms).

#### Julia code

* Variable in JuMP model: `vdiscountedtechnologyemissionspenalty[r,t,y]`

### [Financing cost](@id vfinancecost)

Financing cost incurred for new endogenously built [technology](@ref technology) capacity. NEMO calculates this cost by assuming that capital costs for the capacity are financed at the [technology's interest rate](@ref InterestRateTechnology) and repaid in equal installments over the capacity's lifetime. This variable provides the total financing cost over the lifetime, discounted to the capacity's installation year. Unit: scenario's cost [unit](@ref uoms).

#### Julia code

* Variable in JuMP model: `vfinancecost[r,t,y]`

### [Financing cost storage](@id vfinancecoststorage)

Financing cost incurred for new endogenously built [storage](@ref storage) capacity. NEMO calculates this cost by assuming that capital costs for the capacity are financed at the [storage's interest rate](@ref InterestRateStorage) and repaid in equal installments over the capacity's lifetime. This variable provides the total financing cost over the lifetime, discounted to the capacity's installation year. Unit: scenario's cost [unit](@ref uoms).

#### Julia code

* Variable in JuMP model: `vfinancecoststorage[r,s,y]`

### [Financing cost transmission](@id vfinancecosttransmission)

Financing cost incurred for new endogenously built [transmission](@ref transmissionline) capacity. NEMO calculates this cost by assuming that capital costs for the capacity are financed at the transmission line's interest rate and repaid in equal installments over the capacity's lifetime. This variable provides the total financing cost over the lifetime, discounted to the capacity's installation year. Unit: scenario's cost [unit](@ref uoms).

#### Julia code

* Variable in JuMP model: `vfinancecosttransmission[tr,y]`

### [Model period cost by region](@id vmodelperiodcostbyregion)

Sum of all discounted costs in a [region](@ref region) during the modeled [years](@ref year). Includes [technology](@ref technology), [storage](@ref storage), and [transmission](@ref transmissionline) costs. Unit: scenario's cost [unit](@ref uoms).

#### Julia code

* Variable in JuMP model: `vmodelperiodcostbyregion[r]`

### [Operating cost](@id voperatingcost)

Sum of [fixed](@ref vannualfixedoperatingcost) and [variable](@ref vannualvariableoperatingcost) operation and maintenance costs for a [technology](@ref technology). Unit: scenario's cost [unit](@ref uoms).

#### Julia code

* Variable in JuMP model: `voperatingcost[r,t,y]`

### [Operating cost transmission](@id voperatingcosttransmission)

Sum of fixed and variable operation and maintenance costs for a [transmission line](@ref transmissionline). Unit: scenario's cost [unit](@ref uoms).

#### Julia code

* Variable in JuMP model: `voperatingcosttransmission[tr,y]`

### [Discounted operating cost](@id vdiscountedoperatingcost)

Discounted [operation and maintenance costs](@ref voperatingcost) for a [technology](@ref technology). NEMO discounts the costs to the first [year](@ref year) in the scenario's database using the associated [region's](@ref region) [discount rate](@ref DiscountRate). This variable includes adjustments to account for non-modeled years when the `calcyears` argument of [`calculatescenario`](@ref scenario_calc) or [`writescenariomodel`](@ref) is invoked. See [Calculating selected years](@ref selected_years) for details. Unit: scenario's cost [unit](@ref uoms).

#### Julia code

* Variable in JuMP model: `vdiscountedoperatingcost[r,t,y]`

### [Discounted operating cost transmission](@id vdiscountedoperatingcosttransmission)

Discounted [operation and maintenance costs](@ref voperatingcosttransmission) for a [transmission line](@ref transmissionline). NEMO discounts the costs to the first [year](@ref year) in the scenario's database using the [discount rate](@ref DiscountRate) for the [region](@ref region) containing the line's first [node](@ref node). This variable includes adjustments to account for non-modeled years when the `calcyears` argument of [`calculatescenario`](@ref scenario_calc) or [`writescenariomodel`](@ref) is invoked. See [Calculating selected years](@ref selected_years) for details. Unit: scenario's cost [unit](@ref uoms).

#### Julia code

* Variable in JuMP model: `vdiscountedoperatingcosttransmission[tr,y]`

### [Fixed operating cost](@id vannualfixedoperatingcost)

Fixed operation and maintenance costs for a [technology](@ref technology). Unit: scenario's cost [unit](@ref uoms).

#### Julia code

* Variable in JuMP model: `vannualfixedoperatingcost[r,t,y]`

### [Variable operating cost](@id vannualvariableoperatingcost)

Variable operation and maintenance costs for a [technology](@ref technology). Unit: scenario's cost [unit](@ref uoms).

#### Julia code

* Variable in JuMP model: `vannualvariableoperatingcost[r,t,y]`

### [Variable operating cost transmission](@id vvariablecosttransmission)

Variable operation and maintenance costs for a [transmission line](@ref transmissionline). Unit: scenario's cost [unit](@ref uoms).

#### Julia code

* Variable in JuMP model: `vvariablecosttransmission[tr,y]`

### [Variable operating cost transmission by time slice](@id vvariablecosttransmissionbyts)

Variable operation and maintenance costs for a [transmission line](@ref transmissionline) in a [time slice](@ref timeslice). Unit: scenario's cost [unit](@ref uoms).

#### Julia code

* Variable in JuMP model: `vvariablecosttransmissionbyts[tr,l,f,y]`

### [Salvage value](@id vsalvagevalue)

Undiscounted residual value of [capital investment](@ref vcapitalinvestment) remaining at the end of the modeling period. The [DepreciationMethod](@ref DepreciationMethod) parameter determines the approach used to calculate salvage value. Unit: scenario's cost [unit](@ref uoms).

#### Julia code

* Variable in JuMP model: `vsalvagevalue[r,t,y]`

### [Salvage value storage](@id vsalvagevaluestorage)

Undiscounted residual value of [capital investment storage](@ref vcapitalinvestmentstorage) remaining at the end of the modeling period. The [DepreciationMethod](@ref DepreciationMethod) parameter determines the approach used to calculate salvage value. Unit: scenario's cost [unit](@ref uoms).

#### Julia code

* Variable in JuMP model: `vsalvagevaluestorage[r,s,y]`

### [Salvage value transmission](@id vsalvagevaluetransmission)

Undiscounted residual value of [capital investment transmission](@ref vcapitalinvestmenttransmission) remaining at the end of the modeling period. The [DepreciationMethod](@ref DepreciationMethod) parameter determines the approach used to calculate salvage value. Unit: scenario's cost [unit](@ref uoms).

#### Julia code

* Variable in JuMP model: `vsalvagevaluetransmission[tr,y]`

### [Discounted salvage value](@id vdiscountedsalvagevalue)

Discounted residual value of [capital investment](@ref vcapitalinvestment) remaining at the end of the modeling period. NEMO discounts the value to the first [year](@ref year) in the scenario's database using the associated [region's](@ref region) [discount rate](@ref DiscountRate). Unit: scenario's cost [unit](@ref uoms).

#### Julia code

* Variable in JuMP model: `vdiscountedsalvagevalue[r,t,y]`

### [Discounted salvage value storage](@id vdiscountedsalvagevaluestorage)

Discounted residual value of [capital investment storage](@ref vcapitalinvestmentstorage) remaining at the end of the modeling period. NEMO discounts the value to the first [year](@ref year) in the scenario's database using the associated [region's](@ref region) [discount rate](@ref DiscountRate). Unit: scenario's cost [unit](@ref uoms).

#### Julia code

* Variable in JuMP model: `vdiscountedsalvagevaluestorage[r,s,y]`

### [Discounted salvage value transmission](@id vdiscountedsalvagevaluetransmission)

Discounted residual value of [capital investment transmission](@ref vcapitalinvestmenttransmission) remaining at the end of the modeling period. NEMO discounts the value to the first [year](@ref year) in the scenario's database using the [discount rate](@ref DiscountRate) for the [region](@ref region) containing the transmission line's first [node](@ref node). Unit: scenario's cost [unit](@ref uoms).

#### Julia code

* Variable in JuMP model: `vdiscountedsalvagevaluetransmission[tr,y]`

### [Total discounted cost](@id vtotaldiscountedcost)

Sum of all discounted costs in a [region](@ref region) and [year](@ref year) ([technology](@ref technology), [storage](@ref storage), and [transmission](@ref transmissionline)). This variable includes adjustments to account for non-modeled years when the `calcyears` argument of [`calculatescenario`](@ref scenario_calc) or [`writescenariomodel`](@ref) is invoked. See [Calculating selected years](@ref selected_years) for details. Unit: scenario's cost [unit](@ref uoms).

#### Julia code

* Variable in JuMP model: `vtotaldiscountedcost[r,y]`

### [Total discounted storage cost](@id vtotaldiscountedstoragecost)

Sum of discounted [storage](@ref storage) costs: [`vdiscountedcapitalinvestmentstorage`](@ref vdiscountedcapitalinvestmentstorage) - [`vdiscountedsalvagevaluestorage`](@ref vdiscountedsalvagevaluestorage). This variable includes adjustments to account for non-modeled years when the `calcyears` argument of [`calculatescenario`](@ref scenario_calc) or [`writescenariomodel`](@ref) is invoked. See [Calculating selected years](@ref selected_years) for details. Unit: scenario's cost [unit](@ref uoms).

#### Julia code
* Variable in JuMP model: `vtotaldiscountedstoragecost[r,s,y]`

### [Total discounted technology cost](@id vtotaldiscountedcostbytechnology)

Sum of discounted [technology](@ref technology) costs: [`vdiscountedoperatingcost`](@ref vdiscountedoperatingcost) + [`vdiscountedcapitalinvestment`](@ref vdiscountedcapitalinvestment) + [`vdiscountedtechnologyemissionspenalty`](@ref vdiscountedtechnologyemissionspenalty) - [`vdiscountedsalvagevalue`](@ref vdiscountedsalvagevalue). This variable includes adjustments to account for non-modeled years when the `calcyears` argument of [`calculatescenario`](@ref scenario_calc) or [`writescenariomodel`](@ref) is invoked. See [Calculating selected years](@ref selected_years) for details. Unit: scenario's cost [unit](@ref uoms).

#### Julia code

* Variable in JuMP model: `vtotaldiscountedcostbytechnology[r,t,y]`

### [Total discounted transmission cost](@id vtotaldiscountedtransmissioncostbyregion)

Sum of discounted [transmission](@ref transmissionline) costs: [`vdiscountedcapitalinvestmenttransmission`](@ref vdiscountedcapitalinvestmenttransmission) - [`vdiscountedsalvagevaluetransmission`](@ref vdiscountedsalvagevaluetransmission) + [`vdiscountedoperatingcosttransmission`](@ref vdiscountedoperatingcosttransmission). This variable includes adjustments to account for non-modeled years when the `calcyears` argument of [`calculatescenario`](@ref scenario_calc) or [`writescenariomodel`](@ref) is invoked. See [Calculating selected years](@ref selected_years) for details. Unit: scenario's cost [unit](@ref uoms).

#### Julia code

* Variable in JuMP model: `vtotaldiscountedtransmissioncostbyregion[r,y]`

## Demand

### [Nodal annual demand](@id vdemandannualnodal)

[Nodal demand](@ref vdemandnodal) summed across [time slices](@ref timeslice). Unit: region's energy [unit](@ref uoms).

#### Julia code

* Variable in JuMP model: `vdemandannualnodal[n,f,y]`

### [Non-nodal annual demand](@id vdemandannualnn)

[Non-nodal demand](@ref vdemandnn) summed across [time slices](@ref timeslice). Unit: region's energy [unit](@ref uoms).

#### Julia code

* Variable in JuMP model: `vdemandannualnn[r,f,y]`

### [Nodal demand](@id vdemandnodal)

Time-sliced [nodal](@ref nodal_def) demand (time-sliced demand is defined with [`SpecifiedAnnualDemand`](@ref SpecifiedAnnualDemand) and [`SpecifiedDemandProfile`](@ref SpecifiedDemandProfile)). Unit: region's energy [unit](@ref uoms).

#### Julia code

* Variable in JuMP model: `vdemandnodal[n,l,f,y]`

### [Non-nodal demand](@id vdemandnn)

Time-sliced [non-nodal](@ref nodal_def) demand (time-sliced demand is defined with [`SpecifiedAnnualDemand`](@ref SpecifiedAnnualDemand) and [`SpecifiedDemandProfile`](@ref SpecifiedDemandProfile)). Unit: region's energy [unit](@ref uoms).

#### Julia code

* Variable in JuMP model: `vdemandnn[r,l,f,y]`

### [Non-nodal rate of demand](@id vrateofdemandnn)

Rate of time-sliced [non-nodal](@ref nodal_def) demand (time-sliced demand is defined with [`SpecifiedAnnualDemand`](@ref SpecifiedAnnualDemand) and [`SpecifiedDemandProfile`](@ref SpecifiedDemandProfile)). Unit: region's energy [unit](@ref uoms) / year.

#### Julia code

* Variable in JuMP model: `vrateofdemandnn[r,l,f,y]`

## Emissions

### [Annual technology emissions by mode](@id vannualtechnologyemissionbymode)

Annual [emissions](@ref emission) produced by a [technology](@ref technology) operating in the specified [mode](@ref mode_of_operation). Unit: scenario's emissions [unit](@ref uoms).

#### Julia code

* Variable in JuMP model: `vannualtechnologyemissionbymode[r,t,e,m,y]`

### [Annual technology emissions](@id vannualtechnologyemission)

Annual [emissions](@ref emission) produced by a [technology](@ref technology). Unit: scenario's emissions [unit](@ref uoms).

#### Julia code

* Variable in JuMP model: `vannualtechnologyemission[r,t,e,y]`

### [Annual emissions](@id vannualemissions)

Total emissions in a [year](@ref year). Includes any exogenously specified emissions ([`AnnualExogenousEmission`](@ref AnnualExogenousEmission) parameter). Unit: scenario's emissions [unit](@ref uoms).

#### Julia code

* Variable in JuMP model: `vannualemissions[r,e,y]`

### [Model period emissions](@id vmodelperiodemissions)

Total emissions during all modeled [years](@ref year). Includes any exogenously specified emissions ([`AnnualExogenousEmission`](@ref AnnualExogenousEmission) and [`ModelPeriodExogenousEmission`](@ref ModelPeriodExogenousEmission) parameters). Unit: scenario's emissions [unit](@ref uoms).

#### Julia code

* Variable in JuMP model: `vmodelperiodemissions[r,e]`

## Reserve margin

### [Demand needing reserve margin](@id vdemandneedingreservemargin)

Total rate of production of [fuels](@ref fuel) tagged with [`ReserveMarginTagFuel`](@ref ReserveMarginTagFuel). This variable is an element in [reserve margin](@ref ReserveMargin) calculations. Unit: region's energy [unit](@ref uoms) / year.

#### Julia code

* Variable in JuMP model: `vdemandneedingreservemargin[r,l,y]`

### [Total capacity in reserve margin](@id vtotalcapacityinreservemargin)

Total [technology](@ref technology) capacity (combining all technologies) that counts toward meeting the [region's](@ref region) [reserve margin](@ref ReserveMargin). Unit: region's energy [unit](@ref uoms) / year.

#### Julia code

* Variable in JuMP model: `vtotalcapacityinreservemargin[r,y]`

## Storage

### [Accumulated new storage capacity](@id vaccumulatednewstoragecapacity)

Total endogenously determined [storage](@ref storage) capacity existing in a [year](@ref year). Unit: region's energy [unit](@ref uoms).

#### Julia code

* Variable in JuMP model: `vaccumulatednewstoragecapacity[r,s,y]`

### [New storage capacity](@id  vnewstoragecapacity)

New endogenously determined [storage](@ref storage) capacity added in a [year](@ref year). Unit: region's energy [unit](@ref uoms).

#### Julia code

* Variable in JuMP model: ` vnewstoragecapacity[r,s,y]`

### [Nodal rate of storage charge](@id vrateofstoragechargenodal)

Rate of energy stored in [nodal](@ref nodal_def) [storage](@ref storage). Unit: region's energy [unit](@ref uoms) / year.

#### Julia code

* Variable in JuMP model: `vrateofstoragechargenodal[n,s,l,y]`

### [Nodal rate of storage discharge](@id vrateofstoragedischargenodal)

Rate of energy released from [nodal](@ref nodal_def) [storage](@ref storage). Unit: region's energy [unit](@ref uoms) / year.

#### Julia code

* Variable in JuMP model: `vrateofstoragedischargenodal[n,s,l,y]`

### [Nodal storage level time slice end](@id vstorageleveltsendnodal)

Energy in [nodal](@ref nodal_def) [storage](@ref storage) at the end of the first hour in a [time slice](@ref timeslice). Unit: region's energy [unit](@ref uoms).

#### Julia code

* Variable in JuMP model: `vstorageleveltsendnodal[n,s,l,y]`

### [Nodal storage level time slice group 1 start](@id vstorageleveltsgroup1startnodal)

Energy in [nodal](@ref nodal_def) [storage](@ref storage) at the start of a [time slice group 1](@ref tsgroup1). Unit: region's energy [unit](@ref uoms).

#### Julia code

* Variable in JuMP model: `vstorageleveltsgroup1startnodal[n,s,tg1,y]`

### [Nodal storage level time slice group 1 end](@id vstorageleveltsgroup1endnodal)

Energy in [nodal](@ref nodal_def) [storage](@ref storage) at the end of a [time slice group 1](@ref tsgroup1). Unit: region's energy [unit](@ref uoms).

#### Julia code

* Variable in JuMP model: `vstorageleveltsgroup1endnodal[n,s,tg1,y]`

### [Nodal storage level time slice group 2 start](@id vstorageleveltsgroup2startnodal)

Energy in [nodal](@ref nodal_def) [storage](@ref storage) at the start of a [time slice group 2](@ref tsgroup2) within a [time slice group 1](@ref tsgroup1). Unit: region's energy [unit](@ref uoms).

#### Julia code

* Variable in JuMP model: `vstorageleveltsgroup2startnodal[n,s,tg1,tg2,y]`

### [Nodal storage level time slice group 2 end](@id vstorageleveltsgroup2endnodal)

Energy in [nodal](@ref nodal_def) [storage](@ref storage) at the end of a [time slice group 2](@ref tsgroup2) within a [time slice group 1](@ref tsgroup1). Unit: region's energy [unit](@ref uoms).

#### Julia code

* Variable in JuMP model: `vstorageleveltsgroup2endnodal[n,s,tg1,tg2,y]`

### [Nodal storage level year end](@id vstoragelevelyearendnodal)

Energy in [nodal](@ref nodal_def) [storage](@ref storage) at the end of a [year](@ref year). Unit: region's energy [unit](@ref uoms).

#### Julia code

* Variable in JuMP model: `vstoragelevelyearendnodal[n,s,y]`

### [Non-nodal rate of storage charge](@id vrateofstoragechargenn)

Rate of energy stored in [non-nodal](@ref nodal_def) [storage](@ref storage). Unit: region's energy [unit](@ref uoms) / year.

#### Julia code

* Variable in JuMP model: `vrateofstoragechargenn[r,s,l,y]`

### [Non-nodal rate of storage discharge](@id vrateofstoragedischargenn)

Rate of energy released from [non-nodal](@ref nodal_def) [storage](@ref storage). Unit: region's energy [unit](@ref uoms) / year.

#### Julia code

* Variable in JuMP model: `vrateofstoragedischargenn[r,s,l,y]`

### [Non-nodal storage level time slice end](@id vstorageleveltsendnn)

Energy in [non-nodal](@ref nodal_def) [storage](@ref storage) at the end of the first hour in a [time slice](@ref timeslice). Unit: region's energy [unit](@ref uoms).

#### Julia code

* Variable in JuMP model: `vstorageleveltsendnn[r,s,l,y]`

### [Non-nodal storage level time slice group 1 start](@id vstorageleveltsgroup1startnn)

Energy in [non-nodal](@ref nodal_def) [storage](@ref storage) at the start of a [time slice group 1](@ref tsgroup1). Unit: region's energy [unit](@ref uoms).

#### Julia code

* Variable in JuMP model: `vstorageleveltsgroup1startnn[r,s,tg1,y]`

### [Non-nodal storage level time slice group 1 end](@id vstorageleveltsgroup1endnn)

Energy in [non-nodal](@ref nodal_def) [storage](@ref storage) at the end of a [time slice group 1](@ref tsgroup1). Unit: region's energy [unit](@ref uoms).

#### Julia code

* Variable in JuMP model: `vstorageleveltsgroup1endnn[r,s,tg1,y]`

### [Non-nodal storage level time slice group 2 start](@id vstorageleveltsgroup2startnn)

Energy in [non-nodal](@ref nodal_def) [storage](@ref storage) at the start of a [time slice group 2](@ref tsgroup2) within a [time slice group 1](@ref tsgroup1). Unit: region's energy [unit](@ref uoms).

#### Julia code

* Variable in JuMP model: `vstorageleveltsgroup2startnn[r,s,tg1,tg2,y]`

### [Non-nodal storage level time slice group 2 end](@id vstorageleveltsgroup2endnn)

Energy in [non-nodal](@ref nodal_def) [storage](@ref storage) at the end of a [time slice group 2](@ref tsgroup2) within a [time slice group 1](@ref tsgroup1). Unit: region's energy [unit](@ref uoms).

#### Julia code

* Variable in JuMP model: `vstorageleveltsgroup2endnn[r,s,tg1,tg2,y]`

### [Non-nodal storage level year end](@id vstoragelevelyearendnn)

Energy in [non-nodal](@ref nodal_def) [storage](@ref storage) at the end of a [year](@ref year). Unit: region's energy [unit](@ref uoms).

#### Julia code

* Variable in JuMP model: `vstoragelevelyearendnn[r,s,y]`

### [Storage lower limit](@id vstoragelowerlimit)

Minimum energy in [storage](@ref storage) (determined by [MinStorageCharge](@ref MinStorageCharge) and storage capacity). Unit: region's energy [unit](@ref uoms).

#### Julia code

* Variable in JuMP model: `vstoragelowerlimit[r,s,y]`

### [Storage upper limit](@id vstorageupperlimit)

Maximum energy in [storage](@ref storage) (determined by storage capacity). Unit: region's energy [unit](@ref uoms).

#### Julia code

* Variable in JuMP model: `vstorageupperlimit[r,s,y]`

## Technology capacity

### [Accumulated new capacity](@id vaccumulatednewcapacity)

Total endogenously determined [technology](@ref technology) capacity existing in a [year](@ref year). Unit: region's power [unit](@ref uoms).

#### Julia code

* Variable in JuMP model: `vaccumulatednewcapacity[r,t,y]`

### [New capacity](@id vnewcapacity)

New endogenously determined [technology](@ref technology) capacity added in a [year](@ref year). Unit: region's power [unit](@ref uoms).

#### Julia code

* Variable in JuMP model: `vnewcapacity[r,t,y]`

### [Number of new technology units](@id vnumberofnewtechnologyunits)

Number of increments of new endogenously determined capacity added for a [technology](@ref technology) in a [year](@ref year). The size of each increment is set with the [`CapacityOfOneTechnologyUnit`](@ref CapacityOfOneTechnologyUnit) parameter. No unit.

#### Julia code

* Variable in JuMP model: `vnumberofnewtechnologyunits[r,t,y]`

### [Total annual capacity](@id vtotalcapacityannual)

Total [technology](@ref technology) capacity (endogenous and exogenous) existing in a [year](@ref year). Unit: region's power [unit](@ref uoms).

#### Julia code

* Variable in JuMP model: `vtotalcapacityannual[r,t,y]`

## Transmission

### [Annual transmission](@id vtransmissionannual)

Net annual transmission of a [fuel](@ref fuel) from a [node](@ref node). Accounts for efficiency losses in energy received at the node. Unit: energy [unit](@ref uoms) for [region](@ref region) containing node.

#### Julia code

* Variable in JuMP model: `vtransmissionannual[n,f,y]`

### [Transmission built](@id vtransmissionbuilt)

Fraction of a candidate [transmission line](@ref transmissionline) built in a [year](@ref year). No unit (ranges between 0 and 1). This variable will have an integral value if you do not select the `continuoustransmission` option when calculating a scenario (see [`calculatescenario`](@ref)).

#### Julia code

* Variable in JuMP model: `vtransmissionbuilt[tr,y]`

### [Transmission by line](@id vtransmissionbyline)

Flow of a [fuel](@ref fuel) through a [transmission line](@ref transmissionline) (i.e., from the line's first [node](@ref node) [`n1`] to its second node [`n2`]) in a [time slice](@ref timeslice). Unit: megawatts.

#### Julia code

* Variable in JuMP model: `vtransmissionbyline[tr,l,f,y]`

### [Transmission exists](@id vtransmissionexists)

Fraction of a [transmission line](@ref transmissionline) existing in a [year](@ref year). No unit (ranges between 0 and 1).

#### Julia code

* Variable in JuMP model: `vtransmissionexists[tr,y]`

### [Voltage angle](@id vvoltageangle)

Voltage angle at a [node](@ref node) in a [time slice](@ref timeslice). NEMO only calculates this variable if you enable direct current optimized power flow modeling (see [`TransmissionModelingEnabled`](@ref TransmissionModelingEnabled)). Unit: radians.

#### Julia code

* Variable in JuMP model: `vvoltageangle[n,l,y]`
