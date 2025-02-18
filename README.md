![|nemo logo](docs/src/assets/nemo_logo_small.png)

# NEMO: Next Energy Modeling system for Optimization

[![](https://img.shields.io/badge/docs-stable-blue.svg)](https://sei-international.github.io/NemoMod.jl/stable)
[![](https://img.shields.io/badge/docs-dev-blue.svg)](https://sei-international.github.io/NemoMod.jl/dev)

NEMO is a high performance, open-source energy system optimization modeling tool developed in [Julia](https://julialang.org/).  It is intended for users who seek substantial optimization capabilities without the financial burden of proprietary software or the performance bottlenecks of common open-source alternatives. Key features of NEMO include:

- Least-cost optimization of energy supply and demand
- Support for multiple regions and regional trade
- Modeling of energy storage
- Nodal network simulations and modeling of power and pipeline flow
- Modeling of emissions and emission constraints (including carbon pricing and pollutant externalities)
- Modeling of renewable energy targets
- Support for simulating selected years in a modeling period
- Parallel processing
- Support for multiple solvers: [Cbc](https://github.com/coin-or/Cbc), [CPLEX](https://www.ibm.com/analytics/cplex-optimizer), [GLPK](https://www.gnu.org/software/glpk/), [Gurobi](https://www.gurobi.com/), [HiGHS](https://highs.dev/), [Mosek](https://www.mosek.com/), and [Xpress](https://www.fico.com/en/products/fico-xpress-optimization)
- Optimization warm starts
- [SQLite](https://www.sqlite.org/) data store
- Numerous performance tuning options

NEMO can be used in command line mode or with the [Low Emissions Analysis Platform](https://leap.sei.org/) (LEAP - formerly the Long-range Energy Alternatives Planning system) as a graphical user interface.

Development of NEMO is led by the Energy Modeling Program at the [Stockholm Environment Institute (SEI)](https://www.sei.org/).

# Getting started with NEMO

For instructions on installing and using NEMO, see the [documentation](https://sei-international.github.io/NemoMod.jl/).

# Contributing to NEMO

If you are interested in contributing to NEMO, please contact [Jason Veysey](https://www.sei.org/people/jason-veysey/).

# Licensing and attribution

NEMO's Julia code is made available under the Apache License, Version 2.0. See [LICENSE.md](LICENSE.md) for details, including attribution requirements and limitations on use.

The initial versions of NEMO were informed by version 2017_11_08 of the [Open Source Energy Modelling System (OSeMOSYS)](https://github.com/OSeMOSYS/OSeMOSYS), which was also released under the Apache License, Version 2.0.

# For more information

The NEMO team includes several SEI staff: [Jason Veysey](https://www.sei.org/people/jason-veysey/), [Charlie Heaps](https://www.sei.org/people/charles-heaps/), and [Taylor Binnington](https://www.sei.org/people/taylor-binnington/). Please feel free to contact any of us for more information or if you have questions.
