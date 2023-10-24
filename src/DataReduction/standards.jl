function markStandards!(pd; i = nothing, prefix = nothing, snames = nothing, standard = 0)
    j = findSamples(pd; snames = snames, prefix = prefix, i = i)
    return setStandard!(pd; i = j, standard = standard)
end

function fitStandards!(pd::run; method::String, refmat::Union{String,Vector{String}}, n = 1)
    if isa(refmat, String)
        refmat = [refmat]
    end
    setDRS!(pd; method = method, refmat = refmat)
    groups = groupStandards!(pd)

    function misfit(par)
        out = 0
        c = par[end]
        aft = parseSPar(par; par = "f")
        aFT = parseSPar(par; par = "F")
        for g in groups
            ft = polyVal(; p = aft, t = g.t)
            FT = polyVal(; p = aFT, t = g.T)
            X = getX(g.Xm, g.Ym, g.Zm, g.A, g.B, ft, FT, g.bXt, g.bYt, g.bZt, c)
            Z = getZ(g.Xm, g.Ym, g.Zm, g.A, g.B, ft, FT, g.bXt, g.bYt, g.bZt, c)
            out +=
                sum(getS(X, Z, g.Xm, g.Ym, g.Zm, g.A, g.B, ft, FT, g.bXt, g.bYt, g.bZt, c))
        end
        return out
    end

    init = fill(0.0, 2 * n)
    fit = optimize(misfit, init)
    sol = Optim.minimizer(fit)
    return setSPar!(pd; spar = sol)
end

function groupStandards!(pd::run)
    bpar = getBPar(pd)
    if isnothing(bpar)
        PTerror("missingBlank")
    end
    A = getA(pd)
    B = getB(pd)
    bx = parseBPar(bpar; par = "bx")
    by = parseBPar(bpar; par = "by")
    bz = parseBPar(bpar; par = "bz")
    std = getStandard(pd)
    groups = Vector{NamedTuple}(undef, 0)
    for i in eachindex(A)
        j = findall(in(i), std)
        s = signalData(pd; channels = getChannels(pd), i = j)
        t = s[:, 1]
        T = s[:, 2]
        Xm = s[:, 3]
        Ym = s[:, 4]
        Zm = s[:, 5]
        bXt = polyVal(; p = bx, t = t)
        bYt = polyVal(; p = by, t = t)
        bZt = polyVal(; p = bz, t = t)
        dat = (
            A = A[i],
            B = B[i],
            t = t,
            T = T,
            Xm = Xm,
            Ym = Ym,
            Zm = Zm,
            bXt = bXt,
            bYt = bYt,
            bZt = bZt,
        )
        push!(groups, dat)
    end
    return groups
end

function predictStandard(
    pd::run;
    sname::Union{Nothing,String} = nothing,
    prefix::Union{Nothing,String} = nothing,
    i::Union{Nothing,Integer} = nothing,
)
    bpar = getBPar(pd)
    spar = getSPar(pd)
    if isnothing(bpar)
        PTerror("missingBlank")
    end
    if isnothing(spar)
        PTerror("missingStandard")
    end
    i = findSamples(pd; i = i, prefix = prefix, snames = sname)[1]
    standard = getStandard(pd; i = i)
    if standard < 1
        return nothing
    end
    s = signalData(pd; i = i)

    t = s[:, 1]
    T = s[:, 2]
    Xm = s[:, 3]
    Ym = s[:, 4]
    Zm = s[:, 5]
    c = parseSPar(spar; par = "c")
    ft = polyVal(; p = parseSPar(spar; par = "f"), t = t)
    FT = polyVal(; p = parseSPar(spar; par = "F"), t = T)

    bXt = polyVal(; p = parseBPar(bpar; par = "bx"), t = t)
    bYt = polyVal(; p = parseBPar(bpar; par = "by"), t = t)
    bZt = polyVal(; p = parseBPar(bpar; par = "bz"), t = t)

    A = getA(pd)[standard]
    B = getB(pd)[standard]
    X = getX(Xm, Ym, Zm, A, B, ft, FT, bXt, bYt, bZt, c)
    Z = getZ(Xm, Ym, Zm, A, B, ft, FT, bXt, bYt, bZt, c)

    Xp = @. X + bXt
    Yp = @. A * Z * exp(c) + B * X * ft * FT + bYt
    Zp = @. Z + bZt

    return hcat(t, T, Xp, Yp, Zp)
end

function parseSPar(spar; par = "c")
    if isnothing(spar)
        PTerror("missingStandard")
    end
    np = size(spar, 1)
    n = Int(np / 2)
    if (par == "c")
        return spar[end]
    elseif (par == "f")
        return spar[1:n]
    elseif (par == "F")
        return [0; spar[(n + 1):(2 * n - 1)]]
    else
        return nothing
    end
end
