```@meta
CurrentModule = NemoMod
```

![NEMO logo](assets/nemo_logo_small.png)

This documentation explains how to use **NEMO**: the **Next Energy Modeling System for Optimization**.

NEMO is a high-performance, open-source energy system optimization modeling tool. It is intended for users who seek substantial optimization capabilities without the financial burden of proprietary software or the performance bottlenecks of common open-source alternatives. Key features of NEMO include:

- Least-cost optimization of energy supply and demand
- Support for multiple regions and regional trade
- Modeling of energy storage
- Nodal network simulations and modeling of power and pipeline flow
- Modeling of emissions and emission constraints (including carbon prices and pollutant externalities)
- Modeling of renewable energy targets
- Parallel processing
- Support for multiple solvers: [GLPK](https://www.gnu.org/software/glpk/), [Cbc](https://projects.coin-or.org/Cbc), [CPLEX](https://www.ibm.com/analytics/cplex-optimizer), [Gurobi](https://www.gurobi.com/), and [Mosek](https://www.mosek.com/)
- [SQLite](https://www.sqlite.org/) data store
- Numerous performance tuning options

NEMO can be used as a stand-alone tool but is designed to leverage the [Low Emissions Analysis Platform (LEAP)](https://energycommunity.org/) as a user interface. Many users will find it easiest to exploit NEMO via LEAP.

For more background on NEMO and its raison d’être, see the README at NEMO's [GitHub homepage](https://github.com/sei-international/NemoMod.jl).

# NEMO team

NEMO is a project of the Energy Modeling Program at the [Stockholm Environment Institute](https://www.sei.org/) (SEI). Key contributors include [Jason Veysey](https://www.sei.org/people/jason-veysey/), [Eric Kemp-Benedict](https://www.sei.org/people/eric-kemp-benedict/), [Taylor Binnington](https://acadiacenter.org/people/taylor-binnington/), and [Charlie Heaps](https://www.sei.org/people/charles-heaps/). The project was started through an SEI Seed & Innovation grant funded by the [Swedish International Development Cooperation Agency](https://www.sida.se/English/) (Sida).

```@raw html
<a href="https://www.sei.org"><img src="assets/sei_logo.svg" alt="SEI logo" style="display:block; margin: 0 auto"/></a>
```
