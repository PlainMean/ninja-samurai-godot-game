extends SceneTree
## External verification script, deliberately excluded from the release pack.
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	var scene = load("res://scenes/duel.tscn").instantiate()
	root.add_child(scene)
	scene.set_process(false)
	await process_frame
	scene._primary()
	for encounter in range(3):
		scene._primary()
		while not scene.model.terminal():
			scene.advance(scene.model.duration())
			while scene.model.state == scene.Combat.Phase.TELEGRAPH:
				scene.model.request_defense(scene.model.strike().defense_required)
				scene.advance(scene.model.duration() + 0.6)
			assert(scene.model.state == scene.Combat.Phase.COUNTER_WINDOW)
			scene.model.request_strike()
			scene.advance(0.6)
		scene.advance(0.4)
		assert(scene.run.seals == encounter + 1)
		if encounter < 2: scene._reward(&"long_breath" if encounter == 0 else &"iron_resolve")
	assert(scene.run.state == scene.Run.State.CLEARED and scene.run.counters == 12)
	print("PASS exported-pack complete three-encounter run, six atlases and typed data loaded")
	scene.queue_free()
	await process_frame
	quit()
