using MVTfitting
using Documenter

DocMeta.setdocmeta!(MVTfitting, :DocTestSetup, :(using MVTfitting); recursive=true)

makedocs(;
    modules=[MVTfitting],
    authors="Dario Sarra",
    repo="https://github.com/DarioSarra/MVTfitting.jl/blob/{commit}{path}#{line}",
    sitename="MVTfitting.jl",
    format=Documenter.HTML(;
        prettyurls=get(ENV, "CI", "false") == "true",
        canonical="https://DarioSarra.github.io/MVTfitting.jl",
        edit_link="main",
        assets=String[],
    ),
    pages=[
        "Home" => "index.md",
    ],
)

deploydocs(;
    repo="github.com/DarioSarra/MVTfitting.jl",
    devbranch="main",
)
