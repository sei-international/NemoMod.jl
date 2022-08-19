```@meta
CurrentModule = NemoMod
```

![NEMO logo](assets/nemo_logo_small.png)

This documentation explains how to use **NEMO**: the **Next Energy Modeling system for Optimization**.

NEMO is a high-performance, open-source energy system optimization modeling tool. It is intended for users who seek substantial optimization capabilities without the financial burden of proprietary software or the performance bottlenecks of common open-source alternatives. Key features of NEMO include:

- Least-cost optimization of energy supply and demand
- Support for multiple regions and regional trade
- Modeling of energy storage
- Nodal network simulations and modeling of power and pipeline flow
- Modeling of emissions and emission constraints (including carbon prices and pollutant externalities)
- Modeling of renewable energy targets
- Support for simulating selected years in a modeling period
- Parallel processing
- Support for multiple solvers: [Cbc](https://github.com/coin-or/Cbc), [CPLEX](https://www.ibm.com/analytics/cplex-optimizer), [GLPK](https://www.gnu.org/software/glpk/), [Gurobi](https://www.gurobi.com/), [HiGHS](https://highs.dev/), [Mosek](https://www.mosek.com/), and [Xpress](https://www.fico.com/en/products/fico-xpress-optimization)
- Optimization warm starts
- [SQLite](https://www.sqlite.org/) data store
- Numerous performance tuning options

NEMO can be used as a stand-alone tool but is designed to leverage the [Low Emissions Analysis Platform (LEAP)](https://leap.sei.org) as a user interface. Many users will find it easiest to exploit NEMO via LEAP.

For more background on NEMO and its raison d'être, see the README at NEMO's [GitHub homepage](https://github.com/sei-international/NemoMod.jl).

# NEMO team

NEMO is a project of the Energy Modeling Program at the [Stockholm Environment Institute](https://www.sei.org/) (SEI). Key contributors include [Jason Veysey](https://www.sei.org/people/jason-veysey/), [Charlie Heaps](https://www.sei.org/people/charles-heaps/), [Eric Kemp-Benedict](https://www.sei.org/people/eric-kemp-benedict/), and [Taylor Binnington](https://www.sei.org/people/taylor-binnington/). The project was started through an SEI Seed & Innovation grant funded by the [Swedish International Development Cooperation Agency](https://www.sida.se/English/) (Sida).
