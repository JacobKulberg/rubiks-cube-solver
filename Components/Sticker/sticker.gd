@tool
class_name Sticker
extends Node3D
## Represents a colored sticker on a Rubik's Cube piece.
##
## Manages the visual appearance of individual stickers by applying
## the appropriate color to the mesh material.

enum StickerColor {
	WHITE,
	YELLOW,
	RED,
	ORANGE,
	BLUE,
	GREEN,
}

@export var sticker_color: StickerColor:
	get:
		return _sticker_color
	set(value):
		_sticker_color = value
		set_sticker_color(value)

var _sticker_color: StickerColor = StickerColor.WHITE


func _ready() -> void:
	set_sticker_color(sticker_color)


## Sets the sticker's color by updating the mesh material.
## Creates a duplicate of the material to avoid affecting other stickers.
func set_sticker_color(color: StickerColor) -> void:
	var mesh: MeshInstance3D = $StickerMesh as MeshInstance3D
	var mat: StandardMaterial3D = mesh.get_active_material(0).duplicate() as StandardMaterial3D
	mesh.set_surface_override_material(0, mat)

	match color:
		StickerColor.WHITE:
			mat.albedo_color = Color(1.0, 1.0, 1.0)
		StickerColor.YELLOW:
			mat.albedo_color = Color(1.0, 1.0, 0.0)
		StickerColor.RED:
			mat.albedo_color = Color(1.0, 0.0, 0.0)
		StickerColor.ORANGE:
			mat.albedo_color = Color(1.0, 0.5, 0.0)
		StickerColor.BLUE:
			mat.albedo_color = Color(0.0, 0.0, 1.0)
		StickerColor.GREEN:
			mat.albedo_color = Color(0.0, 1.0, 0.0)
