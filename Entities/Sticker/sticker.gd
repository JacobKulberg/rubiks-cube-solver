@tool
class_name Sticker
extends Node3D

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


func _ready():
	set_sticker_color(sticker_color)


func set_sticker_color(color: StickerColor):
	var mesh: MeshInstance3D = $StickerMesh as MeshInstance3D
	var mat: StandardMaterial3D = mesh.get_active_material(0).duplicate() as StandardMaterial3D
	mesh.set_surface_override_material(0, mat)

	if color == StickerColor.WHITE:
		mat.albedo_color = Color(1.0, 1.0, 1.0)
	elif color == StickerColor.YELLOW:
		mat.albedo_color = Color(1.0, 1.0, 0.0)
	elif color == StickerColor.RED:
		mat.albedo_color = Color(1.0, 0.0, 0.0)
	elif color == StickerColor.ORANGE:
		mat.albedo_color = Color(1.0, 0.5, 0.0)
	elif color == StickerColor.BLUE:
		mat.albedo_color = Color(0.0, 0.0, 1.0)
	elif color == StickerColor.GREEN:
		mat.albedo_color = Color(0.0, 1.0, 0.0)
