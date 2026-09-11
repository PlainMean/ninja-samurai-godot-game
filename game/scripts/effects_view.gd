extends Node2D
const Frames = preload("res://assets/frames/moonlit_dojo/combat_fx_frames.tres")
const Playback = preload("res://scripts/frame_playback.gd")
var clocks := {}
func _ready() -> void:
	for tag in [&"block", &"dodge", &"hit", &"seal"]:
		var sprite := AnimatedSprite2D.new()
		sprite.name = tag
		sprite.scale = Vector2(2, 2)
		sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		sprite.visible = false
		add_child(sprite)
func trigger(tag: StringName, at: Vector2) -> void:
	clocks[tag] = 0.0
	get_node(NodePath(tag)).position = at
	update_frames()
func advance(delta: float) -> void:
	for tag in clocks.keys():
		clocks[tag] += delta
		var duration := 0.0
		for i in range(Frames.get_frame_count(tag)): duration += Frames.get_frame_duration(tag, i) / 10.0
		if clocks[tag] >= duration: clocks.erase(tag)
	update_frames()
func clear() -> void:
	clocks.clear()
	update_frames()
func update_frames() -> void:
	for sprite in get_children():
		sprite.visible = clocks.has(StringName(sprite.name))
		if sprite.visible: Playback.show_frame(sprite, Frames, sprite.name, clocks[StringName(sprite.name)])
