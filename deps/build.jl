using PyCall

# Test if MNE is installed in Python
try
    pyimport("mne")
catch
    # We need to try to install it
    using Conda,HTTP,YAML

    env_url = "https://raw.githubusercontent.com/mne-tools/mne-python/master/environment.yml"

    r = HTTP.request("GET",env_url)
    r.status!=200 && error("could not download dependency list for MNE")

    env = YAML.load(IOBuffer(r.body))
    Conda.add(Vector{String}(filter(d->d isa String,env["dependencies"])))

    pip = pyimport("pip._internal")

    pip_cmd = ["install"]
    for d in filter(d->d isa Dict && haskey(d,"pip"),env["dependencies"])[1]["pip"]
        occursin("--only-binary",d) && (d = split(d)[1])
        push!(pip_cmd,d)
    end
    pip.main(pip_cmd)

    pyimport("mne")
end
