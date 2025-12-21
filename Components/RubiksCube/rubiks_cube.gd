class_name RubiksCube
extends Node3D
## Main RubiksCube node.
##
## Handles user events and turn interaction.

## Base duration for a single turn when the queue is empty.
@export var base_turn_duration := 0.15
## Minimum allowed duration a turn may reach.
@export var min_turn_duration := 0.075
## Amount by which turn duration increases or decreases as queue size changes.
@export var turn_duration_step := 0.01
## Maximum number of turns allowed in the queue.
@export var max_turns_queued := 10
## Sensitivity for mouse rotation.
@export var rotation_sensitivity := 0.005

## Whether the user is currently dragging with middle mouse button.
var is_dragging := false
## Last mouse position during drag.
var last_mouse_position := Vector2.ZERO
## Helper that manages turn queuing, animation, and undo logic.
var turn_helper: RubiksCubeTurnHelper
## Logical state of the cube.
var state: RubiksCubeState
## Thistlethwaite's Algorithm solver instance.
var thistlethwaite_solver: ThistlethwaiteSolver

## Reference to main camera node
@onready var camera: Camera3D = get_node("../Camera3D") as Camera3D


func _ready() -> void:
	turn_helper = RubiksCubeTurnHelper.new(self)
	state = RubiksCubeState.new()
	thistlethwaite_solver = ThistlethwaiteSolver.new()


## Returns cube to neutral rotation when not being dragged.
func _physics_process(delta: float) -> void:
	if not is_dragging:
		rotation.x = lerpf(rotation.x, 0.0, delta * 3.0)
		rotation.z = lerpf(rotation.z, 0.0, delta * 3.0)


## Handles input for triggering random turns or undo operations.
## LMB: queue random turn
## RMB: undo last turn
func _input(event: InputEvent) -> void:
	var mouse_event := event as InputEventMouseButton
	if mouse_event and mouse_event.pressed:
		if mouse_event.button_index == MOUSE_BUTTON_LEFT:
			# TODO: this is only random temporarily
			var faces: Array[String] = ["R", "L", "U", "D", "F", "B"]
			var suffixes: Array[String] = ["", "'", "2"]
			turn_helper.queue_turn(faces.pick_random() + suffixes.pick_random())

			_pulse_scale()
		elif mouse_event.button_index == MOUSE_BUTTON_RIGHT:
			turn_helper.undo_last_turn()

			_pulse_scale()
		elif mouse_event.button_index == MOUSE_BUTTON_MIDDLE:
			is_dragging = true
			last_mouse_position = mouse_event.position
	elif mouse_event and not mouse_event.pressed:
		if mouse_event.button_index == MOUSE_BUTTON_MIDDLE:
			is_dragging = false

	var mouse_motion_event := event as InputEventMouseMotion
	if mouse_motion_event and is_dragging:
		var delta := mouse_motion_event.position - last_mouse_position
		last_mouse_position = mouse_motion_event.position

		rotate(camera.global_transform.basis.y, delta.x * rotation_sensitivity)
		rotate(camera.global_transform.basis.x, delta.y * rotation_sensitivity)

	var key_event := event as InputEventKey
	if key_event and key_event.keycode == KEY_SPACE and key_event.is_pressed():
		var solution := thistlethwaite_solver.solve(get_current_state())
		print("Solution: ", " ".join(solution))
		execute_algorithm(" ".join(solution))
	elif key_event and key_event.keycode == KEY_B and key_event.is_pressed():
		ThistlethwaiteTableGenerator.new().generate_all_tables()
		thistlethwaite_solver = ThistlethwaiteSolver.new()
	elif key_event and key_event.keycode == KEY_P and key_event.is_pressed():
		state.print()


## Returns a copy of the current cube state.
func get_current_state() -> RubiksCubeState:
	return state.copy()


## Executes a sequence of turns from a space-separated string.
func execute_algorithm(turns: String) -> void:
	turns = turns.strip_edges()

	if turns.is_empty():
		return

	var turn_list := turns.split(" ")
	for turn in turn_list:
		turn_helper.queue_turn(turn, true, true)


## Plays a brief, pulsing scale animation when the cube is interacted with.
func _pulse_scale() -> void:
	var scale_tween := create_tween()
	scale_tween.set_ease(Tween.EASE_OUT)
	scale_tween.set_trans(Tween.TRANS_CUBIC)
	scale_tween.tween_property(self, "scale", Vector3.ONE * 1.125, 0.05) # magic numbers but whatev
	scale_tween.tween_property(self, "scale", Vector3.ONE, 0.1)
