class_name RubiksCube
extends Node3D

@export var base_duration := 0.15
@export var min_duration := 0.075
@export var duration_step := 0.01
@export var max_moves_queued := 10

var is_rotating := false
var move_queue := []
var current_duration := base_duration
var side_dict := {
	"X_POS": "X+",
	"X_NEG": "X-",
	"Y_POS": "Y+",
	"Y_NEG": "Y-",
	"Z_POS": "Z+",
	"Z_NEG": "Z-",
}


func _input(event: InputEvent) -> void:
	var key_event := event as InputEventMouseButton
	if key_event and key_event.button_index == MOUSE_BUTTON_LEFT and key_event.pressed:
		var sides: Array[String] = []
		sides.assign(side_dict.values())
		# TODO: this is only random temporarily
		if is_rotating and move_queue.size() < max_moves_queued:
			move_queue.push_back(sides[randi() % sides.size()])
		else:
			rotate_side(sides[randi() % sides.size()])


func rotate_side(side: String) -> void:
	# dont rotate while rotating
	if is_rotating:
		return

	is_rotating = true

	var target_duration := max(base_duration - duration_step * move_queue.size(), min_duration) as float

	if target_duration < current_duration:
		current_duration = max(current_duration - duration_step, target_duration)
	elif target_duration > current_duration:
		current_duration = min(current_duration + duration_step, target_duration)

	var duration := current_duration

	# get all pieces on side
	var pieces: Array[Node3D] = []
	pieces.assign(get_tree().get_nodes_in_group(side))

	# create rotation helper
	var rotation_helper := Node3D.new()
	rotation_helper.name = "RotationHelper"
	self.add_child(rotation_helper)

	# reparent pieces to rotation helper
	for piece in pieces:
		piece.reparent(rotation_helper)

	# rotate 90deg
	var rotation_amount := deg_to_rad(90)
	# TODO: this is only random temporarily
	if randi() % 2 == 0:
		rotation_amount *= -1
	var target_rotation := Vector3.ZERO

	match side[0]:
		"X":
			target_rotation.x += rotation_amount
		"Y":
			target_rotation.y += rotation_amount
		"Z":
			target_rotation.z += rotation_amount

	# rotate smoothly
	var tween := create_tween()
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(rotation_helper, "rotation", target_rotation, duration)
	await tween.finished

	# reparent pieces to rubik's cube
	for piece in pieces:
		piece.reparent($Pieces)

	# delete rotation helper
	rotation_helper.queue_free()

	# reassign groups
	for piece in pieces:
		# remove all side groups
		var side_groups: Array[String] = []
		side_groups.assign(side_dict.values())
		for group in side_groups:
			piece.remove_from_group(group)

		var piece_pos: Vector3 = piece.position

		# to account for floating point precision error
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

	is_rotating = false
	if move_queue.size() > 0:
		var next_side = move_queue.pop_front()
		rotate_side(next_side)
