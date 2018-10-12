#=
    NEMO: Next-generation Energy Modeling system for Optimization.
    https://github.com/sei-international/NemoMod.jl

    Copyright © 2018: Stockholm Environment Institute U.S.

    Release 0.1: Julia version of OSeMOSYS version 2017_11_08.  http://www.osemosys.org/

    File description: Functions for ahead-of-time compilation of NEMO.
=#

using PackageCompiler

"""Generates a new Julia system image that includes the NemoMod package. The package is optimized and compiled into the system image
    based on the use cases in NemoMod/test/runtests.jl (i.e., the standard NemoMod test cases). The existing system image is replaced unless
    the replacesysimage argument is false."""
function compilenemo(replacesysimage::String = true)
    PackageCompiler.compile_package("NemoMod"; force = replacesysimage, cpu_target = "native")
end  # compilenemo()
