# Generic test harness for NGen components.
using JuMP, SQLite, DataFrames, Cbc, NullableArrays, IterTools

include("ngen_functions.jl")

function test()
    dbpath = "C:\\temp\\TEMBA_datafile.sl3"
    # dbpath = "C:\\temp\\SAMBA_datafile.sl3"
    # dbpath = "C:\\temp\\utopia_2015_08_27.sl3"
    db = SQLite.DB(dbpath)
    logmsg("Connected to model database. Path = " * dbpath * ".")

    createviewwithdefaults(db, ["AnnualEmissionLimit"])

    global model = Model(solver = CbcSolver())  # NGen model; Cbc for mixed-integer problems (otherwise try ClpSolver() in Clp package)

    syear = dropnull(SQLite.query(db, "select val from YEAR order by val")[:val])  # YEAR set
    stechnology = dropnull(SQLite.query(db, "select val from TECHNOLOGY")[:val])  # TECHNOLOGY set
    stimeslice = dropnull(SQLite.query(db, "select val from TIMESLICE")[:val])  # TIMESLICE set
    sfuel = dropnull(SQLite.query(db, "select val from FUEL")[:val])  # FUEL set
    semission = dropnull(SQLite.query(db, "select val from EMISSION")[:val])  # EMISSION set
    smode_of_operation = dropnull(SQLite.query(db, "select val from MODE_OF_OPERATION")[:val])  # MODE_OF_OPERATION set
    sregion = dropnull(SQLite.query(db, "select val from REGION")[:val])  # REGION set
    sseason = dropnull(SQLite.query(db, "select val from SEASON order by val")[:val])  # SEASON set
    sdaytype = dropnull(SQLite.query(db, "select val from DAYTYPE order by val")[:val])  # DAYTYPE set
    sdailytimebracket = dropnull(SQLite.query(db, "select val from DAILYTIMEBRACKET")[:val])  # DAILYTIMEBRACKET set
    # FLEXIBLEDEMANDTYPE not used in Utopia example; substitute empty value
    sflexibledemandtype = Array{String,1}()  # FLEXIBLEDEMANDTYPE set
    global sstorage = dropnull(SQLite.query(db, "select val from STORAGE")[:val])  # STORAGE set

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
    logmsg("Defined costing variables.")

    logmsg("Finished set-up.")

    # BEGIN: TDC2_TotalDiscountedCost.
    constraintnum = 1  # Number of next constraint to be added to constraint array
    @constraintref tdc2_totaldiscountedcost[1:length(sregion) * length(syear)]

    for (r, y) in product(sregion, syear)
        tdc2_totaldiscountedcost[constraintnum] = @constraint(model, (length(stechnology) == 0 ? 0 : sum([vtotaldiscountedcostbytechnology[r,t,y] for t = stechnology])) + (length(sstorage) == 0 ? 0 : sum([vtotaldiscountedstoragecost[r,s,y] for s = sstorage])) == vtotaldiscountedcost[r,y])
        constraintnum += 1
    end

    logmsg("Created constraint TDC2_TotalDiscountedCost.")
    # END: TDC2_TotalDiscountedCost.

end
