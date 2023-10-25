function plot(
    pd::Sample;
    channels::Union{Nothing,Vector{String}},
    transformation = "sqrt",
    show = true,
)
    if isnothing(channels)
        channels = getLabels(pd)
    end
    selected = [2; label2index(pd, channels)]
    plotdat = getDat(pd)[:, selected]
    p = plotHelper(
        plotdat;
        labels = getLabels(pd)[selected],
        transformation = transformation,
        show = show,
    )
    dy = Plots.ylims(p)
    plotWindows!(p; pd = pd, blank = true, dy = dy, linecolor = "blue")
    plotWindows!(p; pd = pd, blank = false, dy = dy, linecolor = "red")
    if show
        display(p)
    end
    return p
end

function plot(
    pd::Run;
    channels::Union{Nothing,Vector{String}} = nothing,
    transformation = "sqrt",
    steps = 1000,
    i::Union{Nothing,Int} = nothing,
    show = true,
)
    if isnothing(i)
        data = poolRunDat(pd)
        labels = getLabels(pd)
        if isnothing(channels)
            selected = [1; 3:ncol(pd)]
        else
            selected = [1; label2index(pd, channels)]
        end
        step = Int(ceil(size(data, 1) / steps))
        plotdat = data[1:step:end, selected]
        p = plotHelper(
            plotdat;
            labels = labels[selected],
            transformation = transformation,
            show = show,
            seriestype = :path,
        )
    else
        if isnothing(channels)
            channels = getChannels(pd)
        end
        p = plot(
            getSamples(pd)[i];
            channels = channels,
            transformation = transformation,
            show = show,
        )
        plotFitted!(p; pd = pd, i = i, channels = channels, transformation = transformation)
    end
    if show
        display(p)
    end
    return p
end

function plotHelper(
    data::Matrix;
    labels::Vector{String},
    seriestype = :scatter,
    ms = 2,
    ma = 0.5,
    transformation = "sqrt",
    show = false,
)
    x = data[:, 1]
    y = data[:, 2:end]
    ty = (transformation == "") ? y : eval(Symbol(transformation)).(y)
    p = Plots.plot(
        x,
        ty;
        seriestype = seriestype,
        ms = ms,
        ma = ma,
        label = reshape(labels[2:end], 1, :),
        legend = :topleft,
    )
    xlab = labels[1]
    ylab = transformation == "" ? "signal" : transformation * "(signal)"
    xlabel!(xlab)
    ylabel!(ylab)
    if show
        display(p)
    end
    return p
end

function plotWindows!(
    p;
    pd::Sample,
    blank = false,
    dy = Plots.ylims(p),
    linecolor = "black",
)
    windows = blank ? getBWin(pd) : getSWin(pd)
    if isnothing(windows)
        return
    end
    data = getDat(pd)
    for w in windows
        from = data[w[1], 2]
        to = data[w[2], 2]
        Plots.plot!(
            p,
            [from, from, to, to, from],
            collect(dy[[1, 2, 2, 1, 1]]);
            linecolor = linecolor,
            linestyle = :dot,
            label = "",
        )
    end
end

function plotFitted!(
    p;
    pd::Run,
    i::Int,
    channels = nothing,
    dy = Plots.ylims(p),
    transformation = "sqrt",
    linecolor = "black",
    linestyle = :solid,
    label = "",
)
    fittedchannels = getChannels(pd)
    if isnothing(fittedchannels)
        return
    end
    available = findall(in(channels), fittedchannels)
    if (size(available, 1) < 1)
        return
    end
    pred = predictStandard(pd; i = i)
    x = pred[:, 2]
    y = pred[:, available .+ 2]
    ty = (transformation == "") ? y : eval(Symbol(transformation)).(y)
    return Plots.plot!(
        p,
        x,
        ty;
        linecolor = linecolor,
        linestyle = linestyle,
        label = label,
    )
end
