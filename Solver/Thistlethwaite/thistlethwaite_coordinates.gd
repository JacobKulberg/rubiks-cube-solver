class_name ThistlethwaiteCoordinates
extends RefCounted
## Coordinate encoding functions for Thistlethwaite's algorithm.[br][br]
##
## Each function maps a cube state to a numeric coordinate that uniquely identifies
## a subset of the cube's configurations. These coordinates are used as keys in
## lookup tables generated via BFS.


## Returns the edge orientation coordinate for phase G0 (0-2047).[br][br]
##
## Encodes the orientation of the first 11 edges as a binary number.[br]
## The 12th edge orientation is determined by parity and is not stored.[br][br]
##
## Used to reduce G0 to G1.
static func get_edge_orientation_coord(state: RubiksCubeState) -> int:
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
static func get_corner_orientation_coord(state: RubiksCubeState) -> int:
	var sum := 0
	for i in range(7):
		sum += state.corner_orientations[state.corner_permutations[i]] * (3 ** i)
	return sum


## Returns the E-slice position coordinate for phase G1 (0-494).[br][br]
##
## Encodes which 4 of the 12 edge positions contain E-slice edges (FL, FR, BL, BR)[br][br]
##
## Used to reduce G1 to G2.
static func get_e_slice_coord(state: RubiksCubeState) -> int:
	var e_edges := [state.EDGE.FL, state.EDGE.FR, state.EDGE.BL, state.EDGE.BR]
	var positions_with_e_edges: Array[int] = []

	# find which positions contain E-slice edges
	for i in range(12):
		if state.edge_permutations[i] in e_edges:
			positions_with_e_edges.push_back(i)

	positions_with_e_edges.sort()
	var index := 0

	# convert to combinatorial index using binomial coefficients
	# encodes 4 edges from 12 = C(12, 4) = 495 combinations
	for i in range(4):
		var start := 0 if i == 0 else positions_with_e_edges[i - 1] + 1
		for j in range(start, positions_with_e_edges[i]):
			var n := 12 - j - 1
			var r := 4 - i - 1

			if r > n or r < 0:
				continue
			if r == 0 or r == n:
				index += 1
				continue

			r = min(r, n - r)

			# calculate binomial coefficient
			var binom := 1
			for b in range(r):
				binom = binom * (n - b) / (b + 1)
			index += binom

	return index
