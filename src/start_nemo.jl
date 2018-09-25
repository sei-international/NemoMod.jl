"""Point of entry for NEMO. Allows specification of command-line arguments:
    • dbpath - Path to SQLite database for scenario to be modeled.
    • solver - Name of solver to be used (currently, CPLEX or Cbc).
    • numprocs - Number of worker processes to use for NEMO run.
"""
function startnemo(dbpath::String, solver::String = "Cbc", numprocs::Int = Sys.CPU_CORES)
    # Note: Sys.CPU_CORES has been renamed to Sys.CPU_THREADS in Julia 1.0

    # Sample paths
    # dbpath = "C:\\temp\\TEMBA_datafile.sl3"
    # dbpath = "C:\\temp\\TEMBA_datafile_2010_only.sl3"
    # dbpath = "C:\\temp\\SAMBA_datafile.sl3"
    # dbpath = "C:\\temp\\utopia_2015_08_27.sl3"

    # BEGIN: Parameter validation.
    if !ispath(dbpath)
        error("dbpath must refer to a valid file system path.")
    end

    if uppercase(solver) == "CPLEX"
        solver = "CPLEX"
    elseif uppercase(solver) == "CBC"
        solver = "Cbc"
    else
        error("Requested solver (" * solver * ") is not supported.")
    end

    if numprocs < 1
        error("numprocs must be >= 1.")
    end
    # END: Parameter validation.

    # BEGIN: Add worker processes.
    while nprocs() < numprocs
        addprocs(1)
    end
    # END: Add worker processes.

    # BEGIN: Call main function for NEMO.
    @everywhere include("nemo.jl")

    @time Nemo.main()
    # END: Call main function for NEMO.
end  # startnemo()
