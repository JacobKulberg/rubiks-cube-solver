class_name GithubButton
extends PanelContainer

var is_hovered := false
var hover_tween: Tween


func _process(_delta: float) -> void:
	# increase button scale when hovered
	# set button scale back to (1.0, 1.0) when unhovered

	if hover_tween:
		hover_tween.kill()

	hover_tween = create_tween()
	hover_tween.set_ease(Tween.EASE_OUT)
	hover_tween.set_trans(Tween.TRANS_CUBIC)

	if is_hovered:
		hover_tween.tween_property(self, "scale", Vector2(1.1, 1.1), 0.15)
	else:
		hover_tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.15)


func _on_mouse_entered() -> void:
	is_hovered = true


func _on_mouse_exited() -> void:
	is_hovered = false


func _on_gui_input(event: InputEvent) -> void:
	if event is not InputEventMouseButton:
		return

	if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		OS.shell_open("https://github.com/JacobKulberg/rubiks-cube-solver")
		_pulse_scale()


func _pulse_scale() -> void:
	# pulsing scaling effect on button click
	var pulse_tween := create_tween()
	pulse_tween.set_ease(Tween.EASE_OUT)
	pulse_tween.set_trans(Tween.TRANS_CUBIC)
	pulse_tween.tween_property(self, "scale", Vector2(0.875, 0.875), 0.05)
	pulse_tween.tween_property(self, "scale", Vector2.ONE, 0.1)
