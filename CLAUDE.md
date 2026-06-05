# NEMO: Next Energy Modeling system for Optimization

NEMO is a high-performance, open-source energy system optimization modeling tool written in Julia. It is developed by the Energy Modeling Program at the Stockholm Environment Institute (SEI).

## Project structure

- `src/` - Julia source code for the NemoMod package
- `test/` - Test suite
- `docs/` - Documentation (built with Documenter.jl)
- `utils/` - Utility scripts
- `Project.toml` / `Manifest.toml` - Julia package dependencies

## Key facts

- Package name: `NemoMod`
- Language: Julia
- Optimization backend: supports Cbc, CPLEX, GLPK, Gurobi, HiGHS, Mosek, and Xpress solvers
- Data store: SQLite databases
- Can be used standalone (CLI) or via the LEAP GUI

## Documentation

- Stable docs: https://sei-international.github.io/NemoMod.jl/stable
- Dev docs: https://sei-international.github.io/NemoMod.jl/dev
