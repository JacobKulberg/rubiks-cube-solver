@tool
class_name EdgePiece
extends Piece

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

var _sticker1_color: Sticker.StickerColor = Sticker.StickerColor.WHITE
var _sticker2_color: Sticker.StickerColor = Sticker.StickerColor.WHITE


func apply_color() -> void:
	var sticker1: Sticker = $Cubelet/Sticker1 as Sticker
	var sticker2: Sticker = $Cubelet/Sticker2 as Sticker

	sticker1.set_sticker_color(sticker1_color)
	sticker2.set_sticker_color(sticker2_color)
