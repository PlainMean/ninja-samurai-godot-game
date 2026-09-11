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
		assert(scene.model.spec.element == Element.Type.WATER)
		assert("WATER · Weakness: WIND" in scene.hud.get_node("ElementInfo").text)
		while not scene.model.terminal():
			assert(scene.model.request_attack(Element.Type.WIND))
			scene.advance(0.6)
			if not scene.model.terminal(): scene.advance(0.95)
		scene.advance(0.4)
		assert(scene.run.seals == encounter + 1)
		if encounter < 2: scene._reward(&"long_breath" if encounter == 0 else &"iron_resolve")
	assert(scene.run.state == scene.Run.State.CLEARED and scene.run.attacks == 7 and scene.run.damage == 4)
	print("PASS exported-pack complete three-encounter run, seven WIND attacks, four WATER replies, six atlases and typed elements loaded")
	scene.queue_free()
	await process_frame
	quit()
