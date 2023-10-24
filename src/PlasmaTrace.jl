#=
    PlasmaTrace.jl
    Data reduction software for laser ablation mass spectrometry.

    Copyright © 2023 Pieter Vermeesch & Jarred Lloyd

    Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated
    documentation files (the “Software”), to deal in the Software without restriction, including without limitation the
    rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit
    persons to whom the Software is furnished to do so, subject to the following conditions:

    The above copyright notice and this permission notice shall be included in all copies or substantial portions of the
    Software.

    THE SOFTWARE IS PROVIDED “AS IS”, WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE
    WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
    COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR
    OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.


=#
__precompile__()

module PlasmaTrace

import Base.SimdLoop: @simd
import Base.Threads: @spawn, @threads

using ColorSchemes
using Dates
using Optim
using Statistics
using StatsBase

include("types.jl")
include("referencematerials.jl")
include("Tools/toolbox.jl")
include("Tools/errors.jl")
include("Tools/io.jl")
include("DataReduction/blanks.jl")
include("DataReduction/crunch.jl")
include("DataReduction/DRS.jl")
include("DataReduction/methods.jl")
include("DataReduction/samples.jl")
include("DataReduction/standards.jl")
include("DataReduction/windows.jl")
include("Plotting/plots.jl")

end
