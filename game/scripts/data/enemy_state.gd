class_name EnemyState
extends RefCounted
var spec: EncounterSpec
var slot: int
var hp: int
func _init(source: EncounterSpec, index: int) -> void:
	spec = source
	slot = index
	hp = source.enemy_max_hp
func intent_element(turn: int) -> Element.Type:
	return spec.element if spec.attack_elements.is_empty() else spec.attack_elements[(turn - 1) % spec.attack_elements.size()] as Element.Type
func intent_name(turn: int) -> String:
	return "Strike" if spec.attack_names.is_empty() else spec.attack_names[(turn - 1) % spec.attack_names.size()]
