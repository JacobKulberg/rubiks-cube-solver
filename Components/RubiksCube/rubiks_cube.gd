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


## Handles input for triggering random turns or undo operations.
## LMB on cube: queue random turn
## RMB on cube: undo last turn
## MMB: drag to rotate cube
## SPACE: solve cube and print solution
## B: regenerate Thistlethwaite tables
## P: print current cube state
## T: run Thistlethwaite tests
func _input(event: InputEvent) -> void:
	var mouse_event := event as InputEventMouseButton
	if mouse_event and mouse_event.pressed:
		if mouse_event.button_index == MOUSE_BUTTON_LEFT:
			if _is_mouse_over_cube(mouse_event.position):
				# TODO: this is only random temporarily
				var faces: Array[String] = ["R", "L", "U", "D", "F", "B"]
				var suffixes: Array[String] = ["", "'", "2"]
				turn_helper.queue_turn(faces.pick_random() + suffixes.pick_random())

				_pulse_scale()
		elif mouse_event.button_index == MOUSE_BUTTON_RIGHT:
			if _is_mouse_over_cube(mouse_event.position):
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
	if key_event and key_event.is_pressed():
		match key_event.keycode:
			KEY_SPACE:
				var solution := thistlethwaite_solver.solve(get_current_state())
				print("Solution: ", " ".join(solution))
				execute_algorithm(" ".join(solution))
			KEY_B:
				ThistlethwaiteTableGenerator.new().generate_all_tables()
				thistlethwaite_solver = ThistlethwaiteSolver.new()
			KEY_P:
				state.print()
			KEY_T:
				ThistlethwaiteTestRunner.run()


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
	pulse_tween.tween_property(self, "pulse_scale", 0.125, 0.05)
	pulse_tween.tween_property(self, "pulse_scale", 0.0, 0.1)
