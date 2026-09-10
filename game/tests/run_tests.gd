extends SceneTree
const Combat = preload("res://scripts/combat_model.gd")
const Touch = preload("res://scripts/touch_action.gd")
var checks := 0
var failures := 0
var activations := 0

func check(condition: bool, description: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error("FAIL: " + description)

func _initialize() -> void:
	call_deferred("run")

func warning():
	var m = Combat.new()
	m.start()
	m.step(0.7)
	return m

func opening():
	var m = warning()
	m.request_block()
	m.step(1.5)
	return m

func run() -> void:
	var m = Combat.new()
	check(m.state == Combat.Phase.READY and m.player_hp == 3 and m.enemy_hp == 3, "initial ready health")
	m.step(99)
	check(m.state == Combat.Phase.READY and not m.request_block() and not m.request_strike(), "ready rejects time/input")
	for hz in [30, 60, 120]:
		m.start()
		for i in range(int(0.7 * hz)):
			m.step(1.0 / hz)
		check(m.state == Combat.Phase.TELEGRAPH and is_zero_approx(m.elapsed), "rest boundary at %d Hz" % hz)
		for i in range(int(0.9 * hz)):
			m.step(1.0 / hz)
		check(m.state == Combat.Phase.ENEMY_ATTACK and m.player_hp == 3, "warning boundary at %d Hz" % hz)
		for i in range(int(0.6 * hz)):
			m.step(1.0 / hz)
		check(m.state == Combat.Phase.REST and m.player_hp == 2, "attack duration at %d Hz" % hz)
	m = warning()
	check(not m.request_strike(), "early strike rejected")
	m.step(0.899)
	check(m.request_block() and not m.request_block(), "block before deadline once")
	m.step(0.001)
	check(not m.request_block(), "block at deadline rejected")
	m.step(0.299)
	check(not m.impact_resolved and m.player_hp == 3, "no impact at 299 ms")
	m.step(0.001)
	check(m.impact_resolved and m.player_hp == 3 and m.drain_events().count("blocked") == 1, "blocked at 300 ms")
	m.step(0.3)
	check(m.state == Combat.Phase.COUNTER_WINDOW, "blocked opens counter")
	check(m.request_strike() and not m.request_strike(), "one valid strike")
	m.step(0.299)
	check(m.enemy_hp == 3, "ninja no impact at 299 ms")
	m.step(0.001)
	check(m.enemy_hp == 2 and m.drain_events().count("counter") == 1, "ninja impact once at 300 ms")
	m.step(0.3)
	check(m.enemy_hp == 2 and m.state == Combat.Phase.REST, "ninja completes recovery")
	m = warning()
	m.step(0.9)
	check(not m.request_block(), "late block rejected")
	m.step(0.3)
	check(m.player_hp == 2, "missed block loses one")
	m.step(0.3)
	check(m.state == Combat.Phase.REST and m.player_hp == 2, "miss skips counter, no duplicate hit")
	m = opening()
	m.step(1.2)
	check(m.state == Combat.Phase.REST and m.player_hp == 3 and not m.request_strike(), "expired counter costs no health and rejects late strike")
	m.start()
	for cycle in range(3):
		m.step(0.7)
		check(m.request_block(), "win block %d" % cycle)
		m.step(1.5)
		check(m.request_strike(), "win strike %d" % cycle)
		m.step(0.3)
		check(m.state == Combat.Phase.PLAYER_ATTACK, "lethal impact still animates")
		m.step(0.3)
	check(m.state == Combat.Phase.WON and m.enemy_hp == 0 and m.player_hp == 3, "three counters win")
	check(m.drain_events().count("won") == 1, "one win event")
	m.step(500)
	check(m.enemy_hp == 0 and not m.request_strike() and not m.request_block(), "won frozen")
	m.start()
	m.step(6.3)
	check(m.player_hp == 0 and m.state == Combat.Phase.ENEMY_ATTACK, "large delta lethal before recovery complete")
	m.step(0.3)
	check(m.state == Combat.Phase.LOST and m.drain_events().count("hit") == 3, "large delta three hits lose")
	m.step(500)
	check(m.player_hp == 0 and m.drain_events().count("lost") == 0, "lost frozen no duplicate result")
	# Pause boundaries and every recoverable phase.
	m = warning()
	m.request_block()
	m.step(1.199)
	m.prepare_resume()
	check(m.state == Combat.Phase.TELEGRAPH and m.elapsed == 0 and not m.block_latched and m.player_hp == 3, "pause pre-impact restarts warning")
	m.step(1.2)
	m.prepare_resume()
	check(m.state == Combat.Phase.ENEMY_ATTACK and m.impact_resolved and m.player_hp == 2, "pause post-impact retains damage")
	m.step(0.3)
	check(m.player_hp == 2, "resume never repeats impact")
	m = warning()
	m.request_block()
	m.step(1.2)
	m.prepare_resume()
	m.step(0.3)
	check(m.state == Combat.Phase.COUNTER_WINDOW and m.player_hp == 3, "resolved block keeps earned counter after pause")
	m.step(0.8)
	m.prepare_resume()
	check(m.elapsed == 0, "counter resumes full window")
	m.request_strike()
	m.step(0.299)
	m.prepare_resume()
	check(is_equal_approx(m.elapsed, 0.299), "player attack pause keeps time")
	m.step(0.301)
	check(m.enemy_hp == 2, "player attack resume hits once")
	m.start()
	m.step(0.2)
	m.prepare_resume()
	check(is_equal_approx(m.elapsed, 0.2), "rest pause retains time")
	m = opening()
	m.request_strike()
	m.step(0.3)
	m.prepare_resume()
	m.step(0.3)
	check(m.enemy_hp == 2 and m.drain_events().count("counter") == 1, "player pause after impact never repeats damage")
	# Whole-run determinism with coarse versus fine deltas.
	var a = Combat.new()
	var b = Combat.new()
	a.start()
	b.start()
	a.step(100)
	for i in range(10000): b.step(0.01)
	check(a.state == b.state and a.player_hp == b.player_hp and a.drain_events() == b.drain_events(), "partition-independent event order")
	for who in ["ninja", "samurai"]:
		var frames: SpriteFrames = load("res://assets/frames/%s_frames.tres" % who)
		check(frames.get_frame_count("attack") == 6 and frames.get_animation_speed("attack") == 10 and not frames.get_animation_loop("attack"), who + " animation metadata")
		for i in range(6):
			var atlas: AtlasTexture = frames.get_frame_texture("attack", i)
			check(atlas.region == Rect2(i * 32, 0, 32, 32) and atlas.filter_clip and frames.get_frame_duration("attack", i) == 1, who + " atlas frame %d" % i)
			check(atlas.atlas.get_size() == Vector2(192, 32), who + " sheet size")
		var cfg := ConfigFile.new()
		cfg.load("res://assets/sprites/%s_attack_sheet.png.import" % who)
		check(cfg.get_value("params", "compress/mode") == 0 and cfg.get_value("params", "mipmaps/generate") == false, who + " lossless/no mipmaps")
		var source := Image.new()
		source.load_png_from_buffer(FileAccess.get_file_as_bytes("res://assets/sprites/%s_attack_sheet.png" % who))
		var imported: Image = frames.get_frame_texture("attack", 0).atlas.get_image()
		check(source.get_data() == imported.get_data(), who + " imported RGBA pixels match source exactly")
	# Real scene wiring and view reset.
	var duel = load("res://scenes/duel.tscn").instantiate()
	root.add_child(duel)
	duel.set_process(false)
	await process_frame
	check(duel.modal.visible and duel.block_button.disabled and duel.strike_button.disabled, "start modal blocks combat")
	check(duel.ninja.sprite.flip_h == false and duel.samurai.sprite.flip_h == true, "fighters face each other")
	for retry in range(20):
		duel._primary()
		check(duel.model.player_hp == 3 and duel.model.enemy_hp == 3 and not duel.paused and not duel.modal.visible, "retry health/modal reset %d" % retry)
		for frame in range(6):
			duel.model.state = Combat.Phase.PLAYER_ATTACK
			duel.model.elapsed = frame * 0.1
			duel._refresh()
			check(duel.ninja.sprite.frame == frame and not duel.ninja.sprite.is_playing(), "model-driven frame %d" % frame)
		duel.pause_duel()
		check(duel.paused and duel.modal.visible and Touch.pointer_owner == null, "pause modal clears pointers")
		duel._primary()
		duel.model.start()
		duel.model.step(100)
		duel._refresh()
		check(duel.modal.visible, "result modal")
	check(duel.primary_button.activated.get_connections().size() == 1, "retry has no duplicate connections")
	duel._primary()
	check(duel.feedback_time == 0 and duel.ninja.position == duel.ninja.home and duel.ninja.sprite.frame == 0 and not duel.ninja.guard, "retry clears presentation")
	duel.model.step(0.7)
	duel._process(0.251)
	check(duel.paused and duel.model.player_hp == 3, "live stall pauses without damage")
	duel._primary()
	OS.delay_msec(260)
	duel._process(0.016)
	check(duel.paused, "wall-clock stalls detected even when engine clamps delta")
	duel.queue_free()
	await process_frame
	# Send native touch events through scaled viewports and complete actual UI flows.
	for scale_factor in [1, 2, 3]:
		var viewport := SubViewport.new()
		viewport.size = Vector2i(390, 844) * scale_factor
		viewport.size_2d_override = Vector2i(390, 844)
		viewport.size_2d_override_stretch = true
		root.add_child(viewport)
		var screen = load("res://scenes/duel.tscn").instantiate()
		viewport.add_child(screen)
		screen.set_process(false)
		await process_frame
		await process_frame
		scene_tap(viewport, screen.primary_button)
		check(screen.model.state == Combat.Phase.REST, "scaled Start touch %dx" % scale_factor)
		for cycle in range(3):
			screen.model.step(0.7)
			screen._refresh()
			scene_tap(viewport, screen.block_button)
			check(screen.model.block_latched, "scaled Block touch")
			screen.model.step(1.5)
			screen._refresh()
			scene_tap(viewport, screen.strike_button)
			check(screen.model.state == Combat.Phase.PLAYER_ATTACK, "scaled Strike touch")
			screen.model.step(0.6)
			screen._refresh()
		check(screen.model.state == Combat.Phase.WON and screen.modal.visible, "touch-only win")
		scene_tap(viewport, screen.primary_button)
		check(screen.model.player_hp == 3 and screen.model.enemy_hp == 3, "touch-only retry")
		scene_tap(viewport, screen.pause_button)
		check(screen.paused, "touch-only Pause")
		scene_tap(viewport, screen.primary_button)
		check(not screen.paused, "touch-only Resume")
		screen.model.step(6.6)
		screen._refresh()
		check(screen.model.state == Combat.Phase.LOST and screen.modal.visible, "touch-started loss")
		viewport.queue_free()
		await process_frame
	# Feed the same native touch/mouse event classes as a viewport.
	var button = Touch.new()
	button.position = Vector2(20, 20)
	button.size = Vector2(100, 60)
	root.add_child(button)
	button.activated.connect(func(): activations += 1)
	button.disabled = true
	touch(button, 0, true, Vector2(30, 30))
	button.disabled = false
	touch(button, 0, true, Vector2(30, 30))
	check(activations == 0, "disabled held touch never activates when enabled")
	touch(button, 0, false, Vector2(300, 300))
	touch(button, 0, true, Vector2(30, 30))
	touch(button, 1, true, Vector2(30, 30))
	check(activations == 1, "second finger ignored")
	touch(button, 1, false, Vector2(30, 30))
	check(button.pointer_id == 0, "secondary release cannot cancel primary")
	touch(button, 0, false, Vector2(300, 300))
	check(Touch.pointer_owner == null and not button.button_pressed, "release outside clears ownership")
	touch(button, 0, true, Vector2(30, 30))
	touch(button, 0, true, Vector2(30, 30), true)
	check(Touch.pointer_owner == null, "touch cancellation")
	var mouse := InputEventMouseButton.new()
	mouse.button_index = MOUSE_BUTTON_LEFT
	mouse.position = Vector2(30, 30)
	mouse.pressed = true
	button._input(mouse)
	button._input(mouse)
	check(activations == 3, "real mouse activates once")
	mouse.pressed = false
	mouse.position = Vector2(300, 300)
	button._input(mouse)
	check(Touch.pointer_owner == null, "mouse release outside")
	button.queue_free()
	await process_frame
	print("RESULT: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)

func touch(button: Button, index: int, down: bool, position: Vector2, canceled := false) -> void:
	var event := InputEventScreenTouch.new()
	event.index = index
	event.pressed = down
	event.position = position
	event.canceled = canceled
	button._input(event)

func scene_tap(viewport: SubViewport, button: Button) -> void:
	var event := InputEventScreenTouch.new()
	event.index = 0
	event.pressed = true
	event.position = viewport.get_final_transform() * button.get_global_rect().get_center()
	viewport.push_input(event, false)
	event = event.duplicate()
	event.pressed = false
	event.position = Vector2(-10, -10)
	viewport.push_input(event, false)
