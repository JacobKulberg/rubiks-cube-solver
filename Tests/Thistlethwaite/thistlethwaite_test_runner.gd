class_name ThistlethwaiteTestRunner
extends RefCounted
## Unit tests for the Thistlethwaite solver.


## Runs unit tests for the Thistlethwaite solver using predefined and random scrambles.
static func run() -> void:
	var total_scrambles := 0
	var total_solves := 0

	print_rich("[color=#FFFF7A][b]\n=== Thistlethwaite Unit Tests ===\n[/b][/color]")
	print_rich("[color=white][u]%-20s%-12s%-8s%-6s[/u][/color]" % ["Scramble", "Solved", "HTM", "Time"])

	var solved_state := RubiksCubeState.new()

	var dir := DirAccess.open("res://Tests/Scrambles/")
	dir.list_dir_begin()

	var file_name := dir.get_next()
	while file_name != "":
		if dir.current_is_dir():
			file_name = dir.get_next()
			continue

		total_scrambles += 1

		var now := Time.get_ticks_msec()
		var test_str := file_name.substr(0, file_name.length() - 4)

		var file := FileAccess.open("res://Tests/Scrambles/%s" % file_name, FileAccess.READ)

		var scramble_moves := file.get_as_text().strip_edges().split(" ")
		file.close()

		var test_state := solved_state.copy()

		for move in scramble_moves:
			test_state.apply_turn(move)

		var solution_turns := ThistlethwaiteSolver.new(false).solve(test_state)
		var final_state := test_state.copy()
		for move in solution_turns:
			final_state.apply_turn(move)

		var elapsed := Time.get_ticks_msec() - now
		if final_state.to_hash() == solved_state.to_hash():
			test_str = "%-20s%-12s%-8d%-6s" % [test_str, "YES", solution_turns.size(), "%dms" % elapsed]
			test_str = "[color=lightgreen]" + test_str + "[/color]"

			total_solves += 1
		else:
			test_str = "%-20s%-12s%-8d%-6s" % [test_str, "NO", solution_turns.size(), "%dms" % elapsed]
			test_str = "[color=#FF7A7A]" + test_str + "[/color]"

		print_rich(test_str)

		file_name = dir.get_next()

	dir.list_dir_end()

	# random tests
	var turns_count := []
	var times_count := []

	for i in range(9):
		var random_state := solved_state.copy()
		var faces: Array[String] = ["R", "L", "U", "D", "F", "B"]
		var suffixes: Array[String] = ["", "'", "2"]
		var scramble_moves: Array[String] = []
		for j in range(50):
			var move: String = faces.pick_random() + suffixes.pick_random()
			scramble_moves.push_back(move)
			random_state.apply_turn(move)

		total_scrambles += 1

		var now := Time.get_ticks_msec()
		var scramble_str := "Random %d" % (i + 1)

		var solution_turns := ThistlethwaiteSolver.new(false).solve(random_state)
		var final_state := random_state.copy()
		for move in solution_turns:
			final_state.apply_turn(move)

		var elapsed := Time.get_ticks_msec() - now
		if final_state.to_hash() == solved_state.to_hash():
			scramble_str = "%-20s%-12s%-8d%-6s" % [scramble_str, "YES", solution_turns.size(), "%dms" % elapsed]
			scramble_str = "[color=lightgreen]" + scramble_str + "[/color]"

			total_solves += 1
		else:
			scramble_str = "%-20s%-12s%-8d%-6s" % [scramble_str, "NO", solution_turns.size(), "%dms" % elapsed]
			scramble_str = "[color=#FF7A7A]" + scramble_str + "[/color]"

		turns_count.push_back(solution_turns.size())
		times_count.push_back(elapsed)

		print_rich(scramble_str)

	print_rich("\n[color=white][u]Half-turn Metric (HTM)[/u][/color]")
	print_rich("[color=lightgreen]Best: %d[/color]" % turns_count.min())
	print_rich("[color=#FF7A7A]Worst: %d[/color]" % turns_count.max())
	print_rich("[color=#FFA857]Average: %0.2f\n[/color]" % (turns_count.reduce(func(a: int, b: int) -> float: return a + b) / float(turns_count.size())))

	print_rich("\n[color=white][u]Solve Time[/u][/color]")
	print_rich("[color=lightgreen]Best: %dms[/color]" % times_count.min())
	print_rich("[color=#FF7A7A]Worst: %dms[/color]" % times_count.max())
	print_rich("[color=#FFA857]Average: %0.2fms\n[/color]" % (times_count.reduce(func(a: int, b: int) -> float: return a + b) / float(times_count.size())))

	if total_scrambles == total_solves:
		print_rich("\n[color=#FFFF7A][b]Solved [/b][color=lightgreen]%d of %d[/color][b] total scrambles![/b][/color]" % [total_solves, total_scrambles])
	else:
		print_rich("\n[color=#FFFF7A][b]Solved [/b][color=#FF7A7A]%d of %d[/color][b] total scrambles![/b][/color]" % [total_solves, total_scrambles])
