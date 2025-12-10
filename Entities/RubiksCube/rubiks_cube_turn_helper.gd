class_name RubiksCubeTurnHelper
extends RefCounted

var cube: RubiksCube
var is_turning := false
var turn_queue: Array[String] = []
var current_duration: float
var base_duration: float
var min_duration: float
var duration_step: float
var max_turns_queued: int


func _init(rubiks_cube: RubiksCube) -> void:
	cube = rubiks_cube
	base_duration = cube.base_duration
	min_duration = cube.min_duration
	duration_step = cube.duration_step
	max_turns_queued = cube.max_moves_queued
	current_duration = base_duration


func queue_turn(face: String) -> void:
	if is_turning:
		if turn_queue.size() >= max_turns_queued:
			return

		turn_queue.push_back(face)
	else:
		make_turn(face)


func make_turn(face: String) -> void:
	if is_turning:
		return

	is_turning = true

	var duration := _calculate_duration()
	var pieces := _get_pieces_on_face(face)
	var turn_helper := _create_turn_helper(pieces)
	var turn_rotation := _calculate_turn_rotation(face)

	await _animate_turn(turn_helper, turn_rotation, duration)

	_reparent_pieces_to_cube(pieces)
	turn_helper.queue_free()
	_reassign_piece_groups(pieces)

	is_turning = false
	_process_next_turn()


func _calculate_duration() -> float:
	var target_duration := base_duration - duration_step * turn_queue.size()
	if target_duration < min_duration:
		target_duration = min_duration

	if target_duration < current_duration:
		current_duration = current_duration - duration_step
		if current_duration < target_duration:
			current_duration = target_duration
	elif target_duration > current_duration:
		current_duration = current_duration + duration_step
		if current_duration > target_duration:
			current_duration = target_duration

	return current_duration


func _get_pieces_on_face(face: String) -> Array[Node3D]:
	var pieces: Array[Node3D] = []
	pieces.assign(cube.get_tree().get_nodes_in_group(face))
	return pieces


func _create_turn_helper(pieces: Array[Node3D]) -> Node3D:
	var turn_helper := Node3D.new()
	turn_helper.name = "TurnHelper"
	cube.add_child(turn_helper)

	for piece in pieces:
		piece.reparent(turn_helper)

	return turn_helper


func _calculate_turn_rotation(face: String) -> Vector3:
	var rotation_amount := deg_to_rad(90)
	# TODO: this is only random temporarily
	if randi() % 2 == 0:
		rotation_amount *= -1

	var turn_rotation := Vector3.ZERO
	match face[0]:
		"X":
			turn_rotation.x += rotation_amount
		"Y":
			turn_rotation.y += rotation_amount
		"Z":
			turn_rotation.z += rotation_amount

	return turn_rotation


func _animate_turn(turn_helper: Node3D, turn_rotation: Vector3, duration: float) -> void:
	var tween := cube.create_tween()
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(turn_helper, "rotation", turn_rotation, duration)
	await tween.finished


func _reparent_pieces_to_cube(pieces: Array[Node3D]) -> void:
	for piece in pieces:
		piece.reparent(cube.get_node("Pieces"))


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


func _process_next_turn() -> void:
	if turn_queue.size() > 0:
		var next_face := turn_queue[0]
		turn_queue.remove_at(0)
		make_turn(next_face)
