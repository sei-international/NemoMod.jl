using JuMP

rows = RemoteChannel(()->Channel{Int}(32))
constraints = RemoteChannel(()->Channel{Any}(32))
m = Model()
limit = 10
@variable(m, x[1:limit])
@constraintref test[1:limit]

function constraint_parallel()
    i = limit

    @async compilerows()

    for p in workers()
        @async remote_do(make_constraint, p, m, rows, constraints)
    end

    while i > 0
        test[i] = take!(constraints)
        i = i - 1
    end
end

function compilerows()
    for i in 1:limit
        put!(rows, i)
    end
end

function make_constraint(m::JuMP.Model, rows::RemoteChannel, constraints::RemoteChannel)
    while isready(rows)
        z = take!(rows)
        #put!(constraints, @LinearConstraint(:x[z] >= 0)
    end
end

function constraint_serial()
    for i = 1:limit
        test[i] = @constraint(m, x[i] >= 0)
    end
end
