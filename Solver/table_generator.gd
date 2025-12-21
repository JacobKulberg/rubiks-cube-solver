class_name TableGenerator
extends RefCounted
## Utility class for saving and loading lookup tables.
##
## Uses a simple binary format with [int] keys and [int] values.[br]
## Format: [size: u32] followed by [key: u64, value: u32] pairs


## Saves a lookup table to a binary file.[br][br]
##
## [param table]: [Dictionary] mapping coordinates to depths ([int] to [int]).[br]
## [param filepath]: Path where the table will be saved (e.g. "res://Solver/Tables/phase0.dat").
func save_table(table: Dictionary, filepath: String) -> void:
	var file := FileAccess.open(filepath, FileAccess.WRITE)
	if file == null:
		push_error("Failed to open file for writing: " + filepath)
		return

	# write table size
	file.store_32(table.size())

	for key: int in table.keys():
		file.store_64(key) # coordinate
		file.store_32(table[key]) # depth

	file.close()

	print("Saved table to " + filepath + "\n")


## Loads a lookup table from a binary file.[br][br]
##
## [param filepath]: Path where the table is saved (e.g. "res://Solver/Tables/phase0.dat").
func load_table(filepath: String) -> Dictionary:
	var file := FileAccess.open(filepath, FileAccess.READ)
	if file == null:
		push_error("Failed to open file for reading: " + filepath)
		return { }

	var table: Dictionary = { }

	# read table size
	var size := file.get_32()

	for i in range(size):
		var key := file.get_64() # coordinate
		var value := file.get_32() # depth
		table[key] = value

	file.close()

	print("Loaded table from: %s (size: %d)" % [filepath, table.size()])
	return table
