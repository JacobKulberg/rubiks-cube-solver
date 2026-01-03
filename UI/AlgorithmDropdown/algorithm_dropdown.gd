class_name AlgorithmDropdown
extends PanelContainer

@export var save_file_path := "res://Preferences/preferences.cfg"

@onready var dropdown := $MarginContainer/OptionButton


func _ready() -> void:
	_load_setting()


func get_algorithm_index() -> int:
	var config := ConfigFile.new()
	config.load(save_file_path)
	var index: int = config.get_value("Preferences", "selected_algorithm", 0)
	return index


func _on_option_button_item_selected(index: int) -> void:
	_save_setting(index)


func _save_setting(index: int) -> void:
	var config := ConfigFile.new()
	config.load(save_file_path)
	config.set_value("Preferences", "selected_algorithm", index)
	config.save(save_file_path)


func _load_setting() -> void:
	var config := ConfigFile.new()
	var preferences_exist := config.load(save_file_path)
	if preferences_exist == OK:
		var saved_index: int = config.get_value("Preferences", "selected_algorithm", 0)
		dropdown.select(saved_index)
	else:
		dropdown.select(0)
