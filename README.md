![|nemo logo](docs/src/assets/nemo_logo_small.png)

# NEMO: Next Energy Modeling system for Optimization

NEMO is a high-performance, open-source energy system optimization tool developed in [Julia](https://julialang.org/).  It is intended for modelers who seek substantial optimization capabilities without the financial burden of proprietary software or the performance bottlenecks of common open-source alternatives. Key features of NEMO include:

- Least-cost optimization of energy supply and demand
- Support for multiple regions and regional trade
- Modeling of energy storage
- Nodal network simulations and modeling of power flow
- Modeling of emissions and emission constraints
- Modeling of renewable energy targets
- Parallel processing
- Support for multiple solvers: [GLPK](https://www.gnu.org/software/glpk/), [Cbc](https://projects.coin-or.org/Cbc), [CPLEX](https://www.ibm.com/analytics/cplex-optimizer), [Gurobi](https://www.gurobi.com/), and [Mosek](https://www.mosek.com/)
- [SQLite](https://www.sqlite.org/) data store

NEMO can be used in command-line mode, and it is also being integrated with the [Long-range Energy Alternatives Planning system (LEAP)](https://www.energycommunity.org/). This will allow LEAP to serve as a graphical user interface to NEMO.

Development of NEMO is led by the Energy Modeling Program at the [Stockholm Environment Institute (SEI)](https://www.sei.org/).

# Getting started with NEMO

For instructions on installing and using NEMO, see the [documentation]().

# Contributing to NEMO

We're in the process of preparing guidelines for community contributions to NEMO. For now, if you'd like to contribute, please contact [Jason Veysey](https://www.sei.org/people/jason-veysey/).

# Licensing and attribution

NEMO's Julia code is made available under the Apache License, Version 2.0. See [LICENSE.md](LICENSE.md) for details, including attribution requirements and limitations on use.

The initial versions of NEMO were informed by version 2017_11_08 of the [Open Source Energy Modelling System (OSeMOSYS)](OSeMOSYS), which was also released under the Apache License, Version 2.0.

# For more information

The NEMO team includes several SEI staff: [Jason Veysey](https://www.sei.org/people/jason-veysey/), [Eric Kemp-Benedict](https://www.sei.org/people/eric-kemp-benedict/), and [Charlie Heaps](https://www.sei.org/people/charles-heaps/). Please feel free to contact any of us for more information or if you have questions.
