```@meta
CurrentModule = NemoMod
```

![|nemo logo](assets/nemo_logo_small.png)

This documentation explains how to use **|nemo**: the **Next Energy Modeling System for Optimization**.

|nemo is a high performance, open source energy system optimization model intended for users who seek substantial optimization capabilities without the limitations of proprietary, fee-based software or the performance bottlenecks of common open source alternatives. Key features of |nemo include:

- Least-cost optimization of energy supply and demand
- Support for multiple regions and regional trade
- Modeling of energy storage
- Modeling of emissions and emission constraints
- Modeling of renewable energy targets
- Parallel processing
- [SQLite](https://www.sqlite.org/) data store

For more background on |nemo and its raison d’être,
see the README at |nemo's [GitHub homepage](https://github.com/sei-international/NemoMod.jl).

# |nemo team

|nemo is a project of the Energy Modeling Program at the [Stockholm Environment Institute](https://www.sei.org/) (SEI). Key contributors include [Jason Veysey](https://www.sei.org/people/jason-veysey/), [Eric Kemp-Benedict](https://www.sei.org/people/eric-kemp-benedict/), [Taylor Binnington](https://www.sei.org/people/taylor-binnington/), and [Charlie Heaps](https://www.sei.org/people/charles-heaps/). The project was started through an SEI Seed & Innovation grant funded by the [Swedish International Development Cooperation Agency](https://www.sida.se/English/) (Sida).

```@raw html
<a href="https://www.sei.org"><img src="assets/sei_logo.svg" alt="SEI logo" style="display:block; margin: 0 auto"/></a>
```

```@raw html
<!---

- Installation
- Model specification
  + Introduction
  + Sets
  + Parameters
  + Variables
  + Time slicing
  + Other deeper dives
  + Mathematical model
- Data store
  + Using GNU MathProg data
- Solving a scenario

--->
```
