using Documenter

if !(@isdefined NemoMod)
    using NemoMod
end

"""
    Documenter.Writers.HTMLWriter.analytics_script(line::String)

Overload of Documenter.Writers.HTMLWriter.analytics_script() that provides
compatibility with Google Analytics 4.
"""
# Overload appears not to be necessary as of Documenter v1.16.1
#= function Documenter.Writers.HTMLWriter.analytics_script(tracking_id::AbstractString)
    if isempty(tracking_id)
        return Documenter.Utilities.DOM.Tag(Symbol("#RAW#"))("")
    else
        return Documenter.Utilities.DOM.Tag(Symbol("#RAW#"))("""<!-- Global site tag (gtag.js) - Google Analytics -->
        <script async src="https://www.googletagmanager.com/gtag/js?id=$(tracking_id)"></script>
        <script>
          window.dataLayer = window.dataLayer || [];
          function gtag(){dataLayer.push(arguments);}
          gtag('js', new Date());
          gtag('config', '$(tracking_id)');
        </script>""")
    end
end  # Documenter.Writers.HTMLWriter.analytics_script(tracking_id::AbstractString) =#

makedocs(
    sitename = "NEMO",
    format = Documenter.HTML(analytics="G-9GTNP1Q3KY"),
    pages = [
        "Introduction" => "index.md"
        "Quick start" => "quick_start.md"
        "Installation" => "installation.md"
        "Modeling concept" => "modeling_concept.md"
        "Inputs" => [
            "Dimensions" => "dimensions.md"
            "Parameters" => [
                "Overview" => "parameters.md"
                "Demands" => "parameters_demands.md"
                "Technology performance and operation" => "parameters_technology.md"
                "Costs, financing, and subsidies" => "parameters_costs.md"
                "Capacity and investment limits" => "parameters_capacity_limits.md"
                "Activity limits and production shares" => "parameters_activity_limits.md"
                "Emissions" => "parameters_emissions.md"
                "Reserve margins" => "parameters_reserve_margins.md"
                "Storage" => "parameters_storage.md"
                "Transmission, nodes, and trade" => "parameters_transmission.md"
                "Model structure and groupings" => "parameters_structure.md"
            ]
            "Time slicing" => "time_slicing.md"
            "Units of measure" => "units.md"
        ]
        "Outputs" => [
            "Variables" => "variables.md"
        ]
        #"Mathematical model"
        "Scenario databases" => "scenario_db.md"
        "Calculating a scenario" => [
            "Julia syntax" => "calculatescenario.md"
            "Perfect foresight vs. limited foresight" => "foresight.md"
            "Calculating selected years" => "selected_years.md"
            "Configuration files" => "configuration_file.md"
            "Performance tips" => "performance_tips.md"
            "Troubleshooting infeasibility" => "infeasibility.md"
        ]
        "Custom constraints" => "custom_constraints.md"
        "FAQs" => "faqs.md"
        "Function reference" => "functions.md"
        "Release notes" => "release_notes.md"
    ],
)

deploydocs(repo = "github.com/sei-international/NemoMod.jl.git")

# Documenter can also automatically deploy documentation to gh-pages.
# See "Hosting Documentation" and deploydocs() in the Documenter manual
# for more information.
#=deploydocs(
    repo = "<repository url>"
)=#

#= Markdown syntax for referring to one docstring

```@docs
#NemoMod.logmsg(msg::String, suppress=false, dtm=now()::DateTime)
```

=#
