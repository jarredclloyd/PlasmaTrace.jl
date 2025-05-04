# ratios
function plot(samp::Sample,
              method::AbstractString,
              channels::AbstractDict,
              blank::AbstractDataFrame,
              pars::NamedTuple,
              standards::Union{AbstractDict,AbstractVector},
              glass::Union{AbstractDict,AbstractVector};
              num=nothing,den=nothing,
              transformation=nothing,
              seriestype=:scatter,
              ms=2,ma=0.5,xlim=:auto,ylim=:auto,
              linecol="black",linestyle=:solid,
              i=nothing,legend=:topleft,
              show_title=true,
              titlefontsize=10,
              kw...)
    Sanchors = getAnchors(method,standards,false)
    Ganchors = getAnchors(method,glass,true)
    anchors = merge(Sanchors,Ganchors)
    return plot(samp,channels,blank,pars,anchors;
                num=num,den=den,transformation=transformation,
                seriestype=seriestype,
                ms=ms,ma=ma,xlim=xlim,ylim=ylim,i=i,
                legend=legend,show_title=show_title,
                titlefontsize=titlefontsize,
                kw...)
end
function plot(samp::Sample,
              channels::AbstractDict,
              blank::AbstractDataFrame,
              pars::NamedTuple,
              anchors::AbstractDict;
              num=nothing,den=nothing,
              transformation=nothing,
              seriestype=:scatter,
              ms=2,ma=0.5,
              xlim=:auto,ylim=:auto,
              linecol="black",
              linestyle=:solid,
              i=nothing,
              legend=:topleft,
              show_title=true,
              titlefontsize=10,
              kw...)

    channelvec = collect(values(channels))

    if samp.group == "sample"

        p = plot(samp;
                 channels=channelvec,
                 num=num,den=den,transformation=transformation,
                 seriestype=seriestype,ms=ms,ma=ma,
                 xlim=xlim,ylim=ylim,i=i,
                 legend=legend,show_title=show_title,
                 titlefontsize=titlefontsize,kw...)
        
    else

        p = plot(samp;
                 channels=channelvec,
                 num=num,den=den,transformation=transformation,
                 seriestype=seriestype,ms=ms,ma=ma,xlim=xlim,ylim=ylim,
                 i=i,legend=legend,show_title=show_title,
                 titlefontsize=titlefontsize,kw...)

        plotFitted!(p,samp,blank,pars,channels,anchors;
                    num=num,den=den,transformation=transformation,
                    linecolor=linecol,linestyle=linestyle)
        
    end

    plotFittedBlank!(p,samp,blank,channelvec;
                     num=num,den=den,
                     transformation=transformation,
                     linecolor=linecol,linestyle=linestyle)

    return p
end
# concentrations
function plot(samp::Sample,
              blank::AbstractDataFrame,
              pars::AbstractVector,
              elements::AbstractDataFrame,
              internal::AbstractString;
              num=nothing,den=nothing,
              transformation=nothing,
              seriestype=:scatter,
              ms=2,ma=0.5,xlim=:auto,ylim=:auto,
              linecol="black",linestyle=:solid,i=nothing,
              legend=:topleft,show_title=true,
              titlefontsize=10,kw...)
    if samp.group == "sample"

        p = plot(samp;
                 num=num,den=den,transformation=transformation,
                 seriestype=seriestype,ms=ms,ma=ma,
                 xlim=xlim,ylim=ylim,i=i,
                 legend=legend,show_title=show_title,
                 titlefontsize=titlefontsize,kw...)
        
    else

        p = plot(samp;
                 num=num,den=den,transformation=transformation,
                 seriestype=seriestype,ms=ms,ma=ma,xlim=xlim,ylim=ylim,
                 i=i,legend=legend,show_title=show_title,
                 titlefontsize=titlefontsize,kw...)

        plotFitted!(p,samp,blank,pars,elements,internal;
                    num=num,den=den,transformation=transformation,
                    linecolor=linecol,linestyle=linestyle)
        
    end
    
    plotFittedBlank!(p,samp,blank;
                     num=num,den=den,transformation=transformation,
                     linecolor=linecol,linestyle=linestyle)

    return p
end
function plot(samp::Sample,
              blank::AbstractDataFrame,
              pars::AbstractVector,
              internal::AbstractString;
              num=nothing,den=nothing,
              transformation=nothing,
              seriestype=:scatter,
              ms=2,ma=0.5,xlim=:auto,ylim=:auto,
              linecol="black",linestyle=:solid,i=nothing,
              legend=:topleft,show_title=true,
              titlefontsize=10,kw...)
    elements = channels2elements(samp)
    return plot(samp,blank,pars,elements,internal;
                num=num,den=den,
                transformation=transformation,
                seriestype=seriestype,ms=ms,ma=ma,xlim=xlim,ylim=ylim,
                linecol=linecol,linestyle=linestyle,i=i,
                legend=legend,show_title=show_title,
                titlefontsize=titlefontsize,kw...)
end
function plot(samp::Sample;
              channels::AbstractVector=getChannels(samp),
              num::Union{Nothing,AbstractString}=nothing,
              den::Union{Nothing,AbstractString}=nothing,
              transformation::Union{Nothing,AbstractString}=nothing,
              seriestype=:scatter,ms=2,ma=0.5,
              xlim=:auto,ylim=:auto,
              i::Union{Nothing,Integer}=nothing,
              legend=:topleft,
              show_title=true,
              titlefontsize=10,
              padding::Number=0.1,
              kw...)
    x, y, ty, xlab, ylab, ylim = prep_plot(samp,channels,num,den,ylim,transformation)
    p = Plots.plot(x,Matrix(ty);
                   ms=ms,ma=ma,seriestype=seriestype,
                   label=permutedims(names(y)),
                   legend=legend,xlimits=xlim,ylimits=ylim,
                   kw...)
    Plots.xlabel!(xlab)
    Plots.ylabel!(ylab)
    if show_title
        title = samp.sname*" ["*samp.group*"]"
        if !isnothing(i)
            title = string(i) * ". " * title
        end
        Plots.title!(title;titlefontsize=titlefontsize)
    end
    if ylim == :auto
        dy_win = collect(Plots.ylims(p))
    else
        buffer = (ylim[2]-ylim[1])*padding/2
        dy_win = (ylim[1] + buffer, ylim[2] - buffer)
    end
    # plot t0:
    Plots.plot!(p,[samp.t0,samp.t0],collect(dy_win[[1,2]]);
                linecolor="grey",linestyle=:dot,label="")
    # plot selection windows:
    for win in [samp.bwin,samp.swin]
        for w in win
            from = x[w[1]]
            to = x[w[2]]
            Plots.plot!(p,[from,from,to,to,from],collect(dy_win[[1,2,2,1,1]]);
                        linecolor="black",linestyle=:dot,label="")
        end
    end
    return p
end
export plot

function prep_plot(samp::Sample,
                   channels::AbstractVector,
                   num::Union{Nothing,AbstractString}=nothing,
                   den::Union{Nothing,AbstractString}=nothing,
                   ylim=:auto,
                   transformation::Union{Nothing,AbstractString}=nothing;
                   padding::Number=0.1)
    xlab = names(samp.dat)[1]
    x = samp.dat[:,xlab]
    meas = samp.dat[:,channels]
    ratsig = isnothing(den) ? "signal" : "ratio"
    y = (ratsig == "signal") ? meas : formRatios(meas,num,den)    
    arg = nothing
    min_val = minimum(Matrix(y))
    if isnothing(transformation)
        ylab = ratsig
    elseif (transformation == "log" && min_val <= 0) ||
        (transformation == "sqrt" && min_val < 0)
        ylab = transformation * "(" * ratsig * "+offset)"
    else
        ylab = transformation*"("*ratsig*")"
    end
    ty = transformeer(y,transformation)
    if ylim == :auto && ratsig == "ratio"
        ylim = get_ylim(samp,channels,num,den,transformation;
                        padding=padding)
    end
    return x, y, ty, xlab, ylab, ylim
end
export prep_plot
function get_ylim(samp::Sample,
                  channels::AbstractVector,
                  num::Union{Nothing,AbstractString}=nothing,
                  den::Union{Nothing,AbstractString}=nothing,
                  transformation::Union{Nothing,AbstractString}=nothing;
                  padding::Number=0.1)
    dat = windowData(samp,blank=false,signal=true)
    meas = dat[:,channels]
    ratsig = isnothing(den) ? "signal" : "ratio"
    y = (ratsig == "signal") ? meas : formRatios(meas,num,den)
    ty = transformeer(y,transformation)
    miny, maxy = extrema(Matrix(ty))
    buffer = (maxy-miny)*padding
    return (miny-buffer,maxy+buffer)
end

# minerals
function plotFitted!(p,
                     samp::Sample,
                     blank::AbstractDataFrame,
                     pars::NamedTuple,
                     channels::AbstractDict,
                     anchors::AbstractDict;
                     num::Union{Nothing,AbstractString}=nothing,
                     den::Union{Nothing,AbstractString}=nothing,
                     transformation::Union{Nothing,AbstractString}=nothing,
                     linecolor="black",
                     linestyle=:solid)
    pred = predict(samp,pars,blank,channels,anchors)
    rename!(pred,[channels[i] for i in names(pred)])
    plotFitted!(p,samp,pred;
                num=num,den=den,transformation=transformation,
                linecolor=linecolor,linestyle=linestyle)
end
# concentrations
function plotFitted!(p,
                     samp::Sample,
                     blank::AbstractDataFrame,
                     pars::AbstractVector,
                     elements::AbstractDataFrame,
                     internal::AbstractString;
                     num::Union{Nothing,AbstractString}=nothing,
                     den::Union{Nothing,AbstractString}=nothing,
                     transformation::Union{Nothing,AbstractString}=nothing,
                     linecolor="black",
                     linestyle=:solid)
    pred = predict(samp,pars,blank,elements,internal)
    plotFitted!(p,samp,pred;
                num=num,den=den,transformation=transformation,
                linecolor=linecolor,linestyle=linestyle)
end
# helper
function plotFitted!(p,
                     samp::Sample,
                     pred::AbstractDataFrame;
                     blank::Bool=false,signal::Bool=true,
                     num::Union{Nothing,AbstractString}=nothing,
                     den::Union{Nothing,AbstractString}=nothing,
                     transformation::Union{Nothing,AbstractString}=nothing,
                     linecolor="black",linestyle=:solid)
    x = windowData(samp,blank=blank,signal=signal)[:,1]
    y = formRatios(pred,num,den)
    ty = transformeer(y,transformation)
    for tyi in eachcol(ty)
        Plots.plot!(p,x,tyi;linecolor=linecolor,linestyle=linestyle,label="")
    end
end
export plotFitted!

# minerals
function plotFittedBlank!(p,
                          samp::Sample,
                          blank::AbstractDataFrame,
                          channels::AbstractVector;
                          num::Union{Nothing,AbstractString}=nothing,
                          den::Union{Nothing,AbstractString}=nothing,
                          transformation::Union{Nothing,AbstractString}=nothing,
                          linecolor="black",
                          linestyle=:solid)
    pred = predict(samp,blank[:,channels])
    plotFitted!(p,samp,pred;
                blank=true,signal=false,
                num=num,den=den,transformation=transformation,
                linecolor=linecolor,linestyle=linestyle)
end
# concentrations
function plotFittedBlank!(p,
                          samp::Sample,
                          blank::AbstractDataFrame;
                          num::Union{Nothing,AbstractString}=nothing,
                          den::Union{Nothing,AbstractString}=nothing,
                          transformation::Union{Nothing,AbstractString}=nothing,
                          linecolor="black",
                          linestyle=:solid)
    pred = predict(samp,blank)
    plotFitted!(p,samp,pred;
                blank=true,signal=false,
                num=num,den=den,transformation=transformation,
                linecolor=linecolor,linestyle=linestyle)
end
export plotFittedBlank!
