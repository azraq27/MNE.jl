# Basic structures

export FreqData,FreqArray,FreqVector

export duration
export stoi,itos
export channel,times

"Abstract type of structs containing frequency data"
abstract type FreqData end

"""
    FreqVector{T}(data::AbstractArray{T,1}, freq::Float64; name::String="", code::Symbol=:unknown) where T<:Number

Struct of a single `Vector` frequency data.
* `data`: raw data points
* `freq`: data frequency
* `name`: arbitrary name as `String` (default = `""`)
* `code`: arbitrary data type as `Symbol` (default = `:unknown`)

Data can be accessed using []-notation
"""
mutable struct FreqVector{T} <: FreqData where T<:Number
    data::AbstractArray{T,1}
    freq::Float64
    name::String
    code::Symbol
end

FreqVector(data::AbstractArray{T,1},freq::K;name::String="",code::Symbol=:unknown) where {T<:Number,K<:Real} = FreqVector(data,Float64(freq),name,code)

"""
    FreqArray{T}(data::AbstractArray{T,2}, freq::Float64; names::Vector{String}=[], code::Symbol=:unknown) where T<:Number

Struct of an `Array` frequency data. Makes the assumption `data` was collected at same frequency, synced in time.

* `data`: raw data points; arranged as (time, channels), column-major
* `freq`: data frequency
* `names`: `Vector{String}` of names (default = ["","" ...])
* `code`: arbitrary data type as `Symbol` (default = `:unknown`)

Data can be accessed by []-notation, or using the helper function `channel` to return a single `FreqVector`
"""
mutable struct FreqArray{T} <: FreqData where T<:Number
    data::AbstractArray{T,2}
    freq::Float64
    names::Vector{String}
    code::Symbol

    function FreqArray(data::AbstractArray{T,2},freq::K;names::Vector{String}=[],code::Symbol=:unknown) where {T<:Number,K<:Number}
        if length(names)==0
            names = ["" for i=1:size(data,2)]
        end
        if size(data,2) != length(names)
            error("""Trying to create a FreqArray with data size $(size(data)) and names length $(length(names))
                    Data must be arranged in columns""")
        end
        return new{T}(data,Float64(freq),names,code)
    end
end

function FreqArray(v::FreqVector{T}...) where T
    codes = collect(Set([vv.code for vv in v]))
    freqs = collect(Set([vv.freq for vv in v]))
    @assert length(codes)==1
    @assert length(freqs)==1

    lengths = collect(Set([length(vv.data) for vv in v]))
    @assert length(lengths)==1

    names = [vv.name for vv in v]
    data = Array{T,2}(undef,(lengths[1],length(names)))
    for i=1:length(names)
        data[:,i] = v[i].data
    end

    FreqArray(data,freqs[1],names,codes[1])
end

import Base.length,Base.getindex

itype = Union{Vector{Int},UnitRange,Colon}

length(v::FreqVector) = length(v.data)
length(a::FreqArray) = size(a.data,1)

"""length of `FreqData` in seconds"""
duration(v::FreqData) = length(v)*(1/v.freq)

getindex(v::FreqVector,I::itype) = FreqVector(view(v.data,I),v.freq,v.name,v.code)
getindex(a::FreqArray,I::Union{itype,Int}) = FreqVector(view(a.data,I,Colon()),a.freq,a.name,a.code)

getindex(v::FreqVector,I::StepRange) = FreqVector(view(v.data,I),v.freq/I.step,v.name,v.code)
getindex(a::FreqArray,I::StepRange) = FreqVector(view(a.data,I,Colon()),a.freq/I.step,a.name,a.code)

getindex(v::FreqVector,I::Int) = v.data[I]

"""Convert `s` seconds to data index"""
stoi(a::FreqData,s::T) where T<:Real = round(Int,s*a.freq)
stoi(a::FreqData,s::AbstractArray{T,1}) where T<:Real = [stoi(a,ss) for ss in s]
"""Convert data index `i` to seconds"""
itos(a::FreqData,i::Int) = i/a.freq
itos(a::FreqData,i::AbstractArray{Int,1}) = [itos(a,ii) for ii in i]

getindex(a::FreqData,f::Union{T,AbstractArray{T,1}}) where T<:AbstractFloat = getindex(a,stoi(a,f))

"""Extract a specific channel from `FreqArray` and returns a single `FreqVector`"""
channel(a::FreqArray,c::Int,I::itype) = FreqVector(view(a.data,I,c),a.freq,a.names[c],a.code)
channel(a::FreqArray,c::Int) = channel(a,c,Colon())
channel(a::FreqArray,c::String,I::itype) = channel(a,findfirst(isequal(c),a.names),I)
channel(a::FreqArray,c::String) = channel(a,c,Colon())

"""Extract a set of channels from `FreqArray` and returns another `FreqArray`"""
channel(a::FreqArray,c::itype,I::itype) = FreqArray(view(a.data,I,c),a.freq,a.names[c],a.code)
channel(a::FreqArray,c::itype) = channel(a,c,Colon())
channel(a::FreqArray,c::Vector{String}) = channel(a,[findfirst(isequal(cc),a.names) for cc in c])

"""
    times(a::FreqVector)

Create a series of times (in seconds) the same length as data (useful as X-axis for plotting)"""
times(a::FreqData) = [itos(a,i) for i in 1:length(a)]
