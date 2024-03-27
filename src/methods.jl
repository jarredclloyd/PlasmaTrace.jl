export getChannels,
    getSnames,
    getGroups,
    setStandards!,
    summarise,
    summarize,
    setBwin!,
    setSwin!,
    pool,
    setReferenceMaterials!,
    getAnchor,
    setAnchor!,
    subset,
    getDat,
    PAselect

function getChannels(run::Vector{Sample})
    return getChannels(run[1])
end

function getChannels(sample::Sample)
    return names(sample.data)[3:end]
end


function getSnames(run::Vector{Sample})
    return getAttr(run, :sample_name)
end

function getGroups(run::Vector{Sample})
    return getAttr(run, :group)
end

function getAttr(run::Vector{Sample}, attr::Symbol)
    ns = length(run)
    first = getproperty(run[1], attr)
    out = fill(first, ns)
    for i in eachindex(run)
        out[i] = getproperty(run[i], attr)
    end
    return out
end

function setStandards!(run::Vector{Sample}, selection::Vector{Int}, refmat::AbstractString)
    for i in selection
        run[i].group = refmat
    end
end
function setStandards!(run::Vector{Sample}, prefix::AbstractString, refmat::AbstractString)
    snames = getSnames(run)
    selection = findall(contains(prefix), snames)
    return setStandards!(run::Vector{Sample}, selection, refmat)
end
function setStandards!(run::Vector{Sample}, standards::AbstractDict)
    for (refmat, prefix) in standards
        setStandards!(run, prefix, refmat)
    end
end
function setStandards!(run::Vector{Sample}, refmat::AbstractString)
    for sample in run
        sample.group = refmat
    end
end


function summarise(run::Vector{Sample}, verbatim = true)
    ns = length(run)
    snames = getSnames(run)
    groups = fill("sample", ns)
    dates = fill(run[1].date_time, ns)
    for i in eachindex(run)
        groups[i] = run[i].group
        dates[i] = run[i].date_time
    end
    out = DataFrame(; name = snames, date = dates, group = groups)
    if verbatim
        println(out)
    end
    return out
end
function summarize(run::Vector{Sample}, verbatim = true)
    return summarise(run, verbatim)
end


function setBwin!(sample::Sample, blank_window = nothing)
    if isnothing(blank_window)
        blank_window = autoWindow(sample; blank = true)
    end
    return sample.blank_window = blank_window
end
function setBwin!(run::Vector{Sample}, blank_window = nothing)
    for i in eachindex(run)
        setBwin!(run[i], blank_window)
    end
end


function setSwin!(sample::Sample, signal_window = nothing)
    if isnothing(signal_window)
        signal_window = autoWindow(sample; blank = false)
    end
    return sample.signal_window = signal_window
end
function setSwin!(run::Vector{Sample}, signal_window = nothing)
    for i in eachindex(run)
        setSwin!(run[i], signal_window)
    end
end


function autoWindow(signals::AbstractDataFrame; blank = false)
    total = sum.(eachrow(signals))
    q = Statistics.quantile(total, [0.05, 0.95])
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
function autoWindow(sample::Sample; blank = false)
    return autoWindow(sample.data[:, 3:end]; blank = blank)
end

function pool(run::Vector{Sample}; blank = false, signal = false, group = nothing)
    if isnothing(group)
        selection = 1:length(run)
    else
        groups = getGroups(run)
        selection = findall(contains(group), groups)
    end
    ns = length(selection)
    dats = Vector{DataFrame}(undef, ns)
    for i in eachindex(selection)
        dats[i] = windowData(run[selection[i]]; blank = blank, signal = signal)
    end
    return reduce(vcat, dats)
end


function windowData(sample::Sample; blank = false, signal = false)
    if blank
        windows = sample.blank_window
    elseif signal
        windows = sample.signal_window
    else
        windows = [(1, size(sample, 1))]
    end
    selection = Integer[]
    for w in windows
        append!(selection, w[1]:w[2])
    end
    return sample.data[selection, :]
end

function string2windows(sample::Sample; text::AbstractString, single = false)
    if single
        parts = split(text, ',')
        stime = [parse(Float64, parts[1])]
        ftime = [parse(Float64, parts[2])]
        nw = 1
    else
        parts = split(text, ['(', ')', ','])
        stime = parse.(Float64, parts[2:4:end])
        ftime = parse.(Float64, parts[3:4:end])
        nw = Int(round(size(parts, 1) / 4))
    end
    windows = Vector{Window}(undef, nw)
    t = sample.data[:, 2]
    nt = size(t, 1)
    maxt = t[end]
    for i = 1:nw
        if stime[i] > t[end]
            stime[i] = t[end - 1]
            print("Warning: start point out of bounds and truncated to ")
            print(string(stime[i]) * " seconds.")
        end
        if ftime[i] > t[end]
            ftime[i] = t[end]
            print("Warning: end point out of bounds and truncated to ")
            print(string(maxt) * " seconds.")
        end
        start = max(1, Int(round(nt * stime[i] / maxt)))
        finish = min(nt, Int(round(nt * ftime[i] / maxt)))
        windows[i] = (start, finish)
    end
    return windows
end

function setReferenceMaterials!(csv::AbstractString)
    tab = CSV.read(csv, DataFrame)
    refmat = Dict()
    for row in eachrow(tab)
        method = row["method"]
        if !(method in keys(refmat))
            refmat[method] = Dict()
        end
        name = row["name"]
        refmat[method][name] = (t = (row["t"], row["st"]), y0 = (row["y0"], row["sy0"]))
    end
    return _PT["refmat"] = refmat
end


function getx0y0(method::AbstractString, refmat::AbstractString)
    L = _PT["lambda"][method][1]
    t = _PT["refmat"][method][refmat].t[1]
    x0 = 1 / (exp(L * t) - 1)
    y0 = _PT["refmat"][method][refmat].y0[1]
    return (x0 = x0, y0 = y0)
end

function getAnchor(method::AbstractString, refmat::AbstractString)
    if method == "LuHf"
        return getx0y0(method, refmat)
    end
end
function getAnchor(method::AbstractString, standards::Vector{String})
    nr = length(standards)
    out = Dict{String,NamedTuple}()
    for standard in standards
        out[standard] = getAnchor(method, standard)
    end
    return out
end
function getAnchor(method::AbstractString, standards::AbstractDict)
    return getAnchor(method, collect(keys(standards)))
end


function setAnchor!(method::AbstractString, standards::AbstractDict)
    setMethod!(method)
    setStandards!(standards)
    return setAnchor!()
end
function setAnchor!(method::AbstractString)
    setMethod!(method)
    return setAnchor!()
end


function subset(run::Vector{Sample}, selector::AbstractString)
    if length(selection) < 1
        selection = findall(contains(prefix), getGroups(selector))
    end
    return run[selection]
end
function subset(ratios::AbstractDataFrame, prefix::AbstractString)
    return ratios[findall(contains(prefix), ratios[:, 1]), :]
end


function getDat(samp::Sample)
    return samp.dat
end
function getDat(samp::Sample, channels::AbstractDict)
    return samp.dat[:, collect(values(channels))]
end

function PAselect(run::Vector{Sample}; channels::AbstractDict, cutoff::AbstractFloat)
    ns = length(run)
    good = fill(false, ns)
    for i in eachindex(good)
        dat = getDat(run[i], channels)
        good[i] = !(false in Matrix(dat .< cutoff))
    end
    return good
end
