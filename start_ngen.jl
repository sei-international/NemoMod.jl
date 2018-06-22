# Script to run NGen.

# Add worker processes
while nprocs() < Sys.CPU_CORES
    addprocs(1)
end

@everywhere include("ngen.jl")

@time NGen.main()
