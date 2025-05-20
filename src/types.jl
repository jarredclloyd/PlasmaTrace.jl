mutable struct Sample
    sname::String
    datetime::DateTime
    dat::DataFrame
    t0::Float64
    bwin::Vector{Tuple}
    swin::Vector{Tuple}
    group::String
end
export Sample

mutable struct OrderedDict
    names::Vector{String}
    dict::Dict
end
