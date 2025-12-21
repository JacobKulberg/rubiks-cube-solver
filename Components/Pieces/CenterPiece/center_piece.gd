@tool
class_name CenterPiece
extends Piece
## Represents a center piece of the Rubik's Cube.
##
## Center pieces have one visible sticker and are located at the center of each face.
## The sticker color can be assigned via an exported property.

@export var sticker1_color: Sticker.StickerColor:
	get:
		return _sticker1_color
	set(value):
		_sticker1_color = value
		apply_color()

var _sticker1_color: Sticker.StickerColor = Sticker.StickerColor.WHITE


func apply_color() -> void:
	var sticker1: Sticker = $Cubelet/Sticker1 as Sticker

	sticker1.set_sticker_color(sticker1_color)
