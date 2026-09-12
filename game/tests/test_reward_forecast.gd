extends RefCounted
func run(t) -> void:
	for gate in range(7):
		for capacity in range(5, 12):
			for health in range(1, capacity + 1):
				for id in [&"mend", &"long_breath" if gate == 0 else &"iron_resolve"]:
					var r := RunModel.new()
					r.state = RunModel.State.INTERMISSION
					r.encounter_index = gate
					r.hp = health
					r.max_hp = capacity
					var f := r.reward_forecast(id)
					var expected_max := capacity + int(id != &"mend")
					var expected_hp := mini(expected_max, health + (2 if id == &"mend" else 1))
					t.check(f.hp == expected_hp and f.max_hp == expected_max and f.restored == expected_hp - health, "reward forecast exact clamped health and capacity")
					t.check(r.reward_forecast(id) == f and r.hp == health and r.max_hp == capacity and r.upgrades.is_empty() and r.encounter_index == gate and not r.reward_claimed, "reward forecast pure and repeatable")
					f.hp = 999
					t.check(r.reward_forecast(id).hp == expected_hp, "caller cannot mutate future reward")
					var enabled: bool = id != &"mend" or health < capacity
					t.check(r.choose_reward(id) == enabled, "forecast eligibility matches actual reward")
					if enabled:
						t.check(r.hp == expected_hp and r.max_hp == expected_max and r.state == RunModel.State.INTRO and r.encounter_index == gate + 1 and r.upgrades == [id], "claim applies exact forecast and advances once")
						t.check(r.reward_forecast(id).is_empty() and not r.choose_reward(id) and r.hp == expected_hp, "stale preview cannot claim twice")
					else:
						t.check(r.hp == health and not r.reward_claimed and r.state == RunModel.State.INTERMISSION, "full health mend leaves shrine unchanged")
	for state in RunModel.State.values():
		var r := RunModel.new()
		r.state = state
		t.check(r.reward_forecast(&"unknown").is_empty() and not r.choose_reward(&"unknown"), "unknown rewards always rejected")
		if state != RunModel.State.INTERMISSION:
			t.check(r.reward_forecast(&"mend").is_empty() and r.reward_choices().is_empty() and r.next_guardian_text().is_empty(), "reward previews absent outside shrine")
	var s = load("res://scenes/duel.tscn").instantiate()
	s.area_campaign = false
	t.root.add_child(s)
	s.set_process(false)
	for available in [Vector2(390,844), Vector2(390,700), Vector2(360,800), Vector2(393,852), Vector2(430,932)]:
		preload("res://scripts/layout_helper.gd").apply(s, available)
		for gate in range(7):
			for health in [1, 5]:
				s.run.state = RunModel.State.INTERMISSION
				s.run.encounter_index = gate
				s.run.hp = health
				s.run.max_hp = 5
				s._refresh()
				await t.process_frame
				await t.process_frame
				t.check(s.choice_a.disabled == (health == 5) and not s.choice_b.disabled, "scene reward eligibility matches preview")
				t.check(s.choice_b.text == ("Long Breath" if gate == 0 else "Iron Resolve") + "\n%d / 5 → %d / 6 HP" % [health, health + 1], "scene displays exact capacity reward")
				t.check(s.run.next_guardian_text() in s.modal.get_node("Panel/Content/Instructions").text and str([4,5,3,4,4,5,5][gate]) + " HP" in s.run.next_guardian_text(), "shrine previews next guardian health")
				for button in [s.choice_a, s.choice_b]:
					var font: Font = button.get_theme_font("font")
					var font_size: int = button.get_theme_font_size("font_size")
					for line in button.text.split("\n"):
						t.check(font.get_string_size(line, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x <= button.size.x - 20, "reward text fits existing button width")
					t.check(font.get_height(font_size) * 2 <= button.size.y - 12 and button.size.y >= 72, "two-line reward fits unchanged touch target")
				t.check(s.choice_a.get_global_rect().end.y <= s.choice_b.get_global_rect().position.y and s.choice_b.get_global_rect().end.y <= s.modal.get_node("Panel").get_global_rect().end.y, "reward controls stay separated and within modal")
				t.check(s.modal.get_node("Panel").size == Vector2(350,326), "reward preview preserves modal bounds")
	s.run.state = RunModel.State.INTERMISSION
	s.run.encounter_index = 0
	s.run.hp = 3
	s.run.max_hp = 5
	s._refresh()
	s.choice_b.activated.emit()
	t.check(s.run.state == RunModel.State.INTRO and s.run.hp == 4 and s.model.player_hp == 4 and s.run.max_hp == 6, "existing choice control applies preview to next fight")
	s._title()
	t.check(s.run.hp == 5 and s.run.max_hp == 5 and s.run.reward_choices().is_empty(), "title resets reward preview state")
	s.queue_free()
	await t.process_frame
