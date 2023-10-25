function setBlanks!(pd::Sample; windows = nothing)
    return setWindows!(pd; blank = true, windows = windows)
end
function setBlanks!(pd::Run; windows = nothing, i = nothing)
    return setWindows!(pd; blank = true, windows = windows, i = i)
end

function setSignals!(pd::Sample; windows = nothing)
    return setWindows!(pd; blank = false, windows = windows)
end
function setSignals!(pd::Run; windows = nothing, i = nothing)
    return setWindows!(pd; blank = false, windows = windows, i = i)
end

function setWindows!(pd::Sample; blank = false, windows = nothing)
    if isnothing(windows)
        windows = autoWindow(pd; blank = blank)
    end
    fun = blank ? setBWin! : setSWin!
    return fun(pd, windows)
end
function setWindows!(pd::Run; blank = false, windows = nothing, i = nothing)
    if isnothing(i)
        i = 1:length(pd)
    end
    samples = getSamples(pd)
    for j in i
        setWindows!(samples[j]; blank = blank, windows = windows)
    end
    return setSamples!(pd; samples = samples)
end

function autoWindow(pd::Sample; blank = false)::Vector{window}
    dat = getDat(pd)[:, 3:end]
    total = vec(sum(dat; dims = 2))
    q = quantile(total, [0.05, 0.95])
    mid = (q[2] + q[1]) / 10
    low = total .< mid
    blk = findall(low)
    sig = findall(.!low)
    if blank
        min = minimum(blk)
        max = maximum(blk)
        from = floor(Int, min)
        to = floor(Int, (19 * max + min) / 20)
    else
        min = minimum(sig)
        max = maximum(sig)
        from = ceil(Int, (9 * min + max) / 10)
        to = ceil(Int, max)
    end
    return [(from, to)]
end

function blankData(pd::Sample; channels::Vector{String})
    return windowData(pd; blank = true, channels = channels)
end
function blankData(pd::Run; channels = nothing, i = nothing)
    return windowData(pd; blank = true, channels = channels, i = i)
end

function signalData(pd::Sample; channels::Vector{String})
    return windowData(pd; blank = false, channels = channels)
end
function signalData(pd::Run; channels = nothing, i = nothing)
    return windowData(pd; blank = false, channels = channels, i = i)
end

function windowData(pd::Sample; blank = false, channels = nothing)
    windows = blank ? getBWin(pd) : getSWin(pd)
    selection = Vector{Int}()
    if isnothing(windows)
        PTerror("missingWindows")
    end
    for w in windows
        append!(selection, w[1]:w[2])
    end
    labels = [getLabels(pd)[1:2]; channels] # add time columns
    dat = getCols(pd; labels = labels)
    return dat[selection, :]
end

function windowData(
    pd::Run;
    blank::Bool = false,
    channels::Union{Nothing,Vector{String}} = nothing,
    i::Union{Nothing,Int,Vector{Int}} = nothing,
)
    if isnothing(channels)
        channels = getChannels(pd)
        if isnothing(channels)
            channels = getLabels(pd)
        end
    end
    if isnothing(i)
        i = Vector{Int}(1:length(pd))
    elseif isa(i, Int)
        i = [i]
    end
    ni = size(i, 1)
    dats = Vector{Matrix}(undef, ni)
    samples = getSamples(pd)
    for j in eachindex(i)
        dats[j] = windowData(samples[i[j]]; blank = blank, channels = channels)
    end
    return reduce(vcat, dats)
end
