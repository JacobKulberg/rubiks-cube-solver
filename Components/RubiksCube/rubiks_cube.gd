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
## Sensitivity for mouse rotation
@export var rotation_sensitivity := 0.005

## Maps face identifiers to their corresponding group names.
var face_dict := {
	"X_POS": "X+",
	"X_NEG": "X-",
	"Y_POS": "Y+",
	"Y_NEG": "Y-",
	"Z_POS": "Z+",
	"Z_NEG": "Z-",
}
## Whether the user is currently dragging with middle mouse button
var is_dragging := false
## Last mouse position during drag
var last_mouse_position := Vector2.ZERO
## Helper that manages turn queuing, animation, and undo logic.
var turn_helper: RubiksCubeTurnHelper
var cube_state: RubiksCubeState

## Reference to main camera node
@onready var camera: Camera3D = get_node("../Camera3D")


## Initializes the turn helper.
func _ready() -> void:
	turn_helper = RubiksCubeTurnHelper.new(self)
	cube_state = RubiksCubeState.new()


## Slowly rotates the cube, unless its being dragged.
func _physics_process(delta: float) -> void:
	if not is_dragging:
		rotation_degrees.y += delta * 30
		if rotation_degrees.y >= 360.0:
			rotation_degrees.y -= 360.0

		rotation.x = lerp(rotation.x, 0.0, delta)
		rotation.z = lerp(rotation.z, 0.0, delta * 2.0)


## Handles input for triggering random turns or undo operations.
## LMB: queue random turn
## RMB: undo last turn
func _input(event: InputEvent) -> void:
	var mouse_event := event as InputEventMouseButton
	if mouse_event and mouse_event.pressed:
		if mouse_event.button_index == MOUSE_BUTTON_LEFT:
			var faces: Array[String] = []
			faces.assign(face_dict.values())
			# TODO: this is only random temporarily
			turn_helper.queue_turn(faces[randi() % faces.size()])

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


func get_current_state() -> RubiksCubeState:
	return cube_state.copy()


## Plays a brief, pulsing scale animation when the cube is interacted with.
func _pulse_scale() -> void:
	var scale_tween := create_tween()
	scale_tween.set_ease(Tween.EASE_OUT)
	scale_tween.set_trans(Tween.TRANS_CUBIC)
	scale_tween.tween_property(self, "scale", Vector3.ONE * 1.125, 0.05) # magic numbers but whatev
	scale_tween.tween_property(self, "scale", Vector3.ONE, 0.1)
