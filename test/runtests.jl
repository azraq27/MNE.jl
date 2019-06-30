# Random data params
# `_i` variables have integer frequencies
data_freq = rand()*5000
data_freq_i = rand(1:5000)
data_dur = rand(1:0.01:120)
data_nchann = rand(1:200)
data_type = Float32

# Random data
data_num = round(Int,data_freq*data_dur,RoundDown)
data_num_i = round(Int,data_freq_i*data_dur,RoundDown)
raw_vec = rand(data_type,data_num)
raw_vec_i = rand(data_type,data_num_i)
raw_arr = rand(data_type,(data_num,data_nchann))
raw_arr_i = rand(data_type,(data_num_i,data_nchann))

data_vec = FreqVector(raw_vec,data_freq,name="test",code=:test)
data_vec_i = FreqVector(raw_vec_i,data_freq_i,name="test",code=:test)
data_arr = FreqArray(raw_arr,data_freq,names=["channel_$i" for i=1:data_nchann],code=:t)
data_arr_i = FreqArray(raw_arr_i,data_freq_i,names=["channel_$i" for i=1:data_nchann],code=:t)
