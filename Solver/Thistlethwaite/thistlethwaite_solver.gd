class_name ThistlethwaiteSolver
extends TableGenerator
## Solver for Thistlethwaite's Algorithm.

# Precomputed lookup table for phase G0 (edge orientation maps to depth)
var phase0_table: Dictionary
# Precomputed lookup table for phase G1 (corner orientation and M-slice position map to depth)
var phase1_table: Dictionary
# Precomputed lookup table for phase G2 (E/S-slice position, corner tetrad, edge parity, and tetrad twist map to depth)
var phase2_table: Dictionary
# Precomputed lookup table for phase G3 (edge and corner permutations map to depth)
var phase3_table: Dictionary


## Loads lookup tables from disk.
func _init(verbose: bool = true) -> void:
	phase0_table = load_table("res://Solver/Thistlethwaite/Tables/phase0_table.dat", verbose)
	phase1_table = load_table("res://Solver/Thistlethwaite/Tables/phase1_table.dat", verbose)
	phase2_table = load_table("res://Solver/Thistlethwaite/Tables/phase2_table.dat", verbose)
	phase3_table = load_table("res://Solver/Thistlethwaite/Tables/phase3_table.dat", verbose)


## Solves the cube using Thistlethwaite's Algorithm.[br][br]
##
## [param state]: Current cube state[br][br]
##
## Returns the complete solution as an array of turn strings in standard notation.[br]
## The solution chains together turns from all phases.
func solve(state: RubiksCubeState) -> Array[String]:
	state = state.copy()
	var search := ThistlethwaiteSearch.new()

	# Phase G0: Orient all edges
	var phase0_turns := search.solve_phase0(state, phase0_table)
	state.apply_turns(" ".join(phase0_turns))

	# Phase G1: Orient all corners and permute M-slice
	var phase1_turns := search.solve_phase1(state, phase1_table)
	state.apply_turns(" ".join(phase1_turns))

	# Phase G2:
	var phase2_turns := search.solve_phase2(state, phase2_table)
	state.apply_turns(" ".join(phase2_turns))

	# Phase G3:
	var phase3_turns := search.solve_phase3(state, phase3_table)
	state.apply_turns(" ".join(phase3_turns))

	# Combine all phase solutions
	var all_turns: Array[String] = []
	all_turns.append_array(phase0_turns)
	all_turns.append_array(phase1_turns)
	all_turns.append_array(phase2_turns)
	all_turns.append_array(phase3_turns)
	_reduce_redundant_turns(all_turns)
	return all_turns


func _reduce_redundant_turns(turns: Array[String]) -> void:
	var i := 0
	while i < turns.size() - 1:
		if turns[i][0] != turns[i + 1][0]:
			i += 1
			continue

		var total := _turn_value(turns[i]) + _turn_value(turns[i + 1])
		total = (total % 4 + 4) % 4

		turns.remove_at(i + 1)

		if total == 0:
			turns.remove_at(i)
		else:
			turns[i] = turns[i][0] + ("" if total == 1 else "2" if total == 2 else "'")

		i = maxi(i - 1, 0)


func _turn_value(turn: String) -> int:
	match turn.length():
		1:
			return 1
		2:
			return -1 if turn[1] == "'" else 2

	return 0
