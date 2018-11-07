#=
    NEMO: Next-generation Energy Modeling system for Optimization.
    https://github.com/sei-international/NemoMod.jl

    Copyright © 2018: Stockholm Environment Institute U.S.

    Release 0.1: Julia version of OSeMOSYS version 2017_11_08.  http://www.osemosys.org/

    File description: Utilities for ahead-of-time compilation of NEMO. Typical usage in a REPL session:
        using NemoMod
        include(normpath(joinpath(pathof(NemoMod), "..", "..", "utils", "compilation.jl")))
        compilenemo()
=#

using PackageCompiler, Libdl, NemoMod

"""Clone of PackageCompiler.snoop_userimg(). Implemented here in order to allow a custom blacklist to be passed to PackageCompiler.snoop().
    This should be a temporary measure eventually obviated by upgrades to PackageCompiler (i.e., for compatability with Julia 1.0)."""
function snoop_userimg_nemo(userimg, packages::Tuple{String, String}...)
    snooped_precompiles = map(packages) do package_snoopfile
        package, snoopfile = package_snoopfile
        abs_package_path = if ispath(package)
            normpath(abspath(package))
        else
            normpath(Base.find_package(package), "..", "..")
        end
        file2snoop = normpath(abspath(joinpath(abs_package_path, snoopfile)))
        package = PackageCompiler.package_folder(PackageCompiler.get_root_dir(abs_package_path))
        isdir(package) || mkpath(package)
        precompile_file = joinpath(package, "precompile.jl")
        PackageCompiler.snoop(file2snoop, precompile_file, joinpath(package, "snooped.csv"),
            Vector{Pair{String, String}}(), String["Main", ", _}"])
        return precompile_file
    end
    # merge all of the temporary files into a single output
    open(userimg, "w") do output
        println(output, """
            # Prevent this from being put into the Main namespace
            Core.eval(Module(), quote
            """)
        for (pkg, _) in packages
            println(output, """
                import $pkg
                """)
        end
        println(output, """
            for m in Base.loaded_modules_array()
                Core.isdefined(@__MODULE__, nameof(m)) || Core.eval(@__MODULE__, Expr(:(=), nameof(m), m))
            end
            """)
        for path in snooped_precompiles
            open(input -> write(output, input), path)
            println(output)
        end
        println(output, """
            end) # eval
            """)
    end
    nothing
end  # snoop_userimg_nemo(userimg, packages::Tuple{String, String}...)

"""Generates a new Julia system image including specified additional packages. Arguments:
    • replacesysimage - Indicates whether the existing system image should be overwritten with the new image. If false, the new image is saved
        in a different directory (reported at the end of the function's execution).
    • packagesandusecases - One or more tuples of the following form:
        > First item - Name of the additional package to be included in the new system image.
        > Second item - Use cases that determine what functionality of the package is included in the new system image.
Example invocations:
    • compilenemo() - New system image includes NemoMod with compiled functionality based on standard NemoMod test cases. Support for GLPK solver is included
        in new system image since it's NEMO's default solver. Existing system image is overwritten.
    • compilenemo(true, ("NemoMod", normpath(joinpath(pathof(NemoMod), "..", "..", "test", "runtests.jl"))),
        ("CPLEX", normpath(joinpath(pathof(NemoMod), "..", "..", "test", "test_cplex.jl")))) - New system image includes NemoMod and CPLEX; compiled functionality
        is based on standard NemoMod test cases plus a supplemental test case for CPLEX. Support for GLPK and CPLEX solvers is included in new system image.
        Existing system image is overwritten.
    • compilenemo(false, ("NemoMod", normpath(joinpath(pathof(NemoMod), "..", "..", "test", "runtests.jl"))),
        ("CPLEX", normpath(joinpath(pathof(NemoMod), "..", "..", "test", "test_cplex.jl")))) - Same as above but existing system image is not overwritten. New
        system image is saved in a directory reported at end of function execution."""
function compilenemo(replacesysimage::Bool = true, packagesandusecases::Tuple{String, String}...=("NemoMod", normpath(joinpath(pathof(NemoMod), "..", "..", "test", "runtests.jl"))))
    # Restore stock system image to avoid conflicts
    PackageCompiler.revert()

    # Create snooping file
    snoop_userimg_nemo(PackageCompiler.sysimg_folder("precompile.jl"), packagesandusecases...)

    # To avoid a copying error at the end of compile_package(), manually remove any pre-existing back-up of system image in Julia system image folder
    rm(joinpath(PackageCompiler.default_sysimg_path(false), "sys.$(Libdl.dlext)") * ".packagecompiler_backup"; force = true)

    PackageCompiler.compile_package("NemoMod"; reuse = true, force = replacesysimage, cpu_target = "native")
end  # compilenemo()
