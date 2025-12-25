class_name RubiksCube
extends Node3D
## Main RubiksCube node.
##
## Handles user events and turn interaction.

## Base duration for a single turn when the queue is empty.
@export var base_turn_duration := 0.2
## Minimum allowed duration a turn may reach.
@export var min_turn_duration := 0.08
## Amount by which turn duration increases or decreases as queue size changes.
@export var turn_duration_step := 0.015
## Maximum number of turns allowed in the queue.
@export var max_turns_queued := 8
## Sensitivity for mouse rotation.
@export var rotation_sensitivity := 0.005

## Whether the user is currently dragging with middle mouse button.
var is_dragging := false
## Last mouse position during drag.
var last_mouse_position := Vector2.ZERO
## Whether the mouse is currently hovering over the cube.
var is_hovering := false
## Current hover scale bonus (0.0 when not hovering, 0.05 when hovering).
var hover_scale := 0.0
## Tween for hover scale animation.
var hover_tween: Tween
## Current pulse scale bonus from click animation.
var pulse_scale := 0.0
## Helper that manages turn queuing, animation, and undo logic.
var turn_helper: RubiksCubeTurnHelper
## Logical state of the cube.
var state: RubiksCubeState
## Thistlethwaite's Algorithm solver instance.
var thistlethwaite_solver: ThistlethwaiteSolver

## Reference to main camera node
@onready var camera: Camera3D = get_node("../Camera3D") as Camera3D


func _ready() -> void:
	# initialize components
	turn_helper = RubiksCubeTurnHelper.new(self)
	state = RubiksCubeState.new()
	thistlethwaite_solver = ThistlethwaiteSolver.new()


## Updates cube scale based on hover and pulse bonuses.
func _process(_delta: float) -> void:
	_update_hover_state()
	_apply_scale()


## Returns cube to neutral rotation when not being dragged.
func _physics_process(delta: float) -> void:
	if not is_dragging:
		rotation.x = lerpf(rotation.x, 0.0, delta * 3.0)
		rotation.z = lerpf(rotation.z, 0.0, delta * 3.0)


## Handles all user input.
func _input(event: InputEvent) -> void:
	var mouse_button_event := event as InputEventMouseButton
	_handle_mouse_button_event(mouse_button_event)

	var mouse_motion_event := event as InputEventMouseMotion
	_handle_mouse_motion_event(mouse_motion_event)

	var key_event := event as InputEventKey
	_handle_key_event(key_event)


## Returns a copy of the current cube state.
func get_current_state() -> RubiksCubeState:
	return state.copy()


## Solves the cube and prints the solution in standard cube notation.
func solve() -> void:
	if turn_helper.is_turning:
		return

	var solution := thistlethwaite_solver.solve(get_current_state())
	print("Solution: ", " ".join(solution))
	execute_algorithm(" ".join(solution))


## Scrambles the cube by performing 50 random turns.
func scramble() -> void:
	var faces: Array[String] = ["R", "L", "U", "D", "F", "B"]
	var suffixes: Array[String] = ["", "'", "2"]
	var scramble_moves: Array[String] = []
	for j in range(50):
		var turn: String = faces.pick_random() + suffixes.pick_random()
		scramble_moves.push_back(turn)
	var scramble_str := " ".join(scramble_moves)
	execute_algorithm(scramble_str)


## Builds all Thistlethwaite tables for phases 1 through 4
func generate_thistlethwaite_tables() -> void:
	var thistlethwaite_table_generator := ThistlethwaiteTableGenerator.new()
	thistlethwaite_table_generator.generate_all_tables()

	thistlethwaite_solver = ThistlethwaiteSolver.new()


## Executes a sequence of turns from a space-separated string.
func execute_algorithm(turns: String) -> void:
	turns = turns.strip_edges()

	if turns.is_empty():
		return

	var turn_list := turns.split(" ")
	for turn in turn_list:
		turn_helper.queue_turn(turn, true, true)


## Handles all mouse clicking events.
func _handle_mouse_button_event(event: InputEventMouseButton) -> void:
	if not event:
		return

	if event.pressed:
		match event.button_index:
			MOUSE_BUTTON_LEFT:
				if _is_mouse_over_cube(event.position):
					_turn_random_face()
			MOUSE_BUTTON_RIGHT:
				if _is_mouse_over_cube(event.position):
					_undo_last_turn()
			MOUSE_BUTTON_MIDDLE:
				is_dragging = true
				last_mouse_position = event.position
	elif event.button_index == MOUSE_BUTTON_MIDDLE:
		is_dragging = false


## Handles all mouse motion events.
func _handle_mouse_motion_event(event: InputEventMouseMotion) -> void:
	if not event:
		return

	if is_dragging:
		var delta := event.position - last_mouse_position
		last_mouse_position = event.position

		rotate(camera.global_transform.basis.y, delta.x * rotation_sensitivity)
		rotate(camera.global_transform.basis.x, delta.y * rotation_sensitivity)


## Handles all keyboard events.
func _handle_key_event(event: InputEventKey) -> void:
	if not event:
		return

	if event.is_pressed():
		match event.keycode:
			KEY_SPACE:
				solve()
			KEY_B:
				generate_thistlethwaite_tables()
			KEY_P:
				state.print()
			KEY_T:
				ThistlethwaiteTestRunner.run()


## Turns a random face on the cube clockwise, counterclockwise, or 180 degrees.
func _turn_random_face() -> void:
	var faces: Array[String] = ["R", "L", "U", "D", "F", "B"]
	var suffixes: Array[String] = ["", "'", "2"]
	turn_helper.queue_turn(faces.pick_random() + suffixes.pick_random())

	_pulse_scale()


## Undoes the last turn made.
func _undo_last_turn() -> void:
	turn_helper.undo_last_turn()

	_pulse_scale()


## Checks if mouse position is over the cube using raycast.
func _is_mouse_over_cube(mouse_position: Vector2) -> bool:
	var from := camera.project_ray_origin(mouse_position)
	var to := from + camera.project_ray_normal(mouse_position) * 1000.0

	var space_state := get_world_3d().direct_space_state
	var query := PhysicsRayQueryParameters3D.create(from, to)
	query.collide_with_areas = true
	query.collide_with_bodies = true

	var result := space_state.intersect_ray(query)
	if result:
		# check if the hit object is part of the cube
		var collider: Node3D = result.get("collider")

		if collider:
			var parent := collider

			while parent:
				if parent == self:
					return true

				parent = parent.get_parent()

	return false


## Updates hover state and animates hover scale when it changes.
func _update_hover_state() -> void:
	var mouse_pos := get_viewport().get_mouse_position()
	var hovering := _is_mouse_over_cube(mouse_pos)

	if hovering != is_hovering:
		is_hovering = hovering

		if is_hovering:
			Input.set_default_cursor_shape(Input.CURSOR_POINTING_HAND)
		else:
			Input.set_default_cursor_shape(Input.CURSOR_ARROW)

		if hover_tween:
			hover_tween.kill()

		hover_tween = create_tween()
		hover_tween.set_ease(Tween.EASE_OUT)
		hover_tween.set_trans(Tween.TRANS_CUBIC)
		hover_tween.tween_property(self, "hover_scale", 0.05 if is_hovering else 0.0, 0.15)


## Applies the combined hover and pulse scale to the cube.
func _apply_scale() -> void:
	var total_scale := 1.0 + hover_scale + pulse_scale
	scale = Vector3.ONE * total_scale


## Plays a brief, pulsing scale animation when the cube is interacted with.
func _pulse_scale() -> void:
	var pulse_tween := create_tween()
	pulse_tween.set_ease(Tween.EASE_OUT)
	pulse_tween.set_trans(Tween.TRANS_CUBIC)
	pulse_tween.tween_property(self, "pulse_scale", -0.125, 0.05)
	pulse_tween.tween_property(self, "pulse_scale", 0.0, 0.1)
