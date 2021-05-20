using Documenter
using NemoMod

makedocs(
    sitename = "NEMO",
    format = Documenter.HTML(),
    pages = [
        "Introduction" => "index.md"
        "Quick start" => "quick_start.md"
        "Installation" => "installation.md"
        "Model concept" => "model_concept.md"
        "Inputs" => [
            "Dimensions" => "dimensions.md"
            "Parameters" => "parameters.md"
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
            "Calculating selected years" => "selected_years.md"
            "Configuration files" => "configuration_file.md"
            "Performance tips" => "performance_tips.md"
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
