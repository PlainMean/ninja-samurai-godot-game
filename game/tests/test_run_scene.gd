extends RefCounted
const C = preload("res://scripts/combat_model.gd")
const R = preload("res://scripts/run_model.gd")
const Touch = preload("res://scripts/touch_action.gd")
const Layout = preload("res://scripts/layout_helper.gd")
var now := 1000000
func tap(t, viewport, button) -> void:
	t.scene_tap(viewport, button)
func beat(t, screen, viewport) -> void:
	tap(t, viewport, screen.attack_buttons[Element.weakness(screen.run.spec().element)-1])
	t.check(screen.model.state == C.Phase.PLAYER_ATTACK, "scene weakness accepted")
	for frame in range(6):
		screen.model.elapsed = frame * 0.1
		screen._refresh()
		t.check(screen.ninja.sprite.frame == frame and not screen.ninja.sprite.is_playing(), "six original player frames")
	screen.model.elapsed = 0.0
	screen.advance(0.6)
	if not screen.model.terminal():
		t.check(screen.model.state == C.Phase.ENEMY_TURN and screen.hud.get_node("Cue").text == "ENEMY TURN", "visible automatic enemy turn")
		screen.advance(0.35)
		for frame in range(6):
			screen.model.elapsed = frame * 0.1
			screen.hud.present(screen.snapshot())
			# Isolate animation sampling from the recent hurt overlay.
			screen.hurt_enemy = -1.0
			screen._present_fighters()
			t.check(screen.samurai.sprite.frame == frame and not screen.samurai.sprite.is_playing(), "six original enemy frames")
		screen.model.elapsed = 0.0
		screen.advance(0.6)
func fits(t, screen) -> void:
	await t.process_frame
	await t.process_frame
	if screen.modal.visible:
		var panel = screen.get_node("Modal/Panel")
		t.check(panel.size.x <= 350 and panel.size.y <= 326, "modal container fits specified bounds " + str(panel.size))
		for label in screen.get_node("Modal/Panel/Content").get_children():
			if label.visible:
				t.check(panel.get_global_rect().encloses(label.get_global_rect()), "modal child inside panel " + label.name)
	for button in screen.attack_buttons:
		t.check(button.size == Vector2(83,96), "four equal action targets")
func run(t) -> void:
	for factor in [1,2,3]:
		for mend in [false,true]:
			var viewport := SubViewport.new()
			viewport.size = Vector2i(390,844) * factor
			viewport.size_2d_override = Vector2i(390,844)
			viewport.size_2d_override_stretch = true
			t.root.add_child(viewport)
			var s = load("res://scenes/duel.tscn").instantiate()
			viewport.add_child(s)
			s.set_process(false)
			s.clock = func(): return now
			s.last_tick_usec = now
			await t.process_frame
			await t.process_frame
			await fits(t,s)
			t.check(s.modal.visible and s.attack_buttons.all(func(button): return button.disabled), "title blocks all combat")
			t.check(not s.ninja.sprite.flip_h and s.samurai.sprite.flip_h, "only enemy flipped")
			tap(t,viewport,s.primary_button)
			t.check(s.run.state == R.State.INTRO, "Begin enters intro without tap leakage")
			s.pause_duel()
			s.advance(5)
			t.check(not s.paused and s.run.state == R.State.INTRO, "intro inert on lifecycle/time")
			for encounter in range(8):
				tap(t,viewport,s.primary_button)
				t.check(s.run.state == R.State.FIGHT and s.model.enemy_hp == [3,4,5,3,4,4,5,5][encounter], "Fight configures encounter")
				while not s.model.terminal(): beat(t,s,viewport)
				t.check(not s.modal.visible and s.run.seals == encounter, "lethal recovery before terminal handoff")
				s.advance(0.399)
				t.check(s.run.state == R.State.FIGHT, "399ms terminal delay")
				tap(t,viewport,s.pause_button)
				var frozen: float = s.terminal_time
				var decorative: float = s.presentation_time
				s.advance(5)
				t.check(s.paused and s.terminal_time == frozen and s.presentation_time == decorative, "pause freezes terminal and decoration")
				tap(t,viewport,s.primary_button)
				s.advance(0.001)
				await fits(t,s)
				t.check(s.run.seals == encounter+1 and s.modal.visible and s.samurai.sprite.animation == &"defeat" and s.samurai.sprite.frame == 2, "one seal and held defeat at 400ms")
				if encounter < 7:
					s.pause_duel()
					t.check(not s.paused and s.run.state == R.State.INTERMISSION, "reward lifecycle inert")
					t.check(s.choice_a.disabled == (s.run.hp == s.run.max_hp), "Mend disabled only at full HP")
					tap(t,viewport,s.choice_a if mend else s.choice_b)
					t.check(s.run.state == R.State.INTRO and s.model.state == C.Phase.READY, "reward enters fresh intro without leakage " + str(s.run.state) + "/" + str(s.model.state))
				t.check(s.run.attacks == [2,4,7,9,11,13,16,19][encounter], "landed attack stats")
			t.check(s.run.state == R.State.CLEARED and s.run.seals == 8 and s.run.attacks == 19, "touch-only eight encounter clear")
			tap(t,viewport,s.primary_button)
			t.check(s.run.state == R.State.INTRO and s.run.hp == 5 and s.run.upgrades.is_empty(), "New run fresh")
			var baseline: int = s.find_children("*", "", true, false).size()
			for retry in range(20):
				tap(t,viewport,s.primary_button)
				s.model.player_hp = 1
				s._attack(Element.Type.FIRE)
				s.advance(1.55)
				t.check(s.model.state == C.Phase.LOST and not s.modal.visible, "loss recovery before result")
				s.advance(0.4)
				t.check(s.run.state == R.State.FAILED and s.modal.visible, "touch-started loss")
				if retry == 0: await fits(t,s)
				tap(t,viewport,s.primary_button)
				t.check(s.run.state == R.State.INTRO and s.run.hp == 5 and s.model.enemy_hp == 3 and not s.paused, "retry health/modal reset")
				t.check(s.feedback_time == 0 and s.ninja.position == s.ninja.home and s.ninja.sprite.frame == 0 and not s.ninja.guard and s.get_node("Arena/Effects").clocks.is_empty(), "retry clears all presentation")
				t.check(s.find_children("*", "", true, false).size() == baseline and s.primary_button.activated.get_connections().size() == 1, "20 retries stable nodes/connections")
			tap(t,viewport,s.primary_button)
			s.advance(0.7)
			s._process(0.251)
			t.check(s.paused and s.model.player_hp == 5, "live delta stall pauses without damage")
			tap(t,viewport,s.primary_button)
			now += 260000
			s._process(0.016)
			t.check(s.paused, "monotonic stall despite clamped delta")
			tap(t,viewport,s.secondary_button)
			t.check(s.run.state == R.State.TITLE and not s.paused and Touch.pointer_owner == null, "Return to title cancels ownership/run")
			t.check(baseline <= 200, "scene node budget")
			viewport.queue_free()
			await t.process_frame
	# Input eligibility and processing share one monotonic interval.
	var s = load("res://scenes/duel.tscn").instantiate()
	t.root.add_child(s)
	s.set_process(false)
	s.clock = func(): return now
	s._primary()
	s._primary()
	for i in range(4):
		t.check(s.attack_buttons[i].text == ["FIRE","WATER","EARTH","WIND"][i],"explicit elemental touch label")
	s.advance(100)
	t.check(s.model.state==C.Phase.PLAYER_TURN and s.model.player_hp==5,"scene waits indefinitely")
	s._attack(Element.Type.WATER)
	now += 199000
	s._attack(Element.Type.WIND)
	t.check(s.model.selected_element==Element.Type.WATER and is_equal_approx(s.model.elapsed,0.199),"resolution tap cannot replace choice")
	s._process(0.199)
	t.check(is_equal_approx(s.model.elapsed,0.199),"process does not consume input interval twice")
	s.advance(1.151)
	now += 200000
	s._attack(Element.Type.WIND)
	t.check(s.model.state==C.Phase.PLAYER_TURN and s.model.attacks==1,"resolution tap cannot queue next-turn attack")
	for available in [Vector2(390,844),Vector2(360,800),Vector2(430,932),Vector2(360,740),Vector2(390,700)]:
		var metrics := Layout.metrics(available)
		Layout.apply(s,available)
		t.check(60 * metrics.scale >= 48 and 83 * metrics.scale >= 48 and 96 * metrics.scale >= 48, "CSS targets " + str(available))
		t.check(s.get_node("HUD/Actions").position.y + 96 <= metrics.height and s.get_node("Modal/Panel").position.y + 326 <= metrics.height, "compact controls inside canvas")
		t.check(s.get_node("HUD/Feedback").get_rect().end.y <= s.get_node("HUD/Hint").position.y and s.get_node("HUD/Hint").get_rect().end.y <= s.get_node("HUD/Actions").position.y,"log selection and controls do not overlap")
	Layout.apply(s,Vector2(390,844))
	# Held touch and second finger cannot create extra turns.
	t.touch(s.attack_buttons[0],0,true,s.attack_buttons[0].get_global_rect().get_center())
	t.touch(s.attack_buttons[3],1,true,s.attack_buttons[3].get_global_rect().get_center())
	t.check(s.model.selected_element==Element.Type.FIRE,"second finger cannot replace attack")
	s.advance(1.55)
	t.touch(s.attack_buttons[0],0,true,s.attack_buttons[0].get_global_rect().get_center())
	t.check(s.model.state==C.Phase.PLAYER_TURN and s.model.attacks==2,"held attack never repeats next turn")
	t.touch(s.attack_buttons[0],0,false,Vector2(-10,-10))
	s.pause_duel()
	var frozen := [s.model.state,s.model.elapsed,s.model.player_hp,s.model.enemy_hp]
	s._attack(Element.Type.WIND)
	s.advance(100)
	t.check(frozen==[s.model.state,s.model.elapsed,s.model.player_hp,s.model.enemy_hp] and Touch.pointer_owner==null,"modal blocks damage/input and cancels pointers")
	s._primary()
	s._attack(Element.Type.WIND)
	s.advance(0.999)
	t.check(s.run.state == R.State.FIGHT and is_equal_approx(s.terminal_time,0.399), "coarse attack to terminal preserves remaining time")
	s.advance(0.001)
	t.check(s.run.state == R.State.INTERMISSION, "coarse handoff exact 1000ms after attack")
	# Pause on both sides of both impact boundaries via the scene coordinator.
	for at in [0.299,0.3,0.6,1.249,1.25]:
		s._title()
		s._primary()
		s._primary()
		s._attack(Element.Type.FIRE)
		s.advance(at)
		frozen=[s.model.state,s.model.elapsed,s.model.player_hp,s.model.enemy_hp]
		s.pause_duel()
		s.advance(100)
		s._attack(Element.Type.WIND)
		t.check(frozen==[s.model.state,s.model.elapsed,s.model.player_hp,s.model.enemy_hp],"scene pause preserves impact state")
		s._primary()
		s.advance(1.55-at)
		t.check(s.model.player_hp==4 and s.model.enemy_hp==2 and s.model.attacks==1 and s.model.state==C.Phase.PLAYER_TURN,"scene resume resolves once")
	s._title()
	s._primary()
	s.run.encounter_index=7
	s._primary()
	t.check('Enemy: WATER · Weakness: WIND' in s.hud.get_node("ElementInfo").text,"final boss explicitly WATER with WIND weakness")
	s._attack(Element.Type.WIND)
	s.advance(1.55)
	t.check('WIND · EFFECTIVE · 2 damage' in s.hud.get_node("Hint").text and 'Foe WATER · NEUTRAL · 1 dmg' in s.hud.get_node("Feedback").text and 'Turn 2' in s.hud.get_node("ElementInfo").text,"visible selection matchup damage log and turn")
	s.queue_free()
	await t.process_frame
