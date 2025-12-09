@tool
class_name CornerPiece
extends Node3D

@export var sticker1_color: Sticker.StickerColor:
	get:
		return _sticker1_color
	set(value):
		_sticker1_color = value
		apply_color()
@export var sticker2_color: Sticker.StickerColor:
	get:
		return _sticker2_color
	set(value):
		_sticker2_color = value
		apply_color()
@export var sticker3_color: Sticker.StickerColor:
	get:
		return _sticker3_color
	set(value):
		_sticker3_color = value
		apply_color()

var _sticker1_color: Sticker.StickerColor = Sticker.StickerColor.WHITE
var _sticker2_color: Sticker.StickerColor = Sticker.StickerColor.WHITE
var _sticker3_color: Sticker.StickerColor = Sticker.StickerColor.WHITE


func _ready():
	apply_color()


func apply_color():
	var sticker1: Sticker = $Cubelet/Sticker1 as Sticker
	var sticker2: Sticker = $Cubelet/Sticker2 as Sticker
	var sticker3: Sticker = $Cubelet/Sticker3 as Sticker

	sticker1.set_sticker_color(sticker1_color)
	sticker2.set_sticker_color(sticker2_color)
	sticker3.set_sticker_color(sticker3_color)
