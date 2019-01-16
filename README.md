# NEMO: Next Energy Modeling system for Optimization

NEMO is a high performance, open source energy system optimization tool developed in [Julia](https://julialang.org/).  It is intended for modelers who seek substantial optimization capabilities without the limitations of proprietary, fee-based software or the performance bottlenecks of common open source alternatives. Key features of NEMO include:

- Least-cost optimization of energy supply and demand
- Support for multiple regions and regional trade
- Modeling of energy storage
- Modeling of emissions and emission constraints
- Modeling of renewable energy targets
- Parallel processing
- [SQLite](https://www.sqlite.org/) data store

NEMO can be used in command-line mode by installing this Julia package, and it also being integrated with the [Long-range Energy Alternatives Planning system (LEAP)](https://www.energycommunity.org/). This will allow LEAP to serve as a graphical user interface to NEMO.

Development of NEMO is led by the Energy Modeling Program at the [Stockholm Environment Institute (SEI)](https://www.sei.org/).

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

This method is intended for users who want a quick, easy way to install NEMO and Julia together. SEI provides installers that deploy the two from a single file. Each installer includes an option to install a fully compiled copy of NEMO (i.e., a Julia system image into which NEMO has been compiled; if this option is not selected, NEMO can still be executed with just-in-time compilation). Currently, installers are available for the following platforms:

- Windows 64-bit

To obtain an installer, contact [Jason Veysey](https://www.sei.org/people/jason-veysey/). Once NEMO is installed, you can invoke it as described under [Manual installation](https://github.com/sei-international/NemoMod.jl/blob/master/README.md#manual-installation) above.

# Contributing to NEMO

We're in the process of preparing guidelines for community contributions to NEMO. For now, if you'd like to contribute, please contact [Jason Veysey](https://www.sei.org/people/jason-veysey/).

# Licensing and attribution

NEMO's Julia code is made available under the Apache License, Version 2.0. See [LICENSE.md](LICENSE.md) for details, including attribution requirements and limitations on use.

The initial versions of NEMO were informed by version 2017_11_08 of the [Open Source Energy Modelling System (OSeMOSYS)](OSeMOSYS), which was also released under the Apache License, Version 2.0.

# For more information

The NEMO team includes several SEI staff: [Jason Veysey](https://www.sei.org/people/jason-veysey/), [Eric Kemp-Benedict](https://www.sei.org/people/eric-kemp-benedict/), [Taylor Binnington](https://www.sei.org/people/taylor-binnington/), and [Charlie Heaps](https://www.sei.org/people/charles-heaps/). Please feel free to contact any of us for more information or if you have questions.

We're also working on NEMO documentation - it's coming soon!
