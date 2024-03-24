#=====================
pkg > activate .
pkg > test Plasmatrace
======================#

using Test, CSV
import Plots

function loadtest(verbatim=false)
    run = load("data",instrument="Agilent")
    if verbatim summarise(run) end
    return run
end

function plottest()
    myrun = loadtest()
    p = plot(myrun[1],["Hf176 -> 258","Hf178 -> 260"])
    @test display(p) != NaN
    p = plot(myrun[1],["Hf176 -> 258","Hf178 -> 260"], denominator="Hf178 -> 260")
    @test display(p) != NaN
end

function windowtest()
    myrun = loadtest()
    i = 2
    setSwin!(myrun[i],[(70,90),(100,140)])
    p = plot(myrun[i],["Hf176 -> 258","Hf178 -> 260"])
    @test display(p) != NaN
end

function blanktest()
    myrun = loadtest()
    blk = fit_blanks(myrun,n=2)
    return myrun, blk
end

function standardtest(verbatim=false)
    myrun, blk = blanktest()
    standards = Dict("BP" => "BP", "Hogsbo" => "hogsbo_ana")
    setStandards!(myrun,standards)
    anchors = getAnchor("LuHf",standards)
    if verbatim
        summarise(myrun)
        println(anchors)
    end
end

function fractionationtest()
    myrun, blk = blanktest()
    channels = Dict("d" => "Hf178 -> 260",
                    "D" => "Hf176 -> 258",
                    "P" => "Lu175 -> 175")
    standards = Dict("Hogsbo" => "hogsbo_ana")#, "BP" => "BP"
    setStandards!(myrun,standards)
    anchors = getAnchor("LuHf",standards)
    fit = fractionation(myrun,blank=blk,channels=channels,
                        anchors=anchors,nf=2,nF=1,
                        mf=1.4671,verbose=true)
    return myrun, blk, fit, channels, anchors
end

function predicttest()
    myrun, blk, fit, channels, anchors = fractionationtest()
    sample = myrun[5]
    pred = predict(sample,fit,blk,channels,anchors)
    p = plot(sample,channels,denominator="D")
    plotFitted!(p,sample,fit,blk,channels,anchors,denominator="D")
    @test display(p) != NaN
end

function crunchtest()
    myrun, blk, fit, channels, anchors = fractionationtest()
    pooled = pool(myrun,signal=true,group="Hogsbo")
    (x0,y0) = anchors["Hogsbo"]
    pred = predict(pooled,fit,blk,channels,x0,y0)
    misfit = @. pooled[:,channels["d"]] - pred[:,"d"]
    p = Plots.histogram(misfit,legend=false)
    @test display(p) != NaN
end

function sampletest()
    myrun, blk, fit, channels, anchors = fractionationtest()
    t, T, P, D, d = atomic(myrun[1],channels=channels,pars=fit,blank=blk)
    ratios = averat(myrun,channels=channels,pars=fit,blank=blk)
    return ratios
end

function readmetest()
    run = load("data",instrument="Agilent")
    blk = fit_blanks(run,n=2)
    standards = Dict("Hogsbo" => "hogsbo_ana") # "BP" => "BP"
    setStandards!(run,standards)
    anchors = getAnchor("LuHf",standards)
    channels = Dict("d"=>"Hf178 -> 260","D"=>"Hf176 -> 258","P"=>"Lu175 -> 175")
    fit = fractionation(run,blank=blk,channels=channels,anchors=anchors,nf=1,nF=0,mf=1.4671)
    ratios = averat(run,channels=channels,pars=fit,blank=blk)
    return ratios
end

function exporttest()
    ratios = readmetest()
    selection = subset(ratios,"BP") # "hogsbo"
    CSV.write("BP.csv",selection)
    export2IsoplotR("BP.json",selection,"LuHf")
end

function TUItest()
    PT("logs/test.log")
end

Plots.closeall()

@testset "load" begin loadtest(true) end
@testset "plot raw data" begin plottest() end
@testset "set selection window" begin windowtest() end
@testset "set method and blanks" begin blanktest() end
@testset "assign standards" begin standardtest(true) end
@testset "fit fractionation" begin fractionationtest() end
@testset "plot fit" begin predicttest() end
@testset "crunch" begin crunchtest() end
@testset "process sample" begin sampletest() end
@testset "readme example" begin readmetest() end
@testset "export" begin exporttest() end
@testset "TUI" begin TUItest() end
