using MNE,Dates

for data_type in [Int16,Int32,Int64,Float16,Float32,Float64,ComplexF16,ComplexF32,ComplexF64]
    for i=1:5
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

        data_vec = SampleVector(raw_vec,data_freq,name="test",code=:test)
        data_vec_i = SampleVector(raw_vec_i,data_freq_i,name="test",code=:test)
        data_arr = SampleArray(raw_arr,data_freq,names=["channel_$i" for i=1:data_nchann],code=:test)
        data_arr_i = SampleArray(raw_arr_i,data_freq_i,names=["channel_$i" for i=1:data_nchann],code=:test)

        @assert length(data_vec) == data_num
        @assert length(data_vec_i) == data_num_i
        @assert length(data_arr) == data_num
        @assert length(data_arr_i) == data_num_i

        @assert abs(duration(data_vec) - Millisecond(round(Int,1000*data_num/data_freq))) < Millisecond(10)
        @assert abs(duration(data_vec_i) - Millisecond(round(Int,1000*data_num_i/data_freq_i))) < Millisecond(10)
        @assert abs(duration(data_arr) - Millisecond(round(Int,1000*data_num/data_freq))) < Millisecond(10)
        @assert abs(duration(data_arr_i) - Millisecond(round(Int,1000*data_num_i/data_freq_i))) < Millisecond(10)

        for i=1:5
            ii = rand(1:data_num-2)
            iii = rand(ii+1:data_num)
            c = rand(1:data_nchann)
            @assert data_vec[ii] == raw_vec[ii]
            @assert data_vec[ii:iii].data == raw_vec[ii:iii]
            @assert data_arr[ii].data == raw_arr[ii:ii,:]
            @assert data_arr[ii:iii].data == raw_arr[ii:iii,:]
            @assert channel(data_arr,c,ii) == raw_arr[ii,c]
            @assert channel(data_arr,c,ii:iii).data == raw_arr[ii:iii,c]
            @assert channel(data_arr,c).data == raw_arr[:,c]
            @assert channel(data_arr,"channel_$c",ii) == raw_arr[ii,c]
            @assert channel(data_arr,"channel_$c",ii:iii).data == raw_arr[ii:iii,c]
            @assert channel(data_arr,"channel_$c").data == raw_arr[:,c]

            ii = rand(1:data_num_i-2)
            iii = rand(ii+1:data_num_i)
            @assert data_vec_i[ii] == raw_vec_i[ii]
            @assert data_vec_i[ii:iii].data == raw_vec_i[ii:iii]
            @assert data_arr_i[ii].data == raw_arr_i[ii:ii,:]
            @assert data_arr_i[ii:iii].data == raw_arr_i[ii:iii,:]
            @assert channel(data_arr_i,c,ii) == raw_arr_i[ii,c]
            @assert channel(data_arr_i,c,ii:iii).data == raw_arr_i[ii:iii,c]
            @assert channel(data_arr_i,c).data == raw_arr_i[:,c]
            @assert channel(data_arr_i,"channel_$c",ii) == raw_arr_i[ii,c]
            @assert channel(data_arr_i,"channel_$c",ii:iii).data == raw_arr_i[ii:iii,c]
            @assert channel(data_arr_i,"channel_$c").data == raw_arr_i[:,c]
        end
    end
end

#=


"""Extract a specific channel from `SampleArray` and returns a single `SampleVector`"""
channel(a::SampleArray,c::Int,I::itype) = SampleVector(view(a.data,I,c),a.freq,a.names[c],a.code)
channel(a::SampleArray,c::Int) = channel(a,c,Colon())
channel(a::SampleArray,c::String,I::itype) = channel(a,findfirst(isequal(c),a.names),I)
channel(a::SampleArray,c::String) = channel(a,c,Colon())

"""Extract a set of channels from `SampleArray` and returns another `SampleArray`"""
channel(a::SampleArray,c::itype,I::itype) = SampleArray(view(a.data,I,c),a.freq,a.names[c],a.code)
channel(a::SampleArray,c::itype) = channel(a,c,Colon())
channel(a::SampleArray,c::Vector{String}) = channel(a,[findfirst(isequal(cc),a.names) for cc in c])

"""
    times(a::SampleVector)

Create a series of times (in seconds) the same length as data (useful as X-axis for plotting)"""
times(a::SampleData) = [itos(a,i) for i in 1:length(a)]
=#
