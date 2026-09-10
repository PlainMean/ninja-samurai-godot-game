extends Node2D
@export var frames: SpriteFrames
@export var faces_left := false
var sprite: AnimatedSprite2D
var home := Vector2.ZERO
var guard := false

func _ready() -> void:
	home = position
	var pivot := Node2D.new()
	pivot.name = "Visual"
	pivot.scale = Vector2(4, 4)
	add_child(pivot)
	sprite = AnimatedSprite2D.new()
	sprite.name = "Sprite"
	sprite.sprite_frames = frames
	sprite.animation = &"attack"
	sprite.centered = false
	sprite.position = Vector2(-16, -30)
	sprite.flip_h = faces_left
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.texture_repeat = CanvasItem.TEXTURE_REPEAT_DISABLED
	pivot.add_child(sprite)
	sprite.stop()

func show_pose(frame_index: int, attack_elapsed: float, attacking: bool, guarded: bool, tint: Color) -> void:
	sprite.frame = clampi(frame_index, 0, 5)
	sprite.modulate = tint
	var lunge := 0.0
	if attacking:
		lunge = 24.0 * (1.0 - absf(attack_elapsed / 0.3 - 1.0))
	position = (home + Vector2(-lunge if faces_left else lunge, 0)).round()
	guard = guarded
	queue_redraw()

func _draw() -> void:
	if guard:
		draw_arc(Vector2(0, -57), 55.0, -1.35, 1.35, 20, Color("258b91"), 4.0, false)
