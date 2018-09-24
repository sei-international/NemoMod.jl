# Custom types that implement DataStreams.Data.Source interface - used for streaming results into NGen database.

# BEGIN: Source type for JuMP data containers.
struct jumpsource <: Data.Source
    schema::Data.Schema
    jc::JuMP.JuMPContainer
    slvdtm::String  # Using ISO8601 string representation of DateTime for compatibility with SQLite
end

"""Main constructor for a jumpsource based on a JuMPArray. Required parameters:
    - ja - The JuMPArray. Should be the result of a JuMP getvalue() call.
    - colnames - An array of column names for the indices in ja. The name "val" is added for the values in ja, and "solvedtm" is added for the solve date/time associated with ja."""
function jumpsource(ja::JuMP.JuMPArray, colnames::Array{String,1})
    local coltypes::Array{DataType,1} = Array{DataType,1}()  # Array of column types in ja

    for i in ja.indexsets
        push!(coltypes, typeof(i[1]))
    end

    # Add type for val - always a floating-point value per JuMP getvalue() documentation
    push!(coltypes, Float64)

    # Add type for solvedtm
    push!(coltypes, String)

    schema = Data.Schema(union(colnames, ["val", "solvedtm"]), coltypes, length(ja.innerArray))
    return jumpsource(schema, ja, Base.Dates.format(solvedtm,"yyyy-mm-dd HH:MM:SS.sss"))
end

"""Main constructor for a jumpsource based on a JuMPDict. Required parameters:
    - jd - The JuMPDict. Should be the result of a JuMP getvalue() call.
    - colnames - An array of column names for the indices in jd. The name "val" is added for the values in jd, and "solvedtm" is added for the solve date/time associated with jd."""
function jumpsource(jd::JuMP.JuMPDict, colnames::Array{String,1})
    local coltypes::Array{DataType,1} = Array{DataType,1}()  # Array of column types in jd
    local firstkey::NTuple = collect(keys(jd.tupledict))[1]  # First key in jd

    for i = 1:length(firstkey)
        push!(coltypes, typeof(firstkey[i]))
    end

    # Add type for val - always a floating-point value per JuMP getvalue() documentation
    push!(coltypes, Float64)

    # Add type for solvedtm
    push!(coltypes, String)

    schema = Data.Schema(union(colnames, ["val", "solvedtm"]), coltypes, length(jd.tupledict))
    return jumpsource(schema, jd, Base.Dates.format(solvedtm,"yyyy-mm-dd HH:MM:SS.sss"))
end

Data.schema(source::jumpsource) = source.schema
Data.schema(source::jumpsource, ::Type{Data.Field}) = source.schema
Data.schema(source::jumpsource, ::Type{Data.Column}) = source.schema

function Data.isdone(source::jumpsource, row::Int, col::Int)
    row > size(source.schema)[1] || col > size(source.schema)[2]
end

Data.streamtype(::Type{jumpsource}, ::Type{Data.Field}) = true

function Data.streamfrom{T}(source::jumpsource, ::Type{Data.Field}, ::Type{T}, row::Int, col::Int)
    # Branch on type of JuMPContainer
    if source.jc isa JuMP.JuMPArray
        if col == size(source.schema)[2]  # Last column - i.e., solvedtm column
            return source.slvdtm
        elseif col == size(source.schema)[2] - 1  # Penultimate column - i.e., val column
            return source.jc.innerArray[row]
        else  # Index column
            local blocksize::Int = 1  # For target index set, how many rows elapse when cycling once through set's values (i.e., one block of values)
            local positioninblock::Int  # For target row, relative position in block in which it's located
            local repsofeachvalueinblock::Int = 1  # Number of times each value repeats in a block in target index set

            for i = 1:col
                blocksize *= length(source.jc.indexsets[i])
            end

            positioninblock = mod(row,blocksize)

            if positioninblock == 0  # Even division; last row in block
                positioninblock = blocksize
            end

            for i = 1:col-1
                repsofeachvalueinblock *= length(source.jc.indexsets[i])
            end

            return source.jc.indexsets[col][Int(ceil(positioninblock / repsofeachvalueinblock))]
        end
    elseif source.jc isa JuMP.JuMPDict
        if col == size(source.schema)[2]  # Last column - i.e., solvedtm column
            return source.slvdtm
        elseif col == size(source.schema)[2] - 1  # Penultimate column - i.e., val column
            return collect(values(source.jc.tupledict))[row]
        else  # Index column
            return collect(keys(source.jc.tupledict))[row][col]
        end
    end
end

#= Not supported in currently installed DataStreams package
function Data.reset!(source::jumpsource)
    return nothing
end

function Data.accesspattern(source::arraysource)
    return Data.RandomAccess
end
=#
# END: Source type for JuMP data containers.

#= x = NGen.jumpsource(JuMP.getvalue(NGen.tdc), ["r", "y"])
x = NGen.jumpsource(JuMP.getvalue(NGen.vru), ["r", "l", "t", "f", "y"])
dbpath = "C:\\temp\\utopia_2015_08_27.sl3"
db = SQLite.DB(dbpath)
SQLite.load(db, "AA1tdc", x)
=#

"""Saves model results to a SQLite database using DataStreams functionality. Requires three arguments:
    1) vars - Array of model variables for which results will be retrieved and saved to SQLite.
    2) modelvarindices - Dictionary mapping model variables to tuples of (variable name, [index column names]).
    3) db - SQLite database.
An interesting implementation of the DataStreams source interface for JuMP, but unfortunately the performance isn't adequate for large models."""
function savevarresultsds(vars::Array{JuMP.JuMPContainer,1}, modelvarindices::Dict{JuMP.JuMPContainer, Tuple{String,Array{String,1}}}, db::SQLite.DB)
    for v in vars
        # Need to modify code to capture variable name
        SQLite.load(db, modelvarindices[v][1], NGen.jumpsource(JuMP.getvalue(v), modelvarindices[v][2]))
    end
end  # savevarresultsds(vars::Array{JuMP.JuMPContainer,1}, modelvarindices::Dict{JuMP.JuMPContainer, Tuple{String,Array{String,1}}}, db::SQLite.DB)
