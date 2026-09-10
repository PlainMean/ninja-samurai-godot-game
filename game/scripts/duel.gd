extends Control
const Combat = preload("res://scripts/combat_model.gd")
const TouchAction = preload("res://scripts/touch_action.gd")
var model = Combat.new()
var paused := false
var last_tick_usec := 0
var feedback_time := 0.0
var feedback_text := ""
@onready var ninja = $Arena/Ninja
@onready var samurai = $Arena/Samurai
@onready var hud = $HUD
@onready var modal = $Modal
@onready var block_button = $HUD/Actions/BlockButton
@onready var strike_button = $HUD/Actions/StrikeButton
@onready var pause_button = $HUD/PauseButton
@onready var primary_button = $Modal/Panel/Content/PrimaryButton

func _ready() -> void:
	block_button.activated.connect(_block)
	strike_button.activated.connect(_strike)
	pause_button.activated.connect(pause_duel)
	primary_button.activated.connect(_primary)
	$BrowserLifecycle.pause_requested.connect(pause_duel)
	_refresh()

func _process(delta: float) -> void:
	var now := Time.get_ticks_usec()
	var wall_gap := float(now - last_tick_usec) / 1000000.0 if last_tick_usec > 0 else delta
	last_tick_usec = now
	if model.state != Combat.Phase.READY and not model.terminal() and not paused:
		if delta > 0.25 or wall_gap > 0.25:
			pause_duel()
		else:
			model.step(delta)
			feedback_time = maxf(0.0, feedback_time - delta)
			for event in model.drain_events():
				match event:
					"guard": feedback_text = "Guard ready"
					"blocked": feedback_text = "Blocked!"
					"hit": feedback_text = "Hit! Watch for the warning."
					"counter": feedback_text = "Counter landed!"
					_: continue
				feedback_time = 0.65
	_refresh()

func _block() -> void:
	if not paused and not modal.visible:
		model.request_block()
	_refresh()

func _strike() -> void:
	if not paused and not modal.visible:
		model.request_strike()
	_refresh()

func _primary() -> void:
	last_tick_usec = Time.get_ticks_usec()
	_cancel_pointers()
	if paused:
		paused = false
	else:
		model.start()
	feedback_time = 0.0
	feedback_text = ""
	_refresh()

func pause_duel() -> void:
	_cancel_pointers()
	if paused or model.state == Combat.Phase.READY or model.terminal():
		return
	paused = true
	model.prepare_resume()
	model.drain_events()
	feedback_time = 0.0
	feedback_text = ""
	_refresh()

func _cancel_pointers() -> void:
	for button in [block_button, strike_button, pause_button, primary_button]:
		if is_instance_valid(button):
			button.cancel_pointer()

func _refresh() -> void:
	var state: int = model.state
	var ready: bool = state == Combat.Phase.READY
	var finished: bool = model.terminal()
	var show_modal: bool = ready or finished or paused
	if modal.visible != show_modal:
		_cancel_pointers()
	modal.visible = show_modal
	block_button.disabled = show_modal or state != Combat.Phase.TELEGRAPH or model.block_latched
	strike_button.disabled = show_modal or state != Combat.Phase.COUNTER_WINDOW
	pause_button.disabled = show_modal
	hud.get_node("Header/PlayerHealth").text = "You %d/3" % model.player_hp
	hud.get_node("Header/EnemyHealth").text = "Samurai %d/3" % model.enemy_hp
	var cue := "Ready your guard"
	match state:
		Combat.Phase.REST: cue = "Get ready…"
		Combat.Phase.TELEGRAPH: cue = "Guard ready" if model.block_latched else "Incoming — tap Block"
		Combat.Phase.ENEMY_ATTACK: cue = "Hold your ground"
		Combat.Phase.COUNTER_WINDOW: cue = "Open — tap Strike"
		Combat.Phase.PLAYER_ATTACK: cue = "Counterattack!"
		Combat.Phase.WON: cue = "Three perfect counters"
		Combat.Phase.LOST: cue = "A new duel awaits"
	hud.get_node("Cue").text = cue
	hud.get_node("PhaseProgress").value = 100.0 * (1.0 - model.elapsed / model.duration()) if model.duration() > 0 else 0.0
	hud.get_node("Feedback").text = feedback_text if feedback_time > 0 else ""
	block_button.text = "GUARD SET" if model.block_latched else "BLOCK"
	var enemy_attacking: bool = state == Combat.Phase.ENEMY_ATTACK
	var player_attacking: bool = state == Combat.Phase.PLAYER_ATTACK
	var attack_frame := mini(int(floor((model.elapsed + 0.000000001) / 0.1)), 5)
	var ninja_frame := attack_frame if player_attacking else (5 if state == Combat.Phase.WON else 0)
	var samurai_frame := attack_frame if enemy_attacking else (5 if state in [Combat.Phase.COUNTER_WINDOW, Combat.Phase.PLAYER_ATTACK, Combat.Phase.LOST, Combat.Phase.WON] else 0)
	var ninja_tint := Color.WHITE
	var samurai_tint := Color.WHITE
	if feedback_time > 0.4:
		if feedback_text.begins_with("Hit!"): ninja_tint = Color("e07565")
		if feedback_text == "Blocked!": ninja_tint = Color("76dbe1")
		if feedback_text == "Counter landed!": samurai_tint = Color("e07565")
	if state == Combat.Phase.LOST: ninja_tint = Color(0.55, 0.55, 0.55)
	if state == Combat.Phase.WON: samurai_tint = Color(0.55, 0.55, 0.55)
	ninja.show_pose(ninja_frame, model.elapsed, player_attacking, model.block_latched, ninja_tint)
	samurai.show_pose(samurai_frame, model.elapsed, enemy_attacking, false, samurai_tint)
	if show_modal:
		var heading: Label = modal.get_node("Panel/Content/Heading")
		var instructions: Label = modal.get_node("Panel/Content/Instructions")
		if paused:
			heading.text = "Duel paused"
			instructions.text = "Take a breath.\nTap Resume when you’re ready."
			primary_button.text = "RESUME"
		elif ready:
			heading.text = "Block & Counter"
			instructions.text = "Block the warning.\nStrike when the samurai opens up.\nLand 3 hits."
			primary_button.text = "START DUEL"
		else:
			heading.text = "You win" if state == Combat.Phase.WON else "Try again"
			instructions.text = "Three counters. One calm ninja." if state == Combat.Phase.WON else "Tap Block during the warning,\nthen Strike when you see Open."
			primary_button.text = "PLAY AGAIN"
