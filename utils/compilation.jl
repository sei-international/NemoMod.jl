#=
    NEMO: Next-generation Energy Modeling system for Optimization.
    https://github.com/sei-international/NemoMod.jl

    Copyright © 2018: Stockholm Environment Institute U.S.

    File description: Utilities for ahead-of-time compilation of |nemo. Typical usage in a REPL session:
        using NemoMod
        include(normpath(joinpath(pathof(NemoMod), "..", "..", "utils", "compilation.jl")))
        compilenemo()
=#

# BEGIN: Ensure all packages needed for stock |nemo compilation are installed.
using Pkg

if length(setdiff(["PackageCompiler", "Libdl", "JuMP", "SQLite", "DataFrames", "Distributed", "Dates", "ConfParser", "GLPKMathProgInterface", "Cbc"],
    collect(keys(Pkg.installed())))) > 0

    Pkg.add(setdiff(["PackageCompiler", "Libdl", "JuMP", "SQLite", "DataFrames", "Distributed", "Dates", "ConfParser", "GLPKMathProgInterface", "Cbc"],
        collect(keys(Pkg.installed()))))
end
# END: Ensure all packages needed for stock |nemo compilation are installed.

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

"""Replaces the Julia system image file with the image whose full path is specified in src.
    The logic in this function is necessary to avoid Julia locks on the system image file."""
function copysysimage(src::String)
    local sysimagepath::String = joinpath(PackageCompiler.default_sysimg_path(false), "sys.$(Libdl.dlext)")
        # Path to Julia system image file
    local sysimagedir::String = dirname(sysimagepath)
        # Directory containing Julia system image file

    # BEGIN: Try to delete any existing sys.dll.nemo_compile_backup files.
    for f in readdir(sysimagedir)
        try
            startswith(f, "sys.dll.nemo_compile_backup") && rm(joinpath(sysimagedir, f))
        catch
            # Just continue
        end
    end
    # END: Try to delete any existing sys.dll.nemo_compile_backup files.

    # BEGIN: Rename Julia system image file.
    if isfile(sysimagepath)
        local sysimagemoved::Bool = false  # Indicates whether Julia system image file has been renamed from "sys.dll"
        local counter::Int = 0  # Successive integer to append to new name for Julia system image file

        while !sysimagemoved
            counter += 1

            try
                mv(sysimagepath, sysimagepath * ".nemo_compile_backup" * string(counter); force = true)
                sysimagemoved = true
            catch
                # Just continue
            end
        end
    end
    # END: Rename Julia system image file.

    # Copy src to system image
    cp(src, sysimagepath)
end  # copysysimage(src::String)

"""Generates a new Julia system image including specified additional packages. Arguments:
    • packagesandusecases - One or more tuples of the following form:
        > First item - Name of the additional package to be included in the new system image.
        > Second item - Use cases that determine what functionality of the package is included in the new system image.
Example invocations:
    • compilenemo() - New system image includes NemoMod with compiled functionality based on standard NemoMod test cases. Support for GLPK and Cbc solvers is included
        in new system image since they're |nemo's default solvers.
    • compilenemo(("NemoMod", normpath(joinpath(pathof(NemoMod), "..", "..", "test", "runtests.jl"))),
        ("CPLEX", normpath(joinpath(pathof(NemoMod), "..", "..", "test", "test_cplex.jl")))) - New system image includes NemoMod and CPLEX; compiled functionality
        is based on standard NemoMod test cases plus a supplemental test case for CPLEX. Support for GLPK, Cbc, and CPLEX solvers is included in new system image."""
function compilenemo(packagesandusecases::Tuple{String, String}...=
    ("NemoMod", normpath(joinpath(pathof(NemoMod), "..", "..", "test", "runtests.jl"))))
    # BEGIN: Restore stock system image.
    #= Background:
    |nemo all-in-one installer backs up original system image as lib\julia\sys.dll.nemo_backup.
    Calling PackageCompiler.compile_package() with force = true pushes current system image to sys.dll.packagecompiler_backup in lib\julia
        (if this file doesn't exist already).
    PackageCompiler.revert() copies any sys.dll from CPU target-specific subdirectory under PackageCompiler sysimg folder to lib\julia.
        Such sys.dll's are clean system images (no extra packages added) created by PackageCompiler (revert creates one).

    Logic:
        1) Restore lib\julia\sys.dll.nemo_backup if available.
        2) Otherwise, restore lib\julia\sys.dll.packagecompiler_backup if available.
        3) Otherwise, assume sys.dll is stock. Copy sys.dll to lib\julia\sys.dll.nemo_backup for future reference.
    =#
    local sysimagedir::String = PackageCompiler.default_sysimg_path(false)  # Directory containing Julia system image file

    if isfile(joinpath(sysimagedir, "sys.$(Libdl.dlext).nemo_backup"))
        copysysimage(joinpath(sysimagedir, "sys.$(Libdl.dlext).nemo_backup"))
    elseif isfile(joinpath(sysimagedir, "sys.$(Libdl.dlext).packagecompiler_backup"))
        copysysimage(joinpath(sysimagedir, "sys.$(Libdl.dlext).packagecompiler_backup"))
    else
        cp(joinpath(sysimagedir, "sys.$(Libdl.dlext)"), joinpath(sysimagedir, "sys.$(Libdl.dlext).nemo_backup"))
    end
    # END: Restore stock system image.

    # Create snooping file
    snoop_userimg_nemo(PackageCompiler.sysimg_folder("precompile.jl"), packagesandusecases...)

    # Compile new system image
    local imgfile::String = PackageCompiler.compile_package("NemoMod"; reuse = true, force = false, cpu_target = "native")

    # Replace system image
    copysysimage(imgfile)
    @info "compilenemo() replaced system image. This supersedes prior messages from PackageCompiler."
end  # compilenemo(packagesandusecases::Tuple{String, String}...= ("NemoMod", normpath(joinpath(pathof(NemoMod), "..", "..", "test", "runtests.jl"))))

"""A convenience function for compiling |nemo with support for Gurobi, CPLEX, and/or Mosek
    included (corresponding parameter = true) or excluded (corresponding parameter = false).
    Support for GLPK and Cbc is included in all cases, even if all parameters are false."""
function compilenemo(; gurobi = false, cplex = false, mosek = false)
    # BEGIN: Ensure Julia packages for Gurobi, CPLEX, and Mosek, as needed, are installed.
    local pkgs::Array{String,1} = Array{String,1}()
        # Array of names of packages whose installation will be verified

    gurobi && push!(pkgs, "Gurobi")
    cplex && push!(pkgs, "CPLEX")
    mosek && push!(pkgs, "Mosek")

    pkgs = setdiff(pkgs, collect(keys(Pkg.installed())))

    length(pkgs) > 0 && Pkg.add(pkgs)
    # END: Ensure Julia packages for Gurobi, CPLEX, and Mosek, as needed, are installed.

    # BEGIN: Call compilenemo() with appropriate packagesandusecases.
    local puc::Array{Tuple{String,String},1} = Array{Tuple{String,String},1}()
        # Array of Tuples for packagesandusecases

    push!(puc, ("NemoMod", normpath(joinpath(pathof(NemoMod), "..", "..", "test", "runtests.jl"))))
    gurobi && push!(puc, ("Gurobi", normpath(joinpath(pathof(NemoMod), "..", "..", "test", "test_gurobi.jl"))))
    cplex && push!(puc, ("CPLEX", normpath(joinpath(pathof(NemoMod), "..", "..", "test", "test_cplex.jl"))))
    mosek && push!(puc, ("Mosek", normpath(joinpath(pathof(NemoMod), "..", "..", "test", "test_mosek.jl"))))

    compilenemo(puc...)
    # END: Call compilenemo() with appropriate packagesandusecases.
end  # compilenemo(; gurobi = false, cplex = false, mosek = false)
