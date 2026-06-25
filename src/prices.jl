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
    prodweightedprice(slicekeys::Vector{NTuple{4,String}}, prices::Dict{NTuple{4,String},Float64},
        prodvar) -> Float64

Returns the production-weighted average of the prices in `prices` for the keys in `slicekeys`,
using `value(prodvar[k...])` as the weight for each key `k`. `prodvar` is a JuMP variable
container indexed identically to the keys (e.g. `vproductionnn` or `vproductionnodal`).
"""
function prodweightedprice(slicekeys::Vector{NTuple{4,String}}, prices::Dict{NTuple{4,String},Float64}, prodvar)
    local wsum::Float64 = 0.0   # Sum of production weights
    local pwsum::Float64 = 0.0  # Sum of price * weight

    for k in slicekeys
        local w::Float64 = value(prodvar[k[1], k[2], k[3], k[4]])
        pwsum += prices[k] * w
        wsum += w
    end

    return pwsum / wsum
end  # prodweightedprice(...)

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

Calculates fuel price outputs for a solved scenario from the duals of its energy balance
constraints and saves the requested price tables to `db`. Recognized outputs in `varstosavearr`:
- `vfuelprice` (region, time slice, fuel, year) and `vfuelpricenodal` (node, time slice, fuel,
  year): the sum of the time slice and annual energy balance duals, converted to nominal currency.
- `vfuelpriceannual` (region, fuel, year): a production-weighted annual price covering both
  non-nodal and nodal fuels.
- `vfuelpricenodalannual` (node, fuel, year): a production-weighted annual price per node.

If `jumpmodel` contains integer or binary variables, they are fixed at their optimal values and
the model is re-solved as an LP so that meaningful duals are available; the model's integrality
is restored before the function returns. If the solver does not provide duals (e.g., Cbc), a
warning is logged and no price tables are saved. `syear` must be the solve's modeled years sorted
ascending; `lastmodeledyear` is its last element.
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
    local saveannualnn::Bool = in("vfuelpriceannual", varstosavearr)
    local saveannualnodal::Bool = in("vfuelpricenodalannual", varstosavearr)

    if !(saveslicenn || saveannualnn || saveslicenodal || saveannualnodal)
        return
    end

    local hasnodal::Bool = haskey(modelvarindices, "vproductionnodal")  # Indicates whether the scenario includes nodal (transmission-modeled) fuels
    local needslicenn::Bool = saveslicenn || saveannualnn  # Non-nodal time slice prices feed both their own table and the annual table
    local needslicenodal::Bool = (saveslicenodal || saveannualnodal || saveannualnn) && hasnodal  # Nodal time slice prices feed their own table, the nodal annual table, and the regional annual table (for nodal fuels)
    # END: Determine which price outputs are requested.

    # BEGIN: If model is a MIP, fix discrete variables and re-solve as an LP to obtain duals.
    local undo = nothing  # Function that restores model integrality; nothing if model is already an LP

    if any(v -> is_integer(v) || is_binary(v), all_variables(jumpmodel))
        undo = fix_discrete_variables(jumpmodel)  # Fixes integer/binary variables at current values and relaxes integrality
        optimize!(jumpmodel)
        logmsg("Re-solved model as an LP with discrete variables fixed at their optimal values in order to calculate fuel prices.")
    end
    # END: If model is a MIP, fix discrete variables and re-solve as an LP to obtain duals.

    try
        if !has_duals(jumpmodel)
            @warn "Solver did not provide dual values; fuel prices cannot be calculated (e.g., Cbc does not produce duals). Continuing with NEMO."
            return
        end

        # Production variables used to limit prices to time slices with production
        local prodnn = modelvarindices["vproductionnn"][1]  # vproductionnn container
        local prodnodal = hasnodal ? modelvarindices["vproductionnodal"][1] : nothing  # vproductionnodal container (nothing if no nodal modeling)        

        # BEGIN: Build per-region discount rates and node-to-region map for undiscounting.
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
        # END: Build per-region discount rates and node-to-region map for undiscounting.

        # BEGIN: Define function to cache undiscounting multipliers by (region, year).
        local multcache::Dict{NTuple{2,String}, Float64} = Dict{NTuple{2,String}, Float64}()

        local function undiscmult(r::String, y::String)
            return get!(multcache, (r, y)) do
                activitycostundiscountmultiplier(get(drdict, r, 0.0), y, syear, yearintervalsdict,
                    firstscenarioyear, lastscenarioyear, (y == lastmodeledyear) && (!limitedforesight || finalgroupyears))
            end
        end
        # END: Define function to cache undiscounting multipliers by (region, year).

        # Note: Straight duals from JuMP are appropriate for pricing because all four constraints used (eba11, eba11tr, ebb5, ebb5tr) are formulated as (production - consumption) >= 0 (or a constant for exogenous demand). In JuMP, "a feasible dual on a >= constraint is nonnegative" (https://jump.dev/JuMP.jl/stable/manual/constraints/#constraint_duality). The duals thus represent the change in total discounted costs for a unit increase in demand.

        # BEGIN: Calculate time slice prices (sum of time slice and annual balance duals, undiscounted).
        local slicepricesnn::Dict{NTuple{4,String}, Float64} = Dict{NTuple{4,String}, Float64}()  # vfuelprice, keyed by (r,l,f,y)

        if needslicenn
            for (k, con) in eba11_refs  # k = (r,l,f,y)
                value(prodnn[k[1], k[2], k[3], k[4]]) == 0.0 && continue  # No production => degenerate dual and no price received; omit

                local r = k[1]; local f = k[3]; local y = k[4]
                local annualdual::Float64 = haskey(ebb5_refs, (r, f, y)) ? dual(ebb5_refs[(r, f, y)]) : 0.0
                slicepricesnn[k] = (dual(con) + annualdual) * undiscmult(r, y)

                #= if k[3] == ("gas")  # Example of logging a specific nodal price for debugging
                    @info "dual(con) = $(dual(con)), annualdual = $annualdual, undiscmult = $(undiscmult(r, y)), slicepricesnn[$k] = $(slicepricesnn[k])"
                    println(con)
                end =#
            end
        end

        local slicepricesnodal::Dict{NTuple{4,String}, Float64} = Dict{NTuple{4,String}, Float64}()  # vfuelpricenodal, keyed by (n,l,f,y)

        if needslicenodal
            for (k, con) in eba11tr_refs  # k = (n,l,f,y)
                value(prodnodal[k[1], k[2], k[3], k[4]]) == 0.0 && continue  # No production => degenerate dual and no price received; omit

                local n = k[1]; local f = k[3]; local y = k[4]
                local annualdual::Float64 = haskey(ebb5tr_refs, (n, f, y)) ? dual(ebb5tr_refs[(n, f, y)]) : 0.0
                slicepricesnodal[k] = (dual(con) + annualdual) * undiscmult(get(noderegion, n, ""), y)
            end
        end
        # END: Calculate time slice prices.

        # BEGIN: Calculate regional annual prices (vfuelpriceannual) for non-nodal and nodal fuels.
        local annualpricesnn::Dict{NTuple{3,String}, Float64} = Dict{NTuple{3,String}, Float64}()  # keyed by (r,f,y)

        if saveannualnn
            local prodannualnn = modelvarindices["vproductionannualnn"][1]

            # Non-nodal fuels: production-weighted average of non-nodal time slice prices; non-timesliced fuels take the annual dual directly; fuels without any production are omitted
            local slicegroupsnn::Dict{NTuple{3,String}, Vector{NTuple{4,String}}} = Dict{NTuple{3,String}, Vector{NTuple{4,String}}}()  # Dictionary mapping (r,f,y) to a vector of (r,l,f,y) keys for the time slice prices in that region, fuel, and year

            for k in keys(slicepricesnn)
                push!(get!(slicegroupsnn, (k[1], k[3], k[4]), Vector{NTuple{4,String}}()), k)
            end

            for rfy in union(keys(slicegroupsnn), keys(ebb5_refs))
                if haskey(slicegroupsnn, rfy)
                    annualpricesnn[rfy] = prodweightedprice(slicegroupsnn[rfy], slicepricesnn, prodnn)
                elseif value(prodannualnn[rfy[1], rfy[2], rfy[3]]) != 0.0
                    annualpricesnn[rfy] = dual(ebb5_refs[rfy]) * undiscmult(rfy[1], rfy[3])
                end
            end

            # Nodal fuels: production-weighted average of nodal time slice prices over all nodes in the region
            if needslicenodal
                local nodalgroups::Dict{NTuple{3,String}, Vector{NTuple{4,String}}} = Dict{NTuple{3,String}, Vector{NTuple{4,String}}}()  # Dictionary mapping (r,f,y) to a vector of (n,l,f,y) keys for the nodal time slice prices in that region, fuel, and year

                for k in keys(slicepricesnodal)  # k = (n,l,f,y); group by (region of n, f, y)
                    push!(get!(nodalgroups, (noderegion[k[1]], k[3], k[4]), Vector{NTuple{4,String}}()), k)
                end

                for (rfy, ks) in nodalgroups
                    annualpricesnn[rfy] = prodweightedprice(ks, slicepricesnodal, prodnodal)
                end
            end
        end
        # END: Calculate regional annual prices.

        # BEGIN: Calculate nodal annual prices (vfuelpricenodalannual).
        local annualpricesnodal::Dict{NTuple{3,String}, Float64} = Dict{NTuple{3,String}, Float64}()  # keyed by (n,f,y)

        if saveannualnodal && hasnodal
            local prodannualnodal = modelvarindices["vproductionannualnodal"][1]
            local slicegroupsnodal::Dict{NTuple{3,String}, Vector{NTuple{4,String}}} = Dict{NTuple{3,String}, Vector{NTuple{4,String}}}()  # Dictionary mapping (n,f,y) to a vector of (n,l,f,y) keys for the time slice prices in that node, fuel, and year

            for k in keys(slicepricesnodal)
                push!(get!(slicegroupsnodal, (k[1], k[3], k[4]), Vector{NTuple{4,String}}()), k)
            end

            for nfy in union(keys(slicegroupsnodal), keys(ebb5tr_refs))
                if haskey(slicegroupsnodal, nfy)
                    annualpricesnodal[nfy] = prodweightedprice(slicegroupsnodal[nfy], slicepricesnodal, prodnodal)
                elseif value(prodannualnodal[nfy[1], nfy[2], nfy[3]]) != 0.0
                    annualpricesnodal[nfy] = dual(ebb5tr_refs[nfy]) * undiscmult(get(noderegion, nfy[1], ""), nfy[3])
                end
            end
        end
        # END: Calculate nodal annual prices.

        # BEGIN: Save requested price tables.
        if saveslicenn
            savefuelpricetable(db, "vfuelprice", ["r", "l", "f", "y"], slicepricesnn, solvedtmstr, reportzeros, quiet)
        end

        if saveannualnn
            savefuelpricetable(db, "vfuelpriceannual", ["r", "f", "y"], annualpricesnn, solvedtmstr, reportzeros, quiet)
        end

        if saveslicenodal
            savefuelpricetable(db, "vfuelpricenodal", ["n", "l", "f", "y"], slicepricesnodal, solvedtmstr, reportzeros, quiet)
        end

        if saveannualnodal
            savefuelpricetable(db, "vfuelpricenodalannual", ["n", "f", "y"], annualpricesnodal, solvedtmstr, reportzeros, quiet)
        end
        # END: Save requested price tables.
    finally
        if !isnothing(undo)
            undo()  # Restore model integrality (invalidates the LP solution, so this is the last step)
        end
    end
end  # calculatefuelprices(...)