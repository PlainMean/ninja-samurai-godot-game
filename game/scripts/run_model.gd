class_name RunModel
extends RefCounted
enum State { TITLE, INTRO, FIGHT, INTERMISSION, CLEARED, FAILED }
const ENCOUNTERS: Array[EncounterSpec] = [
	preload("res://data/encounters/gate_guard.tres"),
	preload("res://data/encounters/courtyard_retainer.tres"),
	preload("res://data/encounters/dojo_master.tres")]
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
	return ENCOUNTERS[encounter_index]

func begin_run() -> bool:
	if state not in [State.TITLE, State.CLEARED, State.FAILED]: return false
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
	combat.start()
	terminal_handoff = false
	state = State.FIGHT
	return true

func resolve_encounter(combat: CombatModel) -> bool:
	if state != State.FIGHT or terminal_handoff or not combat.terminal(): return false
	terminal_handoff = true
	results.append({"name": spec().display_name, "won": combat.state == CombatModel.Phase.WON, "attacks": combat.attacks, "damage": combat.damage})
	hp = combat.player_hp
	attacks += combat.attacks
	damage += combat.damage
	if combat.state == CombatModel.Phase.LOST:
		loss_hint = "WIND deals 2 damage to WATER.\nMend restores health between fights."
		state = State.FAILED
	else:
		seals += 1
		reward_claimed = false
		state = State.CLEARED if seals == 3 else State.INTERMISSION
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
	for i in range(3):
		result.append("SEALED" if i < seals else ("NEXT" if i == encounter_index else "LOCKED"))
	return result

func journey_text() -> String:
	if state == State.CLEARED:
		return "The seals open the moonlit archive.\nYour training becomes its next legend."
	if state == State.INTERMISSION:
		return "Shrine of renewal\n%d attacks · %d damage taken" % [results.back().attacks, results.back().damage] if not results.is_empty() else "Shrine of renewal\nOne gift before the next guardian."
	if state == State.FAILED:
		return "The archive waits.\nEvery new run begins at the gate."
	return "Gate %s  ·  Court %s\nMaster %s" % route_status()
