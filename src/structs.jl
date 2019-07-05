# Basic structures

export SampleData,SampleArray,SampleVector

export duration
export stoi,itos
export channel,times

"""
    stoi(freq::Real,s::{Real,Second,Millisecond})

Convert `s` seconds to data index if data is sampled at `freq`"""
stoi(freq::K,s::T) where {K<:Real,T<:Real} = round(Int,s*freq)
stoi(freq::K,s::Second) where {K<:Real} = stoi(freq,Dates.value(s))
stoi(freq::K,s::Millisecond) where {K<:Real} = stoi(freq,Dates.value(s)/1000)
stoi(freq::K,s::AbstractArray{T,1}) where {K<:Real,T<:Union{Real,Second,Millisecond}} = [stoi(freq,ss) for ss in s]

"""
    itos(freq::Real,i::Integer)

Convert data index `i` to `Millisecond` if data is sampled at `freq`"""
itos(freq::K,i::T) where {K<:Real,T<:Integer} = Millisecond(round(Int,1000*i/freq))

"""
    itos(freq::Real,i::Integer,start::DateTime)
    itos(freq::Real,i::Vector{Integer},start::DateTime)

Convert data index `i` to `DateTime` if data is sampled at `freq` and started at `start`"""
itos(freq::K,i::T,start::DateTime) where {K<:Real,T<:Integer} = itos(freq,i) + start
itos(freq::K,i::AbstractArray{T,1},start::DateTime) where {K<:Real,T<:Integer} = [itos(freq,ii,start) for ii in i]

"""
    times(num::Int,freq::Real,start::DateTime=DateTime(0))

Create a DateTime vector the length `num`, assuming the data was collected at `freq` Hz and started at `start`"""
times(num::Int,freq::K,start::DateTime=DateTime(0)) where K<:Real = [itos(freq,i-1,start) for i in 1:num]


"Abstract type containing data sampled at a certain frequency, along with timing and metadata"
abstract type SampleData end

"""
    SampleVector(data::AbstractArray{Number,1}, [times::AbstractArray{{Number,DateTime},1},] freq::Float64; name::String="", code::Symbol=:unknown, start::DateTime=DateTime(0))

Struct of a single `Vector` of sampled data.
* `data`: raw data points
* `times`: corresponding times of raw data points, either as a `Number` or `DateTime`.

   If omitted, it will be calculated as `DateTime` using the given `freq` starting at `start`
* `freq`: data frequency
* `name`: arbitrary name as `String` (default = `""`)
* `code`: arbitrary data type as `Symbol` (default = `:unknown`)

Data can be accessed using []-notation
"""
mutable struct SampleVector{T,K} <: SampleData where {T<:Number,K<:Union{Number,DateTime}}
    data::AbstractArray{T,1}
    times::AbstractArray{K,1}
    freq::Float64
    name::String
    code::Symbol
end

SampleVector(data::AbstractArray{T,1},times::AbstractArray{K,1},freq::F;name::String="",code::Symbol=:unknown) where {T<:Number,K<:Union{Number,DateTime},F<:Real} = SampleVector(data,times,Float64(freq),name,code)
SampleVector(data::AbstractArray{T,1},freq::F;name::String="",code::Symbol=:unknown,start::DateTime=DateTime(0)) where {T<:Number,K<:Union{Number,DateTime},F<:Real} = SampleVector(data,times(length(data),freq,start),Float64(freq),name,code)

"""
    SampleArray(data::AbstractArray{Number,2}, [times::AbstractArray{{Number,DateTime},1},] freq::Float64; names::Vector{String}=[], code::Symbol=:unknown) where T<:Number

Struct of an `Array` frequency data. Makes the assumption `data` was collected at same frequency, synced in time.

* `data`: raw data points; arranged as (time, channels), column-major
* `freq`: data frequency
* `names`: `Vector{String}` of names (default = ["","" ...])
* `code`: arbitrary data type as `Symbol` (default = `:unknown`)

Data can be accessed by []-notation, or using the helper function `channel` to return a single `SampleVector`
"""
mutable struct SampleArray{T} <: SampleData where T<:Number
    data::AbstractArray{T,2}
    freq::Float64
    names::Vector{String}
    code::Symbol

    function SampleArray(data::AbstractArray{T,2},freq::K,names::Vector{String},code::Symbol) where {T<:Number,K<:Number}
        if size(data,2) != length(names)
            error("""Trying to create a SampleArray with data size $(size(data)) and names length $(length(names))
                    Data must be arranged in columns""")
        end
        return new{T}(data,Float64(freq),names,code)
    end
end

function SampleArray(data::AbstractArray{T,2},freq::K;names::Vector{String}=[],code::Symbol=:unknown) where {T<:Number,K<:Number}
    if length(names)==0
        names = ["" for i=1:size(data,2)]
    end
    SampleArray(data,freq,names,code)
end

function SampleArray(v::SampleVector{T}...) where T
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

    SampleArray(data,freqs[1],names,codes[1])
end

import Base.length,Base.getindex,Base.lastindex,Base.==

itype = Union{Vector{Int},UnitRange,Colon}

length(v::SampleVector) = length(v.data)
length(a::SampleArray) = size(a.data,1)

lastindex(v::SampleData) = length(v)
lastindex(a::SampleArray,d::Int) = size(a.data,d)

function ==(a::SampleVector,b::SampleVector)
    ((a.code != b.code) || (a.freq != b.freq) || (a.name != b.name)) && return false
    return a.data == b.data
end

function ==(a::SampleArray,b::SampleArray)
    ((a.code != b.code) || (a.freq != b.freq) || (a.names != b.names)) && return false
    return a.data == b.data
end

"""length of `SampleData` in seconds"""
duration(v::SampleData) = length(v)/v.freq

getindex(v::SampleVector,I::itype) = SampleVector(view(v.data,I),v.freq,v.name,v.code)
getindex(a::SampleArray,I::itype) = SampleArray(view(a.data,I,Colon()),a.freq,a.names,a.code)

getindex(v::SampleVector,I::StepRange) = SampleVector(view(v.data,I),v.freq/I.step,v.name,v.code)
getindex(a::SampleArray,I::StepRange) = SampleArray(view(a.data,I,Colon()),a.freq/I.step,a.names,a.code)

getindex(v::SampleVector,I::Int) = v.data[I]
getindex(a::SampleArray,I::Int) = SampleArray(view(a.data,I:I,Colon()),a.freq,a.names,a.code)


getindex(a::SampleData,f::Union{T,AbstractArray{T,1}}) where T<:AbstractFloat = getindex(a,stoi(a,f))

"""Extract a specific channel from `SampleArray` and returns a single `SampleVector`"""
channel(a::SampleArray,c::Int,I::itype) = SampleVector(view(a.data,I,c),a.freq,a.names[c],a.code)
channel(a::SampleArray,c::Int,I::Int) = a.data[I,c]
channel(a::SampleArray,c::Int) = channel(a,c,Colon())
channel(a::SampleArray,c::String,I::itype) = channel(a,findfirst(isequal(c),a.names),I)
channel(a::SampleArray,c::String,I::Int) = a.data[I,findfirst(isequal(c),a.names)]
channel(a::SampleArray,c::String) = channel(a,c,Colon())

"""Extract a set of channels from `SampleArray` and returns another `SampleArray`"""
channel(a::SampleArray,c::itype,I::itype) = SampleArray(view(a.data,I,c),a.freq,a.names[c],a.code)
channel(a::SampleArray,c::itype) = channel(a,c,Colon())
channel(a::SampleArray,c::Vector{String}) = channel(a,[findfirst(isequal(cc),a.names) for cc in c])
