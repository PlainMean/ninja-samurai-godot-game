class_name HeroSpec
extends Resource
## Data only. RunModel owns recruitment; CombatModel owns all combat HP/effects.
@export var id: StringName
@export var display_name: String
@export var description: String
@export var role: String
@export var element: Element.Type = Element.Type.WATER
@export var max_hp := 6
@export var ability_id: StringName = &"support_strike"
@export var attack_min := 1
@export var attack_max := 2
@export var effect := "Strike after your hit; WATER matchup adds 1. Enemy replies cost Kira 1 HP."
@export var sprite_frames: SpriteFrames
@export var join_condition: StringName = &"first_boss_victory"
