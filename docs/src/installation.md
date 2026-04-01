```@meta
CurrentModule = NemoMod
```
# [Installing NEMO](@id installation)

NEMO can be installed in two ways: with an installer program and manually via GitHub.

## [Installer program](@id installer_program)

The installer program is the easiest way to install NEMO. It sets up all of NEMO's files and ensures an appropriate version of [Julia](https://julialang.org/), the language NEMO is programmed in, is installed. You can download a copy of the installer program through the [LEAP website](https://leap.sei.org/download) (note that you must register for the site to access the download link).

Once you've downloaded the installer, run it and follow the prompts.

![NEMO installer welcome screen with setup wizard interface. The window displays the title "Welcome to the NEMO - Next Energy Modeling system for Optimization Setup Wizard" at the top. On the left side is a blue icon featuring a box and wireless signal symbol. The main content area contains introductory text explaining that this will install NEMO and recommends closing other applications before continuing. Instructions prompt the user to click Next to continue or Cancel to exit setup. Two buttons at the bottom right labeled Next and Cancel allow navigation.](assets/nemo_installer.png)

One of the files that the installer delivers is a pre-compiled session environment (system image) for Julia that includes support for NEMO. Ordinarily, Julia compiles programs like NEMO at run-time, a feature that impairs performance when a program is started. The NEMO system image avoids this performance penalty by providing NEMO in a pre-compiled form. This is a significant advantage, but there's one caveat: if you make any customizations to NEMO's code, they won't take effect unless you [restore the default Julia system image](@ref restore_default_sysimage) as described below.

!!! note
    At present, an installer is only available for Windows 10 and 11 64-bit. Users on other platforms should refer to [GitHub installation](@ref github_installation).

### Uninstalling NEMO

If you installed NEMO with the installer program, you should be able to reverse the installation using your operating system's normal uninstall function. In Windows, go to Start -> Add or remove programs, and choose to uninstall NEMO.

### Updating NEMO

If you installed with the installer program and want to update to a new version of NEMO, simply run the new installer. It's not necessary to uninstall the old version of NEMO first.

### Troubleshooting problems with installer program

If the installer program throws an error, check its log file for more information about the problem. You can find installer log files in the temporary directory for your operating system user (in Windows, this is the directory mapped to the `TEMP` environment variable, accessible in the File Explorer by navigating to `%temp%`). The file names of installer log files start with "Setup Log". If you and your local IT support cannot resolve the problem you encountered, please email [Jason Veysey](https://www.sei.org/people/jason-veysey/) for assistance. **Include a copy of the installer log file in your message.**

### [Restoring default Julia system image](@id restore_default_sysimage)

If you install Julia with the NEMO installer program and need to restore the default Julia system image, follow these steps.

**Steps in Windows**

* Close any Julia windows or processes.
* Open the Julia library directory (typically `%ProgramData%\Julia\<Julia version>\lib\julia`).
* Replace `sys.dll` with `sys.dll.nemo_backup`.

Once you do this, there will be a performance penalty when starting NEMO, but any customizations you make to the NEMO code will take effect.

!!! tip
    It's a good practice to back up the NEMO system image before overwriting it. That way, you'll be able to restore it if desired.

## [GitHub installation](@id github_installation)

To install NEMO from GitHub, you must first have a working Julia installation on your computer. **The NEMO team has verified NEMO's compatibility with Julia 1.12.4; other versions of Julia may not work correctly.**

Once Julia is set up, start a Julia session and add the NEMO package (named `NemoMod`):

```julia
julia> ]

pkg> add https://github.com/sei-international/NemoMod.jl
```

This will install the latest NEMO code from GitHub (which may include pre-release code). To install a particular version of NEMO, find its commit hash on the [NEMO GitHub releases page](https://github.com/sei-international/NemoMod.jl/releases) and insert it at the end of the add command after a `#` sign. For example, for NEMO 1.0.5:

```julia
pkg> add https://github.com/sei-international/NemoMod.jl#84705cc0b56435a1a2e7c2d3d0e91afc5b46922d
```

## [Solver compatibility](@id solver_compatibility)
When you [calculate a scenario](@ref scenario_calc) in NEMO, the tool formulates an optimization problem that must be solved by a compatible solver. In general, this process yields a conventional linear programming (LP) problem, but certain run-time options can change the problem type.

!!! note

    NEMO generates an ordinary LP optimization problem when calculating a scenario unless you do one of the following:
    * Set the [capacity of one technology unit](@ref CapacityOfOneTechnologyUnit) parameter (creates a mixed-integer linear programming [MILP] problem)
    * Set the `continuoustransmission` argument for [`calculatescenario`](@ref) to `false` (creates a MILP problem if transmission modeling is enabled)
    * Model a [transmission line](@ref transmissionline) with a non-zero variable cost (creates a MILP problem if transmission modeling is enabled)
    * Model a transmission line whose efficiency is less than 1 using [transmission modeling type 3](@ref TransmissionModelingEnabled) (creates a MILP problem)
    * Run a direct current optimized power flow simulation using [transmission modeling type 1](@ref TransmissionModelingEnabled) (creates a problem with a quadratic term)
    * Use the [minimum annual transmission between nodes](@ref MinAnnualTransmissionNodes) parameter or [maximum annual transmission between nodes](@ref MaxAnnualTransmissionNodes) parameter (creates a MILP problem)
    * Set the `forcemip` argument for `calculatescenario` to `true` (creates a MILP problem)

Optimization operations in NEMO are carried out with version 1.29.4 of the [JuMP](https://github.com/jump-dev/JuMP.jl) package. In principle, NEMO is compatible with any solver that can be called through JuMP, but you must ensure the selected solver can handle the problem you're presenting (LP/MILP/quadratic). For a list of solvers that work with JuMP, see [the JuMP documentation](https://jump.dev/JuMP.jl/stable/installation/#Supported-solvers).

A solver can be specified when calculating a scenario in NEMO by passing a JuMP `Model` object that references the solver to NEMO's [`calculatescenario`](@ref) method. For example:

```julia
julia> NemoMod.calculatescenario("c:/temp/scenario_db.sqlite"; jumpmodel = Model(optimizer_with_attributes(GLPK.Optimizer, "presolve" => true)))
```

Note that in order to do this, you must have the corresponding Julia interface (package) for the solver installed on your computer.

NEMO has been tested for compatibility with the following solver packages (which in turn support the listed versions of the associated solvers).

| Solver | Julia package version | Solver program versions |
|:--- | :-- |:-- |
| [Cbc](https://github.com/jump-dev/Cbc.jl) | 1.3.0 | 2.10.12 |
| [CPLEX](https://github.com/jump-dev/CPLEX.jl) | 1.1.1 | 12.10 - 22.1 |
| [GLPK](https://github.com/jump-dev/GLPK.jl) | 1.2.1 | 5.0 |
| [Gurobi](https://github.com/jump-dev/Gurobi.jl) | 1.9.2 | 9.0 - 13.0.1 |
| [HiGHS](https://github.com/jump-dev/HiGHS.jl) | 1.21.0 | 1.13.0 |
| [Mosek](https://github.com/jump-dev/MosekTools.jl) | 11.0.1 | 11.0.30 |
| [Xpress](https://github.com/jump-dev/Xpress.jl) | 0.17.2 | 8.4 - 9.8 |

!!! tip
    Older versions of NEMO may be compatible with older versions of these solvers. For example, [NEMO 1.2](https://github.com/sei-international/NemoMod.jl/releases/tag/v1.2) is compatible with CPLEX 12.8 - 12.9 and Gurobi 7 - 8.

If you install NEMO with the [NEMO installer](@ref installer_program), all of the preceding solver packages will be installed as well. Some of the packages come with the underlying solver programs (solver binaries), and some require separately installed licenses as described below.

* **Solver program installed with solver's Julia package, no separate license required** - Cbc, GLPK, HiGHS. Once their Julia packages are installed, these solvers can be used immediately. 
* **Solver program installed with solver's Julia package, separate license required** - Gurobi, Mosek. See the documentation for these solvers for information on licensing.
* **Solver program not installed with solver's Julia package, separate license required** - CPLEX, Xpress. See the documentation for these solvers for information on licensing and installing the solver program. If you install one of these solvers and it does not work with NEMO, try reinstalling NEMO.

!!! warning
    NEMO may not be compatible with solvers and solver versions not listed above. The NEMO team generally does not provide support to troubleshoot issues with such solvers or versions.

## [NEMO package directory](@id nemo_package_directory)

NEMO's source code and some other NEMO-specific files (e.g., a sample [configuration file](@ref configuration_file) and [scenario databases](@ref scenario_db)) are stored in a directory for NEMO's Julia package. If you installed NEMO from GitHub, you can find this directory by running these Julia commands:

```julia
julia> using NemoMod

julia> println(normpath(joinpath(pathof(NemoMod), "..", "..")))
```

If you installed NEMO with the installer program, the NEMO package directory should be the first subdirectory in `%ProgramData%\NEMO\depot\packages\NemoMod`.