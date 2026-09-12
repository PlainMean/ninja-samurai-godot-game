class_name UnitSpec
extends Resource
## Presentation-only identity. Combat behavior remains in EncounterSpec.
@export var unit_id: StringName
@export var display_name: String
@export var role: String
@export var element: Element.Type = Element.Type.NONE
@export var attack_animation: SpriteFrames
@export var visual_scale := 2.5
@export var boss := false
