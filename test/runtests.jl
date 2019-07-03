using MNE

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

        @assert stoi(data_vec,0) == 0
        @assert stoi(data_vec_i,0) == 0
        @assert abs(stoi(data_vec,data_dur) - data_num) <= 1
        @assert abs(stoi(data_vec_i,data_dur) - data_num_i) <= 1

        @assert itos(data_arr,0) == 0
        @assert itos(data_arr_i,0) == 0
        @assert abs(itos(data_arr,data_num) - data_dur) <= 1/data_freq
        @assert abs(itos(data_arr_i,data_num_i) - data_dur) <= 1/data_freq_i

        @assert itos(data_vec,0) == 0
        @assert itos(data_vec_i,0) == 0
        @assert abs(itos(data_vec,data_num) - data_dur) <= 1/data_freq
        @assert abs(itos(data_vec_i,data_num_i) - data_dur) <= 1/data_freq_i

        @assert itos(data_arr,0) == 0
        @assert itos(data_arr_i,0) == 0
        @assert abs(itos(data_arr,data_num) - data_dur) <= 1/data_freq
        @assert abs(itos(data_arr_i,data_num_i) - data_dur) <= 1/data_freq_i

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

            @assert data_vec[1/data_freq] == data_vec[1]
            @assert data_vec_i[1/data_freq_i] == data_vec_i[1]
            @assert data_arr[1/data_freq] == data_arr[1]
            @assert data_arr_i[1/data_freq_i] == data_arr_i[1]
            @assert data_vec[data_num/data_freq] == data_vec[end]
            @assert data_vec_i[data_num_i/data_freq_i] == data_vec_i[end]
            @assert data_arr[data_num/data_freq] == data_arr[end]
            @assert data_arr_i[data_num_i/data_freq_i] == data_arr_i[end]
        end
    end
end

#=


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
