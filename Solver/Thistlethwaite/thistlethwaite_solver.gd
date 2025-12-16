class_name ThistlethwaiteSolver
extends TableGenerator
## Solver for Thistlethwaite's Algorithm.

# Precomputed lookup table for phase G0 (edge orientation maps to depth)
var phase0_table: Dictionary[int, int]
# Precomputed lookup table for phase G1 (corner orientation and M-slice position map to depth)
var phase1_table: Dictionary[int, int]
# Precomputed lookup table for phase G2 (E/S-slice position, corner tetrad, and edge parity map to depth)
var phase2_table: Dictionary[int, int]


## Loads lookup tables from disk.
func _init() -> void:
	phase0_table = load_table("res://Solver/Thistlethwaite/Tables/phase0_table.dat")
	phase1_table = load_table("res://Solver/Thistlethwaite/Tables/phase1_table.dat")
	phase2_table = load_table("res://Solver/Thistlethwaite/Tables/phase2_table.dat")


## Solves the cube using Thistlethwaite's Algorithm.[br][br]
##
## [param state]: Current cube state (will be modified while solving)[br][br]
##
## Returns the complete solution as an array of turn strings in standard notation.[br]
## The solution chains together turns from all phases.
func solve(state: RubiksCubeState) -> Array[String]:
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

	# Combine all phase solutions
	var all_turns: Array[String] = []
	all_turns.append_array(phase0_turns)
	all_turns.append_array(phase1_turns)
	all_turns.append_array(phase2_turns)
	return all_turns
