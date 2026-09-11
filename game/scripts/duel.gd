extends Control
const StrikeData = preload("res://scripts/data/strike_spec.gd")
const PatternData = preload("res://scripts/data/pattern_spec.gd")
const EncounterData = preload("res://scripts/data/encounter_spec.gd")
const Combat = preload("res://scripts/combat_model.gd")
const Run = preload("res://scripts/run_model.gd")
const Layout = preload("res://scripts/layout_helper.gd")
var model := Combat.new()
var run := Run.new()
var paused := false
var last_tick_usec := 0
var clock: Callable = func(): return Time.get_ticks_usec()
var presentation_time := 0.0
var terminal_time := 0.0
var feedback_time := 0.0
var feedback_text := ""
var hurt_player := -1.0
var hurt_enemy := -1.0
var defense_time := 0.0
@onready var ninja = $Arena/Ninja
@onready var samurai = $Arena/Samurai
@onready var hud = $HUD
@onready var modal = $Modal
@onready var block_button = $HUD/Actions/BlockButton
@onready var dodge_button = $HUD/Actions/DodgeButton
@onready var strike_button = $HUD/Actions/StrikeButton
@onready var pause_button = $HUD/PauseButton
@onready var primary_button = $Modal/Panel/Content/PrimaryButton
@onready var choice_a = $Modal/Panel/Content/ChoiceAButton
@onready var choice_b = $Modal/Panel/Content/ChoiceBButton
@onready var secondary_button = $Modal/Panel/Content/SecondaryButton
func _ready() -> void:
	block_button.activated.connect(_block)
	dodge_button.activated.connect(_dodge)
	strike_button.activated.connect(_strike)
	pause_button.activated.connect(pause_duel)
	primary_button.activated.connect(_primary)
	choice_a.activated.connect(func(): _reward(&"mend"))
	choice_b.activated.connect(func(): _reward(&"long_breath" if run.encounter_index == 0 else &"iron_resolve"))
	secondary_button.activated.connect(_title)
	$BrowserLifecycle.pause_requested.connect(pause_duel)
	get_viewport().size_changed.connect(_layout)
	_layout()
	last_tick_usec = clock.call()
	_refresh()
func _layout() -> void:
	var available := Vector2(DisplayServer.window_get_size()) if OS.has_feature("web") else get_viewport_rect().size
	if OS.has_feature("web"):
		var desired := Vector2i(390, int(Layout.metrics(available).height))
		if get_window().content_scale_size != desired: get_window().content_scale_size = desired
	Layout.apply(self, available)
func _process(delta: float) -> void:
	_sync_time(delta)
	_refresh()
func _sync_time(engine_delta := 0.0) -> void:
	var now: int = clock.call()
	var gap := float(now - last_tick_usec) / 1000000.0 if last_tick_usec > 0 else 0.0
	last_tick_usec = now
	if paused: return
	if run.state != Run.State.FIGHT:
		if gap >= 0 and gap <= 0.25:
			presentation_time += gap
			$Arena/Effects.advance(gap)
		return
	if engine_delta > 0.25 or gap > 0.25:
		pause_duel()
		return
	advance(maxf(0.0, gap))
func advance(delta: float) -> void:
	if paused or run.state != Run.State.FIGHT or not is_finite(delta) or delta <= 0: return
	var remaining := delta
	while remaining > Combat.EPS and run.state == Run.State.FIGHT:
		var boundary := 0.4 - terminal_time if model.terminal() else model.duration() - model.elapsed
		if model.is_attack() and not model.impact_resolved: boundary = Combat.IMPACT_TIME - model.elapsed
		var consumed := minf(remaining, boundary)
		presentation_time += consumed
		feedback_time = maxf(0.0, feedback_time - consumed)
		$Arena/Effects.advance(consumed)
		remaining -= consumed
		if model.terminal():
			terminal_time = minf(0.4, terminal_time + consumed)
			if terminal_time + Combat.EPS >= 0.4 and run.resolve_encounter(model):
				_cancel_pointers()
				if model.state == Combat.Phase.WON: $Arena/Effects.trigger(&"seal", $Arena/Effects.to_local(hud.get_node("Seal%d" % (run.seals - 1)).get_global_rect().get_center()))
		else:
			model.step(consumed)
			_consume_events()
	_refresh()

func _consume_events() -> void:
	for event in model.drain_events():
		match event.kind:
			CombatEvent.Kind.DEFENSE_SELECTED:
				defense_time = presentation_time
				feedback_text = "Guard set" if event.selected_defense == StrikeSpec.Defense.BLOCK else "Dodge set"
			CombatEvent.Kind.DEFENDED:
				feedback_text = "Blocked!" if event.selected_defense == StrikeSpec.Defense.BLOCK else "Dodged!"
				$Arena/Effects.trigger(&"block" if event.selected_defense == StrikeSpec.Defense.BLOCK else &"dodge", Vector2(195,390) if event.selected_defense == StrikeSpec.Defense.BLOCK else Vector2(111,444))
			CombatEvent.Kind.DAMAGE:
				hurt_player = presentation_time
				feedback_text = "Hit! Dodge HEAVY." if event.defense_required == StrikeSpec.Defense.DODGE else "Hit! Block each CUT."
				$Arena/Effects.trigger(&"hit", Vector2(195,390))
			CombatEvent.Kind.COUNTER:
				hurt_enemy = presentation_time
				feedback_text = "Counter landed!"
				$Arena/Effects.trigger(&"hit", Vector2(195,390))
			CombatEvent.Kind.WON, CombatEvent.Kind.LOST: terminal_time = 0.0
		feedback_time = 0.65
func _block() -> void: _action(StrikeSpec.Defense.BLOCK)
func _dodge() -> void: _action(StrikeSpec.Defense.DODGE)
func _action(defense: StrikeSpec.Defense) -> void:
	_sync_time()
	if not paused and run.state == Run.State.FIGHT: model.request_defense(defense)
	_consume_events()
	_refresh()
func _strike() -> void:
	_sync_time()
	if not paused and run.state == Run.State.FIGHT: model.request_strike()
	_refresh()
func _clear_presentation() -> void:
	terminal_time = 0.0
	presentation_time = 0.0
	feedback_time = 0.0
	feedback_text = ""
	hurt_player = -1.0
	hurt_enemy = -1.0
	defense_time = 0.0
	$Arena/Effects.clear()
func _primary() -> void:
	_cancel_pointers()
	last_tick_usec = clock.call()
	if paused: paused = false
	elif run.state in [Run.State.TITLE, Run.State.CLEARED, Run.State.FAILED]:
		run.begin_run()
		model.reset()
		_clear_presentation()
	elif run.state == Run.State.INTRO:
		run.begin_encounter(model)
		_clear_presentation()
	_refresh()
func _reward(id: StringName) -> void:
	if run.choose_reward(id):
		_cancel_pointers()
		model.configure(run.spec(), run.hp, run.max_hp, run.counter_bonus_ms)
		_clear_presentation()
	_refresh()
func _title() -> void:
	run.return_to_title()
	paused = false
	model.reset()
	_cancel_pointers()
	_clear_presentation()
	_refresh()
func pause_duel() -> void:
	_cancel_pointers()
	if paused or run.state != Run.State.FIGHT: return
	paused = true
	model.prepare_resume()
	model.drain_events()
	_refresh()
func _cancel_pointers() -> void:
	for button in [block_button,dodge_button,strike_button,pause_button,primary_button,choice_a,choice_b,secondary_button]:
		if is_instance_valid(button): button.cancel_pointer()
func snapshot() -> Dictionary:
	var cue := "Read the cue."
	var icon := &"cut"
	if model.strike().defense_required == StrikeSpec.Defense.DODGE: icon = &"heavy"
	elif model.pattern().strikes.size() == 2: icon = &"double_cut"
	match model.state:
		Combat.Phase.REST: cue = "Get ready…"
		Combat.Phase.TELEGRAPH:
			cue = "HEAVY — DODGE" if icon == &"heavy" else "CUT %d / %d — BLOCK" % [model.strike_index + 1, model.pattern().strikes.size()]
		Combat.Phase.ENEMY_ATTACK: cue = "HEAVY" if icon == &"heavy" else "CUT %d / %d" % [model.strike_index + 1, model.pattern().strikes.size()]
		Combat.Phase.COUNTER_WINDOW: cue = "OPEN — STRIKE"
		Combat.Phase.PLAYER_ATTACK: cue = "Counterattack!"
		Combat.Phase.WON: cue = "Seal earned"
		Combat.Phase.LOST: cue = "Run ended"
	return {"hp": model.player_hp if run.state == Run.State.FIGHT else run.hp, "max_hp": run.max_hp,
		"enemy_hp": model.enemy_hp, "enemy_max_hp": run.spec().enemy_max_hp, "enemy_name": run.spec().display_name,
		"seals": run.seals, "encounter": run.encounter_index + 1, "cue": cue, "icon": icon,
		"feedback": feedback_text if feedback_time > 0 else "",
		"technique": " · ".join(run.upgrades.map(func(id): return {&"mend": "Mend", &"long_breath": "Long Breath", &"iron_resolve": "Iron Resolve"}[id])) if not run.upgrades.is_empty() else "Block CUT. Dodge HEAVY.\nStrike only when OPEN.",
		"progress": 100.0 * (1.0 - model.elapsed / model.duration()) if model.state in [Combat.Phase.TELEGRAPH, Combat.Phase.COUNTER_WINDOW] else 0.0}
func _refresh() -> void:
	var show_modal := paused or run.state != Run.State.FIGHT
	if modal.visible != show_modal: _cancel_pointers()
	modal.visible = show_modal
	block_button.disabled = show_modal or model.state != Combat.Phase.TELEGRAPH or model.block_latched
	dodge_button.disabled = block_button.disabled
	strike_button.disabled = show_modal or model.state != Combat.Phase.COUNTER_WINDOW
	pause_button.disabled = show_modal
	hud.present(snapshot())
	$Arena.present(run.spec(), presentation_time)
	_present_fighters()
	var heading := ""
	var instructions := ""
	var primary := ""
	var choices: Array = []
	if paused:
		heading = "Run paused"
		instructions = "Tap Resume when ready.\nReturn to title discards this run."
		primary = "Resume"
	else:
		match run.state:
			Run.State.TITLE:
				heading = "Three Seals"
				instructions = "Read the cue. Defend. Counter.\nChallenge three dojo guardians."
				primary = "Begin run"
			Run.State.INTRO:
				heading = run.spec().display_name
				instructions = "%d / 3\n%s" % [run.encounter_index + 1, run.spec().intro_text]
				primary = "Fight"
			Run.State.INTERMISSION:
				heading = "Choose a technique"
				instructions = "Seal %d / 3 earned · HP %d / %d" % [run.seals,run.hp,run.max_hp]
				choices = [{"text": "Mend — Health full" if run.hp == run.max_hp else "Mend — Restore 2 HP\n%d → %d / %d HP" % [run.hp, mini(run.max_hp,run.hp+2),run.max_hp], "enabled": run.can_choose(&"mend")},
					{"text": "Long Breath\nCounter windows +300 ms" if run.encounter_index == 0 else "Iron Resolve — Max HP +1\n%d / %d → %d / 6 HP" % [run.hp,run.max_hp,mini(6,run.hp+1)], "enabled": true}]
			Run.State.CLEARED:
				heading = "Dojo cleared"
				instructions = "Seals 3 / 3 · HP %d / %d\n%d counters · %d defenses" % [run.hp,run.max_hp,run.counters,run.defenses]
				primary = "New run"
			Run.State.FAILED:
				heading = "Run ended"
				instructions = "Seals %d / 3\n%s" % [run.seals,run.loss_hint]
				primary = "Retry run"
	modal.present(heading,instructions,primary,choices,paused)
func _present_fighters() -> void:
	for fighter in [ninja,samurai]:
		var player: bool = fighter == ninja
		var attack: bool = model.state == (Combat.Phase.PLAYER_ATTACK if player else Combat.Phase.ENEMY_ATTACK)
		var defeated: bool = model.state == (Combat.Phase.LOST if player else Combat.Phase.WON)
		var hurt: float = hurt_player if player else hurt_enemy
		var tag := &"idle"
		var time := presentation_time
		if defeated:
			tag = &"defeat"
			time = terminal_time
		elif hurt >= 0 and presentation_time - hurt < 0.2:
			tag = &"hurt"
			time = presentation_time - hurt
		elif attack:
			tag = &"attack"
			time = model.elapsed
		elif player and model.block_latched and model.state in [Combat.Phase.TELEGRAPH,Combat.Phase.ENEMY_ATTACK]:
			tag = &"guard" if model.selected_defense == StrikeSpec.Defense.BLOCK else &"dodge"
			time = presentation_time - defense_time
		elif not player and model.state == Combat.Phase.TELEGRAPH:
			tag = &"warn_heavy" if model.strike().defense_required == StrikeSpec.Defense.DODGE else &"warn_cut"
		fighter.present(tag,time,attack,model.elapsed,player and model.state == Combat.Phase.ENEMY_ATTACK and model.selected_defense == StrikeSpec.Defense.DODGE)
