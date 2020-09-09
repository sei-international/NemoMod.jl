![|nemo logo](docs/src/assets/nemo_logo_small.png)

# NEMO: Next Energy Modeling system for Optimization

NEMO is a high performance, open-source energy system optimization modeling tool developed in [Julia](https://julialang.org/).  It is intended for users who seek substantial optimization capabilities without the financial burden of proprietary software or the performance bottlenecks of common open-source alternatives. Key features of NEMO include:

- Least-cost optimization of energy supply and demand
- Support for multiple regions and regional trade
- Modeling of energy storage
- Nodal network simulations and modeling of power and pipeline flow
- Modeling of emissions and emission constraints (including carbon pricing and pollutant externalities)
- Modeling of renewable energy targets
- Parallel processing
- Support for multiple solvers: [Cbc](https://projects.coin-or.org/Cbc), [CPLEX](https://www.ibm.com/analytics/cplex-optimizer), [GLPK](https://www.gnu.org/software/glpk/), [Gurobi](https://www.gurobi.com/), [Mosek](https://www.mosek.com/), and [Xpress](https://www.fico.com/en/products/fico-xpress-optimization)
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

The NEMO team includes several SEI staff: [Jason Veysey](https://www.sei.org/people/jason-veysey/), [Eric Kemp-Benedict](https://www.sei.org/people/eric-kemp-benedict/), and [Charlie Heaps](https://www.sei.org/people/charles-heaps/). Please feel free to contact any of us for more information or if you have questions.
