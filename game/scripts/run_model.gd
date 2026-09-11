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

func choose_reward(id: StringName) -> bool:
	if not can_choose(id): return false
	reward_claimed = true
	match id:
		&"mend": hp = mini(max_hp, hp + 2)
		&"long_breath":
			max_hp += 1
			hp = mini(max_hp, hp + 1)
		&"iron_resolve":
			max_hp += 1
			hp = mini(max_hp, hp + 1)
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
