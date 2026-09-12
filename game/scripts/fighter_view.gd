extends Node2D
const Playback = preload("res://scripts/frame_playback.gd")
@export var frames: SpriteFrames
@export var support: SpriteFrames
@export var faces_left := false
@onready var sprite: AnimatedSprite2D = $Visual/Sprite
var selected_unit: UnitSpec
var legacy_frames: SpriteFrames
var legacy_support: SpriteFrames
var home := Vector2.ZERO
var guard := false
func _ready() -> void:
	legacy_frames = frames
	legacy_support = support
	home = position
	sprite.flip_h = faces_left
	sprite.stop()
func present(tag: StringName, time: float, attacking: bool, attack_elapsed: float, dodging: bool) -> void:
	Playback.show_frame(sprite, frames if tag == &"attack" else support, tag, time)
	var lunge := 24.0 * (1.0 - absf(attack_elapsed / 0.3 - 1.0)) if attacking else 0.0
	var retreat := 20.0 * (1.0 - absf(attack_elapsed / 0.3 - 1.0)) if dodging else 0.0
	position = (home + Vector2(-lunge if faces_left else lunge - retreat, 0)).round()
	guard = tag == &"guard"

func configure_unit(unit: UnitSpec) -> void:
	if selected_unit == unit: return
	selected_unit = unit
	frames = unit.attack_animation if unit != null else legacy_frames
	support = unit.attack_animation if unit != null else legacy_support
	$Visual.scale = Vector2.ONE * unit.visual_scale if unit != null else Vector2(4,4)
	sprite.position = Vector2(-24,-44) if unit != null else Vector2(-16,-30)
