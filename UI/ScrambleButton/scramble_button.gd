class_name ScrambleButton
extends PanelContainer

var is_hovered := false
var hover_tween: Tween

@onready var cube := get_tree().get_first_node_in_group("cube") as RubiksCube
@onready var solution_text: Label = get_tree().get_first_node_in_group("solution_text") as Label


func _process(_delta: float) -> void:
	# increase button scale when hovered
	# set button scale back to (1.0, 1.0) when unhovered

	if cube.turn_helper.is_turning:
		mouse_default_cursor_shape = Control.CURSOR_FORBIDDEN
	else:
		mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND

	if hover_tween:
		hover_tween.kill()

	hover_tween = create_tween()
	hover_tween.set_ease(Tween.EASE_OUT)
	hover_tween.set_trans(Tween.TRANS_CUBIC)

	if is_hovered and not cube.turn_helper.is_turning:
		hover_tween.tween_property(self, "scale", Vector2(1.05, 1.05), 0.15)
	else:
		hover_tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.15)


func _on_mouse_entered() -> void:
	is_hovered = true


func _on_mouse_exited() -> void:
	is_hovered = false


func _on_gui_input(event: InputEvent) -> void:
	if event is not InputEventMouseButton:
		return

	if cube.turn_helper.is_turning:
		return

	if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		cube.scramble()

		_pulse_scale()

		solution_text.text = ""


func _pulse_scale() -> void:
	# pulsing scaling effect on button click
	var pulse_tween := create_tween()
	pulse_tween.set_ease(Tween.EASE_OUT)
	pulse_tween.set_trans(Tween.TRANS_CUBIC)
	pulse_tween.tween_property(self, "scale", Vector2(0.875, 0.875), 0.05)
	pulse_tween.tween_property(self, "scale", Vector2.ONE, 0.1)
