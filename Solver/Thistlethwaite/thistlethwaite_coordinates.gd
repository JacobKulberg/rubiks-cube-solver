class_name ThistlethwaiteCoordinates
extends RefCounted
## Coordinate encoding functions for Thistlethwaite's algorithm.[br][br]
##
## Each function maps a cube state to a numeric coordinate that uniquely identifies
## a subset of the cube's configurations. These coordinates are used as keys in
## lookup tables generated via BFS.

## The 18 turns allowed in phase G0
const G0_TURNS: Array[String] = ["R", "R'", "R2", "L", "L'", "L2", "U", "U'", "U2", "D", "D'", "D2", "F", "F'", "F2", "B", "B'", "B2"]
## The 14 turns allowed in phase G1
const G1_TURNS: Array[String] = ["R", "R'", "R2", "L", "L'", "L2", "U2", "D2", "F", "F'", "F2", "B", "B'", "B2"]
## The 10 turns allowed in phase G2
const G2_TURNS: Array[String] = ["R", "R'", "R2", "L", "L'", "L2", "U2", "D2", "F2", "B2"]
## The 6 turns allowed in phase G3
const G3_TURNS: Array[String] = ["R2", "L2", "U2", "D2", "F2", "B2"]


## Returns the G0 coordinate composed of the edge orientation coordinate.
static func get_phase0_coord(state: RubiksCubeState) -> int:
	var edge_coord := _get_edge_orientation_coord(state)
	return edge_coord


## Returns the G1 coordinate composed of the corner orientation and M-slice position coordinates.
static func get_phase1_coord(state: RubiksCubeState) -> int:
	var corner_coord := _get_corner_orientation_coord(state)
	var m_slice_coord := _get_m_slice_coord(state)
	return corner_coord * 495 + m_slice_coord


## Returns the G2 coordinate composed of the E/S-slice position, corner tetrad, edge parity, and tetrad twist coordinates.
static func get_phase2_coord(state: RubiksCubeState) -> int:
	var es_slice_coord := _get_es_slice_coord(state)
	var corner_tetrad_coord := _get_corner_tetrad_coord(state)
	var tetrad_twist_coord := _get_tetrad_twist_coord(state) # edge parity built in
	return (es_slice_coord * 70 + corner_tetrad_coord) * 6 + tetrad_twist_coord


## Returns the G3 coordinate composed of the corner and edge permutation coordinates.
static func get_phase3_coord(state: RubiksCubeState) -> int:
	var corner_perm_coord := _get_corner_perm_coord(state)
	var edge_perm_coord := _get_edge_perm_coord(state)
	return edge_perm_coord * 96 + corner_perm_coord


## Returns the edge orientation coordinate for phase G0 (0-2047).[br][br]
##
## Encodes the orientation of the first 11 edges as a binary number.[br]
## The 12th edge orientation is determined by parity and is not stored.[br][br]
##
## Used to reduce G0 to G1.
static func _get_edge_orientation_coord(state: RubiksCubeState) -> int:
	var sum := 0
	for i in range(11):
		sum += state.edge_orientations[state.edge_permutations[i]] * (1 << i)
	return sum


## Returns the corner orientation coordinate for phase G1 (0-2186).[br][br]
##
## Encodes the orientation of the first 7 corners as a base-3 number.[br]
## The 8th corner orientation is determined by mod-3 parity and is not stored.[br][br]
##
## Used to reduce G1 to G2.
static func _get_corner_orientation_coord(state: RubiksCubeState) -> int:
	var sum := 0
	for i in range(7):
		sum += state.corner_orientations[state.corner_permutations[i]] * (3 ** i)
	return sum


## Returns the M-slice position coordinate for phase G1 (0-494).[br][br]
##
## Encodes which 4 of the 12 edge positions contain M-slice edges (UF, UB, DF, DB)[br][br]
##
## Used to reduce G1 to G2.
static func _get_m_slice_coord(state: RubiksCubeState) -> int:
	var m_edges := [state.EDGE.UF, state.EDGE.UB, state.EDGE.DF, state.EDGE.DB]
	var positions_with_m_edges: Array[int] = []

	# find which positions contain M-slice edges
	for i in range(12):
		if state.edge_permutations[i] in m_edges:
			positions_with_m_edges.push_back(i)

	positions_with_m_edges.sort()
	return _combinatorial_index(positions_with_m_edges, 12, 4)


## Returns the E/S-slice position coordinate for phase G2 (0-69).[br][br]
##
## Encodes which 4 of the 8 non-M-slice edge positions contain E-slice edges (FL, FR, BL, BR)[br][br]
##
## Used to reduce G2 to G3.
static func _get_es_slice_coord(state: RubiksCubeState) -> int:
	var e_edges := [state.EDGE.FL, state.EDGE.FR, state.EDGE.BL, state.EDGE.BR]
	var m_edges := [state.EDGE.UF, state.EDGE.UB, state.EDGE.DF, state.EDGE.DB]

	var positions_with_e_edges: Array[int] = []
	var compressed_index := 0

	for i in range(12):
		var edge := state.edge_permutations[i]

		# skip M-slice edges
		if edge in m_edges:
			continue

		# remaining 8 positions are E or S slice
		if edge in e_edges:
			positions_with_e_edges.push_back(compressed_index)

		compressed_index += 1

	positions_with_e_edges.sort()
	return _combinatorial_index(positions_with_e_edges, 8, 4)


## Returns the corner tetrad coordinate for phase G2 (0-69).[br][br]
##
## Encodes which 4 of the 8 corner positions contain tetrad A corners (UFR, UBL, DBR, DFL)[br][br]
##
## Used to reduce G2 to G3.
static func _get_corner_tetrad_coord(state: RubiksCubeState) -> int:
	var tetrad_a := [
		state.CORNER.UFR,
		state.CORNER.UBL,
		state.CORNER.DBR,
		state.CORNER.DFL,
	]

	var positions_with_a: Array[int] = []

	# find which corner positions contain tetrad A corners
	for i in range(8):
		if state.corner_permutations[i] in tetrad_a:
			positions_with_a.push_back(i)

	positions_with_a.sort()
	return _combinatorial_index(positions_with_a, 8, 4)


## Returns the tetrad twists coordinate for phase G2 (0-5).[br][br]
##
## Encodes the combined twist and parity of the corner tetrads.[br][br]
##
## Used to reduce G2 to G3.
static func _get_tetrad_twist_coord(state: RubiksCubeState) -> int:
	# credit to Jaap Scherphuis: https://puzzling.stackexchange.com/a/109429

	# define a consistent tetrad split and a stable mapping to indices 0..7,
	# where indices 0..3 are tetrad A and 4..7 are tetrad B
	var tetrad_a := [
		state.CORNER.UFR,
		state.CORNER.UBL,
		state.CORNER.DBR,
		state.CORNER.DFL,
	]
	var tetrad_b := [
		state.CORNER.UBR,
		state.CORNER.UFL,
		state.CORNER.DFR,
		state.CORNER.DBL,
	]

	var corner_to_tetrad_index := { }
	for i in range(4):
		corner_to_tetrad_index[tetrad_a[i]] = i # 0..3
		corner_to_tetrad_index[tetrad_b[i]] = 4 + i # 4..7

	# map corners to their tetrad-relative positions
	var combined_perm := PackedInt32Array()
	combined_perm.resize(8)

	var tetrad_b_perm := PackedInt32Array()
	tetrad_b_perm.resize(4)

	var next_a := 0
	var next_b := 0

	# iterate corner positions 0..7, using the same order as state.corner_permutations
	for pos in range(8):
		var corner := state.corner_permutations[pos]
		var tetrad_index: int = corner_to_tetrad_index[corner] # 0..7

		if (tetrad_index & 4) != 0:
			# corner belongs to tetrad B
			combined_perm[tetrad_index] = next_b
			next_b += 1
		else:
			# corner belongs to tetrad A
			combined_perm[next_a] = tetrad_index
			next_a += 1

	# find permutation of tetrad B after "solving" tetrad A
	for i in range(4):
		tetrad_b_perm[i] = combined_perm[4 + combined_perm[i]]

	# fix one piece of tetrad B (so only relative arrangement matters)
	for i in range(3, 0, -1):
		tetrad_b_perm[i] ^= tetrad_b_perm[0]

	# encode (twist * 2 + parity) into 0..5
	var twist_plus_parity := tetrad_b_perm[1] * 2 - 2
	if tetrad_b_perm[3] < tetrad_b_perm[2]:
		twist_plus_parity += 1

	return twist_plus_parity


## Returns the corner permutation coordinate for phase G3 (0-95).[br][br]
##
## Encodes the permutation of the 8 corners using the factorial number system.[br][br]
##
## Used to reduce G3 to G4.
static func _get_corner_perm_coord(state: RubiksCubeState) -> int:
	var perm := state.corner_permutations
	var index := 0
	var used := []

	# track which corners have already been used
	for i in range(8):
		used.push_back(false)

	# factorial number system
	# total states = 8! = 40320
	# unique corner permutations in G3 = 96
	for i in range(8):
		var smaller_unused := 0
		for j in range(perm[i]):
			if not used[j]:
				smaller_unused += 1

		index += smaller_unused * _factorial(7 - i)
		used[perm[i]] = true

	return index


## Returns the edge permutation coordinate for phase G3 (0-6911).[br][br]
##
## Encodes the permutation of the 12 edges using the factorial number system.[br][br]
##
## Used to reduce G3 to G4.
static func _get_edge_perm_coord(state: RubiksCubeState) -> int:
	var perm := state.edge_permutations
	var index := 0
	var used := []

	# track which edges have already been used
	for i in range(12):
		used.push_back(false)

	# factorial number system
	# total states = 12! = 479001600
	# unique edge permutations in G3 = 6912
	for i in range(12):
		var smaller_unused := 0
		for j in range(perm[i]):
			if not used[j]:
				smaller_unused += 1

		index += smaller_unused * _factorial(11 - i)
		used[perm[i]] = true

	return index


## Converts a sorted array of selected positions to a combinatorial index.[br][br]
##
## Uses binomial coefficients to encode which [param k] positions out of [param n] are selected.[br]
## [param positions]: Sorted array of selected positions.[br]
## [param n]: Total number of positions.[br]
## [param k]: Number of positions to select.
static func _combinatorial_index(positions: Array[int], n: int, k: int) -> int:
	var index := 0
	for i in range(k):
		var start := 0 if i == 0 else positions[i - 1] + 1
		for j in range(start, positions[i]):
			index += _choose(n - j - 1, k - i - 1)
	return index


static func _choose(n: int, r: int) -> int:
	if r < 0 or r > n:
		return 0
	return _factorial(n) / (_factorial(r) * _factorial(n - r))


static func _factorial(n: int) -> int:
	var prod := 1
	for i in range(2, n + 1):
		prod *= i
	return prod
