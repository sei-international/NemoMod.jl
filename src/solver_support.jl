#=
    NEMO: Next-generation Energy Modeling system for Optimization.
    https://github.com/sei-international/NemoMod.jl

    Copyright © 2020: Stockholm Environment Institute U.S.

    File description: Functions for working with solvers.
=#

"""
    can_init_xpress()

Implements logic from `Xpress.get_xpauthpath` to determine if it's safe to load Xpress within NEMO.
    Returns `true` or `false`.
"""
function can_init_xpress()
    XPAUTH = "xpauth.xpr"

    paths_to_try::Array{String, 1} = Array{String, 1}()
    push!(paths_to_try, XPAUTH)

    if haskey(ENV, "XPAUTH_PATH")
        push!(paths_to_try, joinpath(ENV["XPAUTH_PATH"], XPAUTH))
    end

    if haskey(ENV, "XPRESSDIR")
        push!(paths_to_try, joinpath(ENV["XPRESSDIR"], "bin", XPAUTH))
    end

    push!(paths_to_try, joinpath("bin", XPAUTH))

    for p in paths_to_try
        if isfile(p)
            return true
        end
    end

    return false
end  # can_init_xpress()
