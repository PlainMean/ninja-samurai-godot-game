extends SceneTree
## External verification script, deliberately excluded from the release pack.
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	var scene = load("res://scenes/duel.tscn").instantiate()
	scene.area_campaign = false
	root.add_child(scene)
	scene.set_process(false)
	await process_frame
	assert(scene.modal.get_node("Route").visible)
	scene._primary()
	for encounter in range(8):
		scene._primary()
		assert(scene.model.spec.element == [2,1,3,4,2,1,3,2][encounter])
		assert("%s · Weakness: %s" % [Element.label(scene.run.spec().element), Element.label(Element.weakness(scene.run.spec().element))] in scene.hud.get_node("ElementInfo").text)
		assert(scene.hud.get_node("Intent").text == "Intent: %s · 1 dmg if foe survives\n%s" % [Element.label(scene.model.enemy_intent().element),scene.model.enemy_intent().name])
		assert(scene.attack_buttons[Element.weakness(scene.run.spec().element)-1].get_node("Forecast").text == "2 dmg")
		while not scene.model.terminal():
			assert(scene.model.request_attack(Element.weakness(scene.run.spec().element)))
			scene.advance(0.3)
			var tag:=Element.effect_tag(scene.model.selected_element)
			assert(scene.get_node("Arena/Effects").get_node(NodePath(tag)).visible)
			scene.advance(0.3)
			if not scene.model.terminal(): scene.advance(0.95)
		scene.advance(0.4)
		assert(scene.run.seals == encounter + 1)
		assert(scene.run.results.size() == encounter + 1)
		assert(scene.modal.get_node("Shrine" if encounter < 7 else "Reveal").visible)
		if encounter < 7:
			assert(scene.choice_b.text == scene.run.reward_choices()[1].text)
			assert(scene.run.next_guardian_text() in scene.modal.get_node("Panel/Content/Instructions").text)
		if encounter < 7: scene._reward(&"long_breath" if encounter == 0 else &"iron_resolve")
	assert(scene.run.state == scene.Run.State.CLEARED and scene.run.attacks == 19 and scene.run.damage == 11)
	for name in ["water","fire","earth","wind"]:
		var frames: SpriteFrames=load("res://assets/frames/elements/%s_frames.tres" % name)
		assert(frames.get_frame_count(name)==4 and frames.get_frame_texture(name,0).get_size()==Vector2(48,48))
	print("PASS exported-pack complete eight-encounter run, nineteen effective attacks, eleven varied replies, all effect atlases and typed elements loaded")

	scene.clock = func(): return 1000000
	scene.last_tick_usec = 1000000
	scene.area_campaign = true
	scene._title()
	scene._primary()
	scene._area_action("pair",0)
	for step in range(12):
		scene._area_action("node",scene.run.next_nodes()[0])
		scene._primary()
		while not scene.model.terminal():
			scene._attack(1)
			scene.advance(1.55)
		scene.advance(0.4)
		assert(scene.run.state == RunModel.State.LOOT)
		scene._area_action("loot",0)
		var e := 1
		while e < 5 and scene.run.techniques[e] == 3: e += 1
		scene._area_action("train",0 if e == 5 else e)
	assert(scene.run.state == RunModel.State.CLEARED and scene.run.bosses_defeated() == 4)
	print("PASS exported-pack area map, twelve nodes, four bosses, loot and technique full clear")
	scene.queue_free()
	await process_frame
	quit()
