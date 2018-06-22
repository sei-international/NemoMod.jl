"""Generates Dicts that can be used to restrict JuMP constraints or variables to selected indices
(rather than all values in their dimensions) at creation. Requires two arguments:
    1) df - The results of a query that selects the index values.
    2) numdicts - The number of Dicts that should be created.  The first Dict is for the first field in
        the query, the second is for the first two fields in the query, and so on.  Dict keys are arrays
        of the values of the key fields to which the Dict corresponds, and Dict values are Sets of corresponding
        values in the next field of the query (field #2 for the first Dict, field #3 for the second Dict, and so on).
Returns an array of the generated Dicts."""
function keydicts(df::DataFrames.DataFrame, numdicts::Int)
    local returnval = Array{Dict{Array{String,1},Set{String}},1}()  # Function return value

    # Set up empty dictionaries in returnval
    for i in 1:numdicts
        push!(returnval, Dict{Array{String,1},Set{String}}())
    end

    # Populate dictionaries using df
    for row in eachrow(df)
        for j in 1:numdicts
            if !haskey(returnval[j], [get(row[k]) for k = 1:j])
                returnval[j][[get(row[k]) for k = 1:j]] = Set{String}()
            end

            push!(returnval[j][[get(row[k]) for k = 1:j]], get(row[j+1]))
        end
    end

    return returnval
end  # keydicts(df::DataFrames.DataFrame, numdicts::Int)

"""Runs keydicts using parallel worker processes if available and there are at least 10,000 rows in df for each
worker process."""
function keydicts_parallel(df::DataFrames.DataFrame, numdicts::Int)
    local returnval = Array{Dict{Array{String,1},Set{String}},1}()  # Function return value
    local np = nprocs()  # Number of active processes
    local dfrows = size(df)[1]  # Number of rows in df

    if np == 1 || div(dfrows, np-1) < 10000
        # Run keydicts for entire df
        returnval = keydicts(df, numdicts)
    else
        # Divide operation among worker processes
        local blockdivrem = divrem(dfrows, np-1)  # Quotient and remainder from dividing dfrows by np-1; element 1 = quotient, element 2 = remainder
        local results = Array{typeof(returnval), 1}(np-1)  # Collection of results from async processing

        # Dispatch async tasks in main process, each of which performs a remotecall_fetch on a worker process. Wrap in sync block to wait until all async processes
        #   finish before proceeding.
        @sync begin
            for p=2:np
                @async begin
                    # Pass each process a block of rows from df
                    results[p-1] = remotecall_fetch(keydicts, workers()[p-1], df[((p-2) * blockdivrem[1] + 1):((p-1) * blockdivrem[1] + (p == np ? blockdivrem[2] : 0)),:], numdicts)
                end
            end
        end

        # Merge results from async tasks
        for i = 1:numdicts
            push!(returnval, Dict{Array{String,1},Set{String}}())

            for j = 1:np-1
                returnval[i] = merge(union, returnval[i], results[j][i])
            end
        end
    end

    return returnval
end  # keydicts_parallel(df::DataFrames.DataFrame, numdicts::Int)
