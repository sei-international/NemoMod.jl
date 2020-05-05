```@meta
CurrentModule = NemoMod
```
# [Units of measure](@id uoms)

NEMO uses units of measure in the following categories:

  * Energy
  * Power
  * Costs
  * Emissions

When you define a scenario, you choose units in these categories and must employ them consistently across [parameters](@ref parameters). Each scenario can have one cost unit and one emissions unit. Energy and power units can vary by [region](@ref region) within a scenario, but it's generally easier to select a single energy unit and a single power unit for all regions.

!!! tip

    Typical units for a national-scale NEMO model are petajoules for energy, gigawatts for power, million $ for costs, and metric tonnes for emissions. These are the units LEAP uses with NEMO.

Two parameters define the relationship between power units and energy units.

  * [CapacityToActivityUnit](@ref CapacityToActivityUnit): For a given region, the power unit * 1 year, expressed in terms of the energy unit. For example, if the power unit is gigawatts and the energy unit is petajoules, this parameter should be 1 GW-year expressed in PJ, or 31.536 PJ/GW-year. NEMO uses CapacityToActivityUnit when translating between the capacity of [technologies](@ref technology) and their energy outputs and inputs.

  * [TransmissionCapacityToActivityUnit](@ref TransmissionCapacityToActivityUnit): For a given region, one megawatt-year expressed in terms of the energy unit. For example, if the energy unit is petajoules, this parameter should be 0.031536 PJ/MW-year. NEMO uses TransmissionCapacityToActivityUnit when converting energy flowing over [transmission lines](@ref transmissionline) into the appropriate energy unit. The power unit for transmission lines is always megawatts in NEMO.
