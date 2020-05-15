using Documenter
using NemoMod

makedocs(
    sitename = "NEMO",
    format = Documenter.HTML(),
    pages = [
        "Introduction" => "index.md"
        # Quick start
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
        #"Calculating a scenario" => "scenario_calc.md"
        #   Julia syntax
        "Configuration files" => "configuration_file.md"
        #   Performance tips
        # Advanced topics
        #   Custom constraints
        #"Function reference" => "functions.md"
    ],
)

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
