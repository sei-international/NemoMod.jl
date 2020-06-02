```@meta
CurrentModule = NemoMod
```
# [Installing NEMO](@id installation)

NEMO can be installed in two ways: through an installer program and manually via GitHub.

## [Installer program](@id installer_program)

The installer program is the easiest way to install NEMO. Here are the steps to follow:

1. Download a copy of the installer to your computer and run it. The installer is distributed through the [LEAP website](https://energycommunity.org/download) and is freely available once you register for the site (registration is also free).

2. The installer will step you through the installation process. You'll be prompted to accept the NEMO license (the [Apache License, version 2.0](http://www.apache.org/licenses/LICENSE-2.0)) and asked which components of NEMO you'd like to install.

   ![NEMO installer components](assets/nemo_installer_components.png)

   NEMO is built with the [Julia programming language](https://julialang.org/), so the first component is a version of Julia that's compatible with the version of NEMO you're installing. The second component is the NEMO software itself. Both the first and second components are obligatory.

   The third component, which is optional, is a pre-compiled session environment (system image) for Julia that includes support for NEMO. Ordinarily, Julia compiles programs like NEMO at run-time, a feature that impairs performance when a program is started. The NEMO system image avoids this performance penalty by providing NEMO in a pre-compiled form. **It is recommended for all users, especially those who are using NEMO with LEAP.** Note, though, that if the NEMO system image is installed, any customizations you make to the NEMO code won't take affect unless you [restore the default Julia system image](@ref restore_default_sysimage).

3. Select the components to install, and press the Install button. Then follow the prompts to finish the installation (some steps may take a few minutes). The installer will tell you when the installation is complete.

   ![NEMO installer finished](assets/nemo_installer_finished.png)

!!! note
    At present, an installer is only available for Windows 10 64-bit. Users on other platforms should refer to [GitHub installation](@ref) below.

### Uninstalling NEMO

If you installed NEMO with the installer program, you should be able to reverse the installation using your operating system's normal uninstall function. In Windows, go to Start -> Add or remove programs, and choose to uninstall NEMO.

### Updating NEMO

If you installed with the installer program and want to update to a new version of NEMO, simply run the new installer. It's not necessary to uninstall the old version of NEMO first.

### Troubleshooting problems with installer program

If the installer program encounters an error, it should report the problem to you and provide instructions on recommended next steps. If these steps do not resolve the issue, please email [Jason Veysey](https://www.sei.org/people/jason-veysey/) for assistance.

### [Restoring default Julia system image](@id restore_default_sysimage)

If you install the NEMO system image when running the NEMO installer, you can restore Julia's default system image as follows.

**Steps in Windows**

* Close any Julia windows or processes.
* Open the Julia library directory (typically `%LocalAppData%\Programs\Julia\<Julia version>\lib\julia`).
* Replace `sys.dll` with `sys.dll.nemo_backup`.

Once you do this, there will be a performance penalty when starting NEMO, but any customizations you make to the NEMO code will take effect.

!!! tip
    It's a good practice to back up the NEMO system image before overwriting it. That way, you'll be able to restore it if desired.

## GitHub installation

To install NEMO from GitHub, add the NEMO package (named `NemoMod`) within Julia.

```julia
julia> ]

pkg> add https://github.com/sei-international/NemoMod.jl
```

This will install the latest NEMO code from GitHub (which may include pre-release code). To install a particular version of NEMO, find its commit hash on the [NEMO GitHub releases page](https://github.com/sei-international/NemoMod.jl/releases) and insert it at the end of the add command after a `#` sign. For example, for NEMO 1.0.5:

```julia
pkg> add https://github.com/sei-international/NemoMod.jl#84705cc0b56435a1a2e7c2d3d0e91afc5b46922d
```

## Solver compatibility

NEMO formulates a mixed-integer linear optimization problem and requires a solver that can handle this class of problems. Optimization operations in NEMO are carried out with version 0.18.6 of the [JuMP](https://github.com/JuliaOpt/JuMP.jl) package. In principle, NEMO is compatible with any mixed-integer linear solver that can be called through JuMP (see [the JuMP documentation](http://www.juliaopt.org/JuMP.jl/v0.18/) for more details). A solver can be specified when calculating a scenario in NEMO by passing a JuMP `Model` object that references the solver to NEMO's [`calculatescenario`](@ref) method. For example:

```julia
julia> NemoMod.calculatescenario("c:/temp/scenario_db.sqlite"; jumpmodel = Model(solver = GLPKSolverMIP(presolve=true)))
```

Note that in order to do this, you must have the corresponding Julia interface (package) for the solver installed on your computer.

NEMO has been tested for compatibility with the following solver packages (which in turn support the listed versions of the corresponding solvers).

| Solver | Julia package version | Solver program versions |
|:--- | :-- |:-- |
| [Cbc](https://github.com/JuliaOpt/Cbc.jl) | 0.6.3 | 2.9.9 |
| [CPLEX](https://github.com/JuliaOpt/CPLEX.jl) | 0.5.1 | 12.8 - 12.9 |
| [GLPK](https://github.com/JuliaOpt/GLPK.jl) / [GLPKMathProgInterface](https://github.com/JuliaOpt/GLPKMathProgInterface.jl) | 0.10.0 / 0.4.4 | 4.64 |
| [Gurobi](https://github.com/JuliaOpt/Gurobi.jl) | 0.6.0 | 7.0 - 8.1 |
| [Mosek](https://github.com/JuliaOpt/Mosek.jl) | 0.9.8 | 8.1 |

If you install NEMO with the [NEMO installer](@ref installer_program), all compatible solver packages will be installed as well. The packages for the open-source solvers (GLPK and Cbc) come with the underlying solver programs, so you should be able to use these solvers immediately upon installation.

The Mosek Julia package also provides the underlying solver program. In this case, though, you must have a valid Mosek license installed on your computer in order to use the solver. Typically, for a single-computer license (a server license), a license file must be installed at `%USERPROFILE%\mosek\mosek.lic` (Windows) or `$HOME/mosek/mosek.lic` (Linux or MacOS). See the [Mosek documentation](https://www.mosek.com/resources/getting-started/) for more information.

The Julia packages for CPLEX and Gurobi do **not** include the corresponding solver programs. These must be licensed and set up separately. If CPLEX or Gurobi is installed on your computer when you run the NEMO installer, the installer will link the Julia package to the solver binaries. Otherwise, you may need to perform this step yourself:

```julia
julia> using Pkg

julia> Pkg.build("CPLEX")
```

or

```julia
julia> using Pkg

julia> Pkg.build("Gurobi")
```

!!! warning
    NEMO may not be compatible with solvers and solver versions not listed above. The NEMO team generally does not provide support to troubleshoot issues with such solvers or versions.
