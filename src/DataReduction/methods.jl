# helper functions
function label2index(pd::plasmaData, labels::Union{Nothing,Vector{String}})
    allabels = getLabels(pd)
    if isnothing(labels)
        return 1:size(allabels, 1)
    end
    out = Vector{Integer}(undef, 0)
    for label in labels
        i = findfirst(in([label]), allabels)
        if !isnothing(i)
            push!(out, i)
        end
    end
    return out
end
# get sample attributes from a run:
function accesSample(pd::run, i::Union{Nothing,Integer,Vector{Integer}}, T::Type, fun::Function)
    if isnothing(i)
        i = 1:length(pd)
    end
    samples = getSamples(pd)[i]
    if isa(i, Integer)
        out = fun(samples)
    else
        out = Vector{T}(undef, size(i, 1))
        for j in eachindex(samples)
            out[j] = fun(samples[j])
        end
    end
    return out
end
function accessSample!(pd::run, i::Union{Integer,Vector{Integer}}, fun::Function, val::Any)
    samples = getSamples(pd)
    for j in i
        fun(samples[j], val)
    end
    return setSamples!(pd; samples = samples)
end
# set the control parameters inside a run:
function accessControl!(pd::run, attribute::Symbol, fun::Function, val::Any)
    ctrl = getControl(pd)
    (ctrl, A)
    return setControl(pd; ctrl = ctrl)
end

# get sample attributes
function getSname(pd::sample)
    return getproperty(pd, :sname)
end
function getDateTime(pd::sample)
    return getproperty(pd, :datetime)
end
function getLabels(pd::sample)
    return getproperty(pd, :labels)
end
function getDat(pd::sample)
    return getproperty(pd, :dat)
end
function getBWin(pd::sample)
    return getproperty(pd, :bwin)
end
function getSWin(pd::sample)
    return getproperty(pd, :swin)
end
function getStandard(pd::sample)
    return getproperty(pd, :standard)
end
function getCols(pd::sample; labels)
    return getDat(pd)[:, label2index(pd, labels)]
end

# get run attributes
function getSamples(pd::run)
    return getproperty(pd, :samples)
end
function getControl(pd::run)
    return getproperty(pd, :control)
end
function getBPar(pd::run)
    return getproperty(pd, :bpar)
end
function getSPar(pd::run)
    return getproperty(pd, :spar)
end
function getBCov(pd::run)
    return getproperty(pd, :bcov)
end
function getSCov(pd::run)
    return getproperty(pd, :scov)
end

# get sample attributes from a run
function getSnames(pd::run; i = nothing)
    return accesSample(pd, i, String, getSname)
end
function getDateTimes(pd::run; i = nothing)
    return accesSample(pd, i, DateTime, getDateTime)
end
function getLabels(pd::run; i = 1)
    return out = accesSample(pd, i, Vector{String}, getLabels)
end
function getDat(pd::run; i = nothing)
    return accesSample(pd, i, Matrix, getDat)
end
function getBWin(pd::run; i = nothing)
    return accesSample(pd, i, Vector{window}, getBWin)
end
function getSWin(pd::run; i = nothing)
    return accesSample(pd, i, Vector{window}, getSWin)
end
function getStandard(pd::run; i = nothing)
    return accesSample(pd, i, Integer, getStandard)
end

# get control attributes
function getA(ctrl::Union{Nothing,control})
    return isnothing(ctrl) ? nothing : getproperty(ctrl, :A)
end
function getB(ctrl::Union{Nothing,control})
    return isnothing(ctrl) ? nothing : getproperty(ctrl, :B)
end
function getChannels(ctrl::Union{Nothing,control})
    return isnothing(ctrl) ? nothing : getproperty(ctrl, :channels)
end

# get control attributes from a run
function getA(pd::run)
    return getA(getControl(pd))
end
function getB(pd::run)
    return getB(getControl(pd))
end
function getChannels(pd::run)
    return getChannels(getControl(pd))
end

# set sample attributes
function setSname!(pd::sample; sname::String)
    return setproperty!(pd, :sname, sname)
end
function setDateTime!(pd::sample; datetime::DateTime)
    return setproperty!(pd, :datetime, datetime)
end
function setLabels!(pd::sample; labels::Vector{String})
    return setproperty!(pd, :labels, labels)
end
function setDat!(pd::sample; dat::Matrix)
    return setproperty!(pd, :dat, dat)
end
function setBWin!(pd::sample, bwin::Vector{window})
    return setproperty!(pd, :bwin, bwin)
end
function setSWin!(pd::sample, swin::Vector{window})
    return setproperty!(pd, :swin, swin)
end
function setStandard!(pd::sample, standard::Integer)
    return setproperty!(pd, :standard, standard)
end

# set run attributes
function setSamples!(pd::run; samples::Vector{sample})
    return setproperty!(pd, :samples, samples)
end
function setControl!(pd::run; ctrl::control)
    return setproperty!(pd, :control, ctrl)
end
function setBPar!(pd::run; bpar::Vector)
    return setproperty!(pd, :bpar, bpar)
end
function setSPar!(pd::run; spar::Vector)
    return setproperty!(pd, :spar, spar)
end
function setBCov!(pd::run; bcov::Matrix)
    return setproperty!(pd, :bcov, bcov)
end
function setSCov!(pd::run; scov::Matrix)
    return setproperty!(pd, :scov, scov)
end

# set key sample attributes in a run
function setBWin!(pd::run; i, bwin::Vector{window})
    return accessSample!(pd, i, setBWin!, bwin)
end
function setSWin!(pd::run; i, swin::Vector{window})
    return accessSample!(pd, i, setSWin!, bwin)
end
function setStandard!(pd::run; i, standard::Integer)
    return accessSample!(pd, i, setStandard!, standard)
end

# set control attributes
function setA!(ctrl::control, A::Vector{AbstractFloat})
    return setproperty!(pd, :A, A)
end
function setB!(ctrl::control, B::Vector{AbstractFloat})
    return setproperty!(pd, :B, B)
end
function setChannels!(ctrl::control, channels::Vector{String})
    return setproperty!(pd, :channels, channels)
end

# set control attributes in a run
function setA!(pd::run, A::AbstractFloat)
    return accessControl!(pd, :A, setA!, A)
end
function setB!(pd::run, B::AbstractFloat)
    return accessControl!(pd, :B, setB!, b)
end
function setChannels!(pd::run, channels::Vector{String})
    return accessControl!(pd, :channels, setChannels!, channels)
end

length(pd::run) = size(getSamples(pd), 1)
ncol(pd::plasmaData) = size(getLabels(pd), 1)

function poolRunDat(pd::run, i = nothing)
    dats = getDat(pd; i = i)
    return reduce(vcat, dats)
end
