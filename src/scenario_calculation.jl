#=
    NEMO: Next Energy Modeling system for Optimization.
    https://github.com/sei-international/NemoMod.jl

    Copyright © 2018: Stockholm Environment Institute U.S.

    File description: Functions for calculating a NEMO scenario.
=#

"""
    calculatescenario(dbpath::String; jumpmodel::JuMP.Model = Model(Cbc.Optimizer),
        calcyears::Array{Int, 1} = Array{Int, 1}(),
        varstosave::String = "vdemandnn, vnewcapacity, vtotalcapacityannual,
            vproductionbytechnologyannual, vproductionnn, vusebytechnologyannual,
            vusenn, vtotaldiscountedcost",
        restrictvars::Bool = true, reportzeros::Bool = false,
        continuoustransmission::Bool = false,
        forcemip::Bool = false, startvalsdbpath::String = "",
        startvalsvars::String = "", precalcresultspath::String = "",
        quiet::Bool = false
    )

Calculates a scenario specified in a scenario database. Returns a `MathOptInterface.TerminationStatusCode` indicating
the termination status reported by the solver used for the calculation (e.g., `OPTIMAL::TerminationStatusCode = 1`).

# Arguments
- `dbpath::String`: Path to the scenario database, which must be a SQLite version 3 database that
    implements NEMO's scenario database structure. See NEMO's documentation on scenario databases
    for details. Empty scenario databases can be generated with NEMO's `createnemodb` function.
- `jumpmodel::JuMP.Model`: [JuMP](https://github.com/jump-dev/JuMP.jl) model object
    specifying the solver to be used for the calculation.
    Examples: `Model(optimizer_with_attributes(GLPK.Optimizer, "presolve" => true))`,
    `Model(CPLEX.Optimizer)`, `Model(optimizer_with_attributes(Gurobi.Optimizer, "NumericFocus" => 1))`.
    Note that the solver's Julia package (Julia wrapper) must be installed. See the
    documentation for JuMP for information on how to specify a solver and set solver options.
- `calcyears::Array{Int, 1}`: Years to include in the calculation (a subset of the years specified in
    the scenario database). All years in the database are included if this argument is omitted.
- `varstosave::String`: Comma-delimited list of output variables whose results should be
    saved in the scenario database when the scenario is calculated. See NEMO's documentation on
    outputs for information on the variables that are available.
- `restrictvars::Bool`: Indicates whether NEMO should conduct additional data analysis
    to limit the set of variables created in the optimization problem for the scenario.
    By default, to improve performance, NEMO selectively creates certain variables to
    avoid combinations of subscripts that do not exist in the scenario's data. This option
    increases the stringency of this filtering. It requires more processing time as the
    problem is built, but it can substantially reduce the solve time for large models.
- `reportzeros::Bool`: Indicates whether results saved in the scenario database should
    include values equal to zero. Specifying `false` can substantially improve the
    performance of large models.
- `continuoustransmission::Bool`: Indicates whether continuous (`true`) or binary (`false`)
    variables are used to represent investment decisions for candidate transmission lines. Not
    relevant in scenarios that do not model transmission.
- `forcemip::Bool`: Forces NEMO to formulate the optimization problem for the scenario as a
    mixed-integer problem. This can improve performance with some solvers (e.g., CPLEX, Mosek). If
    this option is set to `false`, the input parameters for the scenario (i.e., in the scenario
    database) determine whether the optimization problem is mixed-integer.
- `startvalsdbpath::String`: Path to a previously calculated scenario database from which NEMO
    should take starting values for variables in the optimization problem formulated in this
    function. This argument is used in conjunction with `startvalsvars`.
- `startvalsvars::String`: Comma-delimited list of variables for which starting values should be set.
    See NEMO's documentation on outputs for information on the variables that are available. NEMO
    takes starting values from output variable results saved in the database identified by
    `startvalsdbpath`. Saved results are matched to variables in the optimization problem using
    the variables' subscripts, and starting values are set with JuMP's `set_start_value` function.
    If `startvalsvars` is an empty string, NEMO sets starting values for all variables present in
    both the optimization problem and the `startvalsdbpath` database.
- `precalcresultspath::String`: Path to a previously calculated scenario database that NEMO should
    copy over the database specified by `dbpath`. This argument can also be a directory containing
    previously calculated scenario databases, in which case NEMO copies any file in the directory
    with the same name as the `dbpath` database. The intent of the argument is to short-circuit
    calculations in situations where valid results already exist.
- `quiet::Bool`: Suppresses low-priority status messages (which are otherwise printed to
    `STDOUT`).
"""
function calculatescenario(
    dbpath::String;
    jumpmodel::JuMP.Model = Model(Cbc.Optimizer),
    calcyears::Array{Int, 1} = Array{Int, 1}(),
    varstosave::String = "vdemandnn, vnewcapacity, vtotalcapacityannual, vproductionbytechnologyannual, vproductionnn, vusebytechnologyannual, vusenn, vtotaldiscountedcost",
    numprocs::Int = 0,
    targetprocs::Array{Int, 1} = Array{Int, 1}(),
    restrictvars::Bool = true,
    reportzeros::Bool = false,
    continuoustransmission::Bool = false,
    forcemip::Bool = false,
    startvalsdbpath::String = "",
    startvalsvars::String = "",
    precalcresultspath::String = "",
    quiet::Bool = false)

    try
        modelscenario(dbpath; jumpmodel=jumpmodel, calcyears=calcyears, varstosave=varstosave, restrictvars=restrictvars, reportzeros=reportzeros,
            continuoustransmission=continuoustransmission, forcemip=forcemip, startvalsdbpath=startvalsdbpath, startvalsvars=startvalsvars,
            precalcresultspath=precalcresultspath, quiet=quiet)
    catch e
        println("NEMO encountered an error with the following message: " * sprint(showerror, e) * ".")
        println("To report this issue to the NEMO team, please submit an error report at https://leap.sei.org/support/. Please include in the report a list of steps to reproduce the error and the error message.")
    end
end  # calculatescenario()

"""
    modelscenario(dbpath::String;
        jumpmodel::JuMP.Model = Model(Cbc.Optimizer),
        calcyears::Array{Int, 1} = Array{Int, 1}(),
        varstosave::String = "vdemandnn, vnewcapacity, vtotalcapacityannual,
            vproductionbytechnologyannual, vproductionnn, vusebytechnologyannual,
            vusenn, vtotaldiscountedcost",
        restrictvars::Bool = true,
        reportzeros::Bool = false, continuoustransmission::Bool = false,
        forcemip::Bool = false,
        startvalsdbpath::String = "",
        startvalsvars::String = "",
        precalcresultspath::String = "",
        quiet::Bool = false,
        writemodel::Bool = false, writefilename::String = "",
        writefileformat::MathOptInterface.FileFormats.FileFormat = MathOptInterface.FileFormats.FORMAT_MPS
    )

Implements scenario modeling logic for calculatescenario() and writescenariomodel().
"""
function modelscenario(
    dbpath::String;
    jumpmodel::JuMP.Model = Model(Cbc.Optimizer),
    calcyears::Array{Int, 1} = Array{Int, 1}(),
    varstosave::String = "vdemandnn, vnewcapacity, vtotalcapacityannual, vproductionbytechnologyannual, vproductionnn, vusebytechnologyannual, vusenn, vtotaldiscountedcost",
    restrictvars::Bool = true,
    reportzeros::Bool = false,
    continuoustransmission::Bool = false,
    forcemip = false,
    startvalsdbpath::String = "",
    startvalsvars::String = "",
    precalcresultspath::String = "",
    quiet::Bool = false,
    writemodel::Bool = false,
    writefilename::String = "",
    writefileformat::MathOptInterface.FileFormats.FileFormat = MathOptInterface.FileFormats.FORMAT_MPS
    )
# Lines within modelscenario() are not indented since the function is so lengthy. To make an otherwise local
# variable visible outside the function, prefix it with global. For JuMP constraint references,
# create a new global variable and assign to it the constraint reference.

logmsg("Started modeling scenario.")

# BEGIN: Validate arguments.
if !isfile(dbpath)
    error("dbpath argument must refer to a file.")
end

# Convert varstosave into an array of strings with no empty values
local varstosavearr = String.(split(replace(varstosave, " " => ""), ","; keepempty = false))

if writemodel && length(writefilename) == 0
    error("writefilename argument must be specified if writemodel is true.")
end

logmsg("Validated run-time arguments.", quiet)
# END: Validate arguments.

# BEGIN: Read config file and process calculatescenarioargs and solver blocks.
configfile = getconfig(quiet)  # ConfParse structure for config file if one is found; otherwise nothing

if configfile != nothing
    local jumpdirectmode::Bool = (mode(jumpmodel) == JuMP.DIRECT)  # Indicates whether jumpmodel is in direct mode
    local jumpbridges::Bool = (jumpdirectmode ? false : (typeof(backend(jumpmodel).optimizer) <: MathOptInterface.Bridges.LazyBridgeOptimizer))  # Indicates whether bridging is enabled in jumpmodel

    # Arrays of Boolean and string arguments for calculatescenario(); necessary in order to have mutable objects for getconfigargs! call
    local boolargs::Array{Bool,1} = [restrictvars,reportzeros,continuoustransmission,forcemip,quiet,jumpdirectmode,jumpbridges]
    local stringargs::Array{String,1} = [startvalsdbpath,startvalsvars,precalcresultspath]

    getconfigargs!(configfile, calcyears, varstosavearr, boolargs, stringargs, quiet)

    restrictvars = boolargs[1]
    reportzeros = boolargs[2]
    continuoustransmission = boolargs[3]
    forcemip = boolargs[4]
    quiet = boolargs[5]

    startvalsdbpath = stringargs[1]
    startvalsvars = stringargs[2]
    precalcresultspath = stringargs[3]

    if jumpdirectmode != boolargs[6] || jumpbridges != boolargs[7]
        reset_jumpmodel(jumpmodel; direct=boolargs[6], bridges=boolargs[7])
    end

    setsolverparamsfromcfg(configfile, jumpmodel, quiet)
end
# END: Read config file and process calculatescenarioargs and solver blocks.

# BEGIN: Check precalcresultspath and return pre-calculated scenario database if appropriate.
if length(precalcresultspath) > 0
    local precalcfilepath::String = ""  # Full path to pre-calculated scenario database, if precalcresultspath identifies one

    if isfile(precalcresultspath)
        precalcfilepath = normpath(precalcresultspath)
    elseif isdir(precalcresultspath)
        local testpcf::String = normpath(joinpath(precalcresultspath, basename(realpath(dbpath))))

        if isfile(testpcf)
            precalcfilepath = testpcf
        end
    end

    if length(precalcfilepath) > 0
        cp(precalcfilepath, dbpath; force=true, follow_symlinks=true)
        logmsg("Copied pre-calculated results file $precalcfilepath to $(realpath(dbpath)). Finished modeling scenario." )
        return termination_status(jumpmodel)
    end

    logmsg("Could not identify a pre-calculated results file using precalcresultspath argument. Continuing with NEMO." )
end
# END: Check precalcresultspath and return pre-calculated scenario database if appropriate.

# BEGIN: Check whether modeling is for selected years only.
local restrictyears::Bool = (calcyears == Array{Int, 1}() ? false : true)  # Indicates whether scenario modeling is for a selected set of years
local inyears::String = ""  # SQL in clause predicate indicating which years are selected for modeling

if restrictyears
    inyears = " (" * join(calcyears, ",") * ") "
end
# END: Check whether modeling is for selected years only.

# BEGIN: Set module global variables that depend on arguments.
global csdbpath = dbpath
global csquiet = quiet
global csrestrictyears = restrictyears
global csinyears = inyears

if configfile != nothing && haskey(configfile, "includes", "customconstraints")
    # Define global variable for jumpmodel
    global csjumpmodel = jumpmodel
end
# END: Set module global variables that depend on arguments.

# BEGIN: Connect to SQLite database.
db = SQLite.DB(dbpath)
logmsg("Connected to scenario database. Path = " * normpath(dbpath) * ".", quiet)
# END: Connect to SQLite database.

# BEGIN: Update database if necessary.
dbversion::Int64 = DataFrame(SQLite.DBInterface.execute(db, "select version from version"))[1, :version]

dbversion == 2 && db_v2_to_v3(db; quiet = quiet)
dbversion < 4 && db_v3_to_v4(db; quiet = quiet)
dbversion < 5 && db_v4_to_v5(db; quiet = quiet)
dbversion < 6 && db_v5_to_v6(db; quiet = quiet)
dbversion < 7 && db_v6_to_v7(db; quiet = quiet)
dbversion < 8 && db_v7_to_v8(db; quiet = quiet)
dbversion < 9 && db_v8_to_v9(db; quiet = quiet)
dbversion < 10 && db_v9_to_v10(db; quiet = quiet)
# END: Update database if necessary.

# BEGIN: Perform beforescenariocalc include.
if configfile != nothing && haskey(configfile, "includes", "beforescenariocalc")
    try
        include(normpath(joinpath(pwd(), retrieve(configfile, "includes", "beforescenariocalc"))))
        logmsg("Performed beforescenariocalc include.", quiet)
    catch e
        logmsg("Could not perform beforescenariocalc include. Error message: " * sprint(showerror, e) * ". Continuing with NEMO.", quiet)
    end
end
# END: Perform beforescenariocalc include.

# BEGIN: Drop any pre-existing result tables.
dropresulttables(db, true)
logmsg("Dropped pre-existing result tables from database.", quiet)
# END: Drop any pre-existing result tables.

# BEGIN: Check if transmission modeling is required.
local transmissionmodeling::Bool = false  # Indicates whether scenario involves transmission modeling
local tempquery::SQLite.Query = SQLite.DBInterface.execute(db,
    "select distinct type from TransmissionModelingEnabled $(restrictyears ? " where y in" * inyears : "")")  # Temporary SQLite.Query object
local transmissionmodelingtypes::Array{Int64, 1} = SQLite.done(tempquery) ? Array{Int64, 1}() : collect(skipmissing(DataFrame(tempquery)[!, :type]))
    # Array of transmission modeling types requested for scenario

if length(transmissionmodelingtypes) > 0
    transmissionmodeling = true
end

logmsg("Verified that transmission modeling " * (transmissionmodeling ? "is" : "is not") * " enabled.", quiet)
# END: Check if transmission modeling is required.

# BEGIN: Create parameter views showing default values and parameter indices.
# Array of parameter tables needing default views in scenario database
local paramsneedingdefs::Array{String, 1} = ["OutputActivityRatio", "InputActivityRatio", "ResidualCapacity", "OperationalLife",
"FixedCost", "YearSplit", "SpecifiedAnnualDemand", "SpecifiedDemandProfile", "VariableCost", "DiscountRate", "CapitalCost",
"CapitalCostStorage", "CapacityFactor", "CapacityToActivityUnit", "CapacityOfOneTechnologyUnit", "AvailabilityFactor",
"TradeRoute", "TechnologyToStorage", "TechnologyFromStorage", "StorageLevelStart", "StorageMaxChargeRate", "StorageMaxDischargeRate",
"ResidualStorageCapacity", "MinStorageCharge", "OperationalLifeStorage", "DepreciationMethod", "TotalAnnualMaxCapacity",
"TotalAnnualMinCapacity", "TotalAnnualMaxCapacityInvestment", "TotalAnnualMinCapacityInvestment",
"TotalTechnologyAnnualActivityUpperLimit", "TotalTechnologyAnnualActivityLowerLimit", "TotalTechnologyModelPeriodActivityUpperLimit",
"TotalTechnologyModelPeriodActivityLowerLimit", "ReserveMarginTagTechnology", "ReserveMargin", "RETagTechnology",
"REMinProductionTarget", "REMinProductionTargetRG", "EmissionActivityRatio", "EmissionsPenalty", "ModelPeriodExogenousEmission",
"AnnualExogenousEmission", "AnnualEmissionLimit", "ModelPeriodEmissionLimit", "AccumulatedAnnualDemand", "TotalAnnualMaxCapacityStorage",
"TotalAnnualMinCapacityStorage", "TotalAnnualMaxCapacityInvestmentStorage", "TotalAnnualMinCapacityInvestmentStorage",
"TransmissionCapacityToActivityUnit", "StorageFullLoadHours", "RampRate", "RampingReset", "NodalDistributionDemand",
"NodalDistributionTechnologyCapacity", "NodalDistributionStorageCapacity", "MinimumUtilization", "InterestRateTechnology",
"InterestRateStorage", "MinShareProduction"]

createviewwithdefaults(db, paramsneedingdefs)
create_other_nemo_indices(db)

logmsg("Created parameter views and indices.", quiet)
# END: Create parameter views showing default values and parameter indices.

# BEGIN: Create temporary tables.
# These tables are created as ordinary tables, not SQLite temporary tables, in order to make them simultaneously visible to multiple Julia processes
create_temp_tables(db)
logmsg("Created temporary tables.", quiet)
# END: Create temporary tables.

# BEGIN: Execute database queries in parallel.
querycommands::Dict{String, Tuple{String, String}} = scenario_calc_queries(dbpath, transmissionmodeling,
    in("vproductionbytechnology", varstosavearr), in("vusebytechnology", varstosavearr), restrictyears, inyears)
queries::Dict{String, DataFrame} = run_queries(querycommands)

logmsg("Executed core database queries.", quiet)
# END: Execute database queries in parallel.

# BEGIN: Define dimensions.
tempquery = SQLite.DBInterface.execute(db, "select val from YEAR $(restrictyears ? "where val in" * inyears : "") order by val")
syear::Array{String,1} = SQLite.done(tempquery) ? Array{String,1}() : collect(skipmissing(DataFrame(tempquery)[!, :val]))  # YEAR dimension
tempquery = SQLite.DBInterface.execute(db, "select min(val) from year")
firstscenarioyear::Int64 = parse(Int, DataFrame(tempquery)[1,1])  # First year in YEAR table, even if not selected in calcyears
tempquery = SQLite.DBInterface.execute(db, "select max(val) from year")
lastscenarioyear::Int64 = parse(Int, DataFrame(tempquery)[1,1])  # Last year in YEAR table, even if not selected in calcyears
tempquery = SQLite.DBInterface.execute(db, "select val from TECHNOLOGY")
stechnology::Array{String,1} = SQLite.done(tempquery) ? Array{String,1}() : collect(skipmissing(DataFrame(tempquery)[!, :val]))  # TECHNOLOGY dimension
tempquery = SQLite.DBInterface.execute(db, "select val from TIMESLICE")
stimeslice::Array{String,1} = SQLite.done(tempquery) ? Array{String,1}() : collect(skipmissing(DataFrame(tempquery)[!, :val]))  # TIMESLICE dimension
tempquery = SQLite.DBInterface.execute(db, "select val from FUEL")
sfuel::Array{String,1} = SQLite.done(tempquery) ? Array{String,1}() : collect(skipmissing(DataFrame(tempquery)[!, :val]))  # FUEL dimension
tempquery = SQLite.DBInterface.execute(db, "select val from EMISSION")
semission::Array{String,1} = SQLite.done(tempquery) ? Array{String,1}() : collect(skipmissing(DataFrame(tempquery)[!, :val]))  # EMISSION dimension
tempquery = SQLite.DBInterface.execute(db, "select val from MODE_OF_OPERATION")
smode_of_operation::Array{String,1} = SQLite.done(tempquery) ? Array{String,1}() : collect(skipmissing(DataFrame(tempquery)[!, :val]))  # MODE_OF_OPERATION dimension
tempquery = SQLite.DBInterface.execute(db, "select val from REGION")
sregion::Array{String,1} = SQLite.done(tempquery) ? Array{String,1}() : collect(skipmissing(DataFrame(tempquery)[!, :val]))  # REGION dimension
tempquery = SQLite.DBInterface.execute(db, "select val from STORAGE")
sstorage::Array{String,1} = SQLite.done(tempquery) ? Array{String,1}() : collect(skipmissing(DataFrame(tempquery)[!, :val]))  # STORAGE dimension
tempquery = SQLite.DBInterface.execute(db, "select name from TSGROUP1")
stsgroup1::Array{String,1} = SQLite.done(tempquery) ? Array{String,1}() : collect(skipmissing(DataFrame(tempquery)[!, :name]))  # Time slice group 1 dimension
tempquery = SQLite.DBInterface.execute(db, "select name from TSGROUP2")
stsgroup2::Array{String,1} = SQLite.done(tempquery) ? Array{String,1}() : collect(skipmissing(DataFrame(tempquery)[!, :name]))  # Time slice group 2 dimension

if transmissionmodeling
    tempquery = SQLite.DBInterface.execute(db, "select val from NODE")
    snode::Array{String,1} = SQLite.done(tempquery) ? Array{String,1}() : collect(skipmissing(DataFrame(tempquery)[!, :val]))  # Node dimension
    tempquery = SQLite.DBInterface.execute(db, "select id from TransmissionLine")
    stransmission::Array{String,1} = SQLite.done(tempquery) ? Array{String,1}() : collect(skipmissing(DataFrame(tempquery)[!, :id]))  # Transmission line dimension
end

tsgroup1dict::Dict{Int, Tuple{String, Float64}} = Dict{Int, Tuple{String, Float64}}(row[:order] => (row[:name], row[:multiplier]) for row in
    SQLite.DBInterface.execute(db, "select [order], name, cast (multiplier as real) as multiplier from tsgroup1 order by [order]"))
    # For TSGROUP1, a dictionary mapping orders to tuples of (name, multiplier)
tsgroup2dict::Dict{Int, Tuple{String, Float64}} = Dict{Int, Tuple{String, Float64}}(row[:order] => (row[:name], row[:multiplier]) for row in
    SQLite.DBInterface.execute(db, "select [order], name, cast (multiplier as real) as multiplier from tsgroup2 order by [order]"))
    # For TSGROUP2, a dictionary mapping orders to tuples of (name, multiplier)
ltsgroupdict::Dict{Tuple{Int, Int, Int}, String} = Dict{Tuple{Int, Int, Int}, String}((row[:tg1o], row[:tg2o], row[:lo]) => row[:l] for row in
    SQLite.DBInterface.execute(db, "select ltg.l as l, ltg.lorder as lo, ltg.tg2, tg2.[order] as tg2o, ltg.tg1, tg1.[order] as tg1o
    from LTsGroup ltg, TSGROUP2 tg2, TSGROUP1 tg1
    where
    ltg.tg2 = tg2.name
    and ltg.tg1 = tg1.name"))  # Dictionary of LTsGroup table mapping tuples of (tsgroup1 order, tsgroup2 order, time slice order) to time slice vals
yearintervalsdict::Dict{String, Int} = Dict{String,Int}()  # A dictionary mapping years that are being modeled to the number of years in the intervals they represent. For a given modeled year, the corresponding interval contains years that are <= modeled year and > prior modeled year or first year in YEAR - 1, whichever is later.

for row in SQLite.DBInterface.execute(db, "select y, intv + case when rn = 1 then 1 else 0 end as intv from (
	select y, ifnull(lag_calc, 0) as intv, row_number() over (order by y) as rn from (
		select val as y, val - lag(val) over (order by val) as lag_calc
			from year
            $(restrictyears ? "where val = (select min(val) from year) or val in" * inyears : "")
	) $(restrictyears ? "where y in" * inyears : "")
)")
    yearintervalsdict[row[:y]] = row[:intv]
end

logmsg("Defined dimensions.", quiet)
# END: Define dimensions.

# BEGIN: Define model variables.
modelvarindices::Dict{String, Tuple{AbstractArray,Array{String,1}}} = Dict{String, Tuple{AbstractArray,Array{String,1}}}()
# Dictionary mapping model variable names to tuples of (variable, [index column names]); must have an entry here in order to save
#   variable's results back to database

# Demands
if in("vrateofdemandnn", varstosavearr)
    @variable(jumpmodel, vrateofdemandnn[sregion, stimeslice, sfuel, syear] >= 0)
    modelvarindices["vrateofdemandnn"] = (vrateofdemandnn, ["r","l","f","y"])
end

@variable(jumpmodel, vdemandnn[sregion, stimeslice, sfuel, syear] >= 0)
modelvarindices["vdemandnn"] = (vdemandnn, ["r","l","f","y"])

@variable(jumpmodel, vdemandannualnn[sregion, sfuel, syear] >= 0)
modelvarindices["vdemandannualnn"] = (vdemandannualnn, ["r","f","y"])

logmsg("Defined demand variables.", quiet)

# Storage
@variable(jumpmodel, vstorageleveltsgroup1startnn[sregion, sstorage, stsgroup1, syear] >= 0)
@variable(jumpmodel, vstorageleveltsgroup1endnn[sregion, sstorage, stsgroup1, syear] >= 0)
@variable(jumpmodel, vstorageleveltsgroup2startnn[sregion, sstorage, stsgroup1, stsgroup2, syear] >= 0)
@variable(jumpmodel, vstorageleveltsgroup2endnn[sregion, sstorage, stsgroup1, stsgroup2, syear] >= 0)
@variable(jumpmodel, vstorageleveltsendnn[sregion, sstorage, stimeslice, syear] >= 0)  # Storage level at end of first hour in time slice
@variable(jumpmodel, vstoragelevelyearendnn[sregion, sstorage, syear] >= 0)
@variable(jumpmodel, vrateofstoragechargenn[sregion, sstorage, stimeslice, syear] >= 0)
@variable(jumpmodel, vrateofstoragedischargenn[sregion, sstorage, stimeslice, syear] >= 0)
@variable(jumpmodel, vstoragelowerlimit[sregion, sstorage, syear] >= 0)
@variable(jumpmodel, vstorageupperlimit[sregion, sstorage, syear] >= 0)
@variable(jumpmodel, vaccumulatednewstoragecapacity[sregion, sstorage, syear] >= 0)
@variable(jumpmodel, vnewstoragecapacity[sregion, sstorage, syear] >= 0)
@variable(jumpmodel, vfinancecoststorage[sregion, sstorage, syear] >= 0)
@variable(jumpmodel, vcapitalinvestmentstorage[sregion, sstorage, syear] >= 0)
@variable(jumpmodel, vdiscountedcapitalinvestmentstorage[sregion, sstorage, syear] >= 0)
@variable(jumpmodel, vsalvagevaluestorage[sregion, sstorage, syear] >= 0)
@variable(jumpmodel, vdiscountedsalvagevaluestorage[sregion, sstorage, syear] >= 0)
@variable(jumpmodel, vtotaldiscountedstoragecost[sregion, sstorage, syear] >= 0)

modelvarindices["vstorageleveltsgroup1startnn"] = (vstorageleveltsgroup1startnn, ["r", "s", "tg1", "y"])
modelvarindices["vstorageleveltsgroup1endnn"] = (vstorageleveltsgroup1endnn, ["r", "s", "tg1", "y"])
modelvarindices["vstorageleveltsgroup2startnn"] = (vstorageleveltsgroup2startnn, ["r", "s", "tg1", "tg2", "y"])
modelvarindices["vstorageleveltsgroup2endnn"] = (vstorageleveltsgroup2endnn, ["r", "s", "tg1", "tg2", "y"])
modelvarindices["vstorageleveltsendnn"] = (vstorageleveltsendnn, ["r", "s", "l", "y"])
modelvarindices["vstoragelevelyearendnn"] = (vstoragelevelyearendnn, ["r", "s", "y"])
modelvarindices["vrateofstoragechargenn"] = (vrateofstoragechargenn, ["r", "s", "l", "y"])
modelvarindices["vrateofstoragedischargenn"] = (vrateofstoragedischargenn, ["r", "s", "l", "y"])
modelvarindices["vstoragelowerlimit"] = (vstoragelowerlimit, ["r", "s", "y"])
modelvarindices["vstorageupperlimit"] = (vstorageupperlimit, ["r", "s", "y"])
modelvarindices["vaccumulatednewstoragecapacity"] = (vaccumulatednewstoragecapacity, ["r", "s", "y"])
modelvarindices["vnewstoragecapacity"] = (vnewstoragecapacity, ["r", "s", "y"])
modelvarindices["vfinancecoststorage"] = (vfinancecoststorage, ["r", "s", "y"])
modelvarindices["vcapitalinvestmentstorage"] = (vcapitalinvestmentstorage, ["r", "s", "y"])
modelvarindices["vdiscountedcapitalinvestmentstorage"] = (vdiscountedcapitalinvestmentstorage, ["r", "s", "y"])
modelvarindices["vsalvagevaluestorage"] = (vsalvagevaluestorage, ["r", "s", "y"])
modelvarindices["vdiscountedsalvagevaluestorage"] = (vdiscountedsalvagevaluestorage, ["r", "s", "y"])
modelvarindices["vtotaldiscountedstoragecost"] = (vtotaldiscountedstoragecost, ["r", "s", "y"])
logmsg("Defined storage variables.", quiet)

# Capacity
# If forcemip is in effect, create an integer variable here
if in("vnumberofnewtechnologyunits", varstosavearr) || size(queries["querycaa5_totalnewcapacity"])[1] > 0 || forcemip
    @variable(jumpmodel, vnumberofnewtechnologyunits[sregion, stechnology, syear] >= 0, Int)
    modelvarindices["vnumberofnewtechnologyunits"] = (vnumberofnewtechnologyunits, ["r", "t", "y"])
end

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

(annualactivityupperlimits, modelperiodactivityupperlimits) = checkactivityupperlimits(db, 10000.0, restrictyears, inyears)

# Disable model period activity checks when modeling selected years
if restrictyears
    modelperiodactivityupperlimits && @warn "Model period activity upper limits for technologies (TotalTechnologyModelPeriodActivityUpperLimit parameter) are not enforced when modeling selected years."
    modelperiodactivityupperlimits = false
end

local annualactivitylowerlimits::Bool = true
# Indicates whether constraints for TotalTechnologyAnnualActivityLowerLimit should be added to model
local modelperiodactivitylowerlimits::Bool = true
# Indicates whether constraints for TotalTechnologyModelPeriodActivityLowerLimit should be added to model

queryannualactivitylowerlimit::SQLite.Query = SQLite.DBInterface.execute(db, "select r, t, y, cast(val as real) as amn
    from TotalTechnologyAnnualActivityLowerLimit_def
    where val > 0 $(restrictyears ? "and y in" * inyears : "")")

if SQLite.done(queryannualactivitylowerlimit)
    annualactivitylowerlimits = false
end

querymodelperiodactivitylowerlimit::SQLite.Query = SQLite.DBInterface.execute(db, "select r, t, cast(val as real) as mmn
    from TotalTechnologyModelPeriodActivityLowerLimit_def
    where val > 0")

if SQLite.done(querymodelperiodactivitylowerlimit)
    modelperiodactivitylowerlimits = false
elseif restrictyears
    @warn "Model period activity lower limits for technologies (TotalTechnologyModelPeriodActivityLowerLimit parameter) are not enforced when modeling selected years."
    modelperiodactivitylowerlimits = false
end

if restrictvars
    indexdicts = keydicts_threaded(queries["queryvrateofactivityvar"], 4)  # Array of Dicts used to restrict indices of following variable
    @variable(jumpmodel, vrateofactivity[r=[k[1] for k = keys(indexdicts[1])], l=indexdicts[1][[r]], t=indexdicts[2][[r,l]],
        m=indexdicts[3][[r,l,t]], y=indexdicts[4][[r,l,t,m]]] >= 0)
else
    @variable(jumpmodel, vrateofactivity[sregion, stimeslice, stechnology, smode_of_operation, syear] >= 0)
end

modelvarindices["vrateofactivity"] = (vrateofactivity, ["r", "l", "t", "m", "y"])

@variable(jumpmodel, vrateoftotalactivity[sregion, stechnology, stimeslice, syear] >= 0)
modelvarindices["vrateoftotalactivity"] = (vrateoftotalactivity, ["r", "t", "l", "y"])

if (annualactivityupperlimits || annualactivitylowerlimits || modelperiodactivityupperlimits || modelperiodactivitylowerlimits
    || in("vtotaltechnologyannualactivity", varstosavearr) || in("vtotaltechnologymodelperiodactivity", varstosavearr))

    @variable(jumpmodel, vtotaltechnologyannualactivity[sregion, stechnology, syear] >= 0)
    modelvarindices["vtotaltechnologyannualactivity"] = (vtotaltechnologyannualactivity, ["r", "t", "y"])
end

@variable(jumpmodel, vtotalannualtechnologyactivitybymode[sregion, stechnology, smode_of_operation, syear] >= 0)
modelvarindices["vtotalannualtechnologyactivitybymode"] = (vtotalannualtechnologyactivitybymode, ["r", "t", "m", "y"])

if modelperiodactivityupperlimits || modelperiodactivitylowerlimits || in("vtotaltechnologymodelperiodactivity", varstosavearr)
    @variable(jumpmodel, vtotaltechnologymodelperiodactivity[sregion, stechnology])
    modelvarindices["vtotaltechnologymodelperiodactivity"] = (vtotaltechnologymodelperiodactivity, ["r", "t"])
end

if in("vproductionbytechnology", varstosavearr)
    # Overall query showing indices of vproductionbytechnology; nodal contributions will be added later if needed
    queryvproductionbytechnologyindices::DataFrames.DataFrame = queries["queryvrateofproductionbytechnologynn"]
end

if restrictvars
    if in("vrateofproductionbytechnologybymodenn", varstosavearr)
        indexdicts = keydicts_threaded(queries["queryvrateofproductionbytechnologybymodenn"], 5)  # Array of Dicts used to restrict indices of following variable
        @variable(jumpmodel, vrateofproductionbytechnologybymodenn[r=[k[1] for k = keys(indexdicts[1])], l=indexdicts[1][[r]], t=indexdicts[2][[r,l]],
            m=indexdicts[3][[r,l,t]], f=indexdicts[4][[r,l,t,m]], y=indexdicts[5][[r,l,t,m,f]]] >= 0)
    end

    indexdicts = keydicts_threaded(queries["queryvrateofproductionbytechnologynn"], 4)  # Array of Dicts used to restrict indices of following variable
    @variable(jumpmodel, vrateofproductionbytechnologynn[r=[k[1] for k = keys(indexdicts[1])], l=indexdicts[1][[r]], t=indexdicts[2][[r,l]],
        f=indexdicts[3][[r,l,t]], y=indexdicts[4][[r,l,t,f]]] >= 0)

    indexdicts = keydicts_threaded(queries["queryvproductionbytechnologyannual"], 3)  # Array of Dicts used to restrict indices of vproductionbytechnologyannual
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

if in("vusebytechnology", varstosavearr)
    # Overall query showing indices of vusebytechnology; nodal contributions will be added later if needed
    queryvusebytechnologyindices::DataFrames.DataFrame = queries["queryvrateofusebytechnologynn"]
end

if restrictvars
    if in("vrateofusebytechnologybymodenn", varstosavearr)
        indexdicts = keydicts_threaded(queries["queryvrateofusebytechnologybymodenn"], 5)  # Array of Dicts used to restrict indices of following variable
        @variable(jumpmodel, vrateofusebytechnologybymodenn[r=[k[1] for k = keys(indexdicts[1])], l=indexdicts[1][[r]], t=indexdicts[2][[r,l]],
            m=indexdicts[3][[r,l,t]], f=indexdicts[4][[r,l,t,m]], y=indexdicts[5][[r,l,t,m,f]]] >= 0)
    end

    indexdicts = keydicts_threaded(queries["queryvrateofusebytechnologynn"], 4)  # Array of Dicts used to restrict indices of following variable
    @variable(jumpmodel, vrateofusebytechnologynn[r=[k[1] for k = keys(indexdicts[1])], l=indexdicts[1][[r]], t=indexdicts[2][[r,l]],
        f=indexdicts[3][[r,l,t]], y=indexdicts[4][[r,l,t,f]]] >= 0)

    indexdicts = keydicts_threaded(queries["queryvusebytechnologyannual"], 3)  # Array of Dicts used to restrict indices of vusebytechnologyannual
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

if restrictvars
    indexdicts = keydicts_threaded(queries["queryvtrade"], 4)  # Array of Dicts used to restrict indices of following variable
    @variable(jumpmodel, vtrade[r=[k[1] for k = keys(indexdicts[1])], rr=indexdicts[1][[r]], l=indexdicts[2][[r,rr]],
        f=indexdicts[3][[r,rr,l]], y=indexdicts[4][[r,rr,l,f]]] >= 0)

    indexdicts = keydicts_threaded(queries["queryvtradeannual"], 3)  # Array of Dicts used to restrict indices of following variable
    @variable(jumpmodel, vtradeannual[r=[k[1] for k = keys(indexdicts[1])], rr=indexdicts[1][[r]], f=indexdicts[2][[r,rr]],
        y=indexdicts[3][[r,rr,f]]])
else
    @variable(jumpmodel, vtrade[sregion, sregion, stimeslice, sfuel, syear] >= 0)
    @variable(jumpmodel, vtradeannual[sregion, sregion, sfuel, syear])
end

modelvarindices["vtrade"] = (vtrade, ["r", "rr", "l", "f", "y"])
modelvarindices["vtradeannual"] = (vtradeannual, ["r", "rr", "f", "y"])

@variable(jumpmodel, vproductionannualnn[sregion, sfuel, syear] >= 0)
modelvarindices["vproductionannualnn"] = (vproductionannualnn, ["r", "f", "y"])
@variable(jumpmodel, vgenerationannualnn[sregion, sfuel, syear] >= 0)
modelvarindices["vgenerationannualnn"] = (vgenerationannualnn, ["r", "f", "y"])
@variable(jumpmodel, vregenerationannualnn[sregion, sfuel, syear] >= 0)
modelvarindices["vregenerationannualnn"] = (vregenerationannualnn, ["r", "f", "y"])
@variable(jumpmodel, vuseannualnn[sregion, sfuel, syear] >= 0)
modelvarindices["vuseannualnn"] = (vuseannualnn, ["r", "f", "y"])
logmsg("Defined activity variables.", quiet)

# Costing
@variable(jumpmodel, vfinancecost[sregion, stechnology, syear] >= 0)
modelvarindices["vfinancecost"] = (vfinancecost, ["r", "t", "y"])
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
@variable(jumpmodel, vtotaldiscountedcostbytechnology[sregion, stechnology, syear])
modelvarindices["vtotaldiscountedcostbytechnology"] = (vtotaldiscountedcostbytechnology, ["r", "t", "y"])
@variable(jumpmodel, vtotaldiscountedcost[sregion, syear])
modelvarindices["vtotaldiscountedcost"] = (vtotaldiscountedcost, ["r", "y"])

if in("vmodelperiodcostbyregion", varstosavearr)
    @variable(jumpmodel, vmodelperiodcostbyregion[sregion])
    modelvarindices["vmodelperiodcostbyregion"] = (vmodelperiodcostbyregion, ["r"])
end

logmsg("Defined costing variables.", quiet)

# Reserve margin
@variable(jumpmodel, vtotalcapacityinreservemargin[sregion, sfuel, syear] >= 0)
modelvarindices["vtotalcapacityinreservemargin"] = (vtotalcapacityinreservemargin, ["r", "f", "y"])

logmsg("Defined reserve margin variables.", quiet)

# Emissions
if in("vannualtechnologyemissionbymode", varstosavearr)
    @variable(jumpmodel, vannualtechnologyemissionbymode[sregion, stechnology, semission, smode_of_operation, syear])
    modelvarindices["vannualtechnologyemissionbymode"] = (vannualtechnologyemissionbymode, ["r", "t", "e", "m", "y"])
end

@variable(jumpmodel, vannualtechnologyemission[sregion, stechnology, semission, syear])
modelvarindices["vannualtechnologyemission"] = (vannualtechnologyemission, ["r", "t", "e", "y"])

if in("vannualtechnologyemissionpenaltybyemission", varstosavearr)
    @variable(jumpmodel, vannualtechnologyemissionpenaltybyemission[sregion, stechnology, semission, syear])
    modelvarindices["vannualtechnologyemissionpenaltybyemission"] = (vannualtechnologyemissionpenaltybyemission, ["r", "t", "e", "y"])
end

@variable(jumpmodel, vannualtechnologyemissionspenalty[sregion, stechnology, syear])
modelvarindices["vannualtechnologyemissionspenalty"] = (vannualtechnologyemissionspenalty, ["r", "t", "y"])
@variable(jumpmodel, vdiscountedtechnologyemissionspenalty[sregion, stechnology, syear])
modelvarindices["vdiscountedtechnologyemissionspenalty"] = (vdiscountedtechnologyemissionspenalty, ["r", "t", "y"])
@variable(jumpmodel, vannualemissions[sregion, semission, syear])
modelvarindices["vannualemissions"] = (vannualemissions, ["r", "e", "y"])
@variable(jumpmodel, vmodelperiodemissions[sregion, semission])
modelvarindices["vmodelperiodemissions"] = (vmodelperiodemissions, ["r", "e"])

logmsg("Defined emissions variables.", quiet)

# Transmission
if transmissionmodeling
    if in("vproductionbytechnology", varstosavearr)
        queryvproductionbytechnologyindices = vcat(queryvproductionbytechnologyindices,
        queries["queryvproductionbytechnologyindices_nodalpart"])
    end

    if in("vusebytechnology", varstosavearr)
        queryvusebytechnologyindices = vcat(queryvusebytechnologyindices,
        queries["queryvusebytechnologyindices_nodalpart"])
    end

    # Activity
    if restrictvars
        indexdicts = keydicts_threaded(queries["queryvrateofactivitynodal"], 4)  # Array of Dicts used to restrict indices of following variable
        @variable(jumpmodel, vrateofactivitynodal[n=[k[1] for k = keys(indexdicts[1])], l=indexdicts[1][[n]], t=indexdicts[2][[n,l]],
            m=indexdicts[3][[n,l,t]], y=indexdicts[4][[n,l,t,m]]] >= 0)

        indexdicts = keydicts_threaded(queries["queryvrateofproductionbytechnologynodal"], 4)  # Array of Dicts used to restrict indices of following variable
        @variable(jumpmodel, vrateofproductionbytechnologynodal[n=[k[1] for k = keys(indexdicts[1])], l=indexdicts[1][[n]], t=indexdicts[2][[n,l]],
            f=indexdicts[3][[n,l,t]], y=indexdicts[4][[n,l,t,f]]] >= 0)

        indexdicts = keydicts_threaded(queries["queryvrateofusebytechnologynodal"], 4)  # Array of Dicts used to restrict indices of following variable
        @variable(jumpmodel, vrateofusebytechnologynodal[n=[k[1] for k = keys(indexdicts[1])], l=indexdicts[1][[n]], t=indexdicts[2][[n,l]],
            f=indexdicts[3][[n,l,t]], y=indexdicts[4][[n,l,t,f]]] >= 0)

        indexdicts = keydicts_threaded(queries["queryvtransmissionbyline"], 3)  # Array of Dicts used to restrict indices of following variable
        @variable(jumpmodel, vtransmissionbyline[tr=[k[1] for k = keys(indexdicts[1])], l=indexdicts[1][[tr]], f=indexdicts[2][[tr,l]],
            y=indexdicts[3][[tr,l,f]]])

        indexdicts = keydicts_threaded(filter(row -> row.vc > 0 || (row.type == 3 && row.eff < 1), queries["queryvtransmissionbyline"]), 3)  # Array of Dicts used to restrict indices of following variable
        @variable(jumpmodel, vtransmissionbylineneg[tr=[k[1] for k = keys(indexdicts[1])], l=indexdicts[1][[tr]], f=indexdicts[2][[tr,l]],
            y=indexdicts[3][[tr,l,f]]], Bin)

        indexdicts = keydicts_threaded(vcat(select(queries["queryvtransmissionlosses"], :n1=>:n, :tr, :l, :f, :y),
            select(queries["queryvtransmissionlosses"], :n2=>:n, :tr, :l, :f, :y)), 4)
        @variable(jumpmodel, vtransmissionlosses[n=[k[1] for k = keys(indexdicts[1])], tr=indexdicts[1][[n]], l=indexdicts[2][[n,tr]],
            f=indexdicts[3][[n,tr,l]], y=indexdicts[4][[n,tr,l,f]]])
    else
        @variable(jumpmodel, vrateofactivitynodal[snode, stimeslice, stechnology, smode_of_operation, syear] >= 0)
        @variable(jumpmodel, vrateofproductionbytechnologynodal[snode, stimeslice, stechnology, sfuel, syear] >= 0)
        @variable(jumpmodel, vrateofusebytechnologynodal[snode, stimeslice, stechnology, sfuel, syear] >= 0)
        @variable(jumpmodel, vtransmissionbyline[stransmission, stimeslice, sfuel, syear])
        @variable(jumpmodel, vtransmissionbylineneg[stransmission, stimeslice, sfuel, syear], Bin)
        @variable(jumpmodel, vtransmissionlosses[snode, stransmission, stimeslice, sfuel, syear])
    end

    modelvarindices["vrateofactivitynodal"] = (vrateofactivitynodal, ["n", "l", "t", "m", "y"])
    modelvarindices["vrateofproductionbytechnologynodal"] = (vrateofproductionbytechnologynodal, ["n", "l", "t", "f", "y"])
    modelvarindices["vrateofusebytechnologynodal"] = (vrateofusebytechnologynodal, ["n", "l", "t", "f", "y"])
    # Note: n1 is from node; n2 is to node
    modelvarindices["vtransmissionbyline"] = (vtransmissionbyline, ["tr", "l", "f", "y"])
    modelvarindices["vtransmissionbylineneg"] = (vtransmissionbylineneg, ["tr", "l", "f", "y"])  # Internal variable - indicates whether corresponding vtransmissionbyline is <= 0; only used when a) transmission modeling type is 3 and efficiency < 1; or b) transmission variable cost > 0
    modelvarindices["vtransmissionlosses"] = (vtransmissionlosses, ["n", "tr", "l", "f", "y"])  # Internal variable - only used when transmission modeling type is 3 and efficiency < 1

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

    @variable(jumpmodel, vgenerationannualnodal[snode, sfuel, syear] >= 0)
    modelvarindices["vgenerationannualnodal"] = (vgenerationannualnodal, ["n","f","y"])

    @variable(jumpmodel, vregenerationannualnodal[snode, sfuel, syear] >= 0)
    modelvarindices["vregenerationannualnodal"] = (vregenerationannualnodal, ["n","f","y"])

    @variable(jumpmodel, vusenodal[snode, stimeslice, sfuel, syear] >= 0)
    modelvarindices["vusenodal"] = (vusenodal, ["n","l","f","y"])

    @variable(jumpmodel, vuseannualnodal[snode, sfuel, syear] >= 0)
    modelvarindices["vuseannualnodal"] = (vuseannualnodal, ["n","f","y"])

    # Demands
    @variable(jumpmodel, vdemandnodal[snode, stimeslice, sfuel, syear] >= 0)
    modelvarindices["vdemandnodal"] = (vdemandnodal, ["n","l","f","y"])

    @variable(jumpmodel, vdemandannualnodal[snode, sfuel, syear] >= 0)
    modelvarindices["vdemandannualnodal"] = (vdemandannualnodal, ["n","f","y"])

    # Capacity and other
    # vtransmissionannual is net annual transmission from n in energy terms
    @variable(jumpmodel, vtransmissionannual[snode, sfuel, syear])
    modelvarindices["vtransmissionannual"] = (vtransmissionannual, ["n","f","y"])

    # Indicates whether tr is built in year
    if continuoustransmission
        @variable(jumpmodel, 0 <= vtransmissionbuilt[stransmission, syear] <= 1)
    else
        @variable(jumpmodel, vtransmissionbuilt[stransmission, syear], Bin)
    end

    modelvarindices["vtransmissionbuilt"] = (vtransmissionbuilt, ["tr","y"])

    # Indicates whether tr exists (exogenously or endogenously) in year (0 or 1 if vtransmissionbuilt is Bin, otherwise between 0 and 1)
    @variable(jumpmodel, 0 <= vtransmissionexists[stransmission, syear] <= 1)
    modelvarindices["vtransmissionexists"] = (vtransmissionexists, ["tr","y"])

    # 1 = DC optimized power flow, 2 = DCOPF with disjunctive relaxation
    if in(1, transmissionmodelingtypes) || in(2, transmissionmodelingtypes)
        @variable(jumpmodel, -pi <= vvoltageangle[snode, stimeslice, syear] <= pi)
        modelvarindices["vvoltageangle"] = (vvoltageangle, ["n","l","y"])
    end

    # Storage
    if restrictvars
        indexdicts = keydicts_threaded(queries["queryvstorageleveltsgroup1"], 3)  # Array of Dicts used to restrict indices of following variable
        @variable(jumpmodel, vstorageleveltsgroup1startnodal[n=[k[1] for k = keys(indexdicts[1])], s=indexdicts[1][[n]], tg1=indexdicts[2][[n,s]],
            y=indexdicts[3][[n,s,tg1]]] >= 0)
        @variable(jumpmodel, vstorageleveltsgroup1endnodal[n=[k[1] for k = keys(indexdicts[1])], s=indexdicts[1][[n]], tg1=indexdicts[2][[n,s]],
            y=indexdicts[3][[n,s,tg1]]] >= 0)

        indexdicts = keydicts_threaded(queries["queryvstorageleveltsgroup2"], 4)  # Array of Dicts used to restrict indices of following variable
        @variable(jumpmodel, vstorageleveltsgroup2startnodal[n=[k[1] for k = keys(indexdicts[1])], s=indexdicts[1][[n]], tg1=indexdicts[2][[n,s]],
            tg2=indexdicts[3][[n,s,tg1]], y=indexdicts[4][[n,s,tg1,tg2]]] >= 0)
        @variable(jumpmodel, vstorageleveltsgroup2endnodal[n=[k[1] for k = keys(indexdicts[1])], s=indexdicts[1][[n]], tg1=indexdicts[2][[n,s]],
            tg2=indexdicts[3][[n,s,tg1]], y=indexdicts[4][[n,s,tg1,tg2]]] >= 0)

        indexdicts = keydicts_threaded(queries["queryvstoragelevelts"], 3)  # Array of Dicts used to restrict indices of following variable
        @variable(jumpmodel, vstorageleveltsendnodal[n=[k[1] for k = keys(indexdicts[1])], s=indexdicts[1][[n]], l=indexdicts[2][[n,s]],
            y=indexdicts[3][[n,s,l]]] >= 0)
        @variable(jumpmodel, vrateofstoragechargenodal[n=[k[1] for k = keys(indexdicts[1])], s=indexdicts[1][[n]], l=indexdicts[2][[n,s]],
            y=indexdicts[3][[n,s,l]]] >= 0)
        @variable(jumpmodel, vrateofstoragedischargenodal[n=[k[1] for k = keys(indexdicts[1])], s=indexdicts[1][[n]], l=indexdicts[2][[n,s]],
            y=indexdicts[3][[n,s,l]]] >= 0)
    else
        @variable(jumpmodel, vstorageleveltsgroup1startnodal[snode, sstorage, stsgroup1, syear] >= 0)
        @variable(jumpmodel, vstorageleveltsgroup1endnodal[snode, sstorage, stsgroup1, syear] >= 0)
        @variable(jumpmodel, vstorageleveltsgroup2startnodal[snode, sstorage, stsgroup1, stsgroup2, syear] >= 0)
        @variable(jumpmodel, vstorageleveltsgroup2endnodal[snode, sstorage, stsgroup1, stsgroup2, syear] >= 0)
        @variable(jumpmodel, vstorageleveltsendnodal[snode, sstorage, stimeslice, syear] >= 0)  # Storage level at end of first hour in time slice
        @variable(jumpmodel, vrateofstoragechargenodal[snode, sstorage, stimeslice, syear] >= 0)
        @variable(jumpmodel, vrateofstoragedischargenodal[snode, sstorage, stimeslice, syear] >= 0)
    end

    @variable(jumpmodel, vstoragelevelyearendnodal[snode, sstorage, syear] >= 0)

    modelvarindices["vstorageleveltsgroup1startnodal"] = (vstorageleveltsgroup1startnodal, ["n", "s", "tg1", "y"])
    modelvarindices["vstorageleveltsgroup1endnodal"] = (vstorageleveltsgroup1endnodal, ["n", "s", "tg1", "y"])
    modelvarindices["vstorageleveltsgroup2startnodal"] = (vstorageleveltsgroup2startnodal, ["n", "s", "tg1", "tg2", "y"])
    modelvarindices["vstorageleveltsgroup2endnodal"] = (vstorageleveltsgroup2endnodal, ["n", "s", "tg1", "tg2", "y"])
    modelvarindices["vstorageleveltsendnodal"] = (vstorageleveltsendnodal, ["n", "s", "l", "y"])
    modelvarindices["vrateofstoragechargenodal"] = (vrateofstoragechargenodal, ["n", "s", "l", "y"])
    modelvarindices["vrateofstoragedischargenodal"] = (vrateofstoragedischargenodal, ["n", "s", "l", "y"])
    modelvarindices["vstoragelevelyearendnodal"] = (vstoragelevelyearendnodal, ["n", "s", "y"])

    # Costing
    @variable(jumpmodel, vfinancecosttransmission[stransmission, syear] >= 0)
    modelvarindices["vfinancecosttransmission"] = (vfinancecosttransmission, ["tr","y"])
    @variable(jumpmodel, vcapitalinvestmenttransmission[stransmission, syear] >= 0)
    modelvarindices["vcapitalinvestmenttransmission"] = (vcapitalinvestmenttransmission, ["tr","y"])
    @variable(jumpmodel, vdiscountedcapitalinvestmenttransmission[stransmission, syear] >= 0)
    modelvarindices["vdiscountedcapitalinvestmenttransmission"] = (vdiscountedcapitalinvestmenttransmission, ["tr","y"])
    @variable(jumpmodel, vsalvagevaluetransmission[stransmission, syear] >= 0)
    modelvarindices["vsalvagevaluetransmissionvsalvagevaluetransmission"] = (vsalvagevaluetransmission, ["tr","y"])
    @variable(jumpmodel, vdiscountedsalvagevaluetransmission[stransmission, syear] >= 0)
    modelvarindices["vdiscountedsalvagevaluetransmission"] = (vdiscountedsalvagevaluetransmission, ["tr","y"])

    if restrictvars
        indexdicts = keydicts_threaded(filter(row -> row.vc > 0, queries["queryvtransmissionbyline"]), 3)  # Array of Dicts used to restrict indices of following variable
        @variable(jumpmodel, vvariablecosttransmissionbyts[tr=[k[1] for k = keys(indexdicts[1])], l=indexdicts[1][[tr]], f=indexdicts[2][[tr,l]],
            y=indexdicts[3][[tr,l,f]]] >= 0)
    else
        @variable(jumpmodel, vvariablecosttransmissionbyts[stransmission, stimeslice, sfuel, syear] >= 0)
    end

    modelvarindices["vvariablecosttransmissionbyts"] = (vvariablecosttransmissionbyts, ["tr", "l", "f", "y"])
    @variable(jumpmodel, vvariablecosttransmission[stransmission, syear] >= 0)
    modelvarindices["vvariablecosttransmission"] = (vvariablecosttransmission, ["tr","y"])
    @variable(jumpmodel, voperatingcosttransmission[stransmission, syear] >= 0)
    modelvarindices["voperatingcosttransmission"] = (voperatingcosttransmission, ["tr","y"])
    @variable(jumpmodel, vdiscountedoperatingcosttransmission[stransmission, syear] >= 0)
    modelvarindices["vdiscountedoperatingcosttransmission"] = (vdiscountedoperatingcosttransmission, ["tr","y"])
    @variable(jumpmodel, vtotaldiscountedtransmissioncostbyregion[sregion, syear] >= 0)
    modelvarindices["vtotaldiscountedtransmissioncostbyregion"] = (vtotaldiscountedtransmissioncostbyregion, ["r","y"])

    logmsg("Defined transmission variables.", quiet)
end  # if transmissionmodeling

# Combined nodal + non-nodal variables
if in("vproductionbytechnology", varstosavearr)
    if restrictvars
        indexdicts = keydicts_threaded(queryvproductionbytechnologyindices, 4)  # Array of Dicts used to restrict indices of following variable
        @variable(jumpmodel, vproductionbytechnology[r=[k[1] for k = keys(indexdicts[1])], l=indexdicts[1][[r]], t=indexdicts[2][[r,l]],
            f=indexdicts[3][[r,l,t]], y=indexdicts[4][[r,l,t,f]]] >= 0)
    else
        @variable(jumpmodel, vproductionbytechnology[sregion, stimeslice, stechnology, sfuel, syear] >= 0)
    end

    modelvarindices["vproductionbytechnology"] = (vproductionbytechnology, ["r","l","t","f","y"])
end

if in("vusebytechnology", varstosavearr)
    if restrictvars
        indexdicts = keydicts_threaded(queryvusebytechnologyindices, 4)  # Array of Dicts used to restrict indices of following variable
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

# BEGIN: Set variable start values.
if length(startvalsdbpath) > 0
    # For call to setstartvalues, convert startvalsvars into an array of strings with no empty values
    setstartvalues(jumpmodel, startvalsdbpath, quiet; selectedvars = String.(split(replace(startvalsvars, " " => ""), ","; keepempty = false)))
end
# END: Set variable start values.

# BEGIN: Define model constraints.

# Variables used in constraint construction
local cons_channel::Channel{Array{AbstractConstraint,1}} = Channel{Array{AbstractConstraint,1}}(Threads.nthreads() * 2)  # A channel used as a queue for built constraints that must be added to the model
local numconsarrays::Int64 = 0  # Number of Array{AbstractConstraint,1} of built constraints that must be added to the model
local numaddedconsarrays::Int64 = 0  # Number of Array{AbstractConstraint,1} of built constraints that have been added to the model
local finishedqueuingcons::Bool = false  # Indicates whether all constraints have been queued for building (but not necessarily built or added to the model)

# BEGIN: Schedule task to add constraints to model asynchronously.
addconstask::Task = @task begin
    while !finishedqueuingcons || numaddedconsarrays < numconsarrays
        if isready(cons_channel)
            local a = take!(cons_channel)
            #@info "Performed take for numconsarrays = " * string(numconsarrays)
            createconstraints(jumpmodel, a)
            #@info "Created constraints for numconsarrays = " * string(numconsarrays)
            numaddedconsarrays += 1
            #@info "In while loop. numaddedconsarrays = " * string(numaddedconsarrays)
        else
            if numaddedconsarrays == numconsarrays
                #@info "Yielding. finishedqueuingcons = $finishedqueuingcons, numconsarrays = $numconsarrays, numaddedconsarrays = $numaddedconsarrays"
                yield()  # Provides a chance to update finishedqueuingcons before continuing (i.e., once all constraints are built and added to cons_channel)
            else
                #@info "Waiting. finishedqueuingcons = $finishedqueuingcons, numconsarrays = $numconsarrays, numaddedconsarrays = $numaddedconsarrays"
                wait(cons_channel)
            end
        end
    end

    close(cons_channel)
    logmsg("Finished scheduled task to add constraints to model.", quiet)
end

schedule(addconstask)
logmsg("Scheduled task to add constraints to model.", quiet)
# END: Schedule task to add constraints to model asynchronously.

# BEGIN: Wrap multi-threaded constraint building in @sync to allow any errors to propagate.
# For readability's sake, code within @sync block is not indented
@sync(begin

# BEGIN: EQ_SpecifiedDemand.
if in("vrateofdemandnn", varstosavearr)
    ceq_specifieddemand::Array{AbstractConstraint, 1} = Array{AbstractConstraint, 1}()

    t = Threads.@spawn(begin
        for row in DataFrames.eachrow(queries["queryvrateofdemandnn"])
            push!(ceq_specifieddemand, @build_constraint(row[:specifiedannualdemand] * row[:specifieddemandprofile] / row[:ys]
                == vrateofdemandnn[row[:r], row[:l], row[:f], row[:y]]))
        end

        put!(cons_channel, ceq_specifieddemand)
    end)

    numconsarrays += 1
    logmsg("Queued constraint EQ_SpecifiedDemand for creation.", quiet)
end
# END: EQ_SpecifiedDemand.

# BEGIN: CAa1_TotalNewCapacity.
caa1_totalnewcapacity::Array{AbstractConstraint, 1} = Array{AbstractConstraint, 1}()
t = Threads.@spawn(let
    local lastkeys = Array{String, 1}(undef,3)  # lastkeys[1] = r, lastkeys[2] = t, lastkeys[3] = y
    local sumexps = Array{AffExpr, 1}([AffExpr()])  # sumexps[1] = vnewcapacity sum

    for row in SQLite.DBInterface.execute(db,"select r.val as r, t.val as t, y.val as y, yy.val as yy
    from REGION r, TECHNOLOGY t, YEAR y, OperationalLife_def ol, YEAR yy
    where ol.r = r.val and ol.t = t.val
    and y.val - yy.val < ol.val and y.val - yy.val >=0
    $(restrictyears ? "and y.val in" * inyears : "")
    $(restrictyears ? "and yy.val in" * inyears : "")
    order by r.val, t.val, y.val")
        local r = row[:r]
        local t = row[:t]
        local y = row[:y]

        if isassigned(lastkeys, 1) && (r != lastkeys[1] || t != lastkeys[2] || y != lastkeys[3])
            # Create constraint
            push!(caa1_totalnewcapacity, @build_constraint(sumexps[1] == vaccumulatednewcapacity[lastkeys[1],lastkeys[2],lastkeys[3]]))
            sumexps[1] = AffExpr()
        end

        add_to_expression!(sumexps[1], vnewcapacity[r,t,row[:yy]])

        lastkeys[1] = r
        lastkeys[2] = t
        lastkeys[3] = y
    end

    # Create last constraint
    if isassigned(lastkeys, 1)
        push!(caa1_totalnewcapacity, @build_constraint(sumexps[1] == vaccumulatednewcapacity[lastkeys[1],lastkeys[2],lastkeys[3]]))
    end

    put!(cons_channel, caa1_totalnewcapacity)
end)

numconsarrays += 1
logmsg("Queued constraint CAa1_TotalNewCapacity for creation.", quiet)
# END: CAa1_TotalNewCapacity.

# BEGIN: CAa2_TotalAnnualCapacity.
caa2_totalannualcapacity::Array{AbstractConstraint, 1} = Array{AbstractConstraint, 1}()
t = Threads.@spawn(begin
    for row in SQLite.DBInterface.execute(db,"select r.val as r, t.val as t, y.val as y, cast(rc.val as real) as rc
    from REGION r, TECHNOLOGY t, YEAR y
    left join ResidualCapacity_def rc on rc.r = r.val and rc.t = t.val and rc.y = y.val
    $(restrictyears ? "where y.val in" * inyears : "")")
        local r = row[:r]
        local t = row[:t]
        local y = row[:y]
        local rc = ismissing(row[:rc]) ? 0 : row[:rc]

        push!(caa2_totalannualcapacity, @build_constraint(vaccumulatednewcapacity[r,t,y] + rc == vtotalcapacityannual[r,t,y]))
    end

    put!(cons_channel, caa2_totalannualcapacity)
end)

numconsarrays += 1
logmsg("Queued constraint CAa2_TotalAnnualCapacity for creation.", quiet)
# END: CAa2_TotalAnnualCapacity.

# BEGIN: VRateOfActivity1.
# This constraint sets activity to sum of nodal activity for technologies involved in nodal modeling.
vrateofactivity1::Array{AbstractConstraint, 1} = Array{AbstractConstraint, 1}()
t = Threads.@spawn(let
    local lastkeys = Array{String, 1}(undef,5)  # lastkeys[1] = r, lastkeys[2] = l, lastkeys[3] = t, lastkeys[4] = m, lastkeys[5] = y
    local sumexps = Array{AffExpr, 1}([AffExpr()])  # sumexps[1] = vrateofactivitynodal sum

    for row in SQLite.DBInterface.execute(db,
    "select n.r as r, l.val as l, ntc.t as t, ar.m as m, ntc.y as y, ntc.n as n
    from NodalDistributionTechnologyCapacity_def ntc, node n,
    	TransmissionModelingEnabled tme, TIMESLICE l,
    (select r, t, f, m, y from OutputActivityRatio_def
    where val <> 0 $(restrictyears ? "and y in" * inyears : "")
    union
    select r, t, f, m, y from InputActivityRatio_def
    where val <> 0 $(restrictyears ? "and y in" * inyears : "")) ar
    where ntc.val > 0
    and ntc.n = n.val
    and tme.r = n.r and tme.f = ar.f and tme.y = ntc.y
    and ar.r = n.r and ar.t = ntc.t and ar.y = ntc.y
    order by l.val, ntc.t, ar.m, ntc.y, n.r")
        local r = row[:r]
        local l = row[:l]
        local t = row[:t]
        local m = row[:m]
        local y = row[:y]

        if isassigned(lastkeys, 1) && (r != lastkeys[1] || l != lastkeys[2] || t != lastkeys[3] || m != lastkeys[4] || y != lastkeys[5])
            # Create constraint
            push!(vrateofactivity1, @build_constraint(sumexps[1] == vrateofactivity[lastkeys[1],lastkeys[2],lastkeys[3],lastkeys[4],lastkeys[5]]))
            sumexps[1] = AffExpr()
        end

        add_to_expression!(sumexps[1], vrateofactivitynodal[row[:n],l,t,m,y])

        lastkeys[1] = r
        lastkeys[2] = l
        lastkeys[3] = t
        lastkeys[4] = m
        lastkeys[5] = y
    end

    if isassigned(lastkeys, 1)
        push!(vrateofactivity1, @build_constraint(sumexps[1] == vrateofactivity[lastkeys[1],lastkeys[2],lastkeys[3],lastkeys[4],lastkeys[5]]))
    end

    put!(cons_channel, vrateofactivity1)
end)

numconsarrays += 1
logmsg("Queued constraint VRateOfActivity1 for creation.", quiet)
# END: VRateOfActivity1.

# BEGIN: RampRate.
ramprate::Array{AbstractConstraint, 1} = Array{AbstractConstraint, 1}()

t = Threads.@spawn(begin
    for row in SQLite.DBInterface.execute(db, "with ar as (select r, t, f, m, y from OutputActivityRatio_def
    where val <> 0 $(restrictyears ? "and y in" * inyears : "")
    union
    select r, t, f, m, y from InputActivityRatio_def
    where val <> 0 $(restrictyears ? "and y in" * inyears : "")),
    ltgs as (select ltg.tg1, tg1.[order] as tg1o, ltg.tg2, tg2.[order] as tg2o, ltg.l, ltg.lorder,
    lag(ltg.l) over (order by tg1.[order], tg2.[order], ltg.lorder) as prior_l
    from LTsGroup ltg, TSGROUP1 tg1, TSGROUP2 tg2
    where ltg.tg1 = tg1.name
    and ltg.tg2 = tg2.name),
    nodal as (select ntc.n as n, n.r as r, ntc.t as t, ar.m as m, ntc.y as y
    from NodalDistributionTechnologyCapacity_def ntc, node n,
    	TransmissionModelingEnabled tme, ar
    where ntc.val > 0
    and ntc.n = n.val
    and tme.r = n.r and tme.f = ar.f and tme.y = ntc.y
    and ar.r = n.r and ar.t = ntc.t and ar.y = ntc.y)
    select * from (
    select rr.r, rr.t, rr.y, rr.l, m.val as m, cast(rr.val as real) as rr, ltgs.tg1o, ltgs.tg2o, ltgs.lorder, ltgs.prior_l,
    case rrs.val when 0 then 0 when 1 then 1 when 2 then 2 else 2 end as rrs,
    cast(cf.val as real) as cf, cast(cta.val as real) as cta
    from RampRate_def rr, ltgs, CapacityFactor_def cf, CapacityToActivityUnit_def cta, MODE_OF_OPERATION m
    left join RampingReset_def rrs on rr.r = rrs.r
    left join nodal on rr.r = nodal.r and rr.t = nodal.t and rr.y = nodal.y and nodal.m = m.val
    where rr.l = ltgs.l
    and rr.val <> 1.0
    and rr.r = cf.r and rr.t = cf.t and rr.l = cf.l and rr.y = cf.y
    and rr.r = cta.r and rr.t = cta.t
    and nodal.n is null
    and exists (select 1 from ar where ar.r = rr.r and ar.t = rr.t and ar.m = m.val and ar.y = rr.y)
    )
    where
    not (tg1o = 1 and tg2o = 1 and lorder = 1)
    and not (rrs >= 1 and tg2o = 1 and lorder = 1)
    and not (rrs = 2 and lorder = 1)")
        local r = row[:r]
        local t = row[:t]
        local l = row[:l]
        local y = row[:y]
        local m = row[:m]
        local prior_l = row[:prior_l]

        push!(ramprate, @build_constraint(vrateofactivity[r,l,t,m,y] <= vrateofactivity[r,prior_l,t,m,y]
            + vtotalcapacityannual[r,t,y] * row[:rr] * row[:cf] * row[:cta]))
        push!(ramprate, @build_constraint(vrateofactivity[r,l,t,m,y] >= vrateofactivity[r,prior_l,t,m,y]
            - vtotalcapacityannual[r,t,y] * row[:rr] * row[:cf] * row[:cta]))
    end

    put!(cons_channel, ramprate)
end)

numconsarrays += 1
logmsg("Queued constraint RampRate for creation.", quiet)
# END: RampRate.

# BEGIN: RampRateTr.
if transmissionmodeling
    rampratetr::Array{AbstractConstraint, 1} = Array{AbstractConstraint, 1}()

    t = Threads.@spawn(begin
        for row in SQLite.DBInterface.execute(db, "with ltgs as (select ltg.tg1, tg1.[order] as tg1o, ltg.tg2, tg2.[order] as tg2o, ltg.l, ltg.lorder,
        lag(ltg.l) over (order by tg1.[order], tg2.[order], ltg.lorder) as prior_l
        from LTsGroup ltg, TSGROUP1 tg1, TSGROUP2 tg2
        where ltg.tg1 = tg1.name
        and ltg.tg2 = tg2.name)
        select * from (
        select rr.r, ntc.n, rr.t, rr.y, rr.l, ar.m, cast(rr.val as real) as rr, ltgs.tg1o, ltgs.tg2o, ltgs.lorder, ltgs.prior_l,
        case rrs.val when 0 then 0 when 1 then 1 when 2 then 2 else 2 end as rrs,
        cast(cf.val as real) as cf, cast(cta.val as real) as cta, cast(ntc.val as real) as ntc
        from RampRate_def rr, ltgs, CapacityFactor_def cf, CapacityToActivityUnit_def cta, NodalDistributionTechnologyCapacity_def ntc,
        	node n, TransmissionModelingEnabled tme,
        	(select r, t, f, m, y from OutputActivityRatio_def
        	where val <> 0 $(restrictyears ? "and y in" * inyears : "")
        	union
        	select r, t, f, m, y from InputActivityRatio_def
        	where val <> 0 $(restrictyears ? "and y in" * inyears : "")) ar
        left join RampingReset_def rrs on rr.r = rrs.r
        where rr.l = ltgs.l
        and rr.val <> 1.0
        and rr.r = cf.r and rr.t = cf.t and rr.l = cf.l and rr.y = cf.y
        and rr.r = cta.r and rr.t = cta.t
        and ntc.n = n.val
        and rr.r = n.r and rr.t = ntc.t and rr.y = ntc.y and ntc.val > 0
        and rr.r = tme.r and tme.f = ar.f and rr.y = tme.y
        and rr.r = ar.r and rr.t = ar.t and rr.y = ar.y
        )
        where
        not (tg1o = 1 and tg2o = 1 and lorder = 1)
        and not (rrs >= 1 and tg2o = 1 and lorder = 1)
        and not (rrs = 2 and lorder = 1)")
            local r = row[:r]
            local n = row[:n]
            local t = row[:t]
            local l = row[:l]
            local y = row[:y]
            local m = row[:m]
            local prior_l = row[:prior_l]

            push!(rampratetr, @build_constraint(vrateofactivitynodal[n,l,t,m,y] <= vrateofactivitynodal[n,prior_l,t,m,y]
                + vtotalcapacityannual[r,t,y] * row[:ntc] * row[:rr] * row[:cf] * row[:cta]))
            push!(rampratetr, @build_constraint(vrateofactivitynodal[n,l,t,m,y] >= vrateofactivitynodal[n,prior_l,t,m,y]
                - vtotalcapacityannual[r,t,y] * row[:ntc] * row[:rr] * row[:cf] * row[:cta]))
        end

        put!(cons_channel, rampratetr)
    end)

    numconsarrays += 1
    logmsg("Queued constraint RampRateTr for creation.", quiet)
end
# END: RampRateTr.

# BEGIN: CAa3_TotalActivityOfEachTechnology.
caa3_totalactivityofeachtechnology::Array{AbstractConstraint, 1} = Array{AbstractConstraint, 1}()
t = Threads.@spawn(let
    local lastkeys = Array{String, 1}(undef,4)  # lastkeys[1] = r, lastkeys[2] = t, lastkeys[3] = l, lastkeys[4] = y
    local sumexps = Array{AffExpr, 1}([AffExpr()])  # sumexps[1] = vrateofactivity sum

    for row in DataFrames.eachrow(queries["queryvrateofactivityvar"])
        local r = row[:r]
        local t = row[:t]
        local l = row[:l]
        local y = row[:y]

        if isassigned(lastkeys, 1) && (r != lastkeys[1] || t != lastkeys[2] || l != lastkeys[3] || y != lastkeys[4])
            # Create constraint
            push!(caa3_totalactivityofeachtechnology, @build_constraint(sumexps[1] == vrateoftotalactivity[lastkeys[1],lastkeys[2],lastkeys[3],lastkeys[4]]))
            sumexps[1] = AffExpr()
        end

        add_to_expression!(sumexps[1], vrateofactivity[r,l,t,row[:m],y])

        lastkeys[1] = r
        lastkeys[2] = t
        lastkeys[3] = l
        lastkeys[4] = y
    end

    # Create last constraint
    if isassigned(lastkeys, 1)
        push!(caa3_totalactivityofeachtechnology, @build_constraint(sumexps[1] == vrateoftotalactivity[lastkeys[1],lastkeys[2],lastkeys[3],lastkeys[4]]))
    end

    put!(cons_channel, caa3_totalactivityofeachtechnology)
end)

numconsarrays += 1
logmsg("Queued constraint CAa3_TotalActivityOfEachTechnology for creation.", quiet)
# END: CAa3_TotalActivityOfEachTechnology.

# BEGIN: CAa3Tr_TotalActivityOfEachTechnology.
if transmissionmodeling
    caa3tr_totalactivityofeachtechnology::Array{AbstractConstraint, 1} = Array{AbstractConstraint, 1}()
    t = Threads.@spawn(let
        local lastkeys = Array{String, 1}(undef,4)  # lastkeys[1] = n, lastkeys[2] = t, lastkeys[3] = l, lastkeys[4] = y
        local sumexps = Array{AffExpr, 1}([AffExpr()])  # sumexps[1] = vrateofactivitynodal sum

        for row in DataFrames.eachrow(queries["queryvrateofactivitynodal"])
            local n = row[:n]
            local t = row[:t]
            local l = row[:l]
            local y = row[:y]

            if isassigned(lastkeys, 1) && (n != lastkeys[1] || t != lastkeys[2] || l != lastkeys[3] || y != lastkeys[4])
                # Create constraint
                push!(caa3tr_totalactivityofeachtechnology, @build_constraint(sumexps[1] == vrateoftotalactivitynodal[lastkeys[1],lastkeys[2],lastkeys[3],lastkeys[4]]))
                sumexps[1] = AffExpr()
            end

            add_to_expression!(sumexps[1], vrateofactivitynodal[n,l,t,row[:m],y])

            lastkeys[1] = n
            lastkeys[2] = t
            lastkeys[3] = l
            lastkeys[4] = y
        end

        # Create last constraint
        if isassigned(lastkeys, 1)
            push!(caa3tr_totalactivityofeachtechnology, @build_constraint(sumexps[1] == vrateoftotalactivitynodal[lastkeys[1],lastkeys[2],lastkeys[3],lastkeys[4]]))
        end

        put!(cons_channel, caa3tr_totalactivityofeachtechnology)
    end)

    numconsarrays += 1
    logmsg("Queued constraint CAa3Tr_TotalActivityOfEachTechnology for creation.", quiet)
end
# END: CAa3Tr_TotalActivityOfEachTechnology.

# BEGIN: CAa4_Constraint_Capacity and MinimumTechnologyUtilization.
caa4_constraint_capacity::Array{AbstractConstraint, 1} = Array{AbstractConstraint, 1}()
minimum_technology_utilization::Array{AbstractConstraint, 1} = Array{AbstractConstraint, 1}()

t = Threads.@spawn(begin
    for row in SQLite.DBInterface.execute(db,"select r.val as r, l.val as l, t.val as t, y.val as y,
        cast(cf.val as real) as cf, cast(cta.val as real) as cta, cast(mu.val as real) as mu
    from REGION r, TIMESLICE l, TECHNOLOGY t, YEAR y, CapacityFactor_def cf, CapacityToActivityUnit_def cta
    left join MinimumUtilization_def mu on mu.r = r.val and mu.t = t.val and mu.l = l.val and mu.y = y.val
    where cf.r = r.val and cf.t = t.val and cf.l = l.val and cf.y = y.val
    and cta.r = r.val and cta.t = t.val
    $(restrictyears ? "and y.val in" * inyears : "")")
        local r = row[:r]
        local t = row[:t]
        local l = row[:l]
        local y = row[:y]

        push!(caa4_constraint_capacity, @build_constraint(vrateoftotalactivity[r,t,l,y]
            <= vtotalcapacityannual[r,t,y] * row[:cf] * row[:cta]))

        if !ismissing(row[:mu])
            push!(minimum_technology_utilization, @build_constraint(vrateoftotalactivity[r,t,l,y]
            >= vtotalcapacityannual[r,t,y] * row[:cf] * row[:cta] * row[:mu]))
        end
    end

    put!(cons_channel, caa4_constraint_capacity)
    put!(cons_channel, minimum_technology_utilization)
end)

numconsarrays += 2
logmsg("Queued constraint CAa4_Constraint_Capacity for creation.", quiet)
logmsg("Queued constraint MinimumTechnologyUtilization for creation.", quiet)
# END: CAa4_Constraint_Capacity and MinimumTechnologyUtilization.

# BEGIN: CAa4Tr_Constraint_Capacity and MinimumTechnologyUtilizationTr.
if transmissionmodeling
    caa4tr_constraint_capacity::Array{AbstractConstraint, 1} = Array{AbstractConstraint, 1}()
    minimum_technology_utilization_tr::Array{AbstractConstraint, 1} = Array{AbstractConstraint, 1}()

    t = Threads.@spawn(begin
        for row in SQLite.DBInterface.execute(db,"select ntc.n as n, ntc.t as t, l.val as l, ntc.y as y, n.r as r,
        	cast(ntc.val as real) as ntc, cast(cf.val as real) as cf,
        	cast(cta.val as real) as cta, cast(mu.val as real) as mu
        from NodalDistributionTechnologyCapacity_def ntc, TIMESLICE l, NODE n,
        CapacityFactor_def cf, CapacityToActivityUnit_def cta
        left join MinimumUtilization_def mu on mu.r = n.r and mu.t = ntc.t and mu.l = l.val and mu.y = ntc.y
        where ntc.val > 0 $(restrictyears ? "and ntc.y in" * inyears : "")
        and ntc.n = n.val
        and cf.r = n.r and cf.t = ntc.t and cf.l = l.val and cf.y = ntc.y
        and cta.r = n.r and cta.t = ntc.t")
            local n = row[:n]
            local t = row[:t]
            local l = row[:l]
            local y = row[:y]
            local r = row[:r]

            push!(caa4tr_constraint_capacity, @build_constraint(vrateoftotalactivitynodal[n,t,l,y]
                    <= vtotalcapacityannual[r,t,y] * row[:ntc] * row[:cf] * row[:cta]))

            !ismissing(row[:mu]) && push!(minimum_technology_utilization_tr, @build_constraint(vrateoftotalactivitynodal[n,t,l,y]
                >= vtotalcapacityannual[r,t,y] * row[:ntc] * row[:cf] * row[:cta] * row[:mu]))
        end

        put!(cons_channel, caa4tr_constraint_capacity)
        put!(cons_channel, minimum_technology_utilization_tr)
    end)

    numconsarrays += 2
    logmsg("Queued constraint CAa4Tr_Constraint_Capacity for creation.", quiet)
    logmsg("Queued constraint MinimumTechnologyUtilizationTr for creation.", quiet)
end
# END: CAa4Tr_Constraint_Capacity and MinimumTechnologyUtilizationTr.

# BEGIN: CAa5_TotalNewCapacity.
if size(queries["querycaa5_totalnewcapacity"])[1] > 0
    caa5_totalnewcapacity::Array{AbstractConstraint, 1} = Array{AbstractConstraint, 1}()

    t = Threads.@spawn(begin
        for row in DataFrames.eachrow(queries["querycaa5_totalnewcapacity"])
            local r = row[:r]
            local t = row[:t]
            local y = row[:y]

            push!(caa5_totalnewcapacity, @build_constraint(row[:cot] * vnumberofnewtechnologyunits[r,t,y]
                == vnewcapacity[r,t,y]))
        end

        put!(cons_channel, caa5_totalnewcapacity)
    end)

    numconsarrays += 1
    logmsg("Queued constraint CAa5_TotalNewCapacity for creation.", quiet)
end
# END: CAa5_TotalNewCapacity.

#= BEGIN: CAb1_PlannedMaintenance.
# Omitting this constraint since it only serves to apply AvailabilityFactor, for which user demand isn't clear.
#   This parameter specifies an outage on an annual level and lets the model choose when (in which time slices) to take it.
#   Note that the parameter isn't used by LEAP. Omitting the constraint improves performance. If the constraint were
#   reinstated, a variant for transmission modeling (incorporating vrateoftotalactivitynodal) would be needed.
constraintnum = 1  # Number of next constraint to be added to constraint array
@AbstractConstraint cab1_plannedmaintenance[1:length(sregion) * length(stechnology) * length(syear)]

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
        cab1_plannedmaintenance[constraintnum] = @build_constraint(sumexps[1] <= sumexps[2] * lastvals[1] * lastvals[2])
        constraintnum += 1

        sumexps[1] = AffExpr()
        sumexps[2] = AffExpr()
    end

    add_to_expression!(sumexps[1], vrateoftotalactivity[r,t,l,y] * ys)
    add_to_expression!(sumexps[2], vtotalcapacityannual[r,t,y] * row[:cf] * ys)

    lastkeys[1] = r
    lastkeys[2] = t
    lastkeys[3] = y
    lastvals[1] = row[:af]
    lastvals[2] = row[:cta]
end

# Create last constraint
if isassigned(lastkeys, 1)
    cab1_plannedmaintenance[constraintnum] = @build_constraint(sumexps[1] <= sumexps[2] * lastvals[1] * lastvals[2])
end

logmsg("Created constraint CAb1_PlannedMaintenance.", quiet)
# END: CAb1_PlannedMaintenance. =#

# BEGIN: EBa1_RateOfFuelProduction1.
if in("vrateofproductionbytechnologybymodenn", varstosavearr)
    eba1_rateoffuelproduction1::Array{AbstractConstraint, 1} = Array{AbstractConstraint, 1}()

    t = Threads.@spawn(begin
        for row in DataFrames.eachrow(queries["queryvrateofproductionbytechnologybymodenn"])
            local r = row[:r]
            local l = row[:l]
            local t = row[:t]
            local m = row[:m]
            local f = row[:f]
            local y = row[:y]

            push!(eba1_rateoffuelproduction1, @build_constraint(vrateofactivity[r,l,t,m,y] * row[:oar] == vrateofproductionbytechnologybymodenn[r,l,t,m,f,y]))
        end

        put!(cons_channel, eba1_rateoffuelproduction1)
    end)

    numconsarrays += 1
    logmsg("Queued constraint EBa1_RateOfFuelProduction1 for creation.", quiet)
end  # in("vrateofproductionbytechnologybymodenn", varstosavearr)
# END: EBa1_RateOfFuelProduction1.

# BEGIN: EBa2_RateOfFuelProduction2, GenerationAnnualNN, and ReGenerationAnnualNN.
eba2_rateoffuelproduction2::Array{AbstractConstraint, 1} = Array{AbstractConstraint, 1}()
generationannualnn::Array{AbstractConstraint, 1} = Array{AbstractConstraint, 1}()
regenerationannualnn::Array{AbstractConstraint, 1} = Array{AbstractConstraint, 1}()

t = Threads.@spawn(let
    local lastkeys = Array{String, 1}(undef,5)  # lastkeys[1] = r, lastkeys[2] = l, lastkeys[3] = t, lastkeys[4] = f, lastkeys[5] = y
    local sumexps = Array{AffExpr, 1}([AffExpr(), AffExpr(), AffExpr()])  # sumexps[1] = vrateofproductionbytechnologybymodenn-equivalent sum for vrateofproductionbytechnologynn, sumexps[2] = vrateofproductionbytechnologybymodenn-equivalent sum for vgenerationannualnn, sumexps[3] = vrateofproductionbytechnologybymodenn-equivalent sum for vregenerationannualnn

    for row in DataFrames.eachrow(queries["queryvrateofproductionbytechnologybymodenn"])
        local r = row[:r]
        local l = row[:l]
        local t = row[:t]
        local f = row[:f]
        local y = row[:y]

        if isassigned(lastkeys, 1) && (r != lastkeys[1] || l != lastkeys[2] || t != lastkeys[3] || f != lastkeys[4] || y != lastkeys[5])
            # Create constraint
            push!(eba2_rateoffuelproduction2, @build_constraint(sumexps[1] ==
                vrateofproductionbytechnologynn[lastkeys[1], lastkeys[2], lastkeys[3], lastkeys[4], lastkeys[5]]))
            sumexps[1] = AffExpr()
        end

        if isassigned(lastkeys, 1) && (r != lastkeys[1] || f != lastkeys[4] || y != lastkeys[5])
            # Create constraints
            push!(generationannualnn, @build_constraint(sumexps[2] == vgenerationannualnn[lastkeys[1], lastkeys[4], lastkeys[5]]))
            push!(regenerationannualnn, @build_constraint(sumexps[3] == vregenerationannualnn[lastkeys[1], lastkeys[4], lastkeys[5]]))
            sumexps[2] = AffExpr()
            sumexps[3] = AffExpr()
        end

        add_to_expression!(sumexps[1], vrateofactivity[r,l,t,row[:m],y] * row[:oar])
        # Sum is of vrateofproductionbytechnologybymodenn[r,l,t,row[:m],f,y])

        # Exclude production from storage in vgenerationannualnn and vregenerationannualnn
        if ismissing(row[:fs_t])
            add_to_expression!(sumexps[2], vrateofactivity[r,l,t,row[:m],y] * row[:oar] * row[:ys])

            if !ismissing(row[:ret]) && row[:ret] > 0
                add_to_expression!(sumexps[3], vrateofactivity[r,l,t,row[:m],y] * row[:oar] * row[:ys] * row[:ret])
            end
        end

        lastkeys[1] = r
        lastkeys[2] = l
        lastkeys[3] = t
        lastkeys[4] = f
        lastkeys[5] = y
    end

    # Create last constraints
    if isassigned(lastkeys, 1)
        push!(eba2_rateoffuelproduction2, @build_constraint(sumexps[1] ==
            vrateofproductionbytechnologynn[lastkeys[1], lastkeys[2], lastkeys[3], lastkeys[4], lastkeys[5]]))
        push!(generationannualnn, @build_constraint(sumexps[2] == vgenerationannualnn[lastkeys[1], lastkeys[4], lastkeys[5]]))
        push!(regenerationannualnn, @build_constraint(sumexps[3] == vregenerationannualnn[lastkeys[1], lastkeys[4], lastkeys[5]]))
    end

    put!(cons_channel, eba2_rateoffuelproduction2)
    put!(cons_channel, generationannualnn)
    put!(cons_channel, regenerationannualnn)
end)

numconsarrays += 3
logmsg("Queued constraint EBa2_RateOfFuelProduction2 for creation.", quiet)
logmsg("Queued constraint GenerationAnnualNN for creation.", quiet)
logmsg("Queued constraint ReGenerationAnnualNN for creation.", quiet)
# END: EBa2_RateOfFuelProduction2 and GenerationAnnualNN, and ReGenerationAnnualNN.

# BEGIN: EBa2Tr_RateOfFuelProduction2, GenerationAnnualNodal, and ReGenerationAnnualNodal.
if transmissionmodeling
    eba2tr_rateoffuelproduction2::Array{AbstractConstraint, 1} = Array{AbstractConstraint, 1}()
    generationannualnodal::Array{AbstractConstraint, 1} = Array{AbstractConstraint, 1}()
    regenerationannualnodal::Array{AbstractConstraint, 1} = Array{AbstractConstraint, 1}()

    t = Threads.@spawn(let
        local lastkeys = Array{String, 1}(undef,5)  # lastkeys[1] = n, lastkeys[2] = l, lastkeys[3] = t, lastkeys[4] = f, lastkeys[5] = y
        local sumexps = Array{AffExpr, 1}([AffExpr(), AffExpr(), AffExpr()])  # sumexps[1] = vrateofactivitynodal sum for vrateofproductionbytechnologynodal, sumexps[2] = vrateofactivitynodal sum for vgenerationannualnodal, sumexps[3] = vrateofactivitynodal sum for vregenerationannualnodal

        for row in SQLite.DBInterface.execute(db, "select ntc.n as n, ys.l as l, ntc.t as t, oar.f as f, ntc.y as y, m.val as m,
    	   cast(oar.val as real) as oar, cast(ys.val as real) as ys, fs.t as fs_t, cast(ret.val as real) as ret
        from NodalDistributionTechnologyCapacity_def ntc, YearSplit_def ys, MODE_OF_OPERATION m, NODE n, OutputActivityRatio_def oar,
    	TransmissionModelingEnabled tme
		left join (select distinct ns.n, tfs.t, tfs.m, ns.y
		from nodalstorage ns, TechnologyFromStorage_def tfs
		where ns.r = tfs.r and ns.s = tfs.s and tfs.val > 0 $(restrictyears ? "and ns.y in" * inyears : "")
		) fs on fs.n = ntc.n and fs.t = ntc.t and fs.m = m.val and fs.y = ntc.y
        left join RETagTechnology_def ret on ret.r = n.r and ret.t = ntc.t and ret.y = ntc.y
        where ntc.val > 0 $(restrictyears ? "and ntc.y in" * inyears : "")
        and ntc.y = ys.y
        and ntc.n = n.val
        and oar.r = n.r and oar.t = ntc.t and oar.m = m.val and oar.y = ntc.y
        and oar.val > 0
    	and tme.r = n.r and tme.f = oar.f and tme.y = ntc.y
        order by ntc.n, oar.f, ntc.y, ys.l, ntc.t")
            local n = row[:n]
            local l = row[:l]
            local t = row[:t]
            local f = row[:f]
            local y = row[:y]

            if isassigned(lastkeys, 1) && (n != lastkeys[1] || l != lastkeys[2] || t != lastkeys[3] || f != lastkeys[4] || y != lastkeys[5])
                # Create constraint
                push!(eba2tr_rateoffuelproduction2, @build_constraint(sumexps[1] ==
                    vrateofproductionbytechnologynodal[lastkeys[1], lastkeys[2], lastkeys[3], lastkeys[4], lastkeys[5]]))
                sumexps[1] = AffExpr()
            end

            if isassigned(lastkeys, 1) && (n != lastkeys[1] || f != lastkeys[4] || y != lastkeys[5])
                # Create constraints
                push!(generationannualnodal, @build_constraint(sumexps[2] == vgenerationannualnodal[lastkeys[1], lastkeys[4], lastkeys[5]]))
                push!(regenerationannualnodal, @build_constraint(sumexps[3] == vregenerationannualnodal[lastkeys[1], lastkeys[4], lastkeys[5]]))
                sumexps[2] = AffExpr()
                sumexps[3] = AffExpr()
            end

            add_to_expression!(sumexps[1], vrateofactivitynodal[n,l,t,row[:m],y] * row[:oar])

            # Exclude production from storage in vgenerationannualnodal and vregenerationannualnodal
            if ismissing(row[:fs_t])
                add_to_expression!(sumexps[2], vrateofactivitynodal[n,l,t,row[:m],y] * row[:oar] * row[:ys])

                if !ismissing(row[:ret]) && row[:ret] > 0
                    add_to_expression!(sumexps[3], vrateofactivitynodal[n,l,t,row[:m],y] * row[:oar] * row[:ys] * row[:ret])
                end
            end

            lastkeys[1] = n
            lastkeys[2] = l
            lastkeys[3] = t
            lastkeys[4] = f
            lastkeys[5] = y
        end

        # Create last constraints
        if isassigned(lastkeys, 1)
            push!(eba2tr_rateoffuelproduction2, @build_constraint(sumexps[1] ==
                vrateofproductionbytechnologynodal[lastkeys[1], lastkeys[2], lastkeys[3], lastkeys[4], lastkeys[5]]))
            push!(generationannualnodal, @build_constraint(sumexps[2] == vgenerationannualnodal[lastkeys[1], lastkeys[4], lastkeys[5]]))
            push!(regenerationannualnodal, @build_constraint(sumexps[3] == vregenerationannualnodal[lastkeys[1], lastkeys[4], lastkeys[5]]))
        end

        put!(cons_channel, eba2tr_rateoffuelproduction2)
        put!(cons_channel, generationannualnodal)
        put!(cons_channel, regenerationannualnodal)
    end)

    numconsarrays += 3
    logmsg("Queued constraint EBa2Tr_RateOfFuelProduction2 for creation.", quiet)
    logmsg("Queued constraint GenerationAnnualNodal for creation.", quiet)
    logmsg("Queued constraint ReGenerationAnnualNodal for creation.", quiet)
end
# END: EBa2Tr_RateOfFuelProduction2 and GenerationAnnualNodal, and ReGenerationAnnualNodal.

# BEGIN: EBa3_RateOfFuelProduction3.
eba3_rateoffuelproduction3::Array{AbstractConstraint, 1} = Array{AbstractConstraint, 1}()

t = Threads.@spawn(let
    local lastkeys = Array{String, 1}(undef,4)  # lastkeys[1] = r, lastkeys[2] = l, lastkeys[3] = f, lastkeys[4] = y
    local sumexps = Array{AffExpr, 1}([AffExpr()])  # sumexps[1] = vrateofproductionbytechnologynn sum

    # First step: define vrateofproductionnn where technologies exist
    for row in DataFrames.eachrow(queries["queryvrateofproductionbytechnologynn"])
        local r = row[:r]
        local l = row[:l]
        local f = row[:f]
        local y = row[:y]

        if isassigned(lastkeys, 1) && (r != lastkeys[1] || l != lastkeys[2] || f != lastkeys[3] || y != lastkeys[4])
            # Create constraint
            push!(eba3_rateoffuelproduction3, @build_constraint(sumexps[1] == vrateofproductionnn[lastkeys[1],lastkeys[2],lastkeys[3],lastkeys[4]]))
            sumexps[1] = AffExpr()
        end

        add_to_expression!(sumexps[1], vrateofproductionbytechnologynn[r,l,row[:t],f,y])

        lastkeys[1] = r
        lastkeys[2] = l
        lastkeys[3] = f
        lastkeys[4] = y
    end

    # Create last constraint
    if isassigned(lastkeys, 1)
        push!(eba3_rateoffuelproduction3, @build_constraint(sumexps[1] == vrateofproductionnn[lastkeys[1],lastkeys[2],lastkeys[3],lastkeys[4]]))
    end

    # Second step: define vrateofproductionnn where technologies don't exist
    for row in SQLite.DBInterface.execute(db, "select r.val as r, l.val as l, f.val as f, y.val as y
    from region r, TIMESLICE l, fuel f, year y
    left join TransmissionModelingEnabled tme on tme.r = r.val and tme.f = f.val and tme.y = y.val
    left join (select distinct r, t, f, y from OutputActivityRatio_def where val <> 0) oar
    	on oar.r = r.val and oar.f = f.val and oar.y = y.val
    where tme.id is null
    and oar.t is null
    $(restrictyears ? "and y.val in" * inyears : "")")

        push!(eba3_rateoffuelproduction3, @build_constraint(0 == vrateofproductionnn[row[:r],row[:l],row[:f],row[:y]]))
    end

    put!(cons_channel, eba3_rateoffuelproduction3)
end)

numconsarrays += 1
logmsg("Queued constraint EBa3_RateOfFuelProduction3 for creation.", quiet)
# END: EBa3_RateOfFuelProduction3.

# BEGIN: EBa3Tr_RateOfFuelProduction3.
if transmissionmodeling
    eba3tr_rateoffuelproduction3::Array{AbstractConstraint, 1} = Array{AbstractConstraint, 1}()

    t = Threads.@spawn(let
        local lastkeys = Array{String, 1}(undef,4)  # lastkeys[1] = n, lastkeys[2] = l, lastkeys[3] = f, lastkeys[4] = y
        local sumexps = Array{AffExpr, 1}([AffExpr()])  # sumexps[1] = vrateofproductionbytechnologynodal sum

        # First step: set vrateofproductionnodal for nodes with technologies
        for row in DataFrames.eachrow(queries["queryvrateofproductionbytechnologynodal"])
            local n = row[:n]
            local l = row[:l]
            local f = row[:f]
            local y = row[:y]

            if isassigned(lastkeys, 1) && (n != lastkeys[1] || l != lastkeys[2] || f != lastkeys[3] || y != lastkeys[4])
                # Create constraint
                push!(eba3tr_rateoffuelproduction3, @build_constraint(sumexps[1] == vrateofproductionnodal[lastkeys[1],lastkeys[2],lastkeys[3],lastkeys[4]]))
                sumexps[1] = AffExpr()
            end

            add_to_expression!(sumexps[1], vrateofproductionbytechnologynodal[n,l,row[:t],f,y])

            lastkeys[1] = n
            lastkeys[2] = l
            lastkeys[3] = f
            lastkeys[4] = y
        end

        # Create last constraint
        if isassigned(lastkeys, 1)
            push!(eba3tr_rateoffuelproduction3, @build_constraint(sumexps[1] == vrateofproductionnodal[lastkeys[1],lastkeys[2],lastkeys[3],lastkeys[4]]))
        end

        # Second step: set vrateofproductionnodal for nodes that do not have technologies with output
        for row in SQLite.DBInterface.execute(db, "with ntc_oar as (select ntc.n as n, oar.f as f, ntc.y as y
        from NodalDistributionTechnologyCapacity_def ntc, NODE n, OutputActivityRatio_def oar
        where ntc.val > 0
        and ntc.n = n.val
        and oar.r = n.r and oar.t = ntc.t and oar.y = ntc.y and oar.val <> 0)
        select n.val as n, l.val as l, f.val as f, y.val as y
        	from node n, timeslice l, fuel f, year y, TransmissionModelingEnabled tme
        	left join ntc_oar on ntc_oar.n = n.val and ntc_oar.f = f.val and ntc_oar.y = y.val
        	where n.r = tme.r
        	and f.val = tme.f
        	and y.val = tme.y
        	and ntc_oar.n is null
            $(restrictyears ? "and y.val in" * inyears : "")")

            push!(eba3tr_rateoffuelproduction3, @build_constraint(0 == vrateofproductionnodal[row[:n],row[:l],row[:f],row[:y]]))
        end

        put!(cons_channel, eba3tr_rateoffuelproduction3)
    end)

    numconsarrays += 1
    logmsg("Queued constraint EBa3Tr_RateOfFuelProduction3 for creation.", quiet)
end
# END: EBa3Tr_RateOfFuelProduction3.

# BEGIN: VRateOfProduction1.
vrateofproduction1::Array{AbstractConstraint, 1} = Array{AbstractConstraint, 1}()

t = Threads.@spawn(let
    if !transmissionmodeling
        for (r, l, f, y) in Base.product(sregion, stimeslice, sfuel, syear)
            push!(vrateofproduction1, @build_constraint(vrateofproduction[r,l,f,y] == vrateofproductionnn[r,l,f,y]))
        end
    else
        # Combine nodal and non-nodal
        local lastkeys = Array{String, 1}(undef,4)  # lastkeys[1] = r, lastkeys[2] = l, lastkeys[3] = f, lastkeys[4] = y
        local sumexps = Array{AffExpr, 1}([AffExpr()])  # sumexps[1] = vrateofproductionnodal sum

        for row in DataFrames.eachrow(queries["queryvrateofproduse"])
            local r = row[:r]
            local l = row[:l]
            local f = row[:f]
            local y = row[:y]

            if isassigned(lastkeys, 1) && (r != lastkeys[1] || l != lastkeys[2] || f != lastkeys[3] || y != lastkeys[4])
                # Create constraint
                push!(vrateofproduction1, @build_constraint((sumexps[1] == AffExpr() ? vrateofproductionnn[lastkeys[1],lastkeys[2],lastkeys[3],lastkeys[4]] : sumexps[1])
                    == vrateofproduction[lastkeys[1],lastkeys[2],lastkeys[3],lastkeys[4]]))
                sumexps[1] = AffExpr()
            end

            if !ismissing(row[:tme]) && !ismissing(row[:n])
                add_to_expression!(sumexps[1], vrateofproductionnodal[row[:n],l,f,y])
            end

            lastkeys[1] = r
            lastkeys[2] = l
            lastkeys[3] = f
            lastkeys[4] = y
        end

        # Create last constraint
        if isassigned(lastkeys, 1)
            push!(vrateofproduction1, @build_constraint((sumexps[1] == AffExpr() ? vrateofproductionnn[lastkeys[1],lastkeys[2],lastkeys[3],lastkeys[4]] : sumexps[1])
                == vrateofproduction[lastkeys[1],lastkeys[2],lastkeys[3],lastkeys[4]]))
        end
    end

    put!(cons_channel, vrateofproduction1)
end)

numconsarrays += 1
logmsg("Queued constraint VRateOfProduction1 for creation.", quiet)
# END: VRateOfProduction1.

# BEGIN: EBa4_RateOfFuelUse1.
if in("vrateofusebytechnologybymodenn", varstosavearr)
    eba4_rateoffueluse1::Array{AbstractConstraint, 1} = Array{AbstractConstraint, 1}()

    t = Threads.@spawn(begin
        for row in DataFrames.eachrow(queries["queryvrateofusebytechnologybymodenn"])
            local r = row[:r]
            local l = row[:l]
            local f = row[:f]
            local t = row[:t]
            local m = row[:m]
            local y = row[:y]

            push!(eba4_rateoffueluse1, @build_constraint(vrateofactivity[r,l,t,m,y] * row[:iar] == vrateofusebytechnologybymodenn[r,l,t,m,f,y]))
        end

        put!(cons_channel, eba4_rateoffueluse1)
    end)

    numconsarrays += 1
    logmsg("Queued constraint EBa4_RateOfFuelUse1 for creation.", quiet)
end
# END: EBa4_RateOfFuelUse1.

# BEGIN: EBa5_RateOfFuelUse2.
eba5_rateoffueluse2::Array{AbstractConstraint, 1} = Array{AbstractConstraint, 1}()

t = Threads.@spawn(let
    local lastkeys = Array{String, 1}(undef,5)  # lastkeys[1] = r, lastkeys[2] = l, lastkeys[3] = t, lastkeys[4] = f, lastkeys[5] = y
    local sumexps = Array{AffExpr, 1}([AffExpr()]) # sumexps[1] = vrateofusebytechnologybymodenn-equivalent sum

    for row in DataFrames.eachrow(queries["queryvrateofusebytechnologybymodenn"])
        local r = row[:r]
        local l = row[:l]
        local f = row[:f]
        local t = row[:t]
        local y = row[:y]

        if isassigned(lastkeys, 1) && (r != lastkeys[1] || l != lastkeys[2] || t != lastkeys[3] || f != lastkeys[4] || y != lastkeys[5])
            # Create constraint
            push!(eba5_rateoffueluse2, @build_constraint(sumexps[1] ==
                vrateofusebytechnologynn[lastkeys[1], lastkeys[2], lastkeys[3], lastkeys[4], lastkeys[5]]))
            sumexps[1] = AffExpr()
        end

        add_to_expression!(sumexps[1], vrateofactivity[r,l,t,row[:m],y] * row[:iar])
        # Sum is of vrateofusebytechnologybymodenn[r,l,t,row[:m],f,y])

        lastkeys[1] = r
        lastkeys[2] = l
        lastkeys[3] = t
        lastkeys[4] = f
        lastkeys[5] = y
    end

    # Create last constraint
    if isassigned(lastkeys, 1)
        push!(eba5_rateoffueluse2, @build_constraint(sumexps[1] ==
            vrateofusebytechnologynn[lastkeys[1], lastkeys[2], lastkeys[3], lastkeys[4], lastkeys[5]]))
    end

    put!(cons_channel, eba5_rateoffueluse2)
end)

numconsarrays += 1
logmsg("Queued constraint EBa5_RateOfFuelUse2 for creation.", quiet)
# END: EBa5_RateOfFuelUse2.

# BEGIN: EBa5Tr_RateOfFuelUse2.
if transmissionmodeling
    eba5tr_rateoffueluse2::Array{AbstractConstraint, 1} = Array{AbstractConstraint, 1}()

    t = Threads.@spawn(let
        local lastkeys = Array{String, 1}(undef,5)  # lastkeys[1] = n, lastkeys[2] = l, lastkeys[3] = t, lastkeys[4] = f, lastkeys[5] = y
        local sumexps = Array{AffExpr, 1}([AffExpr()])  # sumexps[1] = vrateofactivitynodal sum

        for row in SQLite.DBInterface.execute(db,
        "select ntc.n as n, ys.l as l, ntc.t as t, iar.f as f, ntc.y as y, m.val as m,
    	   cast(iar.val as real) as iar
        from NodalDistributionTechnologyCapacity_def ntc, YearSplit_def ys, MODE_OF_OPERATION m, NODE n, InputActivityRatio_def iar,
    	TransmissionModelingEnabled tme
        where ntc.val > 0 $(restrictyears ? "and ntc.y in" * inyears : "")
        and ntc.y = ys.y
        and ntc.n = n.val
        and iar.r = n.r and iar.t = ntc.t and iar.m = m.val and iar.y = ntc.y
        and iar.val > 0
    	and tme.r = n.r and tme.f = iar.f and tme.y = ntc.y
        order by ntc.n, ys.l, ntc.t, iar.f, ntc.y")
            local n = row[:n]
            local l = row[:l]
            local t = row[:t]
            local f = row[:f]
            local y = row[:y]

            if isassigned(lastkeys, 1) && (n != lastkeys[1] || l != lastkeys[2] || t != lastkeys[3] || f != lastkeys[4] || y != lastkeys[5])
                # Create constraint
                push!(eba5tr_rateoffueluse2, @build_constraint(sumexps[1] ==
                    vrateofusebytechnologynodal[lastkeys[1], lastkeys[2], lastkeys[3], lastkeys[4], lastkeys[5]]))
                sumexps[1] = AffExpr()
            end

            add_to_expression!(sumexps[1], vrateofactivitynodal[n,l,t,row[:m],y] * row[:iar])

            lastkeys[1] = n
            lastkeys[2] = l
            lastkeys[3] = t
            lastkeys[4] = f
            lastkeys[5] = y
        end

        # Create last constraint
        if isassigned(lastkeys, 1)
            push!(eba5tr_rateoffueluse2, @build_constraint(sumexps[1] ==
                vrateofusebytechnologynodal[lastkeys[1], lastkeys[2], lastkeys[3], lastkeys[4], lastkeys[5]]))
        end

        put!(cons_channel, eba5tr_rateoffueluse2)
    end)

    numconsarrays += 1
    logmsg("Queued constraint EBa5Tr_RateOfFuelUse2 for creation.", quiet)
end
# END: EBa5Tr_RateOfFuelUse2.

# BEGIN: EBa6_RateOfFuelUse3.
eba6_rateoffueluse3::Array{AbstractConstraint, 1} = Array{AbstractConstraint, 1}()

t = Threads.@spawn(let
    local lastkeys = Array{String, 1}(undef,4)  # lastkeys[1] = r, lastkeys[2] = l, lastkeys[3] = f, lastkeys[4] = y
    local sumexps = Array{AffExpr, 1}([AffExpr()])  # sumexps[1] = vrateofusebytechnologynn sum

    for row in DataFrames.eachrow(queries["queryvrateofusebytechnologynn"])
        local r = row[:r]
        local l = row[:l]
        local f = row[:f]
        local y = row[:y]

        if isassigned(lastkeys, 1) && (r != lastkeys[1] || l != lastkeys[2] || f != lastkeys[3] || y != lastkeys[4])
            # Create constraint
            push!(eba6_rateoffueluse3, @build_constraint(sumexps[1] == vrateofusenn[lastkeys[1],lastkeys[2],lastkeys[3],lastkeys[4]]))
            sumexps[1] = AffExpr()
        end

        add_to_expression!(sumexps[1], vrateofusebytechnologynn[r,l,row[:t],f,y])

        lastkeys[1] = r
        lastkeys[2] = l
        lastkeys[3] = f
        lastkeys[4] = y
    end

    # Create last constraint
    if isassigned(lastkeys, 1)
        push!(eba6_rateoffueluse3, @build_constraint(sumexps[1] == vrateofusenn[lastkeys[1],lastkeys[2],lastkeys[3],lastkeys[4]]))
    end

    put!(cons_channel, eba6_rateoffueluse3)
end)

numconsarrays += 1
logmsg("Queued constraint EBa6_RateOfFuelUse3 for creation.", quiet)
# END: EBa6_RateOfFuelUse3.

# BEGIN: EBa6Tr_RateOfFuelUse3.
if transmissionmodeling
    eba6tr_rateoffueluse3::Array{AbstractConstraint, 1} = Array{AbstractConstraint, 1}()

    t = Threads.@spawn(let
        local lastkeys = Array{String, 1}(undef,4)  # lastkeys[1] = n, lastkeys[2] = l, lastkeys[3] = f, lastkeys[4] = y
        local sumexps = Array{AffExpr, 1}([AffExpr()])  # sumexps[1] = vrateofusebytechnologynodal sum

        for row in DataFrames.eachrow(queries["queryvrateofusebytechnologynodal"])
            local n = row[:n]
            local l = row[:l]
            local f = row[:f]
            local y = row[:y]

            if isassigned(lastkeys, 1) && (n != lastkeys[1] || l != lastkeys[2] || f != lastkeys[3] || y != lastkeys[4])
                # Create constraint
                push!(eba6tr_rateoffueluse3, @build_constraint(sumexps[1] == vrateofusenodal[lastkeys[1],lastkeys[2],lastkeys[3],lastkeys[4]]))
                sumexps[1] = AffExpr()
            end

            add_to_expression!(sumexps[1], vrateofusebytechnologynodal[n,l,row[:t],f,y])

            lastkeys[1] = n
            lastkeys[2] = l
            lastkeys[3] = f
            lastkeys[4] = y
        end

        # Create last constraint
        if isassigned(lastkeys, 1)
            push!(eba6tr_rateoffueluse3, @build_constraint(sumexps[1] == vrateofusenodal[lastkeys[1],lastkeys[2],lastkeys[3],lastkeys[4]]))
        end

        put!(cons_channel, eba6tr_rateoffueluse3)
    end)

    numconsarrays += 1
    logmsg("Queued constraint EBa6Tr_RateOfFuelUse3 for creation.", quiet)
end
# END: EBa6Tr_RateOfFuelUse3.

# BEGIN: VRateOfUse1.
vrateofuse1::Array{AbstractConstraint, 1} = Array{AbstractConstraint, 1}()

t = Threads.@spawn(let
    if !transmissionmodeling
        for (r, l, f, y) in Base.product(sregion, stimeslice, sfuel, syear)
            push!(vrateofuse1, @build_constraint(vrateofuse[r,l,f,y] == vrateofusenn[r,l,f,y]))
        end
    else
        # Combine nodal and non-nodal
        local lastkeys = Array{String, 1}(undef,4)  # lastkeys[1] = r, lastkeys[2] = l, lastkeys[3] = f, lastkeys[4] = y
        local sumexps = Array{AffExpr, 1}([AffExpr()])  # sumexps[1] = vrateofusenodal sum

        for row in DataFrames.eachrow(queries["queryvrateofproduse"])
            local r = row[:r]
            local l = row[:l]
            local f = row[:f]
            local y = row[:y]

            if isassigned(lastkeys, 1) && (r != lastkeys[1] || l != lastkeys[2] || f != lastkeys[3] || y != lastkeys[4])
                # Create constraint
                push!(vrateofuse1, @build_constraint((sumexps[1] == AffExpr() ? vrateofusenn[lastkeys[1],lastkeys[2],lastkeys[3],lastkeys[4]] : sumexps[1])
                    == vrateofuse[lastkeys[1],lastkeys[2],lastkeys[3],lastkeys[4]]))
                sumexps[1] = AffExpr()
            end

            if !ismissing(row[:tme]) && !ismissing(row[:n])
                add_to_expression!(sumexps[1], vrateofusenodal[row[:n],l,f,y])
            end

            lastkeys[1] = r
            lastkeys[2] = l
            lastkeys[3] = f
            lastkeys[4] = y
        end

        # Create last constraint
        if isassigned(lastkeys, 1)
            push!(vrateofuse1, @build_constraint((sumexps[1] == AffExpr() ? vrateofusenn[lastkeys[1],lastkeys[2],lastkeys[3],lastkeys[4]] : sumexps[1])
                == vrateofuse[lastkeys[1],lastkeys[2],lastkeys[3],lastkeys[4]]))
        end
    end

    put!(cons_channel, vrateofuse1)
end)

numconsarrays += 1
logmsg("Queued constraint VRateOfUse1 for creation.", quiet)
# END: VRateOfUse1.

# BEGIN: EBa7_EnergyBalanceEachTS1 and EBa8_EnergyBalanceEachTS2.
eba7_energybalanceeachts1::Array{AbstractConstraint, 1} = Array{AbstractConstraint, 1}()
eba8_energybalanceeachts2::Array{AbstractConstraint, 1} = Array{AbstractConstraint, 1}()

t = Threads.@spawn(begin
    for row in SQLite.DBInterface.execute(db, "select r.val as r, l.val as l, f.val as f, y.val as y, cast(ys.val as real) as ys
    from region r, timeslice l, fuel f, year y, YearSplit_def ys
    left join TransmissionModelingEnabled tme on tme.r = r.val and tme.f = f.val and tme.y = y.val
    where
    ys.l = l.val and ys.y = y.val
    $(restrictyears ? "and y.val in" * inyears : "")
    and tme.id is null")
        local r = row[:r]
        local l = row[:l]
        local f = row[:f]
        local y = row[:y]

        push!(eba7_energybalanceeachts1, @build_constraint(vrateofproductionnn[r,l,f,y] * row[:ys] == vproductionnn[r,l,f,y]))
        push!(eba8_energybalanceeachts2, @build_constraint(vrateofusenn[r,l,f,y] * row[:ys] == vusenn[r,l,f,y]))
    end

    put!(cons_channel, eba7_energybalanceeachts1)
    put!(cons_channel, eba8_energybalanceeachts2)
end)

numconsarrays += 2
logmsg("Queued constraint EBa7_EnergyBalanceEachTS1 for creation.", quiet)
logmsg("Queued constraint EBa8_EnergyBalanceEachTS2 for creation.", quiet)
# END: EBa7_EnergyBalanceEachTS1 and EBa8_EnergyBalanceEachTS2.

# BEGIN: EBa7Tr_EnergyBalanceEachTS1 and EBa8Tr_EnergyBalanceEachTS2.
if transmissionmodeling
    eba7tr_energybalanceeachts1::Array{AbstractConstraint, 1} = Array{AbstractConstraint, 1}()
    eba8tr_energybalanceeachts2::Array{AbstractConstraint, 1} = Array{AbstractConstraint, 1}()

    t = Threads.@spawn(begin
        for row in SQLite.DBInterface.execute(db, "select n.val as n, l.val as l, f.val as f, y.val as y, cast(ys.val as real) as ys
        from node n, timeslice l, fuel f, year y, YearSplit_def ys,
        TransmissionModelingEnabled tme
        where
        ys.l = l.val and ys.y = y.val
        and tme.r = n.r and tme.f = f.val and tme.y = y.val
        $(restrictyears ? "and y.val in" * inyears : "")")
            local n = row[:n]
            local l = row[:l]
            local f = row[:f]
            local y = row[:y]

            push!(eba7tr_energybalanceeachts1, @build_constraint(vrateofproductionnodal[n,l,f,y] * row[:ys] == vproductionnodal[n,l,f,y]))
            push!(eba8tr_energybalanceeachts2, @build_constraint(vrateofusenodal[n,l,f,y] * row[:ys] == vusenodal[n,l,f,y]))
        end

        put!(cons_channel, eba7tr_energybalanceeachts1)
        put!(cons_channel, eba8tr_energybalanceeachts2)
    end)

    numconsarrays += 2
    logmsg("Queued constraint EBa7Tr_EnergyBalanceEachTS1 for creation.", quiet)
    logmsg("Queued constraint EBa8Tr_EnergyBalanceEachTS2 for creation.", quiet)
end
# END: EBa7Tr_EnergyBalanceEachTS1 and EBa8Tr_EnergyBalanceEachTS2.

# BEGIN: EBa9_EnergyBalanceEachTS3.
eba9_energybalanceeachts3::Array{AbstractConstraint, 1} = Array{AbstractConstraint, 1}()

t = Threads.@spawn(begin
    for row in DataFrames.eachrow(queries["queryvrateofdemandnn"])
        local r = row[:r]
        local l = row[:l]
        local f = row[:f]
        local y = row[:y]

        push!(eba9_energybalanceeachts3, @build_constraint(row[:specifiedannualdemand] * row[:specifieddemandprofile] == vdemandnn[r,l,f,y]))
    end

    put!(cons_channel, eba9_energybalanceeachts3)
end)

numconsarrays += 1
logmsg("Queued constraint EBa9_EnergyBalanceEachTS3 for creation.", quiet)
# END: EBa9_EnergyBalanceEachTS3.

# BEGIN: EBa9Tr_EnergyBalanceEachTS3.
if transmissionmodeling
    eba9tr_energybalanceeachts3::Array{AbstractConstraint, 1} = Array{AbstractConstraint, 1}()

    t = Threads.@spawn(begin
        for row in SQLite.DBInterface.execute(db, "select sdp.r as r, sdp.f as f, sdp.l as l, sdp.y as y, ndd.n as n,
        cast(sdp.val as real) as specifieddemandprofile, cast(sad.val as real) as specifiedannualdemand,
        cast(ndd.val as real) as ndd
        from SpecifiedDemandProfile_def sdp, SpecifiedAnnualDemand_def sad, TransmissionModelingEnabled tme,
        NodalDistributionDemand_def ndd, NODE n
        where sad.r = sdp.r and sad.f = sdp.f and sad.y = sdp.y
        and sdp.val <> 0 and sad.val <> 0 $(restrictyears ? "and sad.y in" * inyears : "")
        and tme.r = sad.r and tme.f = sad.f and tme.y = sad.y
        and ndd.n = n.val
        and n.r = sad.r and ndd.f = sad.f and ndd.y = sad.y
        and ndd.val > 0")
            local n = row[:n]
            local l = row[:l]
            local f = row[:f]
            local y = row[:y]

            push!(eba9tr_energybalanceeachts3, @build_constraint(row[:specifiedannualdemand] * row[:specifieddemandprofile]
                * row[:ndd] == vdemandnodal[n,l,f,y]))
        end

        put!(cons_channel, eba9tr_energybalanceeachts3)
    end)

    numconsarrays += 1
    logmsg("Queued constraint EBa9Tr_EnergyBalanceEachTS3 for creation.", quiet)
end
# END: EBa9Tr_EnergyBalanceEachTS3.

#= Deprecated in NEMO 1.4
# BEGIN: EBa10_EnergyBalanceEachTS4.
eba10_energybalanceeachts4::Array{AbstractConstraint, 1} = Array{AbstractConstraint, 1}()

for (r, rr, l, f, y) in Base.product(sregion, sregion, stimeslice, sfuel, syear)
    push!(eba10_energybalanceeachts4, @build_constraint(vtrade[r,rr,l,f,y] == -vtrade[rr,r,l,f,y]))
end

length(eba10_energybalanceeachts4) > 0 && logmsg("Created constraint EBa10_EnergyBalanceEachTS4.", quiet)
# END: EBa10_EnergyBalanceEachTS4. =#

# BEGIN: EBa11_EnergyBalanceEachTS5.
eba11_energybalanceeachts5::Array{AbstractConstraint, 1} = Array{AbstractConstraint, 1}()
t = Threads.@spawn(let
    local lastkeys = Array{String, 1}(undef,4)  # lastkeys[1] = r, lastkeys[2] = l, lastkeys[3] = f, lastkeys[4] = y
    local sumexps = Array{AffExpr, 1}([AffExpr()]) # sumexps[1] = vtrade sum

    for row in SQLite.DBInterface.execute(db, "select r.val as r, l.val as l, f.val as f, y.val as y, tr.r as tr_r, tr.rr as tr_rr,
        cast(tr.val as real) as trv
    from region r, timeslice l, fuel f, year y
    left join traderoute_def tr on (tr.r = r.val or tr.rr = r.val) and tr.f = f.val and tr.y = y.val and tr.r <> tr.rr and tr.val = 1
    left join TransmissionModelingEnabled tme on tme.r = r.val and tme.f = f.val and tme.y = y.val
    where tme.id is null
    $(restrictyears ? "and y.val in" * inyears : "")
    order by r.val, l.val, f.val, y.val")
        local r = row[:r]
        local l = row[:l]
        local f = row[:f]
        local y = row[:y]

        if isassigned(lastkeys, 1) && (r != lastkeys[1] || l != lastkeys[2] || f != lastkeys[3] || y != lastkeys[4])
            # Create constraint
            push!(eba11_energybalanceeachts5, @build_constraint(vproductionnn[lastkeys[1],lastkeys[2],lastkeys[3],lastkeys[4]] >=
                vdemandnn[lastkeys[1],lastkeys[2],lastkeys[3],lastkeys[4]] + vusenn[lastkeys[1],lastkeys[2],lastkeys[3],lastkeys[4]] + sumexps[1]))
            sumexps[1] = AffExpr()
        end

        # To enable trade between regions, one row in TradeRoute with value = 1.0 should be specified
        # Query results limited to rows with value = 1.0
        if !ismissing(row[:trv])
            if row[:tr_r] == r
                add_to_expression!(sumexps[1], vtrade[r,row[:tr_rr],l,f,y])
            else
                add_to_expression!(sumexps[1], -vtrade[row[:tr_r],r,l,f,y])
            end
        end

        lastkeys[1] = r
        lastkeys[2] = l
        lastkeys[3] = f
        lastkeys[4] = y
    end

    # Create last constraint
    if isassigned(lastkeys, 1)
        push!(eba11_energybalanceeachts5, @build_constraint(vproductionnn[lastkeys[1],lastkeys[2],lastkeys[3],lastkeys[4]] >=
            vdemandnn[lastkeys[1],lastkeys[2],lastkeys[3],lastkeys[4]] + vusenn[lastkeys[1],lastkeys[2],lastkeys[3],lastkeys[4]] + sumexps[1]))
    end

    put!(cons_channel, eba11_energybalanceeachts5)
end)

numconsarrays += 1
logmsg("Queued constraint EBa11_EnergyBalanceEachTS5 for creation.", quiet)
# END: EBa11_EnergyBalanceEachTS5.

# BEGIN: Tr1_SumBuilt.
# Ensures vtransmissionbuilt can be 1 in at most one year
if transmissionmodeling
    tr1_sumbuilt::Array{AbstractConstraint, 1} = Array{AbstractConstraint, 1}()

    t = Threads.@spawn(begin
        for tr in stransmission
            push!(tr1_sumbuilt, @build_constraint(sum([vtransmissionbuilt[tr,y] for y in syear]) <= 1))
        end

        put!(cons_channel, tr1_sumbuilt)
    end)

    numconsarrays += 1
    logmsg("Queued constraint Tr1_SumBuilt for creation.", quiet)
end
# END: Tr1_SumBuilt.

# BEGIN: Tr2_TransmissionExists.
if transmissionmodeling
    tr2_transmissionexists::Array{AbstractConstraint, 1} = Array{AbstractConstraint, 1}()

    t = Threads.@spawn(let
        local lastkeys = Array{String, 1}(undef,2)  # lastkeys[1] = tr, lastkeys[2] = y
        local lastvalsint = Array{Int64, 1}(undef,2)  # lastvalsint[1] = yconstruction, lastvalsint[2] = operationallife
        local sumexps = Array{AffExpr, 1}([AffExpr()])  # sumexps[1] = vtransmissionbuilt sum

        for row in SQLite.DBInterface.execute(db, "select tl.id as tr, tl.yconstruction, tl.operationallife, y.val as y, null as yy
        from TransmissionLine tl, YEAR y
        where tl.yconstruction is not null
        $(restrictyears ? "and y.val in" * inyears : "")
        union all
        select tl.id as tr, tl.yconstruction, tl.operationallife, y.val as y, yy.val as yy
        from TransmissionLine tl, YEAR y, YEAR yy
        where tl.yconstruction is null
        and yy.val + tl.operationallife > y.val
        and yy.val <= y.val
        $(restrictyears ? "and y.val in" * inyears : "") $(restrictyears ? "and yy.val in" * inyears : "")
        order by tr, y")
            local tr = row[:tr]
            local y = row[:y]
            local yy = row[:yy]
            local yconstruction = ismissing(row[:yconstruction]) ? 0 : row[:yconstruction]

            if isassigned(lastkeys, 1) && (tr != lastkeys[1] || y != lastkeys[2])
                # Create constraint
                if sumexps[1] == AffExpr()
                    # Exogenously built line
                    if (lastvalsint[1] <= Meta.parse(lastkeys[2])) && (lastvalsint[1] + lastvalsint[2] > Meta.parse(lastkeys[2]))
                        push!(tr2_transmissionexists, @build_constraint(vtransmissionexists[lastkeys[1],lastkeys[2]] == 1))
                    else
                        push!(tr2_transmissionexists, @build_constraint(vtransmissionexists[lastkeys[1],lastkeys[2]] == 0))
                    end
                else
                    # Endogenous option
                    push!(tr2_transmissionexists, @build_constraint(sumexps[1] == vtransmissionexists[lastkeys[1],lastkeys[2]]))
                end

                sumexps[1] = AffExpr()
            end

            if !ismissing(yy)
                add_to_expression!(sumexps[1], vtransmissionbuilt[tr,yy])
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
                    push!(tr2_transmissionexists, @build_constraint(vtransmissionexists[lastkeys[1],lastkeys[2]] == 1))
                else
                    push!(tr2_transmissionexists, @build_constraint(vtransmissionexists[lastkeys[1],lastkeys[2]] == 0))
                end
            else
                # Endogenous option
                push!(tr2_transmissionexists, @build_constraint(sumexps[1] == vtransmissionexists[lastkeys[1],lastkeys[2]]))
            end
        end

        put!(cons_channel, tr2_transmissionexists)
    end)

    numconsarrays += 1
    logmsg("Queued constraint Tr2_TransmissionExists for creation.", quiet)
end
# END: Tr2_TransmissionExists.

# BEGIN: Tr3_Flow, Tr4_MaxFlow, Tr5_MinFlow, Tr6_VariableCost, Tr7_FlowNeg, and Tr8_Losses.
if transmissionmodeling
    tr3_flow::Array{AbstractConstraint, 1} = Array{AbstractConstraint, 1}()
    tr3a_flow::Array{AbstractConstraint, 1} = Array{AbstractConstraint, 1}()
    tr4_maxflow::Array{AbstractConstraint, 1} = Array{AbstractConstraint, 1}()
    tr5_minflow::Array{AbstractConstraint, 1} = Array{AbstractConstraint, 1}()
    tr6_variablecost::Array{AbstractConstraint, 1} = Array{AbstractConstraint, 1}()
    tr7_flowneg::Array{AbstractConstraint, 1} = Array{AbstractConstraint, 1}()
    tr8_losses::Array{AbstractConstraint, 1} = Array{AbstractConstraint, 1}()

    t = Threads.@spawn(begin
        for row in DataFrames.eachrow(queries["queryvtransmissionbyline"])
            local tr = row[:tr]
            local n1 = row[:n1]
            local n2 = row[:n2]
            local l = row[:l]
            local f = row[:f]
            local y = row[:y]
            local type = row[:type]
            local vc = ismissing(row[:vc]) ? 0.0 : row[:vc]

            # vtransmissionbyline is flow over line tr from n1 to n2; unit is MW
            if (!ismissing(row[:eff]) && row[:eff] < 1 && type == 3) || vc > 0
                # Constraints to populate vtransmissionbylineneg - indicates whether corresponding vtransmissionbyline <= 0
                push!(tr7_flowneg, @build_constraint(vtransmissionbyline[tr,l,f,y] >= (-row[:maxflow] - 0.000001) * vtransmissionbylineneg[tr,l,f,y] + 0.000001))
                push!(tr7_flowneg, @build_constraint(vtransmissionbyline[tr,l,f,y] <= row[:maxflow] * (1 - vtransmissionbylineneg[tr,l,f,y])))
            end

            if type == 1  # DCOPF
                push!(tr3_flow, @build_constraint(1/row[:reactance] * (vvoltageangle[n1,l,y] - vvoltageangle[n2,l,y]) * vtransmissionexists[tr,y]
                    == vtransmissionbyline[tr,l,f,y]))
                push!(tr4_maxflow, @build_constraint(vtransmissionbyline[tr,l,f,y] <= row[:maxflow]))
                push!(tr5_minflow, @build_constraint(vtransmissionbyline[tr,l,f,y] >= -row[:maxflow]))
            elseif type == 2  # DCOPF with disjunctive formulation
                push!(tr3_flow, @build_constraint(vtransmissionbyline[tr,l,f,y] -
                    (1/row[:reactance] * (vvoltageangle[n1,l,y] - vvoltageangle[n2,l,y]))
                    <= (1 - vtransmissionexists[tr,y]) * 500000))
                push!(tr3a_flow, @build_constraint(vtransmissionbyline[tr,l,f,y] -
                    (1/row[:reactance] * (vvoltageangle[n1,l,y] - vvoltageangle[n2,l,y]))
                    >= (vtransmissionexists[tr,y] - 1) * 500000))

                push!(tr4_maxflow, @build_constraint(vtransmissionbyline[tr,l,f,y] <= vtransmissionexists[tr,y] * row[:maxflow]))
                push!(tr5_minflow, @build_constraint(vtransmissionbyline[tr,l,f,y] >= -vtransmissionexists[tr,y] * row[:maxflow]))
            elseif type == 3  # Pipeline flow
                push!(tr4_maxflow, @build_constraint(vtransmissionbyline[tr,l,f,y] <= vtransmissionexists[tr,y] * row[:maxflow]))
                push!(tr5_minflow, @build_constraint(vtransmissionbyline[tr,l,f,y] >= -vtransmissionexists[tr,y] * row[:maxflow]))

                if !ismissing(row[:eff]) && row[:eff] < 1
                    # Constraints to populate vtransmissionlosses - losses (as a negative number, in model's energy unit) from perspective of node receiving energy (0 for nodes sending energy)
                    push!(tr8_losses, @build_constraint(vtransmissionlosses[n1,tr,l,f,y] - vtransmissionbyline[tr,l,f,y] * row[:ys] * row[:tcta] * (1 - row[:eff])
                        <= (1 - vtransmissionbylineneg[tr,l,f,y]) * 500000))
                    push!(tr8_losses, @build_constraint(vtransmissionlosses[n1,tr,l,f,y] - vtransmissionbyline[tr,l,f,y] * row[:ys] * row[:tcta] * (1 - row[:eff])
                        >= (vtransmissionbylineneg[tr,l,f,y] - 1) * 500000))
                    push!(tr8_losses, @build_constraint(vtransmissionlosses[n1,tr,l,f,y] <= vtransmissionbylineneg[tr,l,f,y] * row[:maxflow] * row[:ys] * row[:tcta] * (1 - row[:eff])))
                    push!(tr8_losses, @build_constraint(vtransmissionlosses[n1,tr,l,f,y] >= -vtransmissionbylineneg[tr,l,f,y] * row[:maxflow] * row[:ys] * row[:tcta] * (1 - row[:eff])))

                    push!(tr8_losses, @build_constraint(-vtransmissionlosses[n2,tr,l,f,y] - vtransmissionbyline[tr,l,f,y] * row[:ys] * row[:tcta] * (1 - row[:eff])
                        <= (1 - (1-vtransmissionbylineneg[tr,l,f,y])) * 500000))
                    push!(tr8_losses, @build_constraint(-vtransmissionlosses[n2,tr,l,f,y] - vtransmissionbyline[tr,l,f,y] * row[:ys] * row[:tcta] * (1 - row[:eff])
                        >= ((1-vtransmissionbylineneg[tr,l,f,y]) - 1) * 500000))
                    push!(tr8_losses, @build_constraint(vtransmissionlosses[n2,tr,l,f,y] <= (1-vtransmissionbylineneg[tr,l,f,y]) * row[:maxflow] * row[:ys] * row[:tcta] * (1 - row[:eff])))
                    push!(tr8_losses, @build_constraint(vtransmissionlosses[n2,tr,l,f,y] >= -(1-vtransmissionbylineneg[tr,l,f,y]) * row[:maxflow] * row[:ys] * row[:tcta] * (1 - row[:eff])))
                end
            end

            if vc > 0
                # Constraints to populate vvariablecosttransmissionbyts - always >= 0 and accounting for possibility that vtransmissionbyline may be negative
                push!(tr6_variablecost, @build_constraint(vvariablecosttransmissionbyts[tr,l,f,y] + vtransmissionbyline[tr,l,f,y] * row[:ys] * row[:tcta] * vc
                    <= (1 - vtransmissionbylineneg[tr,l,f,y]) * 500000))
                push!(tr6_variablecost, @build_constraint(vvariablecosttransmissionbyts[tr,l,f,y] + vtransmissionbyline[tr,l,f,y] * row[:ys] * row[:tcta] * vc
                    >= (vtransmissionbylineneg[tr,l,f,y] - 1) * 500000))
                push!(tr6_variablecost, @build_constraint(vvariablecosttransmissionbyts[tr,l,f,y] - vtransmissionbyline[tr,l,f,y] * row[:ys] * row[:tcta] * vc
                    >= -2 * vtransmissionbylineneg[tr,l,f,y] * row[:maxflow] * row[:ys] * row[:tcta] * vc))
                push!(tr6_variablecost, @build_constraint(vvariablecosttransmissionbyts[tr,l,f,y] - vtransmissionbyline[tr,l,f,y] * row[:ys] * row[:tcta] * vc
                    <= 2 * vtransmissionbylineneg[tr,l,f,y] * row[:maxflow] * row[:ys] * row[:tcta] * vc))
            end
        end

        put!(cons_channel, tr3_flow)
        put!(cons_channel, tr3a_flow)
        put!(cons_channel, tr4_maxflow)
        put!(cons_channel, tr5_minflow)
        put!(cons_channel, tr6_variablecost)
        put!(cons_channel, tr7_flowneg)
        put!(cons_channel, tr8_losses)
    end)

    numconsarrays += 7
    logmsg("Queued constraint Tr3_Flow for creation.", quiet)
    logmsg("Queued constraint Tr4_MaxFlow for creation.", quiet)
    logmsg("Queued constraint Tr5_MinFlow for creation.", quiet)
    logmsg("Queued constraint Tr6_VariableCost for creation.", quiet)
    logmsg("Queued constraint Tr7_FlowNeg for creation.", quiet)
    logmsg("Queued constraint Tr8_Losses for creation.", quiet)
end
# END: Tr3_Flow, Tr4_MaxFlow, Tr5_MinFlow, Tr6_VariableCost, Tr7_FlowNeg, and Tr8_Losses.

# BEGIN: EBa11Tr_EnergyBalanceEachTS5 and EBb4_EnergyBalanceEachYear.
if transmissionmodeling
    eba11tr_energybalanceeachts5::Array{AbstractConstraint, 1} = Array{AbstractConstraint, 1}()
    ebb4_energybalanceeachyear::Array{AbstractConstraint, 1} = Array{AbstractConstraint, 1}()

    t = Threads.@spawn(let
        local lastkeys = Array{String, 1}(undef,4)  # lastkeys[1] = n, lastkeys[2] = l, lastkeys[3] = f, lastkeys[4] = y
        local sumexps = Array{AffExpr, 1}([AffExpr(), AffExpr()])  # sumexps[1] = vtransmissionbyline sum for eba11tr_energybalanceeachts5 (aggregated by node),
            # sumexps[2] = vtransmissionbyline sum for ebb4_energybalanceeachyear (aggregated by node and timeslice)
        # sumexpsq = Array{QuadExpr, 1}([QuadExpr(), QuadExpr()])  # Quadratic version of sumexps; used if transmission modeling type = 3 and efficiency < 1

        # First query selects transmission-enabled nodes without any transmission lines, second selects transmission-enabled
        #   nodes that are n1 in a valid transmission line, third selects transmission-enabled nodes that are n2 in a
        #   valid transmission line
        for row in SQLite.DBInterface.execute(db, "select n.val as n, ys.l as l, f.val as f, y.val as y,
        cast(ys.val as real) as ys, null as tr, null as n2, null as trneg, null as n1,
    	null as eff, tme.type as type, cast(tcta.val as real) as tcta
        from NODE n, YearSplit_def ys, FUEL f, YEAR y, TransmissionModelingEnabled tme,
    	TransmissionCapacityToActivityUnit_def tcta
    	where ys.y = y.val $(restrictyears ? "and y.val in" * inyears : "")
        and tme.r = n.r and tme.f = f.val and tme.y = y.val
    	and tcta.r = n.r and tcta.f = f.val
    	and not exists (select 1 from TransmissionLine tl, NODE n2, TransmissionModelingEnabled tme2
    	where
    	n.val = tl.n1 and f.val = tl.f
    	and tl.n2 = n2.val
    	and n2.r = tme2.r and tl.f = tme2.f and y.val = tme2.y and tme.type = tme2.type)
    	and not exists (select 1 from TransmissionLine tl, NODE n2, TransmissionModelingEnabled tme2
    	where
    	n.val = tl.n2 and f.val = tl.f
    	and tl.n1 = n2.val
    	and n2.r = tme2.r and tl.f = tme2.f and y.val = tme2.y and tme.type = tme2.type)
    union all
    select n.val as n, ys.l as l, f.val as f, y.val as y,
        cast(ys.val as real) as ys, tl.id as tr, tl.n2 as n2, null as trneg, null as n1,
        cast(tl.efficiency as real) as eff, tme.type as type,
    	cast(tcta.val as real) as tcta
        from NODE n, YearSplit_def ys, FUEL f, YEAR y, TransmissionModelingEnabled tme,
    	TransmissionLine tl, NODE n2, TransmissionModelingEnabled tme2, TransmissionCapacityToActivityUnit_def tcta
    	where ys.y = y.val $(restrictyears ? "and y.val in" * inyears : "")
        and tme.r = n.r and tme.f = f.val and tme.y = y.val
    	and tcta.r = n.r and tcta.f = f.val
    	and n.val = tl.n1 and f.val = tl.f
    	and tl.n2 = n2.val
    	and n2.r = tme2.r and tl.f = tme2.f and y.val = tme2.y and tme.type = tme2.type
    union all
    select n.val as n, ys.l as l, f.val as f, y.val as y,
        cast(ys.val as real) as ys, null as tr, null as n2, tl.id as trneg, tl.n1 as n1,
    	cast(tl.efficiency as real) as eff, tme.type as type,
    	cast(tcta.val as real) as tcta
        from NODE n, YearSplit_def ys, FUEL f, YEAR y, TransmissionModelingEnabled tme,
    	TransmissionLine tl, NODE n2, TransmissionModelingEnabled tme2, TransmissionCapacityToActivityUnit_def tcta
    	where ys.y = y.val $(restrictyears ? "and y.val in" * inyears : "")
        and tme.r = n.r and tme.f = f.val and tme.y = y.val
    	and tcta.r = n.r and tcta.f = f.val
    	and n.val = tl.n2 and f.val = tl.f
    	and tl.n1 = n2.val
    	and n2.r = tme2.r and tl.f = tme2.f and y.val = tme2.y and tme.type = tme2.type
    order by n, f, y, l")
            local n = row[:n]
            local l = row[:l]
            local f = row[:f]
            local y = row[:y]
            local tr = row[:tr]  # Transmission line for which n is from node (n1)
            local trneg = row[:trneg]  # Transmission line for which n is to node (n2)
            local eff = ismissing(row[:eff]) ? 1.0 : row[:eff]
            local trtype = row[:type]  # Type of transmission modeling for node

            if isassigned(lastkeys, 1) && (n != lastkeys[1] || l != lastkeys[2] || f != lastkeys[3] || y != lastkeys[4])
                # Create constraint
                # May want to change this to an equality constraint
                push!(eba11tr_energybalanceeachts5, @build_constraint(vproductionnodal[lastkeys[1],lastkeys[2],lastkeys[3],lastkeys[4]] >=
                    vdemandnodal[lastkeys[1],lastkeys[2],lastkeys[3],lastkeys[4]] + vusenodal[lastkeys[1],lastkeys[2],lastkeys[3],lastkeys[4]] + sumexps[1]))
                    #+ (length(quad_terms(sumexpsq[1])) > 0 ? sumexpsq[1] : 0)))
                sumexps[1] = AffExpr()
                #sumexpsq[1] = QuadExpr()
            end

            if isassigned(lastkeys, 1) && (n != lastkeys[1] || f != lastkeys[3] || y != lastkeys[4])
                # Create constraint
                # vtransmissionannual is net annual transmission from n in energy terms
                push!(ebb4_energybalanceeachyear, @build_constraint(vtransmissionannual[lastkeys[1],lastkeys[3],lastkeys[4]] == sumexps[2]))
                    #+ (length(quad_terms(sumexpsq[2])) > 0 ? sumexpsq[2] : 0)))
                sumexps[2] = AffExpr()
                #sumexpsq[2] = QuadExpr()
            end

            if !ismissing(tr)
                if trtype == 1 || trtype == 2 || (trtype == 3 && eff >= 1)
                    add_to_expression!(sumexps[1], vtransmissionbyline[tr,l,f,y] * row[:ys] * row[:tcta])
                    add_to_expression!(sumexps[2], vtransmissionbyline[tr,l,f,y] * row[:ys] * row[:tcta])
                elseif trtype == 3 && eff < 1  # Incorporate efficiency in pipeline flow; vtransmissionlosses are losses (as a negative number, in model's energy unit) from perspective of node receiving energy (0 for nodes sending energy)
                    add_to_expression!(sumexps[1], vtransmissionbyline[tr,l,f,y] * row[:ys] * row[:tcta] - vtransmissionlosses[n,tr,l,f,y])
                    add_to_expression!(sumexps[2], vtransmissionbyline[tr,l,f,y] * row[:ys] * row[:tcta] - vtransmissionlosses[n,tr,l,f,y])
                    #sumexpsq[1] = @expression(jumpmodel, sumexpsq[1] + vtransmissionbyline[tr,l,f,y] * row[:ys] * row[:tcta] * (vtransmissionbylineneg[tr,l,f,y] * (eff-1) + 1))
                    #sumexpsq[2] = @expression(jumpmodel, sumexpsq[2] + vtransmissionbyline[tr,l,f,y] * row[:ys] * row[:tcta] * (vtransmissionbylineneg[tr,l,f,y] * (eff-1) + 1))
                end
            end

            if !ismissing(trneg)
                if trtype == 1 || trtype == 2 || (trtype == 3 && eff >= 1)
                    add_to_expression!(sumexps[1], -vtransmissionbyline[trneg,l,f,y] * row[:ys] * row[:tcta])
                    add_to_expression!(sumexps[2], -vtransmissionbyline[trneg,l,f,y] * row[:ys] * row[:tcta])
                elseif trtype == 3 && eff < 1  # Incorporate efficiency for to node in pipeline flow; vtransmissionlosses are losses (as a negative number, in model's energy unit) from perspective of node receiving energy (0 for nodes sending energy)
                    add_to_expression!(sumexps[1], -vtransmissionbyline[trneg,l,f,y] * row[:ys] * row[:tcta] - vtransmissionlosses[n,trneg,l,f,y])
                    add_to_expression!(sumexps[2], -vtransmissionbyline[trneg,l,f,y] * row[:ys] * row[:tcta] - vtransmissionlosses[n,trneg,l,f,y])
                    #sumexpsq[1] = @expression(jumpmodel, sumexpsq[1] + -vtransmissionbyline[trneg,l,f,y] * row[:ys] * row[:tcta] * (eff + vtransmissionbylineneg[trneg,l,f,y] * (1-eff)))
                    #sumexpsq[2] = @expression(jumpmodel, sumexpsq[2] + -vtransmissionbyline[trneg,l,f,y] * row[:ys] * row[:tcta] * (eff + vtransmissionbylineneg[trneg,l,f,y] * (1-eff)))
                end
            end

            lastkeys[1] = n
            lastkeys[2] = l
            lastkeys[3] = f
            lastkeys[4] = y
        end

        # Create last constraint
        if isassigned(lastkeys, 1)
            push!(eba11tr_energybalanceeachts5, @build_constraint(vproductionnodal[lastkeys[1],lastkeys[2],lastkeys[3],lastkeys[4]] >=
                vdemandnodal[lastkeys[1],lastkeys[2],lastkeys[3],lastkeys[4]] + vusenodal[lastkeys[1],lastkeys[2],lastkeys[3],lastkeys[4]] + sumexps[1]))
                #+ (length(quad_terms(sumexpsq[1])) > 0 ? sumexpsq[1] : 0)))
            push!(ebb4_energybalanceeachyear, @build_constraint(vtransmissionannual[lastkeys[1],lastkeys[3],lastkeys[4]] == sumexps[2]))
                #+ (length(quad_terms(sumexpsq[2])) > 0 ? sumexpsq[2] : 0)))
        end

        put!(cons_channel, eba11tr_energybalanceeachts5)
        put!(cons_channel, ebb4_energybalanceeachyear)
    end)

    numconsarrays += 2
    logmsg("Queued constraint EBa11Tr_EnergyBalanceEachTS5 for creation.", quiet)
    logmsg("Queued constraint EBb4_EnergyBalanceEachYear for creation.", quiet)
end
# END: EBa11Tr_EnergyBalanceEachTS5 and EBb4_EnergyBalanceEachYear.

# BEGIN: EBb0_EnergyBalanceEachYear.
ebb0_energybalanceeachyear::Array{AbstractConstraint, 1} = Array{AbstractConstraint, 1}()

t = Threads.@spawn(begin
    for (r, f, y) in Base.product(sregion, sfuel, syear)
        push!(ebb0_energybalanceeachyear, @build_constraint(sum([vdemandnn[r,l,f,y] for l = stimeslice]) == vdemandannualnn[r,f,y]))
    end

    put!(cons_channel, ebb0_energybalanceeachyear)
end)

numconsarrays += 1
logmsg("Queued constraint EBb0_EnergyBalanceEachYear for creation.", quiet)
# END: EBb0_EnergyBalanceEachYear.

# BEGIN: EBb0Tr_EnergyBalanceEachYear.
if transmissionmodeling
    ebb0tr_energybalanceeachyear::Array{AbstractConstraint, 1} = Array{AbstractConstraint, 1}()

    t = Threads.@spawn(begin
        for (n, f, y) in Base.product(snode, sfuel, syear)
            push!(ebb0tr_energybalanceeachyear, @build_constraint(sum([vdemandnodal[n,l,f,y] for l = stimeslice]) == vdemandannualnodal[n,f,y]))
        end

        put!(cons_channel, ebb0tr_energybalanceeachyear)
    end)

    numconsarrays += 1
    logmsg("Queued constraint EBb0Tr_EnergyBalanceEachYear for creation.", quiet)
end
# END: EBb0Tr_EnergyBalanceEachYear.

# BEGIN: EBb1_EnergyBalanceEachYear.
ebb1_energybalanceeachyear::Array{AbstractConstraint, 1} = Array{AbstractConstraint, 1}()

t = Threads.@spawn(begin
    for (r, f, y) in Base.product(sregion, sfuel, syear)
        push!(ebb1_energybalanceeachyear, @build_constraint(sum([vproductionnn[r,l,f,y] for l = stimeslice]) == vproductionannualnn[r,f,y]))
    end

    put!(cons_channel, ebb1_energybalanceeachyear)
end)

numconsarrays += 1
logmsg("Queued constraint EBb1_EnergyBalanceEachYear for creation.", quiet)
# END: EBb1_EnergyBalanceEachYear.

# BEGIN: EBb1Tr_EnergyBalanceEachYear.
if transmissionmodeling
    ebb1tr_energybalanceeachyear::Array{AbstractConstraint, 1} = Array{AbstractConstraint, 1}()

    t = Threads.@spawn(begin
        for (n, f, y) in Base.product(snode, sfuel, syear)
            push!(ebb1tr_energybalanceeachyear, @build_constraint(sum([vproductionnodal[n,l,f,y] for l = stimeslice]) == vproductionannualnodal[n,f,y]))
        end

        put!(cons_channel, ebb1tr_energybalanceeachyear)
    end)

    numconsarrays += 1
    logmsg("Queued constraint EBb1Tr_EnergyBalanceEachYear for creation.", quiet)
end
# END: EBb1Tr_EnergyBalanceEachYear.

# BEGIN: EBb2_EnergyBalanceEachYear.
ebb2_energybalanceeachyear::Array{AbstractConstraint, 1} = Array{AbstractConstraint, 1}()

t = Threads.@spawn(begin
    for (r, f, y) in Base.product(sregion, sfuel, syear)
        push!(ebb2_energybalanceeachyear, @build_constraint(sum([vusenn[r,l,f,y] for l = stimeslice]) == vuseannualnn[r,f,y]))
    end

    put!(cons_channel, ebb2_energybalanceeachyear)
end)

numconsarrays += 1
logmsg("Queued constraint EBb2_EnergyBalanceEachYear for creation.", quiet)
# END: EBb2_EnergyBalanceEachYear.

# BEGIN: EBb2Tr_EnergyBalanceEachYear.
if transmissionmodeling
    ebb2tr_energybalanceeachyear::Array{AbstractConstraint, 1} = Array{AbstractConstraint, 1}()

    t = Threads.@spawn(begin
        for (n, f, y) in Base.product(snode, sfuel, syear)
            push!(ebb2tr_energybalanceeachyear, @build_constraint(sum([vusenodal[n,l,f,y] for l = stimeslice]) == vuseannualnodal[n,f,y]))
        end

        put!(cons_channel, ebb2tr_energybalanceeachyear)
    end)

    numconsarrays += 1
    logmsg("Queued constraint EBb2Tr_EnergyBalanceEachYear for creation.", quiet)
end
# END: EBb2Tr_EnergyBalanceEachYear.

# BEGIN: EBb3_EnergyBalanceEachYear.
ebb3_energybalanceeachyear::Array{AbstractConstraint, 1} = Array{AbstractConstraint, 1}()

t = Threads.@spawn(let
    local lastkeys = Array{String, 1}(undef,4)  # lastkeys[1] = r, lastkeys[2] = rr, lastkeys[3] = f, lastkeys[4] = y
    local sumexps = Array{AffExpr, 1}([AffExpr()])  # sumexps[1] = vtrade sum

    for row in DataFrames.eachrow(queries["queryvtrade"])
        local r = row[:r]
        local rr = row[:rr]
        local f = row[:f]
        local y = row[:y]

        if isassigned(lastkeys, 1) && (r != lastkeys[1] || rr != lastkeys[2] || f != lastkeys[3] || y != lastkeys[4])
            # Create constraint
            push!(ebb3_energybalanceeachyear, @build_constraint(sumexps[1] == vtradeannual[lastkeys[1],lastkeys[2],lastkeys[3],lastkeys[4]]))
            sumexps[1] = AffExpr()
        end

        add_to_expression!(sumexps[1], vtrade[r,rr,row[:l],f,y])

        lastkeys[1] = r
        lastkeys[2] = rr
        lastkeys[3] = f
        lastkeys[4] = y
    end

    # Create last constraint
    if isassigned(lastkeys, 1)
        push!(ebb3_energybalanceeachyear, @build_constraint(sumexps[1] == vtradeannual[lastkeys[1],lastkeys[2],lastkeys[3],lastkeys[4]]))
    end

    put!(cons_channel, ebb3_energybalanceeachyear)
end)

numconsarrays += 1
logmsg("Queued constraint EBb3_EnergyBalanceEachYear for creation.", quiet)
# END: EBb3_EnergyBalanceEachYear.

# BEGIN: EBb5_EnergyBalanceEachYear.
ebb5_energybalanceeachyear::Array{AbstractConstraint, 1} = Array{AbstractConstraint, 1}()

t = Threads.@spawn(let
    local lastkeys = Array{String, 1}(undef,3)  # lastkeys[1] = r, lastkeys[2] = f, lastkeys[3] = y
    local lastvals = Array{Float64, 1}([0.0])  # lastvals[1] = aad
    local sumexps = Array{AffExpr, 1}([AffExpr()])  # sumexps[1] = vtradeannual sum

    for row in SQLite.DBInterface.execute(db, "select r.val as r, f.val as f, y.val as y, cast(aad.val as real) as aad,
        tr.r as tr_r, tr.rr as tr_rr, cast(tr.val as real) as trv
    from region r, fuel f, year y
    left join traderoute_def tr on (tr.r = r.val or tr.rr = r.val) and tr.f = f.val and tr.y = y.val and tr.r <> tr.rr and tr.val = 1
    left join AccumulatedAnnualDemand_def aad on aad.r = r.val and aad.f = f.val and aad.y = y.val
    left join TransmissionModelingEnabled tme on tme.r = r.val and tme.f = f.val and tme.y = y.val
    where tme.id is null $(restrictyears ? "and y.val in" * inyears : "")
    order by r.val, f.val, y.val")
        local r = row[:r]
        local f = row[:f]
        local y = row[:y]

        if isassigned(lastkeys, 1) && (r != lastkeys[1] || f != lastkeys[2] || y != lastkeys[3])
            # Create constraint
            # Inclusion of vdemandannualnn allows users to specify both timesliced and non-timesliced demands for a fuel
            push!(ebb5_energybalanceeachyear, @build_constraint(vproductionannualnn[lastkeys[1],lastkeys[2],lastkeys[3]] >=
                vdemandannualnn[lastkeys[1],lastkeys[2],lastkeys[3]] + vuseannualnn[lastkeys[1],lastkeys[2],lastkeys[3]] + sumexps[1] + lastvals[1]))
            sumexps[1] = AffExpr()
            lastvals[1] = 0.0
        end

        # To enable trade between regions, one row in TradeRoute with value = 1.0 should be specified
        # Query results limited to rows with value = 1.0
        if !ismissing(row[:trv])
            if row[:tr_r] == r
                add_to_expression!(sumexps[1], vtradeannual[r,row[:tr_rr],f,y])
            else
                add_to_expression!(sumexps[1], -vtradeannual[row[:tr_r],r,f,y])
            end
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
        push!(ebb5_energybalanceeachyear, @build_constraint(vproductionannualnn[lastkeys[1],lastkeys[2],lastkeys[3]] >=
            vdemandannualnn[lastkeys[1],lastkeys[2],lastkeys[3]] + vuseannualnn[lastkeys[1],lastkeys[2],lastkeys[3]] + sumexps[1] + lastvals[1]))
    end

    put!(cons_channel, ebb5_energybalanceeachyear)
end)

numconsarrays += 1
logmsg("Queued constraint EBb5_EnergyBalanceEachYear for creation.", quiet)
# END: EBb5_EnergyBalanceEachYear.

# BEGIN: EBb5Tr_EnergyBalanceEachYear.
# For nodal modeling, where there is no trade, this constraint accounts for AccumulatedAnnualDemand only.
if transmissionmodeling
    ebb5tr_energybalanceeachyear::Array{AbstractConstraint, 1} = Array{AbstractConstraint, 1}()

    t = Threads.@spawn(begin
        for row in SQLite.DBInterface.execute(db,
            "select ndd.n as n, ndd.f as f, ndd.y as y, cast(ndd.val as real) as ndd, cast(aad.val as real) as aad
            from NodalDistributionDemand_def ndd, NODE n, TransmissionModelingEnabled tme, AccumulatedAnnualDemand_def aad
            where
            ndd.n = n.val
            and tme.r = n.r and tme.f = ndd.f and tme.y = ndd.y
            and aad.r = n.r and aad.f = ndd.f and aad.y = ndd.y
            and aad.val > 0 $(restrictyears ? "and ndd.y in" * inyears : "")")
            local n = row[:n]
            local f = row[:f]
            local y = row[:y]

            push!(ebb5tr_energybalanceeachyear, @build_constraint(vproductionannualnodal[n,f,y] >=
                vdemandannualnodal[n,f,y] + vuseannualnodal[n,f,y] + vtransmissionannual[n,f,y] + row[:aad] * row[:ndd]))
        end

        put!(cons_channel, ebb5tr_energybalanceeachyear)
    end)

    numconsarrays += 1
    logmsg("Queued constraint EBb5Tr_EnergyBalanceEachYear for creation.", quiet)
end
# END: EBb5Tr_EnergyBalanceEachYear.

# BEGIN: Acc1_FuelProductionByTechnology.
if in("vproductionbytechnology", varstosavearr)
    acc1_fuelproductionbytechnology::Array{AbstractConstraint, 1} = Array{AbstractConstraint, 1}()

    t = Threads.@spawn(let
        for row in DataFrames.eachrow(queries["queryvrateofproductionbytechnologynn"])
            local r = row[:r]
            local l = row[:l]
            local t = row[:t]
            local f = row[:f]
            local y = row[:y]

            push!(acc1_fuelproductionbytechnology, @build_constraint(vrateofproductionbytechnologynn[r,l,t,f,y] * row[:ys] == vproductionbytechnology[r,l,t,f,y]))
        end

        if transmissionmodeling
            local lastkeys = Array{String, 1}(undef,5)  # lastkeys[1] = r, lastkeys[2] = l, lastkeys[3] = t, lastkeys[4] = f, lastkeys[5] = y
            local sumexps = Array{AffExpr, 1}([AffExpr()])  # sumexps[1] = vrateofproductionbytechnologynodal sum

            for row in DataFrames.eachrow(queries["queryvproductionbytechnologynodal"])
                local r = row[:r]
                local l = row[:l]
                local t = row[:t]
                local f = row[:f]
                local y = row[:y]

                if isassigned(lastkeys, 1) && (r != lastkeys[1] || l != lastkeys[2] || t != lastkeys[3] || f != lastkeys[4] || y != lastkeys[5])
                    # Create constraint
                    push!(acc1_fuelproductionbytechnology, @build_constraint(sumexps[1] ==
                        vproductionbytechnology[lastkeys[1],lastkeys[2],lastkeys[3],lastkeys[4],lastkeys[5]]))
                    sumexps[1] = AffExpr()
                end

                add_to_expression!(sumexps[1], vrateofproductionbytechnologynodal[row[:n],l,t,f,y] * row[:ys])

                lastkeys[1] = r
                lastkeys[2] = l
                lastkeys[3] = t
                lastkeys[4] = f
                lastkeys[5] = y
            end

            # Create last constraint
            if isassigned(lastkeys, 1)
                push!(acc1_fuelproductionbytechnology, @build_constraint(sumexps[1] ==
                    vproductionbytechnology[lastkeys[1],lastkeys[2],lastkeys[3],lastkeys[4],lastkeys[5]]))
            end
        end  # transmissionmodeling

        put!(cons_channel, acc1_fuelproductionbytechnology)
    end)

    numconsarrays += 1
    logmsg("Queued constraint Acc1_FuelProductionByTechnology for creation.", quiet)
end  # in("vproductionbytechnology", varstosavearr)
# END: Acc1_FuelProductionByTechnology.

# BEGIN: Acc2_FuelUseByTechnology.
if in("vusebytechnology", varstosavearr)
    acc2_fuelusebytechnology::Array{AbstractConstraint, 1} = Array{AbstractConstraint, 1}()

    t = Threads.@spawn(let
        for row in DataFrames.eachrow(queries["queryvrateofusebytechnologynn"])
            local r = row[:r]
            local l = row[:l]
            local t = row[:t]
            local f = row[:f]
            local y = row[:y]

            push!(acc2_fuelusebytechnology, @build_constraint(vrateofusebytechnologynn[r,l,t,f,y] * row[:ys] == vusebytechnology[r,l,t,f,y]))
        end

        if transmissionmodeling
            local lastkeys = Array{String, 1}(undef,5)  # lastkeys[1] = r, lastkeys[2] = l, lastkeys[3] = t, lastkeys[4] = f, lastkeys[5] = y
            local sumexps = Array{AffExpr, 1}([AffExpr()])  # sumexps[1] = vrateofusebytechnologynodal sum

            for row in DataFrames.eachrow(queries["queryvusebytechnologynodal"])
                local r = row[:r]
                local l = row[:l]
                local t = row[:t]
                local f = row[:f]
                local y = row[:y]

                if isassigned(lastkeys, 1) && (r != lastkeys[1] || l != lastkeys[2] || t != lastkeys[3] || f != lastkeys[4] || y != lastkeys[5])
                    # Create constraint
                    push!(acc2_fuelusebytechnology, @build_constraint(sumexps[1] ==
                        vusebytechnology[lastkeys[1],lastkeys[2],lastkeys[3],lastkeys[4],lastkeys[5]]))
                    sumexps[1] = AffExpr()
                end

                add_to_expression!(sumexps[1], vrateofusebytechnologynodal[row[:n],l,t,f,y] * row[:ys])

                lastkeys[1] = r
                lastkeys[2] = l
                lastkeys[3] = t
                lastkeys[4] = f
                lastkeys[5] = y
            end

            # Create last constraint
            if isassigned(lastkeys, 1)
                push!(acc2_fuelusebytechnology, @build_constraint(sumexps[1] ==
                    vusebytechnology[lastkeys[1],lastkeys[2],lastkeys[3],lastkeys[4],lastkeys[5]]))
            end
        end  # transmissionmodeling

        put!(cons_channel, acc2_fuelusebytechnology)
    end)

    numconsarrays += 1
    logmsg("Queued constraint Acc2_FuelUseByTechnology for creation.", quiet)
end  # in("vusebytechnology", varstosavearr)
# END: Acc2_FuelUseByTechnology.

# BEGIN: Acc3_AverageAnnualRateOfActivity.
acc3_averageannualrateofactivity::Array{AbstractConstraint, 1} = Array{AbstractConstraint, 1}()

t = Threads.@spawn(let
    local lastkeys = Array{String, 1}(undef,4)  # lastkeys[1] = r, lastkeys[2] = t, lastkeys[3] = m, lastkeys[4] = y
    local sumexps = Array{AffExpr, 1}([AffExpr()])  # sumexps[1] = vrateofactivity sum

    for row in SQLite.DBInterface.execute(db, "with ar as (select r, t, f, m, y from OutputActivityRatio_def
    where val <> 0
    union
    select r, t, f, m, y from InputActivityRatio_def
    where val <> 0)
    select r.val as r, t.val as t, m.val as m, y.val as y, ys.l as l, cast(ys.val as real) as ys
    from region r, technology t, mode_of_operation m, year y, YearSplit_def ys
    where ys.y = y.val
    and exists (select 1 from ar where ar.r = r.val and ar.t = t.val and ar.m = m.val and ar.y = y.val)
    $(restrictyears ? "and y.val in" * inyears : "")
    order by r.val, t.val, m.val, y.val")
        local r = row[:r]
        local t = row[:t]
        local m = row[:m]
        local y = row[:y]

        if isassigned(lastkeys, 1) && (r != lastkeys[1] || t != lastkeys[2] || m != lastkeys[3] || y != lastkeys[4])
            # Create constraint
            push!(acc3_averageannualrateofactivity, @build_constraint(sumexps[1] ==
                vtotalannualtechnologyactivitybymode[lastkeys[1],lastkeys[2],lastkeys[3],lastkeys[4]]))
            sumexps[1] = AffExpr()
        end

        add_to_expression!(sumexps[1], vrateofactivity[r,row[:l],t,m,y] * row[:ys])

        lastkeys[1] = r
        lastkeys[2] = t
        lastkeys[3] = m
        lastkeys[4] = y
    end

    # Create last constraint
    if isassigned(lastkeys, 1)
        push!(acc3_averageannualrateofactivity, @build_constraint(sumexps[1] ==
            vtotalannualtechnologyactivitybymode[lastkeys[1],lastkeys[2],lastkeys[3],lastkeys[4]]))
    end

    put!(cons_channel, acc3_averageannualrateofactivity)
end)

numconsarrays += 1
logmsg("Queued constraint Acc3_AverageAnnualRateOfActivity for creation.", quiet)
# END: Acc3_AverageAnnualRateOfActivity.

# BEGIN: Acc4_ModelPeriodCostByRegion.
if in("vmodelperiodcostbyregion", varstosavearr)
    acc4_modelperiodcostbyregion::Array{AbstractConstraint, 1} = Array{AbstractConstraint, 1}()

    t = Threads.@spawn(begin
        for r in sregion
            push!(acc4_modelperiodcostbyregion, @build_constraint(sum([vtotaldiscountedcost[r,y] for y in syear]) == vmodelperiodcostbyregion[r]))
        end

        put!(cons_channel, acc4_modelperiodcostbyregion)
    end)

    numconsarrays += 1
    logmsg("Queued constraint Acc4_ModelPeriodCostByRegion for creation.", quiet)
end
# END: Acc4_ModelPeriodCostByRegion.

# BEGIN: NS1_RateOfStorageCharge.
# vrateofstoragechargenn is in terms of energy output/year (e.g., PJ/yr, depending on CapacityToActivityUnit)
ns1_rateofstoragecharge::Array{AbstractConstraint, 1} = Array{AbstractConstraint, 1}()

t = Threads.@spawn(let
    local lastkeys = Array{String, 1}(undef,4)  # lastkeys[1] = r, lastkeys[2] = s, lastkeys[3] = l, lastkeys[4] = y
    local sumexps = Array{AffExpr, 1}([AffExpr()])  # sumexps[1] = vrateofactivity sum

    for row in SQLite.DBInterface.execute(db, "with ar as (select r, t, m, y from OutputActivityRatio_def
    where val <> 0
    union
    select r, t, m, y from InputActivityRatio_def
    where val <> 0)
    select r.val as r, s.val as s, l.val as l, y.val as y, tts.m as m, tts.t as t
    from region r, storage s, TIMESLICE l, year y, TechnologyToStorage_def tts, ar
    left join nodalstorage ns on ns.r = r.val and ns.s = s.val and ns.y = y.val
    where
    tts.r = r.val and tts.s = s.val and tts.val = 1
    and ns.r is null
    and ar.r = r.val and ar.t = tts.t and ar.m = tts.m and ar.y = y.val
    $(restrictyears ? "and y.val in" * inyears : "")
    order by r.val, s.val, l.val, y.val")
        local r = row[:r]
        local s = row[:s]
        local l = row[:l]
        local y = row[:y]

        if isassigned(lastkeys, 1) && (r != lastkeys[1] || s != lastkeys[2] || l != lastkeys[3] || y != lastkeys[4])
            # Create constraint
            push!(ns1_rateofstoragecharge, @build_constraint(sumexps[1] ==
                vrateofstoragechargenn[lastkeys[1],lastkeys[2],lastkeys[3],lastkeys[4]]))
            sumexps[1] = AffExpr()
        end

        add_to_expression!(sumexps[1], vrateofactivity[r,l,row[:t],row[:m],y])

        lastkeys[1] = r
        lastkeys[2] = s
        lastkeys[3] = l
        lastkeys[4] = y
    end

    # Create last constraint
    if isassigned(lastkeys, 1)
        push!(ns1_rateofstoragecharge, @build_constraint(sumexps[1] ==
            vrateofstoragechargenn[lastkeys[1],lastkeys[2],lastkeys[3],lastkeys[4]]))
    end

    put!(cons_channel, ns1_rateofstoragecharge)
end)

numconsarrays += 1
logmsg("Queued constraint NS1_RateOfStorageCharge for creation.", quiet)
# END: NS1_RateOfStorageCharge.

# BEGIN: NS1Tr_RateOfStorageCharge.
# vrateofstoragechargenodal is in terms of energy output/year (e.g., PJ/yr, depending on CapacityToActivityUnit)
if transmissionmodeling
    ns1tr_rateofstoragecharge::Array{AbstractConstraint, 1} = Array{AbstractConstraint, 1}()

    t = Threads.@spawn(let
        local lastkeys = Array{String, 1}(undef,4)  # lastkeys[1] = n, lastkeys[2] = s, lastkeys[3] = l, lastkeys[4] = y
        local sumexps = Array{AffExpr, 1}([AffExpr()])  # sumexps[1] = vrateofactivitynodal sum

        for row in SQLite.DBInterface.execute(db, "select ns.n as n, ns.s as s, l.val as l, ns.y as y, tts.m as m, tts.t as t
            from nodalstorage ns, TIMESLICE l, TechnologyToStorage_def tts,
        	NodalDistributionTechnologyCapacity_def ntc, TransmissionModelingEnabled tme,
        	(select r, t, f, m, y from OutputActivityRatio_def
            where val <> 0
            union
            select r, t, f, m, y from InputActivityRatio_def
            where val <> 0) ar
        where
        tts.r = ns.r and tts.s = ns.s and tts.val = 1
        and ntc.n = ns.n and ntc.t = tts.t and ntc.y = ns.y and ntc.val > 0
        and tme.r = ns.r and tme.f = ar.f and tme.y = ns.y
        and ar.r = ns.r and ar.t = tts.t and ar.m = tts.m and ar.y = ns.y
        $(restrictyears ? "and ns.y in" * inyears : "")
        order by ns.n, ns.s, l.val, ns.y")
            local n = row[:n]
            local s = row[:s]
            local l = row[:l]
            local y = row[:y]

            if isassigned(lastkeys, 1) && (n != lastkeys[1] || s != lastkeys[2] || l != lastkeys[3] || y != lastkeys[4])
                # Create constraint
                push!(ns1tr_rateofstoragecharge, @build_constraint(sumexps[1] ==
                    vrateofstoragechargenodal[lastkeys[1],lastkeys[2],lastkeys[3],lastkeys[4]]))
                sumexps[1] = AffExpr()
            end

            add_to_expression!(sumexps[1], vrateofactivitynodal[n,l,row[:t],row[:m],y])

            lastkeys[1] = n
            lastkeys[2] = s
            lastkeys[3] = l
            lastkeys[4] = y
        end

        # Create last constraint
        if isassigned(lastkeys, 1)
            push!(ns1tr_rateofstoragecharge, @build_constraint(sumexps[1] ==
                vrateofstoragechargenodal[lastkeys[1],lastkeys[2],lastkeys[3],lastkeys[4]]))
        end

        put!(cons_channel, ns1tr_rateofstoragecharge)
    end)

    numconsarrays += 1
    logmsg("Queued constraint NS1Tr_RateOfStorageCharge for creation.", quiet)
end
# END: NS1Tr_RateOfStorageCharge.

# BEGIN: NS2_RateOfStorageDischarge.
# vrateofstoragedischargenn is in terms of energy output/year (e.g., PJ/yr, depending on CapacityToActivityUnit)
ns2_rateofstoragedischarge::Array{AbstractConstraint, 1} = Array{AbstractConstraint, 1}()

t = Threads.@spawn(let
    local lastkeys = Array{String, 1}(undef,4)  # lastkeys[1] = r, lastkeys[2] = s, lastkeys[3] = l, lastkeys[4] = y
    local sumexps = Array{AffExpr, 1}([AffExpr()])  # sumexps[1] = vrateofactivity sum

    for row in SQLite.DBInterface.execute(db, "with ar as (select r, t, m, y from OutputActivityRatio_def
    where val <> 0
    union
    select r, t, m, y from InputActivityRatio_def
    where val <> 0)
    select r.val as r, s.val as s, l.val as l, y.val as y, tfs.m as m, tfs.t as t
    from region r, storage s, TIMESLICE l, year y, TechnologyFromStorage_def tfs, ar
    left join nodalstorage ns on ns.r = r.val and ns.s = s.val and ns.y = y.val
    where
    tfs.r = r.val and tfs.s = s.val and tfs.val = 1
    and ns.r is null
    and ar.r = r.val and ar.t = tfs.t and ar.m = tfs.m and ar.y = y.val
    $(restrictyears ? "and y.val in" * inyears : "")
    order by r.val, s.val, l.val, y.val")
        local r = row[:r]
        local s = row[:s]
        local l = row[:l]
        local y = row[:y]

        if isassigned(lastkeys, 1) && (r != lastkeys[1] || s != lastkeys[2] || l != lastkeys[3] || y != lastkeys[4])
            # Create constraint
            push!(ns2_rateofstoragedischarge, @build_constraint(sumexps[1] ==
                vrateofstoragedischargenn[lastkeys[1],lastkeys[2],lastkeys[3],lastkeys[4]]))
            sumexps[1] = AffExpr()
        end

        add_to_expression!(sumexps[1], vrateofactivity[r,l,row[:t],row[:m],y])

        lastkeys[1] = r
        lastkeys[2] = s
        lastkeys[3] = l
        lastkeys[4] = y
    end

    # Create last constraint
    if isassigned(lastkeys, 1)
        push!(ns2_rateofstoragedischarge, @build_constraint(sumexps[1] ==
            vrateofstoragedischargenn[lastkeys[1],lastkeys[2],lastkeys[3],lastkeys[4]]))
    end

    put!(cons_channel, ns2_rateofstoragedischarge)
end)

numconsarrays += 1
logmsg("Queued constraint NS2_RateOfStorageDischarge for creation.", quiet)
# END: NS2_RateOfStorageDischarge.

# BEGIN: NS2Tr_RateOfStorageDischarge.
# vrateofstoragedischargenodal is in terms of energy output/year (e.g., PJ/yr, depending on CapacityToActivityUnit)
if transmissionmodeling
    ns2tr_rateofstoragedischarge::Array{AbstractConstraint, 1} = Array{AbstractConstraint, 1}()

    t = Threads.@spawn(let
        local lastkeys = Array{String, 1}(undef,4)  # lastkeys[1] = n, lastkeys[2] = s, lastkeys[3] = l, lastkeys[4] = y
        local sumexps = Array{AffExpr, 1}([AffExpr()])  # sumexps[1] = vrateofactivitynodal sum

        for row in SQLite.DBInterface.execute(db, "select ns.n as n, ns.s as s, l.val as l, ns.y as y, tfs.m as m, tfs.t as t
            from nodalstorage ns, TIMESLICE l, TechnologyFromStorage_def tfs,
        	NodalDistributionTechnologyCapacity_def ntc, TransmissionModelingEnabled tme,
        	(select r, t, f, m, y from OutputActivityRatio_def
            where val <> 0
            union
            select r, t, f, m, y from InputActivityRatio_def
            where val <> 0) ar
        where
        tfs.r = ns.r and tfs.s = ns.s and tfs.val = 1
        and ntc.n = ns.n and ntc.t = tfs.t and ntc.y = ns.y and ntc.val > 0
        and tme.r = ns.r and tme.f = ar.f and tme.y = ns.y
        and ar.r = ns.r and ar.t = tfs.t and ar.m = tfs.m and ar.y = ns.y
        $(restrictyears ? "and ns.y in" * inyears : "")
        order by ns.n, ns.s, l.val, ns.y")
            local n = row[:n]
            local s = row[:s]
            local l = row[:l]
            local y = row[:y]

            if isassigned(lastkeys, 1) && (n != lastkeys[1] || s != lastkeys[2] || l != lastkeys[3] || y != lastkeys[4])
                # Create constraint
                push!(ns2tr_rateofstoragedischarge, @build_constraint(sumexps[1] ==
                    vrateofstoragedischargenodal[lastkeys[1],lastkeys[2],lastkeys[3],lastkeys[4]]))
                sumexps[1] = AffExpr()
            end

            add_to_expression!(sumexps[1], vrateofactivitynodal[n,l,row[:t],row[:m],y])

            lastkeys[1] = n
            lastkeys[2] = s
            lastkeys[3] = l
            lastkeys[4] = y
        end

        # Create last constraint
        if isassigned(lastkeys, 1)
            push!(ns2tr_rateofstoragedischarge, @build_constraint(sumexps[1] ==
                vrateofstoragedischargenodal[lastkeys[1],lastkeys[2],lastkeys[3],lastkeys[4]]))
        end

        put!(cons_channel, ns2tr_rateofstoragedischarge)
    end)

    numconsarrays += 1
    logmsg("Queued constraint NS2Tr_RateOfStorageDischarge for creation.", quiet)
end
# END: NS2Tr_RateOfStorageDischarge.

# BEGIN: NS3_StorageLevelTsGroup1Start, NS4_StorageLevelTsGroup2Start, NS5_StorageLevelTimesliceEnd.
# Note that vstorageleveltsendnn represents storage level (in energy terms) at end of first hour in time slice
ns3_storageleveltsgroup1start::Array{AbstractConstraint, 1} = Array{AbstractConstraint, 1}()
ns4_storageleveltsgroup2start::Array{AbstractConstraint, 1} = Array{AbstractConstraint, 1}()
ns5_storageleveltimesliceend::Array{AbstractConstraint, 1} = Array{AbstractConstraint, 1}()

t = Threads.@spawn(begin
    for row in SQLite.DBInterface.execute(db, "select r.val as r, s.val as s, ltg.l as l, y.val as y, ltg.lorder as lo,
        ltg.tg2 as tg2, tg2.[order] as tg2o, ltg.tg1 as tg1, tg1.[order] as tg1o, cast(se.sls as real) as sls,
        cast(msc.val as real) as msc, cast(rsc.delta as real) as rsc_delta
    from REGION r, STORAGE s, YEAR y, LTsGroup ltg, TSGROUP2 tg2, TSGROUP1 tg1
    left join (select sls.r as r, sls.s as s, sls.val * rsc.val as sls
    from StorageLevelStart_def sls, ResidualStorageCapacity_def rsc
    where sls.r = rsc.r and sls.s = rsc.s and rsc.y = " * first(syear) * ") se on se.r = r.val and se.s = s.val
    left join nodalstorage ns on ns.r = r.val and ns.s = s.val and ns.y = y.val
    left join MinStorageCharge_def msc on msc.r = r.val and msc.s = s.val and msc.y = y.val
    left join (select r, s, y, val - lag(val) over (partition by r, s order by y) as delta
        from ResidualStorageCapacity_def $(restrictyears ? "where y in" * inyears : "")) rsc
        on rsc.r = r.val and rsc.s = s.val and rsc.y = y.val
    where
    ltg.tg2 = tg2.name
    and ltg.tg1 = tg1.name
    and ns.r is null
    $(restrictyears ? "and y.val in" * inyears : "")")
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
            # New endogenous storage capacity is assumed to be delivered with minimum charge
            startlevel = (ismissing(row[:sls]) ? 0 : row[:sls]) + (ismissing(row[:msc]) ? 0 : row[:msc] * vnewstoragecapacity[r,s,y])
            addns3 = true
            addns4 = true
        elseif tg1o == 1 && tg2o == 1 && lo == 1
            # No carryover of energy for non-contiguous years
            startlevel = (!restrictyears || Meta.parse(y)-1 in calcyears ? vstoragelevelyearendnn[r, s, string(Meta.parse(y)-1)] : 0)

            # New endogenous and exogenous storage capacity is assumed to be delivered with minimum charge
            # If exogenous capacity is retired, any charge is assumed to be transferred to other capacity existing at start of year; or lost if no capacity exists
            if !ismissing(row[:msc])
                startlevel += row[:msc] * vnewstoragecapacity[r,s,y]

                if !ismissing(row[:rsc_delta]) && row[:rsc_delta] > 0
                    startlevel += row[:msc] * row[:rsc_delta]
                end
            end

            addns3 = true
            addns4 = true
        elseif tg2o == 1 && lo == 1
            startlevel = vstorageleveltsgroup1endnn[r, s, tsgroup1dict[tg1o-1][1], y]
            addns3 = true
            addns4 = true
        elseif lo == 1
            startlevel = vstorageleveltsgroup2endnn[r, s, tg1, tsgroup2dict[tg2o-1][1], y]
            addns4 = true
        else
            startlevel = vstorageleveltsendnn[r, s, ltsgroupdict[(tg1o, tg2o, lo-1)], y]
        end

        if addns3
            push!(ns3_storageleveltsgroup1start, @build_constraint(startlevel == vstorageleveltsgroup1startnn[r, s, tg1, y]))
        end

        if addns4
            push!(ns4_storageleveltsgroup2start, @build_constraint(startlevel == vstorageleveltsgroup2startnn[r, s, tg1, tg2, y]))
        end

        push!(ns5_storageleveltimesliceend, @build_constraint(startlevel + (vrateofstoragechargenn[r, s, l, y] - vrateofstoragedischargenn[r, s, l, y]) / 8760 == vstorageleveltsendnn[r, s, l, y]))
    end

    put!(cons_channel, ns3_storageleveltsgroup1start)
    put!(cons_channel, ns4_storageleveltsgroup2start)
    put!(cons_channel, ns5_storageleveltimesliceend)
end)

numconsarrays += 3
logmsg("Queued constraint NS3_StorageLevelTsGroup1Start for creation.", quiet)
logmsg("Queued constraint NS4_StorageLevelTsGroup2Start for creation.", quiet)
logmsg("Queued constraint NS5_StorageLevelTimesliceEnd for creation.", quiet)
# END: NS3_StorageLevelTsGroup1Start, NS4_StorageLevelTsGroup2Start, NS5_StorageLevelTimesliceEnd.

# BEGIN: NS3Tr_StorageLevelTsGroup1Start, NS4Tr_StorageLevelTsGroup2Start, NS5Tr_StorageLevelTimesliceEnd.
# Note that vstorageleveltsendnodal represents storage level (in energy terms) at end of first hour in time slice
if transmissionmodeling
    ns3tr_storageleveltsgroup1start::Array{AbstractConstraint, 1} = Array{AbstractConstraint, 1}()
    ns4tr_storageleveltsgroup2start::Array{AbstractConstraint, 1} = Array{AbstractConstraint, 1}()
    ns5tr_storageleveltimesliceend::Array{AbstractConstraint, 1} = Array{AbstractConstraint, 1}()

    t = Threads.@spawn(begin
        # Note that this query distributes StorageLevelStart, MinStorageCharge, and ResidualStorageCapacity according to NodalDistributionStorageCapacity
        for row in SQLite.DBInterface.execute(db, "select ns.r as r, ns.n as n, ns.s as s, ltg.l as l, ns.y as y, ltg.lorder as lo,
            ltg.tg2 as tg2, tg2.[order] as tg2o, ltg.tg1 as tg1, tg1.[order] as tg1o,
        	cast(se.sls * ns.val as real) as sls, cast(msc.val * ns.val as real) as msc, cast(rsc.delta as real) as rsc_delta
        from nodalstorage ns, LTsGroup ltg, TSGROUP2 tg2, TSGROUP1 tg1
    	left join (select sls.r as r, sls.s as s, sls.val * rsc.val as sls
    		from StorageLevelStart_def sls, ResidualStorageCapacity_def rsc
    		where sls.r = rsc.r and sls.s = rsc.s and rsc.y = " * first(syear) * ") se on se.r = ns.r and se.s = ns.s
        left join MinStorageCharge_def msc on msc.r = ns.r and msc.s = ns.s and msc.y = ns.y
        left join (select r, s, y, val - lag(val) over (partition by r, s order by y) as delta
            from ResidualStorageCapacity_def $(restrictyears ? "where y in" * inyears : "")) rsc
            on rsc.r = ns.r and rsc.s = ns.s and rsc.y = ns.y
        where
        ltg.tg2 = tg2.name
        and ltg.tg1 = tg1.name
        $(restrictyears ? "and ns.y in" * inyears : "")")
            local r = row[:r]
            local n = row[:n]
            local s = row[:s]
            local l = row[:l]
            local y = row[:y]
            local tg1 = row[:tg1]
            local tg2 = row[:tg2]
            local lo = row[:lo]
            local tg2o = row[:tg2o]
            local tg1o = row[:tg1o]
            local startlevel  # Storage level at beginning of first hour in time slice
            local addns3::Bool = false  # Indicates whether to add to constraint ns3tr
            local addns4::Bool = false  #  Indicates whether to add to constraint ns4tr

            if y == first(syear) && tg1o == 1 && tg2o == 1 && lo == 1
                # New endogenous storage capacity is assumed to be delivered with minimum charge
                startlevel = (ismissing(row[:sls]) ? 0 : row[:sls]) + (ismissing(row[:msc]) ? 0 : row[:msc] * vnewstoragecapacity[r,s,y])
                addns3 = true
                addns4 = true
            elseif tg1o == 1 && tg2o == 1 && lo == 1
                # No carryover of energy for non-contiguous years
                startlevel = (!restrictyears || Meta.parse(y)-1 in calcyears ? vstoragelevelyearendnodal[n, s, string(Meta.parse(y)-1)] : 0)

                # New endogenous and exogenous storage capacity is assumed to be delivered with minimum charge
                # If exogenous capacity is retired, any charge is assumed to be transferred to other capacity existing at start of year; or lost if no capacity exists
                if !ismissing(row[:msc])
                    startlevel += row[:msc] * vnewstoragecapacity[r,s,y]

                    if !ismissing(row[:rsc_delta]) && row[:rsc_delta] > 0
                        startlevel += row[:msc] * row[:rsc_delta]
                    end
                end

                addns3 = true
                addns4 = true
            elseif tg2o == 1 && lo == 1
                startlevel = vstorageleveltsgroup1endnodal[n, s, tsgroup1dict[tg1o-1][1], y]
                addns3 = true
                addns4 = true
            elseif lo == 1
                startlevel = vstorageleveltsgroup2endnodal[n, s, tg1, tsgroup2dict[tg2o-1][1], y]
                addns4 = true
            else
                startlevel = vstorageleveltsendnodal[n, s, ltsgroupdict[(tg1o, tg2o, lo-1)], y]
            end

            if addns3
                push!(ns3tr_storageleveltsgroup1start, @build_constraint(startlevel == vstorageleveltsgroup1startnodal[n, s, tg1, y]))
            end

            if addns4
                push!(ns4tr_storageleveltsgroup2start, @build_constraint(startlevel == vstorageleveltsgroup2startnodal[n, s, tg1, tg2, y]))
            end

            push!(ns5tr_storageleveltimesliceend, @build_constraint(startlevel + (vrateofstoragechargenodal[n, s, l, y] - vrateofstoragedischargenodal[n, s, l, y]) / 8760 == vstorageleveltsendnodal[n, s, l, y]))
        end

        put!(cons_channel, ns3tr_storageleveltsgroup1start)
        put!(cons_channel, ns4tr_storageleveltsgroup2start)
        put!(cons_channel, ns5tr_storageleveltimesliceend)
    end)

    numconsarrays += 3
    logmsg("Queued constraint NS3Tr_StorageLevelTsGroup1Start for creation.", quiet)
    logmsg("Queued constraint NS4Tr_StorageLevelTsGroup2Start for creation.", quiet)
    logmsg("Queued constraint NS5Tr_StorageLevelTimesliceEnd for creation.", quiet)
end
# END: NS3Tr_StorageLevelTsGroup1Start, NS4Tr_StorageLevelTsGroup2Start, NS5Tr_StorageLevelTimesliceEnd.

# BEGIN: NS6_StorageLevelTsGroup2End and NS6a_StorageLevelTsGroup2NetZero.
ns6_storageleveltsgroup2end::Array{AbstractConstraint, 1} = Array{AbstractConstraint, 1}()
ns6a_storageleveltsgroup2netzero::Array{AbstractConstraint, 1} = Array{AbstractConstraint, 1}()

t = Threads.@spawn(begin
    for row in SQLite.DBInterface.execute(db, "select main.r, main.s, main.tg2nz, main.tg1, main.tg1o, main.tg2, main.tg2o, cast(main.tg2m as real) as tg2m,
        main.y, ltg2.l as maxl, main.maxlo
    from
    (select r.val as r, s.val as s, s.netzerotg2 as tg2nz, tg1.name as tg1, tg1.[order] as tg1o, tg2.name as tg2, tg2.[order] as tg2o, tg2.multiplier as tg2m,
    y.val as y, max(ltg.lorder) as maxlo
    from REGION r, STORAGE s, TSGROUP1 tg1, TSGROUP2 tg2, YEAR as y, LTsGroup ltg
    where
    tg1.name = ltg.tg1
    and tg2.name = ltg.tg2 $(restrictyears ? "and y.val in" * inyears : "")
    group by r.val, s.val, s.netzerotg2, tg1.name, tg1.[order], tg2.name, tg2.[order], tg2.multiplier, y.val) main, LTsGroup ltg2
    left join nodalstorage ns on ns.r = main.r and ns.s = main.s and ns.y = main.y
    where
    ltg2.tg1 = main.tg1
    and ltg2.tg2 = main.tg2
    and ltg2.lorder = main.maxlo
    and ns.r is null")
        local r = row[:r]
        local s = row[:s]
        local tg2nz = row[:tg2nz]  # 1 = tg2 end level must = tg2 start level
        local tg1 = row[:tg1]
        local tg2 = row[:tg2]
        local y = row[:y]

        push!(ns6_storageleveltsgroup2end, @build_constraint(vstorageleveltsgroup2startnn[r, s, tg1, tg2, y] +
            (vstorageleveltsendnn[r, s, row[:maxl], y] - vstorageleveltsgroup2startnn[r, s, tg1, tg2, y]) * row[:tg2m]
            == vstorageleveltsgroup2endnn[r, s, tg1, tg2, y]))

        if tg2nz == 1
            push!(ns6a_storageleveltsgroup2netzero, @build_constraint(vstorageleveltsgroup2startnn[r, s, tg1, tg2, y]
                == vstorageleveltsgroup2endnn[r, s, tg1, tg2, y]))
        end
    end

    put!(cons_channel, ns6_storageleveltsgroup2end)
    put!(cons_channel, ns6a_storageleveltsgroup2netzero)
end)

numconsarrays += 2
logmsg("Queued constraint NS6_StorageLevelTsGroup2End for creation.", quiet)
logmsg("Queued constraint NS6a_StorageLevelTsGroup2NetZero for creation.", quiet)
# END: NS6_StorageLevelTsGroup2End and NS6a_StorageLevelTsGroup2NetZero.

# BEGIN: NS6Tr_StorageLevelTsGroup2End and NS6aTr_StorageLevelTsGroup2NetZero.
if transmissionmodeling
    ns6tr_storageleveltsgroup2end::Array{AbstractConstraint, 1} = Array{AbstractConstraint, 1}()
    ns6atr_storageleveltsgroup2netzero::Array{AbstractConstraint, 1} = Array{AbstractConstraint, 1}()

    t = Threads.@spawn(begin
        for row in SQLite.DBInterface.execute(db, "select main.n, main.s, main.tg2nz, main.tg1, main.tg1o, main.tg2, main.tg2o, cast(main.tg2m as real) as tg2m,
            main.y, ltg2.l as maxl, main.maxlo
        from
        (select ns.n as n, ns.s as s, s.netzerotg2 as tg2nz, tg1.name as tg1, tg1.[order] as tg1o, tg2.name as tg2, tg2.[order] as tg2o,
        tg2.multiplier as tg2m, ns.y as y, max(ltg.lorder) as maxlo
        from nodalstorage ns, STORAGE s, TSGROUP1 tg1, TSGROUP2 tg2, LTsGroup ltg
        where
        ns.s = s.val
        and tg1.name = ltg.tg1
        and tg2.name = ltg.tg2 $(restrictyears ? "and ns.y in" * inyears : "")
        group by ns.n, ns.s, s.netzerotg2, tg1.name, tg1.[order], tg2.name, tg2.[order], tg2.multiplier, ns.y) main, LTsGroup ltg2
        where
        ltg2.tg1 = main.tg1
        and ltg2.tg2 = main.tg2
        and ltg2.lorder = main.maxlo")
            local n = row[:n]
            local s = row[:s]
            local tg2nz = row[:tg2nz]  # 1 = tg2 end level must = tg2 start level
            local tg1 = row[:tg1]
            local tg2 = row[:tg2]
            local y = row[:y]

            push!(ns6tr_storageleveltsgroup2end, @build_constraint(vstorageleveltsgroup2startnodal[n, s, tg1, tg2, y] +
                (vstorageleveltsendnodal[n, s, row[:maxl], y] - vstorageleveltsgroup2startnodal[n, s, tg1, tg2, y]) * row[:tg2m]
                == vstorageleveltsgroup2endnodal[n, s, tg1, tg2, y]))

            if tg2nz == 1
                push!(ns6atr_storageleveltsgroup2netzero, @build_constraint(vstorageleveltsgroup2startnodal[n, s, tg1, tg2, y]
                    == vstorageleveltsgroup2endnodal[n, s, tg1, tg2, y]))
            end
        end

        put!(cons_channel, ns6tr_storageleveltsgroup2end)
        put!(cons_channel, ns6atr_storageleveltsgroup2netzero)
    end)

    numconsarrays += 2
    logmsg("Queued constraint NS6Tr_StorageLevelTsGroup2End for creation.", quiet)
    logmsg("Queued constraint NS6aTr_StorageLevelTsGroup2NetZero for creation.", quiet)
end
# END: NS6Tr_StorageLevelTsGroup2End and NS6aTr_StorageLevelTsGroup2NetZero.

# BEGIN: NS7_StorageLevelTsGroup1End and NS7a_StorageLevelTsGroup1NetZero.
ns7_storageleveltsgroup1end::Array{AbstractConstraint, 1} = Array{AbstractConstraint, 1}()
ns7a_storageleveltsgroup1netzero::Array{AbstractConstraint, 1} = Array{AbstractConstraint, 1}()

t = Threads.@spawn(begin
    for row in SQLite.DBInterface.execute(db, "select r.val as r, s.val as s,
    	case s.netzerotg2 when 1 then 0 else s.netzerotg1 end as tg1nz,
    	tg1.name as tg1, tg1.[order] as tg1o, cast(tg1.multiplier as real) as tg1m,
        y.val as y, max(tg2.[order]) as maxtg2o
    from REGION r, STORAGE s, TSGROUP1 tg1, YEAR as y, LTsGroup ltg, TSGROUP2 tg2
    left join nodalstorage ns on ns.r = r.val and ns.s = s.val and ns.y = y.val
    where
    tg1.name = ltg.tg1
    and ltg.tg2 = tg2.name
    and ns.r is null
    $(restrictyears ? "and y.val in" * inyears : "")
    group by r.val, s.val, tg1.name, tg1.[order], tg1.multiplier, y.val")
        local r = row[:r]
        local s = row[:s]
        local tg1nz = row[:tg1nz]  # 1 = tg1 end level must = tg1 start level (zeroed out when tg2 net zero is activated as tg1 check isn't necessary)
        local tg1 = row[:tg1]
        local y = row[:y]

        push!(ns7_storageleveltsgroup1end, @build_constraint(vstorageleveltsgroup1startnn[r, s, tg1, y] +
            (vstorageleveltsgroup2endnn[r, s, tg1, tsgroup2dict[row[:maxtg2o]][1], y] - vstorageleveltsgroup1startnn[r, s, tg1, y]) * row[:tg1m]
            == vstorageleveltsgroup1endnn[r, s, tg1, y]))

        if tg1nz == 1
            push!(ns7a_storageleveltsgroup1netzero, @build_constraint(vstorageleveltsgroup1startnn[r, s, tg1, y]
                == vstorageleveltsgroup1endnn[r, s, tg1, y]))
        end
    end

    put!(cons_channel, ns7_storageleveltsgroup1end)
    put!(cons_channel, ns7a_storageleveltsgroup1netzero)
end)

numconsarrays += 2
logmsg("Queued constraint NS7_StorageLevelTsGroup1End for creation.", quiet)
logmsg("Queued constraint NS7a_StorageLevelTsGroup1NetZero for creation.", quiet)
# END: NS7_StorageLevelTsGroup1End and NS7a_StorageLevelTsGroup1NetZero.

# BEGIN: NS7Tr_StorageLevelTsGroup1End and NS7aTr_StorageLevelTsGroup1NetZero.
if transmissionmodeling
    ns7tr_storageleveltsgroup1end::Array{AbstractConstraint, 1} = Array{AbstractConstraint, 1}()
    ns7atr_storageleveltsgroup1netzero::Array{AbstractConstraint, 1} = Array{AbstractConstraint, 1}()

    t = Threads.@spawn(begin
        for row in SQLite.DBInterface.execute(db, "select ns.n as n, ns.s as s,
            	case s.netzerotg2 when 1 then 0 else s.netzerotg1 end as tg1nz,
            	tg1.name as tg1, tg1.[order] as tg1o, cast(tg1.multiplier as real) as tg1m,
                ns.y as y, max(tg2.[order]) as maxtg2o
            from nodalstorage ns, STORAGE s, TSGROUP1 tg1, LTsGroup ltg, TSGROUP2 tg2
        where
        ns.s = s.val
        and tg1.name = ltg.tg1
        and ltg.tg2 = tg2.name
        $(restrictyears ? "and ns.y in" * inyears : "")
        group by ns.n, ns.s, tg1.name, tg1.[order], tg1.multiplier, ns.y")
            local n = row[:n]
            local s = row[:s]
            local tg1nz = row[:tg1nz]  # 1 = tg1 end level must = tg1 start level (zeroed out when tg2 net zero is activated as tg1 check isn't necessary)
            local tg1 = row[:tg1]
            local y = row[:y]

            push!(ns7tr_storageleveltsgroup1end, @build_constraint(vstorageleveltsgroup1startnodal[n, s, tg1, y] +
                (vstorageleveltsgroup2endnodal[n, s, tg1, tsgroup2dict[row[:maxtg2o]][1], y] - vstorageleveltsgroup1startnodal[n, s, tg1, y]) * row[:tg1m]
                == vstorageleveltsgroup1endnodal[n, s, tg1, y]))

            if tg1nz == 1
                push!(ns7atr_storageleveltsgroup1netzero, @build_constraint(vstorageleveltsgroup1startnodal[n, s, tg1, y]
                    == vstorageleveltsgroup1endnodal[n, s, tg1, y]))
            end
        end

        put!(cons_channel, ns7tr_storageleveltsgroup1end)
        put!(cons_channel, ns7atr_storageleveltsgroup1netzero)
    end)

    numconsarrays += 2
    logmsg("Queued constraint NS7Tr_StorageLevelTsGroup1End for creation.", quiet)
    logmsg("Queued constraint NS7aTr_StorageLevelTsGroup1NetZero for creation.", quiet)
end
# END: NS7Tr_StorageLevelTsGroup1End and NS7aTr_StorageLevelTsGroup1NetZero.

# BEGIN: NS8_StorageLevelYearEnd and NS8a_StorageLevelYearEndNetZero.
ns8_storagelevelyearend::Array{AbstractConstraint, 1} = Array{AbstractConstraint, 1}()
ns8a_storagelevelyearendnetzero::Array{AbstractConstraint, 1} = Array{AbstractConstraint, 1}()

t = Threads.@spawn(let
    local lastkeys = Array{String, 1}(undef,3)  # lastkeys[1] = r, lastkeys[2] = s, lastkeys[3] = y
    local lastvals = Array{Float64, 1}([0.0, 0.0, 0.0])  # lastvals[1] = sls, lastvals[2] = msc, lastvals[3] = rsc_delta
    local lastvalsint = Array{Int64, 1}(undef,1)  # lastvalsint[1] = ynz
    local sumexps = Array{AffExpr, 1}([AffExpr()])  # sumexps[1] = vrateofstoragechargenn and vrateofstoragedischargenn sum

    for row in SQLite.DBInterface.execute(db, "select r.val as r, s.val as s,
    case s.netzerotg2 when 1 then 0 else case s.netzerotg1 when 1 then 0 else s.netzeroyear end end as ynz,
    y.val as y, ys.l as l, cast(ys.val as real) as ys,
    cast(se.sls as real) as sls, cast(msc.val as real) as msc, cast(rsc.delta as real) as rsc_delta
    from REGION r, STORAGE s, YEAR as y, YearSplit_def ys
    left join (select sls.r as r, sls.s as s, sls.val * rsc.val as sls
    from StorageLevelStart_def sls, ResidualStorageCapacity_def rsc
    where sls.r = rsc.r and sls.s = rsc.s and rsc.y = " * first(syear) * ") se on se.r = r.val and se.s = s.val
    left join nodalstorage ns on ns.r = r.val and ns.s = s.val and ns.y = y.val
    left join MinStorageCharge_def msc on msc.r = r.val and msc.s = s.val and msc.y = y.val
    left join (select r, s, y, val - lag(val) over (partition by r, s order by y) as delta
        from ResidualStorageCapacity_def $(restrictyears ? "where y in" * inyears : "")) rsc on rsc.r = r.val and rsc.s = s.val and rsc.y = y.val
    where y.val = ys.y
    and ns.r is null
    $(restrictyears ? "and y.val in" * inyears : "")
    order by r.val, s.val, y.val")
        local r = row[:r]
        local s = row[:s]
        local ynz = row[:ynz]  # 1 = year end level must = year start level (zeroed out when tg2 net zero or tg1 net zero is activated as year check isn't necessary)
        local y = row[:y]

        if isassigned(lastkeys, 1) && (r != lastkeys[1] || s != lastkeys[2] || y != lastkeys[3])
            # Create constraint
            # New endogenous and exogenous storage capacity is assumed to be delivered with minimum charge
            # If exogenous capacity is retired, any charge is assumed to be transferred to other capacity existing at start of year; or lost if no capacity exists
            push!(ns8_storagelevelyearend, @build_constraint(
                if lastkeys[3] == first(syear)
                    lastvals[1]
                else
                    (!restrictyears || Meta.parse(lastkeys[3])-1 in calcyears ? vstoragelevelyearendnn[lastkeys[1], lastkeys[2], string(Meta.parse(lastkeys[3])-1)] : 0)
                end

                + lastvals[2] * vnewstoragecapacity[lastkeys[1], lastkeys[2], lastkeys[3]]
                + lastvals[2] * (lastvals[3] > 0 ? lastvals[3] : 0) + sumexps[1]
                == vstoragelevelyearendnn[lastkeys[1], lastkeys[2], lastkeys[3]]))

            if lastvalsint[1] == 1
                push!(ns8a_storagelevelyearendnetzero, @build_constraint(
                    if lastkeys[3] == first(syear)
                        lastvals[1]
                    else
                        (!restrictyears || Meta.parse(lastkeys[3])-1 in calcyears ? vstoragelevelyearendnn[lastkeys[1], lastkeys[2], string(Meta.parse(lastkeys[3])-1)] : 0)
                    end

                    + lastvals[2] * vnewstoragecapacity[lastkeys[1], lastkeys[2], lastkeys[3]]
                    + lastvals[2] * (lastvals[3] > 0 ? lastvals[3] : 0)
                    == vstoragelevelyearendnn[lastkeys[1], lastkeys[2], lastkeys[3]]))
            end

            sumexps[1] = AffExpr()
            lastvals = [0.0, 0.0, 0.0]
            lastvalsint[1] = 0
        end

        add_to_expression!(sumexps[1], (vrateofstoragechargenn[r,s,row[:l],y] - vrateofstoragedischargenn[r,s,row[:l],y]) * row[:ys])

        if !ismissing(row[:sls])
            lastvals[1] = row[:sls]
        end

        if !ismissing(row[:msc])
            lastvals[2] = row[:msc]
        end

        if !ismissing(row[:rsc_delta])
            lastvals[3] = row[:rsc_delta]
        end

        lastvalsint[1] = ynz
        lastkeys[1] = r
        lastkeys[2] = s
        lastkeys[3] = y
    end

    # Create last constraint
    if isassigned(lastkeys, 1)
        push!(ns8_storagelevelyearend, @build_constraint(
            if lastkeys[3] == first(syear)
                lastvals[1]
            else
                (!restrictyears || Meta.parse(lastkeys[3])-1 in calcyears ? vstoragelevelyearendnn[lastkeys[1], lastkeys[2], string(Meta.parse(lastkeys[3])-1)] : 0)
            end

            + lastvals[2] * vnewstoragecapacity[lastkeys[1], lastkeys[2], lastkeys[3]]
            + lastvals[2] * (lastvals[3] > 0 ? lastvals[3] : 0) + sumexps[1]
            == vstoragelevelyearendnn[lastkeys[1], lastkeys[2], lastkeys[3]]))

        if lastvalsint[1] == 1
            push!(ns8a_storagelevelyearendnetzero, @build_constraint(
                if lastkeys[3] == first(syear)
                    lastvals[1]
                else
                    (!restrictyears || Meta.parse(lastkeys[3])-1 in calcyears ? vstoragelevelyearendnn[lastkeys[1], lastkeys[2], string(Meta.parse(lastkeys[3])-1)] : 0)
                end

                + lastvals[2] * vnewstoragecapacity[lastkeys[1], lastkeys[2], lastkeys[3]]
                + lastvals[2] * (lastvals[3] > 0 ? lastvals[3] : 0)
                == vstoragelevelyearendnn[lastkeys[1], lastkeys[2], lastkeys[3]]))
        end
    end

    put!(cons_channel, ns8_storagelevelyearend)
    put!(cons_channel, ns8a_storagelevelyearendnetzero)
end)

numconsarrays += 2
logmsg("Queued constraint NS8_StorageLevelYearEnd for creation.", quiet)
logmsg("Queued constraint NS8a_StorageLevelYearEndNetZero for creation.", quiet)
# END: NS8_StorageLevelYearEnd and NS8a_StorageLevelYearEndNetZero.

# BEGIN: NS8Tr_StorageLevelYearEnd and NS8aTr_StorageLevelYearEndNetZero.
if transmissionmodeling
    ns8tr_storagelevelyearend::Array{AbstractConstraint, 1} = Array{AbstractConstraint, 1}()
    ns8atr_storagelevelyearendnetzero::Array{AbstractConstraint, 1} = Array{AbstractConstraint, 1}()

    t = Threads.@spawn(let
        local lastkeys = Array{String, 1}(undef,4)  # lastkeys[1] = n, lastkeys[2] = s, lastkeys[3] = y, lastkeys[4] = r
        local lastvals = Array{Float64, 1}([0.0, 0.0, 0.0])  # lastvals[1] = sls, lastvals[2] = msc, lastvals[3] = rsc_delta
        local lastvalsint = Array{Int64, 1}(undef,1)  # lastvalsint[1] = ynz
        local sumexps = Array{AffExpr, 1}([AffExpr()])  # sumexps[1] = vrateofstoragechargenodal and vrateofstoragedischargenodal sum

        # Note that this query distributes StorageLevelStart, MinStorageCharge, and ResidualStorageCapacity according to NodalDistributionStorageCapacity
        for row in SQLite.DBInterface.execute(db, "select ns.r as r, ns.n as n, s.val as s,
        case s.netzerotg2 when 1 then 0 else case s.netzerotg1 when 1 then 0 else s.netzeroyear end end as ynz,
        ns.y as y, ys.l as l, cast(ys.val as real) as ys,
        cast(se.sls * ns.val as real) as sls, cast(msc.val * ns.val as real) as msc,
        cast(rsc.delta as real) as rsc_delta
        from nodalstorage ns, STORAGE s, YearSplit_def ys
        left join (select sls.r as r, sls.s as s, sls.val * rsc.val as sls
    		from StorageLevelStart_def sls, ResidualStorageCapacity_def rsc
    		where sls.r = rsc.r and sls.s = rsc.s and rsc.y = " * first(syear) * ") se on se.r = ns.r and se.s = ns.s
        left join MinStorageCharge_def msc on msc.r = ns.r and msc.s = s.val and msc.y = ns.y
        left join (select r, s, y, val - lag(val) over (partition by r, s order by y) as delta
    		from ResidualStorageCapacity_def $(restrictyears ? "where y in" * inyears : "")) rsc
            on rsc.r = ns.r and rsc.s = s.val and rsc.y = ns.y
        where ns.s = s.val
    	and ns.y = ys.y
        $(restrictyears ? "and ns.y in" * inyears : "")
        order by ns.n, ns.s, ns.y")
            local n = row[:n]
            local s = row[:s]
            local ynz = row[:ynz]  # 1 = year end level must = year start level (zeroed out when tg2 net zero or tg1 net zero is activated as year check isn't necessary)
            local y = row[:y]

            if isassigned(lastkeys, 1) && (n != lastkeys[1] || s != lastkeys[2] || y != lastkeys[3])
                # Create constraint
                # New endogenous and exogenous storage capacity is assumed to be delivered with minimum charge
                # If exogenous capacity is retired, any charge is assumed to be transferred to other capacity existing at start of year; or lost if no capacity exists
                push!(ns8tr_storagelevelyearend, @build_constraint(
                    if lastkeys[3] == first(syear)
                        lastvals[1]
                    else
                        (!restrictyears || Meta.parse(lastkeys[3])-1 in calcyears ? vstoragelevelyearendnodal[lastkeys[1], lastkeys[2], string(Meta.parse(lastkeys[3])-1)] : 0)
                    end

                    + lastvals[2] * vnewstoragecapacity[lastkeys[4], lastkeys[2], lastkeys[3]]
                    + lastvals[2] * (lastvals[3] > 0 ? lastvals[3] : 0) + sumexps[1]
                    == vstoragelevelyearendnodal[lastkeys[1], lastkeys[2], lastkeys[3]]))

                if lastvalsint[1] == 1
                    push!(ns8atr_storagelevelyearendnetzero, @build_constraint(
                        if lastkeys[3] == first(syear)
                            lastvals[1]
                        else
                            (!restrictyears || Meta.parse(lastkeys[3])-1 in calcyears ? vstoragelevelyearendnodal[lastkeys[1], lastkeys[2], string(Meta.parse(lastkeys[3])-1)] : 0)
                        end

                        + lastvals[2] * vnewstoragecapacity[lastkeys[4], lastkeys[2], lastkeys[3]]
                        + lastvals[2] * (lastvals[3] > 0 ? lastvals[3] : 0)
                        == vstoragelevelyearendnodal[lastkeys[1], lastkeys[2], lastkeys[3]]))
                end

                sumexps[1] = AffExpr()
                lastvals = [0.0, 0.0, 0.0]
                lastvalsint[1] = 0
            end

            add_to_expression!(sumexps[1], (vrateofstoragechargenodal[n,s,row[:l],y] - vrateofstoragedischargenodal[n,s,row[:l],y]) * row[:ys])

            if !ismissing(row[:sls])
                lastvals[1] = row[:sls]
            end

            if !ismissing(row[:msc])
                lastvals[2] = row[:msc]
            end

            if !ismissing(row[:rsc_delta])
                lastvals[3] = row[:rsc_delta]
            end

            lastvalsint[1] = ynz
            lastkeys[1] = n
            lastkeys[2] = s
            lastkeys[3] = y
            lastkeys[4] = row[:r]
        end

        # Create last constraint
        if isassigned(lastkeys, 1)
            push!(ns8tr_storagelevelyearend, @build_constraint(
                if lastkeys[3] == first(syear)
                    lastvals[1]
                else
                    (!restrictyears || Meta.parse(lastkeys[3])-1 in calcyears ? vstoragelevelyearendnodal[lastkeys[1], lastkeys[2], string(Meta.parse(lastkeys[3])-1)] : 0)
                end

                + lastvals[2] * vnewstoragecapacity[lastkeys[4], lastkeys[2], lastkeys[3]]
                + lastvals[2] * (lastvals[3] > 0 ? lastvals[3] : 0) + sumexps[1]
                == vstoragelevelyearendnodal[lastkeys[1], lastkeys[2], lastkeys[3]]))

            if lastvalsint[1] == 1
                push!(ns8atr_storagelevelyearendnetzero, @build_constraint(
                    if lastkeys[3] == first(syear)
                        lastvals[1]
                    else
                        (!restrictyears || Meta.parse(lastkeys[3])-1 in calcyears ? vstoragelevelyearendnodal[lastkeys[1], lastkeys[2], string(Meta.parse(lastkeys[3])-1)] : 0)
                    end

                    + lastvals[2] * vnewstoragecapacity[lastkeys[4], lastkeys[2], lastkeys[3]]
                    + lastvals[2] * (lastvals[3] > 0 ? lastvals[3] : 0)
                    == vstoragelevelyearendnodal[lastkeys[1], lastkeys[2], lastkeys[3]]))
            end
        end

        put!(cons_channel, ns8tr_storagelevelyearend)
        put!(cons_channel, ns8atr_storagelevelyearendnetzero)
    end)

    numconsarrays += 2
    logmsg("Queued constraint NS8Tr_StorageLevelYearEnd for creation.", quiet)
    logmsg("Queued constraint NS8aTr_StorageLevelYearEndNetZero for creation.", quiet)
end
# END: NS8Tr_StorageLevelYearEnd and NS8aTr_StorageLevelYearEndNetZero.

# BEGIN: SI1_StorageUpperLimit.
si1_storageupperlimit::Array{AbstractConstraint, 1} = Array{AbstractConstraint, 1}()

t = Threads.@spawn(begin
    for row in SQLite.DBInterface.execute(db, "select r.val as r, s.val as s, y.val as y, cast(rsc.val as real) as rsc
    from region r, storage s, year y
    left join ResidualStorageCapacity_def rsc on rsc.r = r.val and rsc.s = s.val and rsc.y = y.val
    $(restrictyears ? "where y.val in" * inyears : "")")
        local r = row[:r]
        local s = row[:s]
        local y = row[:y]

        push!(si1_storageupperlimit, @build_constraint(vaccumulatednewstoragecapacity[r,s,y] + (ismissing(row[:rsc]) ? 0 : row[:rsc]) == vstorageupperlimit[r,s,y]))
    end

    put!(cons_channel, si1_storageupperlimit)
end)

numconsarrays += 1
logmsg("Queued constraint SI1_StorageUpperLimit for creation.", quiet)
# END: SI1_StorageUpperLimit.

# BEGIN: SI2_StorageLowerLimit.
si2_storagelowerlimit::Array{AbstractConstraint, 1} = Array{AbstractConstraint, 1}()

t = Threads.@spawn(begin
    for row in SQLite.DBInterface.execute(db, "select r.val as r, s.val as s, y.val as y, cast(msc.val as real) as msc
    from region r, storage s, year y, MinStorageCharge_def msc
    where msc.r = r.val and msc.s = s.val and msc.y = y.val $(restrictyears ? "and y.val in" * inyears : "")")
        local r = row[:r]
        local s = row[:s]
        local y = row[:y]

        push!(si2_storagelowerlimit, @build_constraint(row[:msc] * vstorageupperlimit[r,s,y] == vstoragelowerlimit[r,s,y]))
    end

    put!(cons_channel, si2_storagelowerlimit)
end)

numconsarrays += 1
logmsg("Queued constraint SI2_StorageLowerLimit for creation.", quiet)
# END: SI2_StorageLowerLimit.

# BEGIN: SI3_TotalNewStorage.
si3_totalnewstorage::Array{AbstractConstraint, 1} = Array{AbstractConstraint, 1}()

t = Threads.@spawn(let
    local lastkeys = Array{String, 1}(undef,3)  # lastkeys[1] = r, lastkeys[2] = s, lastkeys[3] = y
    local sumexps = Array{AffExpr, 1}([AffExpr()])  # sumexps[1] = vnewstoragecapacity sum

    for row in SQLite.DBInterface.execute(db, "select r.val as r, s.val as s, y.val as y, cast(ols.val as real) as ols, yy.val as yy
    from region r, storage s, year y, OperationalLifeStorage_def ols, year yy
    where ols.r = r.val and ols.s = s.val
    and y.val - yy.val < ols.val and y.val - yy.val >= 0
    $(restrictyears ? "and y.val in" * inyears : "") $(restrictyears ? "and yy.val in" * inyears : "")
    order by r.val, s.val, y.val")
        local r = row[:r]
        local s = row[:s]
        local y = row[:y]

        if isassigned(lastkeys, 1) && (r != lastkeys[1] || s != lastkeys[2] || y != lastkeys[3])
            # Create constraint
            push!(si3_totalnewstorage, @build_constraint(sumexps[1] ==
                vaccumulatednewstoragecapacity[lastkeys[1],lastkeys[2],lastkeys[3]]))
            sumexps[1] = AffExpr()
        end

        add_to_expression!(sumexps[1], vnewstoragecapacity[r,s,row[:yy]])

        lastkeys[1] = r
        lastkeys[2] = s
        lastkeys[3] = y
    end

    # Create last constraint
    if isassigned(lastkeys, 1)
        push!(si3_totalnewstorage, @build_constraint(sumexps[1] ==
            vaccumulatednewstoragecapacity[lastkeys[1],lastkeys[2],lastkeys[3]]))
    end

    put!(cons_channel, si3_totalnewstorage)
end)

numconsarrays += 1
logmsg("Queued constraint SI3_TotalNewStorage for creation.", quiet)
# END: SI3_TotalNewStorage.

# BEGIN: NS9a_StorageLevelTsLowerLimit and NS9b_StorageLevelTsUpperLimit.
ns9a_storageleveltslowerlimit::Array{AbstractConstraint, 1} = Array{AbstractConstraint, 1}()
ns9b_storageleveltsupperlimit::Array{AbstractConstraint, 1} = Array{AbstractConstraint, 1}()

t = Threads.@spawn(begin
    for row in SQLite.DBInterface.execute(db, "select r.val as r, s.val as s, l.val as l, y.val as y
    from REGION r, STORAGE s, TIMESLICE l, YEAR y
    left join nodalstorage ns on ns.r = r.val and ns.s = s.val and ns.y = y.val
    where ns.r is null $(restrictyears ? "and y.val in" * inyears : "")")
        local r = row[:r]
        local s = row[:s]
        local l = row[:l]
        local y = row[:y]

        push!(ns9a_storageleveltslowerlimit, @build_constraint(vstoragelowerlimit[r,s,y] <= vstorageleveltsendnn[r,s,l,y]))
        push!(ns9b_storageleveltsupperlimit, @build_constraint(vstorageleveltsendnn[r,s,l,y] <= vstorageupperlimit[r,s,y]))
    end

    put!(cons_channel, ns9a_storageleveltslowerlimit)
    put!(cons_channel, ns9b_storageleveltsupperlimit)
end)

numconsarrays += 2
logmsg("Queued constraint NS9a_StorageLevelTsLowerLimit for creation.", quiet)
logmsg("Queued constraint NS9b_StorageLevelTsUpperLimit for creation.", quiet)
# END: NS9a_StorageLevelTsLowerLimit and NS9b_StorageLevelTsUpperLimit.

# BEGIN: NS9aTr_StorageLevelTsLowerLimit and NS9bTr_StorageLevelTsUpperLimit.
if transmissionmodeling
    ns9atr_storageleveltslowerlimit::Array{AbstractConstraint, 1} = Array{AbstractConstraint, 1}()
    ns9btr_storageleveltsupperlimit::Array{AbstractConstraint, 1} = Array{AbstractConstraint, 1}()

    t = Threads.@spawn(begin
        for row in SQLite.DBInterface.execute(db, "select ns.r as r, ns.n as n, ns.s as s, l.val as l, ns.y as y, cast(ns.val as real) as nsc
        from nodalstorage ns, TIMESLICE l $(restrictyears ? "where ns.y in" * inyears : "")")
            local r = row[:r]
            local n = row[:n]
            local s = row[:s]
            local l = row[:l]
            local y = row[:y]
            local nsc = row[:nsc]

            push!(ns9atr_storageleveltslowerlimit, @build_constraint(vstoragelowerlimit[r,s,y] * nsc <= vstorageleveltsendnodal[n,s,l,y]))
            push!(ns9btr_storageleveltsupperlimit, @build_constraint(vstorageleveltsendnodal[n,s,l,y] <= vstorageupperlimit[r,s,y] * nsc))
        end

        put!(cons_channel, ns9atr_storageleveltslowerlimit)
        put!(cons_channel, ns9btr_storageleveltsupperlimit)
    end)

    numconsarrays += 2
    logmsg("Queued constraint NS9aTr_StorageLevelTsLowerLimit for creation.", quiet)
    logmsg("Queued constraint NS9bTr_StorageLevelTsUpperLimit for creation.", quiet)
end
# END: NS9aTr_StorageLevelTsLowerLimit and NS9bTr_StorageLevelTsUpperLimit.

# BEGIN: NS10_StorageChargeLimit.
ns10_storagechargelimit::Array{AbstractConstraint, 1} = Array{AbstractConstraint, 1}()

t = Threads.@spawn(begin
    for row in SQLite.DBInterface.execute(db, "select r.val as r, s.val as s, l.val as l, y.val as y, cast(smc.val as real) as smc
    from region r, storage s, TIMESLICE l, year y, StorageMaxChargeRate_def smc
    left join nodalstorage ns on ns.r = r.val and ns.s = s.val and ns.y = y.val
    where
    r.val = smc.r and s.val = smc.s
    and ns.r is null $(restrictyears ? "and y.val in" * inyears : "")")
        push!(ns10_storagechargelimit, @build_constraint(vrateofstoragechargenn[row[:r], row[:s], row[:l], row[:y]] <= row[:smc]))
    end

    put!(cons_channel, ns10_storagechargelimit)
end)

numconsarrays += 1
logmsg("Queued constraint NS10_StorageChargeLimit for creation.", quiet)
# END: NS10_StorageChargeLimit.

# BEGIN: NS10Tr_StorageChargeLimit.
if transmissionmodeling
    ns10tr_storagechargelimit::Array{AbstractConstraint, 1} = Array{AbstractConstraint, 1}()

    t = Threads.@spawn(begin
        for row in SQLite.DBInterface.execute(db, "select ns.n as n, ns.s as s, l.val as l, ns.y as y, cast(smc.val as real) as smc
        from nodalstorage ns, TIMESLICE l, StorageMaxChargeRate_def smc
        where
        ns.r = smc.r and ns.s = smc.s $(restrictyears ? "and ns.y in" * inyears : "")")
            push!(ns10tr_storagechargelimit, @build_constraint(vrateofstoragechargenodal[row[:n], row[:s], row[:l], row[:y]] <= row[:smc]))
        end

        put!(cons_channel, ns10tr_storagechargelimit)
    end)

    numconsarrays += 1
    logmsg("Queued constraint NS10Tr_StorageChargeLimit for creation.", quiet)
end
# END: NS10Tr_StorageChargeLimit.

# BEGIN: NS11_StorageDischargeLimit.
ns11_storagedischargelimit::Array{AbstractConstraint, 1} = Array{AbstractConstraint, 1}()

t = Threads.@spawn(begin
    for row in SQLite.DBInterface.execute(db, "select r.val as r, s.val as s, l.val as l, y.val as y, cast(smd.val as real) as smd
    from region r, storage s, TIMESLICE l, year y, StorageMaxDischargeRate_def smd
    left join nodalstorage ns on ns.r = r.val and ns.s = s.val and ns.y = y.val
    where
    r.val = smd.r and s.val = smd.s
    and ns.r is null $(restrictyears ? "and y.val in" * inyears : "")")
        push!(ns11_storagedischargelimit, @build_constraint(vrateofstoragedischargenn[row[:r], row[:s], row[:l], row[:y]] <= row[:smd]))
    end

    put!(cons_channel, ns11_storagedischargelimit)
end)

numconsarrays += 1
logmsg("Queued constraint NS11_StorageDischargeLimit for creation.", quiet)
# END: NS11_StorageDischargeLimit.

# BEGIN: NS11Tr_StorageDischargeLimit.
if transmissionmodeling
    ns11tr_storagedischargelimit::Array{AbstractConstraint, 1} = Array{AbstractConstraint, 1}()

    t = Threads.@spawn(begin
        for row in SQLite.DBInterface.execute(db, "select ns.n as n, ns.s as s, l.val as l, ns.y as y, cast(smd.val as real) as smd
        from nodalstorage ns, TIMESLICE l, StorageMaxDischargeRate_def smd
        where
        ns.r = smd.r and ns.s = smd.s $(restrictyears ? "and ns.y in" * inyears : "")")
            push!(ns11tr_storagedischargelimit, @build_constraint(vrateofstoragedischargenodal[row[:n], row[:s], row[:l], row[:y]] <= row[:smd]))
        end

        put!(cons_channel, ns11tr_storagedischargelimit)
    end)

    numconsarrays += 1
    logmsg("Queued constraint NS11Tr_StorageDischargeLimit for creation.", quiet)
end
# END: NS11Tr_StorageDischargeLimit.

# BEGIN: NS12a_StorageLevelTsGroup2LowerLimit and NS12b_StorageLevelTsGroup2UpperLimit.
ns12a_storageleveltsgroup2lowerlimit::Array{AbstractConstraint, 1} = Array{AbstractConstraint, 1}()
ns12b_storageleveltsgroup2upperlimit::Array{AbstractConstraint, 1} = Array{AbstractConstraint, 1}()

t = Threads.@spawn(begin
    for row in SQLite.DBInterface.execute(db, "select r.val as r, s.val as s, tg1.name as tg1, tg2.name as tg2, y.val as y
    from REGION r, STORAGE s, TSGROUP1 tg1, TSGROUP2 tg2, YEAR y
    left join nodalstorage ns on ns.r = r.val and ns.s = s.val and ns.y = y.val
    where ns.r is null $(restrictyears ? "and y.val in" * inyears : "")")
        local r = row[:r]
        local s = row[:s]
        local tg1 = row[:tg1]
        local tg2 = row[:tg2]
        local y = row[:y]

        push!(ns12a_storageleveltsgroup2lowerlimit, @build_constraint(vstoragelowerlimit[r,s,y] <= vstorageleveltsgroup2endnn[r,s,tg1,tg2,y]))
        push!(ns12b_storageleveltsgroup2upperlimit, @build_constraint(vstorageleveltsgroup2endnn[r,s,tg1,tg2,y] <= vstorageupperlimit[r,s,y]))
    end

    put!(cons_channel, ns12a_storageleveltsgroup2lowerlimit)
    put!(cons_channel, ns12b_storageleveltsgroup2upperlimit)
end)

numconsarrays += 2
logmsg("Queued constraint NS12a_StorageLevelTsGroup2LowerLimit for creation.", quiet)
logmsg("Queued constraint NS12b_StorageLevelTsGroup2UpperLimit for creation.", quiet)
# END: NS12a_StorageLevelTsGroup2LowerLimit and NS12b_StorageLevelTsGroup2UpperLimit.

# BEGIN: NS12aTr_StorageLevelTsGroup2LowerLimit and NS12bTr_StorageLevelTsGroup2UpperLimit.
if transmissionmodeling
    ns12atr_storageleveltsgroup2lowerlimit::Array{AbstractConstraint, 1} = Array{AbstractConstraint, 1}()
    ns12btr_storageleveltsgroup2upperlimit::Array{AbstractConstraint, 1} = Array{AbstractConstraint, 1}()

    t = Threads.@spawn(begin
        for row in SQLite.DBInterface.execute(db, "select ns.r as r, ns.n as n, ns.s as s, tg1.name as tg1, tg2.name as tg2, ns.y as y, cast(ns.val as real) as nsc
        from nodalstorage ns, TSGROUP1 tg1, TSGROUP2 tg2 $(restrictyears ? "where ns.y in" * inyears : "")")
            local r = row[:r]
            local n = row[:n]
            local s = row[:s]
            local tg1 = row[:tg1]
            local tg2 = row[:tg2]
            local y = row[:y]
            local nsc = row[:nsc]

            push!(ns12atr_storageleveltsgroup2lowerlimit, @build_constraint(vstoragelowerlimit[r,s,y] * nsc <= vstorageleveltsgroup2endnodal[n,s,tg1,tg2,y]))
            push!(ns12btr_storageleveltsgroup2upperlimit, @build_constraint(vstorageleveltsgroup2endnodal[n,s,tg1,tg2,y] <= vstorageupperlimit[r,s,y] * nsc))
        end

        put!(cons_channel, ns12atr_storageleveltsgroup2lowerlimit)
        put!(cons_channel, ns12btr_storageleveltsgroup2upperlimit)
    end)

    numconsarrays += 2
    logmsg("Queued constraint NS12aTr_StorageLevelTsGroup2LowerLimit for creation.", quiet)
    logmsg("Queued constraint NS12bTr_StorageLevelTsGroup2UpperLimit for creation.", quiet)
end
# END: NS12aTr_StorageLevelTsGroup2LowerLimit and NS12bTr_StorageLevelTsGroup2UpperLimit.

# BEGIN: NS13a_StorageLevelTsGroup1LowerLimit and NS13b_StorageLevelTsGroup1UpperLimit.
ns13a_storageleveltsgroup1lowerlimit::Array{AbstractConstraint, 1} = Array{AbstractConstraint, 1}()
ns13b_storageleveltsgroup1upperlimit::Array{AbstractConstraint, 1} = Array{AbstractConstraint, 1}()

t = Threads.@spawn(begin
    for row in SQLite.DBInterface.execute(db, "select r.val as r, s.val as s, tg1.name as tg1, y.val as y
    from REGION r, STORAGE s, TSGROUP1 tg1, YEAR y
    left join nodalstorage ns on ns.r = r.val and ns.s = s.val and ns.y = y.val
    where ns.r is null $(restrictyears ? "and y.val in" * inyears : "")")
        local r = row[:r]
        local s = row[:s]
        local tg1 = row[:tg1]
        local y = row[:y]

        push!(ns13a_storageleveltsgroup1lowerlimit, @build_constraint(vstoragelowerlimit[r,s,y] <= vstorageleveltsgroup1endnn[r,s,tg1,y]))
        push!(ns13b_storageleveltsgroup1upperlimit, @build_constraint(vstorageleveltsgroup1endnn[r,s,tg1,y] <= vstorageupperlimit[r,s,y]))
    end

    put!(cons_channel, ns13a_storageleveltsgroup1lowerlimit)
    put!(cons_channel, ns13b_storageleveltsgroup1upperlimit)
end)

numconsarrays += 2
logmsg("Queued constraint NS13a_StorageLevelTsGroup1LowerLimit for creation.", quiet)
logmsg("Queued constraint NS13b_StorageLevelTsGroup1UpperLimit for creation.", quiet)
# END: NS13a_StorageLevelTsGroup2LowerLimit and NS13b_StorageLevelTsGroup2UpperLimit.

# BEGIN: NS13aTr_StorageLevelTsGroup1LowerLimit and NS13bTr_StorageLevelTsGroup1UpperLimit.
if transmissionmodeling
    ns13atr_storageleveltsgroup1lowerlimit::Array{AbstractConstraint, 1} = Array{AbstractConstraint, 1}()
    ns13btr_storageleveltsgroup1upperlimit::Array{AbstractConstraint, 1} = Array{AbstractConstraint, 1}()

    t = Threads.@spawn(begin
        for row in SQLite.DBInterface.execute(db, "select ns.r as r, ns.n as n, ns.s as s, tg1.name as tg1, ns.y as y, cast(ns.val as real) as nsc
        from nodalstorage ns, TSGROUP1 tg1 $(restrictyears ? "where ns.y in" * inyears : "")")
            local r = row[:r]
            local n = row[:n]
            local s = row[:s]
            local tg1 = row[:tg1]
            local y = row[:y]
            local nsc = row[:nsc]

            push!(ns13atr_storageleveltsgroup1lowerlimit, @build_constraint(vstoragelowerlimit[r,s,y] * nsc <= vstorageleveltsgroup1endnodal[n,s,tg1,y]))
            push!(ns13btr_storageleveltsgroup1upperlimit, @build_constraint(vstorageleveltsgroup1endnodal[n,s,tg1,y] <= vstorageupperlimit[r,s,y] * nsc))
        end

        put!(cons_channel, ns13atr_storageleveltsgroup1lowerlimit)
        put!(cons_channel, ns13btr_storageleveltsgroup1upperlimit)
    end)

    numconsarrays += 2
    logmsg("Queued constraint NS13aTr_StorageLevelTsGroup2LowerLimit for creation.", quiet)
    logmsg("Queued constraint NS13bTr_StorageLevelTsGroup2UpperLimit for creation.", quiet)
end
# END: NS13aTr_StorageLevelTsGroup2LowerLimit and NS13bTr_StorageLevelTsGroup2UpperLimit.

# BEGIN: NS14_MaxStorageCapacity.
ns14_maxstoragecapacity::Array{AbstractConstraint, 1} = Array{AbstractConstraint, 1}()

t = Threads.@spawn(begin
    for row in SQLite.DBInterface.execute(db, "select smc.r, smc.s, smc.y, cast(smc.val as real) as smc
    from TotalAnnualMaxCapacityStorage_def smc $(restrictyears ? "where smc.y in" * inyears : "")")
        push!(ns14_maxstoragecapacity, @build_constraint(vstorageupperlimit[row[:r],row[:s],row[:y]] <= row[:smc]))
    end

    put!(cons_channel, ns14_maxstoragecapacity)
end)

numconsarrays += 1
logmsg("Queued constraint NS14_MaxStorageCapacity for creation.", quiet)
# END: NS14_MaxStorageCapacity.

# BEGIN: NS15_MinStorageCapacity.
ns15_minstoragecapacity::Array{AbstractConstraint, 1} = Array{AbstractConstraint, 1}()

t = Threads.@spawn(begin
    for row in SQLite.DBInterface.execute(db, "select smc.r, smc.s, smc.y, cast(smc.val as real) as smc
    from TotalAnnualMinCapacityStorage_def smc $(restrictyears ? "where smc.y in" * inyears : "")")
        push!(ns15_minstoragecapacity, @build_constraint(row[:smc] <= vstorageupperlimit[row[:r],row[:s],row[:y]]))
    end

    put!(cons_channel, ns15_minstoragecapacity)
end)

numconsarrays += 1
logmsg("Queued constraint NS15_MinStorageCapacity for creation.", quiet)
# END: NS15_MinStorageCapacity.

# BEGIN: NS16_MaxStorageCapacityInvestment.
ns16_maxstoragecapacityinvestment::Array{AbstractConstraint, 1} = Array{AbstractConstraint, 1}()

t = Threads.@spawn(begin
    for row in SQLite.DBInterface.execute(db, "select smc.r, smc.s, smc.y, cast(smc.val as real) as smc
    from TotalAnnualMaxCapacityInvestmentStorage_def smc $(restrictyears ? "where smc.y in" * inyears : "")")
        # Annual capacity constraints are scaled up when restrictyears is true
        push!(ns16_maxstoragecapacityinvestment, @build_constraint(vnewstoragecapacity[row[:r],row[:s],row[:y]] <= row[:smc]
            * (restrictyears ? yearintervalsdict[row[:y]] : 1)))
    end

    put!(cons_channel, ns16_maxstoragecapacityinvestment)
end)

numconsarrays += 1
logmsg("Queued constraint NS16_MaxStorageCapacityInvestment for creation.", quiet)
# END: NS16_MaxStorageCapacityInvestment.

# BEGIN: NS17_MinStorageCapacityInvestment.
ns17_minstoragecapacityinvestment::Array{AbstractConstraint, 1} = Array{AbstractConstraint, 1}()

t = Threads.@spawn(begin
    for row in SQLite.DBInterface.execute(db, "select smc.r, smc.s, smc.y, cast(smc.val as real) as smc
    from TotalAnnualMinCapacityInvestmentStorage_def smc $(restrictyears ? "where smc.y in" * inyears : "")")
        # Annual capacity constraints are scaled up when restrictyears is true
        push!(ns17_minstoragecapacityinvestment, @build_constraint(row[:smc] * (restrictyears ? yearintervalsdict[row[:y]] : 1)
            <= vnewstoragecapacity[row[:r],row[:s],row[:y]]))
    end

    put!(cons_channel, ns17_minstoragecapacityinvestment)
end)

numconsarrays += 1
logmsg("Queued constraint NS17_MinStorageCapacityInvestment for creation.", quiet)
# END: NS17_MinStorageCapacityInvestment.

# BEGIN: NS18_FullLoadHours.
ns18_fullloadhours::Array{AbstractConstraint, 1} = Array{AbstractConstraint, 1}()

t = Threads.@spawn(let
    local lastkeys = Array{String, 1}(undef,3)  # lastkeys[1] = r, lastkeys[2] = s, lastkeys[3] = y
    local lastvals = Array{Float64, 1}([0.0])  # lastvals[1] = flh
    local sumexps = Array{AffExpr, 1}([AffExpr()])  # sumexps[1] = vnewcapacity sum

    # Note: vnewcapacity is in power units; vnewstoragecapacity is in energy units
    for row in SQLite.DBInterface.execute(db, "select distinct sf.r as r, sf.s as s, sf.y as y, tfs.t as t, cast(sf.val as real) as flh,
    cast(cta.val as real) as cta
    from StorageFullLoadHours_def sf, TechnologyFromStorage_def tfs, CapacityToActivityUnit_def cta
    where sf.r = tfs.r and sf.s = tfs.s and tfs.val = 1
    and tfs.r = cta.r and tfs.t = cta.t
    $(restrictyears ? "and sf.y in" * inyears : "")
    order by sf.r, sf.s, sf.y")
        local r = row[:r]
        local s = row[:s]
        local y = row[:y]

        if isassigned(lastkeys, 1) && (r != lastkeys[1] || s != lastkeys[2] || y != lastkeys[3])
            # Create constraint
            push!(ns18_fullloadhours, @build_constraint((sumexps[1]) * lastvals[1] / 8760 == vnewstoragecapacity[lastkeys[1],lastkeys[2],lastkeys[3]]))
            sumexps[1] = AffExpr()
            lastvals[1] = 0.0
        end

        add_to_expression!(sumexps[1], vnewcapacity[r,row[:t],y] * row[:cta])

        if !ismissing(row[:flh])
            lastvals[1] = row[:flh]
        end

        lastkeys[1] = r
        lastkeys[2] = s
        lastkeys[3] = y
    end

    # Create last constraint
    if isassigned(lastkeys, 1)
        push!(ns18_fullloadhours, @build_constraint((sumexps[1]) * lastvals[1] / 8760 == vnewstoragecapacity[lastkeys[1],lastkeys[2],lastkeys[3]]))
    end

    put!(cons_channel, ns18_fullloadhours)
end)

numconsarrays += 1
logmsg("Queued constraint NS18_FullLoadHours for creation.", quiet)
# END: NS18_FullLoadHours.

# BEGIN: SI4a_FinancingStorage.
# Total financing costs discounted to year new capacity is deployed; assumes capital costs are financed at interest rate and repaid in equal installments over life of storage (payments occur at year's end)
si4a_financingstorage::Array{AbstractConstraint, 1} = Array{AbstractConstraint, 1}()

t = Threads.@spawn(begin
    for row in SQLite.DBInterface.execute(db, "select r.val as r, s.val as s, y.val as y, cast(ccs.val as real) as ccs,
    cast(ols.val as real) as ols, cast(dr.val as real) as dr, cast(irs.val as real) as irs
    from region r, storage s, year y, CapitalCostStorage_def ccs, OperationalLifeStorage_def ols, DiscountRate_def dr, InterestRateStorage_def irs
    where ccs.r = r.val and ccs.s = s.val and ccs.y = y.val
    $(restrictyears ? "and y.val in" * inyears : "")
    and ols.r = r.val and ols.s = s.val
    and dr.r = r.val
    and irs.r = r.val and irs.s = s.val and irs.y = y.val and irs.val is not null and irs.val <> 0")
        local r = row[:r]
        local s = row[:s]
        local y = row[:y]
        local ols = row[:ols]
        local dr = row[:dr]
        local irs = row[:irs]

        push!(si4a_financingstorage, @build_constraint(row[:ccs] * vnewstoragecapacity[r,s,y] * (irs / (1 - (1 + irs)^(-ols)) - 1/ols)
            * (1 - (1 + dr)^(-ols)) / dr == vfinancecoststorage[r,s,y]))
    end

    put!(cons_channel, si4a_financingstorage)
end)

numconsarrays += 1
logmsg("Queued constraint SI4a_FinancingStorage for creation.", quiet)
# END: SI4a_FinancingStorage.

# BEGIN: SI4_UndiscountedCapitalInvestmentStorage.
si4_undiscountedcapitalinvestmentstorage::Array{AbstractConstraint, 1} = Array{AbstractConstraint, 1}()

t = Threads.@spawn(begin
    for row in SQLite.DBInterface.execute(db, "select r.val as r, s.val as s, y.val as y, cast(ccs.val as real) as ccs
    from region r, storage s, year y, CapitalCostStorage_def ccs
    where ccs.r = r.val and ccs.s = s.val and ccs.y = y.val $(restrictyears ? "and y.val in" * inyears : "")")
        local r = row[:r]
        local s = row[:s]
        local y = row[:y]

        push!(si4_undiscountedcapitalinvestmentstorage, @build_constraint(row[:ccs] * vnewstoragecapacity[r,s,y]
            + vfinancecoststorage[r,s,y] == vcapitalinvestmentstorage[r,s,y]))
    end

    put!(cons_channel, si4_undiscountedcapitalinvestmentstorage)
end)

numconsarrays += 1
logmsg("Queued constraint SI4_UndiscountedCapitalInvestmentStorage for creation.", quiet)
# END: SI4_UndiscountedCapitalInvestmentStorage.

# BEGIN: SI5_DiscountingCapitalInvestmentStorage.
si5_discountingcapitalinvestmentstorage::Array{AbstractConstraint, 1} = Array{AbstractConstraint, 1}()

t = Threads.@spawn(let
    local sumexps = Array{AffExpr, 1}([AffExpr()])  # sumexps[1] = sum of discounted costs over interval ending in y

    # When modeling selected years, discounted costs assume linear investment over each year's interval
    for row in SQLite.DBInterface.execute(db, "select r.val as r, s.val as s, y.val as y, cast(dr.val as real) as dr
    from region r, storage s, year y, DiscountRate_def dr
    where dr.r = r.val $(restrictyears ? "and y.val in" * inyears : "")")
        local r = row[:r]
        local s = row[:s]
        local y = row[:y]

        for i = 0:(yearintervalsdict[y]-1)
            add_to_expression!(sumexps[1], vcapitalinvestmentstorage[r,s,y] / yearintervalsdict[y]
                / ((1 + row[:dr])^(Meta.parse(y) - i - firstscenarioyear)))
        end

        push!(si5_discountingcapitalinvestmentstorage, @build_constraint(sumexps[1] == vdiscountedcapitalinvestmentstorage[r,s,y]))
        sumexps[1] = AffExpr()
    end

    put!(cons_channel, si5_discountingcapitalinvestmentstorage)
end)

numconsarrays += 1
logmsg("Queued constraint SI5_DiscountingCapitalInvestmentStorage for creation.", quiet)
# END: SI5_DiscountingCapitalInvestmentStorage.

# BEGIN: SI6_SalvageValueStorageAtEndOfPeriod1.
si6_salvagevaluestorageatendofperiod1::Array{AbstractConstraint, 1} = Array{AbstractConstraint, 1}()

t = Threads.@spawn(begin
    # Salvage values are figured as of last scenario year
    for row in SQLite.DBInterface.execute(db, "select r.val as r, s.val as s, y.val as y
    from region r, storage s, year y, OperationalLifeStorage_def ols
    where ols.r = r.val and ols.s = s.val
    $(restrictyears ? "and y.val in" * inyears : "")
    and y.val + ols.val - 1 <= " * string(lastscenarioyear))
        local r = row[:r]
        local s = row[:s]
        local y = row[:y]

        push!(si6_salvagevaluestorageatendofperiod1, @build_constraint(0 == vsalvagevaluestorage[r,s,y]))
    end

    put!(cons_channel, si6_salvagevaluestorageatendofperiod1)
end)

numconsarrays += 1
logmsg("Queued constraint SI6_SalvageValueStorageAtEndOfPeriod1 for creation.", quiet)
# END: SI6_SalvageValueStorageAtEndOfPeriod1.

# BEGIN: SI7_SalvageValueStorageAtEndOfPeriod2.
si7_salvagevaluestorageatendofperiod2::Array{AbstractConstraint, 1} = Array{AbstractConstraint, 1}()

t = Threads.@spawn(begin
    # Salvage values are figured as of last scenario year
    for row in SQLite.DBInterface.execute(db, "select r.val as r, s.val as s, y.val as y, cast(ols.val as real) as ols
    from region r, storage s, year y, DepreciationMethod_def dm, OperationalLifeStorage_def ols, DiscountRate_def dr
    where dm.r = r.val and dm.val = 1
    $(restrictyears ? "and y.val in" * inyears : "")
    and ols.r = r.val and ols.s = s.val
    and y.val + ols.val - 1 > " * string(lastscenarioyear) *
    " and dr.r = r.val and dr.val = 0
    union
    select r.val as r, s.val as s, y.val as y, cast(ols.val as real) as ols
    from region r, storage s, year y, DepreciationMethod_def dm, OperationalLifeStorage_def ols
    where dm.r = r.val and dm.val = 2
    $(restrictyears ? "and y.val in" * inyears : "")
    and ols.r = r.val and ols.s = s.val
    and y.val + ols.val - 1 > " * string(lastscenarioyear))
        local r = row[:r]
        local s = row[:s]
        local y = row[:y]

        push!(si7_salvagevaluestorageatendofperiod2, @build_constraint(vcapitalinvestmentstorage[r,s,y] * (1 - (lastscenarioyear - Meta.parse(y) + 1) / row[:ols]) == vsalvagevaluestorage[r,s,y]))
    end

    put!(cons_channel, si7_salvagevaluestorageatendofperiod2)
end)

numconsarrays += 1
logmsg("Queued constraint SI7_SalvageValueStorageAtEndOfPeriod2 for creation.", quiet)
# END: SI7_SalvageValueStorageAtEndOfPeriod2.

# BEGIN: SI8_SalvageValueStorageAtEndOfPeriod3.
si8_salvagevaluestorageatendofperiod3::Array{AbstractConstraint, 1} = Array{AbstractConstraint, 1}()

t = Threads.@spawn(begin
    # Salvage values are figured as of last scenario year
    for row in SQLite.DBInterface.execute(db, "select r.val as r, s.val as s, y.val as y, cast(dr.val as real) as dr, cast(ols.val as real) as ols
    from region r, storage s, year y, DepreciationMethod_def dm, OperationalLifeStorage_def ols, DiscountRate_def dr
    where dm.r = r.val and dm.val = 1
    and ols.r = r.val and ols.s = s.val
    $(restrictyears ? "and y.val in" * inyears : "")
    and y.val + ols.val - 1 > " * string(lastscenarioyear) *
    " and dr.r = r.val and dr != 0")
        local r = row[:r]
        local s = row[:s]
        local y = row[:y]
        local dr = row[:dr]

        push!(si8_salvagevaluestorageatendofperiod3, @build_constraint(vcapitalinvestmentstorage[r,s,y] * (1 - (((1 + dr)^(lastscenarioyear - Meta.parse(y) + 1) - 1) / ((1 + dr)^(row[:ols]) - 1))) == vsalvagevaluestorage[r,s,y]))
    end

    put!(cons_channel, si8_salvagevaluestorageatendofperiod3)
end)

numconsarrays += 1
logmsg("Queued constraint SI8_SalvageValueStorageAtEndOfPeriod3 for creation.", quiet)
# END: SI8_SalvageValueStorageAtEndOfPeriod3.

# BEGIN: SI9_SalvageValueStorageDiscountedToStartYear.
si9_salvagevaluestoragediscountedtostartyear::Array{AbstractConstraint, 1} = Array{AbstractConstraint, 1}()

t = Threads.@spawn(begin
    for row in SQLite.DBInterface.execute(db, "select r.val as r, s.val as s, y.val as y, cast(dr.val as real) dr
    from region r, storage s, year y, DiscountRate_def dr
    where dr.r = r.val $(restrictyears ? "and y.val in" * inyears : "")")
        local r = row[:r]
        local s = row[:s]
        local y = row[:y]

        push!(si9_salvagevaluestoragediscountedtostartyear, @build_constraint(vsalvagevaluestorage[r,s,y] / ((1 + row[:dr])^(lastscenarioyear - firstscenarioyear + 1)) == vdiscountedsalvagevaluestorage[r,s,y]))
    end

    put!(cons_channel, si9_salvagevaluestoragediscountedtostartyear)
end)

numconsarrays += 1
logmsg("Queued constraint SI9_SalvageValueStorageDiscountedToStartYear for creation.", quiet)
# END: SI9_SalvageValueStorageDiscountedToStartYear.

# BEGIN: SI10_TotalDiscountedCostByStorage.
si10_totaldiscountedcostbystorage::Array{AbstractConstraint, 1} = Array{AbstractConstraint, 1}()

t = Threads.@spawn(begin
    for (r, s, y) in Base.product(sregion, sstorage, syear)
        push!(si10_totaldiscountedcostbystorage, @build_constraint(vdiscountedcapitalinvestmentstorage[r,s,y] - vdiscountedsalvagevaluestorage[r,s,y] == vtotaldiscountedstoragecost[r,s,y]))
    end

    put!(cons_channel, si10_totaldiscountedcostbystorage)
end)

numconsarrays += 1
logmsg("Queued constraint SI10_TotalDiscountedCostByStorage for creation.", quiet)
# END: SI10_TotalDiscountedCostByStorage.

# BEGIN: CC1a_FinancingTechnology.
# Total financing costs discounted to year new capacity is deployed; assumes capital costs are financed at interest rate and repaid in equal installments over life of technology (payments occur at year's end)
cc1a_financingtechnology::Array{AbstractConstraint, 1} = Array{AbstractConstraint, 1}()

t = Threads.@spawn(begin
    for row in SQLite.DBInterface.execute(db, "select r.val as r, t.val as t, y.val as y, cast(cc.val as real) as cc,
    cast(ol.val as real) as ol, cast(dr.val as real) as dr, cast(irt.val as real) as irt
    from region r, technology t, year y, CapitalCost_def cc, OperationalLife_def ol, DiscountRate_def dr, InterestRateTechnology_def irt
    where cc.r = r.val and cc.t = t.val and cc.y = y.val
    $(restrictyears ? "and y.val in" * inyears : "")
    and ol.r = r.val and ol.t = t.val
    and dr.r = r.val
    and irt.r = r.val and irt.t = t.val and irt.y = y.val and irt.val is not null and irt.val <> 0")
        local r = row[:r]
        local t = row[:t]
        local y = row[:y]
        local ol = row[:ol]
        local dr = row[:dr]
        local irt = row[:irt]

        push!(cc1a_financingtechnology, @build_constraint(row[:cc] * vnewcapacity[r,t,y] * (irt / (1 - (1 + irt)^(-ol)) - 1/ol)
            * (1 - (1 + dr)^(-ol)) / dr == vfinancecost[r,t,y]))
    end

    put!(cons_channel, cc1a_financingtechnology)
end)

numconsarrays += 1
logmsg("Queued constraint CC1a_FinancingTechnology for creation.", quiet)
# END: CC1a_FinancingTechnology.

# BEGIN: CC1_UndiscountedCapitalInvestment.
cc1_undiscountedcapitalinvestment::Array{AbstractConstraint, 1} = Array{AbstractConstraint, 1}()

t = Threads.@spawn(begin
    for row in SQLite.DBInterface.execute(db, "select r.val as r, t.val as t, y.val as y, cast(cc.val as real) as cc
    from region r, technology t, year y, CapitalCost_def cc
    where cc.r = r.val and cc.t = t.val and cc.y = y.val $(restrictyears ? "and y.val in" * inyears : "")")
        local r = row[:r]
        local t = row[:t]
        local y = row[:y]

        push!(cc1_undiscountedcapitalinvestment, @build_constraint(row[:cc] * vnewcapacity[r,t,y]
            + vfinancecost[r,t,y] == vcapitalinvestment[r,t,y]))
    end

    put!(cons_channel, cc1_undiscountedcapitalinvestment)
end)

numconsarrays += 1
logmsg("Queued constraint CC1_UndiscountedCapitalInvestment for creation.", quiet)
# END: CC1_UndiscountedCapitalInvestment.

# BEGIN: CC1aTr_FinancingTransmission.
# Total financing costs discounted to year new capacity is deployed; assumes capital costs are financed at interest rate and repaid in equal installments over life of transmission line (payments occur at year's end)
if transmissionmodeling
    cc1atr_financingtransmission::Array{AbstractConstraint, 1} = Array{AbstractConstraint, 1}()

    t = Threads.@spawn(begin
        for row in SQLite.DBInterface.execute(db, "select tl.id as tr, y.val as y, cast(tl.CapitalCost as real) as cc,
            cast(tl.operationallife as integer) as ol, cast(dr.val as real) as dr, cast(tl.interestrate as real) as irt
        	from TransmissionLine tl, YEAR y, NODE n, DiscountRate_def dr
            where
        	tl.CapitalCost is not null and tl.operationallife is not null and tl.interestrate is not null and tl.interestrate <> 0
        	$(restrictyears ? "and y.val in" * inyears : "")
        	and tl.n1 = n.val
        	and n.r = dr.r")
            local tr = row[:tr]
            local y = row[:y]
            local ol = row[:ol]
            local dr = row[:dr]
            local irt = row[:irt]

            push!(cc1atr_financingtransmission, @build_constraint(row[:cc] * vtransmissionbuilt[tr,y] * (irt / (1 - (1 + irt)^(-ol)) - 1/ol)
                * (1 - (1 + dr)^(-ol)) / dr == vfinancecosttransmission[tr,y]))
        end

        put!(cons_channel, cc1atr_financingtransmission)
    end)

    numconsarrays += 1
    logmsg("Queued constraint CC1aTr_FinancingTransmission for creation.", quiet)
end
# END: CC1aTr_FinancingTransmission.

# BEGIN: CC1Tr_UndiscountedCapitalInvestment.
if transmissionmodeling
    cc1tr_undiscountedcapitalinvestment::Array{AbstractConstraint, 1} = Array{AbstractConstraint, 1}()

    t = Threads.@spawn(begin
        for row in SQLite.DBInterface.execute(db, "select tl.id as tr, y.val as y, cast(tl.CapitalCost as real) as cc from
        TransmissionLine tl, YEAR y
        where tl.CapitalCost is not null $(restrictyears ? "and y.val in" * inyears : "")")
            local tr = row[:tr]
            local y = row[:y]

            push!(cc1tr_undiscountedcapitalinvestment, @build_constraint(row[:cc] * vtransmissionbuilt[tr,y]
                + vfinancecosttransmission[tr,y] == vcapitalinvestmenttransmission[tr,y]))
        end

        put!(cons_channel, cc1tr_undiscountedcapitalinvestment)
    end)

    numconsarrays += 1
    logmsg("Queued constraint CC1Tr_UndiscountedCapitalInvestment for creation.", quiet)
end
# END: CC1Tr_UndiscountedCapitalInvestment.

# BEGIN: CC2_DiscountingCapitalInvestment.
cc2_discountingcapitalinvestment::Array{AbstractConstraint, 1} = Array{AbstractConstraint, 1}()

t = Threads.@spawn(let
    local sumexps = Array{AffExpr, 1}([AffExpr()])  # sumexps[1] = sum of discounted costs over interval ending in y

    # When modeling selected years, discounted costs assume linear investment over each year's interval
    for row in DataFrames.eachrow(queries["queryrtydr"])
        local r = row[:r]
        local t = row[:t]
        local y = row[:y]

        for i = 0:(yearintervalsdict[y]-1)
            add_to_expression!(sumexps[1], vcapitalinvestment[r,t,y] / yearintervalsdict[y]
                / ((1 + row[:dr])^(Meta.parse(y) - i - firstscenarioyear)))
        end

        push!(cc2_discountingcapitalinvestment, @build_constraint(sumexps[1] == vdiscountedcapitalinvestment[r,t,y]))
        sumexps[1] = AffExpr()
    end

    put!(cons_channel, cc2_discountingcapitalinvestment)
end)

numconsarrays += 1
logmsg("Queued constraint CC2_DiscountingCapitalInvestment for creation.", quiet)
# END: CC2_DiscountingCapitalInvestment.

# BEGIN: CC2Tr_DiscountingCapitalInvestment.
if transmissionmodeling
    # Note: if a transmission line crosses regional boundaries, costs are assigned to from region (associated with n1)
    cc2tr_discountingcapitalinvestment::Array{AbstractConstraint, 1} = Array{AbstractConstraint, 1}()

    t = Threads.@spawn(let
        local sumexps = Array{AffExpr, 1}([AffExpr()])  # sumexps[1] = sum of discounted costs over interval ending in y

        # When modeling selected years, discounted costs assume linear investment over each year's interval if continuoustransmission is true
        for row in DataFrames.eachrow(queries["querytrydr"])
            local tr = row[:tr]
            local y = row[:y]

            if !continuoustransmission
                add_to_expression!(sumexps[1], vcapitalinvestmenttransmission[tr,y] / ((1 + row[:dr])^(Meta.parse(y) - firstscenarioyear)))
            else
                for i = 0:(yearintervalsdict[y]-1)
                    add_to_expression!(sumexps[1], vcapitalinvestmenttransmission[tr,y] / yearintervalsdict[y]
                        / ((1 + row[:dr])^(Meta.parse(y) - i - firstscenarioyear)))
                end
            end

            push!(cc2tr_discountingcapitalinvestment, @build_constraint(sumexps[1] == vdiscountedcapitalinvestmenttransmission[tr,y]))
            sumexps[1] = AffExpr()
        end

        put!(cons_channel, cc2tr_discountingcapitalinvestment)
    end)

    numconsarrays += 1
    logmsg("Queued constraint CC2Tr_DiscountingCapitalInvestment for creation.", quiet)
end
# END: CC2Tr_DiscountingCapitalInvestment.

# BEGIN: SV1_SalvageValueAtEndOfPeriod1.
# DepreciationMethod 1 (if discount rate > 0): base salvage value on % of discounted value remaining at end of modeling period.
# DepreciationMethod 2 (or dm 1 if discount rate = 0): base salvage value on % of operational life remaining at end of modeling period.
# Salvage values are figured as of last scenario year
sv1_salvagevalueatendofperiod1::Array{AbstractConstraint, 1} = Array{AbstractConstraint, 1}()

t = Threads.@spawn(begin
    for row in SQLite.DBInterface.execute(db, "select r.val as r, t.val as t, y.val as y, cast(cc.val as real) as cc,
        cast(dr.val as real) as dr, cast(ol.val as real) as ol
    from region r, technology t, year y, DepreciationMethod_def dm, OperationalLife_def ol, CapitalCost_def cc, DiscountRate_def dr
    where dm.r = r.val and dm.val = 1
    and ol.r = r.val and ol.t = t.val
    and y.val + ol.val - 1 > " * string(lastscenarioyear) *
    " and cc.r = r.val and cc.t = t.val and cc.y = y.val
    $(restrictyears ? "and y.val in" * inyears : "")
    and dr.r = r.val and dr.val <> 0")
        local r = row[:r]
        local t = row[:t]
        local y = row[:y]
        local dr = row[:dr]

        push!(sv1_salvagevalueatendofperiod1, @build_constraint(vsalvagevalue[r,t,y] ==
            vcapitalinvestment[r,t,y] * (1 - (((1 + dr)^(lastscenarioyear - Meta.parse(y) + 1) - 1) / ((1 + dr)^(row[:ol]) - 1)))))
    end

    put!(cons_channel, sv1_salvagevalueatendofperiod1)
end)

numconsarrays += 1
logmsg("Queued constraint SV1_SalvageValueAtEndOfPeriod1 for creation.", quiet)
# END: SV1_SalvageValueAtEndOfPeriod1.

# BEGIN: SV1Tr_SalvageValueAtEndOfPeriod1.
if transmissionmodeling
    sv1tr_salvagevalueatendofperiod1::Array{AbstractConstraint, 1} = Array{AbstractConstraint, 1}()

    t = Threads.@spawn(begin
        for row in SQLite.DBInterface.execute(db, "select tl.id as tr, y.val as y, cast(tl.CapitalCost as real) as cc,
    	cast(tl.operationallife as real) as ol, cast(dr.val as real) as dr
    	from TransmissionLine tl, NODE n, YEAR y, DepreciationMethod_def dm, DiscountRate_def dr
        where tl.CapitalCost is not null
    	and tl.n1 = n.val
    	and dm.r = n.r and dm.val = 1
    	and y.val + tl.operationallife - 1 > " * string(lastscenarioyear) *
    	" $(restrictyears ? "and y.val in" * inyears : "")
    	and dr.r = n.r and dr.val <> 0")
            local tr = row[:tr]
            local y = row[:y]
            local dr = row[:dr]

            push!(sv1tr_salvagevalueatendofperiod1, @build_constraint(vsalvagevaluetransmission[tr,y] ==
                vcapitalinvestmenttransmission[tr,y] * (1 - (((1 + dr)^(lastscenarioyear - Meta.parse(y) + 1) - 1) / ((1 + dr)^(row[:ol]) - 1)))))
        end

        put!(cons_channel, sv1tr_salvagevalueatendofperiod1)
    end)

    numconsarrays += 1
    logmsg("Queued constraint SV1Tr_SalvageValueAtEndOfPeriod1 for creation.", quiet)
end
# END: SV1Tr_SalvageValueAtEndOfPeriod1.

# BEGIN: SV2_SalvageValueAtEndOfPeriod2.
sv2_salvagevalueatendofperiod2::Array{AbstractConstraint, 1} = Array{AbstractConstraint, 1}()

t = Threads.@spawn(begin
    for row in SQLite.DBInterface.execute(db, "select r.val as r, t.val as t, y.val as y, cast(cc.val as real) as cc, cast(ol.val as real) as ol
    from region r, technology t, year y, DepreciationMethod_def dm, OperationalLife_def ol, CapitalCost_def cc, DiscountRate_def dr
    where dm.r = r.val and dm.val = 1
    $(restrictyears ? "and y.val in" * inyears : "")
    and ol.r = r.val and ol.t = t.val
    and y.val + ol.val - 1 > " * string(lastscenarioyear) *
    " and cc.r = r.val and cc.t = t.val and cc.y = y.val
    and dr.r = r.val and dr.val = 0
    union
    select r.val as r, t.val as t, y.val as y, cast(cc.val as real) as cc, cast(ol.val as real) as ol
    from region r, technology t, year y, DepreciationMethod_def dm, OperationalLife_def ol,
    CapitalCost_def cc
    where dm.r = r.val and dm.val = 2
    $(restrictyears ? "and y.val in" * inyears : "")
    and ol.r = r.val and ol.t = t.val
    and y.val + ol.val - 1 > " * string(lastscenarioyear) *
    " and cc.r = r.val and cc.t = t.val and cc.y = y.val")
        local r = row[:r]
        local t = row[:t]
        local y = row[:y]

        push!(sv2_salvagevalueatendofperiod2, @build_constraint(vsalvagevalue[r,t,y] ==
            vcapitalinvestment[r,t,y] * (1 - (lastscenarioyear - Meta.parse(y) + 1) / row[:ol])))
    end

    put!(cons_channel, sv2_salvagevalueatendofperiod2)
end)

numconsarrays += 1
logmsg("Queued constraint SV2_SalvageValueAtEndOfPeriod2 for creation.", quiet)
# END: SV2_SalvageValueAtEndOfPeriod2.

# BEGIN: SV2Tr_SalvageValueAtEndOfPeriod2.
if transmissionmodeling
    sv2tr_salvagevalueatendofperiod2::Array{AbstractConstraint, 1} = Array{AbstractConstraint, 1}()

    t = Threads.@spawn(begin
        for row in SQLite.DBInterface.execute(db, "select tl.id as tr, y.val as y, cast(tl.CapitalCost as real) as cc,
    	cast(tl.operationallife as real) as ol
    	from TransmissionLine tl, NODE n, YEAR y, DepreciationMethod_def dm, DiscountRate_def dr
        where tl.CapitalCost is not null
    	and tl.n1 = n.val
    	and dm.r = n.r
        $(restrictyears ? "and y.val in" * inyears : "")
    	and y.val + tl.operationallife - 1 > " * string(lastscenarioyear) *
    	" and dr.r = n.r
        and ((dm.val = 1 and dr.val = 0) or (dm.val = 2))")
            local tr = row[:tr]
            local y = row[:y]

            push!(sv2tr_salvagevalueatendofperiod2, @build_constraint(vsalvagevaluetransmission[tr,y] ==
                vcapitalinvestmenttransmission[tr,y] * (1 - (lastscenarioyear - Meta.parse(y) + 1) / row[:ol])))
        end

        put!(cons_channel, sv2tr_salvagevalueatendofperiod2)
    end)

    numconsarrays += 1
    logmsg("Queued constraint SV2Tr_SalvageValueAtEndOfPeriod2 for creation.", quiet)
end
# END: SV2Tr_SalvageValueAtEndOfPeriod2.

# BEGIN: SV3_SalvageValueAtEndOfPeriod3.
sv3_salvagevalueatendofperiod3::Array{AbstractConstraint, 1} = Array{AbstractConstraint, 1}()

t = Threads.@spawn(begin
    for row in SQLite.DBInterface.execute(db, "select r.val as r, t.val as t, y.val as y
    from region r, technology t, year y, OperationalLife_def ol
    where ol.r = r.val and ol.t = t.val
    $(restrictyears ? "and y.val in" * inyears : "")
    and y.val + ol.val - 1 <= " * string(lastscenarioyear))
        local r = row[:r]
        local t = row[:t]
        local y = row[:y]

        push!(sv3_salvagevalueatendofperiod3, @build_constraint(vsalvagevalue[r,t,y] == 0))
    end

    put!(cons_channel, sv3_salvagevalueatendofperiod3)
end)

numconsarrays += 1
logmsg("Queued constraint SV3_SalvageValueAtEndOfPeriod3 for creation.", quiet)
# END: SV3_SalvageValueAtEndOfPeriod3.

# BEGIN: SV3Tr_SalvageValueAtEndOfPeriod3.
if transmissionmodeling
    sv3tr_salvagevalueatendofperiod3::Array{AbstractConstraint, 1} = Array{AbstractConstraint, 1}()

    t = Threads.@spawn(begin
        for row in SQLite.DBInterface.execute(db, "select tl.id as tr, y.val as y
    	from TransmissionLine tl, YEAR y
        where tl.CapitalCost is not null
        $(restrictyears ? "and y.val in" * inyears : "")
    	and y.val + tl.operationallife - 1 <= " * string(lastscenarioyear))
            local tr = row[:tr]
            local y = row[:y]

            push!(sv3tr_salvagevalueatendofperiod3, @build_constraint(vsalvagevaluetransmission[tr,y] == 0))
        end

        put!(cons_channel, sv3tr_salvagevalueatendofperiod3)
    end)

    numconsarrays += 1
    logmsg("Queued constraint SV3Tr_SalvageValueAtEndOfPeriod3 for creation.", quiet)
end
# END: SV3Tr_SalvageValueAtEndOfPeriod3.

# BEGIN: SV4_SalvageValueDiscountedToStartYear.
sv4_salvagevaluediscountedtostartyear::Array{AbstractConstraint, 1} = Array{AbstractConstraint, 1}()

t = Threads.@spawn(begin
    for row in DataFrames.eachrow(queries["queryrtydr"])
        local r = row[:r]
        local t = row[:t]
        local y = row[:y]

        push!(sv4_salvagevaluediscountedtostartyear, @build_constraint(vdiscountedsalvagevalue[r,t,y] ==
            vsalvagevalue[r,t,y] / ((1 + row[:dr])^(1 + lastscenarioyear - firstscenarioyear))))
    end

    put!(cons_channel, sv4_salvagevaluediscountedtostartyear)
end)

numconsarrays += 1
logmsg("Queued constraint SV4_SalvageValueDiscountedToStartYear for creation.", quiet)
# END: SV4_SalvageValueDiscountedToStartYear.

# BEGIN: SV4Tr_SalvageValueDiscountedToStartYear.
if transmissionmodeling
    sv4tr_salvagevaluediscountedtostartyear::Array{AbstractConstraint, 1} = Array{AbstractConstraint, 1}()

    t = Threads.@spawn(begin
        for row in DataFrames.eachrow(queries["querytrydr"])
            local tr = row[:tr]
            local y = row[:y]

            push!(sv4tr_salvagevaluediscountedtostartyear, @build_constraint(vdiscountedsalvagevaluetransmission[tr,y] ==
                vsalvagevaluetransmission[tr,y] / ((1 + row[:dr])^(1 + lastscenarioyear - firstscenarioyear))))
        end

        put!(cons_channel, sv4tr_salvagevaluediscountedtostartyear)
    end)

    numconsarrays += 1
    logmsg("Queued constraint SV4Tr_SalvageValueDiscountedToStartYear for creation.", quiet)
end
# END: SV4Tr_SalvageValueDiscountedToStartYear.

# BEGIN: OC1_OperatingCostsVariable.
oc1_operatingcostsvariable::Array{AbstractConstraint, 1} = Array{AbstractConstraint, 1}()

t = Threads.@spawn(let
    local lastkeys = Array{String, 1}(undef,3)  # lastkeys[1] = r, lastkeys[2] = t, lastkeys[3] = y
    local sumexps = Array{AffExpr, 1}([AffExpr()])  # sumexps[1] = vtotalannualtechnologyactivitybymode sum

    for row in SQLite.DBInterface.execute(db, "select r.val as r, t.val as t, y.val as y, vc.m as m, cast(vc.val as real) as vc
    from region r, technology t, year y, VariableCost_def vc
    where vc.r = r.val and vc.t = t.val and vc.y = y.val
    and vc.val <> 0
    $(restrictyears ? "and y.val in" * inyears : "")
    order by r.val, t.val, y.val")
        local r = row[:r]
        local t = row[:t]
        local y = row[:y]

        if isassigned(lastkeys, 1) && (r != lastkeys[1] || t != lastkeys[2] || y != lastkeys[3])
            # Create constraint
            push!(oc1_operatingcostsvariable, @build_constraint(sumexps[1] ==
                vannualvariableoperatingcost[lastkeys[1],lastkeys[2],lastkeys[3]]))
            sumexps[1] = AffExpr()
        end

        add_to_expression!(sumexps[1], vtotalannualtechnologyactivitybymode[r,t,row[:m],y] * row[:vc])

        lastkeys[1] = r
        lastkeys[2] = t
        lastkeys[3] = y
    end

    # Create last constraint
    if isassigned(lastkeys, 1)
        push!(oc1_operatingcostsvariable, @build_constraint(sumexps[1] ==
            vannualvariableoperatingcost[lastkeys[1],lastkeys[2],lastkeys[3]]))
    end

    put!(cons_channel, oc1_operatingcostsvariable)
end)

numconsarrays += 1
logmsg("Queued constraint OC1_OperatingCostsVariable for creation.", quiet)
# END: OC1_OperatingCostsVariable.

# BEGIN: OC2_OperatingCostsFixedAnnual.
oc2_operatingcostsfixedannual::Array{AbstractConstraint, 1} = Array{AbstractConstraint, 1}()

t = Threads.@spawn(begin
    for row in SQLite.DBInterface.execute(db, "select r.val as r, t.val as t, y.val as y, cast(fc.val as real) as fc
    from region r, technology t, year y, FixedCost_def fc
    where fc.r = r.val and fc.t = t.val and fc.y = y.val
    $(restrictyears ? "and y.val in" * inyears : "")")
        local r = row[:r]
        local t = row[:t]
        local y = row[:y]

        push!(oc2_operatingcostsfixedannual, @build_constraint(vtotalcapacityannual[r,t,y] * row[:fc] == vannualfixedoperatingcost[r,t,y]))
    end

    put!(cons_channel, oc2_operatingcostsfixedannual)
end)

numconsarrays += 1
logmsg("Queued constraint OC2_OperatingCostsFixedAnnual for creation.", quiet)
# END: OC2_OperatingCostsFixedAnnual.

# BEGIN: OC3_OperatingCostsTotalAnnual.
oc3_operatingcoststotalannual::Array{AbstractConstraint, 1} = Array{AbstractConstraint, 1}()

t = Threads.@spawn(begin
    for (r, t, y) in Base.product(sregion, stechnology, syear)
        push!(oc3_operatingcoststotalannual, @build_constraint(vannualfixedoperatingcost[r,t,y] + vannualvariableoperatingcost[r,t,y] == voperatingcost[r,t,y]))
    end

    put!(cons_channel, oc3_operatingcoststotalannual)
end)

numconsarrays += 1
logmsg("Queued constraint OC3_OperatingCostsTotalAnnual for creation.", quiet)
# END: OC3_OperatingCostsTotalAnnual.

# BEGIN: OCTr_VariableCosts.
if transmissionmodeling
    octr_variablecosts::Array{AbstractConstraint, 1} = Array{AbstractConstraint, 1}()

    t = Threads.@spawn(let
        local lastkeys = Array{String, 1}(undef,2)  # lastkeys[1] = tr, lastkeys[2] = y
        local sumexps = Array{AffExpr, 1}([AffExpr()])  # sumexps[1] = vvariablecosttransmissionbyts sum

        for row in DataFrames.eachrow(filter(row -> row.vc > 0, queries["queryvtransmissionbyline"]))
            local tr = row[:tr]
            local y = row[:y]

            if isassigned(lastkeys, 1) && (tr != lastkeys[1] || y != lastkeys[2])
                # Create constraint
                push!(octr_variablecosts, @build_constraint(vvariablecosttransmission[lastkeys[1],lastkeys[2]] == sumexps[1]))
                sumexps[1] = AffExpr()
            end

            add_to_expression!(sumexps[1], vvariablecosttransmissionbyts[tr,row[:l],row[:f],y])

            lastkeys[1] = tr
            lastkeys[2] = y
        end

        # Create last constraint
        if isassigned(lastkeys, 1)
            push!(octr_variablecosts, @build_constraint(vvariablecosttransmission[lastkeys[1],lastkeys[2]] == sumexps[1]))
        end

        put!(cons_channel, octr_variablecosts)
    end)

    numconsarrays += 1
    logmsg("Queued constraint OCTr_VariableCosts for creation.", quiet)
end
# END: OCTr_VariableCosts.

# BEGIN: OCTr_OperatingCosts.
if transmissionmodeling
    octr_operatingcosts::Array{AbstractConstraint, 1} = Array{AbstractConstraint, 1}()

    t = Threads.@spawn(begin
        for row in SQLite.DBInterface.execute(db, "select tl.id as tr, tme1.y as y,
            cast(tl.VariableCost as real) as vc, cast(tl.fixedcost as real) as fc
            from TransmissionLine tl, NODE n1, NODE n2, TransmissionModelingEnabled tme1,
            TransmissionModelingEnabled tme2, TransmissionCapacityToActivityUnit_def tcta
            where
            tl.n1 = n1.val and tl.n2 = n2.val
            and tme1.r = n1.r and tme1.f = tl.f
            and tme2.r = n2.r and tme2.f = tl.f
            and tme1.y = tme2.y and tme1.type = tme2.type
        	and exists (select 1 from YearSplit_def ys where ys.y = tme1.y)
    		$(restrictyears ? "and tme1.y in" * inyears : "")
        	and tcta.r = n1.r and tl.f = tcta.f")
            local tr = row[:tr]
            local y = row[:y]
            local vc = ismissing(row[:vc]) ? 0.0 : row[:vc]
            local fc = ismissing(row[:fc]) ? 0.0 : row[:fc]

            # Note: if a transmission line has efficiency < 1, variable costs are based on energy entering line
            push!(octr_operatingcosts, @build_constraint((vc > 0 ? vvariablecosttransmission[tr,y] : 0)
                + vtransmissionexists[tr,y] * fc == voperatingcosttransmission[tr,y]))
        end

        put!(cons_channel, octr_operatingcosts)
    end)

    numconsarrays += 1
    logmsg("Queued constraint OCTr_OperatingCosts for creation.", quiet)
end
# END: OCTr_OperatingCosts.

# BEGIN: OC4_DiscountedOperatingCostsTotalAnnual.
oc4_discountedoperatingcoststotalannual::Array{AbstractConstraint, 1} = Array{AbstractConstraint, 1}()

t = Threads.@spawn(let
    local sumexps = Array{AffExpr, 1}([AffExpr(), AffExpr()])  # sumexps[1] = sum of estimated fixed costs in non-modeled years, sumexps[2] = sum of estimated variable costs in non-modeled years
    local lastkeys = Array{String, 1}(undef,4)  # lastkeys[1] = r, lastkeys[2] = t, lastkeys[3] = y, lastkeys[4] = prev_y
    local lastvals = Array{Float64, 1}(undef,3)  # lastvals[1] = dr, lastvals[2] = fsy_rtc, lastvals[3] = fc
    local lastvalsint = Array{Int64, 1}(undef,2)  # lastvalsint[1] = yint, lastvalsint[2] = nyears

    for row in SQLite.DBInterface.execute(db, "select r.val as r, t.val as t, y.val as y, vc.m as m, y.prev_y,
    cast(dr.val as real) as dr, cast(rtc.val as real) as fsy_rtc, cast(fc.val as real) as fc,
    cast(vc.val as real) as vc
    from region r, TECHNOLOGY t,
    	(select y.val, lag(y.val) over (order by y.val) as prev_y from year y
            $(restrictyears ? "where y.val in" * inyears : "")
    	) as y, DiscountRate_def dr
    left join ResidualCapacity_def rtc on rtc.r = r.val and rtc.t = t.val and rtc.y = $firstscenarioyear
    left join FixedCost_def fc on fc.r = r.val and fc.t = t.val and fc.y = y.val
    left join VariableCost_def vc on vc.r = r.val and vc.t = t.val and vc.y = y.val and vc.val <> 0
    WHERE dr.r = r.val
    order by r.val, t.val, y.val")
        local r = row[:r]
        local t = row[:t]
        local y = row[:y]
        local yint::Int64 = Meta.parse(y)
        local prev_y = row[:prev_y]
        local dr = row[:dr]
        local nyears::Int64 = (ismissing(prev_y) ? yint - firstscenarioyear : yint - Meta.parse(prev_y) - 1)  # Number of years in y's interval, excluding y

        if isassigned(lastkeys, 1) && (r != lastkeys[1] || t != lastkeys[2] || y != lastkeys[3])
            # Create constraint
            local pcapacity  # Capacity for r & t at start of y's interval

            # When selected years are modeled, add estimated fixed costs in non-modeled years to discounted operating costs. Assume linear deployment of capacity over modeled intervals.
            if !ismissing(lastvals[3])
                if lastkeys[4] == ""
                    # Residual capacity at start of scenario period
                    pcapacity = (ismissing(lastvals[2]) ? 0 : lastvals[2])
                else
                    # Capacity in previous modeled year
                    pcapacity = vtotalcapacityannual[lastkeys[1], lastkeys[2], lastkeys[4]]
                end

                for i = 1:lastvalsint[2]
                    # Processing all years in interval before y; fixed costs for y itself are already included in voperatingcost
                    add_to_expression!(sumexps[1], (pcapacity + (vtotalcapacityannual[lastkeys[1],lastkeys[2],lastkeys[3]] - pcapacity) / (lastvalsint[2] + 1) * (lastvalsint[2] + 1 - i))
                        * lastvals[3] / ((1 + lastvals[1])^(lastvalsint[1] - i - firstscenarioyear + 0.5)))
                end
            end

            push!(oc4_discountedoperatingcoststotalannual, @build_constraint(sumexps[1] + sumexps[2]
                + voperatingcost[lastkeys[1],lastkeys[2],lastkeys[3]] / ((1 + lastvals[1])^(lastvalsint[1] - firstscenarioyear + 0.5))
                == vdiscountedoperatingcost[lastkeys[1],lastkeys[2],lastkeys[3]]))

            sumexps[1] = AffExpr()
            sumexps[2] = AffExpr()
        end

        # When selected years are modeled, add estimated variable costs in non-modeled years to discounted operating costs. Assume linear scaling of activity over modeled intervals (for years before first modeled year, assume constant activity).
        if !ismissing(row[:vc])
            local pactivity  # Activity for r, t, & m at start of y's interval

            if ismissing(prev_y)
                pactivity = vtotalannualtechnologyactivitybymode[r,t,row[:m],y]
            else
                pactivity = vtotalannualtechnologyactivitybymode[r,t,row[:m],prev_y]
            end

            for i = 1:nyears
                # Processing all years in interval before y; variable costs for y itself are already included in voperatingcost
                add_to_expression!(sumexps[2], (pactivity + (vtotalannualtechnologyactivitybymode[r,t,row[:m],y] - pactivity) / (nyears + 1) * (nyears + 1 - i))
                    * row[:vc] / ((1 + dr)^(yint - i - firstscenarioyear + 0.5)))
            end
        end

        lastkeys[1] = r
        lastkeys[2] = t
        lastkeys[3] = y
        lastkeys[4] = (ismissing(prev_y) ? "" : prev_y)
        lastvals[1] = dr
        lastvals[2] = row[:fsy_rtc]
        lastvals[3] = row[:fc]
        lastvalsint[1] = yint
        lastvalsint[2] = nyears
    end

    # Create last constraint
    if isassigned(lastkeys, 1)
        # Create constraint
        local pcapacity  # Capacity for r & t at start of y's interval

        # When selected years are modeled, add estimated fixed costs in non-modeled years to discounted operating costs. Assume linear deployment of capacity over modeled intervals.
        if !ismissing(lastvals[3])
            if lastkeys[4] == ""
                # Residual capacity at start of scenario period
                pcapacity = (ismissing(lastvals[2]) ? 0 : lastvals[2])
            else
                # Capacity in previous modeled year
                pcapacity = vtotalcapacityannual[lastkeys[1], lastkeys[2], lastkeys[4]]
            end

            for i = 1:lastvalsint[2]
                # Processing all years in interval before y; fixed costs for y itself are already included in voperatingcost
                add_to_expression!(sumexps[1], (pcapacity + (vtotalcapacityannual[lastkeys[1],lastkeys[2],lastkeys[3]] - pcapacity) / (lastvalsint[2] + 1) * (lastvalsint[2] + 1 - i))
                    * lastvals[3] / ((1 + lastvals[1])^(lastvalsint[1] - i - firstscenarioyear + 0.5)))
            end
        end

        push!(oc4_discountedoperatingcoststotalannual, @build_constraint(sumexps[1] + sumexps[2]
            + voperatingcost[lastkeys[1],lastkeys[2],lastkeys[3]] / ((1 + lastvals[1])^(lastvalsint[1] - firstscenarioyear + 0.5))
            == vdiscountedoperatingcost[lastkeys[1],lastkeys[2],lastkeys[3]]))
    end

    put!(cons_channel, oc4_discountedoperatingcoststotalannual)
end)

numconsarrays += 1
logmsg("Queued constraint OC4_DiscountedOperatingCostsTotalAnnual for creation.", quiet)
# END: OC4_DiscountedOperatingCostsTotalAnnual.

# BEGIN: OC4Tr_DiscountedOperatingCostsTotalAnnual.
if transmissionmodeling
    oc4tr_discountedoperatingcoststotalannual::Array{AbstractConstraint, 1} = Array{AbstractConstraint, 1}()

    t = Threads.@spawn(let
        local sumexps = Array{AffExpr, 1}([AffExpr(), AffExpr()])  # sumexps[1] = sum of estimated fixed costs in non-modeled years, sumexps[2] = sum of estimated variable costs in non-modeled years

        for row in SQLite.DBInterface.execute(db, "select tl.id as tr, tl.f as f, tme1.y as y, y.prev_y,
            cast(tl.VariableCost as real) as vc, cast(tl.fixedcost as real) as fc, tl.yconstruction, tl.operationallife as ol,
    		cast(dr.val as real) as dr
            from TransmissionLine tl, NODE n1, NODE n2, TransmissionModelingEnabled tme1,
            TransmissionModelingEnabled tme2, TransmissionCapacityToActivityUnit_def tcta,
    		(select y.val, lag(y.val) over (order by y.val) as prev_y from year y
    			$(restrictyears ? "where y.val in" * inyears : "")
    		) as y, DiscountRate_def dr
            where
            tl.n1 = n1.val and tl.n2 = n2.val
            and tme1.r = n1.r and tme1.f = tl.f
            and tme2.r = n2.r and tme2.f = tl.f
            and tme1.y = tme2.y and tme1.type = tme2.type
        	and exists (select 1 from YearSplit_def ys where ys.y = tme1.y)
        	and tcta.r = n1.r and tl.f = tcta.f
    		and tme1.y = y.val
            and dr.r = n1.r")

            local tr = row[:tr]
            local f = row[:f]
            local y = row[:y]
            local yint::Int64 = Meta.parse(y)
            local prev_y = row[:prev_y]
            local vc = ismissing(row[:vc]) ? 0.0 : row[:vc]
            local fc = ismissing(row[:fc]) ? 0.0 : row[:fc]
            local yconstruction = row[:yconstruction]
            local ol = row[:ol]
            local dr = row[:dr]
            local nyears::Int64 = (ismissing(prev_y) ? yint - firstscenarioyear : yint - Meta.parse(prev_y) - 1)  # Number of years in y's interval, excluding y

            # Add estimated fixed costs in non-modeled years to discounted operating costs; fixed costs for y itself are already included in voperatingcosttransmission
            if !ismissing(yconstruction)
                # Exogenously specified line
                for i = 1:nyears
                    if (yconstruction + ol) > (yint - i)
                        add_to_expression!(sumexps[1], fc / ((1 + dr)^(yint - i - firstscenarioyear + 0.5)))
                    end
                end
            elseif continuoustransmission
                # Endogenously built line - assume linear deployment of capacity over modeled intervals
                local pexists = (ismissing(prev_y) ? 0 : vtransmissionexists[tr, prev_y])  # Fraction of tr existing at start of y's interval

                for i = 1:nyears
                    add_to_expression!(sumexps[1], (pexists + (vtransmissionexists[tr,y] - pexists) / (nyears + 1) * (nyears + 1 - i))
                        * fc / ((1 + dr)^(yint - i - firstscenarioyear + 0.5)))
                end
            end

            # Add estimated variable costs in non-modeled years to discounted operating costs; variable costs for y itself are already included in voperatingcosttransmission. Assume linear scaling of activity over modeled intervals (for years before first modeled year, assume constant activity).
            if vc > 0
                local pactivity  # Activity for tr & f at start of y's interval

                if ismissing(prev_y)
                    pactivity = vvariablecosttransmission[tr,y] / vc
                else
                    pactivity = vvariablecosttransmission[tr,prev_y] / vc
                end

                for i = 1:nyears
                    add_to_expression!(sumexps[2], (pactivity + (vvariablecosttransmission[tr,y] / vc - pactivity) / (nyears + 1) * (nyears + 1 - i))
                        * vc / ((1 + dr)^(yint - i - firstscenarioyear + 0.5)))
                end
            end

            push!(oc4tr_discountedoperatingcoststotalannual, @build_constraint(sumexps[1] + sumexps[2]
                + voperatingcosttransmission[tr,y] / ((1 + dr)^(yint - firstscenarioyear + 0.5)) == vdiscountedoperatingcosttransmission[tr,y]))

            sumexps[1] = AffExpr()
            sumexps[2] = AffExpr()
        end

        put!(cons_channel, oc4tr_discountedoperatingcoststotalannual)
    end)

    numconsarrays += 1
    logmsg("Queued constraint OC4Tr_DiscountedOperatingCostsTotalAnnual for creation.", quiet)
end
# END: OC4Tr_DiscountedOperatingCostsTotalAnnual.

# BEGIN: TDC1_TotalDiscountedCostByTechnology.
tdc1_totaldiscountedcostbytechnology::Array{AbstractConstraint, 1} = Array{AbstractConstraint, 1}()

t = Threads.@spawn(begin
    for (r, t, y) in Base.product(sregion, stechnology, syear)
        push!(tdc1_totaldiscountedcostbytechnology, @build_constraint(vdiscountedoperatingcost[r,t,y] + vdiscountedcapitalinvestment[r,t,y]
            + vdiscountedtechnologyemissionspenalty[r,t,y] - vdiscountedsalvagevalue[r,t,y]
            == vtotaldiscountedcostbytechnology[r,t,y]))
    end

    put!(cons_channel, tdc1_totaldiscountedcostbytechnology)
end)

numconsarrays += 1
logmsg("Queued constraint TDC1_TotalDiscountedCostByTechnology for creation.", quiet)
# END: TDC1_TotalDiscountedCostByTechnology.

# BEGIN: TDCTr_TotalDiscountedTransmissionCostByRegion.
if transmissionmodeling
    tdctr_totaldiscountedtransmissioncostbyregion::Array{AbstractConstraint, 1} = Array{AbstractConstraint, 1}()

    t = Threads.@spawn(let
        local lastkeys = Array{String, 1}(undef,2)  # lastkeys[1] = r, lastkeys[2] = y
        local sumexps = Array{AffExpr, 1}([AffExpr()])  # sumexps[1] = costs sum

        for row in SQLite.DBInterface.execute(db, "select n.r as r, tl.id as tr, y.val as y
    	from TransmissionLine tl, NODE n, YEAR y
        where tl.n1 = n.val
        $(restrictyears ? "and y.val in" * inyears : "")
    	order by n.r, y.val")
            local r = row[:r]
            local y = row[:y]
            local tr = row[:tr]

            if isassigned(lastkeys, 1) && (r != lastkeys[1] || y != lastkeys[2])
                # Create constraint
                push!(tdctr_totaldiscountedtransmissioncostbyregion, @build_constraint(sumexps[1] == vtotaldiscountedtransmissioncostbyregion[lastkeys[1],lastkeys[2]]))
                sumexps[1] = AffExpr()
            end

            add_to_expression!(sumexps[1], vdiscountedcapitalinvestmenttransmission[tr,y] - vdiscountedsalvagevaluetransmission[tr,y]
                + vdiscountedoperatingcosttransmission[tr,y])

            lastkeys[1] = r
            lastkeys[2] = y
        end

        # Create last constraint
        if isassigned(lastkeys, 1)
            push!(tdctr_totaldiscountedtransmissioncostbyregion, @build_constraint(sumexps[1] == vtotaldiscountedtransmissioncostbyregion[lastkeys[1],lastkeys[2]]))
        end

        put!(cons_channel, tdctr_totaldiscountedtransmissioncostbyregion)
    end)

    numconsarrays += 1
    logmsg("Queued constraint TDCTr_TotalDiscountedTransmissionCostByRegion for creation.", quiet)
end
# END: TDCTr_TotalDiscountedTransmissionCostByRegion.

# BEGIN: TDC2_TotalDiscountedCost.
tdc2_totaldiscountedcost::Array{AbstractConstraint, 1} = Array{AbstractConstraint, 1}()

t = Threads.@spawn(begin
    for (r, y) in Base.product(sregion, syear)
        push!(tdc2_totaldiscountedcost, @build_constraint((length(stechnology) == 0 ? 0 : sum([vtotaldiscountedcostbytechnology[r,t,y] for t = stechnology]))
            + (length(sstorage) == 0 ? 0 : sum([vtotaldiscountedstoragecost[r,s,y] for s = sstorage]))
            + (transmissionmodeling ? vtotaldiscountedtransmissioncostbyregion[r,y] : 0)
            == vtotaldiscountedcost[r,y]))
    end

    put!(cons_channel, tdc2_totaldiscountedcost)
end)

numconsarrays += 1
logmsg("Queued constraint TDC2_TotalDiscountedCost for creation.", quiet)
# END: TDC2_TotalDiscountedCost.

# BEGIN: TCC1_TotalAnnualMaxCapacityConstraint.
tcc1_totalannualmaxcapacityconstraint::Array{AbstractConstraint, 1} = Array{AbstractConstraint, 1}()

t = Threads.@spawn(begin
    for row in SQLite.DBInterface.execute(db, "select r, t, y, cast(val as real) as tmx
    from TotalAnnualMaxCapacity_def $(restrictyears ? "where y in" * inyears : "")")
        local r = row[:r]
        local t = row[:t]
        local y = row[:y]

        push!(tcc1_totalannualmaxcapacityconstraint, @build_constraint(vtotalcapacityannual[r,t,y] <= row[:tmx]))
    end

    put!(cons_channel, tcc1_totalannualmaxcapacityconstraint)
end)

numconsarrays += 1
logmsg("Queued constraint TCC1_TotalAnnualMaxCapacityConstraint for creation.", quiet)
# END: TCC1_TotalAnnualMaxCapacityConstraint.

# BEGIN: TCC2_TotalAnnualMinCapacityConstraint.
tcc2_totalannualmincapacityconstraint::Array{AbstractConstraint, 1} = Array{AbstractConstraint, 1}()

t = Threads.@spawn(begin
    for row in SQLite.DBInterface.execute(db, "select r, t, y, cast(val as real) as tmn
    from TotalAnnualMinCapacity_def
    where val > 0 $(restrictyears ? "and y in" * inyears : "")")
        local r = row[:r]
        local t = row[:t]
        local y = row[:y]

        push!(tcc2_totalannualmincapacityconstraint, @build_constraint(vtotalcapacityannual[r,t,y] >= row[:tmn]))
    end

    put!(cons_channel, tcc2_totalannualmincapacityconstraint)
end)

numconsarrays += 1
logmsg("Queued constraint TCC2_TotalAnnualMinCapacityConstraint for creation.", quiet)
# END: TCC2_TotalAnnualMinCapacityConstraint.

# BEGIN: NCC1_TotalAnnualMaxNewCapacityConstraint.
ncc1_totalannualmaxnewcapacityconstraint::Array{AbstractConstraint, 1} = Array{AbstractConstraint, 1}()

t = Threads.@spawn(begin
    for row in SQLite.DBInterface.execute(db, "select r, t, y, cast(val as real) as tmx
    from TotalAnnualMaxCapacityInvestment_def $(restrictyears ? "where y in" * inyears : "")")
        local r = row[:r]
        local t = row[:t]
        local y = row[:y]

        push!(ncc1_totalannualmaxnewcapacityconstraint, @build_constraint(vnewcapacity[r,t,y] <= row[:tmx]
            * (restrictyears ? yearintervalsdict[y] : 1)))
    end

    put!(cons_channel, ncc1_totalannualmaxnewcapacityconstraint)
end)

numconsarrays += 1
logmsg("Queued constraint NCC1_TotalAnnualMaxNewCapacityConstraint for creation.", quiet)
# END: NCC1_TotalAnnualMaxNewCapacityConstraint.

# BEGIN: NCC2_TotalAnnualMinNewCapacityConstraint.
ncc2_totalannualminnewcapacityconstraint::Array{AbstractConstraint, 1} = Array{AbstractConstraint, 1}()

t = Threads.@spawn(begin
    for row in SQLite.DBInterface.execute(db, "select r, t, y, cast(val as real) as tmn
    from TotalAnnualMinCapacityInvestment_def
    where val > 0 $(restrictyears ? "and y in" * inyears : "")")
        local r = row[:r]
        local t = row[:t]
        local y = row[:y]

        push!(ncc2_totalannualminnewcapacityconstraint, @build_constraint(vnewcapacity[r,t,y] >= row[:tmn]
            * (restrictyears ? yearintervalsdict[y] : 1)))
    end

    put!(cons_channel, ncc2_totalannualminnewcapacityconstraint)
end)

numconsarrays += 1
logmsg("Queued constraint NCC2_TotalAnnualMinNewCapacityConstraint for creation.", quiet)
# END: NCC2_TotalAnnualMinNewCapacityConstraint.

# BEGIN: AAC1_TotalAnnualTechnologyActivity.
if (annualactivityupperlimits || annualactivitylowerlimits || modelperiodactivityupperlimits || modelperiodactivitylowerlimits
    || in("vtotaltechnologyannualactivity", varstosavearr) || in("vtotaltechnologymodelperiodactivity", varstosavearr))

    aac1_totalannualtechnologyactivity::Array{AbstractConstraint, 1} = Array{AbstractConstraint, 1}()

    t = Threads.@spawn(let
        local lastkeys = Array{String, 1}(undef,3)  # lastkeys[1] = r, lastkeys[2] = t, lastkeys[3] = y
        local sumexps = Array{AffExpr, 1}([AffExpr()]) # sumexps[1] = vrateoftotalactivity sum

        for row in SQLite.DBInterface.execute(db, "select r.val as r, t.val as t, ys.y as y, ys.l as l, cast(ys.val as real) as ys
        from region r, technology t, YearSplit_def ys
        $(restrictyears ? "where ys.y in" * inyears : "")
        order by r.val, t.val, ys.y")
            local r = row[:r]
            local t = row[:t]
            local y = row[:y]

            if isassigned(lastkeys, 1) && (r != lastkeys[1] || t != lastkeys[2] || y != lastkeys[3])
                # Create constraint
                push!(aac1_totalannualtechnologyactivity, @build_constraint(sumexps[1] ==
                    vtotaltechnologyannualactivity[lastkeys[1],lastkeys[2],lastkeys[3]]))
                sumexps[1] = AffExpr()
            end

            add_to_expression!(sumexps[1], vrateoftotalactivity[r,t,row[:l],y] * row[:ys])

            lastkeys[1] = r
            lastkeys[2] = t
            lastkeys[3] = y
        end

        # Create last constraint
        if isassigned(lastkeys, 1)
            push!(aac1_totalannualtechnologyactivity, @build_constraint(sumexps[1] ==
                vtotaltechnologyannualactivity[lastkeys[1],lastkeys[2],lastkeys[3]]))
        end

        put!(cons_channel, aac1_totalannualtechnologyactivity)
    end)

    numconsarrays += 1
    logmsg("Queued constraint AAC1_TotalAnnualTechnologyActivity for creation.", quiet)
end
# END: AAC1_TotalAnnualTechnologyActivity.

# BEGIN: AAC2_TotalAnnualTechnologyActivityUpperLimit.
if annualactivityupperlimits
    aac2_totalannualtechnologyactivityupperlimit::Array{AbstractConstraint, 1} = Array{AbstractConstraint, 1}()

    t = Threads.@spawn(begin
        for row in SQLite.DBInterface.execute(db, "select r, t, y, cast(val as real) as amx
        from TotalTechnologyAnnualActivityUpperLimit_def $(restrictyears ? "where y in" * inyears : "")")
            local r = row[:r]
            local t = row[:t]
            local y = row[:y]

            push!(aac2_totalannualtechnologyactivityupperlimit, @build_constraint(vtotaltechnologyannualactivity[r,t,y] <= row[:amx]))
        end

        put!(cons_channel, aac2_totalannualtechnologyactivityupperlimit)
    end)

    numconsarrays += 1
    logmsg("Queued constraint AAC2_TotalAnnualTechnologyActivityUpperLimit for creation.", quiet)
end
# END: AAC2_TotalAnnualTechnologyActivityUpperLimit.

# BEGIN: AAC3_TotalAnnualTechnologyActivityLowerLimit.
if annualactivitylowerlimits
    aac3_totalannualtechnologyactivitylowerlimit::Array{AbstractConstraint, 1} = Array{AbstractConstraint, 1}()

    t = Threads.@spawn(begin
        for row in queryannualactivitylowerlimit
            local r = row[:r]
            local t = row[:t]
            local y = row[:y]

            push!(aac3_totalannualtechnologyactivitylowerlimit, @build_constraint(vtotaltechnologyannualactivity[r,t,y] >= row[:amn]))
        end

        put!(cons_channel, aac3_totalannualtechnologyactivitylowerlimit)
    end)

    numconsarrays += 1
    logmsg("Queued constraint AAC3_TotalAnnualTechnologyActivityLowerLimit for creation.", quiet)
end
# END: AAC3_TotalAnnualTechnologyActivityLowerLimit.

# BEGIN: TAC1_TotalModelHorizonTechnologyActivity.
if modelperiodactivitylowerlimits || modelperiodactivityupperlimits || in("vtotaltechnologymodelperiodactivity", varstosavearr)
    tac1_totalmodelhorizontechnologyactivity::Array{AbstractConstraint, 1} = Array{AbstractConstraint, 1}()

    t = Threads.@spawn(begin
        for (r, t) in Base.product(sregion, stechnology)
            push!(tac1_totalmodelhorizontechnologyactivity, @build_constraint(sum([vtotaltechnologyannualactivity[r,t,y] for y = syear]) == vtotaltechnologymodelperiodactivity[r,t]))
        end

        put!(cons_channel, tac1_totalmodelhorizontechnologyactivity)
    end)

    numconsarrays += 1
    logmsg("Queued constraint TAC1_TotalModelHorizonTechnologyActivity for creation.", quiet)
end
# END: TAC1_TotalModelHorizonTechnologyActivity.

# BEGIN: TAC2_TotalModelHorizonTechnologyActivityUpperLimit.
if modelperiodactivityupperlimits
    tac2_totalmodelhorizontechnologyactivityupperlimit::Array{AbstractConstraint, 1} = Array{AbstractConstraint, 1}()

    t = Threads.@spawn(begin
        for row in SQLite.DBInterface.execute(db, "select r, t, cast(val as real) as mmx
        from TotalTechnologyModelPeriodActivityUpperLimit_def")
            local r = row[:r]
            local t = row[:t]

            push!(tac2_totalmodelhorizontechnologyactivityupperlimit, @build_constraint(vtotaltechnologymodelperiodactivity[r,t] <= row[:mmx]))
        end

        put!(cons_channel, tac2_totalmodelhorizontechnologyactivityupperlimit)
    end)

    numconsarrays += 1
    logmsg("Queued constraint TAC2_TotalModelHorizonTechnologyActivityUpperLimit for creation.", quiet)
end
# END: TAC2_TotalModelHorizonTechnologyActivityUpperLimit.

# BEGIN: TAC3_TotalModelHorizonTechnologyActivityLowerLimit.
if modelperiodactivitylowerlimits
    tac3_totalmodelhorizontechnologyactivitylowerlimit::Array{AbstractConstraint, 1} = Array{AbstractConstraint, 1}()

    t = Threads.@spawn(begin
        for row in querymodelperiodactivitylowerlimit
            local r = row[:r]
            local t = row[:t]

            push!(tac3_totalmodelhorizontechnologyactivitylowerlimit, @build_constraint(vtotaltechnologymodelperiodactivity[r,t] >= row[:mmn]))
        end

        put!(cons_channel, tac3_totalmodelhorizontechnologyactivitylowerlimit)
    end)

    numconsarrays += 1
    logmsg("Queued constraint TAC3_TotalModelHorizonTechnologyActivityLowerLimit for creation.", quiet)
end
# END: TAC3_TotalModelHorizonTechnologyActivityLowerLimit.

# BEGIN: RM1_TotalCapacityInReserveMargin.
rm1_totalcapacityinreservemargin::Array{AbstractConstraint, 1} = Array{AbstractConstraint, 1}()

t = Threads.@spawn(let
    local lastkeys = Array{String, 1}(undef,3)  # lastkeys[1] = r, lastkeys[2] = f, lastkeys[3] = y
    local sumexps = Array{AffExpr, 1}([AffExpr()])  # sumexps[1] = vtotalcapacityannual sum

    # Define vtotalcapacityinreservemargin for [r,f,y] with corresponding technologies
    for row in SQLite.DBInterface.execute(db, "select rmt.r, rmt.f, rmt.y, rmt.t, cast(rmt.val as real) as rmt, cast(cau.val as real) as cau
        from ReserveMarginTagTechnology_def rmt, CapacityToActivityUnit_def cau
        where
        rmt.r = cau.r and rmt.t = cau.t
        and rmt.val > 0
        $(restrictyears ? "and rmt.y in" * inyears : "")
        order by rmt.r, rmt.f, rmt.y")
        local r = row[:r]
        local f = row[:f]
        local y = row[:y]

        if isassigned(lastkeys, 1) && (r != lastkeys[1] || f != lastkeys[2] || y != lastkeys[3])
            # Create constraint
            push!(rm1_totalcapacityinreservemargin, @build_constraint(sumexps[1] == vtotalcapacityinreservemargin[lastkeys[1],lastkeys[2],lastkeys[3]]))
            sumexps[1] = AffExpr()
        end

        add_to_expression!(sumexps[1], vtotalcapacityannual[r,row[:t],y] * row[:rmt] * row[:cau])

        lastkeys[1] = r
        lastkeys[2] = f
        lastkeys[3] = y
    end

    # Create last constraint
    if isassigned(lastkeys, 1)
        push!(rm1_totalcapacityinreservemargin, @build_constraint(sumexps[1] == vtotalcapacityinreservemargin[lastkeys[1],lastkeys[2],lastkeys[3]]))
    end

    # Define vtotalcapacityinreservemargin for [r,f,y] with no corresponding technologies
    for row in SQLite.DBInterface.execute(db, "select r.val as r, f.val as f, y.val as y
        from REGION r, FUEL f, YEAR y
        where
        (r, f, y) not in (select rmt.r, rmt.f, rmt.y
            from ReserveMarginTagTechnology_def rmt, CapacityToActivityUnit_def cau
            where
            rmt.r = cau.r
            and rmt.t = cau.t
            and rmt.val > 0)
        $(restrictyears ? "and y.val in" * inyears : "")")

        push!(rm1_totalcapacityinreservemargin, @build_constraint(vtotalcapacityinreservemargin[row[:r],row[:f],row[:y]] == 0))
    end

    put!(cons_channel, rm1_totalcapacityinreservemargin)
end)

numconsarrays += 1
logmsg("Queued constraint RM1_TotalCapacityInReserveMargin for creation.", quiet)
# END: RM1_TotalCapacityInReserveMargin.

# BEGIN: RM2_ReserveMargin.
rm2_reservemargin::Array{AbstractConstraint, 1} = Array{AbstractConstraint, 1}()

t = Threads.@spawn(begin
    for row in SQLite.DBInterface.execute(db, "select rm.r, l.val as l, rm.f, rm.y, cast(rm.val as real) as rm 
        from ReserveMargin rm, TIMESLICE l
        where 1 = 1
        $(restrictyears ? "and rm.y in" * inyears : "")")
        local r = row[:r]
        local l = row[:l]
        local f = row[:f]
        local y = row[:y]

        push!(rm2_reservemargin, @build_constraint(vrateofproduction[r,l,f,y] * row[:rm] <= vtotalcapacityinreservemargin[r,f,y]))
    end

    put!(cons_channel, rm2_reservemargin)
end)

numconsarrays += 1
logmsg("Queued constraint RM2_ReserveMargin for creation.", quiet)
# END: RM2_ReserveMargin.

# BEGIN: RE1_FuelProductionByTechnologyAnnual.
re1_fuelproductionbytechnologyannual::Array{AbstractConstraint, 1} = Array{AbstractConstraint, 1}()

t = Threads.@spawn(let
    local lastkeys = Array{String, 1}(undef,4)  # lastkeys[1] = r, lastkeys[2] = t, lastkeys[3] = f, lastkeys[4] = y
    local sumexps = Array{AffExpr, 1}([AffExpr()])  # sumexps[1] = vproductionbytechnologynn-equivalent sum

    for row in DataFrames.eachrow(queries["queryvproductionbytechnologyannual"])
        local r = row[:r]
        local t = row[:t]
        local f = row[:f]
        local y = row[:y]
        local n = row[:n]

        if isassigned(lastkeys, 1) && (r != lastkeys[1] || t != lastkeys[2] || f != lastkeys[3] || y != lastkeys[4])
            # Create constraint
            push!(re1_fuelproductionbytechnologyannual, @build_constraint(sumexps[1] == vproductionbytechnologyannual[lastkeys[1],lastkeys[2],lastkeys[3],lastkeys[4]]))
            sumexps[1] = AffExpr()
        end

        if ismissing(n)
            add_to_expression!(sumexps[1], vrateofproductionbytechnologynn[r,row[:l],t,f,y] * row[:ys])
        else
            add_to_expression!(sumexps[1], vrateofproductionbytechnologynodal[n,row[:l],t,f,y] * row[:ys])
        end

        lastkeys[1] = r
        lastkeys[2] = t
        lastkeys[3] = f
        lastkeys[4] = y
    end

    # Create last constraint
    if isassigned(lastkeys, 1)
        push!(re1_fuelproductionbytechnologyannual, @build_constraint(sumexps[1] == vproductionbytechnologyannual[lastkeys[1],lastkeys[2],lastkeys[3],lastkeys[4]]))
    end

    put!(cons_channel, re1_fuelproductionbytechnologyannual)
end)

numconsarrays += 1
logmsg("Queued constraint RE1_FuelProductionByTechnologyAnnual for creation.", quiet)
# END: RE1_FuelProductionByTechnologyAnnual.

# BEGIN: FuelUseByTechnologyAnnual.
fuelusebytechnologyannual::Array{AbstractConstraint, 1} = Array{AbstractConstraint, 1}()

t = Threads.@spawn(let
    local lastkeys = Array{String, 1}(undef,4)  # lastkeys[1] = r, lastkeys[2] = t, lastkeys[3] = f, lastkeys[4] = y
    local sumexps = Array{AffExpr, 1}([AffExpr()])  # sumexps[1] = vusebytechnologynn-equivalent sum

    for row in DataFrames.eachrow(queries["queryvusebytechnologyannual"])
        local r = row[:r]
        local t = row[:t]
        local f = row[:f]
        local y = row[:y]
        local n = row[:n]

        if isassigned(lastkeys, 1) && (r != lastkeys[1] || t != lastkeys[2] || f != lastkeys[3] || y != lastkeys[4])
            # Create constraint
            push!(fuelusebytechnologyannual, @build_constraint(sumexps[1] == vusebytechnologyannual[lastkeys[1],lastkeys[2],lastkeys[3],lastkeys[4]]))
            sumexps[1] = AffExpr()
        end

        if ismissing(n)
            add_to_expression!(sumexps[1], vrateofusebytechnologynn[r,row[:l],t,f,y] * row[:ys])
        else
            add_to_expression!(sumexps[1], vrateofusebytechnologynodal[n,row[:l],t,f,y] * row[:ys])
        end

        lastkeys[1] = r
        lastkeys[2] = t
        lastkeys[3] = f
        lastkeys[4] = y
    end

    # Create last constraint
    if isassigned(lastkeys, 1)
        push!(fuelusebytechnologyannual, @build_constraint(sumexps[1] == vusebytechnologyannual[lastkeys[1],lastkeys[2],lastkeys[3],lastkeys[4]]))
    end

    put!(cons_channel, fuelusebytechnologyannual)
end)

numconsarrays += 1
logmsg("Queued constraint FuelUseByTechnologyAnnual for creation.", quiet)
# END: FuelUseByTechnologyAnnual.

# BEGIN: RE2_ProductionTarget.
re2_productiontarget::Array{AbstractConstraint, 1} = Array{AbstractConstraint, 1}()

t = Threads.@spawn(let
    local lastkeys = Array{String, 1}(undef,3)  # lastkeys[1] = r, lastkeys[2] = f, lastkeys[3] = y
    local lastvals = Array{Float64, 1}([0.0])  # lastvals[1] = rmp
    local sumexps = Array{AffExpr, 1}([AffExpr(), AffExpr()])  # sumexps[1] = sum of vregenerationannualnn and vregenerationannualnodal, sumexps[2] = sum of vgenerationannualnn and vgenerationannualnodal

    for row in SQLite.DBInterface.execute(db, "select rmp.r, rmp.f, rmp.y, rn.n, cast(rmp.val as real) as rmp, tme.id as tme
    from REMinProductionTarget_def rmp,
    (select r.val as r, null as n
    from region r
    union all
    select n.r as r, n.val as n
    from node n) rn
	left join TransmissionModelingEnabled tme on tme.r = rmp.r and tme.f = rmp.f and tme.y = rmp.y
    where
    rmp.r = rn.r and rmp.val > 0
    $(restrictyears ? "and rmp.y in" * inyears : "")
    order by rmp.r, rmp.f, rmp.y")
        local r = row[:r]
        local f = row[:f]
        local y = row[:y]
        local n = row[:n]
        local tme = row[:tme]

        if isassigned(lastkeys, 1) && (r != lastkeys[1] || f != lastkeys[2] || y != lastkeys[3])
            # Create constraint
            push!(re2_productiontarget, @build_constraint(sumexps[1] >= (sumexps[2]) * lastvals[1]))
            sumexps[1] = AffExpr()
            sumexps[2] = AffExpr()
        end

        if ismissing(n) && ismissing(tme)
            add_to_expression!(sumexps[1], vregenerationannualnn[r,f,y])
            add_to_expression!(sumexps[2], vgenerationannualnn[r,f,y])
        elseif !ismissing(n) && !ismissing(tme)
            add_to_expression!(sumexps[1], vregenerationannualnodal[n,f,y])
            add_to_expression!(sumexps[2], vgenerationannualnodal[n,f,y])
        end

        lastkeys[1] = r
        lastkeys[2] = f
        lastkeys[3] = y
        lastvals[1] = row[:rmp]
    end

    # Create last constraint
    if isassigned(lastkeys, 1)
        push!(re2_productiontarget, @build_constraint(sumexps[1] >= (sumexps[2]) * lastvals[1]))
    end

    put!(cons_channel, re2_productiontarget)
end)

numconsarrays += 1
logmsg("Queued constraint RE2_ProductionTarget for creation.", quiet)
# END: RE2_ProductionTarget.

# BEGIN: RE3_ProductionTargetRG.
re3_productiontarget::Array{AbstractConstraint, 1} = Array{AbstractConstraint, 1}()

t = Threads.@spawn(let
    local lastkeys = Array{String, 1}(undef,3)  # lastkeys[1] = rg, lastkeys[2] = f, lastkeys[3] = y
    local lastvals = Array{Float64, 1}([0.0])  # lastvals[1] = rgmp
    local sumexps = Array{AffExpr, 1}([AffExpr(), AffExpr()])  # sumexps[1] = sum of vregenerationannualnn and vregenerationannualnodal, sumexps[2] = sum of vgenerationannualnn and vgenerationannualnodal

    for row in SQLite.DBInterface.execute(db, "select rgmp.rg, rrg.r, rn.n, rgmp.f, rgmp.y, cast(rgmp.val as real) as rgmp, tme.id as tme
    from REMinProductionTargetRG rgmp, RRGroup rrg,
    (select r.val as r, null as n
    from region r
    union all
    select n.r as r, n.val as n
    from node n) rn
	left join TransmissionModelingEnabled tme on tme.r = rrg.r and tme.f = rgmp.f and tme.y = rgmp.y
    where
    rgmp.val > 0
	and rgmp.rg = rrg.rg
	and rrg.r = rn.r
    $(restrictyears ? "and rgmp.y in" * inyears : "")
    order by rgmp.rg, rgmp.f, rgmp.y")
        local rg = row[:rg]
        local f = row[:f]
        local y = row[:y]
        local r = row[:r]
        local n = row[:n]
        local tme = row[:tme]

        if isassigned(lastkeys, 1) && (rg != lastkeys[1] || f != lastkeys[2] || y != lastkeys[3])
            # Create constraint
            push!(re3_productiontarget, @build_constraint(sumexps[1] >= (sumexps[2]) * lastvals[1]))
            sumexps[1] = AffExpr()
            sumexps[2] = AffExpr()
        end

        if ismissing(n) && ismissing(tme)
            add_to_expression!(sumexps[1], vregenerationannualnn[r,f,y])
            add_to_expression!(sumexps[2], vgenerationannualnn[r,f,y])
        elseif !ismissing(n) && !ismissing(tme)
            add_to_expression!(sumexps[1], vregenerationannualnodal[n,f,y])
            add_to_expression!(sumexps[2], vgenerationannualnodal[n,f,y])
        end

        lastkeys[1] = rg
        lastkeys[2] = f
        lastkeys[3] = y
        lastvals[1] = row[:rgmp]
    end

    # Create last constraint
    if isassigned(lastkeys, 1)
        push!(re3_productiontarget, @build_constraint(sumexps[1] >= (sumexps[2]) * lastvals[1]))
    end

    put!(cons_channel, re3_productiontarget)
end)

numconsarrays += 1
logmsg("Queued constraint RE3_ProductionTargetRG for creation.", quiet)
# END: RE3_ProductionTargetRG.

# BEGIN: MinShareProduction.
minshareproduction::Array{AbstractConstraint, 1} = Array{AbstractConstraint, 1}()

t = Threads.@spawn(let
    local lastkeys = Array{String, 1}(undef,4)  # lastkeys[1] = r, lastkeys[2] = t, lastkeys[3] = f, lastkeys[4] = y
    local lastvals = Array{Float64, 1}([0.0])  # lastvals[1] = msp
    local sumexps = Array{AffExpr, 1}([AffExpr()]) # sumexps[1] = sum of vgenerationannualnn and vgenerationannualnodal

    for row in SQLite.DBInterface.execute(db, "select msp.r, msp.t, msp.f, msp.y, rn.n, cast(msp.val as real) as msp
    from MinShareProduction_def msp,
    (select r.val as r, null as n
    from region r
    union all
    select n.r as r, n.val as n
    from node n) rn
    where
    msp.r = rn.r and msp.val > 0
    $(restrictyears ? "and msp.y in" * inyears : "")
    order by msp.r, msp.t, msp.f, msp.y")
        local r = row[:r]
        local t = row[:t]
        local f = row[:f]
        local y = row[:y]

        if isassigned(lastkeys, 1) && (r != lastkeys[1] || t != lastkeys[2] || f != lastkeys[3] || y != lastkeys[4])
            # Create constraint
            if !isnothing(variable_by_name(jumpmodel, "vproductionbytechnologyannual[$(lastkeys[1]),$(lastkeys[2]),$(lastkeys[3]),$(lastkeys[4])]"))
                push!(minshareproduction, @build_constraint(vproductionbytechnologyannual[lastkeys[1],lastkeys[2],lastkeys[3],lastkeys[4]] >= (sumexps[1]) * lastvals[1]))
            end

            sumexps[1] = AffExpr()
        end

        if !ismissing(row[:n])
            transmissionmodeling && add_to_expression!(sumexps[1], vgenerationannualnodal[row[:n],f,y])
        else
            add_to_expression!(sumexps[1], vgenerationannualnn[r,f,y])
        end

        lastkeys[1] = r
        lastkeys[2] = t
        lastkeys[3] = f
        lastkeys[4] = y
        lastvals[1] = row[:msp]
    end

    # Create last constraint
    if isassigned(lastkeys, 1)
        if !isnothing(variable_by_name(jumpmodel, "vproductionbytechnologyannual[$(lastkeys[1]),$(lastkeys[2]),$(lastkeys[3]),$(lastkeys[4])]"))
            push!(minshareproduction, @build_constraint(vproductionbytechnologyannual[lastkeys[1],lastkeys[2],lastkeys[3],lastkeys[4]] >= (sumexps[1]) * lastvals[1]))
        end
    end

    put!(cons_channel, minshareproduction)
end)

numconsarrays += 1
logmsg("Queued constraint MinShareProduction for creation.", quiet)
# END: MinShareProduction.

# BEGIN: E1_AnnualEmissionProductionByMode.
if in("vannualtechnologyemissionbymode", varstosavearr)
    e1_annualemissionproductionbymode::Array{AbstractConstraint, 1} = Array{AbstractConstraint, 1}()

    t = Threads.@spawn(begin
        for row in DataFrames.eachrow(queries["queryvannualtechnologyemissionbymode"])
            local r = row[:r]
            local t = row[:t]
            local e = row[:e]
            local m = row[:m]
            local y = row[:y]

            push!(e1_annualemissionproductionbymode, @build_constraint(row[:ear] * vtotalannualtechnologyactivitybymode[r,t,m,y] == vannualtechnologyemissionbymode[r,t,e,m,y]))
        end

        put!(cons_channel, e1_annualemissionproductionbymode)
    end)

    numconsarrays += 1
    logmsg("Queued constraint E1_AnnualEmissionProductionByMode for creation.", quiet)
end
# END: E1_AnnualEmissionProductionByMode.

# BEGIN: E2a_AnnualEmissionProduction.
e2a_annualemissionproduction::Array{AbstractConstraint, 1} = Array{AbstractConstraint, 1}()

t = Threads.@spawn(let
    local lastkeys = Array{String, 1}(undef,4)  # lastkeys[1] = r, lastkeys[2] = t, lastkeys[3] = e, lastkeys[4] = y
    local sumexps = Array{AffExpr, 1}([AffExpr()])  # sumexps[1] = vannualtechnologyemissionbymode-equivalent sum

    for row in DataFrames.eachrow(queries["queryvannualtechnologyemissionbymode"])
        local r = row[:r]
        local t = row[:t]
        local e = row[:e]
        local y = row[:y]

        if isassigned(lastkeys, 1) && (r != lastkeys[1] || t != lastkeys[2] || e != lastkeys[3] || y != lastkeys[4])
            # Create constraint
            push!(e2a_annualemissionproduction, @build_constraint(sumexps[1] ==
                vannualtechnologyemission[lastkeys[1],lastkeys[2],lastkeys[3],lastkeys[4]]))
            sumexps[1] = AffExpr()
        end

        add_to_expression!(sumexps[1], row[:ear] * vtotalannualtechnologyactivitybymode[r,t,row[:m],y])

        lastkeys[1] = r
        lastkeys[2] = t
        lastkeys[3] = e
        lastkeys[4] = y
    end

    # Create last constraint
    if isassigned(lastkeys, 1)
        push!(e2a_annualemissionproduction, @build_constraint(sumexps[1] ==
            vannualtechnologyemission[lastkeys[1],lastkeys[2],lastkeys[3],lastkeys[4]]))
    end

    put!(cons_channel, e2a_annualemissionproduction)
end)

numconsarrays += 1
logmsg("Queued constraint E2a_AnnualEmissionProduction for creation.", quiet)
# END: E2a_AnnualEmissionProduction.

# BEGIN: E2b_AnnualEmissionProduction.
# This constraint is necessary because negative emissions and emission penalties are allowed
e2b_annualemissionproduction::Array{AbstractConstraint, 1} = Array{AbstractConstraint, 1}()

t = Threads.@spawn(begin
    for row in SQLite.DBInterface.execute(db, "select r.val as r, t.val as t, e.val as e, y.val as y
    from REGION r, TECHNOLOGY t, EMISSION e, YEAR y
    left join EmissionActivityRatio_def ear on ear.r = r.val and ear.t = t.val and ear.e = e.val and ear.y = y.val
    where ear.val is null $(restrictyears ? "and y.val in" * inyears : "")")
        push!(e2b_annualemissionproduction, @build_constraint(vannualtechnologyemission[row[:r],row[:t],row[:e],row[:y]] == 0))
    end

    put!(cons_channel, e2b_annualemissionproduction)
end)

numconsarrays += 1
logmsg("Queued constraint E2b_AnnualEmissionProduction for creation.", quiet)
# END: E2b_AnnualEmissionProduction.

# BEGIN: E3_EmissionsPenaltyByTechAndEmission.
if in("vannualtechnologyemissionpenaltybyemission", varstosavearr)
    e3_emissionspenaltybytechandemission::Array{AbstractConstraint, 1} = Array{AbstractConstraint, 1}()

    t = Threads.@spawn(begin
        for row in DataFrames.eachrow(queries["queryvannualtechnologyemissionpenaltybyemission"])
            local r = row[:r]
            local t = row[:t]
            local e = row[:e]
            local y = row[:y]
            local ep = row[:ep]

            if !ismissing(ep)
                push!(e3_emissionspenaltybytechandemission, @build_constraint(vannualtechnologyemission[r,t,e,y] * ep == vannualtechnologyemissionpenaltybyemission[r,t,e,y]))
            end
        end

        put!(cons_channel, e3_emissionspenaltybytechandemission)
    end)

    numconsarrays += 1
    logmsg("Queued constraint E3_EmissionsPenaltyByTechAndEmission for creation.", quiet)
end
# END: E3_EmissionsPenaltyByTechAndEmission.

# BEGIN: E4_EmissionsPenaltyByTechnology.
e4_emissionspenaltybytechnology::Array{AbstractConstraint, 1} = Array{AbstractConstraint, 1}()

t = Threads.@spawn(let
    local lastkeys = Array{String, 1}(undef,3)  # lastkeys[1] = r, lastkeys[2] = t, lastkeys[3] = y
    local sumexps = Array{AffExpr, 1}([AffExpr()])  # sumexps[1] = vannualtechnologyemissionpenaltybyemission-equivalent sum

    for row in DataFrames.eachrow(queries["queryvannualtechnologyemissionpenaltybyemission"])
        local r = row[:r]
        local t = row[:t]
        local y = row[:y]
        local ep = row[:ep]

        if isassigned(lastkeys, 1) && (r != lastkeys[1] || t != lastkeys[2] || y != lastkeys[3])
            # Create constraint
            push!(e4_emissionspenaltybytechnology, @build_constraint(sumexps[1] ==
                vannualtechnologyemissionspenalty[lastkeys[1],lastkeys[2],lastkeys[3]]))
            sumexps[1] = AffExpr()
        end

        if !ismissing(ep)
            add_to_expression!(sumexps[1], vannualtechnologyemission[r,t,row[:e],y] * ep)
        end

        lastkeys[1] = r
        lastkeys[2] = t
        lastkeys[3] = y
    end

    # Create last constraint
    if isassigned(lastkeys, 1)
        push!(e4_emissionspenaltybytechnology, @build_constraint(sumexps[1] ==
            vannualtechnologyemissionspenalty[lastkeys[1],lastkeys[2],lastkeys[3]]))
    end

    put!(cons_channel, e4_emissionspenaltybytechnology)
end)

numconsarrays += 1
logmsg("Queued constraint E4_EmissionsPenaltyByTechnology for creation.", quiet)
# END: E4_EmissionsPenaltyByTechnology.

# BEGIN: E5_DiscountedEmissionsPenaltyByTechnology.
e5_discountedemissionspenaltybytechnology::Array{AbstractConstraint, 1} = Array{AbstractConstraint, 1}()

t = Threads.@spawn(let
    local sumexps = Array{AffExpr, 1}([AffExpr()])  # sumexps[1] = sum of estimated emission penalties in non-modeled years

    for row in SQLite.DBInterface.execute(db, "select r.val as r, t.val as t, y.val as y, y.prev_y, cast(dr.val as real) as dr
    from region r, technology t,
    (select y.val, lag(y.val) over (order by y.val) as prev_y from year y
        $(restrictyears ? "where y.val in" * inyears : "")
    ) as y
    left join DiscountRate_def dr on dr.r = r.val")
        local r = row[:r]
        local t = row[:t]
        local y = row[:y]
        local yint::Int64 = Meta.parse(y)
        local prev_y = row[:prev_y]
        local dr = row[:dr]
        local nyears::Int64 = (ismissing(prev_y) ? yint - firstscenarioyear : yint - Meta.parse(prev_y) - 1)  # Number of years in y's interval, excluding y

        if ismissing(dr) || size(semission,1) == 0
            # Ensure vdiscountedtechnologyemissionspenalty isn't made negative
            push!(e5_discountedemissionspenaltybytechnology, @build_constraint(0 == vdiscountedtechnologyemissionspenalty[r,t,y]))
        else
            # Add estimated emission penalties in non-modeled years to discounted penalties. Assume linear scaling of penalties over modeled intervals (for years before first modeled year, assume constant penalties).
            local ppenalty  # Penalty for r & t at start of y's interval

            if ismissing(prev_y)
                ppenalty = vannualtechnologyemissionspenalty[r,t,y]
            else
                ppenalty = vannualtechnologyemissionspenalty[r,t,prev_y]
            end

            for i = 1:nyears
                add_to_expression!(sumexps[1], (ppenalty + (vannualtechnologyemissionspenalty[r,t,y] - ppenalty) / (nyears + 1) * (nyears + 1 - i))
                    / ((1 + dr)^(yint - i - firstscenarioyear + 0.5)))
            end

            push!(e5_discountedemissionspenaltybytechnology, @build_constraint(sumexps[1]
                + vannualtechnologyemissionspenalty[r,t,y] / ((1 + dr)^(yint - firstscenarioyear + 0.5)) == vdiscountedtechnologyemissionspenalty[r,t,y]))

            sumexps[1] = AffExpr()
        end
    end

    put!(cons_channel, e5_discountedemissionspenaltybytechnology)
end)

numconsarrays += 1
logmsg("Queued constraint E5_DiscountedEmissionsPenaltyByTechnology for creation.", quiet)
# END: E5_DiscountedEmissionsPenaltyByTechnology.

# BEGIN: E6_EmissionsAccounting1.
e6_emissionsaccounting1::Array{AbstractConstraint, 1} = Array{AbstractConstraint, 1}()

t = Threads.@spawn(let
    local lastkeys = Array{String, 1}(undef,3)  # lastkeys[1] = r, lastkeys[2] = e, lastkeys[3] = y
    local lastvals = Array{Float64, 1}([0.0])  # lastvals[1] = aee
    local sumexps = Array{AffExpr, 1}([AffExpr()])  # sumexps[1] = vannualtechnologyemission sum

    for row in SQLite.DBInterface.execute(db, "select distinct ear.r, ear.e, ear.y, ear.t, cast(aee.val as real) as aee
    from EmissionActivityRatio_def ear
    left join AnnualExogenousEmission_def aee on aee.r = ear.r and aee.e = ear.e and aee.y = ear.y
    $(restrictyears ? "where ear.y in" * inyears : "")
    order by ear.r, ear.e, ear.y")
        local r = row[:r]
        local e = row[:e]
        local y = row[:y]

        if isassigned(lastkeys, 1) && (r != lastkeys[1] || e != lastkeys[2] || y != lastkeys[3])
            # Create constraint
            push!(e6_emissionsaccounting1, @build_constraint(sumexps[1] + lastvals[1] ==
                vannualemissions[lastkeys[1],lastkeys[2],lastkeys[3]]))
            sumexps[1] = AffExpr()
        end

        add_to_expression!(sumexps[1], vannualtechnologyemission[r,row[:t],e,y])

        lastkeys[1] = r
        lastkeys[2] = e
        lastkeys[3] = y
        lastvals[1] = (ismissing(row[:aee]) ? 0 : row[:aee])
    end

    # Create last constraint
    if isassigned(lastkeys, 1)
        push!(e6_emissionsaccounting1, @build_constraint(sumexps[1] + lastvals[1] ==
            vannualemissions[lastkeys[1],lastkeys[2],lastkeys[3]]))
    end

    put!(cons_channel, e6_emissionsaccounting1)
end)

numconsarrays += 1
logmsg("Queued constraint E6_EmissionsAccounting1 for creation.", quiet)
# END: E6_EmissionsAccounting1.

# BEGIN: E7_EmissionsAccounting2.
e7_emissionsaccounting2::Array{AbstractConstraint, 1} = Array{AbstractConstraint, 1}()

t = Threads.@spawn(begin
    for row in SQLite.DBInterface.execute(db, "select r.val as r, e.val as e, cast(mpe.val as real) as mpe
    from region r, emission e
    left join ModelPeriodExogenousEmission_def mpe on mpe.r = r.val and mpe.e = e.val")
        local r = row[:r]
        local e = row[:e]
        local mpe = ismissing(row[:mpe]) ? 0 : row[:mpe]

        push!(e7_emissionsaccounting2, @build_constraint(sum([vannualemissions[r,e,y] for y = syear]) + mpe == vmodelperiodemissions[r,e]))
    end

    put!(cons_channel, e7_emissionsaccounting2)
end)

numconsarrays += 1
logmsg("Queued constraint E7_EmissionsAccounting2 for creation.", quiet)
# END: E7_EmissionsAccounting2.

# BEGIN: E8_AnnualEmissionsLimit.
e8_annualemissionslimit::Array{AbstractConstraint, 1} = Array{AbstractConstraint, 1}()

t = Threads.@spawn(begin
    for row in SQLite.DBInterface.execute(db, "select r.val as r, e.val as e, y.val as y, cast(ael.val as real) as ael
    from region r, emission e, year y, AnnualEmissionLimit_def ael
    where ael.r = r.val and ael.e = e.val and ael.y = y.val $(restrictyears ? "and y.val in" * inyears : "")")
        local r = row[:r]
        local e = row[:e]
        local y = row[:y]

        push!(e8_annualemissionslimit, @build_constraint(vannualemissions[r,e,y] <= row[:ael]))
    end

    put!(cons_channel, e8_annualemissionslimit)
end)

numconsarrays += 1
logmsg("Queued constraint E8_AnnualEmissionsLimit for creation.", quiet)
# END: E8_AnnualEmissionsLimit.

# BEGIN: E9_ModelPeriodEmissionsLimit.
e9_modelperiodemissionslimit::Array{AbstractConstraint, 1} = Array{AbstractConstraint, 1}()

t = Threads.@spawn(begin
    if !restrictyears
        for row in DataFrames.eachrow(queries["queryvmodelperiodemissions"])
            local r = row[:r]
            local e = row[:e]

            push!(e9_modelperiodemissionslimit, @build_constraint(vmodelperiodemissions[r,e] <= row[:mpl]))
        end
    end

    put!(cons_channel, e9_modelperiodemissionslimit)
end)

numconsarrays += 1
logmsg("Queued constraint E9_ModelPeriodEmissionsLimit for creation.", quiet)

if restrictyears && size(queries["queryvmodelperiodemissions"])[1] > 0
    @warn "Model period emission limits (ModelPeriodEmissionLimit parameter) are not enforced when modeling selected years."
end
# END: E9_ModelPeriodEmissionsLimit.

logmsg("Queued $numconsarrays standard constraints for creation.", quiet)

finishedqueuingcons = true
end)  # @sync
# END: Wrap multi-threaded constraint building in @sync to allow any errors to propagate.

# BEGIN: Ensure all non-custom constraints are added to model.
if !istaskdone(addconstask)
    wait(addconstask)
end

logmsg("Added $numaddedconsarrays standard constraints to model.", quiet)
# END: Ensure all non-custom constraints are added to model.

# BEGIN: Perform customconstraints include.
if configfile != nothing && haskey(configfile, "includes", "customconstraints")
    try
        include(normpath(joinpath(pwd(), retrieve(configfile, "includes", "customconstraints"))))
        logmsg("Performed customconstraints include.", quiet)
    catch e
        logmsg("Could not perform customconstraints include. Error message: " * sprint(showerror, e) * ". Continuing with NEMO.", quiet)
    end
end
# END: Perform customconstraints include.
# END: Define model constraints.

# BEGIN: Define model objective.
@objective(jumpmodel, Min, sum([vtotaldiscountedcost[r,y] for r = sregion, y = syear]))
logmsg("Defined model objective.", quiet)
# END: Define model objective.

# BEGIN: Calculate or write model.
local returnval  # Value returned by this function

if writemodel
    JuMP.write_to_file(jumpmodel, writefilename; format=writefileformat)
    returnval = writefilename
    logmsg("Wrote model to " * writefilename * ".")
else
    # Calculate model
    optimize!(jumpmodel)
    returnval = termination_status(jumpmodel)  # MathOptInterface.TerminationStatusCode
    solvedtm::DateTime = now()  # Date/time of last solve operation
    solvedtmstr::String = Dates.format(solvedtm, "yyyy-mm-dd HH:MM:SS.sss")  # solvedtm as a formatted string
    logmsg("Solved model. Solver status = " * string(returnval) * ".", quiet, solvedtm)

    # BEGIN: Save results to database.
    if Int(returnval) == 1 && has_values(jumpmodel)  # 1 = Optimal
        savevarresults_threaded(varstosavearr, modelvarindices, db, solvedtmstr, reportzeros, quiet)
        logmsg("Finished saving results to database.", quiet)
    else
        logmsg("Solver did not find an optimal solution for model. No results will be saved to database.")
    end
    # END: Save results to database.
end

# Drop temporary tables
drop_temp_tables(db)
logmsg("Dropped temporary tables.", quiet)

logmsg("Finished modeling scenario.")
return returnval
end  # modelscenario()
