class_name ThistlethwaiteTableGenerator
extends TableGenerator
## Generates lookup tables for Thistlethwait's algorithm using BFS.
##
## Each phase explores the reachable state space from the solved position,
## recording the minimum depth to reach each coordinate. Tables are saved
## to a file for use by the solver.


## Generates all Thistlethwaite lookup tables and saves them to a binary file.[br][br]
##
## This is the main entry point for table generation.[br]
## Run this once to create the tables before using the solver.
func generate_all_tables() -> void:
	print_rich("[color=white][b]\n=== Starting Thistlethwaite Table Generation ===[/b][/color]\n")

	# Generate and save G0 table
	var phase0_table := generate_phase0_table()
	save_table(phase0_table, "res://Solver/Thistlethwaite/Tables/phase0_table.dat")

	# Generate and save G1 table
	var phase1_table := generate_phase1_table()
	save_table(phase1_table, "res://Solver/Thistlethwaite/Tables/phase1_table.dat")

	# Generate and save G2 table
	var phase2_table := generate_phase2_table()
	save_table(phase2_table, "res://Solver/Thistlethwaite/Tables/phase2_table.dat")

	# Generate and save G3 table
	var phase3_table := generate_phase3_table()
	save_table(phase3_table, "res://Solver/Thistlethwaite/Tables/phase3_table.dat")

	print_rich("[color=white][b]=== Thistlethwaite Tables Generated ===[/b][/color]\n")


## Generates the G0 lookup table.[br][br]
##
## Explores all reachable states when only edge orientation matters.[br]
## Uses all 18 turns. Expected size: 2048 states, max depth: 7.[br][br]
##
## Returns a [Dictionary] mapping edge orientation coordinates to search depth.
func generate_phase0_table() -> Dictionary:
	return _generate_phase_table(
		ThistlethwaiteCoordinates.get_phase0_coord,
		ThistlethwaiteCoordinates.G0_TURNS,
		2048,
		"G0 → G1",
	)


## Generates the G1 lookup table.[br][br]
##
## Explores all reachable states when corner orientation and M-slice position matter.[br]
## Uses 14 turns. Expected size: 1082565 states, max depth: 10.[br][br]
##
## Returns a [Dictionary] mapping corner orientation and M-slice position coordinates to search depth.
func generate_phase1_table() -> Dictionary:
	return _generate_phase_table(
		ThistlethwaiteCoordinates.get_phase1_coord,
		ThistlethwaiteCoordinates.G1_TURNS,
		1082565,
		"G1 → G2",
	)


## Generates the G2 lookup table.[br][br]
##
## Explores all reachable states when E/S-slice position, corner tetrad, edge parity, and tetrad twist matter.[br]
## Uses 10 turns. Expected size: 29400 states, max depth: 13
##
## Returns a [Dictionary] mapping E/S-slice position, corner tetrad, edge parity, and tetrad twist coordinates to search depth.
func generate_phase2_table() -> Dictionary:
	return _generate_phase_table(
		ThistlethwaiteCoordinates.get_phase2_coord,
		ThistlethwaiteCoordinates.G2_TURNS,
		29400,
		"G2 → G3",
	)


## Generates the G3 lookup table.[br][br]
##
## Explores all reachable states when edge and corner permutations matter.[br]
## Uses 6 turns. Expected size: 663552 states, max depth: 15
##
## Returns a [Dictionary] mapping edge and corner permutation coordinates to search depth.
func generate_phase3_table() -> Dictionary:
	return _generate_phase_table(
		ThistlethwaiteCoordinates.get_phase3_coord,
		ThistlethwaiteCoordinates.G3_TURNS,
		663552,
		"G3 → G4",
	)


## Generates a phase table using BFS.[br][br]
##
## [param coord_func]: A [Callable] that takes a [RubiksCubeState] and returns its coordinate.[br]
## [param valid_turns]: Array of allowed turn strings for this phase.[br]
## [param expected_size]: Expected number of states (for progress display).[br]
## [param phase_name]: Display name for the phase (e.g., "G0 → G1").[br][br]
##
## Returns a [Dictionary] mapping coordinates to minimum search depth.
func _generate_phase_table(coord_func: Callable, valid_turns: Array[String], expected_size: int, phase_name: String) -> Dictionary:
	var table: Dictionary = { }
	var queue: Array[RubiksCubeState] = []

	# start from solved state
	var solved_state := RubiksCubeState.new()
	var solved_coord: int = coord_func.call(solved_state)

	table[solved_coord] = 0
	queue.push_back(solved_state)

	print_rich("[b]Generating[/b] %s table..." % phase_name)
	var start_time := Time.get_ticks_msec()

	# determine progress interval based on expected size
	var progress_interval := 100 if expected_size < 10000 else (1000 if expected_size < 100000 else 10000)

	# BFS: explore all reachable states level by level
	while not queue.is_empty():
		var current_state: RubiksCubeState = queue[0]
		queue.remove_at(0)
		var current_coord: int = coord_func.call(current_state)
		var current_depth: int = table[current_coord]

		# try all turns from the current state
		for turn in valid_turns:
			var next_state := current_state.copy()
			next_state.apply_turn(turn)
			var next_coord: int = coord_func.call(next_state)

			# record new state if not seen before
			if not table.has(next_coord):
				table[next_coord] = current_depth + 1
				queue.push_back(next_state)

				if table.size() % progress_interval == 0:
					print("%d states found (%0.1f%%)" % [table.size(), table.size() / float(expected_size) * 100])

	print_rich("%s table completed in [b]%dms[/b]!" % [phase_name, Time.get_ticks_msec() - start_time])
	print_rich("Size: [b]%d states[/b]" % table.size())
	print_rich("Max depth: [b]%d turns[/b]\n" % _get_max_depth(table))

	return table


## Returns the maximum depth-value in a given lookup table.
func _get_max_depth(table: Dictionary) -> int:
	var max_depth := 0
	for depth in table.values() as Array[int]:
		if depth > max_depth:
			max_depth = depth
	return max_depth
