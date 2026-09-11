extends Node2D
const Playback = preload("res://scripts/frame_playback.gd")
@export var frames: SpriteFrames
@export var support: SpriteFrames
@export var faces_left := false
@onready var sprite: AnimatedSprite2D = $Visual/Sprite
var home := Vector2.ZERO
var guard := false
func _ready() -> void:
	home = position
	sprite.flip_h = faces_left
	sprite.stop()
func present(tag: StringName, time: float, attacking: bool, attack_elapsed: float, dodging: bool) -> void:
	Playback.show_frame(sprite, frames if tag == &"attack" else support, tag, time)
	var lunge := 24.0 * (1.0 - absf(attack_elapsed / 0.3 - 1.0)) if attacking else 0.0
	var retreat := 20.0 * (1.0 - absf(attack_elapsed / 0.3 - 1.0)) if dodging else 0.0
	position = (home + Vector2(-lunge if faces_left else lunge - retreat, 0)).round()
	guard = tag == &"guard"
