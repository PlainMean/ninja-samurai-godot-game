class_name CombatEvent
extends RefCounted
enum Kind { PLAYER_HIT, ENEMY_HIT, WON, LOST, COMPANION_HIT, COMPANION_WARD, COMPANION_HURT, KIRA_ATTACK, SKILL, EVADE }
var actor: StringName = &"main"
var target_slot := 0
var target_actor: StringName = &"enemy"
var source_slot := -1
var skill_id: StringName = &""
var party_hp: Array[int] = []
var guard := 0
var evade := false
var cooldowns: Dictionary = {}
var kind: Kind
var element: Element.Type = Element.Type.NONE
var matchup: Element.Matchup = Element.Matchup.NEUTRAL
var roll := 0
var weapon_bonus := 0
var technique_level := 0
var matchup_bonus := 0
var damage: int
var companion_hp := 0
var turn: int
var player_hp: int
var enemy_hp: int
func values() -> Array:
	return [kind, element, matchup, damage, turn, player_hp, enemy_hp, actor, target_slot, skill_id, party_hp.duplicate(), companion_hp, roll, weapon_bonus, technique_level, matchup_bonus, guard, evade, cooldowns.duplicate(), target_actor, source_slot]
