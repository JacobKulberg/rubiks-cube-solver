class_name RubiksCubeTurnHelper
extends RefCounted
## Helper class that manages Rubik's Cube turns.
##
## Handles turn queuing, animation, undoing, and piece reassignment.

## Reference to the RubiksCube node.
var cube: RubiksCube
## Whether a turn animation is currently active.
var is_turning := false
## Queue of pending turns. Each item is structured like: [br][br] { [br]	[code]face[/code]: [code]String[/code], [br]	[code]direction[/code]: [code]int[/code], [br]	[code]id[/code]: [code]int[/code] [br] }
var turn_queue: Array[Dictionary] = []
## History of executed turns, used for undo operations.
var turn_history: Array[Dictionary] = []
## Sequential identifier for uniquely tracking turns.
var next_turn_id := 0
## Current duration used for ongoing turn animation.
var current_turn_duration: float
## Base duration for a single turn when the queue is empty.
var base_turn_duration: float
## Minimum allowed duration a turn may reach.
var min_turn_duration: float
## Amount by which turn duration increases or decreases as queue size changes.
var turn_duration_step: float
## Maximum number of turns allowed in the queue.
var max_turns_queued: int


## Initializes the helper using timing configuration from the RubiksCube instance.
func _init(rubiks_cube: RubiksCube) -> void:
	cube = rubiks_cube
	base_turn_duration = cube.base_turn_duration
	min_turn_duration = cube.min_turn_duration
	turn_duration_step = cube.turn_duration_step
	max_turns_queued = cube.max_turns_queued
	current_turn_duration = base_turn_duration


## Queues a turn or executes it immediately if no turn is currently running.
##
## [br] [code]face[/code]: The face identifier (e.g. "X+", "Y-", "Z-").
## [br] [code]direction[/code]: 1 or -1. If 0, a direction is chosen at random.
## [br] [code]add_to_history[/code]: Whether this turn should be added to the undo history.
func queue_turn(face: String, direction: int = 0, add_to_history: bool = true) -> void:
	# TODO: this is only random temporarily
	var turn_direction := direction if direction != 0 else (1 if randi() % 2 == 0 else -1)
	var turn_id := -1

	# log turn into history
	if add_to_history:
		turn_id = next_turn_id
		next_turn_id += 1
		turn_history.push_back(
			{
				"face": face,
				"direction": turn_direction,
				"id": turn_id,
			},
		)

	# if another turn is running, queue this one
	if is_turning:
		# prevent turn queue from exceeding limit
		if turn_queue.size() >= max_turns_queued:
			# remove from history since turn will not execute
			if add_to_history:
				turn_history.pop_back()
			return

		turn_queue.push_back(
			{
				"face": face,
				"direction": turn_direction,
				"id": turn_id,
			},
		)
	else:
		# execute turn immediately
		_make_turn(face, turn_direction)


## Reverses the most recently executed turn, unless the turn queue is full.
func undo_last_turn() -> void:
	# nothing to undo
	if turn_history.is_empty():
		return

	# cannot undo if turn queue is full
	if turn_queue.size() >= max_turns_queued:
		return

	var last_turn: Dictionary = turn_history.pop_back()

	# check if the last turn is already queued for undoing
	# if so, remove it from the turn queue (no need to trigger that turn)
	for i in range(turn_queue.size() - 1, -1, -1):
		var queued_turn := turn_queue[i]
		if queued_turn.id == last_turn.id:
			turn_queue.remove_at(i)
			return

	# otherwise queue reversed turn without logging
	queue_turn(last_turn.face, -last_turn.direction, false)


## Executes the turn animation and updates cube state when the turn completes.
func _make_turn(face: String, direction: int) -> void:
	if is_turning:
		return

	is_turning = true

	var turn_duration := _calculate_turn_duration()
	var pieces := _get_pieces_on_face(face)
	var turn_helper := _create_turn_helper(pieces)
	var turn_rotation := _calculate_turn_rotation(face, direction)

	await _animate_turn(turn_helper, turn_rotation, turn_duration)

	_reparent_pieces_to_cube(pieces)
	turn_helper.queue_free()
	_reassign_piece_groups(pieces)

	is_turning = false
	_process_next_turn()


## Adjusts turn animation duration based on queue size for smooth speed up behavior.
func _calculate_turn_duration() -> float:
	var target_turn_duration := base_turn_duration - turn_duration_step * turn_queue.size()
	if target_turn_duration < min_turn_duration:
		target_turn_duration = min_turn_duration

	if target_turn_duration < current_turn_duration:
		current_turn_duration = current_turn_duration - turn_duration_step
		if current_turn_duration < target_turn_duration:
			current_turn_duration = target_turn_duration
	elif target_turn_duration > current_turn_duration:
		current_turn_duration = current_turn_duration + turn_duration_step
		if current_turn_duration > target_turn_duration:
			current_turn_duration = target_turn_duration

	return current_turn_duration


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


## Calculates a rotation vector for applying a 90 degree turn on a face.
func _calculate_turn_rotation(face: String, direction: int = 0) -> Vector3:
	var rotation_amount := deg_to_rad(90)
	rotation_amount *= direction

	var turn_rotation := Vector3.ZERO
	match face[0]:
		"X":
			turn_rotation.x += rotation_amount
		"Y":
			turn_rotation.y += rotation_amount
		"Z":
			turn_rotation.z += rotation_amount

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
	var face_groups: Array[String] = []
	face_groups.assign(cube.face_dict.values())

	for piece in pieces:
		# remove all face groups
		for group in face_groups:
			piece.remove_from_group(group)

		var piece_pos: Vector3 = piece.position

		# to avoid floating point precision issues
		var threshold := 0.9

		if piece_pos.x >= threshold:
			piece.add_to_group("X+")
		elif piece_pos.x <= -threshold:
			piece.add_to_group("X-")

		if piece_pos.y >= threshold:
			piece.add_to_group("Y+")
		elif piece_pos.y <= -threshold:
			piece.add_to_group("Y-")

		if piece_pos.z >= threshold:
			piece.add_to_group("Z+")
		elif piece_pos.z <= -threshold:
			piece.add_to_group("Z-")


## Executes the next queued turn, if one exists.
func _process_next_turn() -> void:
	if turn_queue.size() > 0:
		var next_turn := turn_queue[0]
		turn_queue.remove_at(0)
		_make_turn(next_turn.face, next_turn.direction)
