#=
    NEMO: Next-generation Energy Modeling system for Optimization.
    https://github.com/sei-international/NemoMod.jl

    Copyright © 2018: Stockholm Environment Institute U.S.

    Release 0.1: Julia version of OSeMOSYS version 2017_11_08.  http://www.osemosys.org/

    File description: Functions for calculating a scenario with NEMO.
=#

"""Runs NEMO for a scenario specified in a SQLite database. Arguments:
    • dbpath - Path to SQLite database.
    • solver - Name of solver to be used (currently, GLPK or CPLEX).
    • varstosave - Comma-delimited list of model variables whose results should be saved in SQLite database.
    • targetprocs - Processes that should be used for parallelized operations within this function."""
function calculatescenario(
    dbpath::String,
    solver::String,
    varstosave::String = "vdemand, vnewstoragecapacity, vaccumulatednewstoragecapacity, vstorageupperlimit, vstoragelowerlimit, vcapitalinvestmentstorage, vdiscountedcapitalinvestmentstorage, vsalvagevaluestorage, vdiscountedsalvagevaluestorage, vnewcapacity, vaccumulatednewcapacity, vtotalcapacityannual, vtotaltechnologyannualactivity, vtotalannualtechnologyactivitybymode, vproductionbytechnologyannual, vproduction, vusebytechnologyannual, vuse, vtrade, vtradeannual, vproductionannual, vuseannual, vcapitalinvestment, vdiscountedcapitalinvestment, vsalvagevalue, vdiscountedsalvagevalue, voperatingcost, vdiscountedoperatingcost, vtotaldiscountedcost",
    targetprocs::Array{Int, 1} = Array{Int, 1}([1]))
# Lines within calculatescenario() are not indented since the function is so lengthy. To make an otherwise local
# variable visible outside the function, prefix it with global. For JuMP constraint references,
# create a new global variable and assign to it the constraint reference.

logmsg("Started scenario calculation.")

# BEGIN: Validate arguments.
if !isfile(dbpath)
    error("dbpath must refer to a file.")
end

if uppercase(solver) == "GLPK"
    solver = "GLPK"
elseif uppercase(solver) == "CPLEX"
    solver = "CPLEX"
else
    error("Requested solver (" * solver * ") is not supported.")
end

logmsg("Validated run-time arguments.")
# END: Validate arguments.

# BEGIN: Connect to SQLite database.
db = SQLite.DB(dbpath)
logmsg("Connected to model database. Path = " * dbpath * ".")
# END: Connect to SQLite database.

# Instantiate JuMP model
if solver == "GLPK"
    model = Model(solver = GLPKSolverMIP(presolve=true))
elseif solver == "CPLEX"
    try
        model = Model(solver = CplexSolver())
    catch ex
        error("Could not instantiate CPLEX - make sure CPLEX package is installed. After installing CPLEX package, run "
            * "Base.compilecache(Base.PkgId(Base.UUID(\"a3c327a0-d2f0-11e8-37fd-d12fd35c3c72\"), \"NemoMod\"))")
    end
# Cbc not yet available for Julia 1.0
#elseif solver == "Cbc"
#    model = Model(solver = CbcSolver(threads = nprocs(), logLevel = 1))
end

# BEGIN: Create parameter views showing default values.
createviewwithdefaults(db, ["OutputActivityRatio", "InputActivityRatio", "ResidualCapacity", "OperationalLife", "FixedCost", "YearSplit", "SpecifiedAnnualDemand", "SpecifiedDemandProfile", "VariableCost", "DiscountRate", "CapitalCost", "CapitalCostStorage", "CapacityFactor", "CapacityToActivityUnit", "CapacityOfOneTechnologyUnit", "AvailabilityFactor", "TradeRoute", "TechnologyToStorage", "Conversionls",
"Conversionld", "Conversionlh", "TechnologyFromStorage", "DaySplit", "StorageLevelStart", "DaysInDayType", "StorageMaxChargeRate", "StorageMaxDischargeRate",
"ResidualStorageCapacity", "MinStorageCharge", "OperationalLifeStorage", "DepreciationMethod", "TotalAnnualMaxCapacity", "TotalAnnualMinCapacity",
"TotalAnnualMaxCapacityInvestment", "TotalAnnualMinCapacityInvestment", "TotalTechnologyAnnualActivityUpperLimit", "TotalTechnologyAnnualActivityLowerLimit",
"TotalTechnologyModelPeriodActivityUpperLimit", "TotalTechnologyModelPeriodActivityLowerLimit", "ReserveMarginTagTechnology", "ReserveMarginTagFuel",
"ReserveMargin", "RETagTechnology", "RETagFuel", "REMinProductionTarget", "EmissionActivityRatio", "EmissionsPenalty", "ModelPeriodExogenousEmission",
"AnnualExogenousEmission", "AnnualEmissionLimit", "ModelPeriodEmissionLimit", "AccumulatedAnnualDemand"])
logmsg("Created parameter views.")
# END: Create parameter views showing default values.

# BEGIN: Define OSeMOSYS sets.
syear::Array{String,1} = collect(skipmissing(SQLite.query(db, "select val from YEAR order by val")[:val]))  # YEAR set
stechnology::Array{String,1} = collect(skipmissing(SQLite.query(db, "select val from TECHNOLOGY")[:val]))  # TECHNOLOGY set
stimeslice::Array{String,1} = collect(skipmissing(SQLite.query(db, "select val from TIMESLICE")[:val]))  # TIMESLICE set
sfuel::Array{String,1} = collect(skipmissing(SQLite.query(db, "select val from FUEL")[:val]))  # FUEL set
semission::Array{String,1} = collect(skipmissing(SQLite.query(db, "select val from EMISSION")[:val]))  # EMISSION set
smode_of_operation::Array{String,1} = collect(skipmissing(SQLite.query(db, "select val from MODE_OF_OPERATION")[:val]))  # MODE_OF_OPERATION set
sregion::Array{String,1} = collect(skipmissing(SQLite.query(db, "select val from REGION")[:val]))  # REGION set
sseason::Array{String,1} = collect(skipmissing(SQLite.query(db, "select val from SEASON order by val")[:val]))  # SEASON set
sdaytype::Array{String,1} = collect(skipmissing(SQLite.query(db, "select val from DAYTYPE order by val")[:val]))  # DAYTYPE set
sdailytimebracket::Array{String,1} = collect(skipmissing(SQLite.query(db, "select val from DAILYTIMEBRACKET")[:val]))  # DAILYTIMEBRACKET set
# FLEXIBLEDEMANDTYPE not used in Utopia example; substitute empty value
sflexibledemandtype::Array{String,1} = Array{String,1}()  # FLEXIBLEDEMANDTYPE set
sstorage::Array{String,1} = collect(skipmissing(SQLite.query(db, "select val from STORAGE")[:val]))  # STORAGE set

logmsg("Defined OSeMOSYS sets.")
# END: Define OSeMOSYS sets.

# BEGIN: Define OSeMOSYS variables.
modelvarindices::Dict{String, Tuple{JuMP.JuMPContainer,Array{String,1}}} = Dict{String, Tuple{JuMP.JuMPContainer,Array{String,1}}}()  # Dictionary mapping model variable names to tuples of (variable, [index column names]); must have an entry here in order to save variable's results back to database

# Demands
@variable(model, vrateofdemand[sregion, stimeslice, sfuel, syear] >= 0)
@variable(model, vdemand[sregion, stimeslice, sfuel, syear] >= 0)

modelvarindices["vrateofdemand"] = (vrateofdemand, ["r","l","f","y"])
modelvarindices["vdemand"] = (vdemand, ["r","l","f","y"])
logmsg("Defined demand variables.")

# Storage
@variable(model, vrateofstoragecharge[sregion, sstorage, sseason, sdaytype, sdailytimebracket, syear])
@variable(model, vrateofstoragedischarge[sregion, sstorage, sseason, sdaytype, sdailytimebracket, syear])
@variable(model, vnetchargewithinyear[sregion, sstorage, sseason, sdaytype, sdailytimebracket, syear])
@variable(model, vnetchargewithinday[sregion, sstorage, sseason, sdaytype, sdailytimebracket, syear])
@variable(model, vstoragelevelyearstart[sregion, sstorage, syear] >= 0)
@variable(model, vstoragelevelyearfinish[sregion, sstorage, syear] >= 0)
@variable(model, vstoragelevelseasonstart[sregion, sstorage, sseason, syear] >= 0)
@variable(model, vstorageleveldaytypestart[sregion, sstorage, sseason, sdaytype, syear] >= 0)
@variable(model, vstorageleveldaytypefinish[sregion, sstorage, sseason, sdaytype, syear] >= 0)
@variable(model, vstoragelowerlimit[sregion, sstorage, syear] >= 0)
@variable(model, vstorageupperlimit[sregion, sstorage, syear] >= 0)
@variable(model, vaccumulatednewstoragecapacity[sregion, sstorage, syear] >= 0)
@variable(model, vnewstoragecapacity[sregion, sstorage, syear] >= 0)
@variable(model, vcapitalinvestmentstorage[sregion, sstorage, syear] >= 0)
@variable(model, vdiscountedcapitalinvestmentstorage[sregion, sstorage, syear] >= 0)
@variable(model, vsalvagevaluestorage[sregion, sstorage, syear] >= 0)
@variable(model, vdiscountedsalvagevaluestorage[sregion, sstorage, syear] >= 0)
@variable(model, vtotaldiscountedstoragecost[sregion, sstorage, syear] >= 0)

modelvarindices["vrateofstoragecharge"] = (vrateofstoragecharge, ["r", "s", "ls", "ld", "lh", "y"])
modelvarindices["vrateofstoragedischarge"] = (vrateofstoragedischarge, ["r", "s", "ls", "ld", "lh", "y"])
modelvarindices["vnetchargewithinyear"] = (vnetchargewithinyear, ["r", "s", "ls", "ld", "lh", "y"])
modelvarindices["vnetchargewithinday"] = (vnetchargewithinday, ["r", "s", "ls", "ld", "lh", "y"])
modelvarindices["vstoragelevelyearstart"] = (vstoragelevelyearstart, ["r", "s", "y"])
modelvarindices["vstoragelevelyearfinish"] = (vstoragelevelyearfinish, ["r", "s", "y"])
modelvarindices["vstoragelevelseasonstart"] = (vstoragelevelseasonstart, ["r", "s", "ls", "y"])
modelvarindices["vstorageleveldaytypestart"] = (vstorageleveldaytypestart, ["r", "s", "ls", "ld", "y"])
modelvarindices["vstorageleveldaytypefinish"] = (vstorageleveldaytypefinish, ["r", "s", "ls", "ld", "y"])
modelvarindices["vstoragelowerlimit"] = (vstoragelowerlimit, ["r", "s", "y"])
modelvarindices["vstorageupperlimit"] = (vstorageupperlimit, ["r", "s", "y"])
modelvarindices["vaccumulatednewstoragecapacity"] = (vaccumulatednewstoragecapacity, ["r", "s", "y"])
modelvarindices["vnewstoragecapacity"] = (vnewstoragecapacity, ["r", "s", "y"])
modelvarindices["vcapitalinvestmentstorage"] = (vcapitalinvestmentstorage, ["r", "s", "y"])
modelvarindices["vdiscountedcapitalinvestmentstorage"] = (vdiscountedcapitalinvestmentstorage, ["r", "s", "y"])
modelvarindices["vsalvagevaluestorage"] = (vsalvagevaluestorage, ["r", "s", "y"])
modelvarindices["vdiscountedsalvagevaluestorage"] = (vdiscountedsalvagevaluestorage, ["r", "s", "y"])
modelvarindices["vtotaldiscountedstoragecost"] = (vtotaldiscountedstoragecost, ["r", "s", "y"])
logmsg("Defined storage variables.")

# Capacity
@variable(model, vnumberofnewtechnologyunits[sregion, stechnology, syear] >= 0, Int)
@variable(model, vnewcapacity[sregion, stechnology, syear] >= 0)
@variable(model, vaccumulatednewcapacity[sregion, stechnology, syear] >= 0)
@variable(model, vtotalcapacityannual[sregion, stechnology, syear] >= 0)

modelvarindices["vnumberofnewtechnologyunits"] = (vnumberofnewtechnologyunits, ["r", "t", "y"])
modelvarindices["vnewcapacity"] = (vnewcapacity, ["r", "t", "y"])
modelvarindices["vaccumulatednewcapacity"] = (vaccumulatednewcapacity, ["r", "t", "y"])
modelvarindices["vtotalcapacityannual"] = (vtotalcapacityannual, ["r", "t", "y"])
logmsg("Defined capacity variables.")

# Activity
@variable(model, vrateofactivity[sregion, stimeslice, stechnology, smode_of_operation, syear] >= 0)
@variable(model, vrateoftotalactivity[sregion, stechnology, stimeslice, syear] >= 0)
@variable(model, vtotaltechnologyannualactivity[sregion, stechnology, syear] >= 0)
@variable(model, vtotalannualtechnologyactivitybymode[sregion, stechnology, smode_of_operation, syear] >= 0)
@variable(model, vtotaltechnologymodelperiodactivity[sregion, stechnology])

queryvrateofproductionbytechnologybymode::DataFrames.DataFrame = SQLite.query(db, "select r.val as r, l.val as l, t.val as t, m.val as m, f.val as f, y.val as y,
cast(oar.val as real) as oar
from region r, timeslice l, technology t, MODE_OF_OPERATION m, fuel f, year y, OutputActivityRatio_def oar
where oar.r = r.val and oar.t = t.val and oar.f = f.val and oar.m = m.val and oar.y = y.val
and oar.val <> 0")

indexdicts = keydicts_parallel(queryvrateofproductionbytechnologybymode, 5, targetprocs)  # Array of Dicts used to restrict indices of following variable

@variable(model, vrateofproductionbytechnologybymode[r=[k[1] for k = keys(indexdicts[1])], l=indexdicts[1][[r]], t=indexdicts[2][[r,l]],
    m=indexdicts[3][[r,l,t]], f=indexdicts[4][[r,l,t,m]], y=indexdicts[5][[r,l,t,m,f]]] >= 0)

# ys included because it's needed for some later constraints based on this query
queryvrateofproductionbytechnology::DataFrames.DataFrame = SQLite.query(db, "select r.val as r, l.val as l, t.val as t, f.val as f, y.val as y, cast(ys.val as real) as ys
from region r, timeslice l, technology t, fuel f, year y, OutputActivityRatio_def oar
left join YearSplit_def ys on ys.l = l.val and ys.y = y.val
where oar.r = r.val and oar.t = t.val and oar.f = f.val and oar.y = y.val
and oar.val <> 0
group by r.val, l.val, t.val, f.val, y.val")

indexdicts = keydicts_parallel(queryvrateofproductionbytechnology, 4, targetprocs)  # Array of Dicts used to restrict indices of following variable

@variable(model, vrateofproductionbytechnology[r=[k[1] for k = keys(indexdicts[1])], l=indexdicts[1][[r]], t=indexdicts[2][[r,l]],
    f=indexdicts[3][[r,l,t]], y=indexdicts[4][[r,l,t,f]]] >= 0)

@variable(model, vproductionbytechnology[r=[k[1] for k = keys(indexdicts[1])], l=indexdicts[1][[r]], t=indexdicts[2][[r,l]],
    f=indexdicts[3][[r,l,t]], y=indexdicts[4][[r,l,t,f]]] >= 0)

# la included because it's needed for some later constraints based on this query
queryproductionbytechnologyannual::DataFrames.DataFrame = SQLite.query(db, "select r.val as r, t.val as t, f.val as f, y.val as y, group_concat(distinct l.val) as la
from REGION r, TECHNOLOGY t, FUEL f, YEAR y, OutputActivityRatio_def oar, TIMESLICE l
where oar.r = r.val and oar.t = t.val and oar.f = f.val and oar.y = y.val
and oar.val <> 0
group by r.val, t.val, f.val, y.val")

indexdicts = keydicts_parallel(queryproductionbytechnologyannual, 3, targetprocs)  # Array of Dicts used to restrict indices of vproductionbytechnologyannual

@variable(model, vproductionbytechnologyannual[r=[k[1] for k = keys(indexdicts[1])], t=indexdicts[1][[r]], f=indexdicts[2][[r,t]],
    y=indexdicts[3][[r,t,f]]] >= 0)

@variable(model, vrateofproduction[sregion, stimeslice, sfuel, syear] >= 0)
@variable(model, vproduction[sregion, stimeslice, sfuel, syear] >= 0)

queryvrateofusebytechnologybymode::DataFrames.DataFrame = SQLite.query(db, "select r.val as r, l.val as l, t.val as t, m.val as m, f.val as f, y.val as y, cast(iar.val as real) as iar
from region r, timeslice l, technology t, MODE_OF_OPERATION m, fuel f, year y, InputActivityRatio_def iar
where iar.r = r.val and iar.t = t.val and iar.f = f.val and iar.m = m.val and iar.y = y.val
and iar.val <> 0")

indexdicts = keydicts_parallel(queryvrateofusebytechnologybymode, 5, targetprocs)  # Array of Dicts used to restrict indices of following variable

@variable(model, vrateofusebytechnologybymode[r=[k[1] for k = keys(indexdicts[1])], l=indexdicts[1][[r]], t=indexdicts[2][[r,l]],
    m=indexdicts[3][[r,l,t]], f=indexdicts[4][[r,l,t,m]], y=indexdicts[5][[r,l,t,m,f]]] >= 0)

# ys included because it's needed for some later constraints based on this query
queryvrateofusebytechnology::DataFrames.DataFrame = SQLite.query(db, "select r.val as r, l.val as l, t.val as t, f.val as f, y.val as y, cast(ys.val as real) as ys
from region r, timeslice l, technology t, fuel f, year y, InputActivityRatio_def iar
left join YearSplit_def ys on ys.l = l.val and ys.y = y.val
where iar.r = r.val and iar.t = t.val and iar.f = f.val and iar.y = y.val
and iar.val <> 0
group by r.val, l.val, t.val, f.val, y.val")

indexdicts = keydicts_parallel(queryvrateofusebytechnology, 4, targetprocs)  # Array of Dicts used to restrict indices of following variable

@variable(model, vrateofusebytechnology[r=[k[1] for k = keys(indexdicts[1])], l=indexdicts[1][[r]], t=indexdicts[2][[r,l]],
    f=indexdicts[3][[r,l,t]], y=indexdicts[4][[r,l,t,f]]] >= 0)

@variable(model, vusebytechnology[r=[k[1] for k = keys(indexdicts[1])], l=indexdicts[1][[r]], t=indexdicts[2][[r,l]],
    f=indexdicts[3][[r,l,t]], y=indexdicts[4][[r,l,t,f]]] >= 0)

indexdicts = keydicts_parallel(SQLite.query(db, "select r.val as r, t.val as t, f.val as f, y.val as y
from REGION r, TECHNOLOGY t, FUEL f, YEAR y, InputActivityRatio_def iar
where iar.r = r.val and iar.t = t.val and iar.f = f.val and iar.y = y.val
and iar.val <> 0
group by r.val, t.val, f.val, y.val"), 3, targetprocs)  # Array of Dicts used to restrict indices of vusebytechnologyannual

@variable(model, vusebytechnologyannual[r=[k[1] for k = keys(indexdicts[1])], t=indexdicts[1][[r]], f=indexdicts[2][[r,t]],
    y=indexdicts[3][[r,t,f]]] >= 0)

@variable(model, vrateofuse[sregion, stimeslice, sfuel, syear] >= 0)
@variable(model, vuse[sregion, stimeslice, sfuel, syear] >= 0)

@variable(model, vtrade[sregion, sregion, stimeslice, sfuel, syear])
@variable(model, vtradeannual[sregion, sregion, sfuel, syear])
@variable(model, vproductionannual[sregion, sfuel, syear] >= 0)
@variable(model, vuseannual[sregion, sfuel, syear] >= 0)

modelvarindices["vrateofactivity"] = (vrateofactivity, ["r", "l", "t", "m", "y"])
modelvarindices["vrateoftotalactivity"] = (vrateoftotalactivity, ["r", "t", "l", "y"])
modelvarindices["vtotaltechnologyannualactivity"] = (vtotaltechnologyannualactivity, ["r", "t", "y"])
modelvarindices["vtotalannualtechnologyactivitybymode"] = (vtotalannualtechnologyactivitybymode, ["r", "t", "m", "y"])
modelvarindices["vtotaltechnologymodelperiodactivity"] = (vtotaltechnologymodelperiodactivity, ["r", "t"])
modelvarindices["vrateofproductionbytechnologybymode"] = (vrateofproductionbytechnologybymode, ["r", "l", "t", "m", "f", "y"])
modelvarindices["vrateofproductionbytechnology"] = (vrateofproductionbytechnology, ["r","l","t","f","y"])
modelvarindices["vproductionbytechnology"] = (vproductionbytechnology, ["r","l","t","f","y"])
modelvarindices["vproductionbytechnologyannual"] = (vproductionbytechnologyannual, ["r","t","f","y"])
modelvarindices["vrateofproduction"] = (vrateofproduction, ["r", "l", "f", "y"])
modelvarindices["vproduction"] = (vproduction, ["r","l","f","y"])
modelvarindices["vrateofusebytechnologybymode"] = (vrateofusebytechnologybymode, ["r", "l", "t", "m", "f", "y"])
modelvarindices["vrateofusebytechnology"] = (vrateofusebytechnology, ["r","l","t","f","y"])
modelvarindices["vusebytechnology"] = (vusebytechnology, ["r","l","t","f","y"])
modelvarindices["vusebytechnologyannual"] = (vusebytechnologyannual, ["r","t","f","y"])
modelvarindices["vrateofuse"] = (vrateofuse, ["r", "l", "f", "y"])
modelvarindices["vuse"] = (vuse, ["r", "l", "f", "y"])
modelvarindices["vtrade"] = (vtrade, ["r", "rr", "l", "f", "y"])
modelvarindices["vtradeannual"] = (vtradeannual, ["r", "rr", "f", "y"])
modelvarindices["vproductionannual"] = (vproductionannual, ["r", "f", "y"])
modelvarindices["vuseannual"] = (vuseannual, ["r", "f", "y"])
logmsg("Defined activity variables.")

# Costing
@variable(model, vcapitalinvestment[sregion, stechnology, syear] >= 0)
@variable(model, vdiscountedcapitalinvestment[sregion, stechnology, syear] >= 0)
@variable(model, vsalvagevalue[sregion, stechnology, syear] >= 0)
@variable(model, vdiscountedsalvagevalue[sregion, stechnology, syear] >= 0)
@variable(model, voperatingcost[sregion, stechnology, syear] >= 0)
@variable(model, vdiscountedoperatingcost[sregion, stechnology, syear] >= 0)
@variable(model, vannualvariableoperatingcost[sregion, stechnology, syear] >= 0)
@variable(model, vannualfixedoperatingcost[sregion, stechnology, syear] >= 0)
@variable(model, vtotaldiscountedcostbytechnology[sregion, stechnology, syear] >= 0)
@variable(model, vtotaldiscountedcost[sregion, syear] >= 0)
@variable(model, vmodelperiodcostbyregion[sregion] >= 0)

modelvarindices["vcapitalinvestment"] = (vcapitalinvestment, ["r", "t", "y"])
modelvarindices["vdiscountedcapitalinvestment"] = (vdiscountedcapitalinvestment, ["r", "t", "y"])
modelvarindices["vsalvagevalue"] = (vsalvagevalue, ["r", "t", "y"])
modelvarindices["vdiscountedsalvagevalue"] = (vdiscountedsalvagevalue, ["r", "t", "y"])
modelvarindices["voperatingcost"] = (voperatingcost, ["r", "t", "y"])
modelvarindices["vdiscountedoperatingcost"] = (vdiscountedoperatingcost, ["r", "t", "y"])
modelvarindices["vannualvariableoperatingcost"] = (vannualvariableoperatingcost, ["r", "t", "y"])
modelvarindices["vannualfixedoperatingcost"] = (vannualfixedoperatingcost, ["r", "t", "y"])
modelvarindices["vtotaldiscountedcostbytechnology"] = (vtotaldiscountedcostbytechnology, ["r", "t", "y"])
modelvarindices["vtotaldiscountedcost"] = (vtotaldiscountedcost, ["r", "y"])
modelvarindices["vmodelperiodcostbyregion"] = (vmodelperiodcostbyregion, ["r"])
logmsg("Defined costing variables.")

# Reserve margin
@variable(model, vtotalcapacityinreservemargin[sregion, syear] >= 0)
@variable(model, vdemandneedingreservemargin[sregion, stimeslice, syear] >= 0)

modelvarindices["vtotalcapacityinreservemargin"] = (vtotalcapacityinreservemargin, ["r", "y"])
modelvarindices["vdemandneedingreservemargin"] = (vdemandneedingreservemargin, ["r", "l", "y"])
logmsg("Defined reserve margin variables.")

# RE target
@variable(model, vtotalreproductionannual[sregion, syear])
@variable(model, vretotalproductionoftargetfuelannual[sregion, syear])

modelvarindices["vtotalreproductionannual"] = (vtotalreproductionannual, ["r", "y"])
modelvarindices["vretotalproductionoftargetfuelannual"] = (vretotalproductionoftargetfuelannual, ["r", "y"])
logmsg("Defined renewable energy target variables.")

# Emissions
@variable(model, vannualtechnologyemissionbymode[sregion, stechnology, semission, smode_of_operation, syear] >= 0)
@variable(model, vannualtechnologyemission[sregion, stechnology, semission, syear] >= 0)
@variable(model, vannualtechnologyemissionpenaltybyemission[sregion, stechnology, semission, syear] >= 0)
@variable(model, vannualtechnologyemissionspenalty[sregion, stechnology, syear] >= 0)
@variable(model, vdiscountedtechnologyemissionspenalty[sregion, stechnology, syear] >= 0)
@variable(model, vannualemissions[sregion, semission, syear] >= 0)
@variable(model, vmodelperiodemissions[sregion, semission] >= 0)

modelvarindices["vannualtechnologyemissionbymode"] = (vannualtechnologyemissionbymode, ["r", "t", "e", "m", "y"])
modelvarindices["vannualtechnologyemission"] = (vannualtechnologyemission, ["r", "t", "e", "y"])
modelvarindices["vannualtechnologyemissionpenaltybyemission"] = (vannualtechnologyemissionpenaltybyemission, ["r", "t", "e", "y"])
modelvarindices["vannualtechnologyemissionspenalty"] = (vannualtechnologyemissionspenalty, ["r", "t", "y"])
modelvarindices["vdiscountedtechnologyemissionspenalty"] = (vdiscountedtechnologyemissionspenalty, ["r", "t", "y"])
modelvarindices["vannualemissions"] = (vannualemissions, ["r", "e", "y"])
modelvarindices["vmodelperiodemissions"] = (vmodelperiodemissions, ["r", "e"])
logmsg("Defined emissions variables.")

logmsg("Finished defining model variables.")
# END: Define OSeMOSYS variables.

# BEGIN: Define OSeMOSYS constraints.

# BEGIN: EQ_SpecifiedDemand.
constraintnum::Int = 1  # Number of next constraint to be added to constraint array
@constraintref ceq_specifieddemand[1:length(sregion) * length(stimeslice) * length(sfuel) * length(syear)]

queryvrateofdemand::DataFrames.DataFrame = SQLite.query(db,"select sdp.r as r, sdp.f as f, sdp.l as l, sdp.y as y,
cast(sdp.val as real) as specifieddemandprofile, cast(sad.val as real) as specifiedannualdemand,
cast(ys.val as real) as ys
from SpecifiedDemandProfile_def sdp, SpecifiedAnnualDemand_def sad, YearSplit_def ys
where sad.r = sdp.r and sad.f = sdp.f and sad.y = sdp.y
and ys.l = sdp.l and ys.y = sdp.y")

for row in eachrow(queryvrateofdemand)
    ceq_specifieddemand[constraintnum] = @constraint(model, row[:specifiedannualdemand] * row[:specifieddemandprofile] / row[:ys]
        == vrateofdemand[row[:r], row[:l], row[:f], row[:y]])
    constraintnum += 1
end

logmsg("Created constraint EQ_SpecifiedDemand.")
# END: EQ_SpecifiedDemand.

# BEGIN: CAa1_TotalNewCapacity.
constraintnum = 1  # Number of next constraint to be added to constraint array
@constraintref caa1_totalnewcapacity[1:length(sregion) * length(stechnology) * length(syear)]

for row in eachrow(SQLite.query(db,"select r.val as r, t.val as t, y.val as y, group_concat(yy.val) as yya
from REGION r, TECHNOLOGY t, YEAR y, OperationalLife_def ol, YEAR yy
where ol.r = r.val and ol.t = t.val
and y.val - yy.val < ol.val and y.val - yy.val >=0
group by r.val, t.val, y.val"))
    local r = row[:r]
    local t = row[:t]
    local y = row[:y]

    caa1_totalnewcapacity[constraintnum] = @constraint(model, sum([vnewcapacity[r,t,yy] for yy = split(row[:yya], ",")])
        == vaccumulatednewcapacity[r,t,y])
    constraintnum += 1
end

logmsg("Created constraint CAa1_TotalNewCapacity.")
# END: CAa1_TotalNewCapacity.

# BEGIN: CAa2_TotalAnnualCapacity.
constraintnum = 1  # Number of next constraint to be added to constraint array
@constraintref caa2_totalannualcapacity[1:length(sregion) * length(stechnology) * length(syear)]

for row in eachrow(SQLite.query(db,"select r.val as r, t.val as t, y.val as y, cast(rc.val as real) as rc
from REGION r, TECHNOLOGY t, YEAR y
left join ResidualCapacity_def rc on rc.r = r.val and rc.t = t.val and rc.y = y.val"))
    local r = row[:r]
    local t = row[:t]
    local y = row[:y]
    local rc = ismissing(row[:rc]) ? 0 : row[:rc]

    caa2_totalannualcapacity[constraintnum] = @constraint(model, vaccumulatednewcapacity[r,t,y] + rc == vtotalcapacityannual[r,t,y])
    constraintnum += 1
end

logmsg("Created constraint CAa2_TotalAnnualCapacity.")
# END: CAa2_TotalAnnualCapacity.

# BEGIN: CAa3_TotalActivityOfEachTechnology.
constraintnum = 1  # Number of next constraint to be added to constraint array
@constraintref caa3_totalactivityofeachtechnology[1:length(sregion) * length(stechnology) * length(stimeslice) * length(syear)]

for (r, t, l, y) in Base.product(sregion, stechnology, stimeslice, syear)
    caa3_totalactivityofeachtechnology[constraintnum] = @constraint(model, sum([vrateofactivity[r,l,t,m,y] for m = smode_of_operation])
        == vrateoftotalactivity[r,t,l,y])
    constraintnum += 1
end

logmsg("Created constraint CAa3_TotalActivityOfEachTechnology.")
# END: CAa3_TotalActivityOfEachTechnology.

# BEGIN: CAa4_Constraint_Capacity.
constraintnum = 1  # Number of next constraint to be added to constraint array
@constraintref caa4_constraint_capacity[1:length(sregion) * length(stimeslice) * length(stechnology) * length(syear)]

for row in eachrow(SQLite.query(db,"select r.val as r, l.val as l, t.val as t, y.val as y,
    cast(cf.val as real) as cf, cast(cta.val as real) as cta
from REGION r, TIMESLICE l, TECHNOLOGY t, YEAR y, CapacityFactor_def cf, CapacityToActivityUnit_def cta
where cf.r = r.val and cf.t = t.val and cf.l = l.val and cf.y = y.val
and cta.r = r.val and cta.t = t.val"))
    local r = row[:r]
    local t = row[:t]
    local l = row[:l]
    local y = row[:y]

    caa4_constraint_capacity[constraintnum] = @constraint(model, vrateoftotalactivity[r,t,l,y]
        <= vtotalcapacityannual[r,t,y] * row[:cf] * row[:cta])
    constraintnum += 1
end

logmsg("Created constraint CAa4_Constraint_Capacity.")
# END: CAa4_Constraint_Capacity.

# BEGIN: CAa5_TotalNewCapacity.
constraintnum = 1  # Number of next constraint to be added to constraint array
@constraintref caa5_totalnewcapacity[1:length(sregion) * length(stechnology) * length(syear)]

for row in eachrow(SQLite.query(db,"select cot.r as r, cot.t as t, cot.y as y, cast(cot.val as real) as cot
from CapacityOfOneTechnologyUnit_def cot where cot.val <> 0"))
    local r = row[:r]
    local t = row[:t]
    local y = row[:y]

    caa5_totalnewcapacity[constraintnum] = @constraint(model, row[:cot] * vnumberofnewtechnologyunits[r,t,y]
        == vnewcapacity[r,t,y])
    constraintnum += 1
end

logmsg("Created constraint CAa5_TotalNewCapacity.")
# END: CAa5_TotalNewCapacity.

# BEGIN: CAb1_PlannedMaintenance.
constraintnum = 1  # Number of next constraint to be added to constraint array
@constraintref cab1_plannedmaintenance[1:length(sregion) * length(stechnology) * length(syear)]

for row in eachrow(SQLite.query(db, "select r.val as r, t.val as t, y.val as y, group_concat(distinct ys.l || ';' || ys.val) as ysa,
group_concat(distinct cf.cf || ';' || cf.ys || ';' || cf.l) as cfa,
cast(af.val as real) as af, cast(cta.val as real) cta
from REGION r, TECHNOLOGY t, YEAR y, YearSplit_def ys,
(select CapacityFactor_def.r, CapacityFactor_def.t, CapacityFactor_def.l, CapacityFactor_def.y,
CapacityFactor_def.val as cf, YearSplit_def.val as ys from CapacityFactor_def, YearSplit_def
where CapacityFactor_def.l = YearSplit_def.l and CapacityFactor_def.y = YearSplit_def.y) cf, AvailabilityFactor_def af,
CapacityToActivityUnit_def cta
where ys.y = y.val
and cf.r = r.val and cf.t = t.val and cf.y = y.val
and af.r = r.val and af.t = t.val and af.y = y.val
and cta.r = r.val and cta.t = t.val
group by r.val, t.val, y.val"))
    local r = row[:r]
    local t = row[:t]
    local y = row[:y]

    cab1_plannedmaintenance[constraintnum] = @constraint(model, sum([vrateoftotalactivity[r,t,split(ys,";")[1],y] * Meta.parse(split(ys,";")[2]) for ys = split(row[:ysa], ",")])
        <= sum([vtotalcapacityannual[r,t,y] * Meta.parse(split(cf,";")[1]) * Meta.parse(split(cf,";")[2]) for cf = split(row[:cfa], ",")])
        * row[:af] * row[:cta])
    constraintnum += 1
end

logmsg("Created constraint CAb1_PlannedMaintenance.")
# END: CAb1_PlannedMaintenance.

# BEGIN: EBa1_RateOfFuelProduction1.
constraintnum = 1  # Number of next constraint to be added to constraint array
@constraintref eba1_rateoffuelproduction1[1:size(queryvrateofproductionbytechnologybymode)[1]]

for row in eachrow(queryvrateofproductionbytechnologybymode)
    local r = row[:r]
    local l = row[:l]
    local t = row[:t]
    local m = row[:m]
    local f = row[:f]
    local y = row[:y]

    eba1_rateoffuelproduction1[constraintnum] = @constraint(model, vrateofactivity[r,l,t,m,y] * row[:oar] == vrateofproductionbytechnologybymode[r,l,t,m,f,y])
    constraintnum += 1
end

logmsg("Created constraint EBa1_RateOfFuelProduction1.")
# END: EBa1_RateOfFuelProduction1.

# BEGIN: EBa2_RateOfFuelProduction2.
constraintnum = 1  # Number of next constraint to be added to constraint array
@constraintref eba2_rateoffuelproduction2[1:size(queryvrateofproductionbytechnology)[1]]

for row in eachrow(queryvrateofproductionbytechnology)
    local r = row[:r]
    local l = row[:l]
    local t = row[:t]
    local f = row[:f]
    local y = row[:y]

    # vrateofproductionbytechnologybymode is JuMP.JuMPDict because it was defined with triangular indexing
    eba2_rateoffuelproduction2[constraintnum] = @constraint(model, sum([(haskey(vrateofproductionbytechnologybymode.tupledict, (r,l,t,m,f,y)) ? vrateofproductionbytechnologybymode[r,l,t,m,f,y] : 0) for m = smode_of_operation]) == vrateofproductionbytechnology[r,l,t,f,y])
    constraintnum += 1
end

logmsg("Created constraint EBa2_RateOfFuelProduction2.")
# END: EBa2_RateOfFuelProduction2.

# BEGIN: EBa3_RateOfFuelProduction3.
constraintnum = 1  # Number of next constraint to be added to constraint array
@constraintref eba3_rateoffuelproduction3[1:length(sregion) * length(stimeslice) * length(sfuel) * length(syear)]

queryvrateofproduction = SQLite.query(db,"select rpt.r as r, rpt.l as l, rpt.f as f, rpt.y as y, cast(ys.val as real) as ys, group_concat(rpt.t) as ta from
(select r.val as r, l.val as l, t.val as t, f.val as f, y.val as y
from region r, timeslice l, technology t, fuel f, year y, OutputActivityRatio_def oar
where oar.r = r.val and oar.t = t.val and oar.f = f.val and oar.y = y.val
and oar.val <> 0
group by r.val, l.val, t.val, f.val, y.val) rpt
left join YearSplit_def ys on ys.l = rpt.l and ys.y = rpt.y
group by rpt.r, rpt.l, rpt.f, rpt.y, ys")

for row in eachrow(queryvrateofproduction)
    local r = row[:r]
    local l = row[:l]
    local f = row[:f]
    local y = row[:y]

    eba3_rateoffuelproduction3[constraintnum] = @constraint(model, sum([vrateofproductionbytechnology[r,l,t,f,y] for t = split(row[:ta], ",")]) == vrateofproduction[r,l,f,y])
    constraintnum += 1
end

logmsg("Created constraint EBa3_RateOfFuelProduction3.")
# END: EBa3_RateOfFuelProduction3.

# BEGIN: EBa4_RateOfFuelUse1.
constraintnum = 1  # Number of next constraint to be added to constraint array
@constraintref eba4_rateoffueluse1[1:size(queryvrateofusebytechnologybymode)[1]]

for row in eachrow(queryvrateofusebytechnologybymode)
    local r = row[:r]
    local l = row[:l]
    local f = row[:f]
    local t = row[:t]
    local m = row[:m]
    local y = row[:y]

    eba4_rateoffueluse1[constraintnum] = @constraint(model, vrateofactivity[r,l,t,m,y] * row[:iar] == vrateofusebytechnologybymode[r,l,t,m,f,y])
    constraintnum += 1
end

logmsg("Created constraint EBa4_RateOfFuelUse1.")
# END: EBa4_RateOfFuelUse1.

# BEGIN: EBa5_RateOfFuelUse2.
constraintnum = 1  # Number of next constraint to be added to constraint array
@constraintref eba5_rateoffueluse2[1:size(queryvrateofusebytechnology)[1]]

for row in eachrow(queryvrateofusebytechnology)
    local r = row[:r]
    local l = row[:l]
    local f = row[:f]
    local t = row[:t]
    local y = row[:y]

    # vrateofusebytechnologybymode is JuMP.JuMPDict because it was defined with triangular indexing
    eba5_rateoffueluse2[constraintnum] = @constraint(model, sum([(haskey(vrateofusebytechnologybymode.tupledict, (r,l,t,m,f,y)) ? vrateofusebytechnologybymode[r,l,t,m,f,y] : 0) for m = smode_of_operation]) == vrateofusebytechnology[r,l,t,f,y])
    constraintnum += 1
end

logmsg("Created constraint EBa5_RateOfFuelUse2.")
# END: EBa5_RateOfFuelUse2.

# BEGIN: EBa6_RateOfFuelUse3.
constraintnum = 1  # Number of next constraint to be added to constraint array

queryvrateofuse::DataFrames.DataFrame = SQLite.query(db, "select rut.r as r, rut.l as l, rut.f as f, rut.y as y, cast(ys.val as real) as ys, group_concat(rut.t) as ta from
(select r.val as r, l.val as l, t.val as t, f.val as f, y.val as y
from region r, timeslice l, technology t, fuel f, year y, InputActivityRatio_def iar
where iar.r = r.val and iar.t = t.val and iar.f = f.val and iar.y = y.val
and iar.val <> 0
group by r.val, l.val, t.val, f.val, y.val) rut
left join YearSplit_def ys on ys.l = rut.l and ys.y = rut.y
group by rut.r, rut.l, rut.f, rut.y, ys")

@constraintref eba6_rateoffueluse3[1:size(queryvrateofuse)[1]]

for row in eachrow(queryvrateofuse)
    local r = row[:r]
    local l = row[:l]
    local f = row[:f]
    local y = row[:y]

    eba6_rateoffueluse3[constraintnum] = @constraint(model, sum([vrateofusebytechnology[r,l,t,f,y] for t = split(row[:ta], ",")]) == vrateofuse[r,l,f,y])
    constraintnum += 1
end

logmsg("Created constraint EBa6_RateOfFuelUse3.")
# END: EBa6_RateOfFuelUse3.

# BEGIN: EBa7_EnergyBalanceEachTS1.
constraintnum = 1  # Number of next constraint to be added to constraint array
@constraintref eba7_energybalanceeachts1[1:size(queryvrateofproduction)[1]]

for row in eachrow(queryvrateofproduction)
    local r = row[:r]
    local l = row[:l]
    local f = row[:f]
    local y = row[:y]

    if !ismissing(row[:ys])
        eba7_energybalanceeachts1[constraintnum] = @constraint(model, vrateofproduction[r,l,f,y] * row[:ys] == vproduction[r,l,f,y])
        constraintnum += 1
    end
end

logmsg("Created constraint EBa7_EnergyBalanceEachTS1.")
# END: EBa7_EnergyBalanceEachTS1.

# BEGIN: EBa8_EnergyBalanceEachTS2.
constraintnum = 1  # Number of next constraint to be added to constraint array
@constraintref eba8_energybalanceeachts2[1:size(queryvrateofuse)[1]]

for row in eachrow(queryvrateofuse)
    local r = row[:r]
    local l = row[:l]
    local f = row[:f]
    local y = row[:y]

    if !ismissing(row[:ys])
        eba8_energybalanceeachts2[constraintnum] = @constraint(model, vrateofuse[r,l,f,y] * row[:ys] == vuse[r,l,f,y])
        constraintnum += 1
    end
end

logmsg("Created constraint EBa8_EnergyBalanceEachTS2.")
# END: EBa8_EnergyBalanceEachTS2.

# BEGIN: EBa9_EnergyBalanceEachTS3.
constraintnum = 1  # Number of next constraint to be added to constraint array
@constraintref eba9_energybalanceeachts3[1:size(queryvrateofdemand)[1]]

for row in eachrow(queryvrateofdemand)
    local r = row[:r]
    local l = row[:l]
    local f = row[:f]
    local y = row[:y]

    eba9_energybalanceeachts3[constraintnum] = @constraint(model, vrateofdemand[r,l,f,y] * row[:ys] == vdemand[r,l,f,y])
    constraintnum += 1
end

logmsg("Created constraint EBa9_EnergyBalanceEachTS3.")
# END: EBa9_EnergyBalanceEachTS3.

# BEGIN: EBa10_EnergyBalanceEachTS4.
constraintnum = 1  # Number of next constraint to be added to constraint array
@constraintref eba10_energybalanceeachts4[1:length(sregion)^2 * length(stimeslice) * length(sfuel) * length(syear)]

for (r, rr, l, f, y) in Base.product(sregion, sregion, stimeslice, sfuel, syear)
    eba10_energybalanceeachts4[constraintnum] = @constraint(model, vtrade[r,rr,l,f,y] == -vtrade[rr,r,l,f,y])
    constraintnum += 1
end

logmsg("Created constraint EBa10_EnergyBalanceEachTS4.")
# END: EBa10_EnergyBalanceEachTS4.

# BEGIN: EBa11_EnergyBalanceEachTS5.
constraintnum = 1  # Number of next constraint to be added to constraint array
@constraintref eba11_energybalanceeachts5[1:length(sregion) * length(stimeslice) * length(sfuel) * length(syear)]

for row in eachrow(SQLite.query(db, "select r.val as r, l.val as l, f.val as f, y.val as y, group_concat(tr.rr || ';' || tr.val) as tra
from region r, timeslice l, fuel f, year y
left join traderoute_def tr on tr.r = r.val and tr.f = f.val and tr.y = y.val
group by r.val, l.val, f.val, y.val"))
    local r = row[:r]
    local l = row[:l]
    local f = row[:f]
    local y = row[:y]

    eba11_energybalanceeachts5[constraintnum] = @constraint(model, vproduction[r,l,f,y] >= vdemand[r,l,f,y] + vuse[r,l,f,y] +
        (ismissing(row[:tra]) ? 0 : sum([vtrade[r,split(tr,";")[1],l,f,y] * Meta.parse(split(tr,";")[2]) for tr = split(row[:tra], ",")])))
    constraintnum += 1
end

logmsg("Created constraint EBa11_EnergyBalanceEachTS5.")
# END: EBa11_EnergyBalanceEachTS5.

# BEGIN: EBb1_EnergyBalanceEachYear1.
constraintnum = 1  # Number of next constraint to be added to constraint array
@constraintref ebb1_energybalanceeachyear1[1:length(sregion) * length(sfuel) * length(syear)]

for (r, f, y) in Base.product(sregion, sfuel, syear)
    ebb1_energybalanceeachyear1[constraintnum] = @constraint(model, sum([vproduction[r,l,f,y] for l = stimeslice]) == vproductionannual[r,f,y])
    constraintnum += 1
end

logmsg("Created constraint EBb1_EnergyBalanceEachYear1.")
# END: EBb1_EnergyBalanceEachYear1.

# BEGIN: EBb2_EnergyBalanceEachYear2.
constraintnum = 1  # Number of next constraint to be added to constraint array
@constraintref ebb2_energybalanceeachyear2[1:length(sregion) * length(sfuel) * length(syear)]

for (r, f, y) in Base.product(sregion, sfuel, syear)
    ebb2_energybalanceeachyear2[constraintnum] = @constraint(model, sum([vuse[r,l,f,y] for l = stimeslice]) == vuseannual[r,f,y])
    constraintnum += 1
end

logmsg("Created constraint EBb2_EnergyBalanceEachYear2.")
# END: EBb2_EnergyBalanceEachYear2.

# BEGIN: EBb3_EnergyBalanceEachYear3.
constraintnum = 1  # Number of next constraint to be added to constraint array
@constraintref ebb3_energybalanceeachyear3[1:length(sregion) * length(sfuel) * length(syear)]

for (r, rr, f, y) in Base.product(sregion, sregion, sfuel, syear)
    ebb3_energybalanceeachyear3[constraintnum] = @constraint(model, sum([vtrade[r,rr,l,f,y] for l = stimeslice]) == vtradeannual[r,rr,f,y])
    constraintnum += 1
end

logmsg("Created constraint EBb3_EnergyBalanceEachYear3.")
# END: EBb3_EnergyBalanceEachYear3.

# BEGIN: EBb4_EnergyBalanceEachYear4.
constraintnum = 1  # Number of next constraint to be added to constraint array
@constraintref ebb4_energybalanceeachyear4[1:length(sregion) * length(sfuel) * length(syear)]

for row in eachrow(SQLite.query(db, "select r.val as r, f.val as f, y.val as y, cast(aad.val as real) as aad,
group_concat(tr.rr || ';' || tr.val) as tra
from region r, fuel f, year y
left join traderoute_def tr on tr.r = r.val and tr.f = f.val and tr.y = y.val
left join AccumulatedAnnualDemand_def aad on aad.r = r.val and aad.f = f.val and aad.y = y.val
group by r.val, f.val, y.val, aad"))
    local r = row[:r]
    local f = row[:f]
    local y = row[:y]

    ebb4_energybalanceeachyear4[constraintnum] = @constraint(model, vproductionannual[r,f,y] >= vuseannual[r,f,y] +
        (ismissing(row[:tra]) ? 0 : sum([vtradeannual[r,split(tr,";")[1],f,y] * Meta.parse(split(tr,";")[2]) for tr = split(row[:tra], ",")])) +
        (ismissing(row[:aad]) ? 0 : row[:aad]))
    constraintnum += 1
end

logmsg("Created constraint EBb4_EnergyBalanceEachYear4.")
# END: EBb4_EnergyBalanceEachYear4.

# BEGIN: Acc1_FuelProductionByTechnology.
constraintnum = 1  # Number of next constraint to be added to constraint array
@constraintref acc1_fuelproductionbytechnology[1:size(queryvrateofproductionbytechnology)[1]]

for row in eachrow(queryvrateofproductionbytechnology)
    local r = row[:r]
    local l = row[:l]
    local t = row[:t]
    local f = row[:f]
    local y = row[:y]

    if !ismissing(row[:ys])
        acc1_fuelproductionbytechnology[constraintnum] = @constraint(model, vrateofproductionbytechnology[r,l,t,f,y] * row[:ys] == vproductionbytechnology[r,l,t,f,y])
        constraintnum += 1
    end
end

logmsg("Created constraint Acc1_FuelProductionByTechnology.")
# END: Acc1_FuelProductionByTechnology.

# BEGIN: Acc2_FuelUseByTechnology.
constraintnum = 1  # Number of next constraint to be added to constraint array
@constraintref acc2_fuelusebytechnology[1:size(queryvrateofusebytechnology)[1]]

for row in eachrow(queryvrateofusebytechnology)
    local r = row[:r]
    local l = row[:l]
    local t = row[:t]
    local f = row[:f]
    local y = row[:y]

    if !ismissing(row[:ys])
        acc2_fuelusebytechnology[constraintnum] = @constraint(model, vrateofusebytechnology[r,l,t,f,y] * row[:ys] == vusebytechnology[r,l,t,f,y])
        constraintnum += 1
    end
end

logmsg("Created constraint Acc2_FuelUseByTechnology.")
# END: Acc2_FuelUseByTechnology.

# BEGIN: Acc3_AverageAnnualRateOfActivity.
constraintnum = 1  # Number of next constraint to be added to constraint array
@constraintref acc3_averageannualrateofactivity[1:length(sregion) * length(stechnology) * length(smode_of_operation) * length(syear)]

for row in eachrow(SQLite.query(db, "select r.val as r, t.val as t, m.val as m, y.val as y, group_concat(l.val || ';' || ys.val) as la
from region r, technology t, mode_of_operation m, year y, timeslice l, YearSplit_def ys
where ys.l = l.val and ys.y = y.val
group by r.val, t.val, m.val, y.val"))
    local r = row[:r]
    local t = row[:t]
    local m = row[:m]
    local y = row[:y]

    acc3_averageannualrateofactivity[constraintnum] = @constraint(model, sum([vrateofactivity[r,split(l,";")[1],t,m,y] * Meta.parse(split(l,";")[2]) for l = split(row[:la], ",")]) == vtotalannualtechnologyactivitybymode[r,t,m,y])
    constraintnum += 1
end

logmsg("Created constraint Acc3_AverageAnnualRateOfActivity.")
# END: Acc3_AverageAnnualRateOfActivity.

# BEGIN: Acc4_ModelPeriodCostByRegion.
constraintnum = 1  # Number of next constraint to be added to constraint array
@constraintref acc4_modelperiodcostbyregion[1:length(sregion)]

for r in sregion
    acc4_modelperiodcostbyregion[constraintnum] = @constraint(model, sum([vtotaldiscountedcost[r,y] for y in syear]) == vmodelperiodcostbyregion[r])
    constraintnum += 1
end

logmsg("Created constraint Acc4_ModelPeriodCostByRegion.")
# END: Acc4_ModelPeriodCostByRegion.

# BEGIN: S1_RateOfStorageCharge.
constraintnum = 1  # Number of next constraint to be added to constraint array
@constraintref s1_rateofstoragecharge[1:length(sregion) * length(sstorage) * length(sseason) * length(sdaytype) * length(sdailytimebracket) * length(syear)]

for row in eachrow(SQLite.query(db, "select r.val as r, s.val as s, ls.val as ls, ld.val as ld, lh.val as lh, y.val as y,
group_concat(t.val || ';' || m.val || ';' || l.val || ';' || (tts.val * cls.val * cld.val * clh.val)) as ia
from region r, storage s, season ls, daytype ld, dailytimebracket lh, year y, technology t,
mode_of_operation m, timeslice l, TechnologyToStorage_def tts, Conversionls_def cls, Conversionld_def cld,
Conversionlh_def clh
where tts.r = r.val and tts.t = t.val and tts.s = s.val and tts.m = m.val and tts.val > 0
and cls.l = l.val and cls.ls = ls.val
and cld.l = l.val and cld.ld = ld.val
and clh.l = l.val and clh.lh = lh.val
group by r.val, s.val, ls.val, ld.val, lh.val, y.val"))
    local r = row[:r]
    local s = row[:s]
    local ls = row[:ls]
    local ld = row[:ld]
    local lh = row[:lh]
    local y = row[:y]

    s1_rateofstoragecharge[constraintnum] = @constraint(model, sum([vrateofactivity[r,split(i,";")[3],split(i,";")[1],split(i,";")[2],y] * Meta.parse(split(i,";")[4]) for i = split(row[:ia], ",")]) == vrateofstoragecharge[r,s,ls,ld,lh,y])
    constraintnum += 1
end

logmsg("Created constraint S1_RateOfStorageCharge.")
# END: S1_RateOfStorageCharge.

# BEGIN: S2_RateOfStorageDischarge.
constraintnum = 1  # Number of next constraint to be added to constraint array
@constraintref s2_rateofstoragedischarge[1:length(sregion) * length(sstorage) * length(sseason) * length(sdaytype) * length(sdailytimebracket) * length(syear)]

for row in eachrow(SQLite.query(db, "select r.val as r, s.val as s, ls.val as ls, ld.val as ld, lh.val as lh, y.val as y,
group_concat(t.val || ';' || m.val || ';' || l.val || ';' || (tfs.val * cls.val * cld.val * clh.val)) as ia
from region r, storage s, season ls, daytype ld, dailytimebracket lh, year y, technology t,
mode_of_operation m, timeslice l, TechnologyFromStorage_def tfs, Conversionls_def cls, Conversionld_def cld,
Conversionlh_def clh
where tfs.r = r.val and tfs.t = t.val and tfs.s = s.val and tfs.m = m.val and tfs.val > 0
and cls.l = l.val and cls.ls = ls.val
and cld.l = l.val and cld.ld = ld.val
and clh.l = l.val and clh.lh = lh.val
group by r.val, s.val, ls.val, ld.val, lh.val, y.val"))
    local r = row[:r]
    local s = row[:s]
    local ls = row[:ls]
    local ld = row[:ld]
    local lh = row[:lh]
    local y = row[:y]

    s2_rateofstoragedischarge[constraintnum] = @constraint(model, sum([vrateofactivity[r,split(i,";")[3],split(i,";")[1],split(i,";")[2],y] * Meta.parse(split(i,";")[4]) for i = split(row[:ia], ",")]) == vrateofstoragedischarge[r,s,ls,ld,lh,y])
    constraintnum += 1
end

logmsg("Created constraint S2_RateOfStorageDischarge.")
# END: S2_RateOfStorageDischarge.

# BEGIN: S3_NetChargeWithinYear.
constraintnum = 1  # Number of next constraint to be added to constraint array
@constraintref s3_netchargewithinyear[1:length(sregion) * length(sstorage) * length(sseason) * length(sdaytype) * length(sdailytimebracket) * length(syear)]

for row in eachrow(SQLite.query(db, "select r.val as r, s.val as s, ls.val as ls, ld.val as ld, lh.val as lh, y.val as y,
group_concat(ys.val * cls.val * cld.val * clh.val) as ia
from region r, storage s, season ls, daytype ld, dailytimebracket lh, year y, timeslice l,
YearSplit_def ys, Conversionls_def cls, Conversionld_def cld, Conversionlh_def clh
where ys.l = l.val and ys.y = y.val
and cls.l = l.val and cls.ls = ls.val and cls.val > 0
and cld.l = l.val and cld.ld = ld.val and cld.val > 0
and clh.l = l.val and clh.lh = lh.val and clh.val > 0
group by r.val, s.val, ls.val, ld.val, lh.val, y.val"))
    local r = row[:r]
    local s = row[:s]
    local ls = row[:ls]
    local ld = row[:ld]
    local lh = row[:lh]
    local y = row[:y]

    s3_netchargewithinyear[constraintnum] = @constraint(model, (vrateofstoragecharge[r,s,ls,ld,lh,y] - vrateofstoragedischarge[r,s,ls,ld,lh,y]) * sum([Meta.parse(i) for i = split(row[:ia], ",")]) == vnetchargewithinyear[r,s,ls,ld,lh,y])
    constraintnum += 1
end

logmsg("Created constraint S3_NetChargeWithinYear.")
# END: S3_NetChargeWithinYear.

# BEGIN: S4_NetChargeWithinDay.
constraintnum = 1  # Number of next constraint to be added to constraint array
@constraintref s4_netchargewithinday[1:length(sregion) * length(sstorage) * length(sseason) * length(sdaytype) * length(sdailytimebracket) * length(syear)]

for row in eachrow(SQLite.query(db, "select r.val as r, s.val as s, ls.val as ls, ld.val as ld, lh.val as lh, y.val as y, cast(ds.val as real) as ds
from region r, storage s, season ls, daytype ld, dailytimebracket lh, year y, daysplit_def ds
where ds.lh = lh.val and ds.y = y.val"))
    local r = row[:r]
    local s = row[:s]
    local ls = row[:ls]
    local ld = row[:ld]
    local lh = row[:lh]
    local y = row[:y]

    s4_netchargewithinday[constraintnum] = @constraint(model, (vrateofstoragecharge[r,s,ls,ld,lh,y] - vrateofstoragedischarge[r,s,ls,ld,lh,y]) * row[:ds] == vnetchargewithinday[r,s,ls,ld,lh,y])
    constraintnum += 1
end

logmsg("Created constraint S4_NetChargeWithinDay.")
# END: S4_NetChargeWithinDay.

# BEGIN: S5_and_S6_StorageLevelYearStart.
constraintnum = 1  # Number of next constraint to be added to constraint array
@constraintref s5_and_s6_storagelevelyearstart[1:length(sregion) * length(sstorage) * length(syear)]

for row in eachrow(SQLite.query(db, "select r.val as r, s.val as s, y.val as y, cast(sls.val as real) as sls
from region r, storage s, year y, StorageLevelStart_def sls
where sls.r = r.val and sls.s = s.val"))
    local r = row[:r]
    local s = row[:s]
    local y = row[:y]

    s5_and_s6_storagelevelyearstart[constraintnum] = @constraint(model, (y == first(syear) ? row[:sls] : vstoragelevelyearstart[r,s,string(Meta.parse(y)-1)] + sum([vnetchargewithinyear[r,s,ls,ld,lh,string(Meta.parse(y)-1)] for ls = sseason, ld = sdaytype, lh = sdailytimebracket])) == vstoragelevelyearstart[r,s,y])
    constraintnum += 1
end

logmsg("Created constraint S5_and_S6_StorageLevelYearStart.")
# END: S5_and_S6_StorageLevelYearStart.

# BEGIN: S7_and_S8_StorageLevelYearFinish.
constraintnum = 1  # Number of next constraint to be added to constraint array
@constraintref s7_and_s8_storagelevelyearfinish[1:length(sregion) * length(sstorage) * length(syear)]

for (r, s, y) in Base.product(sregion, sstorage, syear)
    s7_and_s8_storagelevelyearfinish[constraintnum] = @constraint(model, (y < last(syear) ? vstoragelevelyearstart[r,s,string(Meta.parse(y)+1)] : vstoragelevelyearstart[r,s,y] + sum([vnetchargewithinyear[r,s,ls,ld,lh,y] for ls = sseason, ld = sdaytype, lh = sdailytimebracket])) == vstoragelevelyearfinish[r,s,y])
    constraintnum += 1
end

logmsg("Created constraint S7_and_S8_StorageLevelYearFinish.")
# END: S7_and_S8_StorageLevelYearFinish.

# BEGIN: S9_and_S10_StorageLevelSeasonStart.
constraintnum = 1  # Number of next constraint to be added to constraint array
@constraintref s9_and_s10_storagelevelseasonstart[1:length(sregion) * length(sstorage) * length(sseason) * length(syear)]

for (r, s, ls, y) in Base.product(sregion, sstorage, sseason, syear)
    s9_and_s10_storagelevelseasonstart[constraintnum] = @constraint(model, (ls == first(sseason) ? vstoragelevelyearstart[r,s,y] : vstoragelevelseasonstart[r,s,string(Meta.parse(ls)-1),y] + sum([vnetchargewithinyear[r,s,string(Meta.parse(ls)-1),ld,lh,y] for ld = sdaytype, lh = sdailytimebracket])) == vstoragelevelseasonstart[r,s,ls,y])
    constraintnum += 1
end

logmsg("Created constraint S9_and_S10_StorageLevelSeasonStart.")
# END: S9_and_S10_StorageLevelSeasonStart.

# BEGIN: S11_and_S12_StorageLevelDayTypeStart.
constraintnum = 1  # Number of next constraint to be added to constraint array
@constraintref s11_and_s12_storageleveldaytypestart[1:length(sregion) * length(sstorage) * length(sseason) * length(sdaytype) * length(syear)]

for row in eachrow(SQLite.query(db, "select r.val as r, s.val as s, ls.val as ls, ld.val as ld, y.val as y, cast(did.val as real) as did
from region r, storage s, season ls, daytype ld, year y
left join DaysInDayType_def did on did.ls = ls.val and did.ld = ld.val - 1 and did.y = y.val"))
    local r = row[:r]
    local s = row[:s]
    local ls = row[:ls]
    local ld = row[:ld]
    local y = row[:y]

    s11_and_s12_storageleveldaytypestart[constraintnum] = @constraint(model, (ld == first(sdaytype) ? vstoragelevelseasonstart[r,s,ls,y] : vstorageleveldaytypestart[r,s,ls,string(Meta.parse(ld)-1),y] + sum([vnetchargewithinday[r,s,ls,string(Meta.parse(ld)-1),lh,y] * row[:did] for lh = sdailytimebracket])) == vstorageleveldaytypestart[r,s,ls,ld,y])
    constraintnum += 1
end

logmsg("Created constraint S11_and_S12_StorageLevelDayTypeStart.")
# END: S11_and_S12_StorageLevelDayTypeStart.

# BEGIN: S13_and_S14_and_S15_StorageLevelDayTypeFinish.
constraintnum = 1  # Number of next constraint to be added to constraint array
@constraintref s13_and_s14_and_s15_storageleveldaytypefinish[1:length(sregion) * length(sstorage) * length(sseason) * length(sdaytype) * length(syear)]

for row in eachrow(SQLite.query(db, "select r.val as r, s.val as s, ls.val as ls, ld.val as ld, y.val as y, cast(did.val as real) as did
from region r, storage s, season ls, daytype ld, year y
left join DaysInDayType_def did on did.ls = ls.val and did.ld = ld.val + 1 and did.y = y.val"))
    local r = row[:r]
    local s = row[:s]
    local ls = row[:ls]
    local ld = row[:ld]
    local y = row[:y]

    s13_and_s14_and_s15_storageleveldaytypefinish[constraintnum] = @constraint(model, (ls == last(sseason) && ld == last(sdaytype) ? vstoragelevelyearfinish[r,s,y] : (ld == last(sdaytype) ? vstoragelevelseasonstart[r,s,string(Meta.parse(ls)+1),y] : vstorageleveldaytypefinish[r,s,ls,string(Meta.parse(ld)+1),y] - sum([vnetchargewithinday[r,s,ls,string(Meta.parse(ld)+1),lh,y] * row[:did] for lh = sdailytimebracket]))) == vstorageleveldaytypefinish[r,s,ls,ld,y])
    constraintnum += 1
end

logmsg("Created constraint S13_and_S14_and_S15_StorageLevelDayTypeFinish.")
# END: S13_and_S14_and_S15_StorageLevelDayTypeFinish.

# BEGIN: SC1_LowerLimit_BeginningOfDailyTimeBracketOfFirstInstanceOfDayTypeInFirstWeekConstraint.
constraintnum = 1  # Number of next constraint to be added to constraint array

@constraintref sc1_lowerlimit_beginningofdailytimebracketoffirstinstanceofdaytypeinfirstweekconstraint[1:length(sregion) * length(sstorage) * length(sseason) * length(sdaytype) * length(sdailytimebracket) * length(syear)]

querysc1::DataFrames.DataFrame = SQLite.query(db, "select r.val as r, s.val as s, ls.val as ls, ld.val as ld, lh.val as lh, y.val as y,
group_concat(lhlh.val) as lhlha
from region r, storage s, season ls, daytype ld, dailytimebracket lh, year y
left join dailytimebracket lhlh on lh.val > lhlh.val
group by r.val, s.val, ls.val, ld.val, lh.val, y.val")

for row in eachrow(querysc1)
    local r = row[:r]
    local s = row[:s]
    local ls = row[:ls]
    local ld = row[:ld]
    local lh = row[:lh]
    local y = row[:y]

    sc1_lowerlimit_beginningofdailytimebracketoffirstinstanceofdaytypeinfirstweekconstraint[constraintnum] = @constraint(model, 0 <= vstorageleveldaytypestart[r,s,ls,ld,y] + (ismissing(row[:lhlha]) ? 0 : sum([vnetchargewithinday[r,s,ls,ld,lhlh,y] for lhlh = split(row[:lhlha], ",")])) - vstoragelowerlimit[r,s,y])
    constraintnum += 1
end

logmsg("Created constraint SC1_LowerLimit_BeginningOfDailyTimeBracketOfFirstInstanceOfDayTypeInFirstWeekConstraint.")
# END: SC1_LowerLimit_BeginningOfDailyTimeBracketOfFirstInstanceOfDayTypeInFirstWeekConstraint.

# BEGIN: SC1_UpperLimit_BeginningOfDailyTimeBracketOfFirstInstanceOfDayTypeInFirstWeekConstraint.
constraintnum = 1  # Number of next constraint to be added to constraint array

@constraintref sc1_upperlimit_beginningofdailytimebracketoffirstinstanceofdaytypeinfirstweekconstraint[1:length(sregion) * length(sstorage) * length(sseason) * length(sdaytype) * length(sdailytimebracket) * length(syear)]

for row in eachrow(querysc1)
    local r = row[:r]
    local s = row[:s]
    local ls = row[:ls]
    local ld = row[:ld]
    local lh = row[:lh]
    local y = row[:y]

    sc1_upperlimit_beginningofdailytimebracketoffirstinstanceofdaytypeinfirstweekconstraint[constraintnum] = @constraint(model, vstorageleveldaytypestart[r,s,ls,ld,y] + (ismissing(row[:lhlha]) ? 0 : sum([vnetchargewithinday[r,s,ls,ld,lhlh,y] for lhlh = split(row[:lhlha], ",")])) - vstorageupperlimit[r,s,y] <= 0)
    constraintnum += 1
end

logmsg("Created constraint SC1_UpperLimit_BeginningOfDailyTimeBracketOfFirstInstanceOfDayTypeInFirstWeekConstraint.")
# END: SC1_UpperLimit_BeginningOfDailyTimeBracketOfFirstInstanceOfDayTypeInFirstWeekConstraint.

# BEGIN: SC2_LowerLimit_EndOfDailyTimeBracketOfLastInstanceOfDayTypeInFirstWeekConstraint.
constraintnum = 1  # Number of next constraint to be added to constraint array

@constraintref sc2_lowerlimit_endofdailytimebracketoflastinstanceofdaytypeinfirstweekconstraint[1:length(sregion) * length(sstorage) * length(sseason) * length(sdaytype) * length(sdailytimebracket) * length(syear)]

querysc2::DataFrames.DataFrame = SQLite.query(db, "select r.val as r, s.val as s, ls.val as ls, ld.val as ld, lh.val as lh, y.val as y,
group_concat(lhlh.val) as lhlha
from region r, storage s, season ls, daytype ld, dailytimebracket lh, year y
left join dailytimebracket lhlh on lh.val < lhlh.val
where ld.val > (select min(val) from daytype)
group by r.val, s.val, ls.val, ld.val, lh.val, y.val")

for row in eachrow(querysc2)
    local r = row[:r]
    local s = row[:s]
    local ls = row[:ls]
    local ld = row[:ld]
    local lh = row[:lh]
    local y = row[:y]

    sc2_lowerlimit_endofdailytimebracketoflastinstanceofdaytypeinfirstweekconstraint[constraintnum] = @constraint(model, 0 <= vstorageleveldaytypestart[r,s,ls,ld,y] - (ismissing(row[:lhlha]) ? 0 : sum([vnetchargewithinday[r,s,ls,string(Meta.parse(ld)-1),lhlh,y] for lhlh = split(row[:lhlha], ",")])) - vstoragelowerlimit[r,s,y])
    constraintnum += 1
end

logmsg("Created constraint SC2_LowerLimit_EndOfDailyTimeBracketOfLastInstanceOfDayTypeInFirstWeekConstraint.")
# END: SC2_LowerLimit_EndOfDailyTimeBracketOfLastInstanceOfDayTypeInFirstWeekConstraint.

# BEGIN: SC2_UpperLimit_EndOfDailyTimeBracketOfLastInstanceOfDayTypeInFirstWeekConstraint.
constraintnum = 1  # Number of next constraint to be added to constraint array

@constraintref sc2_upperlimit_endofdailytimebracketoflastinstanceofdaytypeinfirstweekconstraint[1:length(sregion) * length(sstorage) * length(sseason) * length(sdaytype) * length(sdailytimebracket) * length(syear)]

for row in eachrow(querysc2)
    local r = row[:r]
    local s = row[:s]
    local ls = row[:ls]
    local ld = row[:ld]
    local lh = row[:lh]
    local y = row[:y]

    sc2_upperlimit_endofdailytimebracketoflastinstanceofdaytypeinfirstweekconstraint[constraintnum] = @constraint(model, vstorageleveldaytypestart[r,s,ls,ld,y] - (ismissing(row[:lhlha]) ? 0 : sum([vnetchargewithinday[r,s,ls,string(Meta.parse(ld)-1),lhlh,y] for lhlh = split(row[:lhlha], ",")])) - vstorageupperlimit[r,s,y] <= 0)
    constraintnum += 1
end

logmsg("Created constraint SC2_UpperLimit_EndOfDailyTimeBracketOfLastInstanceOfDayTypeInFirstWeekConstraint.")
# END: SC2_UpperLimit_EndOfDailyTimeBracketOfLastInstanceOfDayTypeInFirstWeekConstraint.

# BEGIN: SC3_LowerLimit_EndOfDailyTimeBracketOfLastInstanceOfDayTypeInLastWeekConstraint.
constraintnum = 1  # Number of next constraint to be added to constraint array

@constraintref sc3_lowerlimit_endofdailytimebracketoflastinstanceofdaytypeinlastweekconstraint[1:length(sregion) * length(sstorage) * length(sseason) * length(sdaytype) * length(sdailytimebracket) * length(syear)]

querysc3::DataFrames.DataFrame = SQLite.query(db, "select r.val as r, s.val as s, ls.val as ls, ld.val as ld, lh.val as lh, y.val as y,
group_concat(lhlh.val) as lhlha
from region r, storage s, season ls, daytype ld, dailytimebracket lh, year y
left join dailytimebracket lhlh on lh.val < lhlh.val
group by r.val, s.val, ls.val, ld.val, lh.val, y.val")

for row in eachrow(querysc3)
    local r = row[:r]
    local s = row[:s]
    local ls = row[:ls]
    local ld = row[:ld]
    local lh = row[:lh]
    local y = row[:y]

    sc3_lowerlimit_endofdailytimebracketoflastinstanceofdaytypeinlastweekconstraint[constraintnum] = @constraint(model, 0 <= vstorageleveldaytypefinish[r,s,ls,ld,y] - (ismissing(row[:lhlha]) ? 0 : sum([vnetchargewithinday[r,s,ls,ld,lhlh,y] for lhlh = split(row[:lhlha], ",")])) - vstoragelowerlimit[r,s,y])
    constraintnum += 1
end

logmsg("Created constraint SC3_LowerLimit_EndOfDailyTimeBracketOfLastInstanceOfDayTypeInLastWeekConstraint.")
# END: SC3_LowerLimit_EndOfDailyTimeBracketOfLastInstanceOfDayTypeInLastWeekConstraint.

# BEGIN: SC3_UpperLimit_EndOfDailyTimeBracketOfLastInstanceOfDayTypeInLastWeekConstraint.
constraintnum = 1  # Number of next constraint to be added to constraint array

@constraintref sc3_upperlimit_endofdailytimebracketoflastinstanceofdaytypeinlastweekconstraint[1:length(sregion) * length(sstorage) * length(sseason) * length(sdaytype) * length(sdailytimebracket) * length(syear)]

for row in eachrow(querysc3)
    local r = row[:r]
    local s = row[:s]
    local ls = row[:ls]
    local ld = row[:ld]
    local lh = row[:lh]
    local y = row[:y]

    sc3_upperlimit_endofdailytimebracketoflastinstanceofdaytypeinlastweekconstraint[constraintnum] = @constraint(model, vstorageleveldaytypefinish[r,s,ls,ld,y] - (ismissing(row[:lhlha]) ? 0 : sum([vnetchargewithinday[r,s,ls,ld,lhlh,y] for lhlh = split(row[:lhlha], ",")])) - vstorageupperlimit[r,s,y] <= 0)
    constraintnum += 1
end

logmsg("Created constraint SC3_UpperLimit_EndOfDailyTimeBracketOfLastInstanceOfDayTypeInLastWeekConstraint.")
# END: SC3_UpperLimit_EndOfDailyTimeBracketOfLastInstanceOfDayTypeInLastWeekConstraint.

# BEGIN: SC4_LowerLimit_BeginningOfDailyTimeBracketOfFirstInstanceOfDayTypeInLastWeekConstraint.
constraintnum = 1  # Number of next constraint to be added to constraint array

@constraintref sc4_lowerlimit_beginningofdailytimebracketoffirstinstanceofdaytypeinlastweekconstraint[1:length(sregion) * length(sstorage) * length(sseason) * length(sdaytype) * length(sdailytimebracket) * length(syear)]

querysc4::DataFrames.DataFrame = SQLite.query(db, "select r.val as r, s.val as s, ls.val as ls, ld.val as ld, lh.val as lh, y.val as y,
group_concat(lhlh.val) as lhlha
from region r, storage s, season ls, daytype ld, dailytimebracket lh, year y
left join dailytimebracket lhlh on lh.val > lhlh.val
where ld.val > (select min(val) from daytype)
group by r.val, s.val, ls.val, ld.val, lh.val, y.val")

for row in eachrow(querysc4)
    local r = row[:r]
    local s = row[:s]
    local ls = row[:ls]
    local ld = row[:ld]
    local lh = row[:lh]
    local y = row[:y]

    sc4_lowerlimit_beginningofdailytimebracketoffirstinstanceofdaytypeinlastweekconstraint[constraintnum] = @constraint(model, 0 <= vstorageleveldaytypefinish[r,s,ls,string(Meta.parse(ld)-1),y] + (ismissing(row[:lhlha]) ? 0 : sum([vnetchargewithinday[r,s,ls,ld,lhlh,y] for lhlh = split(row[:lhlha], ",")])) - vstoragelowerlimit[r,s,y])
    constraintnum += 1
end

logmsg("Created constraint SC4_LowerLimit_BeginningOfDailyTimeBracketOfFirstInstanceOfDayTypeInLastWeekConstraint.")
# END: SC4_LowerLimit_BeginningOfDailyTimeBracketOfFirstInstanceOfDayTypeInLastWeekConstraint.

# BEGIN: SC4_UpperLimit_BeginningOfDailyTimeBracketOfFirstInstanceOfDayTypeInLastWeekConstraint.
constraintnum = 1  # Number of next constraint to be added to constraint array

@constraintref sc4_upperlimit_beginningofdailytimebracketoffirstinstanceofdaytypeinlastweekconstraint[1:length(sregion) * length(sstorage) * length(sseason) * length(sdaytype) * length(sdailytimebracket) * length(syear)]

for row in eachrow(querysc4)
    local r = row[:r]
    local s = row[:s]
    local ls = row[:ls]
    local ld = row[:ld]
    local lh = row[:lh]
    local y = row[:y]

    sc4_upperlimit_beginningofdailytimebracketoffirstinstanceofdaytypeinlastweekconstraint[constraintnum] = @constraint(model, vstorageleveldaytypefinish[r,s,ls,string(Meta.parse(ld)-1),y] + (ismissing(row[:lhlha]) ? 0 : sum([vnetchargewithinday[r,s,ls,ld,lhlh,y] for lhlh = split(row[:lhlha], ",")])) - vstorageupperlimit[r,s,y] <= 0)
    constraintnum += 1
end

logmsg("Created constraint SC4_UpperLimit_BeginningOfDailyTimeBracketOfFirstInstanceOfDayTypeInLastWeekConstraint.")
# END: SC4_UpperLimit_BeginningOfDailyTimeBracketOfFirstInstanceOfDayTypeInLastWeekConstraint.

# BEGIN: SC5_MaxChargeConstraint.
constraintnum = 1  # Number of next constraint to be added to constraint array

@constraintref sc5_maxchargeconstraint[1:length(sregion) * length(sstorage) * length(sseason) * length(sdaytype) * length(sdailytimebracket) * length(syear)]

for row in eachrow(SQLite.query(db, "select r.val as r, s.val as s, ls.val as ls, ld.val as ld, lh.val as lh, y.val as y, cast(smx.val as real) as smx
from region r, storage s, season ls, daytype ld, dailytimebracket lh, year y, StorageMaxChargeRate_def smx
where smx.r = r.val and smx.s = s.val"))
    local r = row[:r]
    local s = row[:s]
    local ls = row[:ls]
    local ld = row[:ld]
    local lh = row[:lh]
    local y = row[:y]

    sc5_maxchargeconstraint[constraintnum] = @constraint(model, vrateofstoragecharge[r,s,ls,ld,lh,y] <= row[:smx])
    constraintnum += 1
end

logmsg("Created constraint SC5_MaxChargeConstraint.")
# END: SC5_MaxChargeConstraint.

# BEGIN: SC6_MaxDischargeConstraint.
constraintnum = 1  # Number of next constraint to be added to constraint array

@constraintref sc6_maxdischargeconstraint[1:length(sregion) * length(sstorage) * length(sseason) * length(sdaytype) * length(sdailytimebracket) * length(syear)]

for row in eachrow(SQLite.query(db, "select r.val as r, s.val as s, ls.val as ls, ld.val as ld, lh.val as lh, y.val as y, cast(smx.val as real) as smx
from region r, storage s, season ls, daytype ld, dailytimebracket lh, year y, StorageMaxDischargeRate_def smx
where smx.r = r.val and smx.s = s.val"))
    local r = row[:r]
    local s = row[:s]
    local ls = row[:ls]
    local ld = row[:ld]
    local lh = row[:lh]
    local y = row[:y]

    sc6_maxdischargeconstraint[constraintnum] = @constraint(model, vrateofstoragedischarge[r,s,ls,ld,lh,y] <= row[:smx])
    constraintnum += 1
end

logmsg("Created constraint SC6_MaxDischargeConstraint.")
# END: SC6_MaxDischargeConstraint.

# BEGIN: SI1_StorageUpperLimit.
constraintnum = 1  # Number of next constraint to be added to constraint array

@constraintref si1_storageupperlimit[1:length(sregion) * length(sstorage) * length(syear)]

for row in eachrow(SQLite.query(db, "select r.val as r, s.val as s, y.val as y, cast(rsc.val as real) as rsc
from region r, storage s, year y
left join ResidualStorageCapacity_def rsc on rsc.r = r.val and rsc.s = s.val and rsc.y = y.val"))
    local r = row[:r]
    local s = row[:s]
    local y = row[:y]

    si1_storageupperlimit[constraintnum] = @constraint(model, vaccumulatednewstoragecapacity[r,s,y] + (ismissing(row[:rsc]) ? 0 : row[:rsc]) == vstorageupperlimit[r,s,y])
    constraintnum += 1
end

logmsg("Created constraint SI1_StorageUpperLimit.")
# END: SI1_StorageUpperLimit.

# BEGIN: SI2_StorageLowerLimit.
constraintnum = 1  # Number of next constraint to be added to constraint array

@constraintref si2_storagelowerlimit[1:length(sregion) * length(sstorage) * length(syear)]

for row in eachrow(SQLite.query(db, "select r.val as r, s.val as s, y.val as y, cast(msc.val as real) as msc
from region r, storage s, year y, MinStorageCharge_def msc
where msc.r = r.val and msc.s = s.val and msc.y = y.val"))
    local r = row[:r]
    local s = row[:s]
    local y = row[:y]

    si2_storagelowerlimit[constraintnum] = @constraint(model, row[:msc] * vstorageupperlimit[r,s,y] == vstoragelowerlimit[r,s,y])
    constraintnum += 1
end

logmsg("Created constraint SI2_StorageLowerLimit.")
# END: SI2_StorageLowerLimit.

# BEGIN: SI3_TotalNewStorage.
constraintnum = 1  # Number of next constraint to be added to constraint array

@constraintref si3_totalnewstorage[1:length(sregion) * length(sstorage) * length(syear)]

for row in eachrow(SQLite.query(db, "select r.val as r, s.val as s, y.val as y, cast(ols.val as real) as ols, group_concat(yy.val) as yya
from region r, storage s, year y, OperationalLifeStorage_def ols, year yy
where ols.r = r.val and ols.s = s.val
and y.val - yy.val < ols.val and y.val - yy.val >= 0
group by r.val, s.val, y.val"))
    local r = row[:r]
    local s = row[:s]
    local y = row[:y]

    si3_totalnewstorage[constraintnum] = @constraint(model, sum([vnewstoragecapacity[r,s,yy] for yy = split(row[:yya], ",")]) == vaccumulatednewstoragecapacity[r,s,y])
    constraintnum += 1
end

logmsg("Created constraint SI3_TotalNewStorage.")
# END: SI3_TotalNewStorage.

# BEGIN: SI4_UndiscountedCapitalInvestmentStorage.
constraintnum = 1  # Number of next constraint to be added to constraint array

@constraintref si4_undiscountedcapitalinvestmentstorage[1:length(sregion) * length(sstorage) * length(syear)]

for row in eachrow(SQLite.query(db, "select r.val as r, s.val as s, y.val as y, cast(ccs.val as real) as ccs
from region r, storage s, year y, CapitalCostStorage_def ccs
where ccs.r = r.val and ccs.s = s.val and ccs.y = y.val"))
    local r = row[:r]
    local s = row[:s]
    local y = row[:y]

    si4_undiscountedcapitalinvestmentstorage[constraintnum] = @constraint(model, row[:ccs] * vnewstoragecapacity[r,s,y] == vcapitalinvestmentstorage[r,s,y])
    constraintnum += 1
end

logmsg("Created constraint SI4_UndiscountedCapitalInvestmentStorage.")
# END: SI4_UndiscountedCapitalInvestmentStorage.

# BEGIN: SI5_DiscountingCapitalInvestmentStorage.
constraintnum = 1  # Number of next constraint to be added to constraint array

@constraintref si5_discountingcapitalinvestmentstorage[1:length(sregion) * length(sstorage) * length(syear)]

for row in eachrow(SQLite.query(db, "select r.val as r, s.val as s, y.val as y, cast(dr.val as real) as dr
from region r, storage s, year y, DiscountRate_def dr
where dr.r = r.val"))
    local r = row[:r]
    local s = row[:s]
    local y = row[:y]

    si5_discountingcapitalinvestmentstorage[constraintnum] = @constraint(model, vcapitalinvestmentstorage[r,s,y] / ((1 + row[:dr])^(Meta.parse(y) - Meta.parse(first(syear)))) == vdiscountedcapitalinvestmentstorage[r,s,y])
    constraintnum += 1
end

logmsg("Created constraint SI5_DiscountingCapitalInvestmentStorage.")
# END: SI5_DiscountingCapitalInvestmentStorage.

# BEGIN: SI6_SalvageValueStorageAtEndOfPeriod1.
constraintnum = 1  # Number of next constraint to be added to constraint array

@constraintref si6_salvagevaluestorageatendofperiod1[1:length(sregion) * length(sstorage) * length(syear)]

for row in eachrow(SQLite.query(db, "select r.val as r, s.val as s, y.val as y
from region r, storage s, year y, OperationalLifeStorage_def ols
where ols.r = r.val and ols.s = s.val
and y.val + ols.val - 1 <= " * last(syear)))
    local r = row[:r]
    local s = row[:s]
    local y = row[:y]

    si6_salvagevaluestorageatendofperiod1[constraintnum] = @constraint(model, 0 == vsalvagevaluestorage[r,s,y])
    constraintnum += 1
end

logmsg("Created constraint SI6_SalvageValueStorageAtEndOfPeriod1.")
# END: SI6_SalvageValueStorageAtEndOfPeriod1.

# BEGIN: SI7_SalvageValueStorageAtEndOfPeriod2.
constraintnum = 1  # Number of next constraint to be added to constraint array

@constraintref si7_salvagevaluestorageatendofperiod2[1:length(sregion) * length(sstorage) * length(syear)]

for row in eachrow(SQLite.query(db, "select r.val as r, s.val as s, y.val as y, cast(ols.val as real) as ols
from region r, storage s, year y, DepreciationMethod_def dm, OperationalLifeStorage_def ols, DiscountRate_def dr
where dm.r = r.val and dm.val = 1
and ols.r = r.val and ols.s = s.val
and y.val + ols.val - 1 > " * last(syear) *
" and dr.r = r.val and dr.val = 0
union
select r.val as r, s.val as s, y.val as y, cast(ols.val as real) as ols
from region r, storage s, year y, DepreciationMethod_def dm, OperationalLifeStorage_def ols
where dm.r = r.val and dm.val = 2
and ols.r = r.val and ols.s = s.val
and y.val + ols.val - 1 > " * last(syear)))
    local r = row[:r]
    local s = row[:s]
    local y = row[:y]

    si7_salvagevaluestorageatendofperiod2[constraintnum] = @constraint(model, vcapitalinvestmentstorage[r,s,y] * (1 - (Meta.parse(last(syear)) - Meta.parse(y) + 1) / row[:ols]) == vsalvagevaluestorage[r,s,y])
    constraintnum += 1
end

logmsg("Created constraint SI7_SalvageValueStorageAtEndOfPeriod2.")
# END: SI7_SalvageValueStorageAtEndOfPeriod2.

# BEGIN: SI8_SalvageValueStorageAtEndOfPeriod3.
constraintnum = 1  # Number of next constraint to be added to constraint array

@constraintref si8_salvagevaluestorageatendofperiod3[1:length(sregion) * length(sstorage) * length(syear)]

for row in eachrow(SQLite.query(db, "select r.val as r, s.val as s, y.val as y, cast(dr.val as real) as dr, cast(ols.val as real) as ols
from region r, storage s, year y, DepreciationMethod_def dm, OperationalLifeStorage_def ols, DiscountRate_def dr
where dm.r = r.val and dm.val = 1
and ols.r = r.val and ols.s = s.val
and y.val + ols.val - 1 > " * last(syear) *
" and dr.r = r.val and dr.val > 0"))
    local r = row[:r]
    local s = row[:s]
    local y = row[:y]
    local dr = row[:dr]

    si8_salvagevaluestorageatendofperiod3[constraintnum] = @constraint(model, vcapitalinvestmentstorage[r,s,y] * (1 - (((1 + dr)^(Meta.parse(last(syear)) - Meta.parse(y) + 1) - 1) / ((1 + dr)^(row[:ols]) - 1))) == vsalvagevaluestorage[r,s,y])
    constraintnum += 1
end

logmsg("Created constraint SI8_SalvageValueStorageAtEndOfPeriod3.")
# END: SI8_SalvageValueStorageAtEndOfPeriod3.

# BEGIN: SI9_SalvageValueStorageDiscountedToStartYear.
constraintnum = 1  # Number of next constraint to be added to constraint array

@constraintref si9_salvagevaluestoragediscountedtostartyear[1:length(sregion) * length(sstorage) * length(syear)]

for row in eachrow(SQLite.query(db, "select r.val as r, s.val as s, y.val as y, cast(dr.val as real) as dr
from region r, storage s, year y, DiscountRate_def dr
where dr.r = r.val"))
    local r = row[:r]
    local s = row[:s]
    local y = row[:y]

    si9_salvagevaluestoragediscountedtostartyear[constraintnum] = @constraint(model, vsalvagevaluestorage[r,s,y] / ((1 + row[:dr])^(Meta.parse(last(syear)) - Meta.parse(first(syear)) + 1)) == vdiscountedsalvagevaluestorage[r,s,y])
    constraintnum += 1
end

logmsg("Created constraint SI9_SalvageValueStorageDiscountedToStartYear.")
# END: SI9_SalvageValueStorageDiscountedToStartYear.

# BEGIN: SI10_TotalDiscountedCostByStorage.
constraintnum = 1  # Number of next constraint to be added to constraint array
@constraintref si10_totaldiscountedcostbystorage[1:length(sregion) * length(sstorage) * length(syear)]

for (r, s, y) in Base.product(sregion, sstorage, syear)
    si10_totaldiscountedcostbystorage[constraintnum] = @constraint(model, vdiscountedcapitalinvestmentstorage[r,s,y] - vdiscountedsalvagevaluestorage[r,s,y] == vtotaldiscountedstoragecost[r,s,y])
    constraintnum += 1
end

logmsg("Created constraint SI10_TotalDiscountedCostByStorage.")
# END: SI10_TotalDiscountedCostByStorage.

# BEGIN: CC1_UndiscountedCapitalInvestment.
constraintnum = 1  # Number of next constraint to be added to constraint array

@constraintref cc1_undiscountedcapitalinvestment[1:length(sregion) * length(stechnology) * length(syear)]

for row in eachrow(SQLite.query(db, "select r.val as r, t.val as t, y.val as y, cast(cc.val as real) as cc
from region r, technology t, year y, CapitalCost_def cc
where cc.r = r.val and cc.t = t.val and cc.y = y.val"))
    local r = row[:r]
    local t = row[:t]
    local y = row[:y]

    cc1_undiscountedcapitalinvestment[constraintnum] = @constraint(model, row[:cc] * vnewcapacity[r,t,y] == vcapitalinvestment[r,t,y])
    constraintnum += 1
end

logmsg("Created constraint CC1_UndiscountedCapitalInvestment.")
# END: CC1_UndiscountedCapitalInvestment.

# BEGIN: CC2_DiscountingCapitalInvestment.
constraintnum = 1  # Number of next constraint to be added to constraint array

queryrtydr::DataFrames.DataFrame = SQLite.query(db, "select r.val as r, t.val as t, y.val as y, cast(dr.val as real) as dr
from region r, technology t, year y, DiscountRate_def dr
where dr.r = r.val")

@constraintref cc2_discountingcapitalinvestment[1:size(queryrtydr)[1]]

for row in eachrow(queryrtydr)
    local r = row[:r]
    local t = row[:t]
    local y = row[:y]

    cc2_discountingcapitalinvestment[constraintnum] = @constraint(model, vcapitalinvestment[r,t,y] / ((1 + row[:dr])^(Meta.parse(y) - Meta.parse(first(syear)))) == vdiscountedcapitalinvestment[r,t,y])
    constraintnum += 1
end

logmsg("Created constraint CC2_DiscountingCapitalInvestment.")
# END: CC2_DiscountingCapitalInvestment.

# BEGIN: SV1_SalvageValueAtEndOfPeriod1.
constraintnum = 1  # Number of next constraint to be added to constraint array

@constraintref sv1_salvagevalueatendofperiod1[1:length(sregion) * length(stechnology) * length(syear)]

for row in eachrow(SQLite.query(db, "select r.val as r, t.val as t, y.val as y, cast(cc.val as real) as cc, cast(dr.val as real) as dr,
cast(ol.val as real) as ol
from region r, technology t, year y, DepreciationMethod_def dm, OperationalLife_def ol, DiscountRate_def dr,
CapitalCost_def cc
where dm.r = r.val and dm.val = 1
and ol.r = r.val and ol.t = t.val
and y.val + ol.val - 1 > " * last(syear) *
" and dr.r = r.val and dr.val > 0
and cc.r = r.val and cc.t = t.val and cc.y = y.val"))
    local r = row[:r]
    local t = row[:t]
    local y = row[:y]
    local dr = row[:dr]

    sv1_salvagevalueatendofperiod1[constraintnum] = @constraint(model, vsalvagevalue[r,t,y] == row[:cc] * vnewcapacity[r,t,y] * (1 - (((1 + dr)^(Meta.parse(last(syear)) - Meta.parse(y) + 1) - 1) / ((1 + dr)^(row[:ol]) - 1))))
    constraintnum += 1
end

logmsg("Created constraint SV1_SalvageValueAtEndOfPeriod1.")
# END: SV1_SalvageValueAtEndOfPeriod1.

# BEGIN: SV2_SalvageValueAtEndOfPeriod2.
constraintnum = 1  # Number of next constraint to be added to constraint array

@constraintref sv2_salvagevalueatendofperiod2[1:length(sregion) * length(stechnology) * length(syear)]

for row in eachrow(SQLite.query(db, "select r.val as r, t.val as t, y.val as y, cast(cc.val as real) as cc, cast(ol.val as real) as ol
from region r, technology t, year y, DepreciationMethod_def dm, OperationalLife_def ol, DiscountRate_def dr,
CapitalCost_def cc
where dm.r = r.val and dm.val = 1
and ol.r = r.val and ol.t = t.val
and y.val + ol.val - 1 > " * last(syear) *
" and dr.r = r.val and dr.val = 0
and cc.r = r.val and cc.t = t.val and cc.y = y.val
union
select r.val as r, t.val as t, y.val as y, cast(cc.val as real) as cc, cast(ol.val as real) as ol
from region r, technology t, year y, DepreciationMethod_def dm, OperationalLife_def ol,
CapitalCost_def cc
where dm.r = r.val and dm.val = 2
and ol.r = r.val and ol.t = t.val
and y.val + ol.val - 1 > " * last(syear) *
" and cc.r = r.val and cc.t = t.val and cc.y = y.val"))
    local r = row[:r]
    local t = row[:t]
    local y = row[:y]

    sv2_salvagevalueatendofperiod2[constraintnum] = @constraint(model, vsalvagevalue[r,t,y] == row[:cc] * vnewcapacity[r,t,y] * (1 - (Meta.parse(last(syear)) - Meta.parse(y) + 1) / row[:ol]))
    constraintnum += 1
end

logmsg("Created constraint SV2_SalvageValueAtEndOfPeriod2.")
# END: SV2_SalvageValueAtEndOfPeriod2.

# BEGIN: SV3_SalvageValueAtEndOfPeriod3.
constraintnum = 1  # Number of next constraint to be added to constraint array

@constraintref sv3_salvagevalueatendofperiod3[1:length(sregion) * length(stechnology) * length(syear)]

for row in eachrow(SQLite.query(db, "select r.val as r, t.val as t, y.val as y
from region r, technology t, year y, OperationalLife_def ol
where ol.r = r.val and ol.t = t.val
and y.val + ol.val - 1 <= " * last(syear)))
    local r = row[:r]
    local t = row[:t]
    local y = row[:y]

    sv3_salvagevalueatendofperiod3[constraintnum] = @constraint(model, vsalvagevalue[r,t,y] == 0)
    constraintnum += 1
end

logmsg("Created constraint SV3_SalvageValueAtEndOfPeriod3.")
# END: SV3_SalvageValueAtEndOfPeriod3.

# BEGIN: SV4_SalvageValueDiscountedToStartYear.
constraintnum = 1  # Number of next constraint to be added to constraint array

@constraintref sv4_salvagevaluediscountedtostartyear[1:size(queryrtydr)[1]]

for row in eachrow(queryrtydr)
    local r = row[:r]
    local t = row[:t]
    local y = row[:y]

    sv4_salvagevaluediscountedtostartyear[constraintnum] = @constraint(model, vdiscountedsalvagevalue[r,t,y] == vsalvagevalue[r,t,y] / ((1 + row[:dr])^(1 + Meta.parse(last(syear)) - Meta.parse(first(syear)))))
    constraintnum += 1
end

logmsg("Created constraint SV4_SalvageValueDiscountedToStartYear.")
# END: SV4_SalvageValueDiscountedToStartYear.

# BEGIN: OC1_OperatingCostsVariable.
constraintnum = 1  # Number of next constraint to be added to constraint array

@constraintref oc1_operatingcostsvariable[1:length(sregion) * length(stechnology) * length(syear)]

for row in eachrow(SQLite.query(db, "select r.val as r, t.val as t, y.val as y, group_concat(m.val || ';' || vc.val) as mva
from region r, technology t, year y, mode_of_operation m, VariableCost_def vc
where vc.r = r.val and vc.t = t.val and vc.m = m.val and vc.y = y.val
group by r.val, t.val, y.val"))
    local r = row[:r]
    local t = row[:t]
    local y = row[:y]

    oc1_operatingcostsvariable[constraintnum] = @constraint(model, sum([vtotalannualtechnologyactivitybymode[r,t,split(mv,";")[1],y] * Meta.parse(split(mv,";")[2]) for mv = split(row[:mva], ",")]) == vannualvariableoperatingcost[r,t,y])
    constraintnum += 1
end

logmsg("Created constraint OC1_OperatingCostsVariable.")
# END: OC1_OperatingCostsVariable.

# BEGIN: OC2_OperatingCostsFixedAnnual.
constraintnum = 1  # Number of next constraint to be added to constraint array

@constraintref oc2_operatingcostsfixedannual[1:length(sregion) * length(stechnology) * length(syear)]

for row in eachrow(SQLite.query(db, "select r.val as r, t.val as t, y.val as y, cast(fc.val as real) as fc
from region r, technology t, year y, FixedCost_def fc
where fc.r = r.val and fc.t = t.val and fc.y = y.val"))
    local r = row[:r]
    local t = row[:t]
    local y = row[:y]

    oc2_operatingcostsfixedannual[constraintnum] = @constraint(model, vtotalcapacityannual[r,t,y] * row[:fc] == vannualfixedoperatingcost[r,t,y])
    constraintnum += 1
end

logmsg("Created constraint OC2_OperatingCostsFixedAnnual.")
# END: OC2_OperatingCostsFixedAnnual.

# BEGIN: OC3_OperatingCostsTotalAnnual.
constraintnum = 1  # Number of next constraint to be added to constraint array
@constraintref oc3_operatingcoststotalannual[1:length(sregion) * length(stechnology) * length(syear)]

for (r, t, y) in Base.product(sregion, stechnology, syear)
    oc3_operatingcoststotalannual[constraintnum] = @constraint(model, vannualfixedoperatingcost[r,t,y] + vannualvariableoperatingcost[r,t,y] == voperatingcost[r,t,y])
    constraintnum += 1
end

logmsg("Created constraint OC3_OperatingCostsTotalAnnual.")
# END: OC3_OperatingCostsTotalAnnual.

# BEGIN: OC4_DiscountedOperatingCostsTotalAnnual.
constraintnum = 1  # Number of next constraint to be added to constraint array

@constraintref oc4_discountedoperatingcoststotalannual[1:length(sregion) * length(stechnology) * length(syear)]

for row in eachrow(queryrtydr)
    local r = row[:r]
    local t = row[:t]
    local y = row[:y]
    local dr = row[:dr]

    oc4_discountedoperatingcoststotalannual[constraintnum] = @constraint(model, voperatingcost[r,t,y] / ((1 + dr)^(Meta.parse(y) - Meta.parse(first(syear)) + 0.5)) == vdiscountedoperatingcost[r,t,y])
    constraintnum += 1
end

logmsg("Created constraint OC4_DiscountedOperatingCostsTotalAnnual.")
# END: OC4_DiscountedOperatingCostsTotalAnnual.

# BEGIN: TDC1_TotalDiscountedCostByTechnology.
constraintnum = 1  # Number of next constraint to be added to constraint array
@constraintref tdc1_totaldiscountedcostbytechnology[1:length(sregion) * length(stechnology) * length(syear)]

for (r, t, y) in Base.product(sregion, stechnology, syear)
    tdc1_totaldiscountedcostbytechnology[constraintnum] = @constraint(model, vdiscountedoperatingcost[r,t,y] + vdiscountedcapitalinvestment[r,t,y] + vdiscountedtechnologyemissionspenalty[r,t,y] - vdiscountedsalvagevalue[r,t,y] == vtotaldiscountedcostbytechnology[r,t,y])
    constraintnum += 1
end

logmsg("Created constraint TDC1_TotalDiscountedCostByTechnology.")
# END: TDC1_TotalDiscountedCostByTechnology.

# BEGIN: TDC2_TotalDiscountedCost.
constraintnum = 1  # Number of next constraint to be added to constraint array
@constraintref tdc2_totaldiscountedcost[1:length(sregion) * length(syear)]

for (r, y) in Base.product(sregion, syear)
    tdc2_totaldiscountedcost[constraintnum] = @constraint(model, (length(stechnology) == 0 ? 0 : sum([vtotaldiscountedcostbytechnology[r,t,y] for t = stechnology])) + (length(sstorage) == 0 ? 0 : sum([vtotaldiscountedstoragecost[r,s,y] for s = sstorage])) == vtotaldiscountedcost[r,y])
    constraintnum += 1
end

logmsg("Created constraint TDC2_TotalDiscountedCost.")
# END: TDC2_TotalDiscountedCost.

# BEGIN: TCC1_TotalAnnualMaxCapacityConstraint.
constraintnum = 1  # Number of next constraint to be added to constraint array
@constraintref tcc1_totalannualmaxcapacityconstraint[1:length(sregion) * length(stechnology) * length(syear)]

for row in eachrow(SQLite.query(db, "select r, t, y, cast(val as real) as tmx
from TotalAnnualMaxCapacity_def"))
    local r = row[:r]
    local t = row[:t]
    local y = row[:y]

    tcc1_totalannualmaxcapacityconstraint[constraintnum] = @constraint(model, vtotalcapacityannual[r,t,y] <= row[:tmx])
    constraintnum += 1
end

logmsg("Created constraint TCC1_TotalAnnualMaxCapacityConstraint.")
# END: TCC1_TotalAnnualMaxCapacityConstraint.

# BEGIN: TCC2_TotalAnnualMinCapacityConstraint.
constraintnum = 1  # Number of next constraint to be added to constraint array
@constraintref tcc2_totalannualmincapacityconstraint[1:length(sregion) * length(stechnology) * length(syear)]

for row in eachrow(SQLite.query(db, "select r, t, y, cast(val as real) as tmn
from TotalAnnualMinCapacity_def
where val > 0"))
    local r = row[:r]
    local t = row[:t]
    local y = row[:y]

    tcc2_totalannualmincapacityconstraint[constraintnum] = @constraint(model, vtotalcapacityannual[r,t,y] >= row[:tmn])
    constraintnum += 1
end

logmsg("Created constraint TCC2_TotalAnnualMinCapacityConstraint.")
# END: TCC2_TotalAnnualMinCapacityConstraint.

# BEGIN: NCC1_TotalAnnualMaxNewCapacityConstraint.
constraintnum = 1  # Number of next constraint to be added to constraint array
@constraintref ncc1_totalannualmaxnewcapacityconstraint[1:length(sregion) * length(stechnology) * length(syear)]

for row in eachrow(SQLite.query(db, "select r, t, y, cast(val as real) as tmx
from TotalAnnualMaxCapacityInvestment_def"))
    local r = row[:r]
    local t = row[:t]
    local y = row[:y]

    ncc1_totalannualmaxnewcapacityconstraint[constraintnum] = @constraint(model, vnewcapacity[r,t,y] <= row[:tmx])
    constraintnum += 1
end

logmsg("Created constraint NCC1_TotalAnnualMaxNewCapacityConstraint.")
# END: NCC1_TotalAnnualMaxNewCapacityConstraint.

# BEGIN: NCC2_TotalAnnualMinNewCapacityConstraint.
constraintnum = 1  # Number of next constraint to be added to constraint array
@constraintref ncc2_totalannualminnewcapacityconstraint[1:length(sregion) * length(stechnology) * length(syear)]

for row in eachrow(SQLite.query(db, "select r, t, y, cast(val as real) as tmn
from TotalAnnualMinCapacityInvestment_def
where val > 0"))
    local r = row[:r]
    local t = row[:t]
    local y = row[:y]

    ncc2_totalannualminnewcapacityconstraint[constraintnum] = @constraint(model, vnewcapacity[r,t,y] >= row[:tmn])
    constraintnum += 1
end

logmsg("Created constraint NCC2_TotalAnnualMinNewCapacityConstraint.")
# END: NCC2_TotalAnnualMinNewCapacityConstraint.

# BEGIN: AAC1_TotalAnnualTechnologyActivity.
constraintnum = 1  # Number of next constraint to be added to constraint array

@constraintref aac1_totalannualtechnologyactivity[1:length(sregion) * length(stechnology) * length(syear)]

for row in eachrow(SQLite.query(db, "select r.val as r, t.val as t, y.val as y, group_concat(l.val || ';' || ys.val) as lya
from region r, technology t, year y, timeslice l, YearSplit_def ys
where ys.l = l.val and ys.y = y.val
group by r.val, t.val, y.val"))
    local r = row[:r]
    local t = row[:t]
    local y = row[:y]

    aac1_totalannualtechnologyactivity[constraintnum] = @constraint(model, sum([vrateoftotalactivity[r,t,split(ly,";")[1],y] * Meta.parse(split(ly,";")[2]) for ly = split(row[:lya], ",")]) == vtotaltechnologyannualactivity[r,t,y])
    constraintnum += 1
end

logmsg("Created constraint AAC1_TotalAnnualTechnologyActivity.")
# END: AAC1_TotalAnnualTechnologyActivity.

# BEGIN: AAC2_TotalAnnualTechnologyActivityUpperLimit.
constraintnum = 1  # Number of next constraint to be added to constraint array
@constraintref aac2_totalannualtechnologyactivityupperlimit[1:length(sregion) * length(stechnology) * length(syear)]

for row in eachrow(SQLite.query(db, "select r, t, y, cast(val as real) as amx
from TotalTechnologyAnnualActivityUpperLimit_def"))
    local r = row[:r]
    local t = row[:t]
    local y = row[:y]

    aac2_totalannualtechnologyactivityupperlimit[constraintnum] = @constraint(model, vtotaltechnologyannualactivity[r,t,y] <= row[:amx])
    constraintnum += 1
end

logmsg("Created constraint AAC2_TotalAnnualTechnologyActivityUpperLimit.")
# END: AAC2_TotalAnnualTechnologyActivityUpperLimit.

# BEGIN: AAC3_TotalAnnualTechnologyActivityLowerLimit.
constraintnum = 1  # Number of next constraint to be added to constraint array
@constraintref aac3_totalannualtechnologyactivitylowerlimit[1:length(sregion) * length(stechnology) * length(syear)]

for row in eachrow(SQLite.query(db, "select r, t, y, cast(val as real) as amn
from TotalTechnologyAnnualActivityLowerLimit_def
where val > 0"))
    local r = row[:r]
    local t = row[:t]
    local y = row[:y]

    aac3_totalannualtechnologyactivitylowerlimit[constraintnum] = @constraint(model, vtotaltechnologyannualactivity[r,t,y] >= row[:amn])
    constraintnum += 1
end

logmsg("Created constraint AAC3_TotalAnnualTechnologyActivityLowerLimit.")
# END: AAC3_TotalAnnualTechnologyActivityLowerLimit.

# BEGIN: TAC1_TotalModelHorizonTechnologyActivity.
constraintnum = 1  # Number of next constraint to be added to constraint array
@constraintref tac1_totalmodelhorizontechnologyactivity[1:length(sregion) * length(stechnology)]

for (r, t) in Base.product(sregion, stechnology)
    tac1_totalmodelhorizontechnologyactivity[constraintnum] = @constraint(model, sum([vtotaltechnologyannualactivity[r,t,y] for y = syear]) == vtotaltechnologymodelperiodactivity[r,t])
    constraintnum += 1
end

logmsg("Created constraint TAC1_TotalModelHorizonTechnologyActivity.")
# END: TAC1_TotalModelHorizonTechnologyActivity.

# BEGIN: TAC2_TotalModelHorizonTechnologyActivityUpperLimit.
constraintnum = 1  # Number of next constraint to be added to constraint array
@constraintref tac2_totalmodelhorizontechnologyactivityupperlimit[1:length(sregion) * length(stechnology)]

for row in eachrow(SQLite.query(db, "select r, t, cast(val as real) as mmx
from TotalTechnologyModelPeriodActivityUpperLimit_def
where val > 0"))
    local r = row[:r]
    local t = row[:t]

    tac2_totalmodelhorizontechnologyactivityupperlimit[constraintnum] = @constraint(model, vtotaltechnologymodelperiodactivity[r,t] <= row[:mmx])
    constraintnum += 1
end

logmsg("Created constraint TAC2_TotalModelHorizonTechnologyActivityUpperLimit.")
# END: TAC2_TotalModelHorizonTechnologyActivityUpperLimit.

# BEGIN: TAC3_TotalModelHorizenTechnologyActivityLowerLimit.
constraintnum = 1  # Number of next constraint to be added to constraint array
@constraintref tac3_totalmodelhorizentechnologyactivitylowerlimit[1:length(sregion) * length(stechnology)]

for row in eachrow(SQLite.query(db, "select r, t, cast(val as real) as mmn
from TotalTechnologyModelPeriodActivityLowerLimit_def
where val > 0"))
    local r = row[:r]
    local t = row[:t]

    tac3_totalmodelhorizentechnologyactivitylowerlimit[constraintnum] = @constraint(model, vtotaltechnologymodelperiodactivity[r,t] >= row[:mmn])
    constraintnum += 1
end

logmsg("Created constraint TAC3_TotalModelHorizenTechnologyActivityLowerLimit.")
# END: TAC3_TotalModelHorizenTechnologyActivityLowerLimit.

# BEGIN: RM1_ReserveMargin_TechnologiesIncluded_In_Activity_Units.
constraintnum = 1  # Number of next constraint to be added to constraint array
@constraintref rm1_reservemargin_technologiesincluded_in_activity_units[1:length(sregion) * length(syear)]

for row in eachrow(SQLite.query(db, "select r.val as r, y.val as y, group_concat(t.val || ';' || rmt.val || ';' || cau.val) as trca
from region r, year y, technology t, ReserveMarginTagTechnology_def rmt, CapacityToActivityUnit_def cau
where rmt.r = r.val and rmt.t = t.val and rmt.y = y.val
and cau.r = r.val and cau.t = t.val
group by r.val, y.val"))
    local r = row[:r]
    local y = row[:y]

    rm1_reservemargin_technologiesincluded_in_activity_units[constraintnum] = @constraint(model, sum([vtotalcapacityannual[r,split(trc,";")[1],y] * Meta.parse(split(trc,";")[2]) * Meta.parse(split(trc,";")[3]) for trc = split(row[:trca], ",")]) == vtotalcapacityinreservemargin[r,y])
    constraintnum += 1
end

logmsg("Created constraint RM1_ReserveMargin_TechnologiesIncluded_In_Activity_Units.")
# END: RM1_ReserveMargin_TechnologiesIncluded_In_Activity_Units.

# BEGIN: RM2_ReserveMargin_FuelsIncluded.
constraintnum = 1  # Number of next constraint to be added to constraint array
@constraintref rm2_reservemargin_fuelsincluded[1:length(sregion) * length(stimeslice) * length(syear)]

for row in eachrow(SQLite.query(db, "select r.val as r, l.val as l, y.val as y, group_concat(f.val || ';' || rmf.val) as fra
from region r, timeslice l, year y, fuel f, ReserveMarginTagFuel_def rmf
where rmf.r = r.val and rmf.f = f.val and rmf.y = y.val
group by r.val, l.val, y.val"))
    local r = row[:r]
    local l = row[:l]
    local y = row[:y]

    rm2_reservemargin_fuelsincluded[constraintnum] = @constraint(model, sum([vrateofproduction[r,l,split(fr,";")[1],y] * Meta.parse(split(fr,";")[2]) for fr = split(row[:fra], ",")]) == vdemandneedingreservemargin[r,l,y])
    constraintnum += 1
end

logmsg("Created constraint RM2_ReserveMargin_FuelsIncluded.")
# END: RM2_ReserveMargin_FuelsIncluded.

# BEGIN: RM3_ReserveMargin_Constraint.
constraintnum = 1  # Number of next constraint to be added to constraint array
@constraintref rm3_reservemargin_constraint[1:length(sregion) * length(stimeslice) * length(syear)]

for row in eachrow(SQLite.query(db, "select r.val as r, l.val as l, y.val as y, cast(rm.val as real) as rm
from region r, timeslice l, year y, ReserveMargin_def rm
where rm.r = r.val and rm.y = y.val"))
    local r = row[:r]
    local l = row[:l]
    local y = row[:y]

    rm3_reservemargin_constraint[constraintnum] = @constraint(model, vdemandneedingreservemargin[r,l,y] * row[:rm] <= vtotalcapacityinreservemargin[r,y])
    constraintnum += 1
end

logmsg("Created constraint RM3_ReserveMargin_Constraint.")
# END: RM3_ReserveMargin_Constraint.

# BEGIN: RE1_FuelProductionByTechnologyAnnual.
constraintnum = 1  # Number of next constraint to be added to constraint array
@constraintref re1_fuelproductionbytechnologyannual[1:size(queryproductionbytechnologyannual)[1]]

for row in eachrow(queryproductionbytechnologyannual)
    local r = row[:r]
    local t = row[:t]
    local f = row[:f]
    local y = row[:y]

    re1_fuelproductionbytechnologyannual[constraintnum] = @constraint(model, sum([vproductionbytechnology[r,l,t,f,y] for l = split(row[:la], ",")]) == vproductionbytechnologyannual[r,t,f,y])
    constraintnum += 1
end

logmsg("Created constraint RE1_FuelProductionByTechnologyAnnual.")
# END: RE1_FuelProductionByTechnologyAnnual.

# BEGIN: RE2_TechIncluded.
constraintnum = 1  # Number of next constraint to be added to constraint array

@constraintref re2_techincluded[1:length(sregion) * length(syear)]

for row in eachrow(SQLite.query(db, "select r.val as r, y.val as y, group_concat(distinct t.val || ';' || f.val || ';' || ret.val) as tfa
from REGION r, TECHNOLOGY t, FUEL f, YEAR y, OutputActivityRatio_def oar, RETagTechnology_def ret
where oar.r = r.val and oar.t = t.val and oar.f = f.val and oar.y = y.val and oar.val <> 0
and ret.r = r.val and ret.t = t.val and ret.y = y.val and ret.val <> 0
group by r.val, y.val"))
    local r = row[:r]
    local y = row[:y]

    re2_techincluded[constraintnum] = @constraint(model, sum([vproductionbytechnologyannual[r,split(tf,";")[1],split(tf,";")[2],y] * Meta.parse(split(tf,";")[3]) for tf = split(row[:tfa], ",")]) == vtotalreproductionannual[r,y])
    constraintnum += 1
end

logmsg("Created constraint RE2_TechIncluded.")
# END: RE2_TechIncluded.

# BEGIN: RE3_FuelIncluded.
constraintnum = 1  # Number of next constraint to be added to constraint array

@constraintref re3_fuelincluded[1:length(sregion) * length(syear)]

for row in eachrow(SQLite.query(db, "select r.val as r, y.val as y, group_concat(l.val || ';' || f.val || ';' || ys.val || ';' || rtf.val) as lfa
from REGION r, YEAR y, TIMESLICE l, FUEL f, YearSplit_def ys, RETagFuel_def rtf
where ys.l = l.val and ys.y = y.val
and rtf.r = r.val and rtf.f = f.val and rtf.y = y.val and rtf.val <> 0
group by r.val, y.val"))
    local r = row[:r]
    local y = row[:y]

    re3_fuelincluded[constraintnum] = @constraint(model, sum([vrateofproduction[r,split(lf,";")[1],split(lf,";")[2],y] * Meta.parse(split(lf,";")[3]) * Meta.parse(split(lf,";")[4]) for lf = split(row[:lfa], ",")]) == vretotalproductionoftargetfuelannual[r,y])
    constraintnum += 1
end

logmsg("Created constraint RE3_FuelIncluded.")
# END: RE3_FuelIncluded.

# BEGIN: RE4_EnergyConstraint.
constraintnum = 1  # Number of next constraint to be added to constraint array

@constraintref re4_energyconstraint[1:length(sregion) * length(syear)]

for row in eachrow(SQLite.query(db, "select ry.r as r, ry.y as y, cast(rmp.val as real) as rmp
from
(select r.val as r, y.val as y
from REGION r, TECHNOLOGY t, FUEL f, YEAR y, OutputActivityRatio_def oar, RETagTechnology_def ret
where oar.r = r.val and oar.t = t.val and oar.f = f.val and oar.y = y.val and oar.val <> 0
and ret.r = r.val and ret.t = t.val and ret.y = y.val and ret.val <> 0
group by r.val, y.val
intersect
select r.val as r, y.val as y
from REGION r, YEAR y, TIMESLICE l, FUEL f, YearSplit_def ys, RETagFuel_def rtf
where ys.l = l.val and ys.y = y.val
and rtf.r = r.val and rtf.f = f.val and rtf.y = y.val and rtf.val <> 0
group by r.val, y.val) ry, REMinProductionTarget_def rmp
where rmp.r = ry.r and rmp.y = ry.y"))
    local r = row[:r]
    local y = row[:y]

    re4_energyconstraint[constraintnum] = @constraint(model, row[:rmp] * vretotalproductionoftargetfuelannual[r,y] <= vtotalreproductionannual[r,y])
    constraintnum += 1
end

logmsg("Created constraint RE4_EnergyConstraint.")
# END: RE4_EnergyConstraint.

# Omitting RE5_FuelUseByTechnologyAnnual because it's just an identity that's not used elsewhere in model

# BEGIN: E1_AnnualEmissionProductionByMode.
constraintnum = 1  # Number of next constraint to be added to constraint array

@constraintref e1_annualemissionproductionbymode[1:length(sregion) * length(stechnology) * length(semission) * length(smode_of_operation) * length(syear)]

for row in eachrow(SQLite.query(db, "select r, t, e, m, y, cast(val as real) as ear
from EmissionActivityRatio_def ear"))
    local r = row[:r]
    local t = row[:t]
    local e = row[:e]
    local m = row[:m]
    local y = row[:y]

    e1_annualemissionproductionbymode[constraintnum] = @constraint(model, row[:ear] * vtotalannualtechnologyactivitybymode[r,t,m,y] == vannualtechnologyemissionbymode[r,t,e,m,y])
    constraintnum += 1
end

logmsg("Created constraint E1_AnnualEmissionProductionByMode.")
# END: E1_AnnualEmissionProductionByMode.

# BEGIN: E2_AnnualEmissionProduction.
constraintnum = 1  # Number of next constraint to be added to constraint array

@constraintref e2_annualemissionproduction[1:length(sregion) * length(stechnology) * length(semission) * length(syear)]

for row in eachrow(SQLite.query(db, "select r, t, e, y, group_concat(m) as ma
from EmissionActivityRatio_def ear
group by r, t, e, y"))
    local r = row[:r]
    local t = row[:t]
    local e = row[:e]
    local y = row[:y]

    e2_annualemissionproduction[constraintnum] = @constraint(model, sum([vannualtechnologyemissionbymode[r,t,e,m,y] for m = split(row[:ma], ",")]) == vannualtechnologyemission[r,t,e,y])
    constraintnum += 1
end

logmsg("Created constraint E2_AnnualEmissionProduction.")
# END: E2_AnnualEmissionProduction.

# BEGIN: E3_EmissionsPenaltyByTechAndEmission.
constraintnum = 1  # Number of next constraint to be added to constraint array

@constraintref e3_emissionspenaltybytechandemission[1:length(sregion) * length(stechnology) * length(semission) * length(syear)]

for row in eachrow(SQLite.query(db, "select ear.r as r, ear.t as t, ear.e as e, ear.y as y, cast(ep.val as real) as ep
from EmissionActivityRatio_def ear, EmissionsPenalty_def ep
where ep.r = ear.r and ep.e = ear.e and ep.y = ear.y
group by ear.r, ear.t, ear.e, ear.y, ep.val"))
    local r = row[:r]
    local t = row[:t]
    local e = row[:e]
    local y = row[:y]

    e3_emissionspenaltybytechandemission[constraintnum] = @constraint(model, vannualtechnologyemission[r,t,e,y] * row[:ep] == vannualtechnologyemissionpenaltybyemission[r,t,e,y])
    constraintnum += 1
end

logmsg("Created constraint E3_EmissionsPenaltyByTechAndEmission.")
# END: E3_EmissionsPenaltyByTechAndEmission.

# BEGIN: E4_EmissionsPenaltyByTechnology.
constraintnum = 1  # Number of next constraint to be added to constraint array

@constraintref e4_emissionspenaltybytechnology[1:length(sregion) * length(stechnology) * length(syear)]

for row in eachrow(SQLite.query(db, "select ear.r as r, ear.t as t, ear.y as y, group_concat(distinct ear.e) as ea
from EmissionActivityRatio_def ear, EmissionsPenalty_def ep
where ep.r = ear.r and ep.e = ear.e and ep.y = ear.y
group by ear.r, ear.t, ear.y"))
    local r = row[:r]
    local t = row[:t]
    local y = row[:y]

    e4_emissionspenaltybytechnology[constraintnum] = @constraint(model, sum([vannualtechnologyemissionpenaltybyemission[r,t,e,y] for e = split(row[:ea], ",")]) == vannualtechnologyemissionspenalty[r,t,y])
    constraintnum += 1
end

logmsg("Created constraint E4_EmissionsPenaltyByTechnology.")
# END: E4_EmissionsPenaltyByTechnology.

# BEGIN: E5_DiscountedEmissionsPenaltyByTechnology.
constraintnum = 1  # Number of next constraint to be added to constraint array
@constraintref e5_discountedemissionspenaltybytechnology[1:size(queryrtydr)[1]]

for row in eachrow(queryrtydr)
    local r = row[:r]
    local t = row[:t]
    local y = row[:y]
    local dr = row[:dr]

    e5_discountedemissionspenaltybytechnology[constraintnum] = @constraint(model, vannualtechnologyemissionspenalty[r,t,y] / ((1 + dr)^(Meta.parse(y) - Meta.parse(first(syear)) + 0.5)) == vdiscountedtechnologyemissionspenalty[r,t,y])
    constraintnum += 1
end

logmsg("Created constraint E5_DiscountedEmissionsPenaltyByTechnology.")
# END: E5_DiscountedEmissionsPenaltyByTechnology.

# BEGIN: E6_EmissionsAccounting1.
constraintnum = 1  # Number of next constraint to be added to constraint array

@constraintref e6_emissionsaccounting1[1:length(sregion) * length(semission) * length(syear)]

for row in eachrow(SQLite.query(db, "select r, e, y, group_concat(distinct t) as ta
from EmissionActivityRatio_def ear
group by r, e, y"))
    local r = row[:r]
    local e = row[:e]
    local y = row[:y]

    e6_emissionsaccounting1[constraintnum] = @constraint(model, sum([vannualtechnologyemission[r,t,e,y] for t = split(row[:ta], ",")]) == vannualemissions[r,e,y])
    constraintnum += 1
end

logmsg("Created constraint E6_EmissionsAccounting1.")
# END: E6_EmissionsAccounting1.

# BEGIN: E7_EmissionsAccounting2.
constraintnum = 1  # Number of next constraint to be added to constraint array

@constraintref e7_emissionsaccounting2[1:length(sregion) * length(semission)]

for row in eachrow(SQLite.query(db, "select r.val as r, e.val as e, cast(mpe.val as real) as mpe
from region r, emission e
left join ModelPeriodExogenousEmission_def mpe on mpe.r = r.val and mpe.e = e.val"))
    local r = row[:r]
    local e = row[:e]
    local mpe = ismissing(row[:mpe]) ? 0 : row[:mpe]

    e7_emissionsaccounting2[constraintnum] = @constraint(model, sum([vannualemissions[r,e,y] for y = syear]) == vmodelperiodemissions[r,e] - mpe)
    constraintnum += 1
end

logmsg("Created constraint E7_EmissionsAccounting2.")
# END: E7_EmissionsAccounting2.

# BEGIN: E8_AnnualEmissionsLimit.
constraintnum = 1  # Number of next constraint to be added to constraint array

@constraintref e8_annualemissionslimit[1:length(sregion) * length(semission) * length(syear)]

for row in eachrow(SQLite.query(db, "select r.val as r, e.val as e, y.val as y, cast(aee.val as real) as aee, cast(ael.val as real) as ael
from region r, emission e, year y, AnnualEmissionLimit_def ael
left join AnnualExogenousEmission_def aee on aee.r = r.val and aee.e = e.val and aee.y = y.val
where ael.r = r.val and ael.e = e.val and ael.y = y.val"))
    local r = row[:r]
    local e = row[:e]
    local y = row[:y]
    local aee = ismissing(row[:aee]) ? 0 : row[:aee]

    e8_annualemissionslimit[constraintnum] = @constraint(model, vannualemissions[r,e,y] + aee <= row[:ael])
    constraintnum += 1
end

logmsg("Created constraint E8_AnnualEmissionsLimit.")
# END: E8_AnnualEmissionsLimit.

# BEGIN: E9_ModelPeriodEmissionsLimit.
constraintnum = 1  # Number of next constraint to be added to constraint array

@constraintref e9_modelperiodemissionslimit[1:length(sregion) * length(semission)]

for row in eachrow(SQLite.query(db, "select r.val as r, e.val as e, cast(mpl.val as real) as mpl
from region r, emission e, ModelPeriodEmissionLimit_def mpl
where mpl.r = r.val and mpl.e = e.val"))
    local r = row[:r]
    local e = row[:e]

    e9_modelperiodemissionslimit[constraintnum] = @constraint(model, vmodelperiodemissions[r,e] <= row[:mpl])
    constraintnum += 1
end

logmsg("Created constraint E9_ModelPeriodEmissionsLimit.")
# END: E9_ModelPeriodEmissionsLimit.

# END: Define OSeMOSYS constraints.

# BEGIN: Define model objective.
@objective(model, Min, sum([vtotaldiscountedcost[r,y] for r = sregion, y = syear]))
logmsg("Defined model objective.")
# END: Define model objective.

# Solve model
status::Symbol = solve(model)
solvedtm::DateTime = now()  # Date/time of last solve operation
solvedtmstr::String = Dates.format(solvedtm, "yyyy-mm-dd HH:MM:SS.sss")  # solvedtm as a formatted string
logmsg("Solved model.", solvedtm)

# BEGIN: Save results to database.
savevarresults(String.(split(replace(varstosave, " " => ""), ","; keepempty = false)), modelvarindices, db, solvedtmstr)
logmsg("Finished saving results to database.")
# END: Save results to database.

logmsg("Finished scenario calculation.")
end  # calculatescenario()

"""Runs NEMO for a scenario specified in a GNU MathProg data file. Saves results in a NEMO-compatible SQLite database in same
    directory as GNU MathProg data file. Arguments:
    • gmpdatapath - Path to GNU MathProg data file.
    • solver - Name of solver to be used (currently, GLPK or CPLEX).
    • gmpmodelpath - Path to GNU MathProg model file corresponding to data file.
    • varstosave - Comma-delimited list of model variables whose results should be saved in SQLite database.
    • targetprocs - Processes that should be used for parallelized operations within this function."""
function calculategmpscenario(
    gmpdatapath::String,
    solver::String,
    gmpmodelpath::String = normpath(joinpath(@__DIR__, "..", "utils", "gmpl2sql", "osemosys_2017_11_08_long.txt")),
    varstosave::String = "vdemand, vnewstoragecapacity, vaccumulatednewstoragecapacity, vstorageupperlimit, vstoragelowerlimit, vcapitalinvestmentstorage, vdiscountedcapitalinvestmentstorage, vsalvagevaluestorage, vdiscountedsalvagevaluestorage, vnewcapacity, vaccumulatednewcapacity, vtotalcapacityannual, vtotaltechnologyannualactivity, vtotalannualtechnologyactivitybymode, vproductionbytechnologyannual, vproduction, vusebytechnologyannual, vuse, vtrade, vtradeannual, vproductionannual, vuseannual, vcapitalinvestment, vdiscountedcapitalinvestment, vsalvagevalue, vdiscountedsalvagevalue, voperatingcost, vdiscountedoperatingcost, vtotaldiscountedcost",
    targetprocs::Array{Int, 1} = Array{Int, 1}([1]))

    logmsg("Started conversion of MathProg data file.")

    # BEGIN: Validate arguments.
    if !ispath(gmpdatapath)
        error("gmpdatapath must refer to a valid file system path.")
    end

    if !ispath(gmpmodelpath)
        error("gmpmodelpath must refer to a valid file system path.")
    end

    logmsg("Validated run-time arguments.")
    # END: Validate arguments.

    # BEGIN: Convert data file into NEMO SQLite database.
    local gmp2sqlprog::String = normpath(joinpath(@__DIR__, "..", "utils", "gmpl2sql", "gmpl2sql.exe"))  # Full path to gmp2sql.exe
    run(`$gmp2sqlprog -d $gmpdatapath -m $gmpmodelpath`)
    # END: Convert data file into NEMO SQLite database.

    logmsg("Finished conversion of MathProg data file.")

    # Call calculatescenario()
    calculatescenario(splitext(gmpdatapath)[1] * ".sl3", solver, varstosave, targetprocs)
end  # calculategmpscenario()
