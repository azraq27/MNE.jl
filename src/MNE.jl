module MNE

using PyCall,Dates

mne = PyObject(nothing)

function __init__()
    global mne

    mne = pyimport("mne")
end

include("structs.jl")

end # module
