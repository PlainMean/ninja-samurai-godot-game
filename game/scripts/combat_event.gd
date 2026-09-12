class_name CombatEvent
extends RefCounted
enum Kind { PLAYER_HIT, ENEMY_HIT, WON, LOST }
var kind: Kind
var element: Element.Type = Element.Type.NONE
var matchup: Element.Matchup = Element.Matchup.NEUTRAL
var roll := 0
var weapon_bonus := 0
var technique_level := 0
var matchup_bonus := 0
var damage: int
var turn: int
var player_hp: int
var enemy_hp: int
func values() -> Array:
	return [kind, element, matchup, damage, turn, player_hp, enemy_hp]
