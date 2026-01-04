class_name FourListTableGenerator
extends RefCounted

const TURNS: Array[String] = [
	"R",
	"R'",
	"R2",
	"L",
	"L'",
	"L2",
	"U",
	"U'",
	"U2",
	"D",
	"D'",
	"D2",
	"F",
	"F'",
	"F2",
	"B",
	"B'",
	"B2",
]
const MAX_DEPTH := 5
const OUT_FILE := "res://Solver/FourList/Tables/L_table.dat"


static func load_L_table() -> Array[String]:
	var file := FileAccess.open(OUT_FILE, FileAccess.READ)
	if file == null:
		push_error("Failed to open file for reading: " + OUT_FILE)
		return []

	var count := file.get_32()
	var result: Array[String] = []
	result.resize(count)

	for i in range(count):
		result[i] = file.get_pascal_string()

	file.close()
	return result


static func save_L_table() -> void:
	var file := FileAccess.open(OUT_FILE, FileAccess.WRITE)
	if file == null:
		push_error("Failed to open file for writing: " + OUT_FILE)
		return

	# placeholder for count
	file.store_32(0)

	var sequence: Array[String] = []
	var count := 0
	count = _generate_recursive(file, sequence, "", MAX_DEPTH, count)

	# patch count at file start
	file.seek(0)
	file.store_32(count)
	file.close()

	print("Wrote %d sequences to %s" % [count, OUT_FILE])


static func _generate_recursive(file: FileAccess, sequence: Array[String], last_face: String, depth_remaining: int, count: int) -> int:
	if depth_remaining <= 0:
		return count

	for turn in TURNS:
		var face := turn[0]
		if not last_face.is_empty() and face == last_face:
			continue

		sequence.push_back(turn)
		file.store_pascal_string(" ".join(sequence))
		count += 1

		count = _generate_recursive(file, sequence, face, depth_remaining - 1, count)
		sequence.pop_back()

	return count
