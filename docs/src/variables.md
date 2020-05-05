```@meta
CurrentModule = NemoMod
```
# [Variables](@id variables)

## [Non-nodal rate of demand](@id vrateofdemandnn)

Description.

#### Julia code

* Variable in JuMP model: `vrateofdemandnn[r,l,f,y]`

## [Non-nodal demand](@id vdemandnn)

Description.

#### Julia code

* Variable in JuMP model: `vdemandnn[r,l,f,y]`

## [Non-nodal annual demand](@id vdemandannualnn)

Description.

#### Julia code

* Variable in JuMP model: `vdemandannualnn[r,f,y]`

## [Non-nodal storage level time slice group 1 start](@id vstorageleveltsgroup1startnn)

Description.

#### Julia code

* Variable in JuMP model: `vstorageleveltsgroup1startnn[r,s,tg1,y]`

## [Non-nodal storage level time slice group 1 end](@id vstorageleveltsgroup1endnn)

Description.

#### Julia code

* Variable in JuMP model: `vstorageleveltsgroup1endnn[r,s,tg1,y]`

## [Non-nodal storage level time slice group 2 start](@id vstorageleveltsgroup2startnn)

Description.

#### Julia code

* Variable in JuMP model: `vstorageleveltsgroup2startnn[r,s,tg1,tg2,y]`

## [Non-nodal storage level time slice group 2 end](@id vstorageleveltsgroup2endnn)

Description.

#### Julia code

* Variable in JuMP model: `vstorageleveltsgroup2endnn[r,s,tg1,tg2,y]`

## [Non-nodal storage level time slice end](@id vstorageleveltsendnn)

Description.

#### Julia code

* Variable in JuMP model: `vstorageleveltsendnn[r,s,l,y]`

## [Non-nodal storage level year end](@id vstoragelevelyearendnn)

Description.

#### Julia code

* Variable in JuMP model: `vstoragelevelyearendnn[r,s,y]`

## [Non-nodal rate of storage charge](@id vrateofstoragechargenn)

Description.

#### Julia code

* Variable in JuMP model: `vrateofstoragechargenn[r,s,l,y]`

## [Non-nodal rate of storage discharge](@id vrateofstoragedischargenn)

Description.

#### Julia code

* Variable in JuMP model: `vrateofstoragedischargenn[r,s,l,y]`

## [Storage lower limit](@id vstoragelowerlimit)

Description.

#### Julia code

* Variable in JuMP model: `vstoragelowerlimit[r,s,y]`

## [Storage upper limit](@id vstorageupperlimit)

Description.

#### Julia code

* Variable in JuMP model: `vstorageupperlimit[r,s,y]`

## [Accumulated new storage capacity](@id vaccumulatednewstoragecapacity)

Description.

#### Julia code

* Variable in JuMP model: `vaccumulatednewstoragecapacity[r,s,y]`

## [New storage capacity](@id  vnewstoragecapacity)

Description.

#### Julia code

* Variable in JuMP model: ` vnewstoragecapacity[r,s,y]`

## [Capital investment storage](@id vcapitalinvestmentstorage)

Description.

#### Julia code

* Variable in JuMP model: `vcapitalinvestmentstorage[r,s,y]`

## [Discounted capital investment storage](@id vdiscountedcapitalinvestmentstorage)

Description.

#### Julia code

* Variable in JuMP model: `vdiscountedcapitalinvestmentstorage[r,s,y]`

## [Salvage value storage](@id vsalvagevaluestorage)

Description.

#### Julia code

* Variable in JuMP model: `vsalvagevaluestorage[r,s,y]`

## [Discounted salvage value storage](@id vdiscountedsalvagevaluestorage)

Description.

#### Julia code

* Variable in JuMP model: `vdiscountedsalvagevaluestorage[r,s,y]`

## [Total discounted storage cost](@id vtotaldiscountedstoragecost)

Description.

#### Julia code
* Variable in JuMP model: `vtotaldiscountedstoragecost[r,s,y]`

## [Number of new technology units](@id vnumberofnewtechnologyunits)

Description.

#### Julia code

* Variable in JuMP model: `vnumberofnewtechnologyunits[r,t,y]`

## [New capacity](@id vnewcapacity)

Description.

#### Julia code

* Variable in JuMP model: `vnewcapacity[r,t,y]`

## [Accumulated new capacity](@id vaccumulatednewcapacity)

Description.

#### Julia code

* Variable in JuMP model: `vaccumulatednewcapacity[r,t,y]`

## [Total annual capacity](@id vtotalcapacityannual)

Description.

#### Julia code

* Variable in JuMP model: `vtotalcapacityannual[r,t,y]`

## [rate of activity](@id vrateofactivity)

Description.

#### Julia code

* Variable in JuMP model: `vrateofactivity[r,l,t,m,y]`

## [Rate of total activity](@id vrateoftotalactivity)

Description.

#### Julia code

* Variable in JuMP model: `vrateoftotalactivity[r,t,l,y]`

## [Total technology annual activity](@id vtotaltechnologyannualactivity)

Description.

#### Julia code

* Variable in JuMP model: `vtotaltechnologyannualactivity[r,t,y]`

## [Total annual technology activity by mode](@id vtotalannualtechnologyactivitybymode)

Description.

#### Julia code

* Variable in JuMP model: `vtotalannualtechnologyactivitybymode[r,t,m,y]`

## [Total technology model period activity](@id vtotaltechnologymodelperiodactivity)

Description.

#### Julia code

* Variable in JuMP model: `vtotaltechnologymodelperiodactivity[r,t]`

## [Non-nodal rate of production by technology by mode](@id vrateofproductionbytechnologybymodenn)

Description.

#### Julia code

* Variable in JuMP model: `vrateofproductionbytechnologybymodenn[r,l,t,m,f,y]`

## [Non-nodal rate of production by technology](@id vrateofproductionbytechnologynn)

Description.

#### Julia code

* Variable in JuMP model: `vrateofproductionbytechnologynn[r,l,t,f,y]`

## [Production by technology, annual](@id vproductionbytechnologyannual)

Description.

#### Julia code

* Variable in JuMP model: `vproductionbytechnologyannual[r,t,f,y]`

## [Rate of production](@id vrateofproduction)

Description.

#### Julia code

* Variable in JuMP model: `vrateofproduction[r,l,f,y]`

## [Non-nodal rate of production](@id vrateofproductionnn)

Description.

#### Julia code

* Variable in JuMP model: `vrateofproductionnn[r,l,f,y]`

## [Non-nodal production](@id vproductionnn)

Description.

#### Julia code

* Variable in JuMP model: `vproductionnn[r,l,f,y]`

## [Non-nodal rate of use by technology by mode](@id vrateofusebytechnologybymodenn)

Description.

#### Julia code

* Variable in JuMP model: `vrateofusebytechnologybymodenn[r,l,t,m,f,y]`

## [Non-nodal rate of use by technology](@id vrateofusebytechnologynn)

Description.

#### Julia code

* Variable in JuMP model: `vrateofusebytechnologynn[r,l,t,f,y]`

## [Use by technology, annual](@id vusebytechnologyannual)

Description.

#### Julia code

* Variable in JuMP model: `vusebytechnologyannual[r,t,f,y]`

## [Rate of use](@id vrateofuse)

Description.

#### Julia code

* Variable in JuMP model: `vrateofuse[r,l,f,y]`

## [Non-nodal rate of use](@id vrateofusenn)

Description.

#### Julia code

* Variable in JuMP model: `vrateofusenn[r,l,f,y]`

## [Non-nodal use](@id vusenn)

Description.

#### Julia code

* Variable in JuMP model: `vusenn[r,l,f,y]`

## [Trade](@id vtrade)

Description.

#### Julia code

* Variable in JuMP model: `vtrade[r,rr,l,f,y]`

## [Annual trade](@id vtradeannual)

Description.

#### Julia code

* Variable in JuMP model: `vtradeannual[r,rr,f,y]`

## [Non-nodal production, annual](@id vproductionannualnn)

Description.

#### Julia code

* Variable in JuMP model: `vproductionannualnn[r,f,y]`

## [Non-nodal use, annual](@id vuseannualnn)

Description.

#### Julia code

* Variable in JuMP model: `vuseannualnn[r,f,y]`

## [Capital investment](@id vcapitalinvestment)

Description.

#### Julia code

* Variable in JuMP model: `vcapitalinvestment[r,t,y]`

## [Discounted capital investment](@id vdiscountedcapitalinvestment)

Description.

#### Julia code

* Variable in JuMP model: `vdiscountedcapitalinvestment[r,t,y]`

## [Salvage value](@id vsalvagevalue)

Description.

#### Julia code

* Variable in JuMP model: `vsalvagevalue[r,t,y]`

## [Discounted salvage value](@id vdiscountedsalvagevalue)

Description.

#### Julia code

* Variable in JuMP model: `vdiscountedsalvagevalue[r,t,y]`

## [Operating cost](@id voperatingcost)

Description.

#### Julia code

* Variable in JuMP model: `voperatingcost[r,t,y]`

## [Discounted operating cost](@id vdiscountedoperatingcost)

Description.

#### Julia code

* Variable in JuMP model: `vdiscountedoperatingcost[r,t,y]`

## [Annual variable operating cost](@id vannualvariableoperatingcost)

Description.

#### Julia code

* Variable in JuMP model: `vannualvariableoperatingcost[r,t,y]`

## [Annual fixed operating cost](@id vannualfixedoperatingcost)

Description.

#### Julia code

* Variable in JuMP model: `vannualfixedoperatingcost[r,t,y]`

## [Total discounted cost by technology](@id vtotaldiscountedcostbytechnology)

Description.

#### Julia code

* Variable in JuMP model: `vtotaldiscountedcostbytechnology[r,t,y]`

## [Total discounted cost](@id vtotaldiscountedcost)

Description.

#### Julia code

* Variable in JuMP model: `vtotaldiscountedcost[r,y]`

## [Model period cost by region](@id vmodelperiodcostbyregion)

Description.

#### Julia code

* Variable in JuMP model: `vmodelperiodcostbyregion[r]`

## [Total capacity in reserve margin](@id vtotalcapacityinreservemargin)

Description.

#### Julia code

* Variable in JuMP model: `vtotalcapacityinreservemargin[r,y]`

## [Demand needing reserve margin](@id vdemandneedingreservemargin)

Description.

#### Julia code

* Variable in JuMP model: `vdemandneedingreservemargin[r,l,y]`

## [Total renewable energy production, annual](@id vtotalreproductionannual)

Description.

#### Julia code

* Variable in JuMP model: `vtotalreproductionannual[r,y]`

## [Renewable energy total production of target fuel, annual](@id vretotalproductionoftargetfuelannual)

Description.

#### Julia code

* Variable in JuMP model: `vretotalproductionoftargetfuelannual[r,y]`

## [Annual technology emission by mode](@id vannualtechnologyemissionbymode)

Description.

#### Julia code

* Variable in JuMP model: `vannualtechnologyemissionbymode[r,t,e,m,y]`

## [Annual technology emission](@id vannualtechnologyemission)

Description.

#### Julia code

* Variable in JuMP model: `vannualtechnologyemission[r,t,e,y]`

## [Annual technology emission penalty by emission](@id vannualtechnologyemissionpenaltybyemission)

Description.

#### Julia code

* Variable in JuMP model: `vannualtechnologyemissionpenaltybyemission[r,t,e,y]`

## [Annual technology emissions penalty](@id vannualtechnologyemissionspenalty)

Description.

#### Julia code

* Variable in JuMP model: `vannualtechnologyemissionspenalty[r,t,y]`

## [Discounted technology emission penalty](@id vdiscountedtechnologyemissionspenalty)

Description.

#### Julia code

* Variable in JuMP model: `vdiscountedtechnologyemissionspenalty[r,t,y]`

## [Annual emissions](@id vannualemissions)

Description.

#### Julia code

* Variable in JuMP model: `vannualemissions[r,e,y]`

## [Model period emissions](@id vmodelperiodemissions)

Description.

#### Julia code

* Variable in JuMP model: `vmodelperiodemissions[r,e]`

## [Nodal rate of activity](@id vrateofactivitynodal)

Description.

#### Julia code

* Variable in JuMP model: `vrateofactivitynodal[n,l,t,m,y]`

## [Nodal rate of production by technology](@id vrateofproductionbytechnologynodal)

Description.

#### Julia code

* Variable in JuMP model: `vrateofproductionbytechnologynodal[n,l,t,f,y]`

## [Nodal rate of use by technology](@id vrateofusebytechnologynodal)

Description.

#### Julia code

* Variable in JuMP model: `vrateofusebytechnologynodal[n,l,t,f,y]`

## [Transmission by line](@id vtransmissionbyline)

Description.

#### Julia code

* Variable in JuMP model: `vtransmissionbyline[tr,l,f,y]`

## [Nodal rate of total activity](@id vrateoftotalactivitynodal)

Description.

#### Julia code

* Variable in JuMP model: `vrateoftotalactivitynodal[n,t,l,y]`

## [Nodal rate of production](@id vrateofproductionnodal)

Description.

#### Julia code

* Variable in JuMP model: `vrateofproductionnodal[n,l,f,y]`

## [Nodal rate of use](@id vrateofusenodal)

Description.

#### Julia code

* Variable in JuMP model: `vrateofusenodal[n,l,f,y]`

## [Nodal production](@id vproductionnodal)

Description.

#### Julia code

* Variable in JuMP model: `vproductionnodal[n,l,f,y]`

## [Nodal production, annual](@id vproductionannualnodal)

Description.

#### Julia code

* Variable in JuMP model: `vproductionannualnodal[n,f,y]`

## [Nodal use](@id vusenodal)

Description.

#### Julia code

* Variable in JuMP model: `vusenodal[n,l,f,y]`

## [Nodal use, annual](@id vuseannualnodal)

Description.

#### Julia code

* Variable in JuMP model: `vuseannualnodal[n,l,f,y]`

## [Nodal demand](@id vdemandnodal)

Description.

#### Julia code

* Variable in JuMP model: `vdemandnodal[n,l,f,y]`

## [Nodal demand, annual](@id vdemandannualnodal)

Description.

#### Julia code

* Variable in JuMP model: `vdemandannualnodal[n,f,y]`

## [Annual transmission](@id vtransmissionannual)

Description.

#### Julia code

* Variable in JuMP model: `vtransmissionannual[n,f,y]`

## [Transmission built](@id vtransmissionbuilt)

Description.

#### Julia code

* Variable in JuMP model: `vtransmissionbuilt[tr,y]`

## [Existing transmission](@id vtransmissionexists)

Description.

#### Julia code

* Variable in JuMP model: `vtransmissionexists[tr,y]`

## [Voltage angle](@id vvoltageangle)

Description.

#### Julia code

* Variable in JuMP model: `vvoltageangle[n,l,y]`

## [Nodal storage level time slice group 1 start](@id vstorageleveltsgroup1startnodal)

Description.

#### Julia code

* Variable in JuMP model: `vstorageleveltsgroup1startnodal[n,s,tg1,y]`

## [Nodal storage level time slice group 1 end](@id vstorageleveltsgroup1endnodal)

Description.

#### Julia code

* Variable in JuMP model: `vstorageleveltsgroup1endnodal[n,s,tg1,y]`

## [Nodal storage level time slice group 2 start](@id vstorageleveltsgroup2startnodal)

Description.

#### Julia code

* Variable in JuMP model: `vstorageleveltsgroup2startnodal[n,s,tg1,tg2,y]`

## [Nodal storage level time slice group 2 end](@id vstorageleveltsgroup2endnodal)

Description.

#### Julia code

* Variable in JuMP model: `vstorageleveltsgroup2endnodal[n,s,tg1,tg2,y]`

## [Nodal storage level time slice end](@id vstorageleveltsendnodal)

Description.

#### Julia code

* Variable in JuMP model: `vstorageleveltsendnodal[n,s,l,y]`

## [Nodal rate of storage charge](@id vrateofstoragechargenodal)

Description.

#### Julia code

* Variable in JuMP model: `vrateofstoragechargenodal[n,s,l,y]`

## [Nodal rate of storage discharge](@id vrateofstoragedischargenodal)

Description.

#### Julia code

* Variable in JuMP model: `vrateofstoragedischargenodal[n,s,l,y]`

## [Nodal storage level year end](@id vstoragelevelyearendnodal)

Description.

#### Julia code

* Variable in JuMP model: `vstoragelevelyearendnodal[n,s,y]`

## [Capital investment transmission](@id vcapitalinvestmenttransmission)

Description.

#### Julia code

* Variable in JuMP model: `vcapitalinvestmenttransmission[tr,y]`

## [Discounted capital investment transmission](@id vdiscountedcapitalinvestmenttransmission)

Description.

#### Julia code

* Variable in JuMP model: `vdiscountedcapitalinvestmenttransmission[tr,y]`

## [Salvage value transmission](@id vsalvagevaluetransmission)

Description.

#### Julia code

* Variable in JuMP model: `vsalvagevaluetransmission[tr,y]`

## [Discounted salvage value transmission](@id vdiscountedsalvagevaluetransmission)

Description.

#### Julia code

* Variable in JuMP model: `vdiscountedsalvagevaluetransmission[tr,y]`

## [Operating cost transmission](@id voperatingcosttransmission)

Description.

#### Julia code

* Variable in JuMP model: `voperatingcosttransmission[tr,y]`

## [Discounted operating cost transmission](@id vdiscountedoperatingcosttransmission)

Description.

#### Julia code

* Variable in JuMP model: `vdiscountedoperatingcosttransmission[tr,y]`

## [Total discounted transmission cost by region](@id vtotaldiscountedtransmissioncostbyregion)

Description.

#### Julia code

* Variable in JuMP model: `vtotaldiscountedtransmissioncostbyregion[r,y]`

## [Production by technology](@id vproductionbytechnology)

Description.

#### Julia code

* Variable in JuMP model: `vproductionbytechnology[r,l,t,f,y]`

## [Use by technology](@id vusebytechnology)

Description.

#### Julia code

* Variable in JuMP model: `vusebytechnology[r,l,t,f,y]`
