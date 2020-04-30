```@meta
CurrentModule = NemoMod
```
# Model units

NEMO uses units of measure in the following categories:

  * Energy
  * Power
  * Costs
  * Emissions

When you define a scenario, you choose units in these categories and must use them consistently across [parameters](@ref Parameters). A scenario has one cost unit and one emissions unit. Energy and power units can vary by [region](@ref region), but it's generally easier to use a single energy unit and a single power unit in all regions.

!!! tip

    Typical units for a national-scale NEMO model are petajoules for energy, gigawatts for power, million $ for costs, and metric tonnes for emissions. These are the units LEAP uses with NEMO.

Two parameters allow NEMO to convert from energy to power.

  * [CapacityToActivityUnit](@ref CapacityToActivityUnit): For a given region, the power unit * 1 year, expressed in terms of the energy unit. For example, if the power unit is gigawatts and the energy unit is petajoules, this parameter should be 1 GW-year expressed in PJ, or 31.536 PJ/GW-year.

  * [TransmissionCapacityToActivityUnit](@ref TransmissionCapacityToActivityUnit): One megawatt-year expressed in terms of the 
