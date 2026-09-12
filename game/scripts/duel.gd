extends Control
const EncounterData = preload("res://scripts/data/encounter_spec.gd")
const Combat = preload("res://scripts/combat_model.gd")
const Run = preload("res://scripts/run_model.gd")
const Layout = preload("res://scripts/layout_helper.gd")
var model := Combat.new()
var run := Run.new()
var area_campaign := true
var area_panel: Control
var map_area := 0
var starting_sword := 0
var inventory_open := false
var area_signature := ""
var paused := false
var last_tick_usec := 0
var clock: Callable = func(): return Time.get_ticks_usec()
var presentation_time := 0.0
var terminal_time := 0.0
var feedback_time := 0.0
var feedback_text := ""
var hurt_player := -1.0
var hurt_enemy := -1.0
@onready var ninja = $Arena/Ninja
@onready var samurai = $Arena/Samurai
@onready var hud = $HUD
@onready var modal = $Modal
@onready var attack_buttons: Array[Button] = [$HUD/Actions/FireButton, $HUD/Actions/WaterButton, $HUD/Actions/EarthButton, $HUD/Actions/WindButton]
@onready var pause_button = $HUD/PauseButton
@onready var primary_button = $Modal/Panel/Content/PrimaryButton
@onready var choice_a = $Modal/Panel/Content/ChoiceAButton
@onready var choice_b = $Modal/Panel/Content/ChoiceBButton
@onready var secondary_button = $Modal/Panel/Content/SecondaryButton
func _ready() -> void:
	for i in range(4):
		attack_buttons[i].activated.connect(_attack.bind((i + 1) as Element.Type))
	pause_button.activated.connect(pause_duel)
	primary_button.activated.connect(_primary)
	choice_a.activated.connect(func(): _reward(&"mend"))
	choice_b.activated.connect(func(): _reward(&"long_breath" if run.encounter_index == 0 else &"iron_resolve"))
	secondary_button.activated.connect(_title)
	$BrowserLifecycle.pause_requested.connect(pause_duel)
	get_viewport().size_changed.connect(_layout)
	area_panel = preload("res://scripts/area_panel.gd").new()
	modal.add_child(area_panel)
	area_panel.action.connect(_area_action)
	_layout()
	last_tick_usec = clock.call()
	_refresh()
func _layout() -> void:
	var available := Vector2(DisplayServer.window_get_size()) if OS.has_feature("web") else get_viewport_rect().size
	if OS.has_feature("web"):
		var desired := Vector2i(390, int(Layout.metrics(available).height))
		if get_window().content_scale_size != desired: get_window().content_scale_size = desired
	Layout.apply(self, available)
	if area_panel != null:
		area_panel.position.y = 120 if Layout.metrics(available).compact else 142
		area_panel.size.y = 630 if Layout.metrics(available).compact else 660
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
		var boundary := 0.4 - terminal_time if model.terminal() else (model.duration() - model.elapsed if model.duration() > 0 else remaining)
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
			CombatEvent.Kind.ENEMY_HIT:
				hurt_player = presentation_time
				$Arena/Effects.trigger_element(event.element, Vector2(138,386))
			CombatEvent.Kind.PLAYER_HIT:
				hurt_enemy = presentation_time
				$Arena/Effects.trigger_element(event.element, Vector2(252,386))
			CombatEvent.Kind.WON, CombatEvent.Kind.LOST: terminal_time = 0.0
		feedback_time = 0.65
func _attack(element: Element.Type) -> void:
	# Input eligibility is sampled before synchronizing: a tap during resolution
	# cannot become a queued attack when that synchronization reaches PLAYER_TURN.
	var eligible := not paused and run.state == Run.State.FIGHT and model.state == Combat.Phase.PLAYER_TURN
	_sync_time()
	if eligible and not paused and run.state == Run.State.FIGHT: model.request_attack(element)
	_refresh()
func _clear_presentation() -> void:
	terminal_time = 0.0
	presentation_time = 0.0
	feedback_time = 0.0
	feedback_text = ""
	hurt_player = -1.0
	hurt_enemy = -1.0
	$Arena/Effects.clear()
func _primary() -> void:
	_cancel_pointers()
	last_tick_usec = clock.call()
	if paused: paused = false
	elif run.state in [Run.State.TITLE, Run.State.CLEARED, Run.State.FAILED]:
		if area_campaign:
			run.begin_area_run()
			map_area = 0
			starting_sword = 0
			inventory_open = false
		else: run.begin_run()
		model.reset()
		_clear_presentation()
	elif run.state == Run.State.INTRO:
		run.begin_encounter(model)
		_clear_presentation()
	_refresh()
func _reward(id: StringName) -> void:
	if run.choose_reward(id):
		_cancel_pointers()
		model.configure(run.spec(), run.hp, run.max_hp)
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
	for button in attack_buttons + [pause_button,primary_button,choice_a,choice_b,secondary_button]:
		if is_instance_valid(button): button.cancel_pointer()
func snapshot() -> Dictionary:
	var cue: String = {Combat.Phase.READY: "Choose your element", Combat.Phase.PLAYER_TURN: "PLAYER TURN", Combat.Phase.PLAYER_ATTACK: "Resolving your attack", Combat.Phase.ENEMY_TURN: "ENEMY TURN", Combat.Phase.ENEMY_ATTACK: "Resolving %s attack" % Element.label(model.enemy_intent().element), Combat.Phase.WON: "Seal earned", Combat.Phase.LOST: "Run ended"}[model.state]
	var selected := Element.label(model.selected_element)
	var result := "Choose FIRE, WATER, EARTH or WIND"
	if model.selected_element != Element.Type.NONE:
		result = "%s · %s · %d damage" % [selected, Element.Matchup.keys()[Element.resolve(model.selected_element, run.spec().element)], Element.damage_for(model.selected_element, run.spec().element)]
	return {"levels": run.techniques if run.area_mode else [1,1,1,1,1], "hp": model.player_hp if run.state == Run.State.FIGHT else run.hp, "max_hp": run.max_hp,
		"enemy_hp": model.enemy_hp, "enemy_max_hp": run.spec().enemy_max_hp, "enemy_role": run.spec().unit.role if run.spec().unit != null else "", "enemy_name": ("BOSS · " if run.area_mode and run.current_node % 3 == 2 else "") + run.spec().display_name,
		"total": 12 if run.area_mode else run.encounter_count(), "seals": run.seals, "encounter": run.encounter_index + 1, "cue": cue,
		"feedback": "\n".join(model.combat_log), "technique": ("%s · %s\nRoll 1–4 · same +1–2\nTechnique +0–2 · matchup +0–1" % [run.equipped_weapon().display_name, Element.label(run.equipped_weapon().element)]) if run.area_mode else "Selected: %s\n%s" % [selected, result],
		"turn": model.turn_number, "area": run.AREA_NAMES[run.current_node / 3] if run.area_mode else "", "enemy_element": Element.label(run.spec().element), "affinity": Element.label(model.player_affinity), "weakness": Element.label(Element.weakness(run.spec().element)),
		"intent": model.enemy_intent(), "forecasts": [model.attack_forecast(Element.Type.FIRE), model.attack_forecast(Element.Type.WATER), model.attack_forecast(Element.Type.EARTH), model.attack_forecast(Element.Type.WIND)]}
func _refresh() -> void:
	var show_modal := paused or run.state != Run.State.FIGHT
	if modal.visible != show_modal: _cancel_pointers()
	modal.visible = show_modal
	for button in attack_buttons:
		button.disabled = show_modal or model.state != Combat.Phase.PLAYER_TURN or (run.area_mode and run.techniques[attack_buttons.find(button)+1] == 0)
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
				heading = "Moonlit Dojo" if area_campaign else "Eight Seals"
				instructions = "Read each guardian’s weakness.\nChoose an element; the foe replies.\nEight seals open the archive."
				if area_campaign: instructions = "Four lands. Four bosses.\nChoose your swords and techniques.\nTap your path to the archive."
				primary = "Begin run"
			Run.State.INTRO:
				heading = ("BOSS · " if run.area_mode and run.current_node % 3 == 2 else "") + run.spec().display_name
				instructions = "%d / %d · %s / weak %s\n%s" % [run.encounter_index + 1, run.encounter_count(), Element.label(run.spec().element), Element.label(Element.weakness(run.spec().element)), run.spec().intro_text]
				if run.area_mode: instructions = "%s · Node %d\n%s · weak %s · %d HP\nNext: victory loot → shrine → map" % [run.AREA_NAMES[run.current_node / 3],run.current_node % 3 + 1,Element.label(run.spec().element),Element.label(Element.weakness(run.spec().element)),run.spec().enemy_max_hp]
				if run.spec().unit != null: instructions += "\n" + run.spec().unit.role
				primary = "Fight"
			Run.State.INTERMISSION:
				heading = "Choose a technique"
				instructions = "Seal %d / %d · HP %d / %d\n%s" % [run.seals,run.encounter_count(),run.hp,run.max_hp,run.next_guardian_text()]
				choices = run.reward_choices()
			Run.State.CLEARED:
				heading = "Dojo cleared"
				instructions = "Seals %d / %d · HP %d / %d\n%d attacks · %d damage taken" % [run.seals,run.encounter_count(),run.hp,run.max_hp,run.attacks,run.damage]
				primary = "New run"
			Run.State.FAILED:
				heading = "Run ended"
				instructions = "Seals %d / %d\n%s" % [run.seals,run.encounter_count(),run.loss_hint]
				primary = "Retry run"
	modal.present(heading,instructions,primary,choices,paused)
	modal.present_journey(run, presentation_time, paused)
	_present_area_panel()
func _present_fighters() -> void:
	samurai.configure_unit(run.spec().unit)
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
		fighter.present(tag,time,attack,model.elapsed,false)

func _present_area_panel() -> void:
	if area_panel == null: return
	var active := run.area_mode and not paused and run.state in [Run.State.LOADOUT, Run.State.MAP, Run.State.LOOT, Run.State.TRAINING]
	area_panel.visible = active
	modal.get_node("Panel").visible = not active
	if not active: return
	for child in modal.get_children():
		if child != area_panel and child.name != "Scrim": child.visible = false
	var signature := str([run.state,run.equipped,run.techniques,run.cleared_nodes,map_area,starting_sword,inventory_open])
	if signature != area_signature:
		area_signature = signature
		area_panel.present(run,map_area,starting_sword,inventory_open)

func _area_action(id: String, value: int) -> void:
	_cancel_pointers()
	match id:
		"sword": starting_sword = value
		"pair":
			var pairs := [[1,2],[1,3],[1,4],[2,3],[2,4],[3,4]]
			run.choose_loadout(starting_sword,pairs[value])
		"area": map_area = value
		"node": run.choose_node(value)
		"inventory": inventory_open = not inventory_open
		"equip": run.equip_weapon(value)
		"loot":
			run.finish_loot()
			inventory_open = false
		"train": run.train(value)
		"title": _title()
	_refresh()
