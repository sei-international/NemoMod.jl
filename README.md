# NEMO: *N*ext *E*nergy *M*odeling system for *O*ptimization

NEMO is a high performance, open source energy system optimization tool developed in [Julia](https://julialang.org/).  It is intended for modelers who seek substantial optimization capabilities without the limitations of proprietary, fee-based software and the performance bottlenecks of common open source alternatives. Key features of NEMO include:

- Least-cost optimization of energy supply and demand
- Support for multiple regions and regional trade
- Modeling of energy storage
- Modeling of emissions and emission constraints
- Modeling of renewable energy targets
- Parallel processing
- [SQLite](https://www.sqlite.org/) data store

NEMO can be used in command-line mode by installing this Julia package, and it also being integrated with the [Long-range Energy Alternatives Planning system (LEAP)](https://www.energycommunity.org/). This will allow LEAP to serve as a graphical user interface to NEMO.

# Getting started with NEMO

There are two ways to set up NEMO for command-line usage:

1. Manual installation
2. Automated installation

## Manual installation

This method is appropriate for experienced Julia users (or people who just want to know more about how NEMO is put together!). To install NEMO manually, follow these steps:

1. [Install Julia](https://julialang.org/downloads/). We recommend version 1.0.x of Julia since NEMO is known to be compatible with this version. 64-bit Julia is preferable but should not be essential.

2. Open a [Julia Read-Eval-Print Loop (REPL)](https://docs.julialang.org/en/v1/stdlib/REPL/#The-Julia-REPL-1) session. We suggest suppressing deprecation warnings (specify `--depwarn=no` when invoking Julia) since some of the packages that NEMO uses may show insignificant warnings otherwise.

3. In the REPL window, type `]` to enter Pkg or package management mode, then enter `add https://github.com/sei-international/NemoMod.jl` to install the NEMO package. To install a particular branch of the NEMO repository, put `#` and the name of the branch after `NemoMod.jl` (e.g., `add https://github.com/sei-international/NemoMod.jl#nemo-osemosys`).

4. Exit Pkg mode by pressing backspace, then type `using NemoMod`. Julia will load (and may precompile) the new package, after which you'll be ready to start using NEMO.

5. There are a variety of ways NEMO can be invoked, but the most common is via the `calculatescenario` function (which calculates a scenario specified in a NEMO-compatible SQLite database). For more on information on this function and NEMO-compatible databases, see the NEMO package files, including the [src directory](src) (which contains commented source code) and the [test directory](test) (which contains a sample NEMO-compatible database). You can also consult NEMO's documentation *(coming soon)*.

6. (Optional) To optimize NEMO's performance, we suggest executing a full, ahead-of-time compilation of the NEMO package. This will add a compiled copy of NEMO to Julia's system image and substantially decrease run times. It's a good choice if you're just going to use NEMO for modeling and don't intend to customize the NEMO code. If you do a full compilation and then customize the code, you'll have to recompile in order for your changes to take effect.

You can perform a full compilation with the `compilenemo` function in [utils/compilation.jl](utils/compilation.jl). Read the comments on this function for further information.

## Automated installation

This method is intended for users who want a quick, easy way to install NEMO and Julia together. @jwveysey

