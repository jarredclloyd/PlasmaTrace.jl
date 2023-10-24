const sph = 3.6e6 # seconds per hour
const window = Tuple{Integer,Integer} # why is this an integer rather than a Real? Is the a reason floats can't be used? And why is it a global constant?
abstract type PlasmaData <: Any end

mutable struct Control
    A::Union{Nothing,Vector{AbstractFloat}} # what is A?
    B::Union{Nothing,Vector{AbstractFloat}} # what is B?
    channels::Union{Nothing,Vector{String}}
end

mutable struct Sample <: PlasmaData
    samplename::String
    datetime::DateTime
    labels::Vector{String}
    data::Matrix{AbstractFloat}
    blankwindow::Union{Nothing,Vector{window}}
    samplewindow::Union{Nothing,Vector{window}}
    standard::Integer
end

mutable struct Run <: PlasmaData
    samples::Vector{Sample}
    control::Union{Nothing,Control}
    bpar::Union{Nothing,Vector} # not sure what the abbreviation stands for (parameters?)
    spar::Union{Nothing,Vector} # not sure what the abbreviation stands for (parameters?)
    bcov::Union{Nothing,Matrix} # not sure what the abbreviation stands for (covariance?)
    scov::Union{Nothing,Matrix} # not sure what the abbreviation stands for (covariance?)
end

function sample(sname, datetime, labels, data)
    return sample(sname, datetime, labels, data, nothing, nothing, 0)
end

run(samples) = run(samples, nothing, nothing, nothing, nothing, nothing)
