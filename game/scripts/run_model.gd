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
var counter_bonus_ms := 0
var upgrades: Array[StringName] = []
var counters := 0
var defenses := 0
var damage := 0
var reward_claimed := false
var terminal_handoff := false
var loss_hint := "Tap Block during CUT."

func spec() -> EncounterSpec:
	return ENCOUNTERS[encounter_index]

func begin_run() -> bool:
	if state not in [State.TITLE, State.CLEARED, State.FAILED]: return false
	encounter_index = 0
	max_hp = 5
	hp = 5
	seals = 0
	counter_bonus_ms = 0
	upgrades.clear()
	counters = 0
	defenses = 0
	damage = 0
	reward_claimed = false
	terminal_handoff = false
	loss_hint = "Tap Block during CUT."
	state = State.INTRO
	return true

func begin_encounter(combat: CombatModel) -> bool:
	if state != State.INTRO: return false
	combat.configure(spec(), hp, max_hp, counter_bonus_ms)
	combat.start()
	terminal_handoff = false
	state = State.FIGHT
	return true

func resolve_encounter(combat: CombatModel) -> bool:
	if state != State.FIGHT or terminal_handoff or not combat.terminal(): return false
	terminal_handoff = true
	hp = combat.player_hp
	counters += combat.counters
	defenses += combat.defenses
	damage += combat.damage
	if combat.state == CombatModel.Phase.LOST:
		loss_hint = "Dodge HEAVY; Block cannot stop it." if combat.strike().defense_required == StrikeSpec.Defense.DODGE else ("Block each cut. Release between taps." if combat.pattern().strikes.size() == 2 else "Tap Block during CUT, then Strike when OPEN.")
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
		&"long_breath": counter_bonus_ms = 300
		&"iron_resolve":
			max_hp = 6
			hp = mini(6, hp + 1)
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
