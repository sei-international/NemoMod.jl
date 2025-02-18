#=
    NEMO: Next Energy Modeling system for Optimization.
    https://github.com/sei-international/NemoMod.jl

    Copyright © 2025: Stockholm Environment Institute U.S.

    File description: Functions for querying the scenario database when calculating a scenario.
=#

"""
    scenario_calc_queries(dbpath::String, transmissionmodeling::Bool, vproductionbytechnologysaved::Bool,
        vusebytechnologysaved::Bool, restrictyears::Bool, inyears::String)

Returns a `Dict` of query commands used in NEMO's `modelscenario` function. Each key in the return value is
    a query name, and each value is a `Tuple` where:
        - Element 1 = path to NEMO scenario database in which to execute query (taken from `dbpath` argument)
        - Element 2 = query's SQL statement
    The function's arguments other than `dbpath` delimit the set of returned query commands as noted below.

# Arguments
- `dbpath::String`: Path to NEMO scenario database in which query commands should be executed.
- `transmissionmodeling::Bool`: Indicates whether transmission modeling is enabled in `modelscenario`.
    Additional query commands are included in results when transmission modeling is enabled.
- `vproductionbytechnologysaved::Bool`: Indicates whether output variable `vproductionbytechnology`
    will be saved in `modelscenario`. Additional query commands are included in results when this argument
    and `transmissionmodeling` are `true`.
- `vusebytechnologysaved::Bool`: Indicates whether output variable `vusebytechnology`
    will be saved in `modelscenario`. Additional query commands are included in results when this argument
    and `transmissionmodeling` are `true`.
- `restrictyears::Bool`: Indicates whether `modelscenario` is running for selected years only.
- `inyears::String`: SQL IN clause predicate for years selected for `modelscenario`. When `restrictvars`
    is `true`, this argument is used to include filtering by year in query commands.
- `limitedforesight::Bool`: Indicates whether `modelscenario` is executing part of a limited foresight optimization.
- `lastyearprevgroupyears`: If `modelscenario` is executing part of a limited foresight optimization, the last year 
    modeled in the previous step of the optimization (i.e., the previous invocation of `modelscenario`). `nothing`
    if the current step is the first step of the optimization. Additional query commands are included in results 
    when `limitedforesight` is `true` and this argument is not `nothing`.
- `firstmodeledyear::String`: The first year being modeled in the current invocation of `modelscenario`. Only used
    `limitedforesight` is `true` and `lastyearprevgroupyears` is not `nothing`."""
function scenario_calc_queries(dbpath::String, transmissionmodeling::Bool, vproductionbytechnologysaved::Bool,
    vusebytechnologysaved::Bool, restrictyears::Bool, inyears::String, limitedforesight::Bool, lastyearprevgroupyears,
    firstmodeledyear::String)

    return_val::Dict{String, Tuple{String, String}} = Dict{String, Tuple{String, String}}()  # Return value for this function; map of query names
    #   to tuples of (DB path, SQL command)

    return_val["queryvrateofdemandnn"] = (dbpath, "select sdp.r as r, sdp.f as f, sdp.l as l, sdp.y as y,
    cast(sdp.val as real) as specifieddemandprofile, cast(sad.val as real) as specifiedannualdemand,
    cast(ys.val as real) as ys
    from SpecifiedDemandProfile_def sdp, SpecifiedAnnualDemand_def sad, YearSplit_def ys
    left join TransmissionModelingEnabled tme on tme.r = sad.r and tme.f = sad.f and tme.y = sad.y
    where sad.r = sdp.r and sad.f = sdp.f and sad.y = sdp.y
    and ys.l = sdp.l and ys.y = sdp.y
    and sdp.val <> 0 and sad.val <> 0 and ys.val <> 0
    $(restrictyears ? "and sdp.y in" * inyears : "")
    and tme.id is null")

    return_val["queryvrateofactivityvar"] = (dbpath, "with ar as (select r, t, m, y from OutputActivityRatio_def
    where val <> 0 $(restrictyears ? "and y in" * inyears : "")
    union
    select r, t, m, y from InputActivityRatio_def
    where val <> 0 $(restrictyears ? "and y in" * inyears : ""))
    select r.val as r, l.val as l, t.val as t, m.val as m, y.val as y
    from REGION r, TIMESLICE l, TECHNOLOGY t, MODE_OF_OPERATION m, YEAR y, ar
    where ar.r = r.val and ar.t = t.val and ar.m = m.val and ar.y = y.val
    order by r.val, t.val, l.val, y.val")

    return_val["queryvtrade"] = (dbpath, "select r.val as r, rr.val as rr, l.val as l, f.val as f, y.val as y
    from region r, region rr, TIMESLICE l, FUEL f, year y, TradeRoute_def tr
    WHERE
    r.val = tr.r and rr.val = tr.rr and f.val = tr.f and y.val = tr.y
    and tr.r <> tr.rr and tr.val = 1 $(restrictyears ? "and tr.y in" * inyears : "")
    order by r.val, rr.val, f.val, y.val")

    return_val["queryvtradeannual"] = (dbpath, "select r.val as r, rr.val as rr, f.val as f, y.val as y
    from region r, region rr, FUEL f, year y, TradeRoute_def tr
    WHERE
    r.val = tr.r and rr.val = tr.rr and f.val = tr.f and y.val = tr.y
    and tr.r <> tr.rr and tr.val = 1 $(restrictyears ? "and tr.y in" * inyears : "")")

    # fs_t is populated if t produces from storage
    return_val["queryvrateofproductionbytechnologybymodenn"] = (dbpath, "select r.val as r, ys.l as l, t.val as t, m.val as m, f.val as f, y.val as y,
    cast(oar.val as real) as oar, cast(ys.val as real) as ys, fs.t as fs_t, cast(ret.val as real) as ret
    from region r, YearSplit_def ys, technology t, MODE_OF_OPERATION m, fuel f, year y, OutputActivityRatio_def oar
    left join TransmissionModelingEnabled tme on tme.r = r.val and tme.f = f.val and tme.y = y.val
	left join (select DISTINCT tfs.r, tfs.t, tfs.m, y.val as y from TechnologyFromStorage_def tfs, year y
		left join nodalstorage ns on ns.r = tfs.r and ns.s = tfs.s and ns.y = y.val
		where tfs.val > 0 $(restrictyears ? "and y.val in" * inyears : "")
		and ns.r is null) fs on fs.r = r.val and fs.t = t.val and fs.m = m.val and fs.y = y.val
    left join RETagTechnology_def ret on ret.r = r.val and ret.t = t.val and ret.y = y.val
    where oar.r = r.val and oar.t = t.val and oar.f = f.val and oar.m = m.val and oar.y = y.val
    and oar.val <> 0
    and ys.y = y.val
    and tme.id is null
    $(restrictyears ? "and y.val in" * inyears : "")
	order by r.val, f.val, y.val, ys.l, t.val")

    return_val["queryvrateofproductionbytechnologynn"] = (dbpath, "select r.val as r, ys.l as l, t.val as t, f.val as f, y.val as y, cast(ys.val as real) as ys
    from region r, YearSplit_def ys, technology t, fuel f, year y,
    (select distinct r, t, f, y
    from OutputActivityRatio_def
    where val <> 0 $(restrictyears ? "and y in" * inyears : "")) oar
    left join TransmissionModelingEnabled tme on tme.r = r.val and tme.f = f.val and tme.y = y.val
    where oar.r = r.val and oar.t = t.val and oar.f = f.val and oar.y = y.val
    and ys.y = y.val
    and tme.id is null
    order by r.val, ys.l, f.val, y.val")

    return_val["queryvproductionbytechnologyannual"] = (dbpath, "select * from (
    select r.val as r, t.val as t, f.val as f, y.val as y, null as n, ys.l as l,
    cast(ys.val as real) as ys
    from region r, technology t, fuel f, year y, YearSplit_def ys,
    (select distinct r, t, f, y
    from OutputActivityRatio_def
    where val <> 0 $(restrictyears ? "and y in" * inyears : "")) oar
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
    where val <> 0 $(restrictyears ? "and y in" * inyears : "")) oar
    where ntc.val > 0
    and ntc.n = n.val
    and tme.r = n.r and tme.f = oar.f and tme.y = ntc.y
    and oar.r = n.r and oar.t = ntc.t and oar.y = ntc.y
    and ntc.y = ys.y
    )
    order by r, t, f, y")

    return_val["queryvrateofusebytechnologybymodenn"] = (dbpath, "select r.val as r, ys.l as l, t.val as t, m.val as m, f.val as f, y.val as y, cast(iar.val as real) as iar
    from region r, YearSplit_def ys, technology t, MODE_OF_OPERATION m, fuel f, year y, InputActivityRatio_def iar
    left join TransmissionModelingEnabled tme on tme.r = r.val and tme.f = f.val and tme.y = y.val
	left join (select distinct n.r, ntc.t, ntc.y from NodalDistributionTechnologyCapacity_def ntc, node n where ntc.n = n.val and ntc.val > 0) ntcr 
		on ntcr.r = r.val and ntcr.t = t.val and ntcr.y = y.val
    where iar.r = r.val and iar.t = t.val and iar.f = f.val and iar.m = m.val and iar.y = y.val and iar.val <> 0
    and ys.y = y.val
    and (tme.id is null or (tme.id is not null and ntcr.t is null))
    $(restrictyears ? "and y.val in" * inyears : "")
    order by r.val, ys.l, t.val, f.val, y.val")

    return_val["queryvrateofusebytechnologynn"] = (dbpath, "with iar as (select distinct r, t, f, y from InputActivityRatio_def where val <> 0 $(restrictyears ? "and y in" * inyears : ""))
    select r.val as r, ys.l as l, t.val as t, f.val as f, y.val as y, cast(ys.val as real) as ys
    from region r, YearSplit_def ys, technology t, fuel f, year y, iar
    left join TransmissionModelingEnabled tme on tme.r = r.val and tme.f = f.val and tme.y = y.val
    where iar.r = r.val and iar.t = t.val and iar.f = f.val and iar.y = y.val
    and ys.y = y.val
    and tme.id is null
	union all
	select r.val as r, ys.l as l, t.val as t, f.val as f, y.val as y, cast(ys.val as real) as ys
    from region r, YearSplit_def ys, technology t, fuel f, year y, TransmissionModelingEnabled tme, iar
	left join (select distinct n.r, ntc.t, ntc.y from NodalDistributionTechnologyCapacity_def ntc, node n where ntc.n = n.val and ntc.val > 0) ntcr 
		on ntcr.r = r.val and ntcr.t = t.val and ntcr.y = y.val
	where 
	ys.y = y.val
	and tme.r = r.val and tme.f = f.val and tme.y = y.val
	and iar.r = r.val and iar.t = t.val and iar.f = f.val and iar.y = y.val
	and ntcr.t is null
    order by r.val, ys.l, f.val, y.val")

    return_val["queryvusebytechnologyannual"] = (dbpath, "with iar as (select distinct r, t, f, y from InputActivityRatio_def where val <> 0 $(restrictyears ? "and y in" * inyears : ""))
    select * from (
    select r.val as r, t.val as t, f.val as f, y.val as y, null as n, ys.l as l, cast(ys.val as real) as ys
    from region r, technology t, fuel f, year y, YearSplit_def ys, iar
    left join TransmissionModelingEnabled tme on tme.r = r.val and tme.f = f.val and tme.y = y.val
    where iar.r = r.val and iar.t = t.val and iar.f = f.val and iar.y = y.val
    and ys.y = y.val
    and tme.id is null
	union all
	select r.val as r, t.val as t, f.val as f, y.val as y, null as n, ys.l as l, cast(ys.val as real) as ys
    from region r, technology t, fuel f, year y, YearSplit_def ys, iar, TransmissionModelingEnabled tme
	left join (select distinct n.r, ntc.t, ntc.y from NodalDistributionTechnologyCapacity_def ntc, node n where ntc.n = n.val and ntc.val > 0) ntcr 
		on ntcr.r = r.val and ntcr.t = t.val and ntcr.y = y.val
	where 
	ys.y = y.val
	and tme.r = r.val and tme.f = f.val and tme.y = y.val
	and iar.r = r.val and iar.t = t.val and iar.f = f.val and iar.y = y.val
	and ntcr.t is null
    union all
    select n.r as r, ntc.t as t, iar.f as f, ntc.y as y, ntc.n as n, ys.l as l,
    cast(ys.val as real) as ys
    from NodalDistributionTechnologyCapacity_def ntc, NODE n,
    TransmissionModelingEnabled tme, YearSplit_def ys, iar
    where ntc.val > 0
    and ntc.n = n.val
    and tme.r = n.r and tme.f = iar.f and tme.y = ntc.y
    and iar.r = n.r and iar.t = ntc.t and iar.y = ntc.y
    and ntc.y = ys.y
    )
    order by r, t, f, y")

    return_val["querycaa5_totalnewcapacity"] = (dbpath, "select cot.r as r, cot.t as t, cot.y as y, cast(cot.val as real) as cot
    from CapacityOfOneTechnologyUnit_def cot where cot.val <> 0 $(restrictyears ? "and cot.y in" * inyears : "")")

    return_val["queryrtydr"] = (dbpath, "select r.val as r, t.val as t, y.val as y, cast(dr.val as real) as dr,
    $(limitedforesight && !isnothing(lastyearprevgroupyears) ? "cast(v.val as real)" : "null") as prevcalcval
    from region r, technology t, year y, DiscountRate_def dr, yearintervals yi
    $(limitedforesight && !isnothing(lastyearprevgroupyears) ? "left join vtotaltechnologyannualactivity v on v.r = r.val and v.t = t.val and v.y = (y.val - yi.intv)" : "")
    where dr.r = r.val $(restrictyears ? "and y.val in" * inyears : "")
    and yi.y = y.val
    order by r.val, t.val")

    return_val["queryvannualtechnologyemissionbymode"] = (dbpath, "select r, t, e, y, m, cast(val as real) as ear
    from EmissionActivityRatio_def ear $(restrictyears ? "where y in" * inyears : "")
    order by r, t, e, y")

    return_val["queryvannualtechnologyemissionpenaltybyemission"] = (dbpath, "select r.val as r, t.val as t, y.val as y, e.val as e, cast(ep.val as real) as ep
    from REGION r, TECHNOLOGY t, EMISSION e, YEAR y
    left join EmissionsPenalty_def ep on ep.r = r.val and ep.e = e.val and ep.y = y.val and ep.val <> 0
    $(restrictyears ? "where y.val in" * inyears : "")
    order by r.val, t.val, y.val")

    return_val["queryvmodelperiodemissions"] = (dbpath, "select r.val as r, e.val as e, cast(mpl.val as real) as mpl
    from region r, emission e, ModelPeriodEmissionLimit_def mpl
    where mpl.r = r.val and mpl.e = e.val")

    return_val["queryrempe"] = (dbpath, "select r.val as r, e.val as e, y.val as y, cast(mpe.val as real) as mpe,
    $(limitedforesight && !isnothing(lastyearprevgroupyears) ? "cast(v.val as real)" : "null") as prevcalcval
    from region r, emission e, year y, yearintervals yi
    left join ModelPeriodExogenousEmission_def mpe on mpe.r = r.val and mpe.e = e.val
    $(limitedforesight && !isnothing(lastyearprevgroupyears) ? "left join vannualemissions v on v.r = r.val and v.e = e.val and v.y = (y.val - yi.intv)" : "")
    where yi.y = y.val $(restrictyears ? "and y.val in" * inyears : "")
    order by r.val, e.val, y.val")

    if transmissionmodeling
        return_val["queryvrateofactivitynodal"] = (dbpath, "select ntc.n as n, l.val as l, ntc.t as t, ar.m as m, ntc.y as y
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
        order by ntc.n, ntc.t, l.val, ntc.y")

        return_val["queryvrateofproductionbytechnologynodal"] = (dbpath, "select ntc.n as n, ys.l as l, ntc.t as t, oar.f as f, ntc.y as y,
        	cast(ys.val as real) as ys
        from NodalDistributionTechnologyCapacity_def ntc, YearSplit_def ys, NODE n,
    	TransmissionModelingEnabled tme,
        (select distinct r, t, f, y
        from OutputActivityRatio_def
        where val <> 0 $(restrictyears ? "and y in" * inyears : "")) oar
        where ntc.val > 0
        and ntc.y = ys.y
        and ntc.n = n.val
        and tme.r = n.r and tme.f = oar.f and tme.y = ntc.y
    	and oar.r = n.r and oar.t = ntc.t and oar.y = ntc.y
        order by ntc.n, ys.l, oar.f, ntc.y")

        return_val["queryvrateofusebytechnologynodal"] = (dbpath, "select ntc.n as n, ys.l as l, ntc.t as t, iar.f as f, ntc.y as y,
        	cast(ys.val as real) as ys
        from NodalDistributionTechnologyCapacity_def ntc, YearSplit_def ys, NODE n,
    	TransmissionModelingEnabled tme,
        (select distinct r, t, f, y
        from InputActivityRatio_def
        where val <> 0 $(restrictyears ? "and y in" * inyears : "")) iar
        where ntc.val > 0
        and ntc.y = ys.y
        and ntc.n = n.val
        and tme.r = n.r and tme.f = iar.f and tme.y = ntc.y
    	and iar.r = n.r and iar.t = ntc.t and iar.y = ntc.y
        order by ntc.n, ys.l, iar.f, ntc.y")

        if vproductionbytechnologysaved
            return_val["queryvproductionbytechnologyindices_nodalpart"] = (dbpath, "select distinct n.r as r, ys.l as l, ntc.t as t, oar.f as f, ntc.y as y, null as ys
            from NodalDistributionTechnologyCapacity_def ntc, YearSplit_def ys, NODE n,
            TransmissionModelingEnabled tme,
            (select distinct r, t, f, y
            from OutputActivityRatio_def
            where val <> 0 $(restrictyears ? "and y in" * inyears : "")) oar
            where ntc.val > 0
            and ntc.y = ys.y
            and ntc.n = n.val
            and tme.r = n.r and tme.f = oar.f and tme.y = ntc.y
            and oar.r = n.r and oar.t = ntc.t and oar.y = ntc.y")

            return_val["queryvproductionbytechnologynodal"] = (dbpath, "select n.r as r, ntc.n as n, ys.l as l, ntc.t as t, oar.f as f, ntc.y as y,
                cast(ys.val as real) as ys
            from NodalDistributionTechnologyCapacity_def ntc, YearSplit_def ys, NODE n,
            TransmissionModelingEnabled tme,
            (select distinct r, t, f, y
            from OutputActivityRatio_def
            where val <> 0 $(restrictyears ? "and y in" * inyears : "")) oar
            where ntc.val > 0
            and ntc.y = ys.y
            and ntc.n = n.val
            and tme.r = n.r and tme.f = oar.f and tme.y = ntc.y
            and oar.r = n.r and oar.t = ntc.t and oar.y = ntc.y
            order by n.r, ys.l, ntc.t, oar.f, ntc.y")
        end

        if vusebytechnologysaved
            return_val["queryvusebytechnologyindices_nodalpart"] = (dbpath, "select distinct n.r as r, ys.l as l, ntc.t as t, iar.f as f, ntc.y as y, null as ys
            from NodalDistributionTechnologyCapacity_def ntc, YearSplit_def ys, NODE n,
            TransmissionModelingEnabled tme,
            (select distinct r, t, f, y
            from InputActivityRatio_def
            where val <> 0 $(restrictyears ? "and y in" * inyears : "")) iar
            where ntc.val > 0
            and ntc.y = ys.y
            and ntc.n = n.val
            and tme.r = n.r and tme.f = iar.f and tme.y = ntc.y
            and iar.r = n.r and iar.t = ntc.t and iar.y = ntc.y")

            return_val["queryvusebytechnologynodal"] = (dbpath, "select n.r as r, ntc.n as n, ys.l as l, ntc.t as t, iar.f as f, ntc.y as y,
                cast(ys.val as real) as ys
            from NodalDistributionTechnologyCapacity_def ntc, YearSplit_def ys, NODE n,
            TransmissionModelingEnabled tme,
            (select distinct r, t, f, y
            from InputActivityRatio_def
            where val <> 0 $(restrictyears ? "and y in" * inyears : "")) iar
            where ntc.val > 0
            and ntc.y = ys.y
            and ntc.n = n.val
            and tme.r = n.r and tme.f = iar.f and tme.y = ntc.y
            and iar.r = n.r and iar.t = ntc.t and iar.y = ntc.y
            order by n.r, ys.l, ntc.t, iar.f, ntc.y")
        end

        return_val["queryvtransmissionbyline"] = (dbpath, "select tl.id as tr, ys.l as l, tl.f as f, tme1.y as y, tl.n1 as n1, tl.n2 as n2,
    	tl.reactance as reactance, tme1.type as type, tl.maxflow as maxflow,
        cast(tl.VariableCost as real) as vc, cast(ys.val as real) as ys,
        cast(tl.fixedcost as real) as fc, cast(tcta.val as real) as tcta, cast(tl.efficiency as real) as eff,
        cast(taf.val as real) as taf,
        case when mtn.n2 = tl.n1 then cast(mtn.val as real) else null end as n1_mtn, 
		case when mtn.n2 = tl.n2 then cast(mtn.val as real) else null end as n2_mtn,
		case when mxtn.n2 = tl.n1 then cast(mxtn.val as real) else null end as n1_mxtn,
		case when mxtn.n2 = tl.n2 then cast(mxtn.val as real) else null end as n2_mxtn
        from TransmissionLine tl, NODE n1, NODE n2, TransmissionModelingEnabled tme1,
        TransmissionModelingEnabled tme2, YearSplit_def ys, TransmissionCapacityToActivityUnit_def tcta, 
        TransmissionAvailabilityFactor_def taf
        left join MinAnnualTransmissionNodes_def mtn on ((mtn.n1 = tl.n1 and mtn.n2 = tl.n2) or (mtn.n1 = tl.n2 and mtn.n2 = tl.n1)) and mtn.f = tl.f and mtn.y = tme1.y
		left join MaxAnnualTransmissionNodes_def mxtn on ((mxtn.n1 = tl.n1 and mxtn.n2 = tl.n2) or (mxtn.n1 = tl.n2 and mxtn.n2 = tl.n1)) and mxtn.f = tl.f and mxtn.y = tme1.y
        where
        tl.n1 = n1.val and tl.n2 = n2.val
        and tme1.r = n1.r and tme1.f = tl.f
        and tme2.r = n2.r and tme2.f = tl.f
        and tme1.y = tme2.y and tme1.type = tme2.type
    	and ys.y = tme1.y $(restrictyears ? "and ys.y in" * inyears : "")
    	and tcta.r = n1.r and tl.f = tcta.f
        and taf.tr = tl.id and taf.l = ys.l and taf.y = tme1.y
        order by tl.id, tme1.y")

        return_val["queryvtransmissionlosses"] = (dbpath, "select tl.id as tr, tl.n1, tl.n2, ys.l as l, tl.f as f, tme1.y as y
        from TransmissionLine tl, NODE n1, NODE n2, TransmissionModelingEnabled tme1,
        TransmissionModelingEnabled tme2, YearSplit_def ys
        where
        tl.efficiency < 1
        and tl.n1 = n1.val and tl.n2 = n2.val
        and tme1.r = n1.r and tme1.f = tl.f
        and tme2.r = n2.r and tme2.f = tl.f
        and tme1.y = tme2.y and tme1.type = tme2.type and tme1.type = 3
    	and ys.y = tme1.y $(restrictyears ? "and ys.y in" * inyears : "")")

        return_val["queryvstorageleveltsgroup1"] = (dbpath, "select ns.n as n, ns.s as s, tg1.name as tg1, ns.y as y
        from nodalstorage ns, TSGROUP1 tg1 $(restrictyears ? "where ns.y in" * inyears : "")")

        return_val["queryvstorageleveltsgroup2"] = (dbpath, "select ns.n as n, ns.s as s, tg1.name as tg1, tg2.name as tg2, ns.y as y
        from nodalstorage ns, TSGROUP1 tg1, TSGROUP2 tg2 $(restrictyears ? "where ns.y in" * inyears : "")")

        return_val["queryvstoragelevelts"] = (dbpath, "select ns.n as n, ns.s as s, l.val as l, ns.y as y
        from nodalstorage ns, TIMESLICE l $(restrictyears ? "where ns.y in" * inyears : "")")

        return_val["queryvrateofproduse"] = (dbpath, "select r.val as r, l.val as l, f.val as f, y.val as y, tme.id as tme, n.val as n
        from region r, timeslice l, fuel f, year y, YearSplit_def ys
        left join TransmissionModelingEnabled tme on tme.r = r.val and tme.f = f.val and tme.y = y.val
        left join NODE n on n.r = r.val
        where
        ys.l = l.val and ys.y = y.val
        $(restrictyears ? "and y.val in" * inyears : "")
        order by r.val, l.val, f.val, y.val")

        return_val["querytrydr"] = (dbpath, "select tl.id as tr, y.val as y, cast(dr.val as real) as dr
    	from TransmissionLine tl, NODE n, YEAR y, DiscountRate_def dr
        where tl.n1 = n.val
        and dr.r = n.r
    	$(restrictyears ? "and y.val in" * inyears : "")")
    end  # transmissionmodeling

    if limitedforesight && !isnothing(lastyearprevgroupyears)
        return_val["vannualemissions"] = (dbpath, "select r as vr, e as ve, y as vy, cast(val as real) as vval
        from vannualemissions where y = $(string(lastyearprevgroupyears))")
    end  # limitedforesight && !isnothing(lastyearprevgroupyears)

    return return_val
end  # scenario_calc_queries()

"""
    run_queries(querycommands::Dict{String, Tuple{String, String}})

Runs the SQLite database queries specified in `querycommands` and returns a `Dict` that
    maps each query's name to a `DataFrame` of the query's results. Designed to work with
    the output of `scenario_calc_queries`. Uses multiple threads if they are available.
"""
function run_queries(querycommands::Dict{String, Tuple{String, String}})
    return_val = Dict{String, DataFrame}()
    lck = Base.ReentrantLock()

    Threads.@threads for q in collect(keys(querycommands))
        local df::DataFrame = run_qry(querycommands[q])

        lock(lck) do
            return_val[q] = df
        end
    end

    # Code for running queries without multi-threading; no longer used
    # return_val = Dict{String, DataFrame}(keys(querycommands) .=> map(run_qry, values(querycommands)))

    # Code for running queries in distributed processes; no longer used
    # Omitting process 1 from WorkerPool improves performance
    # queries = Dict{String, DataFrame}(keys(querycommands) .=> pmap(run_qry, WorkerPool(setdiff(targetprocs, [1])), values(querycommands)))

    return return_val
end  # run_queries(querycommands::Dict{String, Tuple{String, String}})

"""
    run_qry(qtpl::Tuple{String, String})

Runs the SQLite database query specified in `qtpl` and returns the result as a DataFrame.
    Element 1 in `qtpl` should be the path to the SQLite database, and element 2 should be the query's
    SQL command. Designed to work with the output of `scenario_calc_queries`."""
function run_qry(qtpl::Tuple{String, String})
    return SQLite.DBInterface.execute(SQLite.DB(qtpl[1]), qtpl[2]) |> DataFrame
end  # run_qry(qtpl::Tuple{String, String, String})