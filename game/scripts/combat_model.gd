class_name CombatModel
extends RefCounted
const EncounterData = preload("res://scripts/data/encounter_spec.gd")
## Sole damage authority. Time advances presentation only, never a player's choice.
enum Phase { READY, PLAYER_TURN, PLAYER_ATTACK, ENEMY_TURN, ENEMY_ATTACK, WON, LOST }
const ATTACK_TIME := 0.6
const IMPACT_TIME := 0.3
const ENEMY_TURN_TIME := 0.35
const EPS := 0.000000001
# Runtime initialization avoids Resource/script compile-order cycles on fresh boot.
static var DEFAULT_SPEC: EncounterSpec = load("res://data/encounters/gate_guard.tres")
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
var weapon_run: RunModel
var last_roll := 0
var last_bonus := 0
var last_level := 0
var combat_log: Array[String] = []

func reset() -> void:
	configure(DEFAULT_SPEC, 5, 5)

func configure(encounter: EncounterSpec, hp: int, max_hp: int, affinity: Element.Type = Element.Type.NONE) -> void:
	weapon_run = null
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
	if weapon_run != null and weapon_run.techniques[element] == 0: return false
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
			var element := selected_element if player else intent_element()
			var defender := spec.element if player else player_affinity
			var amount := Element.damage_for(element, defender)
			if player and weapon_run != null:
				last_roll = weapon_run.roll_weapon()
				last_bonus = 1 + last_roll % 2 if element == weapon_run.equipped_weapon().element else 0
				last_level = weapon_run.techniques[element]
				amount = last_roll + last_bonus + last_level - 1 + int(Element.resolve(element, defender))
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
	if kind == CombatEvent.Kind.PLAYER_HIT and weapon_run != null:
		event.roll = last_roll
		event.weapon_bonus = last_bonus
		event.technique_level = last_level
		event.matchup_bonus = int(matchup)
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

func enemy_intent() -> Dictionary:
	return {"element": intent_element(), "name": intent_name(), "damage": 0 if terminal() else mini(player_hp, Element.damage_for(intent_element(), player_affinity))}

func attack_forecast(element: Element.Type) -> Dictionary:
	if state != Phase.PLAYER_TURN or element not in [Element.Type.FIRE, Element.Type.WATER, Element.Type.EARTH, Element.Type.WIND]: return {}
	if weapon_run != null:
		if weapon_run.techniques[element] == 0: return {}
		var level := weapon_run.techniques[element]
		var same: bool = element == weapon_run.equipped_weapon().element
		var matchup := int(Element.resolve(element, spec.element))
		var low := 1 + (2 if same else 0) + level - 1 + matchup
		var high := 4 + (1 if same else 0) + level - 1 + matchup
		return {"damage": low, "min": low, "max": high, "lethal": low >= enemy_hp, "reply": 0 if low >= enemy_hp else enemy_intent().damage, "matchup": matchup, "range": "%d–%d" % [low,high]}
	var amount := mini(enemy_hp, Element.damage_for(element, spec.element))
	return {"damage": amount, "lethal": amount == enemy_hp,
		"reply": 0 if amount == enemy_hp else enemy_intent().damage,
		"matchup": Element.resolve(element, spec.element)}

func intent_element() -> Element.Type:
	return spec.element if spec.attack_elements.is_empty() else spec.attack_elements[(turn_number-1) % spec.attack_elements.size()] as Element.Type

func intent_name() -> String:
	return "Strike" if spec.attack_names.is_empty() else spec.attack_names[(turn_number-1) % spec.attack_names.size()]

func configure_weapon(owner_run: RunModel) -> void:
	weapon_run = owner_run
