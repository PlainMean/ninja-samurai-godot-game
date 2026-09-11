extends RefCounted
func run(t) -> void:
	var r := RunModel.new()
	var c := CombatModel.new()
	t.check(r.route_status() == ["NEXT","LOCKED","LOCKED"] and r.results.is_empty(), "fresh route and empty records")
	r.begin_run()
	for i in range(3):
		r.begin_encounter(c)
		while not c.terminal():
			c.request_attack(Element.Type.WIND)
			c.step(100)
		r.resolve_encounter(c)
		t.check(r.results.size() == i+1 and r.results[i].won and r.results[i].attacks == [2,2,3][i], "result records actual encounter once")
		r.resolve_encounter(c)
		t.check(r.results.size() == i+1 and r.route_status()[i] == "SEALED", "duplicate handoff cannot duplicate record")
		if i<2: r.choose_reward(&"long_breath" if i==0 else &"iron_resolve")
	t.check("archive" in r.journey_text() and r.route_status() == ["SEALED","SEALED","SEALED"], "final archive revealed after three seals")
	r.begin_run()
	t.check(r.results.is_empty() and r.route_status()==["NEXT","LOCKED","LOCKED"], "retry clears journey")
	r.begin_encounter(c)
	c.player_hp = 1
	c.request_attack(Element.Type.FIRE)
	c.step(100)
	r.resolve_encounter(c)
	t.check(r.results.size()==1 and not r.results[0].won and r.results[0].damage==1 and r.seals==0, "loss records actual result without awarding seal")
	var s = load("res://scenes/duel.tscn").instantiate()
	t.root.add_child(s)
	s.set_process(false)
	await t.process_frame
	t.check(s.modal.get_node("Route").visible and not s.modal.get_node("Shrine").visible and not s.modal.get_node("Reveal").visible, "title shows only route")
	for state in [RunModel.State.INTRO, RunModel.State.INTERMISSION, RunModel.State.CLEARED, RunModel.State.FAILED, RunModel.State.FIGHT]:
		s.run.state = state
		s._refresh()
		var expected := "Shrine" if state==RunModel.State.INTERMISSION else ("Reveal" if state==RunModel.State.CLEARED else "Route")
		for name in ["Route","Shrine","Reveal"]:
			var panel = s.modal.get_node(name)
			t.check(panel.visible == (state!=RunModel.State.FIGHT and name==expected), "exclusive journey scene " + name)
			panel.present("test", 0.3)
			t.check(panel.atlas.region == Rect2(160,0,160,96) and panel.sheet.get_size()==Vector2(480,96), "Aseprite frame sampling and dimensions")
	s.run.state=RunModel.State.INTRO
	for index in range(3):
		s.run.encounter_index=index
		s.presentation_time=99.0
		s._refresh()
		t.check(s.modal.get_node("Route").atlas.region.position.x==index*160, "route artwork tracks unlocked gates instead of animation time")
	for size in [Vector2(390,844),Vector2(390,700)]:
		preload("res://scripts/layout_helper.gd").apply(s,size)
		t.check(s.modal.get_node("Route").get_global_rect().end.y <= s.modal.get_node("Panel").get_global_rect().position.y, "journey does not overlap modal controls")
		t.check(s.modal.get_node("Route").get_global_rect().position.y >= s.hud.get_node("Seal0").get_global_rect().end.y, "compact journey remains below earned-seal header")
	s.run.state=RunModel.State.FIGHT
	s.pause_duel()
	t.check(not s.modal.get_node("Route").visible and not s.modal.get_node("Shrine").visible and not s.modal.get_node("Reveal").visible, "pause preserves battle visibility")
	s.queue_free()
	await t.process_frame
