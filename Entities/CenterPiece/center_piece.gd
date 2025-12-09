@tool
class_name CenterPiece
extends Node3D

@export var sticker1_color: Sticker.StickerColor:
	get:
		return _sticker1_color
	set(value):
		_sticker1_color = value
		apply_color()

var _sticker1_color: Sticker.StickerColor = Sticker.StickerColor.WHITE


func _ready() -> void:
	apply_color()


func apply_color() -> void:
	var sticker1: Sticker = $Cubelet/Sticker1 as Sticker

	sticker1.set_sticker_color(sticker1_color)
