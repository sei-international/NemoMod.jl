#=
    |nemo: Next-generation Energy Modeling system for Optimization.
    https://github.com/sei-international/NemoMod.jl

    Copyright © 2018: Stockholm Environment Institute U.S.

    File description: Functions for calculating a |nemo scenario.
=#

"""
    calculatescenario(dbpath; jumpmodel = Model(solver = GLPKSolverMIP(presolve=true)),
    varstosave = "vdemand, vnewstoragecapacity, vaccumulatednewstoragecapacity,
        vstorageupperlimit, vstoragelowerlimit, vcapitalinvestmentstorage,
        vdiscountedcapitalinvestmentstorage, vsalvagevaluestorage,
        vdiscountedsalvagevaluestorage, vnewcapacity, vaccumulatednewcapacity,
        vtotalcapacityannual, vtotaltechnologyannualactivity,
        vtotalannualtechnologyactivitybymode, vproductionbytechnologyannual,
        vproduction, vusebytechnologyannual, vusenn, vtrade, vtradeannual,
        vproductionannual, vuseannual, vcapitalinvestment,
        vdiscountedcapitalinvestment, vsalvagevalue, vdiscountedsalvagevalue,
        voperatingcost, vdiscountedoperatingcost, vtotaldiscountedcost",
    targetprocs = Array{Int, 1}([1]), restrictvars = false,
    reportzeros = false, quiet = false)

Runs |nemo for a scenario specified in a SQLite database. Returns a Symbol indicating
the solve status reported by the solver.

# Arguments
- `dbpath::String`: Path to SQLite database.
- `jumpmodel::JuMP.Model`: JuMP model object specifying MIP solver to be used.
    Examples: Model(solver = GLPKSolverMIP(presolve=true)), Model(solver = CplexSolver()),
    Model(solver = CbcSolver(logLevel=1, presolve="on")).
    Note that solver package must be installed (GLPK and Cbc are installed with |nemo by
    default).
- `varstosave::String`: Comma-delimited list of model variables whose results should be
    saved in the SQLite database.
- `targetprocs::Array{Int, 1}`: Processes that should be used for parallelized operations
    within the scenario calculation.
- `restrictvars::Bool`: Indicates whether |nemo should conduct additional data analysis
    to limit the set of model variables created. This option avoids creating variables
    for combinations of subscripts that do not exist in the scenario's data. It is
    generally only needed for very large models, in which case it can save substantial
    processing time (in other cases it can add processing time). It is usually used with
    multiple `targetprocs`.
- `reportzeros::Bool`: Indicates whether results saved in the SQLite database should include
    values equal to zero. Specifying `false` can substantially improve the performance
    of large models.
- `quiet::Bool`: Suppresses low-priority status messages (which are otherwise printed to
    STDOUT).

!!! tip
For small models, performance may be improved by turning off the solver's presolve function. For
example, `jumpmodel = Model(solver = GLPKSolverMIP(presolve=false))` or
`jumpmodel = Model(solver = CbcSolver(logLevel=1, presolve="off"))`.
"""
function calculatescenario(
    dbpath::String;
    jumpmodel::JuMP.Model = Model(solver = GLPKSolverMIP(presolve=true)),
    varstosave::String = "vdemand, vnewstoragecapacity, vaccumulatednewstoragecapacity, vstorageupperlimit, vstoragelowerlimit, vcapitalinvestmentstorage, "
    * "vdiscountedcapitalinvestmentstorage, vsalvagevaluestorage, vdiscountedsalvagevaluestorage, vnewcapacity, vaccumulatednewcapacity, vtotalcapacityannual, "
    * "vtotaltechnologyannualactivity, vtotalannualtechnologyactivitybymode, vproductionbytechnologyannual, vproduction, vusebytechnologyannual, vusenn, vtrade, "
    * "vtradeannual, vproductionannual, vuseannual, vcapitalinvestment, vdiscountedcapitalinvestment, vsalvagevalue, vdiscountedsalvagevalue, voperatingcost, "
    * "vdiscountedoperatingcost, vtotaldiscountedcost",
    targetprocs::Array{Int, 1} = Array{Int, 1}([1]),
    restrictvars::Bool = false,
    reportzeros::Bool = false,
    quiet::Bool = false)
# Lines within calculatescenario() are not indented since the function is so lengthy. To make an otherwise local
# variable visible outside the function, prefix it with global. For JuMP constraint references,
# create a new global variable and assign to it the constraint reference.

logmsg("Started scenario calculation.")

# BEGIN: Read config file.
configfile = getconfig(quiet)  # ConfParse structure for config file if one is found; otherwise nothing
# END: Read config file.

# BEGIN: Perform beforescenariocalc include.
if configfile != nothing && haskey(configfile, "includes", "beforescenariocalc")
    try
        include(normpath(joinpath(pwd(), retrieve(configfile, "includes", "beforescenariocalc"))))
        logmsg("Performed beforescenariocalc include.", quiet)
    catch e
        logmsg("Could not perform beforescenariocalc include. Error message: " * sprint(showerror, e) * ". Continuing with |nemo.", quiet)
    end
end
# END: Perform beforescenariocalc include.

# BEGIN: Validate arguments.
if !isfile(dbpath)
    error("dbpath argument must refer to a file.")
end

# Convert varstosave into an array of strings with no empty values
local varstosavearr = String.(split(replace(varstosave, " " => ""), ","; keepempty = false))

logmsg("Validated run-time arguments.", quiet)
# END: Validate arguments.

# BEGIN: Connect to SQLite database.
db = SQLite.DB(dbpath)
logmsg("Connected to scenario database. Path = " * dbpath * ".", quiet)
# END: Connect to SQLite database.

# BEGIN: Drop any pre-existing result tables.
dropresulttables(db, true)
logmsg("Dropped pre-existing result tables from database.", quiet)
# END: Drop any pre-existing result tables.

# BEGIN: Temporary - Add transmission data.
addtransmissiondata(db; quiet = quiet)
# END: Temporary - Add transmission data.

# BEGIN: Check if transmission modeling is required.
local transmissionmodeling::Bool = false  # Indicates whether scenario involves transmission modeling
local transmissionmodelingtypes::Array{Int64, 1} =
    collect(skipmissing(SQLite.query(db, "select distinct type from TransmissionModelingEnabled")[:type]))
    # Array of transmission modeling types requested for scenario

if length(transmissionmodelingtypes) > 0
    transmissionmodeling = true
end

# Temporary - save transmission variables if transmission modeling is enabled
transmissionmodeling && push!(varstosavearr, "vtransmissionbuilt", "vtransmissionexists", "vtransmissionbyline")

logmsg("Verified that transmission modeling " * (transmissionmodeling ? "is" : "is not") * " enabled.", quiet)
# END: Check if transmission modeling is required.

# BEGIN: Create parameter views showing default values.
# Array of parameter tables needing default views in scenario database
local paramsneedingdefs::Array{String, 1} = ["OutputActivityRatio", "InputActivityRatio", "ResidualCapacity", "OperationalLife",
"FixedCost", "YearSplit", "SpecifiedAnnualDemand", "SpecifiedDemandProfile", "VariableCost", "DiscountRate", "CapitalCost",
"CapitalCostStorage", "CapacityFactor", "CapacityToActivityUnit", "CapacityOfOneTechnologyUnit", "AvailabilityFactor",
"TradeRoute", "TechnologyToStorage", "TechnologyFromStorage", "StorageLevelStart", "StorageMaxChargeRate", "StorageMaxDischargeRate",
"ResidualStorageCapacity", "MinStorageCharge", "OperationalLifeStorage", "DepreciationMethod", "TotalAnnualMaxCapacity",
"TotalAnnualMinCapacity", "TotalAnnualMaxCapacityInvestment", "TotalAnnualMinCapacityInvestment",
"TotalTechnologyAnnualActivityUpperLimit", "TotalTechnologyAnnualActivityLowerLimit", "TotalTechnologyModelPeriodActivityUpperLimit",
"TotalTechnologyModelPeriodActivityLowerLimit", "ReserveMarginTagTechnology", "ReserveMarginTagFuel", "ReserveMargin", "RETagTechnology", "RETagFuel",
"REMinProductionTarget", "EmissionActivityRatio", "EmissionsPenalty", "ModelPeriodExogenousEmission",
"AnnualExogenousEmission", "AnnualEmissionLimit", "ModelPeriodEmissionLimit", "AccumulatedAnnualDemand", "TotalAnnualMaxCapacityStorage",
"TotalAnnualMinCapacityStorage", "TotalAnnualMaxCapacityInvestmentStorage", "TotalAnnualMinCapacityInvestmentStorage"]

append!(paramsneedingdefs, ["NodalDistributionDemand", "NodalDistributionTechnologyCapacity", "NodalDistributionStorageCapacity"])

createviewwithdefaults(db, paramsneedingdefs)

logmsg("Created parameter views.", quiet)
# END: Create parameter views showing default values.

# BEGIN: Define sets.
syear::Array{String,1} = collect(skipmissing(SQLite.query(db, "select val from YEAR order by val")[:val]))  # YEAR set
stechnology::Array{String,1} = collect(skipmissing(SQLite.query(db, "select val from TECHNOLOGY")[:val]))  # TECHNOLOGY set
stimeslice::Array{String,1} = collect(skipmissing(SQLite.query(db, "select val from TIMESLICE")[:val]))  # TIMESLICE set
sfuel::Array{String,1} = collect(skipmissing(SQLite.query(db, "select val from FUEL")[:val]))  # FUEL set
semission::Array{String,1} = collect(skipmissing(SQLite.query(db, "select val from EMISSION")[:val]))  # EMISSION set
smode_of_operation::Array{String,1} = collect(skipmissing(SQLite.query(db, "select val from MODE_OF_OPERATION")[:val]))  # MODE_OF_OPERATION set
sregion::Array{String,1} = collect(skipmissing(SQLite.query(db, "select val from REGION")[:val]))  # REGION set
sstorage::Array{String,1} = collect(skipmissing(SQLite.query(db, "select val from STORAGE")[:val]))  # STORAGE set
stsgroup1::Array{String,1} = collect(skipmissing(SQLite.query(db, "select name from TSGROUP1")[:name]))  # Time slice group 1 set
stsgroup2::Array{String,1} = collect(skipmissing(SQLite.query(db, "select name from TSGROUP2")[:name]))  # Time slice group 2 set

if transmissionmodeling
    snode::Array{String,1} = collect(skipmissing(SQLite.query(db, "select val from NODE")[:val]))  # Node set
    stransmission::Array{String,1} = collect(skipmissing(SQLite.query(db, "select id from TransmissionLine")[:id]))  # Transmission line set
end

tsgroup1dict::Dict{Int, Tuple{String, Float64}} = Dict{Int, Tuple{String, Float64}}(row[:order] => (row[:name], row[:multiplier]) for row in
    DataFrames.eachrow(SQLite.query(db, "select [order], name, cast (multiplier as real) as multiplier from tsgroup1 order by [order]")))
    # For TSGROUP1, a dictionary mapping orders to tuples of (name, multiplier)
tsgroup2dict::Dict{Int, Tuple{String, Float64}} = Dict{Int, Tuple{String, Float64}}(row[:order] => (row[:name], row[:multiplier]) for row in
    DataFrames.eachrow(SQLite.query(db, "select [order], name, cast (multiplier as real) as multiplier from tsgroup2 order by [order]")))
    # For TSGROUP2, a dictionary mapping orders to tuples of (name, multiplier)
ltsgroupdict::Dict{Tuple{Int, Int, Int}, String} = Dict{Tuple{Int, Int, Int}, String}((row[:tg1o], row[:tg2o], row[:lo]) => row[:l] for row in
    DataFrames.eachrow(SQLite.query(db, "select ltg.l as l, ltg.lorder as lo, ltg.tg2, tg2.[order] as tg2o, ltg.tg1, tg1.[order] as tg1o
    from LTsGroup ltg, TSGROUP2 tg2, TSGROUP1 tg1
    where
    ltg.tg2 = tg2.name
    and ltg.tg1 = tg1.name")))  # Dictionary of LTsGroup table mapping tuples of (tsgroup1 order, tsgroup2 order, time slice order) to time slice names

logmsg("Defined sets.", quiet)
# END: Define sets.

# BEGIN: Define model variables.
modelvarindices::Dict{String, Tuple{JuMP.JuMPContainer,Array{String,1}}} = Dict{String, Tuple{JuMP.JuMPContainer,Array{String,1}}}()
# Dictionary mapping model variable names to tuples of (variable, [index column names]); must have an entry here in order to save
#   variable's results back to database

# Demands
@variable(jumpmodel, vdemandnn[sregion, stimeslice, sfuel, syear] >= 0)
modelvarindices["vdemandnn"] = (vdemandnn, ["r","l","f","y"])

if in("vrateofdemandnn", varstosavearr)
    @variable(jumpmodel, vrateofdemandnn[sregion, stimeslice, sfuel, syear] >= 0)
    modelvarindices["vrateofdemandnn"] = (vrateofdemandnn, ["r","l","f","y"])
end

logmsg("Defined demand variables.", quiet)

# Storage
@variable(jumpmodel, vstorageleveltsgroup1start[sregion, sstorage, stsgroup1, syear] >= 0)
@variable(jumpmodel, vstorageleveltsgroup1end[sregion, sstorage, stsgroup1, syear] >= 0)
@variable(jumpmodel, vstorageleveltsgroup2start[sregion, sstorage, stsgroup1, stsgroup2, syear] >= 0)
@variable(jumpmodel, vstorageleveltsgroup2end[sregion, sstorage, stsgroup1, stsgroup2, syear] >= 0)
@variable(jumpmodel, vstorageleveltsend[sregion, sstorage, stimeslice, syear] >= 0)  # Storage level at end of first hour in time slice
@variable(jumpmodel, vstoragelevelyearend[sregion, sstorage, syear] >= 0)
@variable(jumpmodel, vrateofstoragecharge[sregion, sstorage, stimeslice, syear] >= 0)
@variable(jumpmodel, vrateofstoragedischarge[sregion, sstorage, stimeslice, syear] >= 0)
@variable(jumpmodel, vstoragelowerlimit[sregion, sstorage, syear] >= 0)
@variable(jumpmodel, vstorageupperlimit[sregion, sstorage, syear] >= 0)
@variable(jumpmodel, vaccumulatednewstoragecapacity[sregion, sstorage, syear] >= 0)
@variable(jumpmodel, vnewstoragecapacity[sregion, sstorage, syear] >= 0)
@variable(jumpmodel, vcapitalinvestmentstorage[sregion, sstorage, syear] >= 0)
@variable(jumpmodel, vdiscountedcapitalinvestmentstorage[sregion, sstorage, syear] >= 0)
@variable(jumpmodel, vsalvagevaluestorage[sregion, sstorage, syear] >= 0)
@variable(jumpmodel, vdiscountedsalvagevaluestorage[sregion, sstorage, syear] >= 0)
@variable(jumpmodel, vtotaldiscountedstoragecost[sregion, sstorage, syear] >= 0)

modelvarindices["vstorageleveltsgroup1start"] = (vstorageleveltsgroup1start, ["r", "s", "tg1", "y"])
modelvarindices["vstorageleveltsgroup1end"] = (vstorageleveltsgroup1end, ["r", "s", "tg1", "y"])
modelvarindices["vstorageleveltsgroup2start"] = (vstorageleveltsgroup2start, ["r", "s", "tg1", "tg2", "y"])
modelvarindices["vstorageleveltsgroup2end"] = (vstorageleveltsgroup2end, ["r", "s", "tg1", "tg2", "y"])
modelvarindices["vstorageleveltsend"] = (vstorageleveltsend, ["r", "s", "l", "y"])
modelvarindices["vstoragelevelyearend"] = (vstoragelevelyearend, ["r", "s", "y"])
modelvarindices["vrateofstoragecharge"] = (vrateofstoragecharge, ["r", "s", "l", "y"])
modelvarindices["vrateofstoragedischarge"] = (vrateofstoragedischarge, ["r", "s", "l", "y"])
modelvarindices["vstoragelowerlimit"] = (vstoragelowerlimit, ["r", "s", "y"])
modelvarindices["vstorageupperlimit"] = (vstorageupperlimit, ["r", "s", "y"])
modelvarindices["vaccumulatednewstoragecapacity"] = (vaccumulatednewstoragecapacity, ["r", "s", "y"])
modelvarindices["vnewstoragecapacity"] = (vnewstoragecapacity, ["r", "s", "y"])
modelvarindices["vcapitalinvestmentstorage"] = (vcapitalinvestmentstorage, ["r", "s", "y"])
modelvarindices["vdiscountedcapitalinvestmentstorage"] = (vdiscountedcapitalinvestmentstorage, ["r", "s", "y"])
modelvarindices["vsalvagevaluestorage"] = (vsalvagevaluestorage, ["r", "s", "y"])
modelvarindices["vdiscountedsalvagevaluestorage"] = (vdiscountedsalvagevaluestorage, ["r", "s", "y"])
modelvarindices["vtotaldiscountedstoragecost"] = (vtotaldiscountedstoragecost, ["r", "s", "y"])
logmsg("Defined storage variables.", quiet)

# Capacity
@variable(jumpmodel, vnumberofnewtechnologyunits[sregion, stechnology, syear] >= 0, Int)
modelvarindices["vnumberofnewtechnologyunits"] = (vnumberofnewtechnologyunits, ["r", "t", "y"])
@variable(jumpmodel, vnewcapacity[sregion, stechnology, syear] >= 0)
modelvarindices["vnewcapacity"] = (vnewcapacity, ["r", "t", "y"])
@variable(jumpmodel, vaccumulatednewcapacity[sregion, stechnology, syear] >= 0)
modelvarindices["vaccumulatednewcapacity"] = (vaccumulatednewcapacity, ["r", "t", "y"])
@variable(jumpmodel, vtotalcapacityannual[sregion, stechnology, syear] >= 0)
modelvarindices["vtotalcapacityannual"] = (vtotalcapacityannual, ["r", "t", "y"])
logmsg("Defined capacity variables.", quiet)

# Activity
# First, perform some checks to see which variables are needed
local annualactivityupperlimits::Bool
# Indicates whether constraints for TotalTechnologyAnnualActivityUpperLimit should be added to model
local modelperiodactivityupperlimits::Bool
# Indicates whether constraints for TotalTechnologyModelPeriodActivityUpperLimit should be added to model

(annualactivityupperlimits, modelperiodactivityupperlimits) = checkactivityupperlimits(db, 10000.0)

local annualactivitylowerlimits::Bool = true
# Indicates whether constraints for TotalTechnologyAnnualActivityLowerLimit should be added to model
local modelperiodactivitylowerlimits::Bool = true
# Indicates whether constraints for TotalTechnologyModelPeriodActivityLowerLimit should be added to model

queryannualactivitylowerlimit::DataFrames.DataFrame = SQLite.query(db,
"select r, t, y, cast(val as real) as amn
from TotalTechnologyAnnualActivityLowerLimit_def
where val > 0")

if size(queryannualactivitylowerlimit)[1] == 0
    annualactivitylowerlimits = false
end

querymodelperiodactivitylowerlimit::DataFrames.DataFrame = SQLite.query(db,
"select r, t, cast(val as real) as mmn
from TotalTechnologyModelPeriodActivityLowerLimit_def
where val > 0")

if size(querymodelperiodactivitylowerlimit)[1] == 0
    modelperiodactivitylowerlimits = false
end

@variable(jumpmodel, vrateofactivity[sregion, stimeslice, stechnology, smode_of_operation, syear] >= 0)
modelvarindices["vrateofactivity"] = (vrateofactivity, ["r", "l", "t", "m", "y"])
@variable(jumpmodel, vrateoftotalactivity[sregion, stechnology, stimeslice, syear] >= 0)
modelvarindices["vrateoftotalactivity"] = (vrateoftotalactivity, ["r", "t", "l", "y"])

if (annualactivityupperlimits || annualactivitylowerlimits || modelperiodactivityupperlimits || modelperiodactivitylowerlimits
    || in("vtotaltechnologyannualactivity", varstosavearr))

    @variable(jumpmodel, vtotaltechnologyannualactivity[sregion, stechnology, syear] >= 0)
    modelvarindices["vtotaltechnologyannualactivity"] = (vtotaltechnologyannualactivity, ["r", "t", "y"])
end

@variable(jumpmodel, vtotalannualtechnologyactivitybymode[sregion, stechnology, smode_of_operation, syear] >= 0)
modelvarindices["vtotalannualtechnologyactivitybymode"] = (vtotalannualtechnologyactivitybymode, ["r", "t", "m", "y"])

if modelperiodactivityupperlimits || modelperiodactivitylowerlimits || in("vtotaltechnologymodelperiodactivity", varstosavearr)
    @variable(jumpmodel, vtotaltechnologymodelperiodactivity[sregion, stechnology])
    modelvarindices["vtotaltechnologymodelperiodactivity"] = (vtotaltechnologymodelperiodactivity, ["r", "t"])
end

queryvrateofproductionbytechnologybymodenn::DataFrames.DataFrame = SQLite.query(db,
"select r.val as r, ys.l as l, t.val as t, m.val as m, f.val as f, y.val as y,
cast(oar.val as real) as oar
from region r, YearSplit_def ys, technology t, MODE_OF_OPERATION m, fuel f, year y, OutputActivityRatio_def oar
left join TransmissionModelingEnabled tme on tme.r = r.val and tme.f = f.val and tme.y = y.val
where oar.r = r.val and oar.t = t.val and oar.f = f.val and oar.m = m.val and oar.y = y.val
and oar.val <> 0
and ys.y = y.val
and tme.id is null
order by r.val, ys.l, t.val, f.val, y.val")

# ys included because it's needed for some later constraints based on this query
queryvrateofproductionbytechnologynn::DataFrames.DataFrame = SQLite.query(db,
"select r.val as r, ys.l as l, t.val as t, f.val as f, y.val as y, cast(ys.val as real) as ys
from region r, YearSplit_def ys, technology t, fuel f, year y,
(select distinct r, t, f, y
from OutputActivityRatio_def
where val <> 0) oar
left join TransmissionModelingEnabled tme on tme.r = r.val and tme.f = f.val and tme.y = y.val
where oar.r = r.val and oar.t = t.val and oar.f = f.val and oar.y = y.val
and ys.y = y.val
and tme.id is null
order by r.val, ys.l, f.val, y.val")

if in("vproductionbytechnology", varstosavearr)
    # Overall query showing indices of vproductionbytechnology; nodal contributions will be added later if needed
    queryvproductionbytechnologyindices::DataFrames.DataFrame = queryvrateofproductionbytechnologynn
end

# ys included because it's needed for some later constraints based on this query
queryvproductionbytechnologyannual::DataFrames.DataFrame = SQLite.query(db,
"select * from (
select r.val as r, t.val as t, f.val as f, y.val as y, null as n, ys.l as l,
cast(ys.val as real) as ys
from region r, technology t, fuel f, year y, YearSplit_def ys,
(select distinct r, t, f, y
from OutputActivityRatio_def
where val <> 0) oar
left join TransmissionModelingEnabled tme on tme.r = r.val and tme.f = f.val and tme.y = y.val
where oar.r = r.val and oar.t = t.val and oar.f = f.val and oar.y = y.val
and ys.y = y.val
and tme.id is null
union all
select n.r as r, ntc.t as t, oar.f as f, ntc.y as y, ntc.n as n, ys.l as l,
cast(ys.val as real) as ys
from NodalDistributionTechnologyCapacity_def ntc, NODE n,
TransmissionModelingEnabled tme, YearSplit_def ys,
(select distinct r, t, f, y
from OutputActivityRatio_def
where val <> 0) oar
where ntc.val > 0
and ntc.n = n.val
and tme.r = n.r and tme.f = oar.f and tme.y = ntc.y
and oar.r = n.r and oar.t = ntc.t and oar.y = ntc.y
and ntc.y = ys.y
)
order by r, t, f, y")

if restrictvars
    if in("vrateofproductionbytechnologybymodenn", varstosavearr)
        indexdicts = keydicts_parallel(queryvrateofproductionbytechnologybymodenn, 5, targetprocs)  # Array of Dicts used to restrict indices of following variable
        @variable(jumpmodel, vrateofproductionbytechnologybymodenn[r=[k[1] for k = keys(indexdicts[1])], l=indexdicts[1][[r]], t=indexdicts[2][[r,l]],
            m=indexdicts[3][[r,l,t]], f=indexdicts[4][[r,l,t,m]], y=indexdicts[5][[r,l,t,m,f]]] >= 0)
    end

    indexdicts = keydicts_parallel(queryvrateofproductionbytechnologynn, 4, targetprocs)  # Array of Dicts used to restrict indices of following variable
    @variable(jumpmodel, vrateofproductionbytechnologynn[r=[k[1] for k = keys(indexdicts[1])], l=indexdicts[1][[r]], t=indexdicts[2][[r,l]],
        f=indexdicts[3][[r,l,t]], y=indexdicts[4][[r,l,t,f]]] >= 0)

    indexdicts = keydicts_parallel(queryvproductionbytechnologyannual, 3, targetprocs)  # Array of Dicts used to restrict indices of vproductionbytechnologyannual
    @variable(jumpmodel, vproductionbytechnologyannual[r=[k[1] for k = keys(indexdicts[1])], t=indexdicts[1][[r]], f=indexdicts[2][[r,t]],
        y=indexdicts[3][[r,t,f]]] >= 0)
else
    in("vrateofproductionbytechnologybymodenn", varstosavearr) &&
        @variable(jumpmodel, vrateofproductionbytechnologybymodenn[sregion, stimeslice, stechnology, smode_of_operation, sfuel, syear] >= 0)
    @variable(jumpmodel, vrateofproductionbytechnologynn[sregion, stimeslice, stechnology, sfuel, syear] >= 0)
    @variable(jumpmodel, vproductionbytechnologyannual[sregion, stechnology, sfuel, syear] >= 0)
end

if in("vrateofproductionbytechnologybymodenn", varstosavearr)
    modelvarindices["vrateofproductionbytechnologybymodenn"] = (vrateofproductionbytechnologybymodenn, ["r", "l", "t", "m", "f", "y"])
end

modelvarindices["vrateofproductionbytechnologynn"] = (vrateofproductionbytechnologynn, ["r","l","t","f","y"])
modelvarindices["vproductionbytechnologyannual"] = (vproductionbytechnologyannual, ["r","t","f","y"])

@variable(jumpmodel, vrateofproduction[sregion, stimeslice, sfuel, syear] >= 0)
modelvarindices["vrateofproduction"] = (vrateofproduction, ["r", "l", "f", "y"])
@variable(jumpmodel, vrateofproductionnn[sregion, stimeslice, sfuel, syear] >= 0)
modelvarindices["vrateofproductionnn"] = (vrateofproductionnn, ["r", "l", "f", "y"])
@variable(jumpmodel, vproductionnn[sregion, stimeslice, sfuel, syear] >= 0)
modelvarindices["vproductionnn"] = (vproductionnn, ["r","l","f","y"])

queryvrateofusebytechnologybymodenn::DataFrames.DataFrame = SQLite.query(db,
"select r.val as r, ys.l as l, t.val as t, m.val as m, f.val as f, y.val as y, cast(iar.val as real) as iar
from region r, YearSplit_def ys, technology t, MODE_OF_OPERATION m, fuel f, year y, InputActivityRatio_def iar
left join TransmissionModelingEnabled tme on tme.r = r.val and tme.f = f.val and tme.y = y.val
where iar.r = r.val and iar.t = t.val and iar.f = f.val and iar.m = m.val and iar.y = y.val
and iar.val <> 0
and ys.y = y.val
and tme.id is null
order by r.val, ys.l, t.val, f.val, y.val")

# ys included because it's needed for some later constraints based on this query
queryvrateofusebytechnologynn::DataFrames.DataFrame = SQLite.query(db, "select
r.val as r, ys.l as l, t.val as t, f.val as f, y.val as y, cast(ys.val as real) as ys
from region r, YearSplit_def ys, technology t, fuel f, year y,
(select distinct r, t, f, y from InputActivityRatio_def where val <> 0) iar
left join TransmissionModelingEnabled tme on tme.r = r.val and tme.f = f.val and tme.y = y.val
where iar.r = r.val and iar.t = t.val and iar.f = f.val and iar.y = y.val
and ys.y = y.val
and tme.id is null
order by r.val, ys.l, f.val, y.val")

if in("vusebytechnology", varstosavearr)
    # Overall query showing indices of vusebytechnology; nodal contributions will be added later if needed
    queryvusebytechnologyindices::DataFrames.DataFrame = queryvrateofusebytechnologynn
end

# ys included because it's needed for some later constraints based on this query
queryvusebytechnologyannual::DataFrames.DataFrame = SQLite.query(db,
"select * from (
select r.val as r, t.val as t, f.val as f, y.val as y, null as n, ys.l as l,
cast(ys.val as real) as ys
from region r, technology t, fuel f, year y, YearSplit_def ys,
(select distinct r, t, f, y from InputActivityRatio_def where val <> 0) iar
left join TransmissionModelingEnabled tme on tme.r = r.val and tme.f = f.val and tme.y = y.val
where iar.r = r.val and iar.t = t.val and iar.f = f.val and iar.y = y.val
and ys.y = y.val
and tme.id is null
union all
select n.r as r, ntc.t as t, iar.f as f, ntc.y as y, ntc.n as n, ys.l as l,
cast(ys.val as real) as ys
from NodalDistributionTechnologyCapacity_def ntc, NODE n,
TransmissionModelingEnabled tme, YearSplit_def ys,
(select distinct r, t, f, y from InputActivityRatio_def where val <> 0) iar
where ntc.val > 0
and ntc.n = n.val
and tme.r = n.r and tme.f = iar.f and tme.y = ntc.y
and iar.r = n.r and iar.t = ntc.t and iar.y = ntc.y
and ntc.y = ys.y
)
order by r, t, f, y")

if restrictvars
    if in("vrateofusebytechnologybymodenn", varstosavearr)
        indexdicts = keydicts_parallel(queryvrateofusebytechnologybymodenn, 5, targetprocs)  # Array of Dicts used to restrict indices of following variable
        @variable(jumpmodel, vrateofusebytechnologybymodenn[r=[k[1] for k = keys(indexdicts[1])], l=indexdicts[1][[r]], t=indexdicts[2][[r,l]],
            m=indexdicts[3][[r,l,t]], f=indexdicts[4][[r,l,t,m]], y=indexdicts[5][[r,l,t,m,f]]] >= 0)
    end

    indexdicts = keydicts_parallel(queryvrateofusebytechnologynn, 4, targetprocs)  # Array of Dicts used to restrict indices of following variable
    @variable(jumpmodel, vrateofusebytechnologynn[r=[k[1] for k = keys(indexdicts[1])], l=indexdicts[1][[r]], t=indexdicts[2][[r,l]],
        f=indexdicts[3][[r,l,t]], y=indexdicts[4][[r,l,t,f]]] >= 0)

    indexdicts = keydicts_parallel(queryvusebytechnologyannual, 3, targetprocs)  # Array of Dicts used to restrict indices of vusebytechnologyannual
    @variable(jumpmodel, vusebytechnologyannual[r=[k[1] for k = keys(indexdicts[1])], t=indexdicts[1][[r]], f=indexdicts[2][[r,t]],
        y=indexdicts[3][[r,t,f]]] >= 0)
else
    in("vrateofusebytechnologybymodenn", varstosavearr) &&
        @variable(jumpmodel, vrateofusebytechnologybymodenn[sregion, stimeslice, stechnology, smode_of_operation, sfuel, syear] >= 0)
    @variable(jumpmodel, vrateofusebytechnologynn[sregion, stimeslice, stechnology, sfuel, syear] >= 0)
    @variable(jumpmodel, vusebytechnologyannual[sregion, stechnology, sfuel, syear] >= 0)
end

if in("vrateofusebytechnologybymodenn", varstosavearr)
    modelvarindices["vrateofusebytechnologybymodenn"] = (vrateofusebytechnologybymodenn, ["r", "l", "t", "m", "f", "y"])
end

modelvarindices["vrateofusebytechnologynn"] = (vrateofusebytechnologynn, ["r","l","t","f","y"])

modelvarindices["vusebytechnologyannual"] = (vusebytechnologyannual, ["r","t","f","y"])

@variable(jumpmodel, vrateofuse[sregion, stimeslice, sfuel, syear] >= 0)
modelvarindices["vrateofuse"] = (vrateofuse, ["r", "l", "f", "y"])
@variable(jumpmodel, vrateofusenn[sregion, stimeslice, sfuel, syear] >= 0)
modelvarindices["vrateofusenn"] = (vrateofusenn, ["r", "l", "f", "y"])
@variable(jumpmodel, vusenn[sregion, stimeslice, sfuel, syear] >= 0)
modelvarindices["vusenn"] = (vusenn, ["r", "l", "f", "y"])

@variable(jumpmodel, vtrade[sregion, sregion, stimeslice, sfuel, syear])
modelvarindices["vtrade"] = (vtrade, ["r", "rr", "l", "f", "y"])
@variable(jumpmodel, vtradeannual[sregion, sregion, sfuel, syear])
modelvarindices["vtradeannual"] = (vtradeannual, ["r", "rr", "f", "y"])
@variable(jumpmodel, vproductionannualnn[sregion, sfuel, syear] >= 0)
modelvarindices["vproductionannualnn"] = (vproductionannualnn, ["r", "f", "y"])
@variable(jumpmodel, vuseannualnn[sregion, sfuel, syear] >= 0)
modelvarindices["vuseannualnn"] = (vuseannualnn, ["r", "f", "y"])
logmsg("Defined activity variables.", quiet)

# Costing
@variable(jumpmodel, vcapitalinvestment[sregion, stechnology, syear] >= 0)
modelvarindices["vcapitalinvestment"] = (vcapitalinvestment, ["r", "t", "y"])
@variable(jumpmodel, vdiscountedcapitalinvestment[sregion, stechnology, syear] >= 0)
modelvarindices["vdiscountedcapitalinvestment"] = (vdiscountedcapitalinvestment, ["r", "t", "y"])
@variable(jumpmodel, vsalvagevalue[sregion, stechnology, syear] >= 0)
modelvarindices["vsalvagevalue"] = (vsalvagevalue, ["r", "t", "y"])
@variable(jumpmodel, vdiscountedsalvagevalue[sregion, stechnology, syear] >= 0)
modelvarindices["vdiscountedsalvagevalue"] = (vdiscountedsalvagevalue, ["r", "t", "y"])
@variable(jumpmodel, voperatingcost[sregion, stechnology, syear] >= 0)
modelvarindices["voperatingcost"] = (voperatingcost, ["r", "t", "y"])
@variable(jumpmodel, vdiscountedoperatingcost[sregion, stechnology, syear] >= 0)
modelvarindices["vdiscountedoperatingcost"] = (vdiscountedoperatingcost, ["r", "t", "y"])
@variable(jumpmodel, vannualvariableoperatingcost[sregion, stechnology, syear] >= 0)
modelvarindices["vannualvariableoperatingcost"] = (vannualvariableoperatingcost, ["r", "t", "y"])
@variable(jumpmodel, vannualfixedoperatingcost[sregion, stechnology, syear] >= 0)
modelvarindices["vannualfixedoperatingcost"] = (vannualfixedoperatingcost, ["r", "t", "y"])
@variable(jumpmodel, vtotaldiscountedcostbytechnology[sregion, stechnology, syear] >= 0)
modelvarindices["vtotaldiscountedcostbytechnology"] = (vtotaldiscountedcostbytechnology, ["r", "t", "y"])
@variable(jumpmodel, vtotaldiscountedcost[sregion, syear] >= 0)
modelvarindices["vtotaldiscountedcost"] = (vtotaldiscountedcost, ["r", "y"])

if in("vmodelperiodcostbyregion", varstosavearr)
    @variable(jumpmodel, vmodelperiodcostbyregion[sregion] >= 0)
    modelvarindices["vmodelperiodcostbyregion"] = (vmodelperiodcostbyregion, ["r"])
end

logmsg("Defined costing variables.", quiet)

# Reserve margin
@variable(jumpmodel, vtotalcapacityinreservemargin[sregion, syear] >= 0)
modelvarindices["vtotalcapacityinreservemargin"] = (vtotalcapacityinreservemargin, ["r", "y"])
@variable(jumpmodel, vdemandneedingreservemargin[sregion, stimeslice, syear] >= 0)
modelvarindices["vdemandneedingreservemargin"] = (vdemandneedingreservemargin, ["r", "l", "y"])

logmsg("Defined reserve margin variables.", quiet)

# RE target
@variable(jumpmodel, vtotalreproductionannual[sregion, syear])
@variable(jumpmodel, vretotalproductionoftargetfuelannual[sregion, syear])

modelvarindices["vtotalreproductionannual"] = (vtotalreproductionannual, ["r", "y"])
modelvarindices["vretotalproductionoftargetfuelannual"] = (vretotalproductionoftargetfuelannual, ["r", "y"])
logmsg("Defined renewable energy target variables.", quiet)

# Emissions
if in("vannualtechnologyemissionbymode", varstosavearr)
    @variable(jumpmodel, vannualtechnologyemissionbymode[sregion, stechnology, semission, smode_of_operation, syear] >= 0)
    modelvarindices["vannualtechnologyemissionbymode"] = (vannualtechnologyemissionbymode, ["r", "t", "e", "m", "y"])
end

@variable(jumpmodel, vannualtechnologyemission[sregion, stechnology, semission, syear] >= 0)
modelvarindices["vannualtechnologyemission"] = (vannualtechnologyemission, ["r", "t", "e", "y"])

if in("vannualtechnologyemissionpenaltybyemission", varstosavearr)
    @variable(jumpmodel, vannualtechnologyemissionpenaltybyemission[sregion, stechnology, semission, syear] >= 0)
    modelvarindices["vannualtechnologyemissionpenaltybyemission"] = (vannualtechnologyemissionpenaltybyemission, ["r", "t", "e", "y"])
end

@variable(jumpmodel, vannualtechnologyemissionspenalty[sregion, stechnology, syear] >= 0)
modelvarindices["vannualtechnologyemissionspenalty"] = (vannualtechnologyemissionspenalty, ["r", "t", "y"])
@variable(jumpmodel, vdiscountedtechnologyemissionspenalty[sregion, stechnology, syear] >= 0)
modelvarindices["vdiscountedtechnologyemissionspenalty"] = (vdiscountedtechnologyemissionspenalty, ["r", "t", "y"])
@variable(jumpmodel, vannualemissions[sregion, semission, syear] >= 0)
modelvarindices["vannualemissions"] = (vannualemissions, ["r", "e", "y"])
@variable(jumpmodel, vmodelperiodemissions[sregion, semission] >= 0)
modelvarindices["vmodelperiodemissions"] = (vmodelperiodemissions, ["r", "e"])

logmsg("Defined emissions variables.", quiet)

# Transmission
if transmissionmodeling
    queryvrateofactivitynodal::DataFrames.DataFrame = SQLite.query(db,
    "select ntc.n as n, l.val as l, ntc.t as t, m.val as m, ntc.y as y
    from NodalDistributionTechnologyCapacity_def ntc, TIMESLICE l, MODE_OF_OPERATION m
    where
    ntc.val > 0
    order by ntc.n, ntc.t, l.val, ntc.y")

    queryvrateofproductionbytechnologynodal::DataFrames.DataFrame = SQLite.query(db,
    "select ntc.n as n, ys.l as l, ntc.t as t, oar.f as f, ntc.y as y,
    	cast(ys.val as real) as ys
    from NodalDistributionTechnologyCapacity_def ntc, YearSplit_def ys, NODE n,
	TransmissionModelingEnabled tme,
    (select distinct r, t, f, y
    from OutputActivityRatio_def
    where val <> 0) oar
    where ntc.val > 0
    and ntc.y = ys.y
    and ntc.n = n.val
    and tme.r = n.r and tme.f = oar.f and tme.y = ntc.y
	and oar.r = n.r and oar.t = ntc.t and oar.y = ntc.y
    order by ntc.n, ys.l, oar.f, ntc.y")

    if in("vproductionbytechnology", varstosavearr)
        queryvproductionbytechnologynodal::DataFrames.DataFrame = SQLite.query(db,
        "select n.r as r, ntc.n as n, ys.l as l, ntc.t as t, oar.f as f, ntc.y as y,
        	cast(ys.val as real) as ys
        from NodalDistributionTechnologyCapacity_def ntc, YearSplit_def ys, NODE n,
    	TransmissionModelingEnabled tme,
        (select distinct r, t, f, y
        from OutputActivityRatio_def
        where val <> 0) oar
        where ntc.val > 0
        and ntc.y = ys.y
        and ntc.n = n.val
        and tme.r = n.r and tme.f = oar.f and tme.y = ntc.y
    	and oar.r = n.r and oar.t = ntc.t and oar.y = ntc.y
        order by n.r, ys.l, ntc.t, oar.f, ntc.y")

        queryvproductionbytechnologyindices = vcat(queryvproductionbytechnologyindices,
        SQLite.query(db,
        "select distinct n.r as r, ys.l as l, ntc.t as t, oar.f as f, ntc.y as y, null as ys
        from NodalDistributionTechnologyCapacity_def ntc, YearSplit_def ys, NODE n,
        TransmissionModelingEnabled tme,
        (select distinct r, t, f, y
        from OutputActivityRatio_def
        where val <> 0) oar
        where ntc.val > 0
        and ntc.y = ys.y
        and ntc.n = n.val
        and tme.r = n.r and tme.f = oar.f and tme.y = ntc.y
        and oar.r = n.r and oar.t = ntc.t and oar.y = ntc.y"))
    end

    queryvrateofusebytechnologynodal::DataFrames.DataFrame = SQLite.query(db,
    "select ntc.n as n, ys.l as l, ntc.t as t, iar.f as f, ntc.y as y,
    	cast(ys.val as real) as ys
    from NodalDistributionTechnologyCapacity_def ntc, YearSplit_def ys, NODE n,
	TransmissionModelingEnabled tme,
    (select distinct r, t, f, y
    from InputActivityRatio_def
    where val <> 0) iar
    where ntc.val > 0
    and ntc.y = ys.y
    and ntc.n = n.val
    and tme.r = n.r and tme.f = iar.f and tme.y = ntc.y
	and iar.r = n.r and iar.t = ntc.t and iar.y = ntc.y
    order by ntc.n, ys.l, iar.f, ntc.y")

    if in("vusebytechnology", varstosavearr)
        queryvusebytechnologynodal::DataFrames.DataFrame = SQLite.query(db,
        "select n.r as r, ntc.n as n, ys.l as l, ntc.t as t, iar.f as f, ntc.y as y,
        	cast(ys.val as real) as ys
        from NodalDistributionTechnologyCapacity_def ntc, YearSplit_def ys, NODE n,
    	TransmissionModelingEnabled tme,
        (select distinct r, t, f, y
        from InputActivityRatio_def
        where val <> 0) iar
        where ntc.val > 0
        and ntc.y = ys.y
        and ntc.n = n.val
        and tme.r = n.r and tme.f = iar.f and tme.y = ntc.y
    	and iar.r = n.r and iar.t = ntc.t and iar.y = ntc.y
        order by n.r, ys.l, ntc.t, iar.f, ntc.y")

        queryvusebytechnologyindices = vcat(queryvusebytechnologyindices,
        SQLite.query(db,
        "select distinct n.r as r, ys.l as l, ntc.t as t, iar.f as f, ntc.y as y, null as ys
        from NodalDistributionTechnologyCapacity_def ntc, YearSplit_def ys, NODE n,
        TransmissionModelingEnabled tme,
        (select distinct r, t, f, y
        from InputActivityRatio_def
        where val <> 0) iar
        where ntc.val > 0
        and ntc.y = ys.y
        and ntc.n = n.val
        and tme.r = n.r and tme.f = iar.f and tme.y = ntc.y
        and iar.r = n.r and iar.t = ntc.t and iar.y = ntc.y"))
    end

    queryvtransmissionbyline::DataFrames.DataFrame = SQLite.query(db,
    "select tl.id as tr, ys.l as l, tl.f as f, tme1.y as y, tl.n1 as n1, tl.n2 as n2,
	tl.reactance as reactance, tme1.type as type, tl.maxflow as maxflow,
    cast(tl.VariableCost as real) as vc, cast(ys.val as real) as ys,
    cast(tl.fixedcost as real) as fc
    from TransmissionLine tl, NODE n1, NODE n2, TransmissionModelingEnabled tme1,
    TransmissionModelingEnabled tme2, YearSplit_def ys
    where
    tl.n1 = n1.val and tl.n2 = n2.val
    and tme1.r = n1.r and tme1.f = tl.f
    and tme2.r = n2.r and tme2.f = tl.f
    and tme1.y = tme2.y and tme1.type = tme2.type
	and ys.y = tme1.y
    order by tl.id, tme1.y")

    if restrictvars
        indexdicts = keydicts_parallel(queryvrateofactivitynodal, 4, targetprocs)  # Array of Dicts used to restrict indices of following variable
        @variable(jumpmodel, vrateofactivitynodal[n=[k[1] for k = keys(indexdicts[1])], l=indexdicts[1][[n]], t=indexdicts[2][[n,l]],
            m=indexdicts[3][[n,l,t]], y=indexdicts[4][[n,l,t,m]]] >= 0)

        indexdicts = keydicts_parallel(queryvrateofproductionbytechnologynodal, 4, targetprocs)  # Array of Dicts used to restrict indices of following variable
        @variable(jumpmodel, vrateofproductionbytechnologynodal[n=[k[1] for k = keys(indexdicts[1])], l=indexdicts[1][[n]], t=indexdicts[2][[n,l]],
            f=indexdicts[3][[n,l,t]], y=indexdicts[4][[n,l,t,f]]] >= 0)

        indexdicts = keydicts_parallel(queryvtransmissionbyline, 3, targetprocs)  # Array of Dicts used to restrict indices of following variable
        @variable(jumpmodel, vtransmissionbyline[tr=[k[1] for k = keys(indexdicts[1])], l=indexdicts[1][[tr]], f=indexdicts[2][[tr,l]],
            y=indexdicts[3][[tr,l,f]]])
    else
        @variable(jumpmodel, vrateofactivitynodal[snode, stimeslice, stechnology, smode_of_operation, syear] >= 0)
        @variable(jumpmodel, vrateofproductionbytechnologynodal[snode, stimeslice, stechnology, sfuel, syear] >= 0)
        @variable(jumpmodel, vtransmissionbyline[stransmission, stimeslice, sfuel, syear])
    end

    modelvarindices["vrateofactivitynodal"] = (vrateofactivitynodal, ["n", "l", "t", "m", "y"])
    modelvarindices["vrateofproductionbytechnologynodal"] = (vrateofproductionbytechnologynodal, ["n", "l", "t", "f", "y"])
    # Note: n1 is from node; n2 is to node
    modelvarindices["vtransmissionbyline"] = (vtransmissionbyline, ["tr", "l", "f", "y"])

    @variable(jumpmodel, vrateoftotalactivitynodal[snode, stechnology, stimeslice, syear] >= 0)
    modelvarindices["vrateoftotalactivitynodal"] = (vrateoftotalactivitynodal, ["n", "t", "l", "y"])

    @variable(jumpmodel, vrateofproductionnodal[snode, stimeslice, sfuel, syear] >= 0)
    modelvarindices["vrateofproductionnodal"] = (vrateofproductionnodal, ["n", "l", "f", "y"])

    @variable(jumpmodel, vrateofusenodal[snode, stimeslice, sfuel, syear] >= 0)
    modelvarindices["vrateofusenodal"] = (vrateofusenodal, ["n", "l", "f", "y"])

    @variable(jumpmodel, vproductionnodal[snode, stimeslice, sfuel, syear] >= 0)
    modelvarindices["vproductionnodal"] = (vproductionnodal, ["n","l","f","y"])

    @variable(jumpmodel, vproductionannualnodal[snode, sfuel, syear] >= 0)
    modelvarindices["vproductionannualnodal"] = (vproductionannualnodal, ["n","f","y"])

    @variable(jumpmodel, vusenodal[snode, stimeslice, sfuel, syear] >= 0)
    modelvarindices["vusenodal"] = (vusenodal, ["n","l","f","y"])

    @variable(jumpmodel, vuseannualnodal[snode, sfuel, syear] >= 0)
    modelvarindices["vuseannualnodal"] = (vuseannualnodal, ["n","f","y"])

    @variable(jumpmodel, vdemandnodal[snode, stimeslice, sfuel, syear] >= 0)
    modelvarindices["vdemandnodal"] = (vdemandnodal, ["n","l","f","y"])

    @variable(jumpmodel, vtransmissionbuilt[stransmission, syear], Bin)  # Indicates whether tr is built in year
    modelvarindices["vtransmissionbuilt"] = (vtransmissionbuilt, ["tr","y"])

    @variable(jumpmodel, vtransmissionexists[stransmission, syear], Bin)  # Indicates whether tr exists (exogenously or endogenously) in year
    modelvarindices["vtransmissionexists"] = (vtransmissionexists, ["tr","y"])

    # 1 = DC optimized power flow, 2 = DCOPF with disjunctive relaxation
    if in(1, transmissionmodelingtypes) || in(2, transmissionmodelingtypes)
        @variable(jumpmodel, -pi <= vvoltageangle[snode, stimeslice, syear] <= pi)
        modelvarindices["vvoltageangle"] = (vvoltageangle, ["n","l","y"])
    end

    @variable(jumpmodel, vcapitalinvestmenttransmission[stransmission, syear] >= 0)
    modelvarindices["vcapitalinvestmenttransmission"] = (vcapitalinvestmenttransmission, ["tr","y"])
    @variable(jumpmodel, vdiscountedcapitalinvestmenttransmission[stransmission, syear] >= 0)
    modelvarindices["vdiscountedcapitalinvestmenttransmission"] = (vdiscountedcapitalinvestmenttransmission, ["tr","y"])
    @variable(jumpmodel, vsalvagevaluetransmission[stransmission, syear] >= 0)
    modelvarindices["vsalvagevaluetransmissionvsalvagevaluetransmission"] = (vsalvagevaluetransmission, ["tr","y"])
    @variable(jumpmodel, vdiscountedsalvagevaluetransmission[stransmission, syear] >= 0)
    modelvarindices["vdiscountedsalvagevaluetransmission"] = (vdiscountedsalvagevaluetransmission, ["tr","y"])
    @variable(jumpmodel, voperatingcosttransmission[stransmission, syear] >= 0)
    modelvarindices["voperatingcosttransmission"] = (voperatingcosttransmission, ["tr","y"])
    @variable(jumpmodel, vdiscountedoperatingcosttransmission[stransmission, syear] >= 0)
    modelvarindices["vdiscountedoperatingcosttransmission"] = (vdiscountedoperatingcosttransmission, ["tr","y"])
    @variable(jumpmodel, vtotaldiscountedtransmissioncostbyregion[sregion, syear] >= 0)
    modelvarindices["vtotaldiscountedtransmissioncostbyregion"] = (vtotaldiscountedtransmissioncostbyregion, ["r","y"])

    logmsg("Defined transmission variables.", quiet)
end  # transmissionmodeling

# Combined nodal + non-nodal variables
if in("vproductionbytechnology", varstosavearr)
    if restrictvars
        indexdicts = keydicts_parallel(queryvproductionbytechnologyindices, 4, targetprocs)  # Array of Dicts used to restrict indices of following variable
        @variable(jumpmodel, vproductionbytechnology[r=[k[1] for k = keys(indexdicts[1])], l=indexdicts[1][[r]], t=indexdicts[2][[r,l]],
            f=indexdicts[3][[r,l,t]], y=indexdicts[4][[r,l,t,f]]] >= 0)
    else
        @variable(jumpmodel, vproductionbytechnology[sregion, stimeslice, stechnology, sfuel, syear] >= 0)
    end

    modelvarindices["vproductionbytechnology"] = (vproductionbytechnology, ["r","l","t","f","y"])
end

if in("vusebytechnology", varstosavearr)
    if restrictvars
        indexdicts = keydicts_parallel(queryvusebytechnologyindices, 4, targetprocs)  # Array of Dicts used to restrict indices of following variable
        @variable(jumpmodel, vusebytechnology[r=[k[1] for k = keys(indexdicts[1])], l=indexdicts[1][[r]], t=indexdicts[2][[r,l]],
            f=indexdicts[3][[r,l,t]], y=indexdicts[4][[r,l,t,f]]] >= 0)
    else
        @variable(jumpmodel, vusebytechnology[sregion, stimeslice, stechnology, sfuel, syear] >= 0)
    end

    modelvarindices["vusebytechnology"] = (vusebytechnology, ["r","l","t","f","y"])
end

logmsg("Defined combined nodal and non-nodal variables.", quiet)

logmsg("Finished defining model variables.", quiet)
# END: Define model variables.

# BEGIN: Define model constraints.

# A few variables used in constraint construction
local lastkeys::Array{String, 1} = Array{String, 1}()  # Array of last key values processed in constraint query loops
local lastvals::Array{Float64, 1} = Array{Float64, 1}()  # Array of last float values saved in constraint query loops
local lastvalsint::Array{Int64, 1} = Array{Int64, 1}()  # Array of last integer values saved in constraint query loops
local sumexps::Array{AffExpr, 1} = Array{AffExpr, 1}()  # Array of sums of variables assembled in constraint query loops
local querytemp::DataFrames.DataFrame = DataFrames.DataFrame()  # Query object for temporary queries

# BEGIN: EQ_SpecifiedDemand.
queryvrateofdemandnn::DataFrames.DataFrame = SQLite.query(db,"select sdp.r as r, sdp.f as f, sdp.l as l, sdp.y as y,
cast(sdp.val as real) as specifieddemandprofile, cast(sad.val as real) as specifiedannualdemand,
cast(ys.val as real) as ys
from SpecifiedDemandProfile_def sdp, SpecifiedAnnualDemand_def sad, YearSplit_def ys
left join TransmissionModelingEnabled tme on tme.r = sad.r and tme.f = sad.f and tme.y = sad.y
where sad.r = sdp.r and sad.f = sdp.f and sad.y = sdp.y
and ys.l = sdp.l and ys.y = sdp.y
and sdp.val <> 0 and sad.val <> 0 and ys.val <> 0
and tme.id is null")

if in("vrateofdemandnn", varstosavearr)
    constraintnum::Int = 1  # Number of next constraint to be added to constraint array
    @constraintref ceq_specifieddemand[1:length(sregion) * length(stimeslice) * length(sfuel) * length(syear)]

    for row in DataFrames.eachrow(queryvrateofdemandnn)
        ceq_specifieddemand[constraintnum] = @constraint(jumpmodel, row[:specifiedannualdemand] * row[:specifieddemandprofile] / row[:ys]
            == vrateofdemandnn[row[:r], row[:l], row[:f], row[:y]])
        constraintnum += 1
    end

    logmsg("Created constraint EQ_SpecifiedDemand.", quiet)
end
# END: EQ_SpecifiedDemand.

# BEGIN: CAa1_TotalNewCapacity.
constraintnum = 1  # Number of next constraint to be added to constraint array
@constraintref caa1_totalnewcapacity[1:length(sregion) * length(stechnology) * length(syear)]

lastkeys = Array{String, 1}(undef,3)  # lastkeys[1] = r, lastkeys[2] = t, lastkeys[3] = y
sumexps = Array{AffExpr, 1}([AffExpr()])
# sumexps[1] = vnewcapacity sum

for row in DataFrames.eachrow(SQLite.query(db,"select r.val as r, t.val as t, y.val as y, yy.val as yy
from REGION r, TECHNOLOGY t, YEAR y, OperationalLife_def ol, YEAR yy
where ol.r = r.val and ol.t = t.val
and y.val - yy.val < ol.val and y.val - yy.val >=0
order by r.val, t.val, y.val"))
    local r = row[:r]
    local t = row[:t]
    local y = row[:y]

    if isassigned(lastkeys, 1) && (r != lastkeys[1] || t != lastkeys[2] || y != lastkeys[3])
        # Create constraint
        caa1_totalnewcapacity[constraintnum] = @constraint(jumpmodel, sumexps[1] == vaccumulatednewcapacity[lastkeys[1],lastkeys[2],lastkeys[3]])
        constraintnum += 1

        sumexps[1] = AffExpr()
    end

    append!(sumexps[1], vnewcapacity[r,t,row[:yy]])

    lastkeys[1] = r
    lastkeys[2] = t
    lastkeys[3] = y
end

# Create last constraint
if isassigned(lastkeys, 1)
    caa1_totalnewcapacity[constraintnum] = @constraint(jumpmodel, sumexps[1] == vaccumulatednewcapacity[lastkeys[1],lastkeys[2],lastkeys[3]])
end

logmsg("Created constraint CAa1_TotalNewCapacity.", quiet)
# END: CAa1_TotalNewCapacity.

# BEGIN: CAa2_TotalAnnualCapacity.
constraintnum = 1  # Number of next constraint to be added to constraint array
@constraintref caa2_totalannualcapacity[1:length(sregion) * length(stechnology) * length(syear)]

for row in DataFrames.eachrow(SQLite.query(db,"select r.val as r, t.val as t, y.val as y, cast(rc.val as real) as rc
from REGION r, TECHNOLOGY t, YEAR y
left join ResidualCapacity_def rc on rc.r = r.val and rc.t = t.val and rc.y = y.val"))
    local r = row[:r]
    local t = row[:t]
    local y = row[:y]
    local rc = ismissing(row[:rc]) ? 0 : row[:rc]

    caa2_totalannualcapacity[constraintnum] = @constraint(jumpmodel, vaccumulatednewcapacity[r,t,y] + rc == vtotalcapacityannual[r,t,y])
    constraintnum += 1
end

logmsg("Created constraint CAa2_TotalAnnualCapacity.", quiet)
# END: CAa2_TotalAnnualCapacity.

# BEGIN: VRateOfActivity1.
# This constraint sets activity to sum of nodal activity for technologies involved in nodal modeling. The implication is that
#   the non-nodal activity is controls total activity.
vrateofactivity1::Array{ConstraintRef, 1} = Array{ConstraintRef, 1}()
lastkeys = Array{String, 1}(undef,5)  # lastkeys[1] = r, lastkeys[2] = l, lastkeys[3] = t, lastkeys[4] = m, lastkeys[5] = y
sumexps = Array{AffExpr, 1}([AffExpr()])  # sumexps[1] = vrateofactivitynodal sum

for row in DataFrames.eachrow(SQLite.query(db,
"select r.val as r, l.val as l, t.val as t, m.val as m, y.val as y, ntc.n as n
from REGION r, TIMESLICE l, TECHNOLOGY t, MODE_OF_OPERATION m, YEAR y,
NodalDistributionTechnologyCapacity_def ntc, NODE n
where ntc.n = n.val
and n.r = r.val and ntc.t = t.val and ntc.y = y.val
and ntc.val > 0
order by r.val, l.val, t.val, m.val, y.val"))
    local r = row[:r]
    local l = row[:l]
    local t = row[:t]
    local m = row[:m]
    local y = row[:y]

    if isassigned(lastkeys, 1) && (r != lastkeys[1] || l != lastkeys[2] || t != lastkeys[3] || m != lastkeys[4] || y != lastkeys[5])
        # Create constraint
        push!(vrateofactivity1, @constraint(jumpmodel, sumexps[1] == vrateofactivity[lastkeys[1],lastkeys[2],lastkeys[3],lastkeys[4],lastkeys[5]]))
        sumexps[1] = AffExpr()
    end

    append!(sumexps[1], vrateofactivitynodal[row[:n],l,t,m,y])

    lastkeys[1] = r
    lastkeys[2] = l
    lastkeys[3] = t
    lastkeys[4] = m
    lastkeys[5] = y
end

if isassigned(lastkeys, 1)
    push!(vrateofactivity1, @constraint(jumpmodel, sumexps[1] == vrateofactivity[lastkeys[1],lastkeys[2],lastkeys[3],lastkeys[4],lastkeys[5]]))
end

logmsg("Created constraint VRateOfActivity1.", quiet)
# END: VRateOfActivity1.

# BEGIN: CAa3_TotalActivityOfEachTechnology.
caa3_totalactivityofeachtechnology::Array{ConstraintRef, 1} = Array{ConstraintRef, 1}()

for (r, t, l, y) in Base.product(sregion, stechnology, stimeslice, syear)
    push!(caa3_totalactivityofeachtechnology, @constraint(jumpmodel, sum([vrateofactivity[r,l,t,m,y] for m = smode_of_operation])
        == vrateoftotalactivity[r,t,l,y]))
end

logmsg("Created constraint CAa3_TotalActivityOfEachTechnology.", quiet)
# END: CAa3_TotalActivityOfEachTechnology.

# BEGIN: CAa3Tr_TotalActivityOfEachTechnology.
if transmissionmodeling
    caa3tr_totalactivityofeachtechnology::Array{ConstraintRef, 1} = Array{ConstraintRef, 1}()
    lastkeys = Array{String, 1}(undef,4)  # lastkeys[1] = n, lastkeys[2] = t, lastkeys[3] = l, lastkeys[4] = y
    sumexps = Array{AffExpr, 1}([AffExpr()])  # sumexps[1] = vrateofactivitynodal sum

    for row in DataFrames.eachrow(queryvrateofactivitynodal)
        local n = row[:n]
        local t = row[:t]
        local l = row[:l]
        local y = row[:y]

        if isassigned(lastkeys, 1) && (n != lastkeys[1] || t != lastkeys[2] || l != lastkeys[3] || y != lastkeys[4])
            # Create constraint
            push!(caa3tr_totalactivityofeachtechnology, @constraint(jumpmodel, sumexps[1] == vrateoftotalactivitynodal[lastkeys[1],lastkeys[2],lastkeys[3],lastkeys[4]]))
            sumexps[1] = AffExpr()
        end

        append!(sumexps[1], vrateofactivitynodal[n,l,t,row[:m],y])

        lastkeys[1] = n
        lastkeys[2] = t
        lastkeys[3] = l
        lastkeys[4] = y
    end

    # Create last constraint
    if isassigned(lastkeys, 1)
        push!(caa3tr_totalactivityofeachtechnology, @constraint(jumpmodel, sumexps[1] == vrateoftotalactivitynodal[lastkeys[1],lastkeys[2],lastkeys[3],lastkeys[4]]))
    end

    logmsg("Created constraint CAa3Tr_TotalActivityOfEachTechnology.", quiet)
end
# END: CAa3Tr_TotalActivityOfEachTechnology.

# BEGIN: CAa4_Constraint_Capacity.
constraintnum = 1  # Number of next constraint to be added to constraint array
@constraintref caa4_constraint_capacity[1:length(sregion) * length(stimeslice) * length(stechnology) * length(syear)]

for row in DataFrames.eachrow(SQLite.query(db,"select r.val as r, l.val as l, t.val as t, y.val as y,
    cast(cf.val as real) as cf, cast(cta.val as real) as cta
from REGION r, TIMESLICE l, TECHNOLOGY t, YEAR y, CapacityFactor_def cf, CapacityToActivityUnit_def cta
where cf.r = r.val and cf.t = t.val and cf.l = l.val and cf.y = y.val
and cta.r = r.val and cta.t = t.val"))
    local r = row[:r]
    local t = row[:t]
    local l = row[:l]
    local y = row[:y]

    caa4_constraint_capacity[constraintnum] = @constraint(jumpmodel, vrateoftotalactivity[r,t,l,y]
        <= vtotalcapacityannual[r,t,y] * row[:cf] * row[:cta])
    constraintnum += 1
end

logmsg("Created constraint CAa4_Constraint_Capacity.", quiet)
# END: CAa4_Constraint_Capacity.

# BEGIN: CAa4Tr_Constraint_Capacity.
if transmissionmodeling
    constraintnum = 1  # Number of next constraint to be added to constraint array
    @constraintref caa4tr_constraint_capacity[1:length(snode) * length(stimeslice) * length(stechnology) * length(syear)]

    for row in DataFrames.eachrow(SQLite.query(db,"select ntc.n as n, ntc.t as t, l.val as l, ntc.y as y, n.r as r,
    	cast(ntc.val as real) as ntc, cast(cf.val as real) as cf,
    	cast(cta.val as real) as cta
    from NodalDistributionTechnologyCapacity_def ntc, TIMESLICE l, NODE n,
    CapacityFactor_def cf, CapacityToActivityUnit_def cta
    where ntc.val > 0
    and ntc.n = n.val
    and cf.r = n.r and cf.t = ntc.t and cf.l = l.val and cf.y = ntc.y
    and cta.r = n.r and cta.t = ntc.t"))
        local n = row[:n]
        local t = row[:t]
        local l = row[:l]
        local y = row[:y]
        local r = row[:r]

        caa4tr_constraint_capacity[constraintnum] = @constraint(jumpmodel, vrateoftotalactivitynodal[n,t,l,y]
            <= vtotalcapacityannual[r,t,y] * row[:ntc] * row[:cf] * row[:cta])
        constraintnum += 1
    end

    logmsg("Created constraint CAa4Tr_Constraint_Capacity.", quiet)
end
# END: CAa4Tr_Constraint_Capacity.

# BEGIN: CAa5_TotalNewCapacity.
constraintnum = 1  # Number of next constraint to be added to constraint array
@constraintref caa5_totalnewcapacity[1:length(sregion) * length(stechnology) * length(syear)]

for row in DataFrames.eachrow(SQLite.query(db,"select cot.r as r, cot.t as t, cot.y as y, cast(cot.val as real) as cot
from CapacityOfOneTechnologyUnit_def cot where cot.val <> 0"))
    local r = row[:r]
    local t = row[:t]
    local y = row[:y]

    caa5_totalnewcapacity[constraintnum] = @constraint(jumpmodel, row[:cot] * vnumberofnewtechnologyunits[r,t,y]
        == vnewcapacity[r,t,y])
    constraintnum += 1
end

logmsg("Created constraint CAa5_TotalNewCapacity.", quiet)
# END: CAa5_TotalNewCapacity.

#= BEGIN: CAb1_PlannedMaintenance.
# Omitting this constraint since it only serves to apply AvailabilityFactor, for which user demand isn't clear.
#   This parameter specifies an outage on an annual level and lets the model choose when (in which time slices) to take it.
#   Note that the parameter isn't used by LEAP. Omitting the constraint improves performance. If the constraint were
#   reinstated, a variant for transmission modeling (incorporating vrateoftotalactivitynodal) would be needed.
constraintnum = 1  # Number of next constraint to be added to constraint array
@constraintref cab1_plannedmaintenance[1:length(sregion) * length(stechnology) * length(syear)]

lastkeys = Array{String, 1}(undef,3)  # lastkeys[1] = r, lastkeys[2] = t, lastkeys[3] = y
lastvals = Array{Float64, 1}(undef,2)  # lastvals[1] = af, lastvals[2] = cta
sumexps = Array{AffExpr, 1}([AffExpr(), AffExpr()])
# sumexps[1] = vrateoftotalactivity sum, sumexps[2] vtotalcapacityannual sum

for row in DataFrames.eachrow(SQLite.query(db, "select r.val as r, t.val as t, y.val as y,
ys.l as l, cast(ys.val as real) as ys, cast(cf.val as real) as cf,
cast(af.val as real) as af, cast(cta.val as real) as cta
from REGION r, TECHNOLOGY t, YEAR y, YearSplit_def ys, CapacityFactor_def cf,
AvailabilityFactor_def af, CapacityToActivityUnit_def cta
where
ys.y = y.val
and cf.r = r.val and cf.t = t.val and cf.l = ys.l and cf.y = y.val
and af.r = r.val and af.t = t.val and af.y = y.val
and cta.r = r.val and cta.t = t.val
order by r.val, t.val, y.val"))
    local r = row[:r]
    local t = row[:t]
    local l = row[:l]
    local y = row[:y]
    local ys = row[:ys]

    if isassigned(lastkeys, 1) && (r != lastkeys[1] || t != lastkeys[2] || y != lastkeys[3])
        # Create constraint
        cab1_plannedmaintenance[constraintnum] = @constraint(jumpmodel, sumexps[1] <= sumexps[2] * lastvals[1] * lastvals[2])
        constraintnum += 1

        sumexps[1] = AffExpr()
        sumexps[2] = AffExpr()
    end

    append!(sumexps[1], vrateoftotalactivity[r,t,l,y] * ys)
    append!(sumexps[2], vtotalcapacityannual[r,t,y] * row[:cf] * ys)

    lastkeys[1] = r
    lastkeys[2] = t
    lastkeys[3] = y
    lastvals[1] = row[:af]
    lastvals[2] = row[:cta]
end

# Create last constraint
if isassigned(lastkeys, 1)
    cab1_plannedmaintenance[constraintnum] = @constraint(jumpmodel, sumexps[1] <= sumexps[2] * lastvals[1] * lastvals[2])
end

logmsg("Created constraint CAb1_PlannedMaintenance.", quiet)
# END: CAb1_PlannedMaintenance. =#

# BEGIN: EBa1_RateOfFuelProduction1.
if in("vrateofproductionbytechnologybymodenn", varstosavearr)
    constraintnum = 1  # Number of next constraint to be added to constraint array
    @constraintref eba1_rateoffuelproduction1[1:size(queryvrateofproductionbytechnologybymodenn)[1]]

    for row in DataFrames.eachrow(queryvrateofproductionbytechnologybymodenn)
        local r = row[:r]
        local l = row[:l]
        local t = row[:t]
        local m = row[:m]
        local f = row[:f]
        local y = row[:y]

        eba1_rateoffuelproduction1[constraintnum] = @constraint(jumpmodel, vrateofactivity[r,l,t,m,y] * row[:oar] == vrateofproductionbytechnologybymodenn[r,l,t,m,f,y])
        constraintnum += 1
    end

    logmsg("Created constraint EBa1_RateOfFuelProduction1.", quiet)
end  # in("vrateofproductionbytechnologybymodenn", varstosavearr)
# END: EBa1_RateOfFuelProduction1.

# BEGIN: EBa2_RateOfFuelProduction2.
constraintnum = 1  # Number of next constraint to be added to constraint array
@constraintref eba2_rateoffuelproduction2[1:size(queryvrateofproductionbytechnologynn)[1]]

lastkeys = Array{String, 1}(undef,5)  # lastkeys[1] = r, lastkeys[2] = l, lastkeys[3] = t, lastkeys[4] = f, lastkeys[5] = y
sumexps = Array{AffExpr, 1}([AffExpr()])
# sumexps[1] = vrateofproductionbytechnologybymodenn-equivalent sum

for row in DataFrames.eachrow(queryvrateofproductionbytechnologybymodenn)
    local r = row[:r]
    local l = row[:l]
    local t = row[:t]
    local f = row[:f]
    local y = row[:y]

    if isassigned(lastkeys, 1) && (r != lastkeys[1] || l != lastkeys[2] || t != lastkeys[3] || f != lastkeys[4] || y != lastkeys[5])
        # Create constraint
        eba2_rateoffuelproduction2[constraintnum] = @constraint(jumpmodel, sumexps[1] ==
            vrateofproductionbytechnologynn[lastkeys[1], lastkeys[2], lastkeys[3], lastkeys[4], lastkeys[5]])
        constraintnum += 1

        sumexps[1] = AffExpr()
    end

    append!(sumexps[1], vrateofactivity[r,l,t,row[:m],y] * row[:oar])
    # Sum is of vrateofproductionbytechnologybymodenn[r,l,t,row[:m],f,y])

    lastkeys[1] = r
    lastkeys[2] = l
    lastkeys[3] = t
    lastkeys[4] = f
    lastkeys[5] = y
end

# Create last constraint
if isassigned(lastkeys, 1)
    eba2_rateoffuelproduction2[constraintnum] = @constraint(jumpmodel, sumexps[1] ==
        vrateofproductionbytechnologynn[lastkeys[1], lastkeys[2], lastkeys[3], lastkeys[4], lastkeys[5]])
end

logmsg("Created constraint EBa2_RateOfFuelProduction2.", quiet)
# END: EBa2_RateOfFuelProduction2.

# BEGIN: EBa2Tr_RateOfFuelProduction2.
if transmissionmodeling
    constraintnum = 1  # Number of next constraint to be added to constraint array
    @constraintref eba2tr_rateoffuelproduction2[1:size(queryvrateofproductionbytechnologynodal)[1]]

    lastkeys = Array{String, 1}(undef,5)  # lastkeys[1] = n, lastkeys[2] = l, lastkeys[3] = t, lastkeys[4] = f, lastkeys[5] = y
    sumexps = Array{AffExpr, 1}([AffExpr()])
    # sumexps[1] = vrateofactivitynodal sum

    for row in DataFrames.eachrow(SQLite.query(db,
    "select ntc.n as n, ys.l as l, ntc.t as t, oar.f as f, ntc.y as y, m.val as m,
	   cast(oar.val as real) as oar
    from NodalDistributionTechnologyCapacity_def ntc, YearSplit_def ys, MODE_OF_OPERATION m, NODE n, OutputActivityRatio_def oar,
	TransmissionModelingEnabled tme
    where ntc.val > 0
    and ntc.y = ys.y
    and ntc.n = n.val
    and oar.r = n.r and oar.t = ntc.t and oar.m = m.val and oar.y = ntc.y
    and oar.val > 0
	and tme.r = n.r and tme.f = oar.f and tme.y = ntc.y
    order by ntc.n, ys.l, ntc.t, oar.f, ntc.y"))
        local n = row[:n]
        local l = row[:l]
        local t = row[:t]
        local f = row[:f]
        local y = row[:y]

        if isassigned(lastkeys, 1) && (n != lastkeys[1] || l != lastkeys[2] || t != lastkeys[3] || f != lastkeys[4] || y != lastkeys[5])
            # Create constraint
            eba2tr_rateoffuelproduction2[constraintnum] = @constraint(jumpmodel, sumexps[1] ==
                vrateofproductionbytechnologynodal[lastkeys[1], lastkeys[2], lastkeys[3], lastkeys[4], lastkeys[5]])
            constraintnum += 1

            sumexps[1] = AffExpr()
        end

        append!(sumexps[1], vrateofactivitynodal[n,l,t,row[:m],y] * row[:oar])

        lastkeys[1] = n
        lastkeys[2] = l
        lastkeys[3] = t
        lastkeys[4] = f
        lastkeys[5] = y
    end

    # Create last constraint
    if isassigned(lastkeys, 1)
        eba2tr_rateoffuelproduction2[constraintnum] = @constraint(jumpmodel, sumexps[1] ==
            vrateofproductionbytechnologynodal[lastkeys[1], lastkeys[2], lastkeys[3], lastkeys[4], lastkeys[5]])
    end

    logmsg("Created constraint EBa2Tr_RateOfFuelProduction2.", quiet)
end
# END: EBa2Tr_RateOfFuelProduction2.

# BEGIN: EBa3_RateOfFuelProduction3.
constraintnum = 1  # Number of next constraint to be added to constraint array
@constraintref eba3_rateoffuelproduction3[1:length(sregion) * length(stimeslice) * length(sfuel) * length(syear)]

lastkeys = Array{String, 1}(undef,4)  # lastkeys[1] = r, lastkeys[2] = l, lastkeys[3] = f, lastkeys[4] = y
sumexps = Array{AffExpr, 1}([AffExpr()])  # sumexps[1] = vrateofproductionbytechnologynn sum

for row in DataFrames.eachrow(queryvrateofproductionbytechnologynn)
    local r = row[:r]
    local l = row[:l]
    local f = row[:f]
    local y = row[:y]

    if isassigned(lastkeys, 1) && (r != lastkeys[1] || l != lastkeys[2] || f != lastkeys[3] || y != lastkeys[4])
        # Create constraint
        eba3_rateoffuelproduction3[constraintnum] = @constraint(jumpmodel, sumexps[1] == vrateofproductionnn[lastkeys[1],lastkeys[2],lastkeys[3],lastkeys[4]])
        constraintnum += 1

        sumexps[1] = AffExpr()
    end

    append!(sumexps[1], vrateofproductionbytechnologynn[r,l,row[:t],f,y])

    lastkeys[1] = r
    lastkeys[2] = l
    lastkeys[3] = f
    lastkeys[4] = y
end

# Create last constraint
if isassigned(lastkeys, 1)
    eba3_rateoffuelproduction3[constraintnum] = @constraint(jumpmodel, sumexps[1] == vrateofproductionnn[lastkeys[1],lastkeys[2],lastkeys[3],lastkeys[4]])
end

logmsg("Created constraint EBa3_RateOfFuelProduction3.", quiet)
# END: EBa3_RateOfFuelProduction3.

# BEGIN: EBa3Tr_RateOfFuelProduction3.
if transmissionmodeling
    constraintnum = 1  # Number of next constraint to be added to constraint array
    @constraintref eba3tr_rateoffuelproduction3[1:length(snode) * length(stimeslice) * length(sfuel) * length(syear)]

    lastkeys = Array{String, 1}(undef,4)  # lastkeys[1] = n, lastkeys[2] = l, lastkeys[3] = f, lastkeys[4] = y
    sumexps = Array{AffExpr, 1}([AffExpr()])  # sumexps[1] = vrateofproductionbytechnologynodal sum

    for row in DataFrames.eachrow(queryvrateofproductionbytechnologynodal)
        local n = row[:n]
        local l = row[:l]
        local f = row[:f]
        local y = row[:y]

        if isassigned(lastkeys, 1) && (n != lastkeys[1] || l != lastkeys[2] || f != lastkeys[3] || y != lastkeys[4])
            # Create constraint
            eba3tr_rateoffuelproduction3[constraintnum] = @constraint(jumpmodel, sumexps[1] == vrateofproductionnodal[lastkeys[1],lastkeys[2],lastkeys[3],lastkeys[4]])
            constraintnum += 1

            sumexps[1] = AffExpr()
        end

        append!(sumexps[1], vrateofproductionbytechnologynodal[n,l,row[:t],f,y])

        lastkeys[1] = n
        lastkeys[2] = l
        lastkeys[3] = f
        lastkeys[4] = y
    end

    # Create last constraint
    if isassigned(lastkeys, 1)
        eba3tr_rateoffuelproduction3[constraintnum] = @constraint(jumpmodel, sumexps[1] == vrateofproductionnodal[lastkeys[1],lastkeys[2],lastkeys[3],lastkeys[4]])
    end

    logmsg("Created constraint EBa3Tr_RateOfFuelProduction3.", quiet)
end
# END: EBa3Tr_RateOfFuelProduction3.

# BEGIN: VRateOfProduction1.
queryvrateofproduse::DataFrames.DataFrame = DataFrames.DataFrame()  # Populated below if transmissionmodeling

if !transmissionmodeling
    @constraint(jumpmodel, vrateofproduction1[r = sregion, l = stimeslice, f = sfuel, y = syear], vrateofproduction[r,l,f,y] == vrateofproductionnn[r,l,f,y])
else
    # Combine nodal and non-nodal
    constraintnum = 1  # Number of next constraint to be added to constraint array
    @constraintref vrateofproduction1[1:length(sregion) * length(stimeslice) * length(sfuel) * length(syear)]

    lastkeys = Array{String, 1}(undef,4)  # lastkeys[1] = r, lastkeys[2] = l, lastkeys[3] = f, lastkeys[4] = y
    sumexps = Array{AffExpr, 1}([AffExpr()])  # sumexps[1] = vrateofproductionnodal sum

    queryvrateofproduse = SQLite.query(db,
    "select r.val as r, l.val as l, f.val as f, y.val as y, tme.id as tme, n.val as n
    from region r, timeslice l, fuel f, year y, YearSplit_def ys
    left join TransmissionModelingEnabled tme on tme.r = r.val and tme.f = f.val and tme.y = y.val
    left join NODE n on n.r = r.val
    where
    ys.l = l.val and ys.y = y.val
    order by r.val, l.val, f.val, y.val")

    for row in DataFrames.eachrow(queryvrateofproduse)
        local r = row[:r]
        local l = row[:l]
        local f = row[:f]
        local y = row[:y]

        if isassigned(lastkeys, 1) && (r != lastkeys[1] || l != lastkeys[2] || f != lastkeys[3] || y != lastkeys[4])
            # Create constraint
            vrateofproduction1[constraintnum] = @constraint(jumpmodel,
                (sumexps[1] == AffExpr() ? vrateofproductionnn[lastkeys[1],lastkeys[2],lastkeys[3],lastkeys[4]] : sumexps[1])
                == vrateofproduction[lastkeys[1],lastkeys[2],lastkeys[3],lastkeys[4]])
            constraintnum += 1

            sumexps[1] = AffExpr()
        end

        if !ismissing(row[:tme]) && !ismissing(row[:n])
            append!(sumexps[1], vrateofproductionnodal[row[:n],l,f,y])
        end

        lastkeys[1] = r
        lastkeys[2] = l
        lastkeys[3] = f
        lastkeys[4] = y
    end

    # Create last constraint
    if isassigned(lastkeys, 1)
        vrateofproduction1[constraintnum] = @constraint(jumpmodel,
            (sumexps[1] == AffExpr() ? vrateofproductionnn[lastkeys[1],lastkeys[2],lastkeys[3],lastkeys[4]] : sumexps[1])
            == vrateofproduction[lastkeys[1],lastkeys[2],lastkeys[3],lastkeys[4]])
    end
end

logmsg("Created constraint VRateOfProduction1.", quiet)
# END: VRateOfProduction1.

# BEGIN: EBa4_RateOfFuelUse1.
if in("vrateofusebytechnologybymodenn", varstosavearr)
    constraintnum = 1  # Number of next constraint to be added to constraint array
    @constraintref eba4_rateoffueluse1[1:size(queryvrateofusebytechnologybymodenn)[1]]

    for row in DataFrames.eachrow(queryvrateofusebytechnologybymodenn)
        local r = row[:r]
        local l = row[:l]
        local f = row[:f]
        local t = row[:t]
        local m = row[:m]
        local y = row[:y]

        eba4_rateoffueluse1[constraintnum] = @constraint(jumpmodel, vrateofactivity[r,l,t,m,y] * row[:iar] == vrateofusebytechnologybymodenn[r,l,t,m,f,y])
        constraintnum += 1
    end

    logmsg("Created constraint EBa4_RateOfFuelUse1.", quiet)
end
# END: EBa4_RateOfFuelUse1.

# BEGIN: EBa5_RateOfFuelUse2.
constraintnum = 1  # Number of next constraint to be added to constraint array
@constraintref eba5_rateoffueluse2[1:size(queryvrateofusebytechnologynn)[1]]

lastkeys = Array{String, 1}(undef,5)  # lastkeys[1] = r, lastkeys[2] = l, lastkeys[3] = t, lastkeys[4] = f, lastkeys[5] = y
sumexps = Array{AffExpr, 1}([AffExpr()])
# sumexps[1] = vrateofusebytechnologybymodenn-equivalent sum

for row in DataFrames.eachrow(queryvrateofusebytechnologybymodenn)
    local r = row[:r]
    local l = row[:l]
    local f = row[:f]
    local t = row[:t]
    local y = row[:y]

    if isassigned(lastkeys, 1) && (r != lastkeys[1] || l != lastkeys[2] || t != lastkeys[3] || f != lastkeys[4] || y != lastkeys[5])
        # Create constraint
        eba5_rateoffueluse2[constraintnum] = @constraint(jumpmodel, sumexps[1] ==
            vrateofusebytechnologynn[lastkeys[1], lastkeys[2], lastkeys[3], lastkeys[4], lastkeys[5]])
        constraintnum += 1

        sumexps[1] = AffExpr()
    end

    append!(sumexps[1], vrateofactivity[r,l,t,row[:m],y] * row[:iar])
    # Sum is of vrateofusebytechnologybymodenn[r,l,t,row[:m],f,y])

    lastkeys[1] = r
    lastkeys[2] = l
    lastkeys[3] = t
    lastkeys[4] = f
    lastkeys[5] = y
end

# Create last constraint
if isassigned(lastkeys, 1)
    eba5_rateoffueluse2[constraintnum] = @constraint(jumpmodel, sumexps[1] ==
        vrateofusebytechnologynn[lastkeys[1], lastkeys[2], lastkeys[3], lastkeys[4], lastkeys[5]])
end

logmsg("Created constraint EBa5_RateOfFuelUse2.", quiet)
# END: EBa5_RateOfFuelUse2.

# BEGIN: EBa5Tr_RateOfFuelUse2.
if transmissionmodeling
    constraintnum = 1  # Number of next constraint to be added to constraint array
    @constraintref eba5tr_rateoffueluse2[1:size(queryvrateofusebytechnologynodal)[1]]

    lastkeys = Array{String, 1}(undef,5)  # lastkeys[1] = n, lastkeys[2] = l, lastkeys[3] = t, lastkeys[4] = f, lastkeys[5] = y
    sumexps = Array{AffExpr, 1}([AffExpr()])
    # sumexps[1] = vrateofactivitynodal sum

    for row in DataFrames.eachrow(SQLite.query(db,
    "select ntc.n as n, ys.l as l, ntc.t as t, iar.f as f, ntc.y as y, m.val as m,
	   cast(iar.val as real) as iar
    from NodalDistributionTechnologyCapacity_def ntc, YearSplit_def ys, MODE_OF_OPERATION m, NODE n, InputActivityRatio_def iar,
	TransmissionModelingEnabled tme
    where ntc.val > 0
    and ntc.y = ys.y
    and ntc.n = n.val
    and iar.r = n.r and iar.t = ntc.t and iar.m = m.val and iar.y = ntc.y
    and iar.val > 0
	and tme.r = n.r and tme.f = iar.f and tme.y = ntc.y
    order by ntc.n, ys.l, ntc.t, iar.f, ntc.y"))
        local n = row[:n]
        local l = row[:l]
        local t = row[:t]
        local f = row[:f]
        local y = row[:y]

        if isassigned(lastkeys, 1) && (n != lastkeys[1] || l != lastkeys[2] || t != lastkeys[3] || f != lastkeys[4] || y != lastkeys[5])
            # Create constraint
            eba5tr_rateoffueluse2[constraintnum] = @constraint(jumpmodel, sumexps[1] ==
                vrateofusebytechnologynodal[lastkeys[1], lastkeys[2], lastkeys[3], lastkeys[4], lastkeys[5]])
            constraintnum += 1

            sumexps[1] = AffExpr()
        end

        append!(sumexps[1], vrateofactivitynodal[n,l,t,row[:m],y] * row[:iar])

        lastkeys[1] = n
        lastkeys[2] = l
        lastkeys[3] = t
        lastkeys[4] = f
        lastkeys[5] = y
    end

    # Create last constraint
    if isassigned(lastkeys, 1)
        eba5tr_rateoffueluse2[constraintnum] = @constraint(jumpmodel, sumexps[1] ==
            vrateofusebytechnologynodal[lastkeys[1], lastkeys[2], lastkeys[3], lastkeys[4], lastkeys[5]])
    end

    logmsg("Created constraint EBa5Tr_RateOfFuelUse2.", quiet)
end
# END: EBa5Tr_RateOfFuelUse2.

# BEGIN: EBa6_RateOfFuelUse3.
constraintnum = 1  # Number of next constraint to be added to constraint array
@constraintref eba6_rateoffueluse3[1:length(sregion) * length(stimeslice) * length(sfuel) * length(syear)]

lastkeys = Array{String, 1}(undef,4)  # lastkeys[1] = r, lastkeys[2] = l, lastkeys[3] = f, lastkeys[4] = y
sumexps = Array{AffExpr, 1}([AffExpr()])  # sumexps[1] = vrateofusebytechnologynn sum

for row in DataFrames.eachrow(queryvrateofusebytechnologynn)
    local r = row[:r]
    local l = row[:l]
    local f = row[:f]
    local y = row[:y]

    if isassigned(lastkeys, 1) && (r != lastkeys[1] || l != lastkeys[2] || f != lastkeys[3] || y != lastkeys[4])
        # Create constraint
        eba6_rateoffueluse3[constraintnum] = @constraint(jumpmodel, sumexps[1] == vrateofusenn[lastkeys[1],lastkeys[2],lastkeys[3],lastkeys[4]])
        constraintnum += 1

        sumexps[1] = AffExpr()
    end

    append!(sumexps[1], vrateofusebytechnologynn[r,l,row[:t],f,y])

    lastkeys[1] = r
    lastkeys[2] = l
    lastkeys[3] = f
    lastkeys[4] = y
end

# Create last constraint
if isassigned(lastkeys, 1)
    eba6_rateoffueluse3[constraintnum] = @constraint(jumpmodel, sumexps[1] == vrateofusenn[lastkeys[1],lastkeys[2],lastkeys[3],lastkeys[4]])
end

logmsg("Created constraint EBa6_RateOfFuelUse3.", quiet)
# END: EBa6_RateOfFuelUse3.

# BEGIN: EBa6Tr_RateOfFuelUse3.
if transmissionmodeling
    constraintnum = 1  # Number of next constraint to be added to constraint array
    @constraintref eba6tr_rateoffueluse3[1:length(snode) * length(stimeslice) * length(sfuel) * length(syear)]

    lastkeys = Array{String, 1}(undef,4)  # lastkeys[1] = n, lastkeys[2] = l, lastkeys[3] = f, lastkeys[4] = y
    sumexps = Array{AffExpr, 1}([AffExpr()])  # sumexps[1] = vrateofusebytechnologynodal sum

    for row in DataFrames.eachrow(queryvrateofusebytechnologynodal)
        local n = row[:n]
        local l = row[:l]
        local f = row[:f]
        local y = row[:y]

        if isassigned(lastkeys, 1) && (n != lastkeys[1] || l != lastkeys[2] || f != lastkeys[3] || y != lastkeys[4])
            # Create constraint
            eba6tr_rateoffueluse3[constraintnum] = @constraint(jumpmodel, sumexps[1] == vrateofusenodal[lastkeys[1],lastkeys[2],lastkeys[3],lastkeys[4]])
            constraintnum += 1

            sumexps[1] = AffExpr()
        end

        append!(sumexps[1], vrateofusebytechnologynodal[n,l,row[:t],f,y])

        lastkeys[1] = n
        lastkeys[2] = l
        lastkeys[3] = f
        lastkeys[4] = y
    end

    # Create last constraint
    if isassigned(lastkeys, 1)
        eba6tr_rateoffueluse3[constraintnum] = @constraint(jumpmodel, sumexps[1] == vrateofusenodal[lastkeys[1],lastkeys[2],lastkeys[3],lastkeys[4]])
    end

    logmsg("Created constraint EBa6Tr_RateOfFuelUse3.", quiet)
end
# END: EBa6Tr_RateOfFuelUse3.

# BEGIN: VRateOfUse1.
if !transmissionmodeling
    @constraint(jumpmodel, vrateofuse1[r = sregion, l = stimeslice, f = sfuel, y = syear], vrateofuse[r,l,f,y] == vrateofusenn[r,l,f,y])
else
    # Combine nodal and non-nodal
    constraintnum = 1  # Number of next constraint to be added to constraint array
    @constraintref vrateofuse1[1:length(sregion) * length(stimeslice) * length(sfuel) * length(syear)]

    lastkeys = Array{String, 1}(undef,4)  # lastkeys[1] = r, lastkeys[2] = l, lastkeys[3] = f, lastkeys[4] = y
    sumexps = Array{AffExpr, 1}([AffExpr()])  # sumexps[1] = vrateofusenodal sum

    for row in DataFrames.eachrow(queryvrateofproduse)
        local r = row[:r]
        local l = row[:l]
        local f = row[:f]
        local y = row[:y]

        if isassigned(lastkeys, 1) && (r != lastkeys[1] || l != lastkeys[2] || f != lastkeys[3] || y != lastkeys[4])
            # Create constraint
            vrateofuse1[constraintnum] = @constraint(jumpmodel,
                (sumexps[1] == AffExpr() ? vrateofusenn[lastkeys[1],lastkeys[2],lastkeys[3],lastkeys[4]] : sumexps[1])
                == vrateofuse[lastkeys[1],lastkeys[2],lastkeys[3],lastkeys[4]])
            constraintnum += 1

            sumexps[1] = AffExpr()
        end

        if !ismissing(row[:tme]) && !ismissing(row[:n])
            append!(sumexps[1], vrateofusenodal[row[:n],l,f,y])
        end

        lastkeys[1] = r
        lastkeys[2] = l
        lastkeys[3] = f
        lastkeys[4] = y
    end

    # Create last constraint
    if isassigned(lastkeys, 1)
        vrateofuse1[constraintnum] = @constraint(jumpmodel,
            (sumexps[1] == AffExpr() ? vrateofusenn[lastkeys[1],lastkeys[2],lastkeys[3],lastkeys[4]] : sumexps[1])
            == vrateofuse[lastkeys[1],lastkeys[2],lastkeys[3],lastkeys[4]])
    end
end

logmsg("Created constraint VRateOfUse1.", quiet)
# END: VRateOfUse1.

# BEGIN: EBa7_EnergyBalanceEachTS1 and EBa8_EnergyBalanceEachTS2.
queryvproduse::DataFrames.DataFrame = SQLite.query(db, "select r.val as r, l.val as l, f.val as f, y.val as y, cast(ys.val as real) as ys
from region r, timeslice l, fuel f, year y, YearSplit_def ys
left join TransmissionModelingEnabled tme on tme.r = r.val and tme.f = f.val and tme.y = y.val
where
ys.l = l.val and ys.y = y.val
and tme.id is null")

constraintnum = 1  # Number of next constraint to be added to constraint array
@constraintref eba7_energybalanceeachts1[1:size(queryvproduse)[1]]
@constraintref eba8_energybalanceeachts2[1:size(queryvproduse)[1]]

for row in DataFrames.eachrow(queryvproduse)
    local r = row[:r]
    local l = row[:l]
    local f = row[:f]
    local y = row[:y]

    eba7_energybalanceeachts1[constraintnum] = @constraint(jumpmodel, vrateofproductionnn[r,l,f,y] * row[:ys] == vproductionnn[r,l,f,y])
    eba8_energybalanceeachts2[constraintnum] = @constraint(jumpmodel, vrateofusenn[r,l,f,y] * row[:ys] == vusenn[r,l,f,y])

    constraintnum += 1
end

logmsg("Created constraints EBa7_EnergyBalanceEachTS1 and EBa8_EnergyBalanceEachTS2.", quiet)
# END: EBa7_EnergyBalanceEachTS1 and EBa8_EnergyBalanceEachTS2.

# BEGIN: EBa7Tr_EnergyBalanceEachTS1 and EBa8Tr_EnergyBalanceEachTS2.
if transmissionmodeling
    queryvproduse = SQLite.query(db, "select n.val as n, l.val as l, f.val as f, y.val as y, cast(ys.val as real) as ys
    from node n, timeslice l, fuel f, year y, YearSplit_def ys,
    TransmissionModelingEnabled tme
    where
    ys.l = l.val and ys.y = y.val
    and tme.r = n.r and tme.f = f.val and tme.y = y.val")

    constraintnum = 1  # Number of next constraint to be added to constraint array
    @constraintref eba7tr_energybalanceeachts1[1:size(queryvproduse)[1]]
    @constraintref eba8tr_energybalanceeachts2[1:size(queryvproduse)[1]]

    for row in DataFrames.eachrow(queryvproduse)
        local n = row[:n]
        local l = row[:l]
        local f = row[:f]
        local y = row[:y]

        eba7tr_energybalanceeachts1[constraintnum] = @constraint(jumpmodel, vrateofproductionnodal[n,l,f,y] * row[:ys] == vproductionnodal[n,l,f,y])
        eba8tr_energybalanceeachts2[constraintnum] = @constraint(jumpmodel, vrateofusenodal[n,l,f,y] * row[:ys] == vusenodal[n,l,f,y])

        constraintnum += 1
    end

    logmsg("Created constraints EBa7Tr_EnergyBalanceEachTS1 and EBa8Tr_EnergyBalanceEachTS2.", quiet)
end
# END: EBa7Tr_EnergyBalanceEachTS1 and EBa8Tr_EnergyBalanceEachTS2.

# BEGIN: EBa9_EnergyBalanceEachTS3.
constraintnum = 1  # Number of next constraint to be added to constraint array
@constraintref eba9_energybalanceeachts3[1:size(queryvrateofdemandnn)[1]]

for row in DataFrames.eachrow(queryvrateofdemandnn)
    local r = row[:r]
    local l = row[:l]
    local f = row[:f]
    local y = row[:y]

    eba9_energybalanceeachts3[constraintnum] = @constraint(jumpmodel, row[:specifiedannualdemand] * row[:specifieddemandprofile] == vdemandnn[r,l,f,y])
    constraintnum += 1
end

logmsg("Created constraint EBa9_EnergyBalanceEachTS3.", quiet)
# END: EBa9_EnergyBalanceEachTS3.

# BEGIN: EBa9Tr_EnergyBalanceEachTS3.
if transmissionmodeling
    querytemp = SQLite.query(db, "select sdp.r as r, sdp.f as f, sdp.l as l, sdp.y as y, ndd.n as n,
    cast(sdp.val as real) as specifieddemandprofile, cast(sad.val as real) as specifiedannualdemand,
    cast(ndd.val as real) as ndd
    from SpecifiedDemandProfile_def sdp, SpecifiedAnnualDemand_def sad, TransmissionModelingEnabled tme,
    NodalDistributionDemand_def ndd, NODE n
    where sad.r = sdp.r and sad.f = sdp.f and sad.y = sdp.y
    and sdp.val <> 0 and sad.val <> 0
    and tme.r = sad.r and tme.f = sad.f and tme.y = sad.y
    and ndd.n = n.val
    and n.r = sad.r and ndd.f = sad.f and ndd.y = sad.y
    and ndd.val > 0")

    constraintnum = 1  # Number of next constraint to be added to constraint array
    @constraintref eba9tr_energybalanceeachts3[1:size(querytemp)[1]]

    for row in DataFrames.eachrow(querytemp)
        local n = row[:n]
        local l = row[:l]
        local f = row[:f]
        local y = row[:y]

        eba9tr_energybalanceeachts3[constraintnum] = @constraint(jumpmodel, row[:specifiedannualdemand] * row[:specifieddemandprofile]
            * row[:ndd] == vdemandnodal[n,l,f,y])
        constraintnum += 1
    end

    logmsg("Created constraint EBa9Tr_EnergyBalanceEachTS3.", quiet)
end
# END: EBa9Tr_EnergyBalanceEachTS3.

# BEGIN: EBa10_EnergyBalanceEachTS4.
constraintnum = 1  # Number of next constraint to be added to constraint array
@constraintref eba10_energybalanceeachts4[1:length(sregion)^2 * length(stimeslice) * length(sfuel) * length(syear)]

for (r, rr, l, f, y) in Base.product(sregion, sregion, stimeslice, sfuel, syear)
    eba10_energybalanceeachts4[constraintnum] = @constraint(jumpmodel, vtrade[r,rr,l,f,y] == -vtrade[rr,r,l,f,y])
    constraintnum += 1
end

logmsg("Created constraint EBa10_EnergyBalanceEachTS4.", quiet)
# END: EBa10_EnergyBalanceEachTS4.

# BEGIN: EBa11_EnergyBalanceEachTS5.
constraintnum = 1  # Number of next constraint to be added to constraint array
@constraintref eba11_energybalanceeachts5[1:length(sregion) * length(stimeslice) * length(sfuel) * length(syear)]

lastkeys = Array{String, 1}(undef,4)  # lastkeys[1] = r, lastkeys[2] = l, lastkeys[3] = f, lastkeys[4] = y
sumexps = Array{AffExpr, 1}([AffExpr()])
# sumexps[1] = vtrade sum

for row in DataFrames.eachrow(SQLite.query(db, "select r.val as r, l.val as l, f.val as f, y.val as y, tr.rr as rr,
    cast(tr.val as real) as trv
from region r, timeslice l, fuel f, year y
left join traderoute_def tr on tr.r = r.val and tr.f = f.val and tr.y = y.val
left join TransmissionModelingEnabled tme on tme.r = r.val and tme.f = f.val and tme.y = y.val
where tme.id is null
order by r.val, l.val, f.val, y.val"))
    local r = row[:r]
    local l = row[:l]
    local f = row[:f]
    local y = row[:y]

    if isassigned(lastkeys, 1) && (r != lastkeys[1] || l != lastkeys[2] || f != lastkeys[3] || y != lastkeys[4])
        # Create constraint
        eba11_energybalanceeachts5[constraintnum] = @constraint(jumpmodel, vproductionnn[lastkeys[1],lastkeys[2],lastkeys[3],lastkeys[4]] >=
            vdemandnn[lastkeys[1],lastkeys[2],lastkeys[3],lastkeys[4]] + vusenn[lastkeys[1],lastkeys[2],lastkeys[3],lastkeys[4]] + sumexps[1])
        constraintnum += 1

        sumexps[1] = AffExpr()
    end

    # Appears that traderoutes must be defined reciprocally - two entries for each pair of regions. Bears testing.
    if !ismissing(row[:rr])
        append!(sumexps[1], vtrade[r,row[:rr],l,f,y] * row[:trv])
    end

    lastkeys[1] = r
    lastkeys[2] = l
    lastkeys[3] = f
    lastkeys[4] = y
end

# Create last constraint
if isassigned(lastkeys, 1)
    eba11_energybalanceeachts5[constraintnum] = @constraint(jumpmodel, vproductionnn[lastkeys[1],lastkeys[2],lastkeys[3],lastkeys[4]] >=
        vdemandnn[lastkeys[1],lastkeys[2],lastkeys[3],lastkeys[4]] + vusenn[lastkeys[1],lastkeys[2],lastkeys[3],lastkeys[4]] + sumexps[1])
end

logmsg("Created constraint EBa11_EnergyBalanceEachTS5.", quiet)
# END: EBa11_EnergyBalanceEachTS5.

# BEGIN: Tr1_SumBuilt.
# Ensures vtransmissionbuilt can be 1 in at most one year
if transmissionmodeling
    constraintnum = 1  # Number of next constraint to be added to constraint array
    @constraintref tr1_sumbuilt[1:length(stransmission)]

    for tr in stransmission
        tr1_sumbuilt[constraintnum] = @constraint(jumpmodel, sum([vtransmissionbuilt[tr,y] for y in syear]) <= 1)
        constraintnum += 1
    end

    logmsg("Created constraint Tr1_SumBuilt.", quiet)
end
# END: Tr1_SumBuilt.

# BEGIN: Tr2_TransmissionExists.
if transmissionmodeling
    constraintnum = 1  # Number of next constraint to be added to constraint array
    @constraintref tr2_transmissionexists[1:length(stransmission) * length(syear)]

    lastkeys = Array{String, 1}(undef,2)  # lastkeys[1] = tr, lastkeys[2] = y
    lastvalsint = Array{Int64, 1}(undef,2)  # lastvalsint[1] = yconstruction, lastvalsint[2] = operationallife
    sumexps = Array{AffExpr, 1}([AffExpr()])  # sumexps[1] = vtransmissionbuilt sum

    for row in DataFrames.eachrow(SQLite.query(db, "select tl.id as tr, tl.yconstruction, tl.operationallife, y.val as y, null as yy
    from TransmissionLine tl, YEAR y
    where tl.yconstruction is not null
    union all
    select tl.id as tr, tl.yconstruction, tl.operationallife, y.val as y, yy.val as yy
    from TransmissionLine tl, YEAR y, YEAR yy
    where tl.yconstruction is null
    and yy.val + tl.operationallife > y.val
    and yy.val <= y.val
    order by tr, y"))
        local tr = row[:tr]
        local y = row[:y]
        local yy = row[:yy]
        local yconstruction = ismissing(row[:yconstruction]) ? 0 : row[:yconstruction]

        if isassigned(lastkeys, 1) && (tr != lastkeys[1] || y != lastkeys[2])
            # Create constraint
            if sumexps[1] == AffExpr()
                # Exogenously built line
                if (lastvalsint[1] <= Meta.parse(lastkeys[2])) && (lastvalsint[1] + lastvalsint[2] > Meta.parse(lastkeys[2]))
                    tr2_transmissionexists[constraintnum] = @constraint(jumpmodel, vtransmissionexists[lastkeys[1],lastkeys[2]] == 1)
                else
                    tr2_transmissionexists[constraintnum] = @constraint(jumpmodel, vtransmissionexists[lastkeys[1],lastkeys[2]] == 0)
                end
            else
                # Endogenous option
                tr2_transmissionexists[constraintnum] = @constraint(jumpmodel, sumexps[1] == vtransmissionexists[lastkeys[1],lastkeys[2]])
            end

            constraintnum += 1
            sumexps[1] = AffExpr()
        end

        if !ismissing(yy)
            append!(sumexps[1], vtransmissionbuilt[tr,yy])
        end

        lastkeys[1] = tr
        lastkeys[2] = y
        lastvalsint[1] = yconstruction
        lastvalsint[2] = row[:operationallife]
    end

    # Create last constraint
    if isassigned(lastkeys, 1)
        if sumexps[1] == AffExpr()
            # Exogenously built line
            if (lastvalsint[1] <= Meta.parse(lastkeys[2])) && (lastvalsint[1] + lastvalsint[2] > Meta.parse(lastkeys[2]))
                tr2_transmissionexists[constraintnum] = @constraint(jumpmodel, vtransmissionexists[lastkeys[1],lastkeys[2]] == 1)
            else
                tr2_transmissionexists[constraintnum] = @constraint(jumpmodel, vtransmissionexists[lastkeys[1],lastkeys[2]] == 0)
            end
        else
            # Endogenous option
            tr2_transmissionexists[constraintnum] = @constraint(jumpmodel, sumexps[1] == vtransmissionexists[lastkeys[1],lastkeys[2]])
        end
    end

    logmsg("Created constraint Tr2_TransmissionExists.", quiet)
end
# END: Tr2_TransmissionExists.

# BEGIN: Tr3_Flow, Tr4_MaxFlow, and Tr5_MinFlow.
if transmissionmodeling
    constraintnum = 1  # Number of next constraint to be added to constraint array
    @constraintref tr3_flow[1:size(queryvtransmissionbyline)[1]]
    tr3a_flow::Array{ConstraintRef, 1} = Array{ConstraintRef, 1}()
    @constraintref tr4_maxflow[1:size(queryvtransmissionbyline)[1]]
    @constraintref tr5_minflow[1:size(queryvtransmissionbyline)[1]]

    for row in DataFrames.eachrow(queryvtransmissionbyline)
        local tr = row[:tr]
        local n1 = row[:n1]
        local n2 = row[:n2]
        local l = row[:l]
        local f = row[:f]
        local y = row[:y]
        local type = row[:type]

        # vtransmissionbyline is flow over line tr from n1 to n2 in model's power units
        if type == 1  # DCOPF
            tr3_flow[constraintnum] = @constraint(jumpmodel, -1/row[:reactance] * (vvoltageangle[n1,l,y] - vvoltageangle[n2,l,y]) * vtransmissionexists[tr,y]
                == vtransmissionbyline[tr,l,f,y])
            tr4_maxflow[constraintnum] = @constraint(jumpmodel, vtransmissionbyline[tr,l,f,y] <= row[:maxflow])
            tr5_minflow[constraintnum] = @constraint(jumpmodel, vtransmissionbyline[tr,l,f,y] >= -row[:maxflow])
        elseif type == 2  # DCOPF with disjunctive formulation
            tr3_flow[constraintnum] = @constraint(jumpmodel, vtransmissionbyline[tr,l,f,y] -
                (-1/row[:reactance] * (vvoltageangle[n1,l,y] - vvoltageangle[n2,l,y]))
                <= (1 - vtransmissionexists[tr,y]) * 1000)
            push!(tr3a_flow, @constraint(jumpmodel, vtransmissionbyline[tr,l,f,y] -
                (-1/row[:reactance] * (vvoltageangle[n1,l,y] - vvoltageangle[n2,l,y]))
                >= (vtransmissionexists[tr,y] - 1) * 1000))
            #tr4_maxflow[constraintnum] = @constraint(jumpmodel, vtransmissionbyline[tr,l,f,y]^2 <= vtransmissionexists[tr,y] * row[:maxflow]^2)
            #tr5_minflow[constraintnum] = @constraint(jumpmodel, vtransmissionbyline[tr,l,f,y]^2 >= 0)
            tr4_maxflow[constraintnum] = @constraint(jumpmodel, vtransmissionbyline[tr,l,f,y] <= vtransmissionexists[tr,y] * row[:maxflow])
            tr5_minflow[constraintnum] = @constraint(jumpmodel, vtransmissionbyline[tr,l,f,y] >= -vtransmissionexists[tr,y] * row[:maxflow])
        end

        constraintnum += 1
    end

    logmsg("Created constraints Tr3_Flow, Tr4_MaxFlow, and Tr5_MinFlow.", quiet)
end
# END: Tr3_Flow, Tr4_MaxFlow, and Tr5_MinFlow.

# BEGIN: EBa11Tr_EnergyBalanceEachTS5.
if transmissionmodeling
    constraintnum = 1  # Number of next constraint to be added to constraint array
    @constraintref eba11tr_energybalanceeachts5[1:length(snode) * length(stimeslice) * length(sfuel) * length(syear)]

    lastkeys = Array{String, 1}(undef,4)  # lastkeys[1] = n, lastkeys[2] = l, lastkeys[3] = f, lastkeys[4] = y
    sumexps = Array{AffExpr, 1}([AffExpr()])  # sumexps[1] = vtransmissionbyline sum

    for row in DataFrames.eachrow(SQLite.query(db, "select n.val as n, ys.l as l, f.val as f, y.val as y,
    cast(ys.val as real) as ys, tl1.tr as tr, tl1.n2 as n2, tl2.tr as trneg, tl2.n1 as n1
    from NODE n, YearSplit_def ys, FUEL f, YEAR y, TransmissionModelingEnabled tme
    left join
    (select tl.id as tr, tl.n1 as n1, tl.n2 as n2, tl.f as f, tme2.y as y,
	tme2.type as type
    from TransmissionLine tl, NODE n2, TransmissionModelingEnabled tme2
    where tl.n2 = n2.val
    and n2.r = tme2.r and tl.f = tme2.f) tl1 on tl1.n1 = n.val and tl1.f = f.val and tl1.y = y.val
		and tl1.type = tme.type
    left join
    (select tl.id as tr, tl.n1 as n1, tl.n2 as n2, tl.f as f, tme2.y as y,
	tme2.type as type
    from TransmissionLine tl, NODE n2, TransmissionModelingEnabled tme2
    where tl.n1 = n2.val
    and n2.r = tme2.r and tl.f = tme2.f) tl2 on tl2.n2 = n.val and tl2.f = f.val and tl2.y = y.val
		and tl2.type = tme.type
	where ys.y = y.val
    and tme.r = n.r and tme.f = f.val and tme.y = y.val
    order by n.val, ys.l, f.val, y.val"))
        local n = row[:n]
        local l = row[:l]
        local f = row[:f]
        local y = row[:y]
        local tr = row[:tr]  # Transmission line for which n is from node (n1)
        local trneg = row[:trneg]  # # Transmission line for which n is to node (n2)

        if isassigned(lastkeys, 1) && (n != lastkeys[1] || l != lastkeys[2] || f != lastkeys[3] || y != lastkeys[4])
            # Create constraint
            eba11tr_energybalanceeachts5[constraintnum] = @constraint(jumpmodel, vproductionnodal[lastkeys[1],lastkeys[2],lastkeys[3],lastkeys[4]] >=
                vdemandnodal[lastkeys[1],lastkeys[2],lastkeys[3],lastkeys[4]] + vusenodal[lastkeys[1],lastkeys[2],lastkeys[3],lastkeys[4]] + sumexps[1])
            constraintnum += 1

            sumexps[1] = AffExpr()
        end

        if !ismissing(tr)
            append!(sumexps[1], vtransmissionbyline[tr,l,f,y] * row[:ys])
        end

        if !ismissing(trneg)
            append!(sumexps[1], -vtransmissionbyline[trneg,l,f,y] * row[:ys])
        end

        lastkeys[1] = n
        lastkeys[2] = l
        lastkeys[3] = f
        lastkeys[4] = y
    end

    # Create last constraint
    if isassigned(lastkeys, 1)
        eba11tr_energybalanceeachts5[constraintnum] = @constraint(jumpmodel, vproductionnodal[lastkeys[1],lastkeys[2],lastkeys[3],lastkeys[4]] >=
            vdemandnodal[lastkeys[1],lastkeys[2],lastkeys[3],lastkeys[4]] + vusenodal[lastkeys[1],lastkeys[2],lastkeys[3],lastkeys[4]] + sumexps[1])
    end

    logmsg("Created constraint EBa11Tr_EnergyBalanceEachTS5.", quiet)
end
# END: EBa11Tr_EnergyBalanceEachTS5.

# BEGIN: EBb1_EnergyBalanceEachYear1.
constraintnum = 1  # Number of next constraint to be added to constraint array
@constraintref ebb1_energybalanceeachyear1[1:length(sregion) * length(sfuel) * length(syear)]

for (r, f, y) in Base.product(sregion, sfuel, syear)
    ebb1_energybalanceeachyear1[constraintnum] = @constraint(jumpmodel, sum([vproductionnn[r,l,f,y] for l = stimeslice]) == vproductionannualnn[r,f,y])
    constraintnum += 1
end

logmsg("Created constraint EBb1_EnergyBalanceEachYear1.", quiet)
# END: EBb1_EnergyBalanceEachYear1.

# BEGIN: EBb1Tr_EnergyBalanceEachYear1.
if transmissionmodeling
    constraintnum = 1  # Number of next constraint to be added to constraint array
    @constraintref ebb1tr_energybalanceeachyear1[1:length(snode) * length(sfuel) * length(syear)]

    for (n, f, y) in Base.product(snode, sfuel, syear)
        ebb1tr_energybalanceeachyear1[constraintnum] = @constraint(jumpmodel, sum([vproductionnodal[n,l,f,y] for l = stimeslice]) == vproductionannualnodal[n,f,y])
        constraintnum += 1
    end

    logmsg("Created constraint EBb1Tr_EnergyBalanceEachYear1.", quiet)
end
# END: EBb1Tr_EnergyBalanceEachYear1.

# BEGIN: EBb2_EnergyBalanceEachYear2.
constraintnum = 1  # Number of next constraint to be added to constraint array
@constraintref ebb2_energybalanceeachyear2[1:length(sregion) * length(sfuel) * length(syear)]

for (r, f, y) in Base.product(sregion, sfuel, syear)
    ebb2_energybalanceeachyear2[constraintnum] = @constraint(jumpmodel, sum([vusenn[r,l,f,y] for l = stimeslice]) == vuseannualnn[r,f,y])
    constraintnum += 1
end

logmsg("Created constraint EBb2_EnergyBalanceEachYear2.", quiet)
# END: EBb2_EnergyBalanceEachYear2.

# BEGIN: EBb2Tr_EnergyBalanceEachYear2.
if transmissionmodeling
    constraintnum = 1  # Number of next constraint to be added to constraint array
    @constraintref ebb2tr_energybalanceeachyear2[1:length(snode) * length(sfuel) * length(syear)]

    for (n, f, y) in Base.product(snode, sfuel, syear)
        ebb2tr_energybalanceeachyear2[constraintnum] = @constraint(jumpmodel, sum([vusenodal[n,l,f,y] for l = stimeslice]) == vuseannualnodal[n,f,y])
        constraintnum += 1
    end

    logmsg("Created constraint EBb2Tr_EnergyBalanceEachYear2.", quiet)
end
# END: EBb2Tr_EnergyBalanceEachYear2.

# BEGIN: EBb3_EnergyBalanceEachYear3.
constraintnum = 1  # Number of next constraint to be added to constraint array
@constraintref ebb3_energybalanceeachyear3[1:length(sregion) * length(sfuel) * length(syear)]

for (r, rr, f, y) in Base.product(sregion, sregion, sfuel, syear)
    ebb3_energybalanceeachyear3[constraintnum] = @constraint(jumpmodel, sum([vtrade[r,rr,l,f,y] for l = stimeslice]) == vtradeannual[r,rr,f,y])
    constraintnum += 1
end

logmsg("Created constraint EBb3_EnergyBalanceEachYear3.", quiet)
# END: EBb3_EnergyBalanceEachYear3.

# BEGIN: EBb4_EnergyBalanceEachYear4.
constraintnum = 1  # Number of next constraint to be added to constraint array
@constraintref ebb4_energybalanceeachyear4[1:length(sregion) * length(sfuel) * length(syear)]

lastkeys = Array{String, 1}(undef,3)  # lastkeys[1] = r, lastkeys[2] = f, lastkeys[3] = y
lastvals = Array{Float64, 1}([0.0])  # lastvals[1] = aad
sumexps = Array{AffExpr, 1}([AffExpr()])  # sumexps[1] = vtradeannual sum

for row in DataFrames.eachrow(SQLite.query(db, "select r.val as r, f.val as f, y.val as y, cast(aad.val as real) as aad,
    tr.rr as rr, cast(tr.val as real) as trv
from region r, fuel f, year y
left join traderoute_def tr on tr.r = r.val and tr.f = f.val and tr.y = y.val
left join AccumulatedAnnualDemand_def aad on aad.r = r.val and aad.f = f.val and aad.y = y.val
left join TransmissionModelingEnabled tme on tme.r = r.val and tme.f = f.val and tme.y = y.val
where tme.id is null
order by r.val, f.val, y.val"))
    local r = row[:r]
    local f = row[:f]
    local y = row[:y]

    if isassigned(lastkeys, 1) && (r != lastkeys[1] || f != lastkeys[2] || y != lastkeys[3])
        # Create constraint
        ebb4_energybalanceeachyear4[constraintnum] = @constraint(jumpmodel, vproductionannualnn[lastkeys[1],lastkeys[2],lastkeys[3]] >=
            vuseannualnn[lastkeys[1],lastkeys[2],lastkeys[3]] + sumexps[1] + lastvals[1])
        constraintnum += 1

        sumexps[1] = AffExpr()
        lastvals[1] = 0.0
    end

    if !ismissing(row[:rr])
        append!(sumexps[1], vtradeannual[r,row[:rr],f,y] * row[:trv])
    end

    if !ismissing(row[:aad])
        lastvals[1] = row[:aad]
    end

    lastkeys[1] = r
    lastkeys[2] = f
    lastkeys[3] = y
end

# Create last constraint
if isassigned(lastkeys, 1)
    ebb4_energybalanceeachyear4[constraintnum] = @constraint(jumpmodel, vproductionannualnn[lastkeys[1],lastkeys[2],lastkeys[3]] >=
        vuseannualnn[lastkeys[1],lastkeys[2],lastkeys[3]] + sumexps[1] + lastvals[1])
end

logmsg("Created constraint EBb4_EnergyBalanceEachYear4.", quiet)
# END: EBb4_EnergyBalanceEachYear4.

# BEGIN: EBb4Tr_EnergyBalanceEachYear4.
# For nodal modeling, where there is not trade, this constraint accounts for AccumulatedAnnualDemand only.
if transmissionmodeling
    constraintnum = 1  # Number of next constraint to be added to constraint array
    @constraintref ebb4tr_energybalanceeachyear4[1:length(snode) * length(sfuel) * length(syear)]

    for row in DataFrames.eachrow(SQLite.query(db,
        "select ndd.n as n, ndd.f as f, ndd.y as y, cast(ndd.val as real) as ndd, cast(aad.val as real) as aad
        from NodalDistributionDemand_def ndd, NODE n, TransmissionModelingEnabled tme, AccumulatedAnnualDemand_def aad
        where
        ndd.n = n.val
        and tme.r = n.r and tme.f = ndd.f and tme.y = ndd.y
        and aad.r = n.r and aad.f = ndd.f and aad.y = ndd.y
        and aad.val > 0"))
        local n = row[:n]
        local f = row[:f]
        local y = row[:y]

        ebb4tr_energybalanceeachyear4[constraintnum] = @constraint(jumpmodel, vproductionannualnodal[n,f,y] >=
            vuseannualnodal[n,f,y] + row[:aad] * row[:ndd])
        constraintnum += 1
    end

    logmsg("Created constraint EBb4Tr_EnergyBalanceEachYear4.", quiet)
end
# END: EBb4Tr_EnergyBalanceEachYear4.

# BEGIN: Acc1_FuelProductionByTechnology.
if in("vproductionbytechnology", varstosavearr)
    constraintnum = 1  # Number of next constraint to be added to constraint array
    @constraintref acc1_fuelproductionbytechnology[1:size(queryvproductionbytechnologyindices)[1]]

    for row in DataFrames.eachrow(queryvrateofproductionbytechnologynn)
        local r = row[:r]
        local l = row[:l]
        local t = row[:t]
        local f = row[:f]
        local y = row[:y]

        acc1_fuelproductionbytechnology[constraintnum] = @constraint(jumpmodel, vrateofproductionbytechnologynn[r,l,t,f,y] * row[:ys] == vproductionbytechnology[r,l,t,f,y])
        constraintnum += 1
    end

    if transmissionmodeling
        lastkeys = Array{String, 1}(undef,5)  # lastkeys[1] = r, lastkeys[2] = l, lastkeys[3] = t, lastkeys[4] = f, lastkeys[5] = y
        sumexps = Array{AffExpr, 1}([AffExpr()])  # sumexps[1] = vrateofproductionbytechnologynodal sum

        for row in DataFrames.eachrow(queryvproductionbytechnologynodal)
            local r = row[:r]
            local l = row[:l]
            local t = row[:t]
            local f = row[:f]
            local y = row[:y]

            if isassigned(lastkeys, 1) && (r != lastkeys[1] || l != lastkeys[2] || t != lastkeys[3] || f != lastkeys[4] || y != lastkeys[5])
                # Create constraint
                acc1_fuelproductionbytechnology[constraintnum] = @constraint(jumpmodel, sumexps[1] ==
                    vproductionbytechnology[lastkeys[1],lastkeys[2],lastkeys[3],lastkeys[4],lastkeys[5]])
                constraintnum += 1

                sumexps[1] = AffExpr()
            end

            append!(sumexps[1], vrateofproductionbytechnologynodal[row[:n],l,t,f,y] * row[:ys])

            lastkeys[1] = r
            lastkeys[2] = l
            lastkeys[3] = t
            lastkeys[4] = f
            lastkeys[5] = y
        end

        # Create last constraint
        if isassigned(lastkeys, 1)
            acc1_fuelproductionbytechnology[constraintnum] = @constraint(jumpmodel, sumexps[1] ==
                vproductionbytechnology[lastkeys[1],lastkeys[2],lastkeys[3],lastkeys[4],lastkeys[5]])
        end
    end  # transmissionmodeling

    logmsg("Created constraint Acc1_FuelProductionByTechnology.", quiet)
end  # in("vproductionbytechnology", varstosavearr)
# END: Acc1_FuelProductionByTechnology.

# BEGIN: Acc2_FuelUseByTechnology.
if in("vusebytechnology", varstosavearr)
    constraintnum = 1  # Number of next constraint to be added to constraint array
    @constraintref acc2_fuelusebytechnology[1:size(queryvusebytechnologyindices)[1]]

    for row in DataFrames.eachrow(queryvrateofusebytechnologynn)
        local r = row[:r]
        local l = row[:l]
        local t = row[:t]
        local f = row[:f]
        local y = row[:y]

        acc2_fuelusebytechnology[constraintnum] = @constraint(jumpmodel, vrateofusebytechnologynn[r,l,t,f,y] * row[:ys] == vusebytechnology[r,l,t,f,y])
        constraintnum += 1
    end

    if transmissionmodeling
        lastkeys = Array{String, 1}(undef,5)  # lastkeys[1] = r, lastkeys[2] = l, lastkeys[3] = t, lastkeys[4] = f, lastkeys[5] = y
        sumexps = Array{AffExpr, 1}([AffExpr()])  # sumexps[1] = vrateofusebytechnologynodal sum

        for row in DataFrames.eachrow(queryvusebytechnologynodal)
            local r = row[:r]
            local l = row[:l]
            local t = row[:t]
            local f = row[:f]
            local y = row[:y]

            if isassigned(lastkeys, 1) && (r != lastkeys[1] || l != lastkeys[2] || t != lastkeys[3] || f != lastkeys[4] || y != lastkeys[5])
                # Create constraint
                acc2_fuelusebytechnology[constraintnum] = @constraint(jumpmodel, sumexps[1] ==
                    vusebytechnology[lastkeys[1],lastkeys[2],lastkeys[3],lastkeys[4],lastkeys[5]])
                constraintnum += 1

                sumexps[1] = AffExpr()
            end

            append!(sumexps[1], vrateofusebytechnologynodal[row[:n],l,t,f,y] * row[:ys])

            lastkeys[1] = r
            lastkeys[2] = l
            lastkeys[3] = t
            lastkeys[4] = f
            lastkeys[5] = y
        end

        # Create last constraint
        if isassigned(lastkeys, 1)
            acc2_fuelusebytechnology[constraintnum] = @constraint(jumpmodel, sumexps[1] ==
                vusebytechnology[lastkeys[1],lastkeys[2],lastkeys[3],lastkeys[4],lastkeys[5]])
        end
    end  # transmissionmodeling

    logmsg("Created constraint Acc2_FuelUseByTechnology.", quiet)
end  # in("vusebytechnology", varstosavearr)
# END: Acc2_FuelUseByTechnology.

# BEGIN: Acc3_AverageAnnualRateOfActivity.
constraintnum = 1  # Number of next constraint to be added to constraint array
@constraintref acc3_averageannualrateofactivity[1:length(sregion) * length(stechnology) * length(smode_of_operation) * length(syear)]

lastkeys = Array{String, 1}(undef,4)  # lastkeys[1] = r, lastkeys[2] = t, lastkeys[3] = m, lastkeys[4] = y
sumexps = Array{AffExpr, 1}([AffExpr()])  # sumexps[1] = vrateofactivity sum

for row in DataFrames.eachrow(SQLite.query(db, "select r.val as r, t.val as t, m.val as m, y.val as y, ys.l as l, cast(ys.val as real) as ys
from region r, technology t, mode_of_operation m, year y, YearSplit_def ys
where ys.y = y.val
order by r.val, t.val, m.val, y.val"))
    local r = row[:r]
    local t = row[:t]
    local m = row[:m]
    local y = row[:y]

    if isassigned(lastkeys, 1) && (r != lastkeys[1] || t != lastkeys[2] || m != lastkeys[3] || y != lastkeys[4])
        # Create constraint
        acc3_averageannualrateofactivity[constraintnum] = @constraint(jumpmodel, sumexps[1] ==
            vtotalannualtechnologyactivitybymode[lastkeys[1],lastkeys[2],lastkeys[3],lastkeys[4]])
        constraintnum += 1

        sumexps[1] = AffExpr()
    end

    append!(sumexps[1], vrateofactivity[r,row[:l],t,m,y] * row[:ys])

    lastkeys[1] = r
    lastkeys[2] = t
    lastkeys[3] = m
    lastkeys[4] = y
end

# Create last constraint
if isassigned(lastkeys, 1)
    acc3_averageannualrateofactivity[constraintnum] = @constraint(jumpmodel, sumexps[1] ==
        vtotalannualtechnologyactivitybymode[lastkeys[1],lastkeys[2],lastkeys[3],lastkeys[4]])
end

logmsg("Created constraint Acc3_AverageAnnualRateOfActivity.", quiet)
# END: Acc3_AverageAnnualRateOfActivity.

# BEGIN: Acc4_ModelPeriodCostByRegion.
if in("vmodelperiodcostbyregion", varstosavearr)
    constraintnum = 1  # Number of next constraint to be added to constraint array
    @constraintref acc4_modelperiodcostbyregion[1:length(sregion)]

    for r in sregion
        acc4_modelperiodcostbyregion[constraintnum] = @constraint(jumpmodel, sum([vtotaldiscountedcost[r,y] for y in syear]) == vmodelperiodcostbyregion[r])
        constraintnum += 1
    end

    logmsg("Created constraint Acc4_ModelPeriodCostByRegion.", quiet)
end
# END: Acc4_ModelPeriodCostByRegion.

# BEGIN: NS1_RateOfStorageCharge.
# vrateofstoragecharge is in terms of energy output/year (e.g., PJ/yr, depending on CapacityToActivityUnit)
constraintnum = 1  # Number of next constraint to be added to constraint array
@constraintref ns1_rateofstoragecharge[1:length(sregion) * length(sstorage) * length(stimeslice) * length(syear)]

lastkeys = Array{String, 1}(undef,4)  # lastkeys[1] = r, lastkeys[2] = s, lastkeys[3] = l, lastkeys[4] = y
sumexps = Array{AffExpr, 1}([AffExpr()])
# sumexps[1] = vrateofactivity sum

for row in DataFrames.eachrow(SQLite.query(db, "select r.val as r, s.val as s, l.val as l, y.val as y, tts.m as m, tts.t as t
from region r, storage s, TIMESLICE l, year y, TechnologyToStorage_def tts
where
tts.r = r.val and tts.s = s.val and tts.val = 1
order by r.val, s.val, l.val, y.val"))
    local r = row[:r]
    local s = row[:s]
    local l = row[:l]
    local y = row[:y]

    if isassigned(lastkeys, 1) && (r != lastkeys[1] || s != lastkeys[2] || l != lastkeys[3] || y != lastkeys[4])
        # Create constraint
        ns1_rateofstoragecharge[constraintnum] = @constraint(jumpmodel, sumexps[1] ==
            vrateofstoragecharge[lastkeys[1],lastkeys[2],lastkeys[3],lastkeys[4]])
        constraintnum += 1

        sumexps[1] = AffExpr()
    end

    append!(sumexps[1], vrateofactivity[r,l,row[:t],row[:m],y])

    lastkeys[1] = r
    lastkeys[2] = s
    lastkeys[3] = l
    lastkeys[4] = y
end

# Create last constraint
if isassigned(lastkeys, 1)
    ns1_rateofstoragecharge[constraintnum] = @constraint(jumpmodel, sumexps[1] ==
        vrateofstoragecharge[lastkeys[1],lastkeys[2],lastkeys[3],lastkeys[4]])
end

logmsg("Created constraint NS1_RateOfStorageCharge.", quiet)
# END: NS1_RateOfStorageCharge.

# BEGIN: NS2_RateOfStorageDischarge.
# vrateofstoragedischarge is in terms of energy output/year (e.g., PJ/yr, depending on CapacityToActivityUnit)
constraintnum = 1  # Number of next constraint to be added to constraint array
@constraintref ns2_rateofstoragedischarge[1:length(sregion) * length(sstorage) * length(stimeslice) * length(syear)]

lastkeys = Array{String, 1}(undef,4)  # lastkeys[1] = r, lastkeys[2] = s, lastkeys[3] = l, lastkeys[4] = y
sumexps = Array{AffExpr, 1}([AffExpr()])
# sumexps[1] = vrateofactivity sum

for row in DataFrames.eachrow(SQLite.query(db, "select r.val as r, s.val as s, l.val as l, y.val as y, tfs.m as m, tfs.t as t
from region r, storage s, TIMESLICE l, year y, TechnologyFromStorage_def tfs
where
tfs.r = r.val and tfs.s = s.val and tfs.val = 1
order by r.val, s.val, l.val, y.val"))
    local r = row[:r]
    local s = row[:s]
    local l = row[:l]
    local y = row[:y]

    if isassigned(lastkeys, 1) && (r != lastkeys[1] || s != lastkeys[2] || l != lastkeys[3] || y != lastkeys[4])
        # Create constraint
        ns2_rateofstoragedischarge[constraintnum] = @constraint(jumpmodel, sumexps[1] ==
            vrateofstoragedischarge[lastkeys[1],lastkeys[2],lastkeys[3],lastkeys[4]])
        constraintnum += 1

        sumexps[1] = AffExpr()
    end

    append!(sumexps[1], vrateofactivity[r,l,row[:t],row[:m],y])

    lastkeys[1] = r
    lastkeys[2] = s
    lastkeys[3] = l
    lastkeys[4] = y
end

# Create last constraint
if isassigned(lastkeys, 1)
    ns2_rateofstoragedischarge[constraintnum] = @constraint(jumpmodel, sumexps[1] ==
        vrateofstoragedischarge[lastkeys[1],lastkeys[2],lastkeys[3],lastkeys[4]])
end

logmsg("Created constraint NS2_RateOfStorageDischarge.", quiet)
# END: NS2_RateOfStorageDischarge.

# BEGIN: NS3_StorageLevelTsGroup1Start, NS4_StorageLevelTsGroup2Start, NS5_StorageLevelTimesliceEnd.
# Note that vstorageleveltsend represents storage level (in energy terms) at end of first hour in time slice
constraintnum = 1  # Number of next constraint to be added to constraint array
constraint2num::Int, constraint3num::Int = 1, 1  # Supplemental constraint counters needed because three constraints are defined in subsequent loop
@constraintref ns3_storageleveltsgroup1start[1:length(sregion) * length(sstorage) * length(stsgroup1) * length(syear)]
@constraintref ns4_storageleveltsgroup2start[1:length(sregion) * length(sstorage) * length(stsgroup1) * length(stsgroup2) * length(syear)]
@constraintref ns5_storageleveltimesliceend[1:length(sregion) * length(sstorage) * length(stimeslice) * length(syear)]

for row in DataFrames.eachrow(SQLite.query(db, "select r.val as r, s.val as s, ltg.l as l, y.val as y, ltg.lorder as lo,
    ltg.tg2 as tg2, tg2.[order] as tg2o, ltg.tg1 as tg1, tg1.[order] as tg1o, cast(sls.val as real) as sls
from REGION r, STORAGE s, YEAR y, LTsGroup ltg, TSGROUP2 tg2, TSGROUP1 tg1
left join StorageLevelStart_def sls on sls.r = r.val and sls.s = s.val
where
ltg.tg2 = tg2.name
and ltg.tg1 = tg1.name"))
    local r = row[:r]
    local s = row[:s]
    local l = row[:l]
    local y = row[:y]
    local tg1 = row[:tg1]
    local tg2 = row[:tg2]
    local lo = row[:lo]
    local tg2o = row[:tg2o]
    local tg1o = row[:tg1o]
    local startlevel  # Storage level at beginning of first hour in time slice
    local addns3::Bool = false  # Indicates whether to add to constraint ns3
    local addns4::Bool = false  #  Indicates whether to add to constraint ns4

    if y == first(syear) && tg1o == 1 && tg2o == 1 && lo == 1
        startlevel = ismissing(row[:sls]) ? 0 : row[:sls]
        addns3 = true
        addns4 = true
    elseif tg1o == 1 && tg2o == 1 && lo == 1
        startlevel = vstoragelevelyearend[r, s, string(Meta.parse(y)-1)]
        addns3 = true
        addns4 = true
    elseif tg2o == 1 && lo == 1
        startlevel = vstorageleveltsgroup1end[r, s, tsgroup1dict[tg1o-1][1], y]
        addns3 = true
        addns4 = true
    elseif lo == 1
        startlevel = vstorageleveltsgroup2end[r, s, tg1, tsgroup2dict[tg2o-1][1], y]
        addns4 = true
    else
        startlevel = vstorageleveltsend[r, s, ltsgroupdict[(tg1o, tg2o, lo-1)], y]
    end

    if addns3
        ns3_storageleveltsgroup1start[constraintnum] = @constraint(jumpmodel, startlevel == vstorageleveltsgroup1start[r, s, tg1, y])
        constraintnum += 1
    end

    if addns4
        ns4_storageleveltsgroup2start[constraint2num] = @constraint(jumpmodel, startlevel == vstorageleveltsgroup2start[r, s, tg1, tg2, y])
        constraint2num += 1
    end

    ns5_storageleveltimesliceend[constraint3num] = @constraint(jumpmodel,
        startlevel + (vrateofstoragecharge[r, s, l, y] - vrateofstoragedischarge[r, s, l, y]) / 8760 == vstorageleveltsend[r, s, l, y])
    constraint3num += 1
end
logmsg("Created constraints NS3_StorageLevelTsGroup1Start, NS4_StorageLevelTsGroup2Start, and NS5_StorageLevelTimesliceEnd.", quiet)
# BEGIN: NS3_StorageLevelTsGroup1Start, NS4_StorageLevelTsGroup2Start, NS5_StorageLevelTimesliceEnd.

# BEGIN: NS6_StorageLevelTsGroup2End.
constraintnum = 1  # Number of next constraint to be added to constraint array
@constraintref ns6_storageleveltsgroup2end[1:length(sregion) * length(sstorage) * length(stsgroup1) * length(stsgroup2) * length(syear)]

for row in DataFrames.eachrow(SQLite.query(db, "select main.r, main.s, main.tg1, main.tg1o, main.tg2, main.tg2o, cast(main.tg2m as real) as tg2m,
    main.y, ltg2.l as maxl, main.maxlo
from
(select r.val as r, s.val as s, tg1.name as tg1, tg1.[order] as tg1o, tg2.name as tg2, tg2.[order] as tg2o, tg2.multiplier as tg2m,
y.val as y, max(ltg.lorder) as maxlo
from REGION r, STORAGE s, TSGROUP1 tg1, TSGROUP2 tg2, YEAR as y, LTsGroup ltg
where
tg1.name = ltg.tg1
and tg2.name = ltg.tg2
group by r.val, s.val, tg1.name, tg1.[order], tg2.name, tg2.[order], tg2.multiplier, y.val) main, LTsGroup ltg2
where
ltg2.tg1 = main.tg1
and ltg2.tg2 = main.tg2
and ltg2.lorder = main.maxlo"))
    local r = row[:r]
    local s = row[:s]
    local tg1 = row[:tg1]
    local tg2 = row[:tg2]
    local y = row[:y]

    ns6_storageleveltsgroup2end[constraintnum] = @constraint(jumpmodel, vstorageleveltsgroup2start[r, s, tg1, tg2, y] +
        (vstorageleveltsend[r, s, row[:maxl], y] - vstorageleveltsgroup2start[r, s, tg1, tg2, y]) * row[:tg2m]
        == vstorageleveltsgroup2end[r, s, tg1, tg2, y])
    constraintnum += 1
end
logmsg("Created constraint NS6_StorageLevelTsGroup2End.", quiet)
# END: NS6_StorageLevelTsGroup2End.

# BEGIN: NS7_StorageLevelTsGroup1End.
constraintnum = 1  # Number of next constraint to be added to constraint array
@constraintref ns7_storageleveltsgroup1end[1:length(sregion) * length(sstorage) * length(stsgroup1) * length(syear)]

for row in DataFrames.eachrow(SQLite.query(db, "select r.val as r, s.val as s, tg1.name as tg1, tg1.[order] as tg1o, cast(tg1.multiplier as real) as tg1m,
    y.val as y, max(tg2.[order]) as maxtg2o
from REGION r, STORAGE s, TSGROUP1 tg1, YEAR as y, LTsGroup ltg, TSGROUP2 tg2
where
tg1.name = ltg.tg1
and ltg.tg2 = tg2.name
group by r.val, s.val, tg1.name, tg1.[order], tg1.multiplier, y.val"))
    local r = row[:r]
    local s = row[:s]
    local tg1 = row[:tg1]
    local y = row[:y]

    ns7_storageleveltsgroup1end[constraintnum] = @constraint(jumpmodel, vstorageleveltsgroup1start[r, s, tg1, y] +
        (vstorageleveltsgroup2end[r, s, tg1, tsgroup2dict[row[:maxtg2o]][1], y] - vstorageleveltsgroup1start[r, s, tg1, y]) * row[:tg1m]
        == vstorageleveltsgroup1end[r, s, tg1, y])
    constraintnum += 1
end
logmsg("Created constraint NS7_StorageLevelTsGroup1End.", quiet)
# END: NS7_StorageLevelTsGroup1End.

# BEGIN: NS8_StorageLevelYearEnd.
constraintnum = 1  # Number of next constraint to be added to constraint array
@constraintref ns8_storagelevelyearend[1:length(sregion) * length(sstorage) * length(syear)]

lastkeys = Array{String, 1}(undef,3)  # lastkeys[1] = r, lastkeys[2] = s, lastkeys[3] = y
lastvals = Array{Float64, 1}([0.0])  # lastvals[1] = sls
sumexps = Array{AffExpr, 1}([AffExpr()])
# sumexps[1] = vrateofstoragecharge and vrateofstoragedischarge sum

for row in DataFrames.eachrow(SQLite.query(db, "select r.val as r, s.val as s, y.val as y, ys.l as l, cast(ys.val as real) as ys,
cast(sls.val as real) as sls
from REGION r, STORAGE s, YEAR as y, YearSplit_def ys
left join StorageLevelStart_def sls on sls.r = r.val and sls.s = s.val
where y.val = ys.y
order by r.val, s.val, y.val"))
    local r = row[:r]
    local s = row[:s]
    local y = row[:y]

    if isassigned(lastkeys, 1) && (r != lastkeys[1] || s != lastkeys[2] || y != lastkeys[3])
        # Create constraint
        ns8_storagelevelyearend[constraintnum] = @constraint(jumpmodel,
            (lastkeys[3] == first(syear) ? lastvals[1] : vstoragelevelyearend[lastkeys[1], lastkeys[2], string(Meta.parse(lastkeys[3])-1)])
            + sumexps[1] == vstoragelevelyearend[lastkeys[1], lastkeys[2], lastkeys[3]])
        constraintnum += 1

        sumexps[1] = AffExpr()
        lastvals[1] = 0.0
    end

    append!(sumexps[1], (vrateofstoragecharge[r,s,row[:l],y] - vrateofstoragedischarge[r,s,row[:l],y]) * row[:ys])

    if !ismissing(row[:sls])
        lastvals[1] = row[:sls]
    end

    lastkeys[1] = r
    lastkeys[2] = s
    lastkeys[3] = y
end

# Create last constraint
if isassigned(lastkeys, 1)
    ns8_storagelevelyearend[constraintnum] = @constraint(jumpmodel,
        (lastkeys[3] == first(syear) ? lastvals[1] : vstoragelevelyearend[lastkeys[1], lastkeys[2], string(Meta.parse(lastkeys[3])-1)])
        + sumexps[1] == vstoragelevelyearend[lastkeys[1], lastkeys[2], lastkeys[3]])
end

logmsg("Created constraint NS8_StorageLevelYearEnd.", quiet)
# END: NS8_StorageLevelYearEnd.

# BEGIN: SI1_StorageUpperLimit.
constraintnum = 1  # Number of next constraint to be added to constraint array

@constraintref si1_storageupperlimit[1:length(sregion) * length(sstorage) * length(syear)]

for row in DataFrames.eachrow(SQLite.query(db, "select r.val as r, s.val as s, y.val as y, cast(rsc.val as real) as rsc
from region r, storage s, year y
left join ResidualStorageCapacity_def rsc on rsc.r = r.val and rsc.s = s.val and rsc.y = y.val"))
    local r = row[:r]
    local s = row[:s]
    local y = row[:y]

    si1_storageupperlimit[constraintnum] = @constraint(jumpmodel, vaccumulatednewstoragecapacity[r,s,y] + (ismissing(row[:rsc]) ? 0 : row[:rsc]) == vstorageupperlimit[r,s,y])
    constraintnum += 1
end

logmsg("Created constraint SI1_StorageUpperLimit.", quiet)
# END: SI1_StorageUpperLimit.

# BEGIN: SI2_StorageLowerLimit.
constraintnum = 1  # Number of next constraint to be added to constraint array

@constraintref si2_storagelowerlimit[1:length(sregion) * length(sstorage) * length(syear)]

for row in DataFrames.eachrow(SQLite.query(db, "select r.val as r, s.val as s, y.val as y, cast(msc.val as real) as msc
from region r, storage s, year y, MinStorageCharge_def msc
where msc.r = r.val and msc.s = s.val and msc.y = y.val"))
    local r = row[:r]
    local s = row[:s]
    local y = row[:y]

    si2_storagelowerlimit[constraintnum] = @constraint(jumpmodel, row[:msc] * vstorageupperlimit[r,s,y] == vstoragelowerlimit[r,s,y])
    constraintnum += 1
end

logmsg("Created constraint SI2_StorageLowerLimit.", quiet)
# END: SI2_StorageLowerLimit.

# BEGIN: SI3_TotalNewStorage.
constraintnum = 1  # Number of next constraint to be added to constraint array
@constraintref si3_totalnewstorage[1:length(sregion) * length(sstorage) * length(syear)]

lastkeys = Array{String, 1}(undef,3)  # lastkeys[1] = r, lastkeys[2] = s, lastkeys[3] = y
sumexps = Array{AffExpr, 1}([AffExpr()])
# sumexps[1] = vnewstoragecapacity sum

for row in DataFrames.eachrow(SQLite.query(db, "select r.val as r, s.val as s, y.val as y, cast(ols.val as real) as ols, yy.val as yy
from region r, storage s, year y, OperationalLifeStorage_def ols, year yy
where ols.r = r.val and ols.s = s.val
and y.val - yy.val < ols.val and y.val - yy.val >= 0
order by r.val, s.val, y.val"))
    local r = row[:r]
    local s = row[:s]
    local y = row[:y]

    if isassigned(lastkeys, 1) && (r != lastkeys[1] || s != lastkeys[2] || y != lastkeys[3])
        # Create constraint
        si3_totalnewstorage[constraintnum] = @constraint(jumpmodel, sumexps[1] ==
            vaccumulatednewstoragecapacity[lastkeys[1],lastkeys[2],lastkeys[3]])
        constraintnum += 1

        sumexps[1] = AffExpr()
    end

    append!(sumexps[1], vnewstoragecapacity[r,s,row[:yy]])

    lastkeys[1] = r
    lastkeys[2] = s
    lastkeys[3] = y
end

# Create last constraint
if isassigned(lastkeys, 1)
    si3_totalnewstorage[constraintnum] = @constraint(jumpmodel, sumexps[1] ==
        vaccumulatednewstoragecapacity[lastkeys[1],lastkeys[2],lastkeys[3]])
end

logmsg("Created constraint SI3_TotalNewStorage.", quiet)
# END: SI3_TotalNewStorage.

# BEGIN: NS9a_StorageLevelTsLowerLimit and NS9b_StorageLevelTsUpperLimit.
constraintnum = 1  # Number of next constraint to be added to constraint array

@constraintref ns9a_storageleveltslowerlimit[1:length(sregion) * length(sstorage) * length(stimeslice) * length(syear)]
@constraintref ns9b_storageleveltsupperlimit[1:length(sregion) * length(sstorage) * length(stimeslice) * length(syear)]

for (r, s, l, y) in Base.product(sregion, sstorage, stimeslice, syear)
    ns9a_storageleveltslowerlimit[constraintnum] = @constraint(jumpmodel, vstoragelowerlimit[r,s,y] <= vstorageleveltsend[r,s,l,y])
    ns9b_storageleveltsupperlimit[constraintnum] = @constraint(jumpmodel, vstorageleveltsend[r,s,l,y] <= vstorageupperlimit[r,s,y])
    constraintnum += 1
end

logmsg("Created constraints NS9a_StorageLevelTsLowerLimit and NS9b_StorageLevelTsUpperLimit.", quiet)
# END: NS9a_StorageLevelTsLowerLimit and NS9b_StorageLevelTsUpperLimit.

# BEGIN: NS10_StorageChargeLimit.
constraintnum = 1  # Number of next constraint to be added to constraint array

@constraintref ns10_storagechargelimit[1:length(sregion) * length(sstorage) * length(stimeslice) * length(syear)]

for row in DataFrames.eachrow(SQLite.query(db, "select r.val as r, s.val as s, l.val as l, y.val as y, cast(smc.val as real) as smc
from region r, storage s, TIMESLICE l, year y, StorageMaxChargeRate_def smc
where
r.val = smc.r
and s.val = smc.s"))
    ns10_storagechargelimit[constraintnum] = @constraint(jumpmodel, vrateofstoragecharge[row[:r], row[:s], row[:l], row[:y]] <= row[:smc])
    constraintnum += 1
end

logmsg("Created constraint NS10_StorageChargeLimit.", quiet)
# END: NS10_StorageChargeLimit.

# BEGIN: NS11_StorageDischargeLimit.
constraintnum = 1  # Number of next constraint to be added to constraint array

@constraintref ns11_storagedischargelimit[1:length(sregion) * length(sstorage) * length(stimeslice) * length(syear)]

for row in DataFrames.eachrow(SQLite.query(db, "select r.val as r, s.val as s, l.val as l, y.val as y, cast(smd.val as real) as smd
from region r, storage s, TIMESLICE l, year y, StorageMaxDischargeRate_def smd
where
r.val = smd.r
and s.val = smd.s"))
    ns11_storagedischargelimit[constraintnum] = @constraint(jumpmodel, vrateofstoragedischarge[row[:r], row[:s], row[:l], row[:y]] <= row[:smd])
    constraintnum += 1
end

logmsg("Created constraint NS11_StorageDischargeLimit.", quiet)
# END: NS11_StorageDischargeLimit.

# BEGIN: NS12a_StorageLevelTsGroup2LowerLimit and NS12b_StorageLevelTsGroup2UpperLimit.
constraintnum = 1  # Number of next constraint to be added to constraint array

@constraintref ns12a_storageleveltsgroup2lowerlimit[1:length(sregion) * length(sstorage) * length(stsgroup1) * length(stsgroup2) * length(syear)]
@constraintref ns12b_storageleveltsgroup2upperlimit[1:length(sregion) * length(sstorage) * length(stsgroup1) * length(stsgroup2) * length(syear)]

for (r, s, tg1, tg2, y) in Base.product(sregion, sstorage, stsgroup1, stsgroup2, syear)
    ns12a_storageleveltsgroup2lowerlimit[constraintnum] = @constraint(jumpmodel, vstoragelowerlimit[r,s,y] <= vstorageleveltsgroup2end[r,s,tg1,tg2,y])
    ns12b_storageleveltsgroup2upperlimit[constraintnum] = @constraint(jumpmodel, vstorageleveltsgroup2end[r,s,tg1,tg2,y] <= vstorageupperlimit[r,s,y])
    constraintnum += 1
end

logmsg("Created constraints NS12a_StorageLevelTsGroup2LowerLimit and NS12b_StorageLevelTsGroup2UpperLimit.", quiet)
# END: NS12a_StorageLevelTsGroup2LowerLimit and NS12b_StorageLevelTsGroup2UpperLimit.

# BEGIN: NS13a_StorageLevelTsGroup1LowerLimit and NS13b_StorageLevelTsGroup1UpperLimit.
constraintnum = 1  # Number of next constraint to be added to constraint array

@constraintref ns13a_storageleveltsgroup1lowerlimit[1:length(sregion) * length(sstorage) * length(stsgroup1) * length(syear)]
@constraintref ns13b_storageleveltsgroup1upperlimit[1:length(sregion) * length(sstorage) * length(stsgroup1) * length(syear)]

for (r, s, tg1, y) in Base.product(sregion, sstorage, stsgroup1, syear)
    ns13a_storageleveltsgroup1lowerlimit[constraintnum] = @constraint(jumpmodel, vstoragelowerlimit[r,s,y] <= vstorageleveltsgroup1end[r,s,tg1,y])
    ns13b_storageleveltsgroup1upperlimit[constraintnum] = @constraint(jumpmodel, vstorageleveltsgroup1end[r,s,tg1,y] <= vstorageupperlimit[r,s,y])
    constraintnum += 1
end

logmsg("Created constraints NS13a_StorageLevelTsGroup1LowerLimit and NS13b_StorageLevelTsGroup1UpperLimit.", quiet)
# END: NS13a_StorageLevelTsGroup2LowerLimit and NS13b_StorageLevelTsGroup2UpperLimit.

# BEGIN: NS14_MaxStorageCapacity.
constraintnum = 1  # Number of next constraint to be added to constraint array

@constraintref ns14_maxstoragecapacity[1:length(sregion) * length(sstorage) * length(syear)]

for row in DataFrames.eachrow(SQLite.query(db, "select smc.r, smc.s, smc.y, cast(smc.val as real) as smc
from TotalAnnualMaxCapacityStorage_def smc"))
    ns14_maxstoragecapacity[constraintnum] = @constraint(jumpmodel, vstorageupperlimit[row[:r],row[:s],row[:y]] <= row[:smc])
    constraintnum += 1
end

logmsg("Created constraint NS14_MaxStorageCapacity.", quiet)
# END: NS14_MaxStorageCapacity.

# BEGIN: NS15_MinStorageCapacity.
constraintnum = 1  # Number of next constraint to be added to constraint array

@constraintref ns15_minstoragecapacity[1:length(sregion) * length(sstorage) * length(syear)]

for row in DataFrames.eachrow(SQLite.query(db, "select smc.r, smc.s, smc.y, cast(smc.val as real) as smc
from TotalAnnualMinCapacityStorage_def smc"))
    ns15_minstoragecapacity[constraintnum] = @constraint(jumpmodel, row[:smc] <= vstorageupperlimit[row[:r],row[:s],row[:y]])
    constraintnum += 1
end

logmsg("Created constraint NS15_MinStorageCapacity.", quiet)
# END: NS15_MinStorageCapacity.

# BEGIN: NS16_MaxStorageCapacityInvestment.
constraintnum = 1  # Number of next constraint to be added to constraint array

@constraintref ns16_maxstoragecapacityinvestment[1:length(sregion) * length(sstorage) * length(syear)]

for row in DataFrames.eachrow(SQLite.query(db, "select smc.r, smc.s, smc.y, cast(smc.val as real) as smc
from TotalAnnualMaxCapacityInvestmentStorage_def smc"))
    ns16_maxstoragecapacityinvestment[constraintnum] = @constraint(jumpmodel, vnewstoragecapacity[row[:r],row[:s],row[:y]] <= row[:smc])
    constraintnum += 1
end

logmsg("Created constraint NS16_MaxStorageCapacityInvestment.", quiet)
# END: NS16_MaxStorageCapacityInvestment.

# BEGIN: NS17_MinStorageCapacityInvestment.
constraintnum = 1  # Number of next constraint to be added to constraint array

@constraintref ns17_minstoragecapacityinvestment[1:length(sregion) * length(sstorage) * length(syear)]

for row in DataFrames.eachrow(SQLite.query(db, "select smc.r, smc.s, smc.y, cast(smc.val as real) as smc
from TotalAnnualMinCapacityInvestmentStorage_def smc"))
    ns17_minstoragecapacityinvestment[constraintnum] = @constraint(jumpmodel, row[:smc] <= vnewstoragecapacity[row[:r],row[:s],row[:y]])
    constraintnum += 1
end

logmsg("Created constraint NS17_MinStorageCapacityInvestment.", quiet)
# END: NS17_MinStorageCapacityInvestment.

# BEGIN: SI4_UndiscountedCapitalInvestmentStorage.
constraintnum = 1  # Number of next constraint to be added to constraint array

@constraintref si4_undiscountedcapitalinvestmentstorage[1:length(sregion) * length(sstorage) * length(syear)]

for row in DataFrames.eachrow(SQLite.query(db, "select r.val as r, s.val as s, y.val as y, cast(ccs.val as real) as ccs
from region r, storage s, year y, CapitalCostStorage_def ccs
where ccs.r = r.val and ccs.s = s.val and ccs.y = y.val"))
    local r = row[:r]
    local s = row[:s]
    local y = row[:y]

    si4_undiscountedcapitalinvestmentstorage[constraintnum] = @constraint(jumpmodel, row[:ccs] * vnewstoragecapacity[r,s,y] == vcapitalinvestmentstorage[r,s,y])
    constraintnum += 1
end

logmsg("Created constraint SI4_UndiscountedCapitalInvestmentStorage.", quiet)
# END: SI4_UndiscountedCapitalInvestmentStorage.

# BEGIN: SI5_DiscountingCapitalInvestmentStorage.
constraintnum = 1  # Number of next constraint to be added to constraint array
@constraintref si5_discountingcapitalinvestmentstorage[1:length(sregion) * length(sstorage) * length(syear)]

for row in DataFrames.eachrow(SQLite.query(db, "select r.val as r, s.val as s, y.val as y, cast(dr.val as real) as dr
from region r, storage s, year y, DiscountRate_def dr
where dr.r = r.val"))
    local r = row[:r]
    local s = row[:s]
    local y = row[:y]

    si5_discountingcapitalinvestmentstorage[constraintnum] = @constraint(jumpmodel, vcapitalinvestmentstorage[r,s,y] / ((1 + row[:dr])^(Meta.parse(y) - Meta.parse(first(syear)))) == vdiscountedcapitalinvestmentstorage[r,s,y])
    constraintnum += 1
end

logmsg("Created constraint SI5_DiscountingCapitalInvestmentStorage.", quiet)
# END: SI5_DiscountingCapitalInvestmentStorage.

# BEGIN: SI6_SalvageValueStorageAtEndOfPeriod1.
constraintnum = 1  # Number of next constraint to be added to constraint array

@constraintref si6_salvagevaluestorageatendofperiod1[1:length(sregion) * length(sstorage) * length(syear)]

for row in DataFrames.eachrow(SQLite.query(db, "select r.val as r, s.val as s, y.val as y
from region r, storage s, year y, OperationalLifeStorage_def ols
where ols.r = r.val and ols.s = s.val
and y.val + ols.val - 1 <= " * last(syear)))
    local r = row[:r]
    local s = row[:s]
    local y = row[:y]

    si6_salvagevaluestorageatendofperiod1[constraintnum] = @constraint(jumpmodel, 0 == vsalvagevaluestorage[r,s,y])
    constraintnum += 1
end

logmsg("Created constraint SI6_SalvageValueStorageAtEndOfPeriod1.", quiet)
# END: SI6_SalvageValueStorageAtEndOfPeriod1.

# BEGIN: SI7_SalvageValueStorageAtEndOfPeriod2.
constraintnum = 1  # Number of next constraint to be added to constraint array

@constraintref si7_salvagevaluestorageatendofperiod2[1:length(sregion) * length(sstorage) * length(syear)]

for row in DataFrames.eachrow(SQLite.query(db, "select r.val as r, s.val as s, y.val as y, cast(ols.val as real) as ols
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

    si7_salvagevaluestorageatendofperiod2[constraintnum] = @constraint(jumpmodel, vcapitalinvestmentstorage[r,s,y] * (1 - (Meta.parse(last(syear)) - Meta.parse(y) + 1) / row[:ols]) == vsalvagevaluestorage[r,s,y])
    constraintnum += 1
end

logmsg("Created constraint SI7_SalvageValueStorageAtEndOfPeriod2.", quiet)
# END: SI7_SalvageValueStorageAtEndOfPeriod2.

# BEGIN: SI8_SalvageValueStorageAtEndOfPeriod3.
constraintnum = 1  # Number of next constraint to be added to constraint array
@constraintref si8_salvagevaluestorageatendofperiod3[1:length(sregion) * length(sstorage) * length(syear)]

for row in DataFrames.eachrow(SQLite.query(db, "select r.val as r, s.val as s, y.val as y, cast(dr.val as real) as dr, cast(ols.val as real) as ols
from region r, storage s, year y, DepreciationMethod_def dm, OperationalLifeStorage_def ols, DiscountRate_def dr
where dm.r = r.val and dm.val = 1
and ols.r = r.val and ols.s = s.val
and y.val + ols.val - 1 > " * last(syear) *
" and dr.r = r.val and dr.val > 0"))
    local r = row[:r]
    local s = row[:s]
    local y = row[:y]
    local dr = row[:dr]

    si8_salvagevaluestorageatendofperiod3[constraintnum] = @constraint(jumpmodel, vcapitalinvestmentstorage[r,s,y] * (1 - (((1 + dr)^(Meta.parse(last(syear)) - Meta.parse(y) + 1) - 1) / ((1 + dr)^(row[:ols]) - 1))) == vsalvagevaluestorage[r,s,y])
    constraintnum += 1
end

logmsg("Created constraint SI8_SalvageValueStorageAtEndOfPeriod3.", quiet)
# END: SI8_SalvageValueStorageAtEndOfPeriod3.

# BEGIN: SI9_SalvageValueStorageDiscountedToStartYear.
constraintnum = 1  # Number of next constraint to be added to constraint array
@constraintref si9_salvagevaluestoragediscountedtostartyear[1:length(sregion) * length(sstorage) * length(syear)]

for row in DataFrames.eachrow(SQLite.query(db, "select r.val as r, s.val as s, y.val as y, cast(dr.val as real) as dr
from region r, storage s, year y, DiscountRate_def dr
where dr.r = r.val"))
    local r = row[:r]
    local s = row[:s]
    local y = row[:y]

    si9_salvagevaluestoragediscountedtostartyear[constraintnum] = @constraint(jumpmodel, vsalvagevaluestorage[r,s,y] / ((1 + row[:dr])^(Meta.parse(last(syear)) - Meta.parse(first(syear)) + 1)) == vdiscountedsalvagevaluestorage[r,s,y])
    constraintnum += 1
end

logmsg("Created constraint SI9_SalvageValueStorageDiscountedToStartYear.", quiet)
# END: SI9_SalvageValueStorageDiscountedToStartYear.

# BEGIN: SI10_TotalDiscountedCostByStorage.
constraintnum = 1  # Number of next constraint to be added to constraint array
@constraintref si10_totaldiscountedcostbystorage[1:length(sregion) * length(sstorage) * length(syear)]

for (r, s, y) in Base.product(sregion, sstorage, syear)
    si10_totaldiscountedcostbystorage[constraintnum] = @constraint(jumpmodel, vdiscountedcapitalinvestmentstorage[r,s,y] - vdiscountedsalvagevaluestorage[r,s,y] == vtotaldiscountedstoragecost[r,s,y])
    constraintnum += 1
end

logmsg("Created constraint SI10_TotalDiscountedCostByStorage.", quiet)
# END: SI10_TotalDiscountedCostByStorage.

# BEGIN: CC1_UndiscountedCapitalInvestment.
constraintnum = 1  # Number of next constraint to be added to constraint array
@constraintref cc1_undiscountedcapitalinvestment[1:length(sregion) * length(stechnology) * length(syear)]

for row in DataFrames.eachrow(SQLite.query(db, "select r.val as r, t.val as t, y.val as y, cast(cc.val as real) as cc
from region r, technology t, year y, CapitalCost_def cc
where cc.r = r.val and cc.t = t.val and cc.y = y.val"))
    local r = row[:r]
    local t = row[:t]
    local y = row[:y]

    cc1_undiscountedcapitalinvestment[constraintnum] = @constraint(jumpmodel, row[:cc] * vnewcapacity[r,t,y] == vcapitalinvestment[r,t,y])
    constraintnum += 1
end

logmsg("Created constraint CC1_UndiscountedCapitalInvestment.", quiet)
# END: CC1_UndiscountedCapitalInvestment.

# BEGIN: CC1Tr_UndiscountedCapitalInvestment.
if transmissionmodeling
    cc1tr_undiscountedcapitalinvestment::Array{ConstraintRef, 1} = Array{ConstraintRef, 1}()

    for row in DataFrames.eachrow(SQLite.query(db, "select tl.id as tr, y.val as y, cast(tl.CapitalCost as real) as cc from
    TransmissionLine tl, YEAR y
    where tl.CapitalCost is not null"))
        local tr = row[:tr]
        local y = row[:y]

        push!(cc1tr_undiscountedcapitalinvestment, @constraint(jumpmodel, row[:cc] * vtransmissionbuilt[tr,y] == vcapitalinvestmenttransmission[tr,y]))
    end

    logmsg("Created constraint CC1Tr_UndiscountedCapitalInvestment.", quiet)
end
# END: CC1Tr_UndiscountedCapitalInvestment.

# BEGIN: CC2_DiscountingCapitalInvestment.
constraintnum = 1  # Number of next constraint to be added to constraint array

queryrtydr::DataFrames.DataFrame = SQLite.query(db, "select r.val as r, t.val as t, y.val as y, cast(dr.val as real) as dr
from region r, technology t, year y, DiscountRate_def dr
where dr.r = r.val")

@constraintref cc2_discountingcapitalinvestment[1:size(queryrtydr)[1]]

for row in DataFrames.eachrow(queryrtydr)
    local r = row[:r]
    local t = row[:t]
    local y = row[:y]

    cc2_discountingcapitalinvestment[constraintnum] = @constraint(jumpmodel, vcapitalinvestment[r,t,y] / ((1 + row[:dr])^(Meta.parse(y) - Meta.parse(first(syear)))) == vdiscountedcapitalinvestment[r,t,y])
    constraintnum += 1
end

logmsg("Created constraint CC2_DiscountingCapitalInvestment.", quiet)
# END: CC2_DiscountingCapitalInvestment.

# BEGIN: CC2Tr_DiscountingCapitalInvestment.
if transmissionmodeling
    # Note: if a transmission line crosses regional boundaries, costs are assigned to from region (associated with n1)
    querytrydr::DataFrames.DataFrame = SQLite.query(db, "select tl.id as tr, y.val as y, cast(dr.val as real) as dr
	from TransmissionLine tl, NODE n, YEAR y, DiscountRate_def dr
    where tl.n1 = n.val
	and n.r = dr.r")

    cc2tr_discountingcapitalinvestment::Array{ConstraintRef, 1} = Array{ConstraintRef, 1}()

    for row in DataFrames.eachrow(querytrydr)
        local tr = row[:tr]
        local y = row[:y]

        push!(cc2tr_discountingcapitalinvestment, @constraint(jumpmodel,
            vcapitalinvestmenttransmission[tr,y] / ((1 + row[:dr])^(Meta.parse(y) - Meta.parse(first(syear)))) == vdiscountedcapitalinvestmenttransmission[tr,y]))
    end

    logmsg("Created constraint CC2Tr_DiscountingCapitalInvestment.", quiet)
end
# END: CC2Tr_DiscountingCapitalInvestment.

# BEGIN: SV1_SalvageValueAtEndOfPeriod1.
# DepreciationMethod 1 (if discount rate > 0): base salvage value on % of discounted value remaining at end of modeling period.
# DepreciationMethod 2 (or dm 1 if discount rate = 0): base salvage value on % of operational life remaining at end of modeling period.
constraintnum = 1  # Number of next constraint to be added to constraint array
@constraintref sv1_salvagevalueatendofperiod1[1:length(sregion) * length(stechnology) * length(syear)]

for row in DataFrames.eachrow(SQLite.query(db, "select r.val as r, t.val as t, y.val as y, cast(cc.val as real) as cc, cast(dr.val as real) as dr,
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

    sv1_salvagevalueatendofperiod1[constraintnum] = @constraint(jumpmodel, vsalvagevalue[r,t,y] ==
        row[:cc] * vnewcapacity[r,t,y] * (1 - (((1 + dr)^(Meta.parse(last(syear)) - Meta.parse(y) + 1) - 1) / ((1 + dr)^(row[:ol]) - 1))))
    constraintnum += 1
end

logmsg("Created constraint SV1_SalvageValueAtEndOfPeriod1.", quiet)
# END: SV1_SalvageValueAtEndOfPeriod1.

# BEGIN: SV1Tr_SalvageValueAtEndOfPeriod1.
if transmissionmodeling
    sv1tr_salvagevalueatendofperiod1::Array{ConstraintRef, 1} = Array{ConstraintRef, 1}()

    for row in DataFrames.eachrow(SQLite.query(db, "select tl.id as tr, y.val as y, cast(tl.CapitalCost as real) as cc,
	cast(tl.operationallife as real) as ol, cast(dr.val as real) as dr
	from TransmissionLine tl, NODE n, YEAR y, DepreciationMethod_def dm, DiscountRate_def dr
    where tl.CapitalCost is not null
	and tl.n1 = n.val
	and dm.r = n.r
	and dr.r = n.r
	and y.val + tl.operationallife - 1 > " * last(syear) *
	" and (dm.val = 1 and dr.val > 0)"))
        local tr = row[:tr]
        local y = row[:y]
        local dr = row[:dr]

        push!(sv1tr_salvagevalueatendofperiod1, @constraint(jumpmodel, vsalvagevaluetransmission[tr,y] ==
            row[:cc] * vtransmissionbuilt[tr,y] * (1 - (((1 + dr)^(Meta.parse(last(syear)) - Meta.parse(y) + 1) - 1) / ((1 + dr)^(row[:ol]) - 1)))))
    end

    logmsg("Created constraint SV1Tr_SalvageValueAtEndOfPeriod1.", quiet)
end
# END: SV1Tr_SalvageValueAtEndOfPeriod1.

# BEGIN: SV2_SalvageValueAtEndOfPeriod2.
constraintnum = 1  # Number of next constraint to be added to constraint array
@constraintref sv2_salvagevalueatendofperiod2[1:length(sregion) * length(stechnology) * length(syear)]

for row in DataFrames.eachrow(SQLite.query(db, "select r.val as r, t.val as t, y.val as y, cast(cc.val as real) as cc, cast(ol.val as real) as ol
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

    sv2_salvagevalueatendofperiod2[constraintnum] = @constraint(jumpmodel, vsalvagevalue[r,t,y] ==
        row[:cc] * vnewcapacity[r,t,y] * (1 - (Meta.parse(last(syear)) - Meta.parse(y) + 1) / row[:ol]))
    constraintnum += 1
end

logmsg("Created constraint SV2_SalvageValueAtEndOfPeriod2.", quiet)
# END: SV2_SalvageValueAtEndOfPeriod2.

# BEGIN: SV2Tr_SalvageValueAtEndOfPeriod2.
if transmissionmodeling
    sv2tr_salvagevalueatendofperiod2::Array{ConstraintRef, 1} = Array{ConstraintRef, 1}()

    for row in DataFrames.eachrow(SQLite.query(db, "select tl.id as tr, y.val as y, cast(tl.CapitalCost as real) as cc,
	cast(tl.operationallife as real) as ol
	from TransmissionLine tl, NODE n, YEAR y, DepreciationMethod_def dm, DiscountRate_def dr
    where tl.CapitalCost is not null
	and tl.n1 = n.val
	and dm.r = n.r
	and dr.r = n.r
	and y.val + tl.operationallife - 1 > " * last(syear) *
	" and ((dm.val = 1 and dr.val = 0) or (dm.val = 2))"))
        local tr = row[:tr]
        local y = row[:y]

        push!(sv2tr_salvagevalueatendofperiod2, @constraint(jumpmodel, vsalvagevaluetransmission[tr,y] ==
            row[:cc] * vtransmissionbuilt[tr,y] * (1 - (Meta.parse(last(syear)) - Meta.parse(y) + 1) / row[:ol])))
    end

    logmsg("Created constraint SV2Tr_SalvageValueAtEndOfPeriod2.", quiet)
end
# END: SV2Tr_SalvageValueAtEndOfPeriod2.

# BEGIN: SV3_SalvageValueAtEndOfPeriod3.
constraintnum = 1  # Number of next constraint to be added to constraint array
@constraintref sv3_salvagevalueatendofperiod3[1:length(sregion) * length(stechnology) * length(syear)]

for row in DataFrames.eachrow(SQLite.query(db, "select r.val as r, t.val as t, y.val as y
from region r, technology t, year y, OperationalLife_def ol
where ol.r = r.val and ol.t = t.val
and y.val + ol.val - 1 <= " * last(syear)))
    local r = row[:r]
    local t = row[:t]
    local y = row[:y]

    sv3_salvagevalueatendofperiod3[constraintnum] = @constraint(jumpmodel, vsalvagevalue[r,t,y] == 0)
    constraintnum += 1
end

logmsg("Created constraint SV3_SalvageValueAtEndOfPeriod3.", quiet)
# END: SV3_SalvageValueAtEndOfPeriod3.

# BEGIN: SV3Tr_SalvageValueAtEndOfPeriod3.
if transmissionmodeling
    sv3tr_salvagevalueatendofperiod3::Array{ConstraintRef, 1} = Array{ConstraintRef, 1}()

    for row in DataFrames.eachrow(SQLite.query(db, "select tl.id as tr, y.val as y
	from TransmissionLine tl, YEAR y
    where tl.CapitalCost is not null
	and y.val + tl.operationallife - 1 <= " * last(syear)))
        local tr = row[:tr]
        local y = row[:y]

        push!(sv3tr_salvagevalueatendofperiod3, @constraint(jumpmodel, vsalvagevaluetransmission[tr,y] == 0))
    end

    logmsg("Created constraint SV3Tr_SalvageValueAtEndOfPeriod3.", quiet)
end
# END: SV3Tr_SalvageValueAtEndOfPeriod3.

# BEGIN: SV4_SalvageValueDiscountedToStartYear.
constraintnum = 1  # Number of next constraint to be added to constraint array
@constraintref sv4_salvagevaluediscountedtostartyear[1:size(queryrtydr)[1]]

for row in DataFrames.eachrow(queryrtydr)
    local r = row[:r]
    local t = row[:t]
    local y = row[:y]

    sv4_salvagevaluediscountedtostartyear[constraintnum] = @constraint(jumpmodel, vdiscountedsalvagevalue[r,t,y] ==
        vsalvagevalue[r,t,y] / ((1 + row[:dr])^(1 + Meta.parse(last(syear)) - Meta.parse(first(syear)))))
    constraintnum += 1
end

logmsg("Created constraint SV4_SalvageValueDiscountedToStartYear.", quiet)
# END: SV4_SalvageValueDiscountedToStartYear.

# BEGIN: SV4Tr_SalvageValueDiscountedToStartYear.
if transmissionmodeling
    sv4tr_salvagevaluediscountedtostartyear::Array{ConstraintRef, 1} = Array{ConstraintRef, 1}()

    for row in DataFrames.eachrow(querytrydr)
        local tr = row[:tr]
        local y = row[:y]

        push!(sv4tr_salvagevaluediscountedtostartyear, @constraint(jumpmodel, vdiscountedsalvagevaluetransmission[tr,y] ==
            vsalvagevaluetransmission[tr,y] / ((1 + row[:dr])^(1 + Meta.parse(last(syear)) - Meta.parse(first(syear))))))
    end

    logmsg("Created constraint SV4Tr_SalvageValueDiscountedToStartYear.", quiet)
end
# END: SV4Tr_SalvageValueDiscountedToStartYear.

# BEGIN: OC1_OperatingCostsVariable.
constraintnum = 1  # Number of next constraint to be added to constraint array
@constraintref oc1_operatingcostsvariable[1:length(sregion) * length(stechnology) * length(syear)]

lastkeys = Array{String, 1}(undef,3)  # lastkeys[1] = r, lastkeys[2] = t, lastkeys[3] = y
sumexps = Array{AffExpr, 1}([AffExpr()])
# sumexps[1] = vtotalannualtechnologyactivitybymode sum

for row in DataFrames.eachrow(SQLite.query(db, "select r.val as r, t.val as t, y.val as y, vc.m as m, cast(vc.val as real) as vc
from region r, technology t, year y, VariableCost_def vc
where vc.r = r.val and vc.t = t.val and vc.y = y.val
and vc.val <> 0
order by r.val, t.val, y.val"))
    local r = row[:r]
    local t = row[:t]
    local y = row[:y]

    if isassigned(lastkeys, 1) && (r != lastkeys[1] || t != lastkeys[2] || y != lastkeys[3])
        # Create constraint
        oc1_operatingcostsvariable[constraintnum] = @constraint(jumpmodel, sumexps[1] ==
            vannualvariableoperatingcost[lastkeys[1],lastkeys[2],lastkeys[3]])
        constraintnum += 1

        sumexps[1] = AffExpr()
    end

    append!(sumexps[1], vtotalannualtechnologyactivitybymode[r,t,row[:m],y] * row[:vc])

    lastkeys[1] = r
    lastkeys[2] = t
    lastkeys[3] = y
end

# Create last constraint
if isassigned(lastkeys, 1)
    oc1_operatingcostsvariable[constraintnum] = @constraint(jumpmodel, sumexps[1] ==
        vannualvariableoperatingcost[lastkeys[1],lastkeys[2],lastkeys[3]])
end

logmsg("Created constraint OC1_OperatingCostsVariable.", quiet)
# END: OC1_OperatingCostsVariable.

# BEGIN: OC2_OperatingCostsFixedAnnual.
constraintnum = 1  # Number of next constraint to be added to constraint array

@constraintref oc2_operatingcostsfixedannual[1:length(sregion) * length(stechnology) * length(syear)]

for row in DataFrames.eachrow(SQLite.query(db, "select r.val as r, t.val as t, y.val as y, cast(fc.val as real) as fc
from region r, technology t, year y, FixedCost_def fc
where fc.r = r.val and fc.t = t.val and fc.y = y.val"))
    local r = row[:r]
    local t = row[:t]
    local y = row[:y]

    oc2_operatingcostsfixedannual[constraintnum] = @constraint(jumpmodel, vtotalcapacityannual[r,t,y] * row[:fc] == vannualfixedoperatingcost[r,t,y])
    constraintnum += 1
end

logmsg("Created constraint OC2_OperatingCostsFixedAnnual.", quiet)
# END: OC2_OperatingCostsFixedAnnual.

# BEGIN: OC3_OperatingCostsTotalAnnual.
constraintnum = 1  # Number of next constraint to be added to constraint array
@constraintref oc3_operatingcoststotalannual[1:length(sregion) * length(stechnology) * length(syear)]

for (r, t, y) in Base.product(sregion, stechnology, syear)
    oc3_operatingcoststotalannual[constraintnum] = @constraint(jumpmodel, vannualfixedoperatingcost[r,t,y] + vannualvariableoperatingcost[r,t,y] == voperatingcost[r,t,y])
    constraintnum += 1
end

logmsg("Created constraint OC3_OperatingCostsTotalAnnual.", quiet)
# END: OC3_OperatingCostsTotalAnnual.

# BEGIN: OCTr_OperatingCosts.
if transmissionmodeling
    octr_operatingcosts::Array{ConstraintRef, 1} = Array{ConstraintRef, 1}()
    lastkeys = Array{String, 1}(undef,2)  # lastkeys[1] = tr, lastkeys[2] = y
    lastvals = Array{Float64, 1}(undef,1)  # lastvals[1] = fc
    sumexps = Array{AffExpr, 1}([AffExpr()])  # sumexps[1] = vtransmissionbyline sum

    for row in DataFrames.eachrow(queryvtransmissionbyline)
        local tr = row[:tr]
        local y = row[:y]
        local vc = ismissing(row[:vc]) ? 0.0 : row[:vc]
        local fc = ismissing(row[:fc]) ? 0.0 : row[:fc]

        if isassigned(lastkeys, 1) && (tr != lastkeys[1] || y != lastkeys[2])
            # Create constraint
            push!(octr_operatingcosts, @constraint(jumpmodel, sumexps[1]
                + vtransmissionexists[lastkeys[1],lastkeys[2]] * lastvals[1] == voperatingcosttransmission[lastkeys[1],lastkeys[2]]))
            sumexps[1] = AffExpr()
        end

        append!(sumexps[1], vtransmissionbyline[tr,row[:l],row[:f],y] * row[:ys] * vc)

        lastkeys[1] = tr
        lastkeys[2] = y
        lastvals[1] = fc
    end

    # Create last constraint
    if isassigned(lastkeys, 1)
        push!(octr_operatingcosts, @constraint(jumpmodel, sumexps[1]
            + vtransmissionexists[lastkeys[1],lastkeys[2]] * lastvals[1] == voperatingcosttransmission[lastkeys[1],lastkeys[2]]))
    end

    logmsg("Created constraint OCTr_OperatingCosts.", quiet)
end
# END: OCTr_OperatingCosts.

# BEGIN: OC4_DiscountedOperatingCostsTotalAnnual.
constraintnum = 1  # Number of next constraint to be added to constraint array

@constraintref oc4_discountedoperatingcoststotalannual[1:length(sregion) * length(stechnology) * length(syear)]

for row in DataFrames.eachrow(queryrtydr)
    local r = row[:r]
    local t = row[:t]
    local y = row[:y]
    local dr = row[:dr]

    oc4_discountedoperatingcoststotalannual[constraintnum] = @constraint(jumpmodel,
        voperatingcost[r,t,y] / ((1 + dr)^(Meta.parse(y) - Meta.parse(first(syear)) + 0.5)) == vdiscountedoperatingcost[r,t,y])
    constraintnum += 1
end

logmsg("Created constraint OC4_DiscountedOperatingCostsTotalAnnual.", quiet)
# END: OC4_DiscountedOperatingCostsTotalAnnual.

# BEGIN: OC4Tr_DiscountedOperatingCostsTotalAnnual.
if transmissionmodeling
    oc4tr_discountedoperatingcoststotalannual::Array{ConstraintRef, 1} = Array{ConstraintRef, 1}()

    for row in DataFrames.eachrow(querytrydr)
        local tr = row[:tr]
        local y = row[:y]
        local dr = row[:dr]

        push!(oc4tr_discountedoperatingcoststotalannual, @constraint(jumpmodel,
            voperatingcosttransmission[tr,y] / ((1 + dr)^(Meta.parse(y) - Meta.parse(first(syear)) + 0.5)) == vdiscountedoperatingcosttransmission[tr,y]))
    end

    logmsg("Created constraint OC4Tr_DiscountedOperatingCostsTotalAnnual.", quiet)
end
# END: OC4Tr_DiscountedOperatingCostsTotalAnnual.

# BEGIN: TDC1_TotalDiscountedCostByTechnology.
constraintnum = 1  # Number of next constraint to be added to constraint array
@constraintref tdc1_totaldiscountedcostbytechnology[1:length(sregion) * length(stechnology) * length(syear)]

for (r, t, y) in Base.product(sregion, stechnology, syear)
    tdc1_totaldiscountedcostbytechnology[constraintnum] = @constraint(jumpmodel,
        vdiscountedoperatingcost[r,t,y] + vdiscountedcapitalinvestment[r,t,y]
        + vdiscountedtechnologyemissionspenalty[r,t,y] - vdiscountedsalvagevalue[r,t,y]
        == vtotaldiscountedcostbytechnology[r,t,y])
    constraintnum += 1
end

logmsg("Created constraint TDC1_TotalDiscountedCostByTechnology.", quiet)
# END: TDC1_TotalDiscountedCostByTechnology.

# BEGIN: TDCTr_TotalDiscountedTransmissionCostByRegion.
if transmissionmodeling
    tdctr_totaldiscountedtransmissioncostbyregion::Array{ConstraintRef, 1} = Array{ConstraintRef, 1}()
    lastkeys = Array{String, 1}(undef,2)  # lastkeys[1] = r, lastkeys[2] = y
    sumexps = Array{AffExpr, 1}([AffExpr()])  # sumexps[1] = costs sum

    for row in DataFrames.eachrow(SQLite.query(db, "select n.r as r, tl.id as tr, y.val as y
	from TransmissionLine tl, NODE n, YEAR y
    where tl.n1 = n.val
	order by n.r, y.val"))
        local r = row[:r]
        local y = row[:y]
        local tr = row[:tr]

        if isassigned(lastkeys, 1) && (r != lastkeys[1] || y != lastkeys[2])
            # Create constraint
            push!(tdctr_totaldiscountedtransmissioncostbyregion, @constraint(jumpmodel,
                sumexps[1] == vtotaldiscountedtransmissioncostbyregion[lastkeys[1],lastkeys[2]]))
            sumexps[1] = AffExpr()
        end

        append!(sumexps[1], vdiscountedcapitalinvestmenttransmission[tr,y] + vdiscountedsalvagevaluetransmission[tr,y]
            + vdiscountedoperatingcosttransmission[tr,y])

        lastkeys[1] = r
        lastkeys[2] = y
    end

    # Create last constraint
    if isassigned(lastkeys, 1)
        push!(tdctr_totaldiscountedtransmissioncostbyregion, @constraint(jumpmodel,
            sumexps[1] == vtotaldiscountedtransmissioncostbyregion[lastkeys[1],lastkeys[2]]))
    end

    logmsg("Created constraint TDCTr_TotalDiscountedTransmissionCostByRegion.", quiet)
end
# END: TDCTr_TotalDiscountedTransmissionCostByRegion.

# BEGIN: TDC2_TotalDiscountedCost.
constraintnum = 1  # Number of next constraint to be added to constraint array
@constraintref tdc2_totaldiscountedcost[1:length(sregion) * length(syear)]

for (r, y) in Base.product(sregion, syear)
    tdc2_totaldiscountedcost[constraintnum] = @constraint(jumpmodel, (length(stechnology) == 0 ? 0 : sum([vtotaldiscountedcostbytechnology[r,t,y] for t = stechnology]))
        + (length(sstorage) == 0 ? 0 : sum([vtotaldiscountedstoragecost[r,s,y] for s = sstorage]))
        + (transmissionmodeling ? vtotaldiscountedtransmissioncostbyregion[r,y] : 0)
        == vtotaldiscountedcost[r,y])
    constraintnum += 1
end

logmsg("Created constraint TDC2_TotalDiscountedCost.", quiet)
# END: TDC2_TotalDiscountedCost.

# BEGIN: TCC1_TotalAnnualMaxCapacityConstraint.
constraintnum = 1  # Number of next constraint to be added to constraint array
@constraintref tcc1_totalannualmaxcapacityconstraint[1:length(sregion) * length(stechnology) * length(syear)]

for row in DataFrames.eachrow(SQLite.query(db, "select r, t, y, cast(val as real) as tmx
from TotalAnnualMaxCapacity_def"))
    local r = row[:r]
    local t = row[:t]
    local y = row[:y]

    tcc1_totalannualmaxcapacityconstraint[constraintnum] = @constraint(jumpmodel, vtotalcapacityannual[r,t,y] <= row[:tmx])
    constraintnum += 1
end

logmsg("Created constraint TCC1_TotalAnnualMaxCapacityConstraint.", quiet)
# END: TCC1_TotalAnnualMaxCapacityConstraint.

# BEGIN: TCC2_TotalAnnualMinCapacityConstraint.
constraintnum = 1  # Number of next constraint to be added to constraint array
@constraintref tcc2_totalannualmincapacityconstraint[1:length(sregion) * length(stechnology) * length(syear)]

for row in DataFrames.eachrow(SQLite.query(db, "select r, t, y, cast(val as real) as tmn
from TotalAnnualMinCapacity_def
where val > 0"))
    local r = row[:r]
    local t = row[:t]
    local y = row[:y]

    tcc2_totalannualmincapacityconstraint[constraintnum] = @constraint(jumpmodel, vtotalcapacityannual[r,t,y] >= row[:tmn])
    constraintnum += 1
end

logmsg("Created constraint TCC2_TotalAnnualMinCapacityConstraint.", quiet)
# END: TCC2_TotalAnnualMinCapacityConstraint.

# BEGIN: NCC1_TotalAnnualMaxNewCapacityConstraint.
constraintnum = 1  # Number of next constraint to be added to constraint array
@constraintref ncc1_totalannualmaxnewcapacityconstraint[1:length(sregion) * length(stechnology) * length(syear)]

for row in DataFrames.eachrow(SQLite.query(db, "select r, t, y, cast(val as real) as tmx
from TotalAnnualMaxCapacityInvestment_def"))
    local r = row[:r]
    local t = row[:t]
    local y = row[:y]

    ncc1_totalannualmaxnewcapacityconstraint[constraintnum] = @constraint(jumpmodel, vnewcapacity[r,t,y] <= row[:tmx])
    constraintnum += 1
end

logmsg("Created constraint NCC1_TotalAnnualMaxNewCapacityConstraint.", quiet)
# END: NCC1_TotalAnnualMaxNewCapacityConstraint.

# BEGIN: NCC2_TotalAnnualMinNewCapacityConstraint.
constraintnum = 1  # Number of next constraint to be added to constraint array
@constraintref ncc2_totalannualminnewcapacityconstraint[1:length(sregion) * length(stechnology) * length(syear)]

for row in DataFrames.eachrow(SQLite.query(db, "select r, t, y, cast(val as real) as tmn
from TotalAnnualMinCapacityInvestment_def
where val > 0"))
    local r = row[:r]
    local t = row[:t]
    local y = row[:y]

    ncc2_totalannualminnewcapacityconstraint[constraintnum] = @constraint(jumpmodel, vnewcapacity[r,t,y] >= row[:tmn])
    constraintnum += 1
end

logmsg("Created constraint NCC2_TotalAnnualMinNewCapacityConstraint.", quiet)
# END: NCC2_TotalAnnualMinNewCapacityConstraint.

# BEGIN: AAC1_TotalAnnualTechnologyActivity.
if (annualactivityupperlimits || annualactivitylowerlimits || modelperiodactivityupperlimits || modelperiodactivitylowerlimits
    || in("vtotaltechnologyannualactivity", varstosavearr))

    constraintnum = 1  # Number of next constraint to be added to constraint array
    @constraintref aac1_totalannualtechnologyactivity[1:length(sregion) * length(stechnology) * length(syear)]

    lastkeys = Array{String, 1}(undef,3)  # lastkeys[1] = r, lastkeys[2] = t, lastkeys[3] = y
    sumexps = Array{AffExpr, 1}([AffExpr()]) # sumexps[1] = vrateoftotalactivity sum

    for row in DataFrames.eachrow(SQLite.query(db, "select r.val as r, t.val as t, ys.y as y, ys.l as l, cast(ys.val as real) as ys
    from region r, technology t, YearSplit_def ys
    order by r.val, t.val, ys.y"))
        local r = row[:r]
        local t = row[:t]
        local y = row[:y]

        if isassigned(lastkeys, 1) && (r != lastkeys[1] || t != lastkeys[2] || y != lastkeys[3])
            # Create constraint
            aac1_totalannualtechnologyactivity[constraintnum] = @constraint(jumpmodel, sumexps[1] ==
                vtotaltechnologyannualactivity[lastkeys[1],lastkeys[2],lastkeys[3]])
            constraintnum += 1

            sumexps[1] = AffExpr()
        end

        append!(sumexps[1], vrateoftotalactivity[r,t,row[:l],y] * row[:ys])

        lastkeys[1] = r
        lastkeys[2] = t
        lastkeys[3] = y
    end

    # Create last constraint
    if isassigned(lastkeys, 1)
        aac1_totalannualtechnologyactivity[constraintnum] = @constraint(jumpmodel, sumexps[1] ==
            vtotaltechnologyannualactivity[lastkeys[1],lastkeys[2],lastkeys[3]])
    end

    logmsg("Created constraint AAC1_TotalAnnualTechnologyActivity.", quiet)
end
# END: AAC1_TotalAnnualTechnologyActivity.

# BEGIN: AAC2_TotalAnnualTechnologyActivityUpperLimit.
if annualactivityupperlimits
    constraintnum = 1  # Number of next constraint to be added to constraint array
    @constraintref aac2_totalannualtechnologyactivityupperlimit[1:length(sregion) * length(stechnology) * length(syear)]

    for row in DataFrames.eachrow(SQLite.query(db, "select r, t, y, cast(val as real) as amx
    from TotalTechnologyAnnualActivityUpperLimit_def"))
        local r = row[:r]
        local t = row[:t]
        local y = row[:y]

        aac2_totalannualtechnologyactivityupperlimit[constraintnum] = @constraint(jumpmodel, vtotaltechnologyannualactivity[r,t,y] <= row[:amx])
        constraintnum += 1
    end

    logmsg("Created constraint AAC2_TotalAnnualTechnologyActivityUpperLimit.", quiet)
end
# END: AAC2_TotalAnnualTechnologyActivityUpperLimit.

# BEGIN: AAC3_TotalAnnualTechnologyActivityLowerLimit.
if annualactivitylowerlimits
    constraintnum = 1  # Number of next constraint to be added to constraint array
    @constraintref aac3_totalannualtechnologyactivitylowerlimit[1:length(sregion) * length(stechnology) * length(syear)]

    for row in DataFrames.eachrow(queryannualactivitylowerlimit)
        local r = row[:r]
        local t = row[:t]
        local y = row[:y]

        aac3_totalannualtechnologyactivitylowerlimit[constraintnum] = @constraint(jumpmodel, vtotaltechnologyannualactivity[r,t,y] >= row[:amn])
        constraintnum += 1
    end

    logmsg("Created constraint AAC3_TotalAnnualTechnologyActivityLowerLimit.", quiet)
end
# END: AAC3_TotalAnnualTechnologyActivityLowerLimit.

# BEGIN: TAC1_TotalModelHorizonTechnologyActivity.
if modelperiodactivitylowerlimits || modelperiodactivityupperlimits || in("vtotaltechnologymodelperiodactivity", varstosavearr)
    constraintnum = 1  # Number of next constraint to be added to constraint array
    @constraintref tac1_totalmodelhorizontechnologyactivity[1:length(sregion) * length(stechnology)]

    for (r, t) in Base.product(sregion, stechnology)
        tac1_totalmodelhorizontechnologyactivity[constraintnum] = @constraint(jumpmodel, sum([vtotaltechnologyannualactivity[r,t,y] for y = syear]) == vtotaltechnologymodelperiodactivity[r,t])
        constraintnum += 1
    end

    logmsg("Created constraint TAC1_TotalModelHorizonTechnologyActivity.", quiet)
end
# END: TAC1_TotalModelHorizonTechnologyActivity.

# BEGIN: TAC2_TotalModelHorizonTechnologyActivityUpperLimit.
if modelperiodactivityupperlimits
    constraintnum = 1  # Number of next constraint to be added to constraint array
    @constraintref tac2_totalmodelhorizontechnologyactivityupperlimit[1:length(sregion) * length(stechnology)]

    for row in DataFrames.eachrow(SQLite.query(db, "select r, t, cast(val as real) as mmx
    from TotalTechnologyModelPeriodActivityUpperLimit_def"))
        local r = row[:r]
        local t = row[:t]

        tac2_totalmodelhorizontechnologyactivityupperlimit[constraintnum] = @constraint(jumpmodel, vtotaltechnologymodelperiodactivity[r,t] <= row[:mmx])
        constraintnum += 1
    end

    logmsg("Created constraint TAC2_TotalModelHorizonTechnologyActivityUpperLimit.", quiet)
end
# END: TAC2_TotalModelHorizonTechnologyActivityUpperLimit.

# BEGIN: TAC3_TotalModelHorizonTechnologyActivityLowerLimit.
if modelperiodactivitylowerlimits
    constraintnum = 1  # Number of next constraint to be added to constraint array
    @constraintref tac3_totalmodelhorizontechnologyactivitylowerlimit[1:length(sregion) * length(stechnology)]

    for row in DataFrames.eachrow(querymodelperiodactivitylowerlimit)
        local r = row[:r]
        local t = row[:t]

        tac3_totalmodelhorizontechnologyactivitylowerlimit[constraintnum] = @constraint(jumpmodel, vtotaltechnologymodelperiodactivity[r,t] >= row[:mmn])
        constraintnum += 1
    end

    logmsg("Created constraint TAC3_TotalModelHorizonTechnologyActivityLowerLimit.", quiet)
end
# END: TAC3_TotalModelHorizonTechnologyActivityLowerLimit.

# BEGIN: RM1_ReserveMargin_TechnologiesIncluded_In_Activity_Units.
constraintnum = 1  # Number of next constraint to be added to constraint array
@constraintref rm1_reservemargin_technologiesincluded_in_activity_units[1:length(sregion) * length(syear)]

lastkeys = Array{String, 1}(undef,2)  # lastkeys[1] = r, lastkeys[2] = y
sumexps = Array{AffExpr, 1}([AffExpr()])  # sumexps[1] = vtotalcapacityannual sum

for row in DataFrames.eachrow(SQLite.query(db, "select r.val as r, y.val as y, rmt.t as t, cast(rmt.val as real) as rmt, cast(cau.val as real) as cau
from region r, year y, ReserveMarginTagTechnology_def rmt, CapacityToActivityUnit_def cau
where rmt.r = r.val and rmt.t = cau.t and rmt.y = y.val and rmt.val <> 0
and cau.r = r.val and cau.val <> 0
order by r.val, y.val"))
    local r = row[:r]
    local y = row[:y]

    if isassigned(lastkeys, 1) && (r != lastkeys[1] || y != lastkeys[2])
        # Create constraint
        rm1_reservemargin_technologiesincluded_in_activity_units[constraintnum] = @constraint(jumpmodel, sumexps[1] ==
            vtotalcapacityinreservemargin[lastkeys[1],lastkeys[2]])
        constraintnum += 1

        sumexps[1] = AffExpr()
    end

    append!(sumexps[1], vtotalcapacityannual[r,row[:t],y] * row[:rmt] * row[:cau])

    lastkeys[1] = r
    lastkeys[2] = y
end

# Create last constraint
if isassigned(lastkeys, 1)
    rm1_reservemargin_technologiesincluded_in_activity_units[constraintnum] = @constraint(jumpmodel, sumexps[1] ==
        vtotalcapacityinreservemargin[lastkeys[1],lastkeys[2]])
end

logmsg("Created constraint RM1_ReserveMargin_TechnologiesIncluded_In_Activity_Units.", quiet)
# END: RM1_ReserveMargin_TechnologiesIncluded_In_Activity_Units.

# BEGIN: RM2_ReserveMargin_FuelsIncluded.
constraintnum = 1  # Number of next constraint to be added to constraint array
@constraintref rm2_reservemargin_fuelsincluded[1:length(sregion) * length(stimeslice) * length(syear)]

lastkeys = Array{String, 1}(undef,3)  # lastkeys[1] = r, lastkeys[2] = l, lastkeys[3] = y
sumexps = Array{AffExpr, 1}([AffExpr()])
# sumexps[1] = vrateofproduction sum

for row in DataFrames.eachrow(SQLite.query(db, "select r.val as r, l.val as l, y.val as y, rmf.f as f, cast(rmf.val as real) as rmf
from region r, timeslice l, year y, ReserveMarginTagFuel_def rmf
where rmf.r = r.val and rmf.y = y.val and rmf.val <> 0
order by r.val, l.val, y.val"))
    local r = row[:r]
    local l = row[:l]
    local y = row[:y]

    if isassigned(lastkeys, 1) && (r != lastkeys[1] || l != lastkeys[2] || y != lastkeys[3])
        # Create constraint
        rm2_reservemargin_fuelsincluded[constraintnum] = @constraint(jumpmodel, sumexps[1] ==
            vdemandneedingreservemargin[lastkeys[1],lastkeys[2],lastkeys[3]])
        constraintnum += 1

        sumexps[1] = AffExpr()
    end

    append!(sumexps[1], vrateofproduction[r,l,row[:f],y] * row[:rmf])

    lastkeys[1] = r
    lastkeys[2] = l
    lastkeys[3] = y
end

# Create last constraint
if isassigned(lastkeys, 1)
    rm2_reservemargin_fuelsincluded[constraintnum] = @constraint(jumpmodel, sumexps[1] ==
        vdemandneedingreservemargin[lastkeys[1],lastkeys[2],lastkeys[3]])
end

logmsg("Created constraint RM2_ReserveMargin_FuelsIncluded.", quiet)
# END: RM2_ReserveMargin_FuelsIncluded.

# BEGIN: RM3_ReserveMargin_Constraint.
constraintnum = 1  # Number of next constraint to be added to constraint array
@constraintref rm3_reservemargin_constraint[1:length(sregion) * length(stimeslice) * length(syear)]

for row in DataFrames.eachrow(SQLite.query(db, "select r.val as r, l.val as l, y.val as y, cast(rm.val as real) as rm
from region r, timeslice l, year y, ReserveMargin_def rm
where rm.r = r.val and rm.y = y.val"))
    local r = row[:r]
    local l = row[:l]
    local y = row[:y]

    rm3_reservemargin_constraint[constraintnum] = @constraint(jumpmodel, vdemandneedingreservemargin[r,l,y] * row[:rm] <= vtotalcapacityinreservemargin[r,y])
    constraintnum += 1
end

logmsg("Created constraint RM3_ReserveMargin_Constraint.", quiet)
# END: RM3_ReserveMargin_Constraint.

# BEGIN: RE1_FuelProductionByTechnologyAnnual.
constraintnum = 1  # Number of next constraint to be added to constraint array
@constraintref re1_fuelproductionbytechnologyannual[1:length(sregion) * length(stechnology) * length(sfuel) * length(syear)]

lastkeys = Array{String, 1}(undef,4)  # lastkeys[1] = r, lastkeys[2] = t, lastkeys[3] = f, lastkeys[4] = y
sumexps = Array{AffExpr, 1}([AffExpr()])  # sumexps[1] = vproductionbytechnologynn-equivalent sum

for row in DataFrames.eachrow(queryvproductionbytechnologyannual)
    local r = row[:r]
    local t = row[:t]
    local f = row[:f]
    local y = row[:y]
    local n = row[:n]

    if isassigned(lastkeys, 1) && (r != lastkeys[1] || t != lastkeys[2] || f != lastkeys[3] || y != lastkeys[4])
        # Create constraint
        re1_fuelproductionbytechnologyannual[constraintnum] = @constraint(jumpmodel, sumexps[1] == vproductionbytechnologyannual[lastkeys[1],lastkeys[2],lastkeys[3],lastkeys[4]])
        constraintnum += 1

        sumexps[1] = AffExpr()
    end

    if ismissing(n)
        append!(sumexps[1], vrateofproductionbytechnologynn[r,row[:l],t,f,y] * row[:ys])
    else
        append!(sumexps[1], vrateofproductionbytechnologynodal[n,row[:l],t,f,y] * row[:ys])
    end

    lastkeys[1] = r
    lastkeys[2] = t
    lastkeys[3] = f
    lastkeys[4] = y
end

# Create last constraint
if isassigned(lastkeys, 1)
    re1_fuelproductionbytechnologyannual[constraintnum] = @constraint(jumpmodel, sumexps[1] == vproductionbytechnologyannual[lastkeys[1],lastkeys[2],lastkeys[3],lastkeys[4]])
end

logmsg("Created constraint RE1_FuelProductionByTechnologyAnnual.", quiet)
# END: RE1_FuelProductionByTechnologyAnnual.

# BEGIN: FuelUseByTechnologyAnnual.
constraintnum = 1  # Number of next constraint to be added to constraint array
@constraintref fuelusebytechnologyannual[1:length(sregion) * length(stechnology) * length(sfuel) * length(syear)]

lastkeys = Array{String, 1}(undef,4)  # lastkeys[1] = r, lastkeys[2] = t, lastkeys[3] = f, lastkeys[4] = y
sumexps = Array{AffExpr, 1}([AffExpr()])  # sumexps[1] = vusebytechnologynn-equivalent sum

for row in DataFrames.eachrow(queryvusebytechnologyannual)
    local r = row[:r]
    local t = row[:t]
    local f = row[:f]
    local y = row[:y]
    local n = row[:n]

    if isassigned(lastkeys, 1) && (r != lastkeys[1] || t != lastkeys[2] || f != lastkeys[3] || y != lastkeys[4])
        # Create constraint
        fuelusebytechnologyannual[constraintnum] = @constraint(jumpmodel, sumexps[1] == vusebytechnologyannual[lastkeys[1],lastkeys[2],lastkeys[3],lastkeys[4]])
        constraintnum += 1

        sumexps[1] = AffExpr()
    end

    if ismissing(n)
        append!(sumexps[1], vrateofusebytechnologynn[r,row[:l],t,f,y] * row[:ys])
    else
        append!(sumexps[1], vrateofusebytechnologynodal[n,row[:l],t,f,y] * row[:ys])
    end

    lastkeys[1] = r
    lastkeys[2] = t
    lastkeys[3] = f
    lastkeys[4] = y
end

# Create last constraint
if isassigned(lastkeys, 1)
    fuelusebytechnologyannual[constraintnum] = @constraint(jumpmodel, sumexps[1] == vusebytechnologyannual[lastkeys[1],lastkeys[2],lastkeys[3],lastkeys[4]])
end

logmsg("Created constraint FuelUseByTechnologyAnnual.", quiet)
# END: FuelUseByTechnologyAnnual.

# BEGIN: RE2_TechIncluded.
constraintnum = 1  # Number of next constraint to be added to constraint array
@constraintref re2_techincluded[1:length(sregion) * length(syear)]

lastkeys = Array{String, 1}(undef,2)  # lastkeys[1] = r, lastkeys[2] = y
sumexps = Array{AffExpr, 1}([AffExpr()]) # sumexps[1] = vproductionbytechnologyannual sum

for row in DataFrames.eachrow(SQLite.query(db, "select r.val as r, y.val as y, oar.t as t, oar.f as f, cast(ret.val as real) as ret
from REGION r, YEAR y, RETagTechnology_def ret,
(select distinct r, t, f, y
from OutputActivityRatio_def
where val <> 0) oar
where oar.r = r.val and oar.t = ret.t and oar.y = y.val
and ret.r = r.val and ret.y = y.val and ret.val <> 0
order by r.val, y.val"))
    local r = row[:r]
    local y = row[:y]

    if isassigned(lastkeys, 1) && (r != lastkeys[1] || y != lastkeys[2])
        # Create constraint
        re2_techincluded[constraintnum] = @constraint(jumpmodel, sumexps[1] ==
            vtotalreproductionannual[lastkeys[1],lastkeys[2]])
        constraintnum += 1

        sumexps[1] = AffExpr()
    end

    append!(sumexps[1], vproductionbytechnologyannual[r,row[:t],row[:f],y] * row[:ret])

    lastkeys[1] = r
    lastkeys[2] = y
end

# Create last constraint
if isassigned(lastkeys, 1)
    re2_techincluded[constraintnum] = @constraint(jumpmodel, sumexps[1] ==
        vtotalreproductionannual[lastkeys[1],lastkeys[2]])
end

logmsg("Created constraint RE2_TechIncluded.", quiet)
# END: RE2_TechIncluded.

# BEGIN: RE3_FuelIncluded.
constraintnum = 1  # Number of next constraint to be added to constraint array
@constraintref re3_fuelincluded[1:length(sregion) * length(syear)]

lastkeys = Array{String, 1}(undef,3)  # lastkeys[1] = r, lastkeys[2] = y
sumexps = Array{AffExpr, 1}([AffExpr()])  # sumexps[1] = vrateofproduction sum

for row in DataFrames.eachrow(SQLite.query(db, "select r.val as r, y.val as y, ys.l as l, rtf.f as f, cast(ys.val as real) as ys,
cast(rtf.val as real) as rtf
from REGION r, YEAR y, YearSplit_def ys, RETagFuel_def rtf
where ys.y = y.val and ys.val <> 0
and rtf.r = r.val and rtf.y = y.val and rtf.val <> 0
order by r.val, y.val"))
    local r = row[:r]
    local y = row[:y]

    if isassigned(lastkeys, 1) && (r != lastkeys[1] || y != lastkeys[2])
        # Create constraint
        re3_fuelincluded[constraintnum] = @constraint(jumpmodel, sumexps[1] ==
            vretotalproductionoftargetfuelannual[lastkeys[1],lastkeys[2]])
        constraintnum += 1

        sumexps[1] = AffExpr()
    end

    append!(sumexps[1], vrateofproduction[r,row[:l],row[:f],y] * row[:ys] * row[:rtf])

    lastkeys[1] = r
    lastkeys[2] = y
end

# Create last constraint
if isassigned(lastkeys, 1)
    re3_fuelincluded[constraintnum] = @constraint(jumpmodel, sumexps[1] ==
        vretotalproductionoftargetfuelannual[lastkeys[1],lastkeys[2]])
end

logmsg("Created constraint RE3_FuelIncluded.", quiet)
# END: RE3_FuelIncluded.

# BEGIN: RE4_EnergyConstraint.
constraintnum = 1  # Number of next constraint to be added to constraint array

@constraintref re4_energyconstraint[1:length(sregion) * length(syear)]

for row in DataFrames.eachrow(SQLite.query(db, "select ry.r as r, ry.y as y, cast(rmp.val as real) as rmp
from
(select distinct r.val as r, y.val as y
from REGION r, TECHNOLOGY t, FUEL f, YEAR y, OutputActivityRatio_def oar, RETagTechnology_def ret
where oar.r = r.val and oar.t = t.val and oar.f = f.val and oar.y = y.val and oar.val <> 0
and ret.r = r.val and ret.t = t.val and ret.y = y.val and ret.val <> 0
intersect
select distinct r.val as r, y.val as y
from REGION r, YEAR y, TIMESLICE l, FUEL f, YearSplit_def ys, RETagFuel_def rtf
where ys.l = l.val and ys.y = y.val
and rtf.r = r.val and rtf.f = f.val and rtf.y = y.val and rtf.val <> 0) ry, REMinProductionTarget_def rmp
where rmp.r = ry.r and rmp.y = ry.y"))
    local r = row[:r]
    local y = row[:y]

    re4_energyconstraint[constraintnum] = @constraint(jumpmodel, row[:rmp] * vretotalproductionoftargetfuelannual[r,y] <= vtotalreproductionannual[r,y])
    constraintnum += 1
end

logmsg("Created constraint RE4_EnergyConstraint.", quiet)
# END: RE4_EnergyConstraint.

# Omitting RE5_FuelUseByTechnologyAnnual because it's just an identity that's not used elsewhere in model

# BEGIN: E1_AnnualEmissionProductionByMode.
queryvannualtechnologyemissionbymode::DataFrames.DataFrame = SQLite.query(db,
"select r, t, e, y, m, cast(val as real) as ear
from EmissionActivityRatio_def ear
order by r, t, e, y")

if in("vannualtechnologyemissionbymode", varstosavearr)
    constraintnum = 1  # Number of next constraint to be added to constraint array
    @constraintref e1_annualemissionproductionbymode[1:length(sregion) * length(stechnology) * length(semission) * length(smode_of_operation) * length(syear)]

    for row in DataFrames.eachrow(queryvannualtechnologyemissionbymode)
        local r = row[:r]
        local t = row[:t]
        local e = row[:e]
        local m = row[:m]
        local y = row[:y]

        e1_annualemissionproductionbymode[constraintnum] = @constraint(jumpmodel, row[:ear] * vtotalannualtechnologyactivitybymode[r,t,m,y] == vannualtechnologyemissionbymode[r,t,e,m,y])
        constraintnum += 1
    end

    logmsg("Created constraint E1_AnnualEmissionProductionByMode.", quiet)
end
# END: E1_AnnualEmissionProductionByMode.

# BEGIN: E2_AnnualEmissionProduction.
constraintnum = 1  # Number of next constraint to be added to constraint array
@constraintref e2_annualemissionproduction[1:length(sregion) * length(stechnology) * length(semission) * length(syear)]

lastkeys = Array{String, 1}(undef,4)  # lastkeys[1] = r, lastkeys[2] = t, lastkeys[3] = e, lastkeys[4] = y
sumexps = Array{AffExpr, 1}([AffExpr()])  # sumexps[1] = vannualtechnologyemissionbymode-equivalent sum

for row in DataFrames.eachrow(queryvannualtechnologyemissionbymode)
    local r = row[:r]
    local t = row[:t]
    local e = row[:e]
    local y = row[:y]

    if isassigned(lastkeys, 1) && (r != lastkeys[1] || t != lastkeys[2] || e != lastkeys[3] || y != lastkeys[4])
        # Create constraint
        e2_annualemissionproduction[constraintnum] = @constraint(jumpmodel, sumexps[1] ==
            vannualtechnologyemission[lastkeys[1],lastkeys[2],lastkeys[3],lastkeys[4]])
        constraintnum += 1

        sumexps[1] = AffExpr()
    end

    append!(sumexps[1], row[:ear] * vtotalannualtechnologyactivitybymode[r,t,row[:m],y])

    lastkeys[1] = r
    lastkeys[2] = t
    lastkeys[3] = e
    lastkeys[4] = y
end

# Create last constraint
if isassigned(lastkeys, 1)
    e2_annualemissionproduction[constraintnum] = @constraint(jumpmodel, sumexps[1] ==
        vannualtechnologyemission[lastkeys[1],lastkeys[2],lastkeys[3],lastkeys[4]])
end

logmsg("Created constraint E2_AnnualEmissionProduction.", quiet)
# END: E2_AnnualEmissionProduction.

# BEGIN: E3_EmissionsPenaltyByTechAndEmission.
queryvannualtechnologyemissionpenaltybyemission::DataFrames.DataFrame = SQLite.query(db,
"select distinct ear.r as r, ear.t as t, ear.e as e, ear.y as y, cast(ep.val as real) as ep
from EmissionActivityRatio_def ear, EmissionsPenalty_def ep
where ep.r = ear.r and ep.e = ear.e and ep.y = ear.y
and ep.val <> 0
order by ear.r, ear.t, ear.y")

if in("vannualtechnologyemissionpenaltybyemission", varstosavearr)
    constraintnum = 1  # Number of next constraint to be added to constraint array
    @constraintref e3_emissionspenaltybytechandemission[1:length(sregion) * length(stechnology) * length(semission) * length(syear)]

    for row in DataFrames.eachrow(queryvannualtechnologyemissionpenaltybyemission)
        local r = row[:r]
        local t = row[:t]
        local e = row[:e]
        local y = row[:y]

        e3_emissionspenaltybytechandemission[constraintnum] = @constraint(jumpmodel, vannualtechnologyemission[r,t,e,y] * row[:ep] == vannualtechnologyemissionpenaltybyemission[r,t,e,y])
        constraintnum += 1
    end

    logmsg("Created constraint E3_EmissionsPenaltyByTechAndEmission.", quiet)
end
# END: E3_EmissionsPenaltyByTechAndEmission.

# BEGIN: E4_EmissionsPenaltyByTechnology.
constraintnum = 1  # Number of next constraint to be added to constraint array
@constraintref e4_emissionspenaltybytechnology[1:length(sregion) * length(stechnology) * length(syear)]

lastkeys = Array{String, 1}(undef,3)  # lastkeys[1] = r, lastkeys[2] = t, lastkeys[3] = y
sumexps = Array{AffExpr, 1}([AffExpr()])
# sumexps[1] = vannualtechnologyemissionpenaltybyemission-equivalent sum

for row in DataFrames.eachrow(queryvannualtechnologyemissionpenaltybyemission)
    local r = row[:r]
    local t = row[:t]
    local y = row[:y]

    if isassigned(lastkeys, 1) && (r != lastkeys[1] || t != lastkeys[2] || y != lastkeys[3])
        # Create constraint
        e4_emissionspenaltybytechnology[constraintnum] = @constraint(jumpmodel, sumexps[1] ==
            vannualtechnologyemissionspenalty[lastkeys[1],lastkeys[2],lastkeys[3]])
        constraintnum += 1

        sumexps[1] = AffExpr()
    end

    append!(sumexps[1], vannualtechnologyemission[r,t,row[:e],y] * row[:ep])

    lastkeys[1] = r
    lastkeys[2] = t
    lastkeys[3] = y
end

# Create last constraint
if isassigned(lastkeys, 1)
    e4_emissionspenaltybytechnology[constraintnum] = @constraint(jumpmodel, sumexps[1] ==
        vannualtechnologyemissionspenalty[lastkeys[1],lastkeys[2],lastkeys[3]])
end

logmsg("Created constraint E4_EmissionsPenaltyByTechnology.", quiet)
# END: E4_EmissionsPenaltyByTechnology.

# BEGIN: E5_DiscountedEmissionsPenaltyByTechnology.
constraintnum = 1  # Number of next constraint to be added to constraint array
@constraintref e5_discountedemissionspenaltybytechnology[1:size(queryrtydr)[1]]

for row in DataFrames.eachrow(queryrtydr)
    local r = row[:r]
    local t = row[:t]
    local y = row[:y]
    local dr = row[:dr]

    e5_discountedemissionspenaltybytechnology[constraintnum] = @constraint(jumpmodel, vannualtechnologyemissionspenalty[r,t,y] / ((1 + dr)^(Meta.parse(y) - Meta.parse(first(syear)) + 0.5)) == vdiscountedtechnologyemissionspenalty[r,t,y])
    constraintnum += 1
end

logmsg("Created constraint E5_DiscountedEmissionsPenaltyByTechnology.", quiet)
# END: E5_DiscountedEmissionsPenaltyByTechnology.

# BEGIN: E6_EmissionsAccounting1.
constraintnum = 1  # Number of next constraint to be added to constraint array
@constraintref e6_emissionsaccounting1[1:length(sregion) * length(semission) * length(syear)]

lastkeys = Array{String, 1}(undef,3)  # lastkeys[1] = r, lastkeys[2] = e, lastkeys[3] = y
sumexps = Array{AffExpr, 1}([AffExpr()])  # sumexps[1] = vannualtechnologyemission sum

for row in DataFrames.eachrow(SQLite.query(db, "select distinct r, e, y, t
from EmissionActivityRatio_def ear
order by r, e, y"))
    local r = row[:r]
    local e = row[:e]
    local y = row[:y]

    if isassigned(lastkeys, 1) && (r != lastkeys[1] || e != lastkeys[2] || y != lastkeys[3])
        # Create constraint
        e6_emissionsaccounting1[constraintnum] = @constraint(jumpmodel, sumexps[1] ==
            vannualemissions[lastkeys[1],lastkeys[2],lastkeys[3]])
        constraintnum += 1

        sumexps[1] = AffExpr()
    end

    append!(sumexps[1], vannualtechnologyemission[r,row[:t],e,y])

    lastkeys[1] = r
    lastkeys[2] = e
    lastkeys[3] = y
end

# Create last constraint
if isassigned(lastkeys, 1)
    e6_emissionsaccounting1[constraintnum] = @constraint(jumpmodel, sumexps[1] ==
        vannualemissions[lastkeys[1],lastkeys[2],lastkeys[3]])
end

logmsg("Created constraint E6_EmissionsAccounting1.", quiet)
# END: E6_EmissionsAccounting1.

# BEGIN: E7_EmissionsAccounting2.
constraintnum = 1  # Number of next constraint to be added to constraint array

@constraintref e7_emissionsaccounting2[1:length(sregion) * length(semission)]

for row in DataFrames.eachrow(SQLite.query(db, "select r.val as r, e.val as e, cast(mpe.val as real) as mpe
from region r, emission e
left join ModelPeriodExogenousEmission_def mpe on mpe.r = r.val and mpe.e = e.val"))
    local r = row[:r]
    local e = row[:e]
    local mpe = ismissing(row[:mpe]) ? 0 : row[:mpe]

    e7_emissionsaccounting2[constraintnum] = @constraint(jumpmodel, sum([vannualemissions[r,e,y] for y = syear]) == vmodelperiodemissions[r,e] - mpe)
    constraintnum += 1
end

logmsg("Created constraint E7_EmissionsAccounting2.", quiet)
# END: E7_EmissionsAccounting2.

# BEGIN: E8_AnnualEmissionsLimit.
constraintnum = 1  # Number of next constraint to be added to constraint array

@constraintref e8_annualemissionslimit[1:length(sregion) * length(semission) * length(syear)]

for row in DataFrames.eachrow(SQLite.query(db, "select r.val as r, e.val as e, y.val as y, cast(aee.val as real) as aee, cast(ael.val as real) as ael
from region r, emission e, year y, AnnualEmissionLimit_def ael
left join AnnualExogenousEmission_def aee on aee.r = r.val and aee.e = e.val and aee.y = y.val
where ael.r = r.val and ael.e = e.val and ael.y = y.val"))
    local r = row[:r]
    local e = row[:e]
    local y = row[:y]
    local aee = ismissing(row[:aee]) ? 0 : row[:aee]

    e8_annualemissionslimit[constraintnum] = @constraint(jumpmodel, vannualemissions[r,e,y] + aee <= row[:ael])
    constraintnum += 1
end

logmsg("Created constraint E8_AnnualEmissionsLimit.", quiet)
# END: E8_AnnualEmissionsLimit.

# BEGIN: E9_ModelPeriodEmissionsLimit.
constraintnum = 1  # Number of next constraint to be added to constraint array

@constraintref e9_modelperiodemissionslimit[1:length(sregion) * length(semission)]

for row in DataFrames.eachrow(SQLite.query(db, "select r.val as r, e.val as e, cast(mpl.val as real) as mpl
from region r, emission e, ModelPeriodEmissionLimit_def mpl
where mpl.r = r.val and mpl.e = e.val"))
    local r = row[:r]
    local e = row[:e]

    e9_modelperiodemissionslimit[constraintnum] = @constraint(jumpmodel, vmodelperiodemissions[r,e] <= row[:mpl])
    constraintnum += 1
end

logmsg("Created constraint E9_ModelPeriodEmissionsLimit.", quiet)
# END: E9_ModelPeriodEmissionsLimit.

# BEGIN: Perform customconstraints include.
if configfile != nothing && haskey(configfile, "includes", "customconstraints")
    try
        include(normpath(joinpath(pwd(), retrieve(configfile, "includes", "customconstraints"))))
        logmsg("Performed customconstraints include.", quiet)
    catch e
        logmsg("Could not perform customconstraints include. Error message: " * sprint(showerror, e) * ". Continuing with |nemo.", quiet)
    end
end
# END: Perform customconstraints include.

# END: Define model constraints.

# BEGIN: Define model objective.
@objective(jumpmodel, Min, sum([vtotaldiscountedcost[r,y] for r = sregion, y = syear]))
logmsg("Defined model objective.", quiet)
# END: Define model objective.

# Solve model
status::Symbol = solve(jumpmodel)
solvedtm::DateTime = now()  # Date/time of last solve operation
solvedtmstr::String = Dates.format(solvedtm, "yyyy-mm-dd HH:MM:SS.sss")  # solvedtm as a formatted string
logmsg("Solved model. Solver status = " * string(status) * ".", quiet, solvedtm)

# BEGIN: Save results to database.
savevarresults(varstosavearr, modelvarindices, db, solvedtmstr, reportzeros, quiet)
logmsg("Finished saving results to database.", quiet)
# END: Save results to database.

logmsg("Finished scenario calculation.")
return status
end  # calculatescenario()

"""
    calculategmpscenario(
    gmpdatapath::String,
    gmpmodelpath::String = normpath(joinpath(@__DIR__, "..", "utils", "gmpl2sql",
        "osemosys_2017_11_08_long.txt"));
    jumpmodel::JuMP.Model = Model(solver = GLPKSolverMIP(presolve=true)),
    varstosave::String = "vdemand, vnewstoragecapacity,
        vaccumulatednewstoragecapacity, vstorageupperlimit, vstoragelowerlimit,
        vcapitalinvestmentstorage, vdiscountedcapitalinvestmentstorage,
        vsalvagevaluestorage, vdiscountedsalvagevaluestorage, vnewcapacity,
        vaccumulatednewcapacity, vtotalcapacityannual,
        vtotaltechnologyannualactivity, vtotalannualtechnologyactivitybymode,
        vproductionbytechnologyannual, vproduction, vusebytechnologyannual,
        vusenn, vtrade, vtradeannual, vproductionannual, vuseannual,
        vcapitalinvestment, vdiscountedcapitalinvestment, vsalvagevalue,
        vdiscountedsalvagevalue, voperatingcost, vdiscountedoperatingcost,
        vtotaldiscountedcost",
    targetprocs::Array{Int, 1} = Array{Int, 1}([1]),
    quiet::Bool = false)

Runs |nemo for a scenario specified in a GNU MathProg data file. Saves results in a
|nemo-compatible SQLite database in same directory as GNU MathProg data file. Returns
a Symbol indicating the solve status reported by the solver.

# Arguments

- `gmpdatapath::String`: Path to GNU MathProg data file.
- `gmpmodelpath::String`: Path to GNU MathProg model file corresponding to data file.
- `jumpmodel::JuMP.Model`: JuMP model object specifying MIP solver to be used.
    Examples: Model(solver = GLPKSolverMIP(presolve=true)), Model(solver = CplexSolver()),
    Model(solver = CbcSolver(logLevel=1, presolve="on")).
    Note that solver package must be installed (GLPK and Cbc are installed with |nemo by
    default).
- `varstosave::String`: Comma-delimited list of model variables whose results should be
    saved in SQLite database.
- `targetprocs::Array{Int, 1}`: Processes that should be used for parallelized operations
    within this function.
- `quiet::Bool`: Suppresses low-priority status messages (which are otherwise printed to
    STDOUT).

!!! tip
For small models, performance may be improved by turning off the solver's presolve function. For
example, `jumpmodel = Model(solver = GLPKSolverMIP(presolve=false))` or
`jumpmodel = Model(solver = CbcSolver(logLevel=1, presolve="off"))`.
"""
function calculategmpscenario(
    gmpdatapath::String,
    gmpmodelpath::String = normpath(joinpath(@__DIR__, "..", "utils", "gmpl2sql", "osemosys_2017_11_08_long.txt"));
    jumpmodel::JuMP.Model = Model(solver = GLPKSolverMIP(presolve=true)),
    varstosave::String = "vdemand, vnewstoragecapacity, vaccumulatednewstoragecapacity, vstorageupperlimit, vstoragelowerlimit, vcapitalinvestmentstorage, vdiscountedcapitalinvestmentstorage, vsalvagevaluestorage, vdiscountedsalvagevaluestorage, vnewcapacity, vaccumulatednewcapacity, vtotalcapacityannual, vtotaltechnologyannualactivity, vtotalannualtechnologyactivitybymode, vproductionbytechnologyannual, vproduction, vusebytechnologyannual, vusenn, vtrade, vtradeannual, vproductionannual, vuseannual, vcapitalinvestment, vdiscountedcapitalinvestment, vsalvagevalue, vdiscountedsalvagevalue, voperatingcost, vdiscountedoperatingcost, vtotaldiscountedcost",
    targetprocs::Array{Int, 1} = Array{Int, 1}([1]),
    quiet::Bool = false)

    logmsg("Started conversion of MathProg data file.")

    # BEGIN: Validate arguments.
    if !isfile(gmpdatapath)
        error("gmpdatapath must refer to a file.")
    end

    if !isfile(gmpmodelpath)
        error("gmpmodelpath must refer to a file.")
    end

    logmsg("Validated run-time arguments.", quiet)
    # END: Validate arguments.

    # BEGIN: Convert data file into |nemo SQLite database.
    local gmp2sqlprog::String = normpath(joinpath(@__DIR__, "..", "utils", "gmpl2sql", "gmpl2sql.exe"))  # Full path to gmp2sql.exe
    run(`$gmp2sqlprog -d $gmpdatapath -m $gmpmodelpath`)
    # END: Convert data file into |nemo SQLite database.

    logmsg("Finished conversion of MathProg data file.")

    # Call calculatescenario()
    status::Symbol = calculatescenario(splitext(gmpdatapath)[1] * ".sl3"; jumpmodel=jumpmodel, varstosave=varstosave, targetprocs=targetprocs, quiet=quiet)
    return status
end  # calculategmpscenario()
