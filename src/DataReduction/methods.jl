# helper functions
function label2index(pd::PlasmaData, labels::Union{Nothing,Vector{String}})
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
function accesSample(pd::Run, i::Union{Nothing,Integer,Vector{Integer}}, T::Type, fun::Function)
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
function accessSample!(pd::Run, i::Union{Integer,Vector{Integer}}, fun::Function, val::Any)
    samples = getSamples(pd)
    for j in i
        fun(samples[j], val)
    end
    return setSamples!(pd; samples = samples)
end
# set the control parameters inside a run:
function accessControl!(pd::Run, attribute::Symbol, fun::Function, val::Any)
    ctrl = getControl(pd)
    (ctrl, A)
    return setControl(pd; ctrl = ctrl)
end

# get sample attributes
function getSname(pd::Sample)
    return getproperty(pd, :samplename)
end
function getDateTime(pd::Sample)
    return getproperty(pd, :datetime)
end
function getLabels(pd::Sample)
    return getproperty(pd, :labels)
end
function getDat(pd::Sample)
    return getproperty(pd, :data)
end
function getBWin(pd::Sample)
    return getproperty(pd, :bwin)
end
function getSWin(pd::Sample)
    return getproperty(pd, :swin)
end
function getStandard(pd::Sample)
    return getproperty(pd, :standard)
end
function getCols(pd::Sample; labels)
    return getDat(pd)[:, label2index(pd, labels)]
end

# get run attributes
function getSamples(pd::Run)
    return getproperty(pd, :samples)
end
function getControl(pd::Run)
    return getproperty(pd, :control)
end
function getBPar(pd::Run)
    return getproperty(pd, :bpar)
end
function getSPar(pd::Run)
    return getproperty(pd, :spar)
end
function getBCov(pd::Run)
    return getproperty(pd, :bcov)
end
function getSCov(pd::Run)
    return getproperty(pd, :scov)
end

# get sample attributes from a run
function getSnames(pd::Run; i = nothing)
    return accesSample(pd, i, String, getSname)
end
function getDateTimes(pd::Run; i = nothing)
    return accesSample(pd, i, DateTime, getDateTime)
end
function getLabels(pd::Run; i = 1)
    return out = accesSample(pd, i, Vector{String}, getLabels)
end
function getDat(pd::Run; i = nothing)
    return accesSample(pd, i, Matrix, getDat)
end
function getBWin(pd::Run; i = nothing)
    return accesSample(pd, i, Vector{window}, getBWin)
end
function getSWin(pd::Run; i = nothing)
    return accesSample(pd, i, Vector{window}, getSWin)
end
function getStandard(pd::Run; i = nothing)
    return accesSample(pd, i, Integer, getStandard)
end

# get control attributes
function getA(ctrl::Union{Nothing, Control})
    return isnothing(ctrl) ? nothing : getproperty(ctrl, :A)
end
function getB(ctrl::Union{Nothing, Control})
    return isnothing(ctrl) ? nothing : getproperty(ctrl, :B)
end
function getChannels(ctrl::Union{Nothing, Control})
    return isnothing(ctrl) ? nothing : getproperty(ctrl, :channels)
end

# get control attributes from a run
function getA(pd::Run)
    return getA(getControl(pd))
end
function getB(pd::Run)
    return getB(getControl(pd))
end
function getChannels(pd::Run)
    return getChannels(getControl(pd))
end

# set sample attributes
function setSname!(pd::Sample; sname::String)
    return setproperty!(pd, :samplename, sname)
end
function setDateTime!(pd::Sample; datetime::DateTime)
    return setproperty!(pd, :datetime, datetime)
end
function setLabels!(pd::Sample; labels::Vector{String})
    return setproperty!(pd, :labels, labels)
end
function setDat!(pd::Sample; dat::Matrix)
    return setproperty!(pd, :dat, dat)
end
function setBWin!(pd::Sample, bwin::Vector{window})
    return setproperty!(pd, :bwin, bwin)
end
function setSWin!(pd::Sample, swin::Vector{window})
    return setproperty!(pd, :swin, swin)
end
function setStandard!(pd::Sample, standard::Integer)
    return setproperty!(pd, :standard, standard)
end

# set run attributes
function setSamples!(pd::Run; samples::Vector{Sample})
    return setproperty!(pd, :samples, samples)
end
function setControl!(pd::Run; ctrl::Control)
    return setproperty!(pd, :control, ctrl)
end
function setBPar!(pd::Run; bpar::Vector)
    return setproperty!(pd, :bpar, bpar)
end
function setSPar!(pd::Run; spar::Vector)
    return setproperty!(pd, :spar, spar)
end
function setBCov!(pd::Run; bcov::Matrix)
    return setproperty!(pd, :bcov, bcov)
end
function setSCov!(pd::Run; scov::Matrix)
    return setproperty!(pd, :scov, scov)
end

# set key sample attributes in a run
function setBWin!(pd::Run; i, bwin::Vector{window})
    return accessSample!(pd, i, setBWin!, bwin)
end
function setSWin!(pd::Run; i, swin::Vector{window})
    return accessSample!(pd, i, setSWin!, bwin)
end
function setStandard!(pd::Run; i, standard::Integer)
    return accessSample!(pd, i, setStandard!, standard)
end

# set control attributes
function setA!(ctrl::Control, A::Vector{AbstractFloat})
    return setproperty!(pd, :A, A)
end
function setB!(ctrl::Control, B::Vector{AbstractFloat})
    return setproperty!(pd, :B, B)
end
function setChannels!(ctrl::Control, channels::Vector{String})
    return setproperty!(pd, :channels, channels)
end

# set control attributes in a run
function setA!(pd::Run, A::AbstractFloat)
    return accessControl!(pd, :A, setA!, A)
end
function setB!(pd::Run, B::AbstractFloat)
    return accessControl!(pd, :B, setB!, b)
end
function setChannels!(pd::Run, channels::Vector{String})
    return accessControl!(pd, :channels, setChannels!, channels)
end

length(pd::Run) = size(getSamples(pd), 1)
ncol(pd::PlasmaData) = size(getLabels(pd), 1)

function poolRunDat(pd::Run, i = nothing)
    dats = getDat(pd; i = i)
    return reduce(vcat, dats)
end
