# Script to run NGen.

# Add worker processes
# Note: Sys.CPU_CORES has been renamed to Sys.CPU_THREADS in Julia 1.0
while nprocs() < Sys.CPU_CORES
    addprocs(1)
end

@everywhere include("ngen.jl")

@time NGen.main()
