function formRatios(df::AbstractDataFrame,
                    num::AbstractString,
                    den::Union{Nothing,AbstractVector};
                    brackets=false)
    formRatios(df,[num],den;brackets=brackets)
end
function formRatios(df::AbstractDataFrame,
                    num::Union{Nothing,AbstractVector},
                    den::AbstractString;
                    brackets=false)
    formRatios(df,num,[den];brackets=brackets)
end
function formRatios(df::AbstractDataFrame,
                    num::Union{Nothing,AbstractVector},
                    den::Union{Nothing,AbstractVector};
                    brackets=false)
    labels = names(df)
    nc = size(labels,1)
    if isnothing(num) && isnothing(den)
        return df
    elseif isnothing(num)
        n = findall(!=(den[1]),labels)
        d = fill(findfirst(==(den[1]),labels),length(n))
    elseif isnothing(den)
        d = findall(!=(num[1]),labels)
        n = fill(findfirst(==(num[1]),labels),length(d))
    elseif length(num)==length(den)
        n = findall(in(num),labels)
        d = findall(in(den),labels)        
    elseif length(num)>length(den)
        n = findall(in(num),labels)
        d = fill(findfirst(==(den[1]),labels),length(n))
    else
        d = findall(in(den),labels)
        n = fill(findfirst(==(num[1]),labels),length(d))
    end
    mat = Matrix(df)
    ratios = @. (mat[:,n]+0.5)/(mat[:,d]+0.5)
    num = labels[n]
    den = labels[d]
    ratlabs = brackets ? "(".*num.*")/(".*den.*")" : num.*"/".*den
    DataFrame(ratios,ratlabs)
end

# polynomial fit with logarithmic coefficients
function polyFit(t::AbstractVector,
                 y::AbstractVector,
                 n::Integer)
    if any(y.>0.0)
        function misfit(par)
            pred = polyVal(par,t)
            sum((y.-pred).^2)
        end
        b0 = log(abs(Statistics.mean(y)))
        init = [b0;fill(-10,n-1)]
        fit = Optim.optimize(misfit,init)
        return Optim.minimizer(fit)
    else
        return fill(-Inf,n)
    end
end

function polyVal(p::AbstractVector,
                 t::AbstractVector)
    np = length(p)
    nt = length(t)
    out = fill(0.0,nt)
    if np>0
        for i in 1:np
            out .+= exp(p[i]).*t.^(i-1)
        end
    end
    out
end
function polyVal(p::AbstractDataFrame,
                 t::AbstractVector)
    nc = size(p,2)
    nr = length(t)
    out = DataFrame(fill(0.0,(nr,nc)),names(p))
    for col in names(p)
        out[:,col] = polyVal(p[:,col],t)
    end
    return out
end
export polyVal

function polyFac(p::AbstractVector,
                 t::AbstractVector)
    np = length(p)
    nt = length(t)
    if np>0
        out = fill(0.0,nt)
        for i in 1:np
            out .+= p[i].*t.^(i-1)
        end
        return exp.(out)
    else
        return fill(1.0,nt)
    end
end
export polyFac

function summarise(run::Vector{Sample};
                   verbose=false,n=length(run))
    ns = length(run)
    snames = getSnames(run)
    groups = fill("sample",ns)
    dates = fill(run[1].datetime,ns)
    for i in eachindex(run)
        groups[i] = run[i].group
        dates[i] = run[i].datetime
    end
    out = DataFrame(name=snames,date=dates,group=groups)
    if verbose println(first(out,n)) end
    return out
end
function summarize(run::Vector{Sample};
                   verbose=true,n=length(run))
    summarise(run;verbose,n)
end
export summarise, summarize

function autoBwin(t::AbstractVector,
                  on::AbstractFloat;
                  start::AbstractFloat=t[1],
                  stop::AbstractFloat=t[end],
                  off::AbstractFloat=stop,
                  absolute_buffer::AbstractFloat=2.0,
                  relative_buffer::AbstractFloat=0.1)
    selection = (t.>=start .&& t.<=stop)
    if (on-start) > absolute_buffer
        t2 = on - absolute_buffer
    else
        t2 = on - (on - start)*(1 - relative_buffer)
    end
    i1 = 1
    i2 = findall(t[selection] .< t2)[end]
    return [(i1,i2)]
end
function autoSwin(t::AbstractVector,
                  on::AbstractFloat;
                  start::AbstractFloat=t[1],
                  stop::AbstractFloat=t[end],
                  off::AbstractFloat=stop,
                  absolute_buffer::AbstractFloat=2.0,
                  relative_buffer::AbstractFloat=0.1)
    selection = (t.>=start .&& t.<=stop)
    if (off-on) > 2*absolute_buffer
        t1 = on + absolute_buffer
        t2 = off - absolute_buffer
    else
        t1 = on + (off - on)*(1 - relative_buffer)
        t2 = off - (off - on)*(1 - relative_buffer)
    end
    i1 = findall(t[selection] .< t1)[end]
    i2 = findall(t[selection] .< t2)[end]
    return [(i1,i2)]
end
function autoWindow(t::AbstractVector,
                    t0::AbstractFloat;
                    blank::Bool=false,
                    absolute_buffer::AbstractFloat=2.0,
                    relative_buffer::AbstractFloat=0.1)
    if blank
        return autoBwin(t,t0;
                        absolute_buffer=absolute_buffer,
                        relative_buffer=relative_buffer)
    else
        return autoSwin(t,t0;
                        absolute_buffer=absolute_buffer,
                        relative_buffer=relative_buffer)
    end
end
function autoWindow(samp::Sample;
                    blank=false)
    return autoWindow(samp.dat[:,1],samp.t0;blank=blank)
end

function pool(run::Vector{Sample};blank=false,signal=false,group=nothing)
    if isnothing(group)
        selection = 1:length(run)
    else
        groups = getGroups(run)
        selection = findall(contains(group),groups)
    end
    ns = length(selection)
    dats = Vector{DataFrame}(undef,ns)
    for i in eachindex(selection)
        dats[i] = windowData(run[selection[i]],blank=blank,signal=signal)
    end
    return reduce(vcat,dats)
end
export pool

function windowData(samp::Sample;blank=false,signal=false)
    if blank
        windows = samp.bwin
    elseif signal
        windows = samp.swin
    else
        windows = [(1,size(samp.dat,1))]
    end
    selection = windows2selection(windows)
    out =  samp.dat[selection,:]
    if signal
        out.T = (out[:,1] .- samp.t0)./60 # in minutes, for numerical stability
    end
    return out
end
export windowData

function windows2selection(windows)
    selection = Integer[]
    for w in windows
        append!(selection, w[1]:w[2])
    end
    return selection
end

function string2windows(samp::Sample,text::AbstractString,single::Bool)
    if single
        parts = split(text,',')
        stime = [parse(Float64,parts[1])]
        ftime = [parse(Float64,parts[2])]
        nw = 1
    else
        parts = split(text,['(',')',','])
        stime = parse.(Float64,parts[2:4:end])
        ftime = parse.(Float64,parts[3:4:end])
        nw = Int(round(size(parts,1)/4))
    end
    windows = Vector{Window}(undef,nw)
    t = samp.dat[:,1]
    nt = size(t,1)
    maxt = t[end]
    for i in 1:nw
        if stime[i]>t[end]
            stime[i] = t[end-1]
            print("Warning: start point out of bounds and truncated to ")
            print(string(stime[i]) * " seconds.")
        end
        if ftime[i]>t[end]
            ftime[i] = t[end]
            print("Warning: end point out of bounds and truncated to ")
            print(string(maxt) * " seconds.")
        end
        windows[i] = time2window(samp,stime[i],ftime[i])
    end
    return windows
end

function t2i(samp::Sample,t::Number)
    nt = size(samp.dat,1)
    maxt = samp.dat[end,1]
    return Int(round(nt*t/maxt))
end
export t2i
function i2t(samp::Sample,i::Integer)
    ni = size(samp.dat,1)
    maxt = samp.dat[end,1]
    return maxt*i/ni
end
export i2t

function time2window(samp::Sample,start::Number,finish::Number)
    ni = size(samp.dat,1)
    from = max(1,t2i(samp,start))
    to = min(ni,t2i(samp,finish))
    return (from,to)
end
function time2window(samp::Sample,twin::AbstractVector)
    out = Tuple[]
    for win in twin
        push!(out,time2window(samp,win[1],win[2]))
    end
    return out
end
export time2window

function prefix2subset(run::Vector{Sample},
                       prefix::AbstractString)
    selection = findall(contains(prefix),getSnames(run))
    return run[selection]
end
function prefix2subset(ratios::AbstractDataFrame,
                       prefix::AbstractString)
    return ratios[findall(contains(prefix),ratios[:,1]),:]
end
export prefix2subset

function automatic_datetime(datetime_string::AbstractString)
    if occursin(r"-", datetime_string)
        date_delim = '-'
    elseif occursin(r"/", datetime_string)
        date_delim = '/'
    else
        date_delim = nothing
    end
    if occursin(r"(?i:AM|PM)", datetime_string)
        time_format = "H:M:S p"
    elseif occursin(r".", datetime_string)
        time_format = "H:M:S.s"
    else
        time_format = "H:M:S"
    end
    datetime_vector = split(datetime_string, r"[-\/ ]")
    if length(datetime_vector[1]) == 4
        date_format = "Y$(date_delim)m$(date_delim)d"
    elseif tryparse(Int,datetime_vector[1]) > 12
        date_format = "d$(date_delim)m$(date_delim)Y"
    else
        date_format = "m$(date_delim)d$(date_delim)Y"
    end
    datetime_format = DateFormat(date_format * " " * time_format)
    datetime = Dates.DateTime(datetime_string,datetime_format)
    if Dates.Year(datetime) < Dates.Year(100)
        datetime += Dates.Year(2000)
    end
    return datetime
end

function time_difference(start::AbstractString,stop::AbstractString)
    t1 = automatic_datetime(start)
    t2 = automatic_datetime(stop)
    return Millisecond(t2-t1).value / 1000
end

"""
rle(v)

Return the run-length encoding of a vector as a tuple.

Function lifted from StatsBase.jl
"""
function rle(v::AbstractVector{T}) where T
    n = length(v)
    vals = T[]
    lens = Int[]
    n>0 || return (vals,lens)
    cv = v[1]
    cl = 1
    i = 2
    @inbounds while i <= n
        vi = v[i]
        if isequal(vi, cv)
            cl += 1
        else
            push!(vals, cv)
            push!(lens, cl)
            cv = vi
            cl = 1
        end
        i += 1
    end
    push!(vals, cv)
    push!(lens, cl)
    return (vals, lens)
end
    
function transformeer(df::AbstractDataFrame,
                      transformation::Union{Nothing,AbstractString})
    if isnothing(transformation)
        out = df
    else
        out = copy(df)
        for key in names(out)
            out[:,key] = eval(Symbol(transformation)).(df[:,key])
        end
    end
    return out
end

function get_offset()
    return 10
end

function Log(val::AbstractFloat)
    return log(val + get_offset())
end
export Log

function dict2string(dict::AbstractDict)
    k = collect(keys(dict))
    v = collect(values(dict))
    q = isa(v[1],AbstractString) ? '"' : ""
    out = "Dict(" * '"' * k[1] * '"' * " => " * q * string(v[1]) * q
    for i in 2:length(k)
        q = isa(v[i],AbstractString) ? '"' : ""
        out *= "," * '"' * k[i] * '"' * " => " * q * string(v[i]) * q
    end
    out *= ")"
    return out
end

function vec2string(v::AbstractVector)
    return "[\"" * join(v .* "\",\"")[1:end-3] * "\"]"
end

function channels2elements(samp::Sample)
    channels = getChannels(samp)
    out = DataFrame()
    elements = collect(keys(_KJ["nuclides"]))
    for channel in channels
        out[!,channel] = channel2element(channel,elements)
    end
    return out    
end
function channels2elements(run::AbstractVector)
    return channels2elements(run[1])
end
export channels2elements

function channel2element(channel::AbstractString,
                         elements::AbstractVector)
    matches = findall(occursin.(elements,channel))
    if length(matches)>1 # e.g. "B" and "Be"
        for element in elements[matches]
            isotopes = string.(_KJ["nuclides"][element])
            hasisotope = findall(occursin.(isotopes,channel))
            if !isempty(hasisotope)
                return [element]
                break
            end
        end
    else # e.g. "Pb"
        return elements[matches]
    end
    return nothing
end
function channel2element(channel::AbstractString)
    elements = collect(keys(_KJ["nuclides"]))
    return channel2element(channel,elements)
end

# elements = 1-row dataframe of elements with channels as column names
# SRM = the name of a glass
# returns a 1-row dataframe with the concentrations
function elements2concs(elements::AbstractDataFrame,
                        SRM::AbstractString)
    refconc = _KJ["glass"][SRM]
    out = copy(elements)
    for col in names(elements)
        element = elements[1,col]
        out[!,col] = DataFrame(refconc)[:,element]
    end
    return out
end

function var_timeseries(cps::AbstractVector)
    var = Statistics.mean((cps[2:end].-cps[1:end-1]).^2)
    return fill(var,length(cps))
end
export var_timeseries

# requires that length(pars) == 2
function hessian2xyerr(H::Matrix,
                       pars::AbstractVector)
    try
        E = LinearAlgebra.inv(H)
        s1 = E[1,1]>0 ? sqrt(E[1,1]) : NaN
        s2 = E[2,2]>0 ? sqrt(E[2,2]) : NaN
        rho = E[1,2]/(s1*s2)
        return [pars[1] s1 pars[2] s2 rho]
    catch
        return [pars[1] NaN pars[2] NaN NaN]
    end
end
