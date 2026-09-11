extends Node2D
const Frames = preload("res://assets/frames/moonlit_dojo/combat_fx_frames.tres")
const Playback = preload("res://scripts/frame_playback.gd")
const ElementFrames = {
	&"water": preload("res://assets/frames/elements/water_frames.tres"),
	&"fire": preload("res://assets/frames/elements/fire_frames.tres"),
	&"earth": preload("res://assets/frames/elements/earth_frames.tres"),
	&"wind": preload("res://assets/frames/elements/wind_frames.tres")}
var clocks := {}
func frames_for(tag: StringName) -> SpriteFrames:
	return ElementFrames.get(tag, Frames)
func trigger_element(element: Element.Type, at: Vector2) -> void:
	trigger(Element.effect_tag(element), at)
func _ready() -> void:
	for tag in [&"block", &"dodge", &"hit", &"seal", &"water", &"fire", &"earth", &"wind"]:
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
		var frames := frames_for(tag)
		for i in range(frames.get_frame_count(tag)): duration += frames.get_frame_duration(tag, i) / frames.get_animation_speed(tag)
		if clocks[tag] >= duration: clocks.erase(tag)
	update_frames()
func clear() -> void:
	clocks.clear()
	update_frames()
func update_frames() -> void:
	for sprite in get_children():
		sprite.visible = clocks.has(StringName(sprite.name))
		if sprite.visible: Playback.show_frame(sprite, frames_for(sprite.name), sprite.name, clocks[StringName(sprite.name)])
