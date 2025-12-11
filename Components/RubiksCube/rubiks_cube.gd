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

## Maps face identifiers to their corresponding group names.
var face_dict := {
	"X_POS": "X+",
	"X_NEG": "X-",
	"Y_POS": "Y+",
	"Y_NEG": "Y-",
	"Z_POS": "Z+",
	"Z_NEG": "Z-",
}
## Helper that manages turn queuing, animation, and undo logic.
var turn_helper: RubiksCubeTurnHelper


## Initializes the turn helper.
func _ready() -> void:
	turn_helper = RubiksCubeTurnHelper.new(self)


## Slowly rotates the cube.
func _physics_process(delta: float) -> void:
	self.rotation_degrees.y += delta * 30


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
		elif mouse_event.button_index == MOUSE_BUTTON_RIGHT:
			turn_helper.undo_last_turn()
		else:
			# do not pulse on other mouse events
			return

		_pulse_scale()


## Plays a brief, pulsing scale animation when the cube is interacted with.
func _pulse_scale() -> void:
	var scale_tween := create_tween()
	scale_tween.set_ease(Tween.EASE_OUT)
	scale_tween.set_trans(Tween.TRANS_CUBIC)
	scale_tween.tween_property(self, "scale", Vector3.ONE * 1.125, 0.05) # magic numbers but whatev
	scale_tween.tween_property(self, "scale", Vector3.ONE, 0.1)
