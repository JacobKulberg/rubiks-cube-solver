class_name ThistlethwaiteSearch
extends RefCounted
## Greedy search algorithm for implementing Thistlethwaite's Algorithm.
##
## Uses precomputed lookup tables to find solutions by always choosing turns
## that reduce the distance to the goal state. This is a greedy depth-first
## approach, not guaranteed to find the shortest solution.


## Reduces G0 to G1 (orients all edges).[br][br]
##
## [param state]: Current cube state (this state will be modified)[br]
## [param table]: Precomputed G0 table (coordinates map to depth)[br][br]
##
## Returns a sequence of turns that orients all edges.[br]
## Uses all turns in the set {L, R, F, B, U, D}
func solve_phase0(state: RubiksCubeState, table: Dictionary[int, int]) -> Array[String]:
	var solution_turns: Array[String] = []
	var current_state := state.copy()

	while true:
		var current_coord := ThistlethwaiteCoordinates.get_edge_orientation_coord(current_state)
		var current_depth: int = table.get(current_coord, -1)

		# goal state reached
		if current_depth == 0:
			break

		# try all 18 turns, choose first that reduces depth
		for turn: String in ThistlethwaiteCoordinates.G0_TURNS:
			var test_state := current_state.copy()
			test_state.apply_turn(turn)
			var new_coord := ThistlethwaiteCoordinates.get_edge_orientation_coord(test_state)
			var new_depth: int = table.get(new_coord, -1)

			# greedy: take first move that reduces depth (local optimum)
			if new_depth == current_depth - 1:
				solution_turns.push_back(turn)
				current_state = test_state
				break

	return solution_turns


## Reduces G1 to G2 (orients all corners and correctly places E-slice).[br][br]
##
## [param state]: Current cube state (this state will be modified)[br]
## [param table]: Precomputed G1 table (coordinates map to depth)[br][br]
##
## Returns a sequence of turns that orients all corners and correctly places E-slice edges in the E-slice.[br]
## Uses all turns in the set {L, R, F, B, U2, D2}
func solve_phase1(state: RubiksCubeState, table: Dictionary[String, int]) -> Array[String]:
	var solution_turns: Array[String] = []
	var current_state := state.copy()

	while true:
		var current_coord := _get_phase1_coord(current_state)
		var current_depth: int = table.get(current_coord, -1)

		# goal state reached
		if current_depth == 0:
			break

		# try all 14 turns (to preserve edge orientation from G0), choose first that reduces depth
		for turn: String in ThistlethwaiteCoordinates.G1_TURNS:
			var test_state := current_state.copy()
			test_state.apply_turn(turn)
			var new_coord := _get_phase1_coord(test_state)
			var new_depth: int = table.get(new_coord, -1)

			# greedy: take first move that reduces depth (local optimum)
			if new_depth == current_depth - 1:
				solution_turns.push_back(turn)
				current_state = test_state
				break

	return solution_turns


## Returns the G1 coordinate composed of the corner orientation and E-slice position coordinates.
func _get_phase1_coord(state: RubiksCubeState) -> String:
	var corner_coord := ThistlethwaiteCoordinates.get_corner_orientation_coord(state)
	var e_slice_coord := ThistlethwaiteCoordinates.get_e_slice_coord(state)
	return "%d_%d" % [corner_coord, e_slice_coord]
