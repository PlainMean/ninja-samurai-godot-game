class_name RunModel
extends RefCounted
const EncounterData = preload("res://scripts/data/encounter_spec.gd")
enum State { TITLE, INTRO, FIGHT, INTERMISSION, CLEARED, FAILED, MAP, LOADOUT, LOOT, TRAINING, RECRUIT }
# Load after scripts compile: const preloads can instantiate uncompiled Resource scripts
# when the main scene (rather than the test runner) is the first entry point.
static var ENCOUNTERS: Array[EncounterSpec] = [
	load("res://data/encounters/gate_guard.tres"),
	load("res://data/encounters/fire_rival.tres"),
	load("res://data/encounters/earth_sentinel.tres"),
	load("res://data/encounters/wind_assassin.tres"),
	load("res://data/encounters/courtyard_retainer.tres"),
	load("res://data/encounters/ember_monk.tres"),
	load("res://data/encounters/mixed_elite.tres"),
	load("res://data/encounters/dojo_master.tres")]
const HeroData = preload("res://scripts/data/hero_spec.gd")
static var COMPANION: HeroSpec = load("res://data/heroes/kira.tres")
var first_boss_defeated := false
var companion_joined := false
var companion_hp := 0
var companion_ability: StringName = &"support_strike"
var companion_level := 0
var companion_trained := false
var after_recruit: State = State.TITLE
var state: State = State.TITLE
var encounter_index := 0
var max_hp := 5
var hp := 5
var seals := 0
var upgrades: Array[StringName] = []
var results: Array[Dictionary] = []
var attacks := 0
var damage := 0
var reward_claimed := false
var terminal_handoff := false
var loss_hint := "WIND is EFFECTIVE against WATER."

func spec() -> EncounterSpec:
	return area_encounters[current_node] if area_mode else ENCOUNTERS[encounter_index]

func begin_run() -> bool:
	if state not in [State.TITLE, State.CLEARED, State.FAILED]: return false
	first_boss_defeated = false
	companion_joined = false
	companion_hp = 0
	companion_ability = COMPANION.ability_id
	companion_level = 0
	companion_trained = false
	after_recruit = State.TITLE
	area_mode = false
	pending_loot = -1
	current_node = 0
	equipped = 0
	cleared_nodes.clear()
	inventory.clear()
	techniques.assign([0,0,0,0,0])
	rng_state = initial_seed
	encounter_index = 0
	max_hp = 5
	hp = 5
	seals = 0
	upgrades.clear()
	results.clear()
	attacks = 0
	damage = 0
	reward_claimed = false
	terminal_handoff = false
	loss_hint = "WIND is EFFECTIVE against WATER."
	state = State.INTRO
	return true

func begin_encounter(combat: CombatModel) -> bool:
	if state != State.INTRO: return false
	combat.configure(spec(), hp, max_hp)
	if area_mode: combat.configure_weapon(self)
	combat.configure_companion(self)
	combat.start()
	terminal_handoff = false
	state = State.FIGHT
	return true

func resolve_encounter(combat: CombatModel) -> bool:
	if state != State.FIGHT or terminal_handoff or not combat.terminal(): return false
	terminal_handoff = true
	results.append({"name": spec().display_name, "won": combat.state == CombatModel.Phase.WON, "attacks": combat.attacks, "damage": combat.damage})
	hp = combat.player_hp
	companion_hp = combat.companion_hp
	attacks += combat.attacks
	damage += combat.damage
	if combat.state == CombatModel.Phase.LOST:
		loss_hint = "%s deals 2 damage to %s.\nMend restores health between fights." % [Element.label(Element.weakness(spec().element)), Element.label(spec().element)]
		state = State.FAILED
	else:
		seals += 1
		if area_mode:
			cleared_nodes.append(current_node)
			pending_loot = [0,4,4,1,5,5,2,2,2,3,3,3][current_node]
			if pending_loot not in inventory: inventory.append(pending_loot)
			state = State.LOOT
			_recruit_after_boss()
			return true
		reward_claimed = false
		state = State.CLEARED if seals == ENCOUNTERS.size() else State.INTERMISSION
		_recruit_after_boss()
	return true

func rewards() -> Array[StringName]:
	if state != State.INTERMISSION: return []
	return [&"mend", &"long_breath" if encounter_index == 0 else &"iron_resolve"]

func can_choose(id: StringName) -> bool:
	return state == State.INTERMISSION and not reward_claimed and id in rewards() and (id != &"mend" or hp < max_hp)

func reward_forecast(id: StringName) -> Dictionary:
	if state != State.INTERMISSION or reward_claimed or id not in rewards(): return {}
	var capacity := max_hp + (0 if id == &"mend" else 1)
	var restored := mini(capacity - hp, 2 if id == &"mend" else 1)
	return {"hp": hp + restored, "max_hp": capacity, "restored": restored, "enabled": can_choose(id)}

func reward_choices() -> Array[Dictionary]:
	var choices: Array[Dictionary] = []
	for id in rewards():
		var forecast := reward_forecast(id)
		if forecast.is_empty(): return []
		var title: String = {&"mend": "Mend", &"long_breath": "Long Breath", &"iron_resolve": "Iron Resolve"}[id]
		var detail := "Health full" if not forecast.enabled else "%d / %d → %d / %d HP" % [hp, max_hp, forecast.hp, forecast.max_hp]
		choices.append({"text": "%s\n%s" % [title, detail], "enabled": forecast.enabled})
	return choices

func next_guardian_text() -> String:
	if state != State.INTERMISSION or encounter_index >= ENCOUNTERS.size() - 1: return ""
	var next := ENCOUNTERS[encounter_index + 1]
	return "Next: %s · %d HP" % [next.display_name, next.enemy_max_hp]

func choose_reward(id: StringName) -> bool:
	var forecast := reward_forecast(id)
	if forecast.is_empty() or not forecast.enabled: return false
	reward_claimed = true
	hp = forecast.hp
	max_hp = forecast.max_hp
	upgrades.append(id)
	encounter_index += 1
	state = State.INTRO
	return true

func return_to_title() -> bool:
	if state == State.TITLE: return false
	state = State.TITLE
	begin_run()
	state = State.TITLE
	return true

func route_status() -> Array[String]:
	var result: Array[String] = []
	for i in range(ENCOUNTERS.size()):
		result.append("SEALED" if i < seals else ("NEXT" if i == encounter_index else "LOCKED"))
	return result

func journey_text() -> String:
	if area_mode:
		if state == State.CLEARED: return "Four bosses fall. The archive opens.\nYour techniques become its next legend."
		return "The four lands guard the archive.\n%d / 12 seals · %d / 4 bosses" % [seals, bosses_defeated()]
	if state == State.CLEARED:
		return "The seals open the moonlit archive.\nYour training becomes its next legend."
	if state == State.INTERMISSION:
		return "Shrine of renewal\n%d attacks · %d damage taken" % [results.back().attacks, results.back().damage] if not results.is_empty() else "Shrine of renewal\nOne gift before the next guardian."
	if state == State.FAILED:
		return "The archive waits.\nEvery new run begins at the gate."
	return "1 %s · 2 %s · 3 %s · 4 %s\n5 %s · 6 %s · 7 %s · 8 %s\n✓ sealed · NOW next · — locked" % route_status().map(func(status): return {"SEALED": "✓", "NEXT": "NOW", "LOCKED": "—"}[status])

# The original eight-seal campaign remains available through begin_run().
const AREA_ENCOUNTER_PATHS = [
	"res://data/encounters/areas/cinder_rival.tres",
	"res://data/encounters/areas/ash_monk.tres",
	"res://data/encounters/areas/ash_shogun.tres",
	"res://data/encounters/areas/gate_guard.tres",
	"res://data/encounters/areas/twin_cut_retainer.tres",
	"res://data/encounters/areas/moonlit_master.tres",
	"res://data/encounters/areas/earth_sentinel.tres",
	"res://data/encounters/areas/iron_vanguard.tres",
	"res://data/encounters/areas/mountain_regent.tres",
	"res://data/encounters/areas/gale_assassin.tres",
	"res://data/encounters/areas/coast_ronin.tres",
	"res://data/encounters/areas/tempest_sovereign.tres"]
const AREA_NAMES = ["Fire Land", "Water Shrine", "Earth Marches", "Wind Coast"]
const WeaponData = preload("res://scripts/data/weapon_spec.gd")
static var WEAPONS: Array[Resource] = [
	load("res://data/weapons/cinder.tres"), load("res://data/weapons/tide.tres"),
	load("res://data/weapons/stone.tres"), load("res://data/weapons/gale.tres"),
	load("res://data/weapons/dawn.tres"), load("res://data/weapons/moon.tres")]
var area_mode := false
var area_encounters: Array[EncounterSpec] = []
var current_node := -1
var cleared_nodes: Array[int] = []
var inventory: Array[int] = []
var equipped := 0
var techniques: Array[int] = [0,0,0,0,0]
var rng_state := 1
var initial_seed := 1
var pending_loot := -1

func begin_area_run(seed_value := 1) -> void:
	area_mode = false
	state = State.TITLE
	begin_run()
	area_mode = true
	initial_seed = maxi(1, posmod(seed_value, 2147483647))
	rng_state = initial_seed
	hp = 12
	max_hp = 12
	current_node = 0
	cleared_nodes.clear()
	inventory.assign([0,1,2,3])
	equipped = 0
	techniques.assign([0,0,0,0,0])
	pending_loot = -1
	area_encounters.clear()
	for path in AREA_ENCOUNTER_PATHS:
		area_encounters.append(load(path))
	state = State.LOADOUT

func choose_loadout(sword: int, pair: Array) -> bool:
	if state != State.LOADOUT or sword not in inventory or pair.size() != 2 or pair[0] == pair[1]: return false
	for e in pair:
		if e not in [1,2,3,4]: return false
	equipped = sword
	for e in pair: techniques[e] = 1
	state = State.MAP
	return true

func area_unlocked(area: int) -> bool:
	if area < 0 or area > 3: return false
	# Ring adjacency from Fire; conquered neighbors unlock entry to a region.
	return area == 0 or ((area + 3) % 4) * 3 + 2 in cleared_nodes or ((area + 1) % 4) * 3 + 2 in cleared_nodes

func next_nodes() -> Array[int]:
	var choices: Array[int] = []
	for area in range(4):
		if not area_unlocked(area): continue
		for slot in range(3):
			var node := area * 3 + slot
			if node in cleared_nodes: continue
			if slot < 2 or (area * 3 in cleared_nodes and area * 3 + 1 in cleared_nodes): choices.append(node)
	return choices

func choose_node(node: int) -> bool:
	if state != State.MAP or node not in next_nodes(): return false
	current_node = node
	encounter_index = node
	state = State.INTRO
	return true

func equipped_weapon() -> Resource:
	return WEAPONS[equipped]

func equip_weapon(index: int) -> bool:
	if not area_mode or state not in [State.LOADOUT, State.MAP, State.LOOT, State.TRAINING] or index not in inventory: return false
	equipped = index
	return true

func finish_loot() -> bool:
	if state != State.LOOT: return false
	pending_loot = -1
	hp = max_hp
	if companion_joined: companion_hp = COMPANION.max_hp
	companion_trained = false
	state = State.TRAINING
	return true

func train(element: int) -> bool:
	if state == State.TRAINING and element == 0 and techniques.slice(1).min() == 3:
		state = State.CLEARED if cleared_nodes.size() == 12 else State.MAP
		return true
	if state != State.TRAINING or element not in [1,2,3,4] or techniques[element] >= 3: return false
	techniques[element] += 1
	state = State.CLEARED if cleared_nodes.size() == 12 else State.MAP
	return true

func roll_weapon() -> int:
	rng_state = (rng_state * 16807) % 2147483647
	return rng_state % 4 + 1

func bosses_defeated() -> int:
	return cleared_nodes.filter(func(n): return n % 3 == 2).size()

func node_label(node: int) -> String:
	return "%s · %s%s" % [AREA_NAMES[node / 3], area_encounters[node].display_name + " · " + area_encounters[node].unit.role, " · BOSS" if node % 3 == 2 else ""]

func encounter_count() -> int:
	return 12 if area_mode else ENCOUNTERS.size()

func _recruit_after_boss() -> void:
	var boss := current_node % 3 == 2 if area_mode else spec().id == &"dojo_master"
	if first_boss_defeated or not boss: return
	first_boss_defeated = true
	companion_joined = true
	companion_hp = COMPANION.max_hp
	after_recruit = state
	state = State.RECRUIT

func continue_recruit() -> bool:
	if state != State.RECRUIT: return false
	state = after_recruit
	return true

func develop_companion(ability: StringName) -> bool:
	if state != State.TRAINING or not companion_joined or companion_trained: return false
	if ability not in [&"support_strike", &"ward_pulse", &"upgrade"]: return false
	if ability == &"upgrade":
		if companion_level >= 2: return false
		companion_level += 1
	else:
		companion_ability = ability
	companion_trained = true
	return true

func companion_ability_name() -> String:
	return "Ward Pulse" if companion_ability == &"ward_pulse" else "Support Strike"
