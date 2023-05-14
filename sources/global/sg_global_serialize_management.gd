extends Node

# Compress method's # 0 - FastLZ # 1 - DEFLATE # 2 - Zstandard # 3 - Gzip
var packed_compress_method = 2

#Serialize packed
func serialize(data):
	var packed_array = PackedByteArray()
	
	packed_array.append_array(var_to_bytes(data))
	return [packed_array.compress(packed_compress_method), packed_array.size()]

#Deserialize packed
func deserialize(packed : PackedByteArray, packed_size):
	return bytes_to_var(packed.decompress(packed_size, packed_compress_method))
