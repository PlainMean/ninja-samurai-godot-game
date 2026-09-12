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

func run() -> void:
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
	await preload("res://tests/test_encounter_patterns.gd").new().run(self)
	await preload("res://tests/test_run_model.gd").new().run(self)
	await preload("res://tests/test_moonlit_assets.gd").new().run(self)
	await preload("res://tests/test_run_scene.gd").new().run(self)
	await preload("res://tests/test_journey.gd").new().run(self)
	await preload("res://tests/test_forecast.gd").new().run(self)
	await preload("res://tests/test_reward_forecast.gd").new().run(self)
	await preload("res://tests/test_eight_seals.gd").new().run(self)
	await preload("res://tests/test_area_campaign.gd").new().run(self)
	await preload("res://tests/test_area_scene.gd").new().run(self)
	await preload("res://tests/test_units.gd").new().run(self)
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

func event_count(m, kind: int) -> int:
	return m.drain_events().filter(func(e): return e.kind == kind).size()

func event_values(m) -> Array:
	return m.drain_events().map(func(e): return e.values())
