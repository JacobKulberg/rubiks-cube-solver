class_name Piece
extends Node3D
## Base class for all Rubik's Cube pieces (corners, edges, centers).
##
## Provides a common interface for applying colors to stickers.
## Subclasses must override [method apply_color] to implement their specific coloring logic.


func _ready() -> void:
	apply_color()


## Applies colors to the piece's stickers.
## Override this method in subclasses to implement piece-specific coloring.
func apply_color() -> void:
	pass
