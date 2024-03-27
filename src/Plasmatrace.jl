# Plasmatrace.jl
# Geochronological data reduction in Julia
#
# Copyright © 2024 Pieter Vermeesch & Jarred C. Lloyd
#
# Licence text goes here

module Plasmatrace

using Dates, DataFrames, Glob
using Plots: Plots
using Statistics: Statistics
using Optim: Optim
using LinearAlgebra: LinearAlgebra
using CSV: CSV
import Base.Threads: @spawn, @threads, @simd

include("types.jl")
include("methods.jl")
include("errors.jl")
include("toolbox.jl")
include("io.jl")
include("json.jl")
include("plots.jl")
include("process.jl")
include("crunch.jl")
include("TUI.jl")

end
