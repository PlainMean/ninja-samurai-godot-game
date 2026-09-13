extends RefCounted
const IDS = [&"gate_guard", &"fire_rival", &"earth_sentinel", &"wind_assassin", &"courtyard_retainer", &"ember_monk", &"mixed_elite", &"dojo_master"]
const HP = [3,4,5,3,4,4,5,5]
const AFFINITIES = [2,1,3,4,2,1,3,2]
const WEAKNESSES = [4,2,1,3,4,2,1,4]
const CYCLES = [[2],[1,1,4],[3,2],[4,1],[2,4],[3,1],[4,2,1,3],[2,1,3,4]]
const COLORS = ["", "ef493c", "328ee6", "a47746", "ffffff"]
func run(t) -> void:
	t.check(RunModel.ENCOUNTERS.size()==8, "exact eight-encounter inventory")
	for i in range(8):
		var spec := RunModel.ENCOUNTERS[i]
		t.check(spec.id==IDS[i] and spec.enemy_max_hp==HP[i] and spec.element==AFFINITIES[i], "independent encounter identity HP affinity oracle")
		t.check(Element.weakness(spec.element)==WEAKNESSES[i], "each enemy has exact readable weakness")
		t.check(spec.attack_elements==CYCLES[i] and spec.attack_names.size()==CYCLES[i].size(), "literal distinct technique cycle")
		var c := CombatModel.new()
		c.configure(spec,100,100,Element.Type.FIRE)
		c.start()
		for turn in range(1,9):
			c.enemy_hp=100 # Exercise repetitions independently of encounter length.
			var expected: int = CYCLES[i][(turn-1)%CYCLES[i].size()]
			var intent := c.enemy_intent()
			t.check(intent==c.enemy_intent() and intent.element==expected and intent.name==spec.attack_names[(turn-1)%CYCLES[i].size()], "pure intent wraps declared cycle")
			var attack: Element.Type = ((turn-1)%4+1) as Element.Type
			var forecast := c.attack_forecast(attack)
			var hp := c.player_hp
			c.request_attack(attack)
			c.step(100)
			var events := c.drain_events()
			t.check(events.size()==2 and events[0].element==attack and events[1].element==expected, "selected player and intent enemy typed effects")
			t.check(c.enemy_hp==100-forecast.damage and hp-c.player_hp==forecast.reply, "all pattern forecasts equal actual damage")
			for event in events:
				t.check(Element.effect_tag(event.element)==Element.label(event.element).to_lower() and Element.effect_color(event.element)==Color(COLORS[event.element]), "both actors exact effect/color metadata")
		# Every opponent suppresses its declared reply on lethal impact.
		c.configure(spec,1,5)
		c.start()
		c.enemy_hp=1
		t.check(c.attack_forecast(Element.weakness(spec.element)).reply==0, "every enemy lethal forecast suppresses reply")
		c.request_attack(Element.weakness(spec.element))
		c.step(100)
		t.check(c.state==CombatModel.Phase.WON and c.player_hp==1 and c.drain_events().all(func(e): return e.kind!=CombatEvent.Kind.ENEMY_HIT), "every enemy lethal suppresses actual reply")
	# Every defeat position returns to level one and clears the full route.
	for i in range(8):
		var r := RunModel.new()
		var c := CombatModel.new()
		r.begin_run()
		r.encounter_index=i
		r.seals=i
		r.hp=1
		r.begin_encounter(c)
		c.request_attack(r.spec().element) # Neutral attack leaves every guardian alive.
		c.step(100)
		t.check(r.resolve_encounter(c) and r.state==RunModel.State.FAILED and r.seals==i and r.hp==0, "defeat retains only previously earned seals at every level")
		t.check(Element.label(WEAKNESSES[i] as Element.Type) in r.loss_hint, "defeat hint uses current guardian weakness")
		r.begin_run()
		t.check(r.encounter_index==0 and r.hp==5 and r.max_hp==5 and r.seals==0 and r.results.is_empty(), "every defeat retries from level one")
		r.begin_encounter(c)
		t.check(c.turn_number==1 and c.enemy_intent().element==Element.Type.WATER and c.selected_element==Element.Type.NONE, "every retry resets intent and selection")
	# Exhaust all 128 sequences of the seven shrine choices without injected HP.
	for mask in range(128):
		var r := RunModel.new()
		var c := CombatModel.new()
		r.begin_run()
		for i in range(8):
			t.check(r.route_status()[i]=="NEXT" and r.route_status().slice(i+1).all(func(x): return x=="LOCKED"), "future route locked")
			r.begin_encounter(c)
			while not c.terminal():
				c.request_attack(WEAKNESSES[i] as Element.Type)
				c.step(100)
			t.check(r.resolve_encounter(c) and not r.resolve_encounter(c) and r.seals==i+1, "every path single deterministic handoff")
			if r.state == RunModel.State.RECRUIT: t.check(r.continue_recruit(), "explicit first-boss join acknowledgment")
			if i<7:
				var gift: StringName = &"mend" if mask & (1<<i) else (&"long_breath" if i==0 else &"iron_resolve")
				t.check(r.choose_reward(gift) and not r.choose_reward(gift), "all reward paths claim once")
		t.check(r.state==RunModel.State.CLEARED and r.hp>0 and r.attacks==19 and r.damage==11 and r.results.size()==8, "all 128 reward paths clear exact run")
		r.begin_run()
		t.check(r.hp==5 and r.max_hp==5 and r.results.is_empty() and r.upgrades.is_empty() and r.seals==0 and r.encounter_index==0, "full-run replay resets deterministically")
	for element in range(1,5):
		var tag := Element.effect_tag(element as Element.Type)
		var frames: SpriteFrames = load("res://assets/frames/elements/%s_frames.tres" % tag)
		var source := Image.new()
		source.load_png_from_buffer(FileAccess.get_file_as_bytes("res://assets/sprites/elements/%s_sheet.png" % tag))
		t.check(frames.get_frame_count(tag)==4 and frames.get_animation_speed(tag)==10 and not frames.get_animation_loop(tag), "element runtime frame count timing and no loop")
		for i in range(4):
			var atlas: AtlasTexture = frames.get_frame_texture(tag,i)
			t.check(atlas.region==Rect2(i*48,0,48,48) and atlas.filter_clip and frames.get_frame_duration(tag,i)==1, "element exact runtime frame region and timing")
			t.check(atlas.atlas.get_image().get_data()==source.get_data(), "element lossless imported pixels")
			var cfg:=ConfigFile.new()
			cfg.load("res://assets/sprites/elements/%s_sheet.png.import" % tag)
			t.check(cfg.get_value("params","compress/mode")==0 and not cfg.get_value("params","mipmaps/generate") and not cfg.get_value("params","process/fix_alpha_border"), "element import preserves pixels and nearest atlas")
	var s=load("res://scenes/duel.tscn").instantiate()
	s.area_campaign = false
	t.root.add_child(s)
	s.set_process(false)
	s.clock=func(): return 1000000
	s.last_tick_usec=1000000
	for element in range(1,5):
		s._title()
		s._primary()
		s._primary()
		s._attack(element as Element.Type)
		s.advance(0.3)
		var fx=s.get_node("Arena/Effects")
		var tag:=Element.effect_tag(element as Element.Type)
		t.check(fx.get_node(NodePath(tag)).visible and fx.clocks.has(tag), "player impact shows chosen element sprite")
		t.check(fx.get_node(NodePath(tag)).position==Vector2(252,386), "player effect lands at enemy")
		s.advance(0.95)
		t.check(fx.get_node("water").visible and fx.get_node("water").position==Vector2(138,386), "enemy impact shows intent element at player")
	# Consume real enemy impact events for all four elements, including mixed elites.
	for index in range(8):
		s._title()
		s._primary()
		s.run.encounter_index=index
		s._primary()
		for turn in range(1,CYCLES[index].size()+1):
			s.model.enemy_hp=100
			s.model.player_hp=100
			s._attack(Element.Type.FIRE)
			s.advance(1.25)
			var tag:=Element.effect_tag(CYCLES[index][turn-1] as Element.Type)
			var fx=s.get_node("Arena/Effects")
			t.check(fx.get_node(NodePath(tag)).visible and fx.get_node(NodePath(tag)).position==Vector2(138,386), "every enemy technique triggers its actual element effect")
			s.advance(0.3)
		# All eight named guardians, weakness and pattern fit the existing UI.
		t.check(s.hud.get_node("EnemyName").text==s.run.spec().display_name and Element.label(WEAKNESSES[index] as Element.Type) in s.hud.get_node("ElementInfo").text, "every guardian identity and weakness visible")
		for path in ["EnemyName","ElementInfo","Intent","Progress"]:
			var label: Label=s.hud.get_node(path)
			for line in label.text.split("\n"):
				t.check(label.get_theme_font("font").get_string_size(line,HORIZONTAL_ALIGNMENT_LEFT,-1,label.get_theme_font_size("font_size")).x<=label.size.x, "eight-level HUD text fits " + path)
		s._title()
		t.check(s.get_node("Arena/Effects").clocks.is_empty(), "title clears every elemental effect clock")
	s.queue_free()
	await t.process_frame
