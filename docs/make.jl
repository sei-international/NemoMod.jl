using Documenter
using NemoMod

makedocs(
    sitename = "NEMO",
    format = Documenter.HTML(),
    pages = [
        "Introduction" => "index.md"
        "Installation" => "installation.md"
        "Model concept" => "model_concept.md"
        "Inputs" => [
            "Dimensions" => "dimensions.md"
            "Parameters" => "parameters.md"
        ]
        "Scenario databases" => "scenario_db.md"
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
