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
var encounter_spec: EncounterSpec = DEFAULT_SPEC
var enemies: Array[EnemyState] = []
var target_slot := 0
var reply_slot := 0
# Compatibility aliases always project the selected target.
var spec: EncounterSpec:
	get: return enemies[target_slot].spec if not enemies.is_empty() else encounter_spec
var enemy_hp: int:
	get: return enemies[target_slot].hp if not enemies.is_empty() else 3
	set(value):
		if not enemies.is_empty(): enemies[target_slot].hp = value
var selected_actor: StringName = &"main"
var auto_companion := true
var active_skill: StringName = &""
var skill_level := 0
var guard := 0
var evade := false
var cooldowns: Dictionary = {}
var run_owner: RunModel
static var SKILLS: Array[SkillSpec] = [load("res://data/skills/flame_dash.tres"), load("res://data/skills/stone_guard.tres"), load("res://data/skills/windstep.tres")]
func _init() -> void:
	configure(DEFAULT_SPEC, 5, 5)
var state: Phase = Phase.READY
var elapsed := 0.0
var player_hp := 5
var player_max_hp := 5
var player_affinity: Element.Type = Element.Type.NONE
var selected_element: Element.Type = Element.Type.NONE
var turn_number := 1
var impact_resolved := false
var attacks := 0
var damage := 0
var events: Array[CombatEvent] = []
var weapon_run: RunModel
var companion_spec: HeroSpec
var companion_hp := 0
var companion_ability: StringName = &"support_strike"
var companion_level := 0
var companion_acted := false
var ward := 0
var last_roll := 0
var last_bonus := 0
var last_level := 0
var combat_log: Array[String] = []
var last_action_summary := "Choose an actor, target and action."

func reset() -> void:
	configure(DEFAULT_SPEC, 5, 5)

func configure(encounter: EncounterSpec, hp: int, max_hp: int, affinity: Element.Type = Element.Type.NONE) -> void:
	weapon_run = null
	companion_spec = null
	companion_hp = 0
	companion_ability = &"support_strike"
	companion_level = 0
	companion_acted = false
	ward = 0
	encounter_spec = encounter
	enemies.clear()
	var sources: Array[EncounterSpec] = []
	sources.assign(encounter.party if not encounter.party.is_empty() else [encounter])
	assert(sources.size() >= 1 and sources.size() <= 3, "An encounter has one to three enemy slots")
	for source in sources:
		assert(source.party.is_empty() and source.enemy_max_hp > 0, "Party members must be non-nested living encounters")
		enemies.append(EnemyState.new(source, enemies.size()))
	target_slot = 0
	reply_slot = 0
	selected_actor = &"main"
	auto_companion = true
	active_skill = &""
	skill_level = 0
	guard = 0
	evade = false
	cooldowns.clear()
	run_owner = null
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
	last_action_summary = "Choose an actor, target and action."
	state = Phase.READY
	elapsed = 0.0

func start() -> void:
	if state == Phase.READY: _enter(Phase.PLAYER_TURN)

func request_attack(element: Element.Type) -> bool:
	if state != Phase.PLAYER_TURN or element not in [Element.Type.FIRE, Element.Type.WATER, Element.Type.EARTH, Element.Type.WIND]:
		return false
	if selected_actor == &"kira": return request_kira_attack()
	if weapon_run != null and weapon_run.techniques[element] == 0: return false
	if not _ensure_target(): return false
	active_skill = &""
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
			_resolve_impact()
		else:
			match state:
				Phase.PLAYER_ATTACK:
					if living_slots().is_empty(): _enter(Phase.WON)
					else:
						reply_slot = living_slots()[0]
						_enter(Phase.ENEMY_TURN)
				Phase.ENEMY_TURN: _enter(Phase.ENEMY_ATTACK)
				Phase.ENEMY_ATTACK:
					if player_hp == 0: _enter(Phase.LOST)
					else:
						var following := living_slots().filter(func(slot): return slot > reply_slot)
						if not following.is_empty():
							reply_slot = following[0]
							_enter(Phase.ENEMY_TURN)
						else:
							turn_number += 1
							for id in cooldowns: cooldowns[id] = maxi(0, cooldowns[id] - 1)
							guard = 0
							evade = false
							_ensure_target()
							_enter(Phase.PLAYER_TURN)

func _resolve_impact() -> void:
	if state == Phase.PLAYER_ATTACK:
		var amount := Element.damage_for(selected_element, spec.element)
		last_roll = 0
		last_bonus = 0
		last_level = 0
		if selected_actor == &"kira":
			amount = kira_damage()
		elif active_skill != &"":
			var skill := skill_spec(active_skill)
			amount = skill_damage(skill)
			guard = skill.guard + skill_level if skill.guard > 0 else 0
			evade = skill.evade
		elif weapon_run != null:
			last_roll = weapon_run.roll_weapon()
			last_bonus = 1 + last_roll % 2 if selected_element == weapon_run.equipped_weapon().element else 0
			last_level = weapon_run.techniques[selected_element]
			amount = last_roll + last_bonus + last_level - 1 + int(Element.resolve(selected_element, spec.element))
		enemy_hp = maxi(0, enemy_hp - amount)
		attacks += 1
		var kind := CombatEvent.Kind.KIRA_ATTACK if selected_actor == &"kira" else (CombatEvent.Kind.SKILL if active_skill != &"" else CombatEvent.Kind.PLAYER_HIT)
		_emit(kind, selected_element, Element.resolve(selected_element, spec.element), amount)
		last_action_summary = combat_log.back()
		if selected_actor == &"main": _companion_action()
	else:
		var element := enemies[reply_slot].intent_element(turn_number)
		var amount := Element.damage_for(element, player_affinity)
		if evade:
			evade = false
			_emit(CombatEvent.Kind.EVADE, element)
			return
		var blocked := mini(guard, amount)
		guard -= blocked
		amount = maxi(0, amount - blocked - ward)
		ward = 0
		damage += mini(player_hp, amount)
		player_hp = maxi(0, player_hp - amount)
		_emit(CombatEvent.Kind.ENEMY_HIT, element, Element.resolve(element, player_affinity), amount)
		if companion_hp > 0:
			companion_hp -= 1
			_emit(CombatEvent.Kind.COMPANION_HURT, element, Element.Matchup.NEUTRAL, 1)
			if companion_hp == 0:
				selected_actor = &"main"
				if run_owner != null: run_owner.selected_actor = &"main"

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
	event.actor = &"kira" if kind in [CombatEvent.Kind.KIRA_ATTACK, CombatEvent.Kind.COMPANION_HIT, CombatEvent.Kind.COMPANION_WARD] else (&"enemy" if kind in [CombatEvent.Kind.ENEMY_HIT,CombatEvent.Kind.COMPANION_HURT] else &"main")
	event.source_slot = reply_slot if state == Phase.ENEMY_ATTACK else -1
	event.target_actor = &"kira" if kind == CombatEvent.Kind.COMPANION_HURT else (&"main" if kind in [CombatEvent.Kind.ENEMY_HIT,CombatEvent.Kind.EVADE,CombatEvent.Kind.COMPANION_WARD] else &"enemy")
	event.target_slot = reply_slot if state == Phase.ENEMY_ATTACK else target_slot
	event.skill_id = &"tide_arc" if kind == CombatEvent.Kind.KIRA_ATTACK else (active_skill if kind == CombatEvent.Kind.SKILL else (&"windstep" if kind == CombatEvent.Kind.EVADE else &""))
	for enemy in enemies: event.party_hp.append(enemy.hp)
	event.guard = guard
	event.evade = evade
	event.cooldowns = cooldowns.duplicate()
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
	event.companion_hp = companion_hp
	events.append(event)
	if kind in [CombatEvent.Kind.KIRA_ATTACK, CombatEvent.Kind.SKILL]:
		combat_log.append("T%d %s %s → #%d · %d dmg" % [turn_number, "Kira" if selected_actor == &"kira" else "You", "Tide Arc WATER" if selected_actor == &"kira" else skill_spec(active_skill).display_name, target_slot + 1, amount])
	if kind == CombatEvent.Kind.SKILL and guard > 0: combat_log[-1] = "T%d Stone Guard · EARTH · block %d" % [turn_number,guard]
	if kind == CombatEvent.Kind.EVADE: combat_log.append("T%d Windstep · evaded #%d" % [turn_number, reply_slot + 1])
	if kind in [CombatEvent.Kind.PLAYER_HIT, CombatEvent.Kind.ENEMY_HIT]:
		combat_log.append("T%d %s %s · %s · %d dmg" % [turn_number, "You" if kind == CombatEvent.Kind.PLAYER_HIT else ("Foe" if enemies.size() == 1 else "Foe #%d" % (reply_slot + 1)), Element.label(element), Element.Matchup.keys()[matchup], amount])
	if kind in [CombatEvent.Kind.COMPANION_HIT, CombatEvent.Kind.COMPANION_WARD, CombatEvent.Kind.COMPANION_HURT]:
		var action := "WATER strike · %d dmg" % amount
		if kind == CombatEvent.Kind.COMPANION_WARD: action = "Ward Pulse · block %d" % amount
		if kind == CombatEvent.Kind.COMPANION_HURT: action = "1 fatigue · %d HP%s" % [companion_hp, " · FALLEN" if companion_hp == 0 else ""]
		combat_log.append("T%d Kira %s" % [turn_number, action])
	while combat_log.size() > (4 if companion_spec != null else 3): combat_log.pop_front()

func _enter(next: Phase) -> void:
	state = next
	elapsed = 0.0
	if is_attack(): impact_resolved = false
	if next == Phase.PLAYER_TURN:
		companion_acted = false
		active_skill = &""
	if terminal(): _emit(CombatEvent.Kind.WON if state == Phase.WON else CombatEvent.Kind.LOST)

func enemy_intent() -> Dictionary:
	return {"element": intent_element(), "name": intent_name(), "damage": 0 if terminal() else mini(player_hp, maxi(0, Element.damage_for(intent_element(), player_affinity) - predicted_ward()))}

func attack_forecast(element: Element.Type) -> Dictionary:
	if state != Phase.PLAYER_TURN or element not in [Element.Type.FIRE, Element.Type.WATER, Element.Type.EARTH, Element.Type.WIND]: return {}
	if selected_actor == &"kira": return kira_forecast()
	if weapon_run != null:
		if weapon_run.techniques[element] == 0: return {}
		var level := weapon_run.techniques[element]
		var same: bool = element == weapon_run.equipped_weapon().element
		var matchup := int(Element.resolve(element, spec.element))
		var low := 1 + (2 if same else 0) + level - 1 + matchup
		var high := 4 + (1 if same else 0) + level - 1 + matchup
		return {"damage": low, "min": low, "max": high, "lethal": low + support_damage() >= enemy_hp, "reply": reply_forecast(low + support_damage()), "matchup": matchup, "range": "%d–%d" % [low,high]}
	var amount := mini(enemy_hp, Element.damage_for(element, spec.element))
	return {"damage": amount, "lethal": amount + support_damage() >= enemy_hp,
		"reply": reply_forecast(amount + support_damage()),
		"matchup": Element.resolve(element, spec.element)}

func intent_element() -> Element.Type:
	return enemies[reply_slot if state in [Phase.ENEMY_TURN, Phase.ENEMY_ATTACK] else target_slot].intent_element(turn_number)

func intent_name() -> String:
	return enemies[reply_slot if state in [Phase.ENEMY_TURN, Phase.ENEMY_ATTACK] else target_slot].intent_name(turn_number)

func configure_weapon(owner_run: RunModel) -> void:
	weapon_run = owner_run

func configure_companion(owner_run: RunModel) -> void:
	if not owner_run.companion_joined: return
	companion_spec = owner_run.COMPANION
	companion_hp = owner_run.companion_hp
	companion_ability = owner_run.companion_ability
	companion_level = owner_run.companion_level

func support_damage() -> int:
	if not auto_companion or selected_actor != &"main" or companion_hp <= 0 or companion_ability != &"support_strike": return 0
	return companion_spec.attack_min + companion_level + int(Element.resolve(companion_spec.element, spec.element))

func _companion_action() -> void:
	# Same impact boundary, strictly after player hit and before the enemy reply.
	# No RNG consumption, and either lethal player/support hit suppresses the reply.
	if not auto_companion or enemy_hp == 0 or companion_hp <= 0 or companion_acted: return
	companion_acted = true
	if companion_ability == &"ward_pulse":
		ward = 1 + companion_level
		_emit(CombatEvent.Kind.COMPANION_WARD, companion_spec.element, Element.Matchup.NEUTRAL, ward)
	else:
		var amount := support_damage()
		enemy_hp = maxi(0, enemy_hp - amount)
		_emit(CombatEvent.Kind.COMPANION_HIT, companion_spec.element, Element.resolve(companion_spec.element, spec.element), amount)

func companion_status() -> String:
	if companion_spec == null: return ""
	var ability := "Ward Pulse" if companion_ability == &"ward_pulse" else "Support Strike"
	var availability := "FALLEN" if companion_hp == 0 else ("Tide Arc ready" if selected_actor == &"kira" else ("Auto off" if not auto_companion else ("Ready next turn" if companion_acted else "Ready · auto")))
	return "ALLY Kira · WATER · %d/%d HP\n%s L%d · %s" % [companion_hp, companion_spec.max_hp, ability, companion_level + 1, availability]

func predicted_ward() -> int:
	if ward > 0: return ward
	if auto_companion and selected_actor == &"main" and companion_hp > 0 and companion_ability == &"ward_pulse" and not companion_acted:
		return 1 + companion_level
	return 0

func configure_actions(owner_run: RunModel) -> void:
	run_owner = owner_run
	skill_level = owner_run.skill_level
	auto_companion = owner_run.auto_companion
	selected_actor = owner_run.selected_actor if companion_hp > 0 else &"main"

func living_slots() -> Array[int]:
	var result: Array[int] = []
	for enemy in enemies:
		if enemy.hp > 0: result.append(enemy.slot)
	return result

func _ensure_target() -> bool:
	var living := living_slots()
	if living.is_empty(): return false
	if target_slot not in living: target_slot = living[0]
	return true

func select_target(slot: int) -> bool:
	if state != Phase.PLAYER_TURN or slot not in living_slots(): return false
	target_slot = slot
	return true

func select_actor(actor: StringName) -> bool:
	if state != Phase.PLAYER_TURN or actor not in [&"main", &"kira"]: return false
	if actor == &"kira" and (companion_spec == null or companion_hp <= 0): return false
	selected_actor = actor
	if run_owner != null: run_owner.selected_actor = actor
	return true

func set_auto_companion(enabled: bool) -> bool:
	if state != Phase.PLAYER_TURN: return false
	auto_companion = enabled
	if run_owner != null: run_owner.auto_companion = enabled
	return true

func kira_damage() -> int:
	return 3 + companion_level + int(Element.resolve(Element.Type.WATER, spec.element))

func request_kira_attack() -> bool:
	if state != Phase.PLAYER_TURN or selected_actor != &"kira" or companion_spec == null or companion_hp <= 0 or not _ensure_target(): return false
	selected_element = Element.Type.WATER
	active_skill = &"tide_arc"
	companion_acted = true
	_enter(Phase.PLAYER_ATTACK)
	return true

func skill_spec(id: StringName) -> SkillSpec:
	for skill in SKILLS:
		if skill.id == id: return skill
	return null

func skill_available(id: StringName) -> bool:
	return state == Phase.PLAYER_TURN and selected_actor == &"main" and skill_spec(id) != null and cooldowns.get(id, 0) == 0 and not living_slots().is_empty()

func skill_damage(skill: SkillSpec) -> int:
	return skill.base_damage + skill_level + int(Element.resolve(skill.element, spec.element)) if skill.base_damage > 0 else 0

func request_skill(id: StringName) -> bool:
	if not skill_available(id) or not _ensure_target(): return false
	var skill := skill_spec(id)
	selected_element = skill.element
	active_skill = id
	cooldowns[id] = skill.cooldown + 1
	_enter(Phase.PLAYER_ATTACK)
	return true

func reply_forecast(target_damage: int, block := 0, skip_first := false) -> int:
	var total := 0
	var pulse := ward if target_damage >= enemy_hp else predicted_ward()
	for enemy in enemies:
		if enemy.hp <= 0 or (enemy.slot == target_slot and target_damage >= enemy.hp): continue
		if skip_first:
			skip_first = false
			continue
		var amount := Element.damage_for(enemy.intent_element(turn_number), player_affinity)
		var absorbed := mini(block, amount)
		block -= absorbed
		total += maxi(0, amount - absorbed - pulse)
		pulse = 0
	return mini(player_hp, total)

func kira_forecast() -> Dictionary:
	if companion_hp <= 0 or companion_spec == null or state != Phase.PLAYER_TURN: return {}
	var amount := kira_damage()
	return {"damage": amount, "min": amount, "max": amount, "range": str(amount), "lethal": amount >= enemy_hp, "reply": reply_forecast(amount), "matchup": Element.resolve(Element.Type.WATER, spec.element)}

func skill_forecast(id: StringName) -> Dictionary:
	var skill := skill_spec(id)
	if skill == null: return {}
	var amount := skill_damage(skill)
	var block := skill.guard + skill_level if skill.guard > 0 else 0
	return {"damage": amount, "guard": block, "evade": skill.evade, "cooldown": cooldowns.get(id, 0), "available": skill_available(id), "reply": reply_forecast(amount + support_damage(), block, skill.evade)}
