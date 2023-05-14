extends Node

func generate_seed() -> int:
	var rng = RandomNumberGenerator.new()
	rng.randomize()
	return rng.randi()

func generate_hash() -> String:
	randomize()#Create one first random number hashed
	var fisrt_part = str(randi()).sha256_text()
	randomize()#Create one second random number hashed
	var last_part = str(randi() % 1000).sha256_text()
	randomize()#Create one second random number hashed
	var third_part = str(randi() % 100).sha256_text()
	var result = (fisrt_part + last_part + third_part).sha256_text()
	
	return result

func get_time_msecs() -> int:
	return ceil((Time.get_unix_time_from_system() - int(Time.get_unix_time_from_system())) * 1000.0)
