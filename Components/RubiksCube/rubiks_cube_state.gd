class_name RubiksCubeState
extends RefCounted
## Represents the logical state of the Rubik's Cube.
##
## The current implementation uses [b]cubelet-based representation[/b]:[br][br]
##
## - [b]Permutation arrays[/b] map from [i]positions → cubelet[/i][br]
## - [b]Orientation arrays[/b] store orientation [i]per cubelet[/i], not per position[br][br]
##
## This means:[br]
## - Cubelets move when the cube is turned[br]
## - Orientation values move with the cubelet[br]
## - Face turns only add orientation deltas; orientation is never reinterpreted[br][br]
##
## [b]Coordinate system:[/b][br]
## - White on U (Y+)[br]
## - Green on F (Z+)[br]
## - Red   on R (X+)[br][br]
##
## Corner positions (indices [code]0-7[/code]):
## [codeblock]
## 0 = UBL, 1 = DFL, 2 = DBR, 3 = UFR,
## 4 = UFL, 5 = DBL, 6 = DFR, 7 = UBR
## [/codeblock][br]
##
## Edge positions (indices [code]0-11[/code]):
## [codeblock]
## 0 = UL, 1 = DL,  2 = DR,  3 = UR,
## 4 = BL, 5 = FL,  6 = FR,  7 = BR,
## 8 = UF, 9 = DF, 10 = DB, 11 = UB
## [/codeblock]

enum CORNER {
	UBL,
	DFL,
	DBR,
	UFR,
	UFL,
	DBL,
	DFR,
	UBR,
}
enum EDGE {
	UL,
	DL,
	DR,
	UR,
	BL,
	FL,
	FR,
	BR,
	UF,
	DF,
	DB,
	UB,
}

## Maps each [b]corner position[/b] to the [b]corner cubelet[/b] currently occupying it.[br][br]
##
## Index: position ([code]0-7[/code])[br]
## Value: cubelet ID (see [enum CORNER])
var corner_permutation: Array[int] = [0, 1, 2, 3, 4, 5, 6, 7]
## Stores the orientation of each corner cubelet.[br][br]
##
## Index: cubelet ID (see [enum CORNER])[br]
## Value:[br]
## - 0 = cubelet is in its reference orientation[br]
## - 1, 2 = cubelet is twisted relative to its reference orientation[br][br]
##
## Corner orientation is defined modulo 3.
var corner_orientation: Array[int] = [0, 0, 0, 0, 0, 0, 0, 0]
## Human-readable names for corner cubelets.
var corner_dict: Dictionary = {
	CORNER.UBL: "UBL",
	CORNER.UBR: "UBR",
	CORNER.UFR: "UFR",
	CORNER.UFL: "UFL",
	CORNER.DBL: "DBL",
	CORNER.DBR: "DBR",
	CORNER.DFR: "DFR",
	CORNER.DFL: "DFL",
}
## Maps each [b]edge position[/b] to the [b]edge cubelet[/b] currently occupying it.[br][br]
##
## Index: position ([code]0-11[/code])[br]
## Value: cubelet ID (see [enum EDGE])
var edge_permutation: Array[int] = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11]
## Stores the orientation of each edge cubelet.[br][br]
##
## Index: cubelet ID (see [enum EDGE])[br]
## Value:[br]
## - 0 = cubelet is unflipped[br]
## - 1 = cubelet is flipped[br][br]
##
## Edge orientation is defined modulo 2.
var edge_orientation: Array[int] = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
## Human-readable names for edge cubelets.
var edge_dict: Dictionary = {
	EDGE.UB: "UB",
	EDGE.UR: "UR",
	EDGE.UF: "UF",
	EDGE.UL: "UL",
	EDGE.BL: "BL",
	EDGE.BR: "BR",
	EDGE.FR: "FR",
	EDGE.FL: "FL",
	EDGE.DB: "DB",
	EDGE.DR: "DR",
	EDGE.DF: "DF",
	EDGE.DL: "DL",
}


## Applies a single face turn to the cube state.[br][br]
##
## The update happens in two steps:[br]
## 1. Cycle the affected cubelets (permutation update)[br]
## 2. Apply orientation deltas to the affected cubelets[br][br]
##
## Orientation is always updated via the permutation arrays,
## ensuring that orientation is stored [b]per cubelet[/b], not per position
func apply_turn(face: String) -> void:
	match face:
		"R":
			var corner_indices: Array[int] = [CORNER.DBR, CORNER.DFR, CORNER.UFR, CORNER.UBR]
			var edge_indices: Array[int] = [EDGE.UR, EDGE.BR, EDGE.DR, EDGE.FR]

			_cycle_pieces(corner_indices, edge_indices)
		"U":
			var corner_indices: Array[int] = [CORNER.UBL, CORNER.UBR, CORNER.UFR, CORNER.UFL]
			var edge_indices: Array[int] = [EDGE.UB, EDGE.UR, EDGE.UF, EDGE.UL]

			_cycle_pieces(corner_indices, edge_indices)

			_orient_corners(corner_indices, [2, 1, 2, 1])
			_orient_edges(edge_indices)
		"L":
			var corner_indices: Array[int] = [CORNER.UBL, CORNER.UFL, CORNER.DFL, CORNER.DBL]
			var edge_indices: Array[int] = [EDGE.FL, EDGE.DL, EDGE.BL, EDGE.UL]

			_cycle_pieces(corner_indices, edge_indices)
		"D":
			var corner_indices: Array[int] = [CORNER.DFL, CORNER.DFR, CORNER.DBR, CORNER.DBL]
			var edge_indices: Array[int] = [EDGE.DL, EDGE.DF, EDGE.DR, EDGE.DB]

			_cycle_pieces(corner_indices, edge_indices)

			_orient_corners(corner_indices, [2, 1, 2, 1])
			_orient_edges(edge_indices)
		"F":
			var corner_indices: Array[int] = [CORNER.UFL, CORNER.UFR, CORNER.DFR, CORNER.DFL]
			var edge_indices: Array[int] = [EDGE.UF, EDGE.FR, EDGE.DF, EDGE.FL]

			_cycle_pieces(corner_indices, edge_indices)

			_orient_corners(corner_indices, [2, 1, 2, 1])
		"B":
			var corner_indices: Array[int] = [CORNER.DBL, CORNER.DBR, CORNER.UBR, CORNER.UBL]
			var edge_indices: Array[int] = [EDGE.BL, EDGE.DB, EDGE.BR, EDGE.UB]

			_cycle_pieces(corner_indices, edge_indices)

			_orient_corners(corner_indices, [2, 1, 2, 1])


## Returns a deep copy of this cube state.[br][br]
##
## [method Array.duplicate] is valid here since [member corner_permutation],
## [member corner_orientation], [member edge_permutation], and [member edge_orientation]
## all store primitive [int] types. So, [method Array.duplicate_deep] would achieve
## the same affect and may be slower.
func copy() -> RubiksCubeState:
	var state_copy := RubiksCubeState.new()
	state_copy.corner_permutation = corner_permutation.duplicate()
	state_copy.corner_orientation = corner_orientation.duplicate()
	state_copy.edge_permutation = edge_permutation.duplicate()
	state_copy.edge_orientation = edge_orientation.duplicate()
	return state_copy


## Returns a hash for all corner/edge permutations/orientations.
## This is used for efficient lookup tables.
func to_hash() -> int:
	return hash([corner_permutation, corner_orientation, edge_permutation, edge_orientation])


## Prints a formatted table of the cube state.[br][br]
##
## [b][u]IMPORTANT:[/u][/b][br]
## This prints [b]permutation by [u]position[/u][/b], but [b]orientation by [u]cubelet[/u][/b].[br][br]
##
## - The "Position" row labels cube slots (fixed locations on the cube)[br]
## - The "Permutation" row shows which cubelet occupies each position[br]
## - The "Orientation" row lists orientation values indexed by cubelet ID (see [enum CORNER] and [enum EDGE]), [b]not[/b] by position.[br][br]
##
## When [param display_acronyms] is [code]true[/code], cubelet IDs are printed as labels
## (e.g. UBL, BR) instead of numeric indices.
func print(display_acronyms: bool = false) -> void:
	var corner_widths: Array[int] = []
	for i in range(8):
		var permutation_width := str(corner_permutation[i]).length()
		var orientation_width := str(corner_orientation[i]).length()

		if display_acronyms:
			permutation_width = corner_dict[corner_permutation[i]].length()
			orientation_width = corner_dict[corner_orientation[i]].length()

		var max_width: Variant = max(permutation_width, orientation_width)
		corner_widths.push_back(max_width)

	var edge_widths: Array[int] = []
	for i in range(12):
		var header_width := str(i).length()
		var permutation_width := str(edge_permutation[i]).length()
		var orientation_width := str(edge_orientation[i]).length()

		if display_acronyms:
			permutation_width = edge_dict[edge_permutation[i]].length()
			orientation_width = edge_dict[edge_orientation[i]].length()

		var max_width: Variant = max(header_width, permutation_width, orientation_width)
		edge_widths.push_back(max_width)

	var corner_header := " "
	for i in range(8):
		var value := str(i)
		if display_acronyms:
			value = corner_dict[i]
		corner_header += value.lpad(corner_widths[i]) + " "

	var edge_header := " "
	for i in range(12):
		var value := str(i)
		if display_acronyms:
			value = edge_dict[i]
		edge_header += value.lpad(edge_widths[i]) + " "

	var corner_total := corner_header.length()
	var edge_total := edge_header.length()

	print("+-------------+" + "-".repeat(corner_total) + "+" + "-".repeat(edge_total) + "+")
	print("|             | Corner" + " ".repeat(corner_total - 7) + "| Edge" + " ".repeat(edge_total - 5) + "|")
	print("|    Position |" + corner_header + "|" + edge_header + "|")
	print("+-------------+" + "-".repeat(corner_total) + "+" + "-".repeat(edge_total) + "+")

	var permutation_str := "| Permutation | "
	for i in range(8):
		var value := str(corner_permutation[i])
		if display_acronyms:
			value = corner_dict[corner_permutation[i]]
		permutation_str += value.lpad(corner_widths[i]) + " "
	permutation_str += "| "
	for i in range(12):
		var value := str(edge_permutation[i])
		if display_acronyms:
			value = edge_dict[edge_permutation[i]]
		permutation_str += value.lpad(edge_widths[i]) + " "
	permutation_str += "|"

	print(permutation_str)

	var orientation_str := "| Orientation | "
	for i in range(8):
		orientation_str += str(corner_orientation[i]).lpad(corner_widths[i]) + " "
	orientation_str += "| "
	for i in range(12):
		orientation_str += str(edge_orientation[i]).lpad(edge_widths[i]) + " "
	orientation_str += "|"

	print(orientation_str)

	print("+-------------+" + "-".repeat(corner_total) + "+" + "-".repeat(edge_total) + "+")
	print()


## Cycles the specified corner and edge positions.[br][br]
##
## Only permutations is updated here. Orientation is [b]not[/b] cycled becayse orientation belongs to cubelets.
func _cycle_pieces(corner_indices: Array[int], edge_indices: Array[int]) -> void:
	var temp := corner_permutation[corner_indices[0]]
	corner_permutation[corner_indices[0]] = corner_permutation[corner_indices[3]]
	corner_permutation[corner_indices[3]] = corner_permutation[corner_indices[2]]
	corner_permutation[corner_indices[2]] = corner_permutation[corner_indices[1]]
	corner_permutation[corner_indices[1]] = temp

	temp = edge_permutation[edge_indices[0]]
	edge_permutation[edge_indices[0]] = edge_permutation[edge_indices[3]]
	edge_permutation[edge_indices[3]] = edge_permutation[edge_indices[2]]
	edge_permutation[edge_indices[2]] = edge_permutation[edge_indices[1]]
	edge_permutation[edge_indices[1]] = temp


## Applies orientation deltas to the specified corner positions.[br][br]
##
## Orientation is applied to the [b]cubelets currently in those positions.[/b]
func _orient_corners(indices: Array[int], deltas: Array[int]) -> void:
	for i in range(indices.size()):
		corner_orientation[corner_permutation[indices[i]]] = (corner_orientation[corner_permutation[indices[i]]] + deltas[i]) % 3


## Flips the edge cubelets currently occupying the specified positions.
func _orient_edges(indices: Array[int]) -> void:
	for i in indices:
		edge_orientation[edge_permutation[i]] = (edge_orientation[edge_permutation[i]] + 1) % 2
