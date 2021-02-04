```@meta
CurrentModule = NemoMod
```
# [FAQs](@id faqs)

## Installation

#### How can I install NEMO on 32-bit Windows?

The [NEMO installer program](@ref installer_program) is only compatible with Windows 10 64-bit. If you want to run NEMO on 32-bit Windows, please follow the instructions for [GitHub installation](@ref github_installation) of NEMO. As they explain, you'll need separately to download and install Julia, then add the NEMO package within Julia.

With GitHub installation, NEMO will be slower to start than if installed with the installer program. This is because the installer program supplies a pre-compiled session environment (system image) for Julia that includes support for NEMO. Without this component, Julia performs some of the compilation of NEMO each time NEMO is run. To create your own pre-compiled session environment for a 32-bit installation, you can use the [PackageCompiler tool](https://github.com/JuliaLang/PackageCompiler.jl).

#### I got an error when I ran the [NEMO installer program](@ref installer_program). What should I do?

If you're running the installer on Windows, **make sure you're using a licensed copy of Windows 10 64-bit**. The installer may not work on other versions of Windows, including Windows 7. If you've verified your operating system but are still encountering an error, click the "Show details" button in the installer and record the error message. You can then report the issue at the [LEAP and NEMO support forum](https://leap.sei.org/support/). When you do, please note which operating system and operating-system display language you're using.

#### Is there a silent mode for the [NEMO installer program](@ref installer_program)?

Yes, you can run the installer in silent mode with a `/S` switch.

#### Why won't my solver work with NEMO?

The first thing to do in case of problems with a solver is to check [whether NEMO supports the solver](@ref solver_compatibility). The NEMO team generally doesn't help to troubleshoot unsupported solvers. Note in particular that **right now, NEMO is only compatible with versions 12.8 and 12.9 of CPLEX and versions 7.0-8.1 of Gurobi.**

You should also make sure your solver is properly licensed. Proprietary solvers including CPLEX, Gurobi, Mosek, and Xpress require a license that must be obtained from their provider.

If you have a compatible, licensed solver but installed it after NEMO, the solver may not be connected to Julia. If you installed NEMO with the [NEMO installer program](@ref installer_program), you can correct this problem by rerunning the installer. Otherwise, try building the Julia package for the solver (`CPLEX`, `Gurobi`, or `Xpress`), for example:

```julia
julia> using Pkg

julia> Pkg.build("CPLEX")
```
## Performance

#### Why is my model slow?

See [Performance tips](@ref performance_tips) for some ideas.

## Training and user support

#### Are there training exercises for NEMO?

Not yet, but the NEMO team is working on it. Exercises will be linked here when they're ready.

#### Where should I report problems with NEMO?

Please report issues at the [LEAP and NEMO support forum](https://leap.sei.org/support/). Before reporting an issue, check the forum to see if your question has already been asked and answered. If you do submit an issue report, be specific and include steps to reproduce the problem.

## Using NEMO with LEAP

#### I'm getting a "database is locked error" when I try to calculate a NEMO scenario in LEAP. How can I resolve this?

There are several reasons why this error could occur.

  * LEAP crashed while it was calculating a scenario with NEMO. In this case, you can fix the problem by stopping the crashed LEAP process (as well as any running Julia processes) in Window's Task Manager, or you can just reboot Windows.

  * You opened a NEMO database for a scenario in LEAP's working directory (using a SQLite client such as DB Browser for SQLite), then tried to recalculate the scenario in LEAP. In this situation, LEAP attempts to overwrite the database but isn't able to. Once you close the database, LEAP should be able to proceed.

  * LEAP isn't able to find the directory where it creates NEMO scenario databases. In principle, the LEAP installer should ensure this doesn't happen, but some users have reported this behavior. You can correct it by adding the path to the LEAP settings folder to the Windows environment variable named "PATH". You can find the path to the LEAP settings folder in LEAP at Settings -> Folders -> Settings.
