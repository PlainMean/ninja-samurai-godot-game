class_name WeaponSpec
extends Resource
@export var id: StringName
@export var display_name: String
@export var element: Element.Type
@export var base_descriptor := "Seeded 1–4"

const VISUALS = {
 Element.Type.FIRE: preload("res://data/weapon_visuals/fire.tres"),
 Element.Type.WATER: preload("res://data/weapon_visuals/water.tres"),
 Element.Type.EARTH: preload("res://data/weapon_visuals/earth.tres"),
 Element.Type.WIND: preload("res://data/weapon_visuals/wind.tres")}
func visual() -> WeaponVisualSpec:
 return VISUALS[element]
