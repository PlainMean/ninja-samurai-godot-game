extends Node2D
const Playback = preload("res://scripts/frame_playback.gd")
@export var frames: SpriteFrames
@export var support: SpriteFrames
@export var faces_left := false
@onready var sprite: AnimatedSprite2D = $Visual/Sprite
var weapon_visual: WeaponVisualSpec
var sword: AnimatedSprite2D
const PlayerAttack = preload("res://assets/frames/weapons/player_attack_frames.tres")
const PlayerSupport = preload("res://assets/frames/weapons/player_support_frames.tres")
# Hand and tip coordinates from the untouched Aseprite pose sources.
const ATTACK_GRIPS = [Vector2(22,16),Vector2(13,9),Vector2(24,14),Vector2(25,18),Vector2(23,23),Vector2(21,18)]
const ATTACK_TIPS = [Vector2(28,7),Vector2(21,1),Vector2(30,6),Vector2(31,17),Vector2(28,30),Vector2(28,11)]
const SUPPORT_GRIPS = [Vector2(22,16),Vector2(22,16),Vector2(21,13),Vector2(21,11),Vector2(19,20),Vector2(18,22),Vector2(18,23),Vector2(18,20),Vector2(20,19),Vector2(21,23),Vector2(21,25),Vector2(22,27)]
const SUPPORT_TIPS = [Vector2(28,7),Vector2(28,7),Vector2(27,4),Vector2(25,2),Vector2(27,15),Vector2(26,18),Vector2(26,20),Vector2(25,15),Vector2(27,13),Vector2(28,20),Vector2(29,24),Vector2(30,27)]
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
	var body := frames if tag == &"attack" else support
	if weapon_visual != null: body = PlayerAttack if tag == &"attack" else PlayerSupport
	Playback.show_frame(sprite, body, tag, time)
	if weapon_visual != null:
		Playback.show_frame(sword, weapon_visual.frames, &"sword", time)
		var atlas: AtlasTexture = body.get_frame_texture(tag, sprite.frame)
		var pose := int(atlas.region.position.x / 32)
		var hand: Vector2 = ATTACK_GRIPS[pose] if tag == &"attack" else SUPPORT_GRIPS[pose]
		var tip: Vector2 = ATTACK_TIPS[pose] if tag == &"attack" else SUPPORT_TIPS[pose]
		sword.position = sprite.position + hand
		sword.rotation = (tip - hand).angle() + PI / 2
	var lunge := 24.0 * scale.x * (1.0 - absf(attack_elapsed / 0.3 - 1.0)) if attacking else 0.0
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

func equip_visual(weapon: WeaponSpec) -> void:
	weapon_visual = weapon.visual() if weapon != null else null
	if sword == null and weapon_visual != null:
		sword = AnimatedSprite2D.new()
		sword.name = "EquippedSword"
		sword.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		sword.centered = false
		sword.scale = Vector2.ONE * 0.4
		$Visual.add_child(sword)
	if sword != null:
		sword.visible = weapon_visual != null
		if weapon_visual != null:
			sword.offset = -weapon_visual.grip
			Playback.show_frame(sword, weapon_visual.frames, &"sword", 0)
