class_name EncounterSpec
extends Resource
@export var id: StringName
@export var display_name: String
@export var enemy_max_hp: int
@export var element: Element.Type = Element.Type.WATER
@export var backdrop_tag: StringName
@export var banner_tag: StringName
@export var intro_text: String
@export var attack_elements: Array[int] = []
@export var attack_names: Array[String] = []
