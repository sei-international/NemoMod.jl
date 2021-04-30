```@meta
CurrentModule = NemoMod
```
# [NEMO model concept](@id model_concept)

NEMO simulates an energy system through least-cost optimization with perfect foresight. Essentially, this means it seeks to meet energy and power demands over time at the lowest possible cost. The cost minimization function in NEMO operates on discounted costs (all costs are discounted to the beginning of the simulation) and simultaneously covers all modeled time periods. Minimized costs can include investment costs (capital and interest), fixed and variable operation and maintenance costs, and emission penalties for different components of the energy system (such as power plants, energy storage facilities, and transmission lines).

NEMO is a deterministic model, but its robust performance makes it practical to explore uncertainties in inputs, including in a large scenario ensemble analysis framework. It represents an energy system through a series of input [dimensions](@ref dimensions) and [parameters](@ref parameters), calculated variables, constraints, and an objective function. A set of input dimensions and parameters (and optionally custom constraints) for NEMO constitutes a *scenario*. You define dimensions and parameters for a scenario by specifying them in a [NEMO scenario database](@ref scenario_db). Each scenario has its own database, and NEMO writes results to the database when the scenario is calculated.

!!! tip
    You can create an empty NEMO scenario database with the [`createnemodb`](@ref) function. If you're using NEMO with LEAP, LEAP will create and populate scenario databases for you.

To define custom constraints for a scenario, you write the constraints in Julia code and point to them in a NEMO [configuration file](@ref configuration_file).

NEMO supports simulating energy demand and supply on an annual and sub-annual basis. Sub-annual modeling is structured using time slices and time slice groups, which you can configure in a variety of ways. How these elements work together is discussed in depth in [Time slicing](@ref time_slicing).

NEMO also allows considerable geographic flexibility. Multiple [regions](@ref region) can be defined in a scenario, with trading allowed between specified regions, and a [nodal](@ref node) transmission (or transmission and distribution) network can be overlaid on the regions for specified [fuels](@ref fuel). [Network segments](@ref transmissionline) (e.g., transmission lines or pipelines) can cross regional borders.

NEMO can be used to model an entire energy system or certain parts of a system - for example, electricity supply and demand only. All NEMO scenarios are driven by some exogenously specified demands, but you can decide how to define these. For instance, demands can be defined for fuels themselves or for energy services that are provided by fuel-consuming devices. Note that NEMO is not a partial-equilibrium model, so it does not incorporate an endogenous demand response to energy supply costs.

NEMO has several features that account for energy system reliability requirements. Most important, you can specify a [reserve margin](@ref ReserveMargin) for energy production capacity that must be maintained at times of peak load. This can be coupled with time-sliced demands, time-sliced availability of supply, and transmission and storage limits. You can vary these parameters across scenarios to test different reliability stressors (including contingency scenarios where certain supply resources are not available).

!!! tip
    A good idea when testing reliability scenarios is to define a high-cost, always-available supply [technology](@ref technology) for unmet demand. This technology can be used as a last resort to avoid an infeasible scenario, and it will indicate where and when additional supply is needed.

The creators of NEMO used the [Open Source Energy Modelling System (OSeMOSYS)](http://www.osemosys.org/) as a starting point when developing NEMO. For this reason, a number of elements in the NEMO code share names with OSeMOSYS. The two tools now differ in substantial ways, but the NEMO team gratefully acknowledges the foundational work of the OSeMOSYS community.
