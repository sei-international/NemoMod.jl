#=
    NEMO: Next-generation Energy Modeling system for Optimization.
    https://github.com/sei-international/NemoMod.jl

    Copyright © 2018: Stockholm Environment Institute U.S.

    Release 0.1: Julia version of OSeMOSYS version 2017_11_08.  http://www.osemosys.org/

    File description: Utilities for ahead-of-time compilation of NEMO. Typical usage in a REPL session:
        using NemoMod
        include(joinpath(NemoMod.packagedirectory(), "utils", "compilation.jl"))
        compilenemo()
=#

using PackageCompiler

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

"""Generates a new Julia system image that includes the NemoMod package. The package is optimized and compiled into the system image
    based on the use cases in NemoMod/test/runtests.jl (i.e., the standard NemoMod test cases). The existing system image is replaced unless
    replacesysimage = false."""
function compilenemo(replacesysimage::Bool = true)
    snoop_userimg_nemo(PackageCompiler.sysimg_folder("precompile.jl"), ("NemoMod", normpath(joinpath(@__DIR__, "..", "test", "runtests.jl"))))
    PackageCompiler.compile_package("NemoMod"; reuse = true, force = replacesysimage, cpu_target = "native")
end  # compilenemo()
