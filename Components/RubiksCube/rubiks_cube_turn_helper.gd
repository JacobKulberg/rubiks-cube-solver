class_name RubiksCubeTurnHelper
extends RefCounted
## Helper class that manages Rubik's Cube turns.
##
## Handles turn queuing, animation, undoing, and piece reassignment.[br][br]
##
## [b]Coordinate system:[/b][br]
## - White on U (Y+)[br]
## - Green on F (X-)[br]
## - Red on R (Z+)[br][br]
##
## [b]Cube orientation:[/b][br]
## - R: Z+ axis[br]
## - L: Z- axis[br]
## - U: Y+ axis[br]
## - D: Y- axis[br]
## - F: X- axis[br]
## - B: X+ axis

## Reference to the RubiksCube node.
var cube: RubiksCube
## Whether a turn animation is currently active.
var is_turning := false
## Queue of pending turns.
var turn_queue: Array[Turn] = []
## History of executed turns, used for undo operations.
var turn_history: Array[Turn] = []
## Base duration for a single turn when the queue is empty.
var base_turn_duration: float
## Minimum allowed duration a turn may reach.
var min_turn_duration: float
## Amount by which turn duration increases or decreases as queue size changes.
var turn_duration_step: float
## Maximum number of turns allowed in the queue.
var max_turns_queued: int
## Sequential identifier for uniquely tracking turns.
var _next_turn_id := 0
## Current duration used for ongoing turn animation.
var _current_turn_duration: float


## Initializes the helper using timing configuration from the RubiksCube instance.
func _init(rubiks_cube: RubiksCube) -> void:
	cube = rubiks_cube
	base_turn_duration = cube.base_turn_duration
	min_turn_duration = cube.min_turn_duration
	turn_duration_step = cube.turn_duration_step
	max_turns_queued = cube.max_turns_queued
	_current_turn_duration = base_turn_duration


## Queues a turn or executes it immediately if no turn is currently running.[br][br]
##
## [param turn_notation]: Standard Rubik's Cube notation (R, L, U, D, F, B with optional ' or 2).[br]
## [param add_to_history]: Whether this turn should be added to the undo history.[br]
## [param ignore_max_size]: Whether the maximum queue size should be accounting for when queuing this turn.
func queue_turn(turn_notation: String, add_to_history: bool = true, ignore_max_size: bool = false) -> void:
	var turn_id := -1

	# log turn into history
	if add_to_history:
		turn_id = _next_turn_id
		_next_turn_id += 1
		turn_history.push_back(Turn.new(turn_notation, turn_id))

	# if another turn is running, queue this one
	if is_turning:
		# prevent turn queue from exceeding limit
		if not ignore_max_size and turn_queue.size() >= max_turns_queued:
			# remove from history since turn will not execute
			if add_to_history:
				turn_history.pop_back()
			return

		turn_queue.push_back(Turn.new(turn_notation, turn_id))
	else:
		# execute turn immediately
		_make_turn(turn_notation)


## Reverses the most recently executed turn, unless the turn queue is full.
func undo_last_turn() -> void:
	# nothing to undo
	if turn_history.is_empty():
		return

	# cannot undo if turn queue is full
	if turn_queue.size() >= max_turns_queued:
		return

	var last_turn: Turn = turn_history[-1]
	turn_history.remove_at(turn_history.size() - 1)

	# check if the last turn is already queued for undoing
	# if so, remove it from the turn queue (no need to trigger that turn)
	for i in range(turn_queue.size() - 1, -1, -1):
		var queued_turn := turn_queue[i]
		if queued_turn.id == last_turn.id:
			turn_queue.remove_at(i)
			return

	# otherwise queue reversed turn without logging
	var reversed_notation := _reverse_notation(last_turn.turn_notation)
	queue_turn(reversed_notation, false)


## Returns a [String] in standard Rubik's Cube notation that negates [param turn_notation]
func _reverse_notation(turn_notation: String) -> String:
	var face := turn_notation[0]

	if turn_notation.length() == 1:
		return face + "'"
	elif turn_notation[1] == "'":
		return face

	# is a half turn
	return turn_notation


## Executes the turn animation and updates cube state when the turn completes.
func _make_turn(turn_notation: String) -> void:
	if is_turning:
		return

	is_turning = true

	var face := turn_notation[0]
	var direction := 1
	var is_half_turn := false

	if turn_notation.length() == 2:
		if turn_notation[1] == "'":
			direction = -1
		elif turn_notation[1] == "2":
			is_half_turn = true

	cube.state.apply_turn(turn_notation)

	var turn_duration := _calculate_turn_duration()
	var pieces := _get_pieces_on_face(face)
	var turn_helper := _create_turn_helper(pieces)
	var turn_rotation := _calculate_turn_rotation(face, direction, is_half_turn)

	# PI/2 < 2.0 < PI
	if absf(turn_rotation.dot(Vector3.ONE)) > 2.0:
		turn_duration *= 2

	await _animate_turn(turn_helper, turn_rotation, turn_duration)

	_reparent_pieces_to_cube(pieces)
	turn_helper.queue_free()
	_reassign_piece_groups(pieces)

	is_turning = false
	_process_next_turn()


## Adjusts turn animation duration based on queue size for smooth speed up behavior.
func _calculate_turn_duration() -> float:
	var target_turn_duration := maxf(base_turn_duration - turn_duration_step * turn_queue.size(), min_turn_duration)

	if target_turn_duration < _current_turn_duration:
		_current_turn_duration = maxf(_current_turn_duration - turn_duration_step, target_turn_duration)
	elif target_turn_duration > _current_turn_duration:
		_current_turn_duration = minf(_current_turn_duration + turn_duration_step, target_turn_duration)

	return _current_turn_duration


## Returns all cube pieces belonging to a given face group.
func _get_pieces_on_face(face: String) -> Array[Node3D]:
	var pieces: Array[Node3D] = []
	pieces.assign(cube.get_tree().get_nodes_in_group(face))
	return pieces


## Creates a temporary Node3D helper and reparents pieces to allow unified rotation.
func _create_turn_helper(pieces: Array[Node3D]) -> Node3D:
	var turn_helper := Node3D.new()
	turn_helper.name = "TurnHelper"
	cube.add_child(turn_helper)

	for piece in pieces:
		piece.reparent(turn_helper)

	return turn_helper


## Calculates a rotation vector for applying a quarter or half turn.
func _calculate_turn_rotation(face: String, direction: int, is_half_turn: bool) -> Vector3:
	var rotation_amount := deg_to_rad(180 if is_half_turn else 90)
	rotation_amount *= direction

	var turn_rotation := Vector3.ZERO
	match face[0]:
		"R":
			turn_rotation.z = -rotation_amount
		"L":
			turn_rotation.z = rotation_amount
		"U":
			turn_rotation.y = -rotation_amount
		"D":
			turn_rotation.y = rotation_amount
		"F":
			turn_rotation.x = rotation_amount
		"B":
			turn_rotation.x = -rotation_amount

	return turn_rotation


## Animates the turn rotation using a tween.
func _animate_turn(turn_helper: Node3D, turn_rotation: Vector3, duration: float) -> void:
	var tween := cube.create_tween()
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(turn_helper, "rotation", turn_rotation, duration)
	await tween.finished


## Reparents rotated pieces back to the main cube once the turn is complete.
func _reparent_pieces_to_cube(pieces: Array[Node3D]) -> void:
	for piece in pieces:
		piece.reparent(cube.get_node("Pieces"))


## Reassigns each piece to its correct face group based on updated world position.
func _reassign_piece_groups(pieces: Array[Node3D]) -> void:
	var all_faces: Array[String] = ["R", "L", "U", "D", "F", "B"]

	for piece in pieces:
		# remove all face groups
		for face in all_faces:
			piece.remove_from_group(face)

		var piece_pos: Vector3 = piece.position

		# to avoid floating point precision issues
		var threshold := 0.9

		if piece_pos.z >= threshold:
			piece.add_to_group("R")
		elif piece_pos.z <= -threshold:
			piece.add_to_group("L")

		if piece_pos.y >= threshold:
			piece.add_to_group("U")
		elif piece_pos.y <= -threshold:
			piece.add_to_group("D")

		if piece_pos.x >= threshold:
			piece.add_to_group("B")
		elif piece_pos.x <= -threshold:
			piece.add_to_group("F")


## Executes the next queued turn, if one exists.
func _process_next_turn() -> void:
	if turn_queue.size() > 0:
		var next_turn := turn_queue[0]
		turn_queue.remove_at(0)
		_make_turn(next_turn.turn_notation)


class Turn:
	var turn_notation: String
	var id: int


	func _init(_turn_notation: String, _id: int = -1) -> void:
		turn_notation = _turn_notation
		id = _id
