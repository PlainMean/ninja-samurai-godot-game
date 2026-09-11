class_name CombatModel
extends RefCounted
## Sole damage authority. Time advances presentation only, never a player's choice.
enum Phase { READY, PLAYER_TURN, PLAYER_ATTACK, ENEMY_TURN, ENEMY_ATTACK, WON, LOST }
const ATTACK_TIME := 0.6
const IMPACT_TIME := 0.3
const ENEMY_TURN_TIME := 0.35
const EPS := 0.000000001
const DEFAULT_SPEC = preload("res://data/encounters/gate_guard.tres")
var spec: EncounterSpec = DEFAULT_SPEC
var state: Phase = Phase.READY
var elapsed := 0.0
var player_hp := 5
var player_max_hp := 5
var enemy_hp := 3
var player_affinity: Element.Type = Element.Type.NONE
var selected_element: Element.Type = Element.Type.NONE
var turn_number := 1
var impact_resolved := false
var attacks := 0
var damage := 0
var events: Array[CombatEvent] = []
var combat_log: Array[String] = []

func reset() -> void:
	configure(DEFAULT_SPEC, 5, 5)

func configure(encounter: EncounterSpec, hp: int, max_hp: int, affinity: Element.Type = Element.Type.NONE) -> void:
	spec = encounter
	player_hp = hp
	player_max_hp = max_hp
	enemy_hp = spec.enemy_max_hp
	player_affinity = affinity
	selected_element = Element.Type.NONE
	turn_number = 1
	impact_resolved = false
	attacks = 0
	damage = 0
	events.clear()
	combat_log.clear()
	state = Phase.READY
	elapsed = 0.0

func start() -> void:
	if state == Phase.READY: _enter(Phase.PLAYER_TURN)

func request_attack(element: Element.Type) -> bool:
	if state != Phase.PLAYER_TURN or element not in [Element.Type.FIRE, Element.Type.WATER, Element.Type.EARTH, Element.Type.WIND]:
		return false
	selected_element = element
	_enter(Phase.PLAYER_ATTACK)
	return true

func duration() -> float:
	if is_attack(): return ATTACK_TIME
	if state == Phase.ENEMY_TURN: return ENEMY_TURN_TIME
	return 0.0

func is_attack() -> bool:
	return state in [Phase.PLAYER_ATTACK, Phase.ENEMY_ATTACK]

func terminal() -> bool:
	return state in [Phase.WON, Phase.LOST]

func step(delta: float) -> void:
	if not is_finite(delta) or delta <= 0.0: return
	var remaining := delta
	while remaining > EPS and duration() > 0.0:
		var boundary := IMPACT_TIME if is_attack() and not impact_resolved else duration()
		var consumed := minf(remaining, maxf(0.0, boundary - elapsed))
		elapsed += consumed
		remaining -= consumed
		if elapsed + EPS < boundary: break
		elapsed = boundary
		if is_attack() and not impact_resolved:
			impact_resolved = true
			var player := state == Phase.PLAYER_ATTACK
			var element := selected_element if player else spec.element
			var defender := spec.element if player else player_affinity
			var amount := Element.damage_for(element, defender)
			if player:
				enemy_hp = maxi(0, enemy_hp - amount)
				attacks += 1
			else:
				damage += mini(player_hp, amount)
				player_hp = maxi(0, player_hp - amount)
			_emit(CombatEvent.Kind.PLAYER_HIT if player else CombatEvent.Kind.ENEMY_HIT, element, Element.resolve(element, defender), amount)
		else:
			match state:
				Phase.PLAYER_ATTACK: _enter(Phase.WON if enemy_hp == 0 else Phase.ENEMY_TURN)
				Phase.ENEMY_TURN: _enter(Phase.ENEMY_ATTACK)
				Phase.ENEMY_ATTACK:
					if player_hp == 0: _enter(Phase.LOST)
					else:
						turn_number += 1
						_enter(Phase.PLAYER_TURN)

func prepare_resume() -> void:
	# Pausing preserves the exact impact/recovery boundary, without replay.
	pass

func drain_events() -> Array[CombatEvent]:
	var result: Array[CombatEvent] = events.duplicate()
	events.clear()
	return result

func _emit(kind: CombatEvent.Kind, element: Element.Type = Element.Type.NONE, matchup: Element.Matchup = Element.Matchup.NEUTRAL, amount := 0) -> void:
	var event := CombatEvent.new()
	event.kind = kind
	event.element = element
	event.matchup = matchup
	event.damage = amount
	event.turn = turn_number
	event.player_hp = player_hp
	event.enemy_hp = enemy_hp
	events.append(event)
	if kind in [CombatEvent.Kind.PLAYER_HIT, CombatEvent.Kind.ENEMY_HIT]:
		combat_log.append("T%d %s %s · %s · %d dmg" % [turn_number, "You" if kind == CombatEvent.Kind.PLAYER_HIT else "Foe", Element.label(element), Element.Matchup.keys()[matchup], amount])
		if combat_log.size() > 3: combat_log.pop_front()

func _enter(next: Phase) -> void:
	state = next
	elapsed = 0.0
	if is_attack(): impact_resolved = false
	if terminal(): _emit(CombatEvent.Kind.WON if state == Phase.WON else CombatEvent.Kind.LOST)
