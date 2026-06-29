#=
    NEMO: Next Energy Modeling system for Optimization.
    https://github.com/sei-international/NemoMod.jl

    Copyright © 2026: Stockholm Environment Institute U.S.

    File description: Functions for calculating fuel prices. Fuel prices are not optimization
    decision variables; they are derived after a scenario is solved from the dual values
    (marginal/shadow prices) of the energy balance constraints. The marginal value of a
    unit of a fuel at a region (or node), time slice, and year is the sum of the duals of:
      - the time slice energy balance (EBa11_EnergyBalanceEachTS5, or EBa11Tr for nodes); and
      - the annual energy balance (EBb5_EnergyBalanceEachYear, or EBb5Tr for nodes).
    The two duals partition one marginal value between the two constraint rows (by LP duality,
    their sum equals the marginal producer's cost), so summing them is both correct and
    necessary for a basis-independent result. Duals are present-value (discounted) quantities;
    they are converted to year-of-occurrence (nominal) currency before being reported.
=#

"""
    oc_intervalweights(yint::Int,
        leninterval::Int,
        constantbackfill::Bool,
        applytail::Bool,
        lastscenarioyear::Int) -> Vector{Tuple{Int,Float64,Float64}}

For a modeled year `yint` that represents and is the end point of an interval of `leninterval` years, returns 
a `Vector` of `Tuple`s that characterizes the years in the interval and two values for each: the fraction of 
a change in activity in the prior modeled year that enters NEMO's discounted cost objective in the year (fpy); and the 
fraction of a change in activity in `yint` that enters the discounted cost objective in the year (fy). These fractions 
are based on how NEMO interpolates technology (and transmission) activity in non-modeled years. The `Tuple`s in
the return `Vector` consist of a year, the first fraction (for activity in the prior modeled year), and the 
second fraction (for activity in `yint`). By construction, the fractions sum to 1 for each year. If 
`leninterval == 1`, the return value is a single `Tuple` with `yint` and fractions of 0 and 1. If `applytail` is 
true, the return value includes additional `Tuple`s for years from `yint + 1` to `lastscenarioyear` (populated 
assuming there are no additional modeled years and a change in activity in `yint` recurs in those years).

# Arguments
- `yint::Int`: The modeled year.
- `leninterval::Int`: The number of years in `yint`'s interval (`yearintervalsdict[yint]`); the interval
  spans `yint - leninterval + 1 … yint`.
- `constantbackfill::Bool`: When true, activity is assumed constant across the interval (`fy == 1` 
  everywhere) rather than interpolated linearly from a prior modeled year.
- `applytail::Bool`: When true, activity is assumed constant from `yint` through `lastscenarioyear`, and 
  the return value includes `Tuple`s for years from `yint + 1` to `lastscenarioyear`.
- `lastscenarioyear::Int`: The last year of the scenario being calculated (even if it is not a modeled year).
"""
function oc_intervalweights(yint::Int, leninterval::Int, constantbackfill::Bool, applytail::Bool, lastscenarioyear::Int)
    local returnval = Vector{Tuple{Int,Float64,Float64}}()  # (calendaryear, fraction of a change in activity in the prior modeled year that enters discounted cost objective in calendaryear, fraction of a change in activity in yint that enters discounted cost objective in calendaryear)

    # Years before yint within its interval (yint is the interval's right-hand anchor)
    for i = 1:(leninterval - 1)
        if constantbackfill
            push!(returnval, (yint - i, 0.0, 1.0))
        else
            push!(returnval, (yint - i, i / leninterval, (leninterval - i) / leninterval))
        end
    end

    push!(returnval, (yint, 0.0, 1.0))  # yint itself

    # Constant extrapolation past the last modeled year of the final solve
    if applytail
        for t = (yint + 1):lastscenarioyear
            push!(returnval, (t, 0.0, 1.0))
        end
    end

    return returnval
end  # oc_intervalweights(...)

"""
    activitycostundiscountmultiplier(dr::Float64,
        y::String,
        syear::Vector{String},
        yearintervalsdict::Dict{String,Int},
        firstscenarioyear::Int,
        lastscenarioyear::Int,
        lastmodeledyearforscenario::Bool) -> Float64

Returns a multiplicative factor for converting a discounted energy balance dual for modeled year `y` 
into the nominal cost of delivering a unit of the dual's fuel in `y`. Assumes that a marginal 
change in total discounted cost represents a change in operating costs.

# Arguments
- `dr::Float64`: The discount rate for the energy balance dual's region.
- `y::String`: The year of the energy balance dual to be converted.
- `syear::Vector{String}`: A vector of all modeled years, sorted in ascending order.
- `yearintervalsdict::Dict{String,Int}`: A dictionary mapping years that are being modeled to the number of 
  years in the intervals they represent.
- `firstscenarioyear::Int`: The first year of the scenario being calculated (even if it is not a modeled year).
- `lastscenarioyear::Int`: The last year of the scenario being calculated (even if it is not a modeled year).
- `lastmodeledyearforscenario::Bool`: A flag indicating whether `y` is the last modeled year for the scenario being calculated.
"""
function activitycostundiscountmultiplier(dr::Float64, y::String, syear::Vector{String},
    yearintervalsdict::Dict{String,Int}, firstscenarioyear::Int, lastscenarioyear::Int, lastmodeledyearforscenario::Bool)

    local yint::Int = parse(Int, y)
    local leninterval::Int = get(yearintervalsdict, y, 1)  # Number of years in the interval represented by yint (yint is the right-hand anchor of the interval)
    local discfactor = yr -> (dr == 0.0 ? 1.0 : 1.0 / ((1.0 + dr) ^ (yr - firstscenarioyear + 0.5)))  # Mid-year discount factor for a calendar year (factor used to convert year-`yr` nominal costs to discounted costs in NEMO's objective)

    local d::Float64 = 0.0  # Effective multiplier in NEMO's objective for a unit change in year-`y` nominal operating costs; depends on how additional activity in `y` propagates through non-modeled years and on the discounting applied in each non-modeled year
    
    # BEGIN: Build up d for y and non-modeled years.
    # Contribution from y's own interval (y as right-hand anchor) plus any constant tail
    for (yr, fpy, fy) in oc_intervalweights(yint, leninterval, 
        (y == first(syear)) && (yint - leninterval + 1 == firstscenarioyear), lastmodeledyearforscenario, lastscenarioyear)
        d += fy * discfactor(yr)
    end

    # Contribution from the next modeled year's interval, where y is the prior (left-hand) anchor
    local yidx::Int = findfirst(==(y), syear)

    if yidx < length(syear)
        local ynext::String = syear[yidx + 1]
        for (yr, fpy, fy) in oc_intervalweights(parse(Int, ynext), get(yearintervalsdict, ynext, 1), false, false, lastscenarioyear)
            d += fpy * discfactor(yr)
        end
    end
    # END: Build up d for y and non-modeled years.

    # Return reciprocal of d, which is the factor that converts a change in discounted costs to a change in year-`y` nominal operating costs
    return 1.0 / d
end  # activitycostundiscountmultiplier(...)

"""
    weightedprice(slicekeys::Vector{NTuple{4,String}}, prices::Dict{NTuple{4,String},Float64}, weight)

Returns the weighted average of the prices in `prices` over the keys in `slicekeys`, using
`weight(k)` as the weight for each key `k`. Returns `nothing` when the total weight is zero,
signaling that there is no transaction of the relevant kind (e.g., no production for a
production-weighted average, or no consumption for a consumption-weighted average) and hence no
result to report. `weight` is a function mapping a key to a `Float64` (e.g. production or demand
plus use).
"""
function weightedprice(slicekeys::Vector{NTuple{4,String}}, prices::Dict{NTuple{4,String},Float64}, weight)
    local wsum::Float64 = 0.0   # Sum of weights
    local pwsum::Float64 = 0.0  # Sum of price * weight

    for k in slicekeys
        local w::Float64 = weight(k)
        pwsum += prices[k] * w
        wsum += w
        # @info "weightedprice: k = $k, price = $(prices[k]), weight = $w, pwsum = $pwsum, wsum = $wsum"
    end

    return wsum > 0.0 ? pwsum / wsum : nothing
end  # weightedprice(...)

"""
    savefuelpricetable(db::SQLite.DB, tablename::String, indexcols::Vector{String},
        prices::Dict, solvedtmstr::String, reportzeros::Bool, quiet::Bool)

Saves a dictionary of fuel prices keyed by index-value tuples to result table `tablename`,
following the conventions used by `savevarresults_threaded`.
"""
function savefuelpricetable(db::SQLite.DB, tablename::String, indexcols::Vector{String},
    prices::Dict, solvedtmstr::String, reportzeros::Bool, quiet::Bool)

    try
        SQLite.DBInterface.execute(db, "BEGIN")
        SQLite.DBInterface.execute(db, "create table if not exists '" * tablename * "' ('" * join(indexcols, "' text, '") * "' text, 'val' real, 'solvedtm' text)")

        for (k, v) in prices
            if reportzeros || v != 0.0
                SQLite.DBInterface.execute(db, "insert into " * tablename * " values('" * join(k, "', '") * "', '" * string(v) * "', '" * solvedtmstr * "')")
            end
        end

        SQLite.DBInterface.execute(db, "COMMIT")
        logmsg("Saved results for " * tablename * " to database.", quiet)
    catch
        SQLite.DBInterface.execute(db, "ROLLBACK")
        rethrow()
    end
end  # savefuelpricetable(...)

"""
    calculatefuelprices(jumpmodel::JuMP.Model,
        eba11_refs::Dict{NTuple{4,String}, ConstraintRef}, eba11tr_refs::Dict{NTuple{4,String}, ConstraintRef},
        ebb5_refs::Dict{NTuple{3,String}, ConstraintRef}, ebb5tr_refs::Dict{NTuple{3,String}, ConstraintRef},
        modelvarindices::Dict{String, Tuple{AbstractArray,Array{String,1}}}, db::SQLite.DB,
        varstosavearr::Vector{String}, syear::Vector{String}, firstscenarioyear::Int, lastscenarioyear::Int,
        lastmodeledyear::String, yearintervalsdict::Dict{String, Int}, limitedforesight::Bool,
        finalgroupyears::Bool, solvedtmstr::String, reportzeros::Bool = false, quiet::Bool = false)

Calculates fuel price outputs for a solved scenario from the duals of its energy balance
constraints and saves the requested price outputs to `db`. Recognized outputs in `varstosavearr`:
- `vfuelprice` (r,l,f,y) / `vfuelpricenodal` (n,l,f,y): per-time-slice marginal prices — the sum of
  the time sliced and annual energy balance duals, converted to nominal currency. Reported only for
  slices with throughput (production, demand, or use); empty slices carry degenerate duals and are omitted.
- `vfuelpriceannualreceived` (r,f,y) / `vfuelpricenodalannualreceived` (n,f,y): production-weighted
  annual average of the slice prices — the average price received by producers.
- `vfuelpriceannualpaid` (r,f,y) / `vfuelpricenodalannualpaid` (n,f,y): consumption-weighted annual
  average — the average price paid by consumers.
For the regional (non-nodal) annual tables, nodal fuels are rolled up to the region as a
production- or consumption-weighted average of their nodal slice prices over the region's nodes.

If `jumpmodel` contains integer or binary variables, they are fixed at their optimal values and the
model is re-solved as an LP so that meaningful duals are available; integrality is restored before
the function returns. If the solver does not provide duals (e.g., Cbc), a warning is logged and no 
outputs are saved.
"""
function calculatefuelprices(jumpmodel::JuMP.Model,
    eba11_refs::Dict{NTuple{4,String}, ConstraintRef},
    eba11tr_refs::Dict{NTuple{4,String}, ConstraintRef},
    ebb5_refs::Dict{NTuple{3,String}, ConstraintRef},
    ebb5tr_refs::Dict{NTuple{3,String}, ConstraintRef},
    modelvarindices::Dict{String, Tuple{AbstractArray,Array{String,1}}},
    db::SQLite.DB,
    varstosavearr::Vector{String},
    syear::Vector{String},
    firstscenarioyear::Int,
    lastscenarioyear::Int,
    lastmodeledyear::String,
    yearintervalsdict::Dict{String, Int},
    limitedforesight::Bool,
    finalgroupyears::Bool,
    solvedtmstr::String,
    reportzeros::Bool = false,
    quiet::Bool = false)

    # BEGIN: Determine which price outputs are requested.
    local saveslicenn::Bool = in("vfuelprice", varstosavearr)
    local saveslicenodal::Bool = in("vfuelpricenodal", varstosavearr)
    local savereceivednn::Bool = in("vfuelpriceannualreceived", varstosavearr)
    local savepaidnn::Bool = in("vfuelpriceannualpaid", varstosavearr)
    local savereceivednodal::Bool = in("vfuelpricenodalannualreceived", varstosavearr)
    local savepaidnodal::Bool = in("vfuelpricenodalannualpaid", varstosavearr)

    if !(saveslicenn || saveslicenodal || savereceivednn || savepaidnn || savereceivednodal || savepaidnodal)
        return
    end

    local hasnodal::Bool = haskey(modelvarindices, "vproductionnodal")  # Scenario includes nodal (transmission-modeled) fuels
    local needslicenn::Bool = saveslicenn || savereceivednn || savepaidnn  # Non-nodal slice prices feed their table and the regional annual tables
    local needslicenodal::Bool = (saveslicenodal || savereceivednn || savepaidnn || savereceivednodal || savepaidnodal) && hasnodal  # Nodal slice prices feed their tables, the nodal annual tables, and the regional annual roll-up of nodal fuels
    # END: Determine which price outputs are requested.

    # BEGIN: If model is a MIP, fix discrete variables and re-solve as an LP to obtain duals.
    local undo = nothing  # Restores model integrality; nothing if model is already an LP

    if any(v -> is_integer(v) || is_binary(v), all_variables(jumpmodel))
        undo = fix_discrete_variables(jumpmodel)
        optimize!(jumpmodel)
        logmsg("Re-solved model as an LP with discrete variables fixed at their optimal values in order to calculate fuel prices.")
    end
    # END: If model is a MIP, fix discrete variables and re-solve as an LP to obtain duals.

    try
        if !has_duals(jumpmodel)
            @warn "Solver did not provide dual values; fuel prices cannot be calculated (e.g., Cbc does not produce duals). Continuing with NEMO."
            return
        end

        # BEGIN: Build dictionaries for some parameters needed in fuel price calculations.
        local drdict::Dict{String, Float64} = Dict{String, Float64}()  # Maps regions to discount rates

        for row in SQLite.DBInterface.execute(db, "select r, cast(val as real) as val from DiscountRate_def")
            drdict[row[:r]] = row[:val]
        end

        local noderegion::Dict{String, String} = Dict{String, String}()  # Maps nodes to regions

        if needslicenodal
            for row in SQLite.DBInterface.execute(db, "select val, r from NODE")
                noderegion[row[:val]] = row[:r]
            end
        end

        local nddict::Dict{NTuple{3,String}, Float64} = Dict{NTuple{3,String}, Float64}()  # NodalDistributionDemand by (n,f,y)

        if needslicenodal
            for row in SQLite.DBInterface.execute(db, "select n, f, y, cast(val as real) as val from NodalDistributionDemand_def")
                nddict[(row[:n], row[:f], row[:y])] = row[:val]
            end
        end

        local fueldict::Dict{String, Int} = Dict{String, Int}()  # Maps fuels to fuel.timesliced
        local saddict::Dict{NTuple{3,String}, Float64} = Dict{NTuple{3,String}, Float64}()  # SpecifiedAnnualDemand by (r,f,y) for non time-sliced fuels
        
        if savepaidnn
            for row in SQLite.DBInterface.execute(db, "select val, timesliced from FUEL")
                fueldict[row[:val]] = row[:timesliced]
            end

            for row in SQLite.DBInterface.execute(db, "select sad.r, sad.f, sad.y, cast(sad.val as real) as val from SpecifiedAnnualDemand_def sad, fuel f where sad.f = f.val and f.timesliced = 0 and sad.val <> 0")
                saddict[(row[:r], row[:f], row[:y])] = row[:val]
            end
        end

        local aaddict::Dict{NTuple{3,String}, Float64} = Dict{NTuple{3,String}, Float64}()  # AccumulatedAnnualDemand by (r,f,y)
        
        if savepaidnn || savepaidnodal
            for row in SQLite.DBInterface.execute(db, "select r, f, y, cast(val as real) as val from AccumulatedAnnualDemand_def where val <> 0")
                aaddict[(row[:r], row[:f], row[:y])] = row[:val]
            end
        end
        # END: Build dictionaries for some parameters needed in fuel price calculations.

        # BEGIN: Define function to cache undiscounting multipliers by (region, year).
        local multcache::Dict{NTuple{2,String}, Float64} = Dict{NTuple{2,String}, Float64}()

        local function undiscmult(r::String, y::String)
            return get!(multcache, (r, y)) do
                activitycostundiscountmultiplier(get(drdict, r, 0.0), y, syear, yearintervalsdict,
                    firstscenarioyear, lastscenarioyear, (y == lastmodeledyear) && (!limitedforesight || finalgroupyears))
            end
        end
        # END: Define function to cache undiscounting multipliers by (region, year).

        # BEGIN: Fetch production and consumption variable containers.
        local prodnn = needslicenn ? modelvarindices["vproductionnn"][1] : nothing
        local demnn = needslicenn ? modelvarindices["vdemandnn"][1] : nothing
        local usenn = (needslicenn || needslicenodal) ? modelvarindices["vusenn"][1] : nothing
        local prodnodal = needslicenodal ? modelvarindices["vproductionnodal"][1] : nothing
        local demnodal = needslicenodal ? modelvarindices["vdemandnodal"][1] : nothing
        local usenodal = needslicenodal ? modelvarindices["vusenodal"][1] : nothing
        local useannualnn = (savepaidnn || savepaidnodal) ? modelvarindices["vuseannualnn"][1] : nothing
        # END: Fetch production and consumption variable containers.

        # BEGIN: Define helper function to calculate nodal consumption in a time slice.
        # Consumption of a nodal fuel at a node in a time slice, including non-nodal-technology use distributed
        #   to the node via NodalDistributionDemand (the vusenn * ndd term in EBa11Tr_EnergyBalanceEachTS5)
        local function nodalconsumption(k::NTuple{4,String})  # k = (n,l,f,y)
            return value(demnodal[k[1], k[2], k[3], k[4]]) + value(usenodal[k[1], k[2], k[3], k[4]]) +
                value(usenn[noderegion[k[1]], k[2], k[3], k[4]]) * get(nddict, (k[1], k[3], k[4]), 0.0)
        end
        # END: Define helper function to calculate nodal consumption in a time slice.

        # BEGIN: Calculate time slice prices (omit slices with no throughput).
        local slicepricesnn::Dict{NTuple{4,String}, Float64} = Dict{NTuple{4,String}, Float64}()  # Maps (r,l,f,y) to price

        if needslicenn
            for (k, con) in eba11_refs  # k = (r,l,f,y)
                local r = k[1]; local f = k[3]; local y = k[4]
                
                (value(prodnn[r,k[2],f,y]) == 0.0 && value(demnn[r,k[2],f,y]) == 0.0
                    && value(usenn[r,k[2],f,y]) == 0.0) && continue
                
                local annualdual::Float64 = haskey(ebb5_refs, (r, f, y)) ? dual(ebb5_refs[(r, f, y)]) : 0.0
                slicepricesnn[k] = (dual(con) + annualdual) * undiscmult(r, y)
            end
        end

        local slicepricesnodal::Dict{NTuple{4,String}, Float64} = Dict{NTuple{4,String}, Float64}()  # Maps (n,l,f,y) to price

        if needslicenodal
            for (k, con) in eba11tr_refs  # k = (n,l,f,y)
                local n = k[1]; local f = k[3]; local y = k[4]
                
                (value(prodnodal[n,k[2],f,y]) == 0.0 && nodalconsumption(k) == 0.0) && continue
                
                local annualdual::Float64 = haskey(ebb5tr_refs, (n, f, y)) ? dual(ebb5tr_refs[(n, f, y)]) : 0.0
                slicepricesnodal[k] = (dual(con) + annualdual) * undiscmult(get(noderegion, n, ""), y)
            end
        end
        # END: Calculate time slice prices.

        local receivednn::Dict{NTuple{3,String}, Float64} = Dict{NTuple{3,String}, Float64}()   # vfuelpriceannualreceived - maps (r,f,y) to price
        local paidnn::Dict{NTuple{3,String}, Float64} = Dict{NTuple{3,String}, Float64}()       # vfuelpriceannualpaid - maps (r,f,y) to price
        local receivednodal::Dict{NTuple{3,String}, Float64} = Dict{NTuple{3,String}, Float64}() # vfuelpricenodalannualreceived - maps (n,f,y) to price
        local paidnodal::Dict{NTuple{3,String}, Float64} = Dict{NTuple{3,String}, Float64}()     # vfuelpricenodalannualpaid - maps (n,f,y) to price

        # BEGIN: Calculate regional annual prices (received and paid), covering non-nodal and nodal fuels.
        if savereceivednn || savepaidnn
            local prodannualnn = modelvarindices["vproductionannualnn"][1]
            local demannualnn = modelvarindices["vdemandannualnn"][1]

            # Non-nodal fuels
            local slicegroupsnn::Dict{NTuple{3,String}, Vector{NTuple{4,String}}} = Dict{NTuple{3,String}, Vector{NTuple{4,String}}}()  # Dictionary mapping (r,f,y) to a vector of (r,l,f,y) keys for the time slice prices for that region, fuel, and year

            for k in keys(slicepricesnn)
                push!(get!(slicegroupsnn, (k[1], k[3], k[4]), Vector{NTuple{4,String}}()), k)
            end

            for rfy in union(keys(slicegroupsnn), keys(ebb5_refs))
                if haskey(slicegroupsnn, rfy)
                    # Time-sliced fuel: weighted average of slice prices
                    if savereceivednn
                        local p = weightedprice(slicegroupsnn[rfy], slicepricesnn, k -> value(prodnn[k[1],k[2],k[3],k[4]]))
                        p !== nothing && (receivednn[rfy] = p)
                    end
                    if savepaidnn
                        local p = weightedprice(slicegroupsnn[rfy], slicepricesnn, k -> value(demnn[k[1],k[2],k[3],k[4]]) + value(usenn[k[1],k[2],k[3],k[4]]))
                        p !== nothing && (paidnn[rfy] = p)
                    end
                else
                    # Non-time-sliced fuel: single annual dual, included where produced (received) / consumed (paid)
                    local val = dual(ebb5_refs[rfy]) * undiscmult(rfy[1], rfy[3])
                    if savereceivednn && value(prodannualnn[rfy[1],rfy[2],rfy[3]]) != 0.0
                        receivednn[rfy] = val
                    end
                    if savepaidnn && ((fueldict[rfy[2]] == 1 ? value(demannualnn[rfy[1],rfy[2],rfy[3]]) : 0.0) + value(useannualnn[rfy[1],rfy[2],rfy[3]]) + get(aaddict, (rfy[1], rfy[2], rfy[3]), 0.0) + get(saddict, (rfy[1], rfy[2], rfy[3]), 0.0)) != 0.0
                        paidnn[rfy] = val
                    end
                end
            end

            # Nodal fuels rolled up to their region
            if needslicenodal
                local nodalgroups::Dict{NTuple{3,String}, Vector{NTuple{4,String}}} = Dict{NTuple{3,String}, Vector{NTuple{4,String}}}()  # Dictionary mapping (r,f,y) to a vector of (n,l,f,y) keys for the nodal time slice prices for that region, fuel, and year

                for k in keys(slicepricesnodal)
                    push!(get!(nodalgroups, (noderegion[k[1]], k[3], k[4]), Vector{NTuple{4,String}}()), k)
                end

                for (rfy, ks) in nodalgroups
                    if savereceivednn
                        local p = weightedprice(ks, slicepricesnodal, k -> value(prodnodal[k[1],k[2],k[3],k[4]]))
                        p !== nothing && (receivednn[rfy] = p)
                    end
                    if savepaidnn
                        local p = weightedprice(ks, slicepricesnodal, nodalconsumption)
                        p !== nothing && (paidnn[rfy] = p)
                    end
                end
            end
        end
        # END: Calculate regional annual prices (received and paid), covering non-nodal and nodal fuels.

        # BEGIN: Calculate nodal annual prices (received and paid), per node.
        if (savereceivednodal || savepaidnodal) && hasnodal
            local prodannualnodal = modelvarindices["vproductionannualnodal"][1]
            local demannualnodal = modelvarindices["vdemandannualnodal"][1]
            local useannualnodal = modelvarindices["vuseannualnodal"][1]

            local slicegroupsnodal::Dict{NTuple{3,String}, Vector{NTuple{4,String}}} = Dict{NTuple{3,String}, Vector{NTuple{4,String}}}()  # Dictionary mapping (n,f,y) to a vector of (n,l,f,y) keys for the time slice prices for that node, fuel, and year

            for k in keys(slicepricesnodal)
                push!(get!(slicegroupsnodal, (k[1], k[3], k[4]), Vector{NTuple{4,String}}()), k)
            end

            for nfy in union(keys(slicegroupsnodal), keys(ebb5tr_refs))
                if haskey(slicegroupsnodal, nfy)
                    if savereceivednodal
                        local p = weightedprice(slicegroupsnodal[nfy], slicepricesnodal, k -> value(prodnodal[k[1],k[2],k[3],k[4]]))
                        p !== nothing && (receivednodal[nfy] = p)
                    end
                    if savepaidnodal
                        local p = weightedprice(slicegroupsnodal[nfy], slicepricesnodal, nodalconsumption)
                        p !== nothing && (paidnodal[nfy] = p)
                    end
                else
                    local val = dual(ebb5tr_refs[nfy]) * undiscmult(get(noderegion, nfy[1], ""), nfy[3])
                    if savereceivednodal && value(prodannualnodal[nfy[1],nfy[2],nfy[3]]) != 0.0
                        receivednodal[nfy] = val
                    end
                    if savepaidnodal && (value(demannualnodal[nfy[1],nfy[2],nfy[3]]) + value(useannualnodal[nfy[1],nfy[2],nfy[3]]) + value(useannualnn[noderegion[nfy[1]],nfy[2],nfy[3]]) * get(nddict, nfy, 0.0) + get(aaddict, (noderegion[nfy[1]], nfy[2], nfy[3]), 0.0) * get(nddict, nfy, 0.0)) != 0.0
                        paidnodal[nfy] = val
                    end
                end
            end
        end
        # END: Calculate nodal annual prices (received and paid), per node.

        # BEGIN: Save requested price tables.
        saveslicenn       && savefuelpricetable(db, "vfuelprice", ["r","l","f","y"], slicepricesnn, solvedtmstr, reportzeros, quiet)
        saveslicenodal    && savefuelpricetable(db, "vfuelpricenodal", ["n","l","f","y"], slicepricesnodal, solvedtmstr, reportzeros, quiet)
        savereceivednn    && savefuelpricetable(db, "vfuelpriceannualreceived", ["r","f","y"], receivednn, solvedtmstr, reportzeros, quiet)
        savepaidnn        && savefuelpricetable(db, "vfuelpriceannualpaid", ["r","f","y"], paidnn, solvedtmstr, reportzeros, quiet)
        savereceivednodal && savefuelpricetable(db, "vfuelpricenodalannualreceived", ["n","f","y"], receivednodal, solvedtmstr, reportzeros, quiet)
        savepaidnodal     && savefuelpricetable(db, "vfuelpricenodalannualpaid", ["n","f","y"], paidnodal, solvedtmstr, reportzeros, quiet)
        # END: Save requested price tables.
    finally
        if !isnothing(undo)
            undo()  # Restore model integrality (invalidates the LP solution, so this is the last step)
        end
    end
end  # calculatefuelprices(...)