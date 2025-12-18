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
		var current_coord := ThistlethwaiteCoordinates.get_phase0_coord(current_state)
		var current_depth: int = table.get(current_coord, -1)

		# goal state reached
		if current_depth == 0:
			break

		# try all 18 turns, choose first that reduces depth
		for turn: String in ThistlethwaiteCoordinates.G0_TURNS:
			var test_state := current_state.copy()
			test_state.apply_turn(turn)
			var new_coord := ThistlethwaiteCoordinates.get_phase0_coord(test_state)
			var new_depth: int = table.get(new_coord, -1)

			# greedy: take first move that reduces depth (local optimum)
			if new_depth == current_depth - 1:
				solution_turns.push_back(turn)
				current_state = test_state
				break

	return solution_turns


## Reduces G1 to G2 (orients all corners and correctly places M-slice).[br][br]
##
## [param state]: Current cube state (this state will be modified)[br]
## [param table]: Precomputed G1 table (coordinates map to depth)[br][br]
##
## Returns a sequence of turns that orients all corners and correctly places M-slice edges in the M-slice.[br]
## Uses all turns in the set {L, R, F, B, U2, D2}
func solve_phase1(state: RubiksCubeState, table: Dictionary[int, int]) -> Array[String]:
	var solution_turns: Array[String] = []
	var current_state := state.copy()

	while true:
		var current_coord := ThistlethwaiteCoordinates.get_phase1_coord(current_state)
		var current_depth: int = table.get(current_coord, -1)

		# goal state reached
		if current_depth == 0:
			break

		# try all 14 turns (to preserve edge orientation from G0), choose first that reduces depth
		for turn: String in ThistlethwaiteCoordinates.G1_TURNS:
			var test_state := current_state.copy()
			test_state.apply_turn(turn)
			var new_coord := ThistlethwaiteCoordinates.get_phase1_coord(test_state)
			var new_depth: int = table.get(new_coord, -1)

			# greedy: take first move that reduces depth (local optimum)
			if new_depth == current_depth - 1:
				solution_turns.push_back(turn)
				current_state = test_state
				break

	return solution_turns


## Reduces G2 to G3.
## Correctly places E- and S-slice edges, places corners in their correct tetrads,
## fixes edge parity, and resolves each tetrad's twist.[br][br]
##
## [param state]: Current cube state (this state will be modified)[br]
## [param table]: Precomputed G2 table (coordinates map to depth)[br][br]
##
## Returns a sequence of turns that completes Phase 2.[br]
## Uses all turns in the set {L, R, F2, B2, U2, D2}
func solve_phase2(state: RubiksCubeState, table: Dictionary[int, int]) -> Array[String]:
	for depth in range(0, 14): # max depth: 13 = 14 - 1
		var solution_turns: Array[String] = []

		if _search_phase2_iddfs(state, table, depth, solution_turns):
			return solution_turns

	return []


## Performs an iterative deepening depth-first search to find a solution for phase G2.[br][br]
##
## Searches for a sequence of G2-legal moves that reduces the cube from G2 to G3 by correctly
## placing E- and S-sliceedges, placing corners in their correct tetrads, fixing edge parity,
## and resolving each tetrad's twist.[br][br]
##
## [param state]: Current cube state (this state will be modified)[br]
## [param table]: Precomputed G2 table (coordinates map to depth)[br]
## [param depth]: Current search depth limit.[br]
## [param solution_turns]: Array to store found solution turns.[br][br]
##
## Returns true if a solution was found within the given depth, false otherwise.
func _search_phase2_iddfs(state: RubiksCubeState, table: Dictionary[int, int], depth: int, solution_turns: Array[String]) -> bool:
	var coord := ThistlethwaiteCoordinates.get_phase2_coord(state)
	var current_depth: Variant = table.get(coord, -1)

	# goal state reached
	if current_depth == 0:
		return true

	if current_depth < 0 or current_depth > depth:
		return false
	if depth == 0:
		return false

	for turn in ThistlethwaiteCoordinates.G2_TURNS:
		var next_state := state.copy()
		next_state.apply_turn(turn)

		solution_turns.push_back(turn)

		if _search_phase2_iddfs(next_state, table, depth - 1, solution_turns):
			return true

		solution_turns.pop_back()

	return false
