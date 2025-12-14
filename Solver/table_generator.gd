class_name TableGenerator
extends RefCounted
## Utility class for saving and loading lookup tables.
##
## Uses a binary format that supports [int] and [String] keys.
## Format: [size: u32] followed by entries of [type_marker: u8, key: variant, value: u32][br][br]
##
## Type markers:[br]
## - 0: [int] key (stored as u32)[br]
## - 1: [String] key (stored as Pascal string)


## Saves a lookup table to a binary file.[br][br]
##
## [param table]: [Dictionary] mapping coordinates to depths ([int] to [int] [u]or[/u] [String] to [int]).[br]
## [param filepath]: Path where the table will be saved (e.g. "res://Solver/Tables/phase0.dat").
func save_table(table: Dictionary[Variant, int], filepath: String) -> void:
	var file := FileAccess.open(filepath, FileAccess.WRITE)
	if file == null:
		push_error("Failed to open file for writing: " + filepath)
		return

	# write table size
	file.store_32(table.size())

	for key: Variant in table.keys():
		if key is String:
			file.store_8(1) # type marker: String
			file.store_pascal_string(key) # value
		else: # key is int
			file.store_8(0) # type marker: int
			file.store_32(key) # value

		file.store_32(table[key]) # depth

	file.close()

	print("Saved table to " + filepath + "\n")


## Loads a lookup table from a binary file.[br][br]
##
## [param filepath]: Path where the table is saved (e.g. "res://Solver/Tables/phase0.dat").
func load_table(filepath: String) -> Dictionary[Variant, int]:
	var file := FileAccess.open(filepath, FileAccess.READ)
	if file == null:
		push_error("Failed to open file for reading: " + filepath)
		return { }

	var table: Dictionary[Variant, int] = { }

	# read table size
	var size := file.get_32()

	for i in range(size):
		var type_marker := file.get_8()
		var key: Variant

		if type_marker == 1:
			key = file.get_pascal_string() # String key
		else:
			key = file.get_32() # int key

		var value := file.get_32() # depth
		table[key] = value

	file.close()

	print("Loaded table from: %s (size: %d)" % [filepath, table.size()])
	return table
