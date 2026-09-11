extends Control
@export var sheet: Texture2D
var atlas := AtlasTexture.new()
func _ready() -> void:
	atlas.atlas = sheet
	$Art.texture = atlas
func present(text: String, time: float) -> void:
	atlas.region = Rect2((int(time / 0.3) % 3) * 160, 0, 160, 96)
	$Caption.text = text
