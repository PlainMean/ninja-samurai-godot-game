extends RefCounted
func run(t) -> void:
	for defender in range(5):
		var weakness := Element.weakness(defender as Element.Type)
		t.check(weakness == [Element.Type.NONE,Element.Type.WATER,Element.Type.WIND,Element.Type.FIRE,Element.Type.EARTH][defender], "derived exact weakness")
		for attack in range(1,5):
			for hp in [1,3]:
				var c := CombatModel.new()
				var spec := EncounterSpec.new()
				spec.element = defender as Element.Type
				spec.enemy_max_hp = hp
				c.configure(spec, 1, 5, Element.Type.FIRE)
				t.check(c.attack_forecast(attack as Element.Type).is_empty(), "ready cannot forecast playable action")
				c.start()
				var forecast := c.attack_forecast(attack as Element.Type)
				t.check(c.attack_forecast(attack as Element.Type)==forecast and c.events.is_empty() and c.attacks==0 and c.enemy_hp==hp and c.selected_element==Element.Type.NONE, "forecast pure and repeatable")
				t.check(forecast.damage==mini(hp,Element.damage_for(attack as Element.Type,defender as Element.Type)) and forecast.reply==int(not forecast.lethal), "forecast clamps damage and suppresses lethal reply")
				c.request_attack(attack as Element.Type)
				t.check(c.attack_forecast(attack as Element.Type).is_empty(), "resolution cannot forecast or queue")
				c.step(100)
				t.check(hp-c.enemy_hp==forecast.damage and c.damage==forecast.reply and c.terminal(), "forecast equals actual deterministic resolution")
	var s=load("res://scenes/duel.tscn").instantiate()
	t.root.add_child(s)
	s.set_process(false)
	s._primary()
	s._primary()
	t.check(s.hud.get_node("Intent").text=="Intent: WATER · 1 dmg if foe survives\nRiver lesson", "visible exact enemy intent")
	for i in range(4):
		t.check(s.attack_buttons[i].get_node("Forecast").text==("2 dmg" if i==3 else "1 dmg"), "visible touch damage forecast")
	s._attack(Element.Type.WIND)
	t.check(s.attack_buttons.all(func(b): return b.get_node("Forecast").text.is_empty()), "forecasts hidden during resolution")
	s.advance(1.55)
	t.check(s.attack_buttons.all(func(b): return b.get_node("Forecast").text=="SEAL"), "all lethal choices explicitly earn seal")
	t.check(s.hud.get_node("Intent").get_rect().position.y >= s.hud.get_node("ElementInfo").get_rect().end.y, "intent below affinity without overlap")
	s.queue_free()
	await t.process_frame
