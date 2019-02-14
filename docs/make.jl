using Documenter
using NemoMod

makedocs(
    sitename = "NemoMod",
    format = :html,
    modules = [NemoMod]
)

# Documenter can also automatically deploy documentation to gh-pages.
# See "Hosting Documentation" and deploydocs() in the Documenter manual
# for more information.
#=deploydocs(
    repo = "<repository url>"
)=#
