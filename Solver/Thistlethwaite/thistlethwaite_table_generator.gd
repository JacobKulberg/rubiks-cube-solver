class_name ThistlethwaiteTableGenerator
extends TableGenerator
## Generates lookup tables for Thistlethwait's algorithm using BFS.
##
## Each phase explores the reachable state space from the solved position,
## recording the minimum depth to reach each coordinate. Tables are saved
## to a file for use by the solver.


## Generates the G0 lookup table.[br][br]
##
## Explores all reachable states when only edge orientation matters.[br]
## Uses all 18 turns. Expected size: 2048 states, max depth: 7.[br][br]
##
## Returns a [Dictionary] mapping edge orientation coordinates to search depth.
func generate_phase0_table() -> Dictionary:
	var table: Dictionary[int, int] = { }
	var queue: Array = []

	# start from solved state
	var solved_state := RubiksCubeState.new()
	var solved_coord := ThistlethwaiteCoordinates.get_edge_orientation_coord(solved_state)

	table[solved_coord] = 0
	queue.push_back(solved_state)

	# allow all 18 turns
	var valid_turns: Array[String] = ["R", "L", "U", "D", "F", "B", "R'", "L'", "U'", "D'", "F'", "B'", "R2", "L2", "U2", "D2", "F2", "B2"]

	print_rich("[b]Generating[/b] G0 → G1 table...")
	var start_time := Time.get_ticks_msec()

	# BFS: explore all reachable states level by level
	while not queue.is_empty():
		var current_state: RubiksCubeState = queue.pop_front()
		var current_coord := ThistlethwaiteCoordinates.get_edge_orientation_coord(current_state)
		var current_depth: int = table[current_coord]

		# try all turns from the current state
		for turn in valid_turns:
			var next_state := current_state.copy()
			next_state.apply_turn(turn)
			var next_coord := ThistlethwaiteCoordinates.get_edge_orientation_coord(next_state)

			# record new state if not seen before
			if not table.has(next_coord):
				table[next_coord] = current_depth + 1
				queue.push_back(next_state)

	print_rich("G0 → G1 table [b]completed[/b] in [b]%d[/b]ms!" % (Time.get_ticks_msec() - start_time))
	print("Size: %d states" % table.size())

	return table


## Generates the G1 lookup table.[br][br]
##
## Explores all reachable states when corner orientation and E-slice position matter.[br]
## Uses 14 turns. Expected size: 1082565 states, max depth: 10.[br][br]
##
## Returns a [Dictionary] mapping corner orientation and E-slice position coordinates to search depth.
func generate_phase1_table() -> Dictionary:
	var table: Dictionary[String, int] = { }
	var queue: Array = []

	# start from solved state
	var solved_state := RubiksCubeState.new()
	var solved_coord := _get_phase1_coord(solved_state)

	table[solved_coord] = 0
	queue.push_back(solved_state)

	# only allow turns that preserve edge orientation
	var valid_turns: Array[String] = ["R", "L", "F", "B", "R'", "L'", "F'", "B'", "R2", "L2", "U2", "D2", "F2", "B2"]

	print_rich("[b]Generating[/b] G1 → G2 table...")
	var start_time := Time.get_ticks_msec()

	# BFS explore all reachable states level by level
	while not queue.is_empty():
		var current_state: RubiksCubeState = queue.pop_front()
		var current_coord := _get_phase1_coord(current_state)
		var current_depth: int = table[current_coord]

		# try all turns from current state
		for turn in valid_turns:
			var next_state := current_state.copy()
			next_state.apply_turn(turn)
			var next_coord := _get_phase1_coord(next_state)

			# record new state if not seen before
			if not table.has(next_coord):
				table[next_coord] = current_depth + 1
				queue.push_back(next_state)

	print_rich("G1 → G2 table [b]completed[/b] in [b]%d[/b]ms!" % (Time.get_ticks_msec() - start_time))
	print("Size: %d states" % table.size())

	return table


## Generates all Thistlethwaite lookup tables and saves them to a binary file.[br][br]
##
## This is the main entry point for table generation.[br]
## Run this once to create the tables before using the solver.
func generate_all_tables() -> void:
	print_rich("[color=white][b]=== Starting Thistlethwaite Table Generation ===[/b][/color]\n")

	# Generate and save G0 table
	var phase0_table := generate_phase0_table()
	print("Max depth: %d\n" % _get_max_depth(phase0_table))
	save_table(phase0_table, "res://Solver/Thistlethwaite/Tables/phase0_table.dat")

	# Generate and save G1 table
	var phase1_table := generate_phase1_table()
	print("Max depth: %d\n" % _get_max_depth(phase1_table))
	save_table(phase1_table, "res://Solver/Thistlethwaite/Tables/phase1_table.dat")


## Returns the composite G1 coordinate (corner orientation + E-slice position).
func _get_phase1_coord(state: RubiksCubeState) -> String:
	var corner_coord := ThistlethwaiteCoordinates.get_corner_orientation_coord(state)
	var e_slice_coord := ThistlethwaiteCoordinates.get_e_slice_coord(state)
	return "%d_%d" % [corner_coord, e_slice_coord]


## Returns the maximum depth-value in a given lookup table.
func _get_max_depth(table: Dictionary) -> int:
	var max_depth := 0
	for depth: int in table.values():
		if depth > max_depth:
			max_depth = depth
	return max_depth
