using MNE

for data_type in [Int16,Int32,Int64,Float16,Float32,Float64,ComplexF16,ComplexF32,ComplexF64]
    for i=1:10
        # Random data params
        # `_i` variables have integer frequencies
        data_freq = rand()*5000
        data_freq_i = rand(1:5000)
        data_dur = rand(1:0.01:120)
        data_nchann = rand(1:200)

        # Random data
        data_num = round(Int,data_freq*data_dur,RoundDown)
        data_num_i = round(Int,data_freq_i*data_dur,RoundDown)
        raw_vec = rand(data_type,data_num)
        raw_vec_i = rand(data_type,data_num_i)
        raw_arr = rand(data_type,(data_num,data_nchann))
        raw_arr_i = rand(data_type,(data_num_i,data_nchann))

        data_vec = FreqVector(raw_vec,data_freq,name="test",code=:test)
        data_vec_i = FreqVector(raw_vec_i,data_freq_i,name="test",code=:test)
        data_arr = FreqArray(raw_arr,data_freq,names=["channel_$i" for i=1:data_nchann],code=:test)
        data_arr_i = FreqArray(raw_arr_i,data_freq_i,names=["channel_$i" for i=1:data_nchann],code=:test)

        @assert length(data_vec) == data_num
        @assert length(data_vec_i) == data_num_i
        @assert length(data_arr) == data_num
        @assert length(data_arr_i) == data_num_i

        @assert abs(duration(data_vec) - data_num/data_freq) < 0.01
        @assert abs(duration(data_vec_i) - data_num_i/data_freq_i) < 0.01
        @assert abs(duration(data_arr) - data_num/data_freq) < 0.01
        @assert abs(duration(data_arr_i) - data_num_i/data_freq_i) < 0.01

        for i=1:20
            ii = rand(1:data_num-2)
            iii = rand(ii+1:data_num)
            c = rand(1:data_nchann)
            @assert data_vec[ii] == raw_vec[ii]
            @assert data_vec[ii:iii].data == raw_vec[ii:iii]
            @assert data_arr[ii].data = raw_arr[ii,:]
            @assert data_arr[ii:iii].data == raw_arr[ii:iii,:]

            ii = rand(1:data_num_i-2)
            iii = rand(ii+1:data_num_i)
            @assert data_vec_i[ii] == raw_vec_i[ii]
            @assert data_vec_i[ii:iii].data == raw_vec_i[ii:iii]
            @assert data_arr_i[ii].data = raw_arr_i[ii,:]
            @assert data_arr_i[ii:iii].data == raw_arr_i[ii:iii,:]
        end
    end
end
#=
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
=#
