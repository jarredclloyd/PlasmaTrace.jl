using PlasmaTrace
using Documenter

DocMeta.setdocmeta!(PlasmaTrace, :DocTestSetup, :(using PlasmaTrace); recursive=true)

makedocs(;
    modules=[PlasmaTrace],
    authors="Pieter Vermeesch <p.vermeesch@ucl.ac.uk>, Jarred C. Lloyd <jarred.lloyd@adelaide.edu.au>",
    repo="https://github.com/jarredclloyd/PlasmaTrace.jl/blob/{commit}{path}#{line}",
    sitename="PlasmaTrace.jl",
    format=Documenter.HTML(;
        prettyurls=get(ENV, "CI", "false") == "true",
        canonical="https://jarredclloyd.github.io/PlasmaTrace.jl",
        edit_link="main",
        assets=String[],
    ),
    pages=[
        "Home" => "index.md",
    ],
)

deploydocs(;
    repo="github.com/jarredclloyd/PlasmaTrace.jl",
    devbranch="main",
)
