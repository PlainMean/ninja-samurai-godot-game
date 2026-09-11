class_name CombatEvent
extends RefCounted
enum Kind { DEFENSE_SELECTED, DEFENDED, DAMAGE, COUNTER, WON, LOST }
var kind: Kind
var pattern_index: int
var strike_index: int
var defense_required: StrikeSpec.Defense
var selected_defense: StrikeSpec.Defense
var player_hp: int
var enemy_hp: int

func values() -> Array:
	return [kind, pattern_index, strike_index, defense_required, selected_defense, player_hp, enemy_hp]
