#=
    NEMO: Next Energy Modeling system for Optimization.
    https://github.com/sei-international/NemoMod.jl

    Copyright © 2025: Stockholm Environment Institute U.S.

    File description: Functions for using NEMO configuration files.
=#

"""
    ConfParser.parse_line(line::String)

Overload of ConfParser.parse_line() in which quoted key values are returned as-is in their
entirety.
"""
#= function ConfParser.parse_line(line::String)
    parsed = String[]
    splitted = split(line, ",")

    # BEGIN: Code added to standard parse_line function.
    if occursin(r"^\".*\"$", line)
        m = match(r"^\"(.*)\"$", line)
        push!(parsed, m.captures[1])
        return parsed
    end
    # END: Code added to standard parse_line function.

    for raw = splitted
        if occursin(r"\S+", raw)
            clean = match(r"\S+", raw)
            push!(parsed, clean.match)
        end
    end
    parsed
end =#

"""
    getconfig(quiet::Bool = false)

Reads in NEMO's configuration file, which should be in the Julia working directory,
in `TOML` format, and named `nemo.toml`, `nemo.ini`, or `nemo.cfg`. See the sample file 
in the NEMO package's `utils` directory for more information. Returns a `Dict` containing
the configuration file's contents, or `nothing` if no configuration file is found.

# Arguments
- `quiet::Bool = false`: Suppresses low-priority status messages (which are otherwise printed to STDOUT).
"""
function getconfig(quiet::Bool = false)
    configpathtoml::String = joinpath(pwd(), "nemo.toml")
    configpathini::String = joinpath(pwd(), "nemo.ini")
    configpathcfg::String = joinpath(pwd(), "nemo.cfg")
    configpath::String = ""

    if isfile(configpathtoml)
        configpath = configpathtoml
    elseif isfile(configpathini)
        configpath = configpathini
    elseif isfile(configpathcfg)
        configpath = configpathcfg
    else
        return nothing
    end

    try
        local configdata::Dict{String,Any} = TOML.parsefile(configpath)
        logmsg("Read NEMO configuration file at " * configpath * ".", quiet)
        return configdata
    catch
        logmsg("Could not parse NEMO configuration file at " * configpath * ". Please verify format.", quiet)
    end
end  # getconfig(quiet::Bool = false)

"""
    getconfigargs!(configfile::ConfParse,
        calcyears::Vector{Vector{Int}},
        varstosavearr::Array{String,1},
        bools::Array{Bool,1},
        quiet::Bool)

Loads run-time arguments for `calculatescenario()` from a configuration file.

# Arguments
- `configfile::ConfParse`: Configuration file. This argument is not changed by the function.
- `calcyears::Vector{Vector{Int}}`: `calculatescenario()` `calcyears` argument. Values specified
    in the configuration file for `[calculatescenarioargs]/calcyears` (including an empty or null value)
    replace what is in this array.
- `varstosavearr::Array{String,1}`: Array representation of `calculatescenario()` `varstosave` argument.
    Values specified in the configuration file for `[calculatescenarioargs]/varstosave` are added to this array.
- `bools::Array{Bool,1}`: Array of Boolean arguments for `calculatescenario()`: `restrictvars`, `reportzeros`,
    `continuoustransmission`, `forcemip`, and `quiet`, in that order. Values specified in the configuration file
    for `[calculatescenarioargs]/restrictvars`, `[calculatescenarioargs]/reportzeros`,
    `[calculatescenarioargs]/continuoustransmission`, `[calculatescenarioargs]/forcemip`, and `[calculatescenarioargs]/quiet`
    overwrite what is in this array (provided the values can be parsed as `Bool`).
- `quiet::Bool`: Suppresses low-priority status messages (which are otherwise printed to `STDOUT`).
    This argument is not changed by the function.
"""
#= function getconfigargs!(configfile::ConfParse, calcyears::Vector{Vector{Int}}, varstosavearr::Array{String,1},
    bools::Array{Bool,1}, strings::Array{String,1}, quiet::Bool)

    if haskey(configfile, "calculatescenarioargs", "calcyears")
        try
            calcyearsconfig = retrieve(configfile, "calculatescenarioargs", "calcyears")
            calcyearsconfigarr::Vector{Vector{Int}} = Vector{Vector{Int}}()  # calcyearsconfig converted to an array of arrays of years

            if isa(calcyearsconfig, String)
                # Should be a single year
                push!(calcyearsconfigarr, [Meta.parse(calcyearsconfig)])
            else
                # calcyearsconfig should be an array of strings - value in configuration file split on commas
                if length(calcyearsconfig) == 0
                    push!(calcyearsconfigarr, Vector{Int}())
                else
                    for e in calcyearsconfig
                        push!(calcyearsconfigarr, [Meta.parse(v) for v in split(e, "|")])  # Vertical bars delimit years in groups that are calculated together with perfect foresight
                    end
                end
            end

            # This separate operation is necessary in order to modify calcyears
            empty!(calcyears)
            append!(calcyears, calcyearsconfigarr)
            logmsg("Read calcyears argument from configuration file.", quiet)
        catch e
            logmsg("Could not read calcyears argument from configuration file. Error message: " * sprint(showerror, e) * ". Continuing with NEMO.", quiet)
        end
    end

    if haskey(configfile, "calculatescenarioargs", "varstosave")
        try
            varstosaveconfig = retrieve(configfile, "calculatescenarioargs", "varstosave")

            if typeof(varstosaveconfig) == String
                union!(varstosavearr, [lowercase(varstosaveconfig)])
            else
                # varstosaveconfig should be an array of strings
                union!(varstosavearr, [lowercase(v) for v in varstosaveconfig])
            end

            logmsg("Read varstosave argument from configuration file.", quiet)
        catch e
            logmsg("Could not read varstosave argument from configuration file. Error message: " * sprint(showerror, e) * ". Continuing with NEMO.", quiet)
        end
    end

    if haskey(configfile, "calculatescenarioargs", "restrictvars")
        try
            bools[1] = Meta.parse(lowercase(retrieve(configfile, "calculatescenarioargs", "restrictvars")))
            logmsg("Read restrictvars argument from configuration file.", quiet)
        catch e
            logmsg("Could not read restrictvars argument from configuration file. Error message: " * sprint(showerror, e) * ". Continuing with NEMO.", quiet)
        end
    end

    if haskey(configfile, "calculatescenarioargs", "reportzeros")
        try
            bools[2] = Meta.parse(lowercase(retrieve(configfile, "calculatescenarioargs", "reportzeros")))
            logmsg("Read reportzeros argument from configuration file.", quiet)
        catch e
            logmsg("Could not read reportzeros argument from configuration file. Error message: " * sprint(showerror, e) * ". Continuing with NEMO.", quiet)
        end
    end

    if haskey(configfile, "calculatescenarioargs", "continuoustransmission")
        try
            bools[3] = Meta.parse(lowercase(retrieve(configfile, "calculatescenarioargs", "continuoustransmission")))
            logmsg("Read continuoustransmission argument from configuration file.", quiet)
        catch e
            logmsg("Could not read continuoustransmission argument from configuration file. Error message: " * sprint(showerror, e) * ". Continuing with NEMO.", quiet)
        end
    end

    if haskey(configfile, "calculatescenarioargs", "forcemip")
        try
            bools[4] = Meta.parse(lowercase(retrieve(configfile, "calculatescenarioargs", "forcemip")))
            logmsg("Read forcemip argument from configuration file.", quiet)
        catch e
            logmsg("Could not read forcemip argument from configuration file. Error message: " * sprint(showerror, e) * ". Continuing with NEMO.", quiet)
        end
    end

    if haskey(configfile, "calculatescenarioargs", "startvalsdbpath")
        try
            startvalsdbpathconfig = retrieve(configfile, "calculatescenarioargs", "startvalsdbpath")

            if typeof(startvalsdbpathconfig) == String
                strings[1] = startvalsdbpathconfig
            else
                # startvalsdbpathconfig should be an array of strings
                strings[1] = join(startvalsdbpathconfig, ",")
            end

            logmsg("Read startvalsdbpath argument from configuration file.", quiet)
        catch e
            logmsg("Could not read startvalsdbpath argument from configuration file. Error message: " * sprint(showerror, e) * ". Continuing with NEMO.", quiet)
        end
    end

    if haskey(configfile, "calculatescenarioargs", "startvalsvars")
        try
            startvalsvarsconfig = retrieve(configfile, "calculatescenarioargs", "startvalsvars")

            if typeof(startvalsvarsconfig) == String
                strings[2] = startvalsvarsconfig
            else
                # startvalsvarsconfig should be an array of strings
                strings[2] = join(startvalsvarsconfig, ",")
            end

            logmsg("Read startvalsvars argument from configuration file.", quiet)
        catch e
            logmsg("Could not read startvalsvars argument from configuration file. Error message: " * sprint(showerror, e) * ". Continuing with NEMO.", quiet)
        end
    end

    if haskey(configfile, "calculatescenarioargs", "precalcresultspath")
        try
            precalcresultspathconfig = retrieve(configfile, "calculatescenarioargs", "precalcresultspath")

            if typeof(precalcresultspathconfig) == String
                strings[3] = precalcresultspathconfig
            else
                # startvalsdbpathconfig should be an array of strings
                strings[3] = join(precalcresultspathconfig, ",")
            end

            logmsg("Read precalcresultspath argument from configuration file.", quiet)
        catch e
            logmsg("Could not read precalcresultspath argument from configuration file. Error message: " * sprint(showerror, e) * ". Continuing with NEMO.", quiet)
        end
    end

    if haskey(configfile, "calculatescenarioargs", "quiet")
        try
            bools[5] = Meta.parse(lowercase(retrieve(configfile, "calculatescenarioargs", "quiet")))
            logmsg("Read quiet argument from configuration file. Value in configuration file will be used from this point forward.", quiet)
        catch e
            logmsg("Could not read quiet argument from configuration file. Error message: " * sprint(showerror, e) * ". Continuing with NEMO.", quiet)
        end
    end

    if haskey(configfile, "calculatescenarioargs", "jumpdirectmode")
        try
            bools[6] = Meta.parse(lowercase(retrieve(configfile, "calculatescenarioargs", "jumpdirectmode")))
            logmsg("Read jumpdirectmode argument from configuration file.", quiet)
        catch e
            logmsg("Could not read jumpdirectmode argument from configuration file. Error message: " * sprint(showerror, e) * ". Continuing with NEMO.", quiet)
        end
    end

    if haskey(configfile, "calculatescenarioargs", "jumpbridges")
        try
            bools[7] = Meta.parse(lowercase(retrieve(configfile, "calculatescenarioargs", "jumpbridges")))
            logmsg("Read jumpbridges argument from configuration file.", quiet)
        catch e
            logmsg("Could not read jumpbridges argument from configuration file. Error message: " * sprint(showerror, e) * ". Continuing with NEMO.", quiet)
        end
    end
end  # getconfigargs!(configfile::ConfParse, calcyears::Array{Int,1}, varstosavearr::Array{String,1}, bools::Array{Bool,1}, quiet::Bool) =#

"""
    setsolverparamsfromcfg(configfile::ConfParse, jumpmodel::JuMP.Model, quiet::Bool)

Sets solver parameters specified in a configuration file. Reports which parameters were and were not successfully set.

# Arguments
- `parameters_string::String`: String containing solver parameters in the format `parameter1=value1,parameter2=value2,...`.
- `jumpmodel::JuMP.Model`: JuMP model in which solver parameters will be set.
- `quiet::Bool`: Suppresses low-priority status messages (which are otherwise printed to `STDOUT`).
"""
function setsolverparamsfromcfg(parameters_string::String, jumpmodel::JuMP.Model, quiet::Bool)
    local params_set::String = ""  # List of parameters that were successfully set; used in status message

    # BEGIN: Process each parameter-value pair in parameters_string.
    for e in split(parameters_string, ","; keepempty=false)
        local split_p::Array{String,1} = [strip(pp) for pp = split(e, "="; keepempty=false)]  # Current parameter specification split on =; split_p[1] = parameter name, split_p[2] = parameter value

        if length(split_p) != 2
            logmsg("Could not set solver parameter specified in configuration file as " * e * ". Continuing with NEMO.", quiet)
            continue
        end

        local val  # Parsed value for current parameter

        # Int, float, and Boolean values - order is important since an integer value will parse to a float
        for t in [Int, Float64, Bool]
            val = tryparse(t, split_p[2])

            if !isnothing(val)
                break
            end
        end

        if isnothing(val)
            # String value
            val = split_p[2]
        end

        # Call set_optimizer_attribute for parameter and value
        try
            set_attribute(jumpmodel, split_p[1], val)
            params_set *= split_p[1] * ", "
        catch
            # Remove attribute from jumpmodel to prevent errors if jumpmodel later needs to be emptied
            try 
                delete!(jumpmodel.moi_backend.params, split_p[1])
            catch
                # Just continue
            end

            try 
                delete!(jumpmodel.moi_backend.optimizer.model.params, split_p[1])
            catch
                # Just continue
            end

            logmsg("Could not set solver parameter specified in configuration file as " * e * ". Continuing with NEMO.", quiet)
        end
    end
    # END: Process each parameter-value pair in parameters_string.

    # Report parameters that were set
    if length(params_set) != 0
        logmsg("Set following solver parameters using values in configuration file: " * params_set[1:prevind(params_set, lastindex(params_set), 2)] * ".", quiet)
    end
end  # setsolverparamsfromcfg(parameters_string::String, jumpmodel::JuMP.Model, quiet::Bool)

"""
     convert_ini_to_toml(ini_path::String, toml_path::String, quiet::Bool = false)

Converts a configuration file from NEMO 2.2 or earlier (in INI format) to the TOML format used in NEMO version 2.3 and later.

# Arguments
- `ini_path::String`: Path to the INI file to be converted.
- `toml_path::String`: Path where the new TOML file should be saved.
- `quiet::Bool = false`: Suppresses low-priority status messages (which are otherwise printed to `STDOUT`).
"""
function convert_ini_to_toml(ini_path::String, toml_path::String, quiet::Bool = false)
    try
        open(toml_path, "w") do io
            open(ini_path, "r") do ini_io
                for line in eachline(ini_io)
                    line = replace(line, ";" => "#")
                    
                    if startswith(line, r"\#|\[calculatescenarioargs\]|\[solver\]|\[includes\]") || isempty(strip(line))
                        # Retain comments, blank lines, and allowable blocks
                        println(io, line)
                    elseif startswith(line, r"jumpdirectmode|jumpbridges|restrictvars|reportzeros|continuoustransmission|forcemip|quiet")
                        # Boolean parameters
                        key, value = split(line, "="; limit=2)
                        
                        comment = ""  # Any comment on this line

                        if contains(value, "#")                        
                            value, comment = split(value, "#"; limit=2)
                        end
                        
                        println(io, "$(strip(key)) = $(strip(lowercase(value)))" * "$(isempty(comment) ? "" : " # $(strip(comment))")")
                    elseif startswith(line, "calcyears")
                        # calcyears parameter - convert to TOML array of arrays
                        key, value = split(line, "="; limit=2)

                        comment = ""  # Any comment on this line

                        if contains(value, "#")                        
                            value, comment = split(value, "#"; limit=2)
                        end

                        toml_value = "["  # Value written into TOML file

                        for group in split(value, ",")
                            years = [strip(y) for y in split(strip(group), "|")]
                            toml_value *= "[" * join(years, ", ") * "], "
                        end

                        toml_value = toml_value[1:length(toml_value) - 2] * "]"  # Remove trailing comma and space, add closing bracket
                        
                        println(io, "$(strip(key)) = $toml_value" * "$(isempty(comment) ? "" : " # $(strip(comment))")")
                    elseif startswith(line, "varstosave")
                        # varstosave parameter - convert to TOML array
                        key, value = split(line, "="; limit=2)

                        comment = ""  # Any comment on this line

                        if contains(value, "#")                        
                            value, comment = split(value, "#"; limit=2)
                        end              

                        vars = [strip(v) for v in split(value, ",")]
                        toml_value = "[\"" * join(vars, "\", \"") * "\"]"
                        println(io, "$(strip(key)) = $toml_value" * "$(isempty(comment) ? "" : " # $(strip(comment))")")
                    elseif startswith(line, r"startvalsdbpath|startvalsvars|precalcresultspath|parameters|beforescenariocalc|afterscenariocalc|customconstraints")
                        # String parameters
                        key, value = split(line, "="; limit=2)

                        comment = ""  # Any comment on this line

                        if contains(value, "#")                        
                            value, comment = split(value, "#"; limit=2)
                        end              

                        value = replace(value, "\"" => "") # Remove any existing quotes around value
                        println(io, "$(strip(key)) = \"$(strip(value))\"" * "$(isempty(comment) ? "" : " # $(strip(comment))")")
                    end
                end
            end
        end

        logmsg("Converted INI file at $ini_path to TOML file at $toml_path.", quiet)
    catch e
        logmsg("Could not convert INI file at $ini_path to TOML file at $toml_path. Error message: " * sprint(showerror, e) * ".")
    end
end  # convert_ini_to_toml(ini_path::String, toml_path::String)