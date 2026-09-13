extends RefCounted
func recruited(area: int = 0) -> RunModel:
 var r := RunModel.new()
 r.begin_area_run(42)
 r.choose_loadout(0,[1,2])
 # Isolate first-boss detection in each region without changing shipped map locks.
 r.current_node = area*3+2
 r.encounter_index = r.current_node
 r.state = RunModel.State.INTRO
 var c := CombatModel.new()
 r.begin_encounter(c)
 while not c.terminal():
  c.request_attack(1)
  c.step(1.55)
 assert(c.state == CombatModel.Phase.WON)
 assert(r.resolve_encounter(c))
 return r
func battle(r: RunModel, enemy_hp := 100) -> CombatModel:
 var c := CombatModel.new()
 var spec: EncounterSpec = r.area_encounters[0].duplicate()
 spec.enemy_max_hp = enemy_hp
 c.configure(spec,12,12)
 c.configure_weapon(r)
 c.configure_companion(r)
 c.start()
 return c
func run(t) -> void:
 var fresh := RunModel.new()
 fresh.begin_area_run(42)
 t.check(not fresh.first_boss_defeated and not fresh.companion_joined and fresh.companion_hp == 0, "solo run start")
 t.check(not fresh.continue_recruit() and not fresh.develop_companion(&"upgrade"), "no premature join or development")
 fresh.choose_loadout(0,[1,2])
 fresh.choose_node(0)
 var solo := CombatModel.new()
 fresh.begin_encounter(solo)
 while not solo.terminal():
  solo.request_attack(1)
  solo.step(1.55)
 fresh.resolve_encounter(solo)
 t.check(not fresh.companion_joined and fresh.state == RunModel.State.LOOT, "guard victory stays solo")
 for area in range(4):
  var r := recruited(area)
  t.check(r.first_boss_defeated and r.companion_joined and r.state == RunModel.State.RECRUIT, "first boss in every area recruits")
  t.check(r.current_node in r.cleared_nodes and r.bosses_defeated() == 1, "boss seal committed before recruitment")
  t.check(r.companion_hp == 6 and r.COMPANION.element == Element.Type.WATER and r.COMPANION.role == "Tide warden" and r.COMPANION.ability_id == &"support_strike", "typed named hero stats and ability")
  t.check(not r.finish_loot() and not r.train(1) and not r.choose_node(0), "recruit blocks rewards shrine and map")
  t.check(r.continue_recruit() and not r.continue_recruit() and r.state == RunModel.State.LOOT, "join continue exactly once")
  var hp := r.companion_hp
  r.equip_weapon(1)
  t.check(r.companion_hp == hp, "inventory preserves ally")
  r.finish_loot()
  t.check(r.develop_companion(&"ward_pulse") and not r.develop_companion(&"upgrade"), "one independent companion development per shrine")
  t.check(r.train(1) and r.companion_ability == &"ward_pulse", "player training unchanged and ally choice persists to map")
  r.state = RunModel.State.TRAINING
  r.companion_trained = false
  t.check(r.develop_companion(&"upgrade") and r.companion_level == 1, "deterministic shrine upgrade")
  r.begin_area_run(42)
  t.check(not r.companion_joined and not r.first_boss_defeated and r.companion_hp == 0 and r.companion_level == 0, "retry resets entire companion")
 var r := recruited()
 r.continue_recruit()
 var c := battle(r)
 var seed_before := r.rng_state
 c.request_attack(1)
 c.step(0.3)
 var events := c.drain_events()
 t.check(events.size() == 2 and events[0].kind == CombatEvent.Kind.PLAYER_HIT and events[1].kind == CombatEvent.Kind.COMPANION_HIT, "player then support ordering")
 t.check(events[1].damage == 2 and events[1].element == Element.Type.WATER, "bounded WATER support versus FIRE")
 t.check(r.rng_state == seed_before*16807%2147483647, "support consumes no RNG")
 c.step(1.25)
 events = c.drain_events()
 t.check(events.size() == 2 and events[0].kind == CombatEvent.Kind.ENEMY_HIT and events[1].kind == CombatEvent.Kind.COMPANION_HURT and c.companion_hp == 5, "enemy reply then fatigue ordering")
 t.check(not c.companion_acted, "support ready next player turn")
 var repeat := recruited()
 repeat.continue_recruit()
 var same := battle(repeat)
 same.request_attack(1)
 same.step(1.55)
 t.check([same.enemy_hp,same.player_hp,same.companion_hp,repeat.rng_state] == [c.enemy_hp,c.player_hp,c.companion_hp,r.rng_state], "repeatable seed and chunked timing")
 c = battle(r,1)
 c.request_attack(1)
 c.step(100)
 events = c.drain_events()
 t.check(events.size() == 2 and events[0].kind == CombatEvent.Kind.PLAYER_HIT and events[1].kind == CombatEvent.Kind.WON and c.companion_hp == 6, "player lethal suppresses support and reply")
 # Exact support lethal with a deterministic unarmed main strike (one damage).
 c = battle(r,3)
 c.weapon_run = null
 t.check(c.attack_forecast(Element.Type.FIRE).lethal and c.attack_forecast(Element.Type.FIRE).reply == 0, "forecast includes lethal companion support")
 c.request_attack(Element.Type.FIRE)
 c.step(100)
 events = c.drain_events()
 t.check(events.size() == 3 and events[1].kind == CombatEvent.Kind.COMPANION_HIT and events[2].kind == CombatEvent.Kind.WON and c.player_hp == 12, "support lethal suppresses enemy reply")
 r.companion_hp = 1
 c = battle(r)
 c.request_attack(1)
 c.step(1.55)
 t.check(c.companion_hp == 0 and "FALLEN" in c.companion_status(), "companion defeat visible")
 c.drain_events()
 c.request_attack(1)
 c.step(1.55)
 t.check(c.drain_events().all(func(e): return e.kind not in [CombatEvent.Kind.COMPANION_HIT,CombatEvent.Kind.COMPANION_WARD]), "fallen ally cannot act; main player still acts")
 r.state = RunModel.State.INTRO
 r.current_node = 0
 var next := CombatModel.new()
 r.begin_encounter(next)
 c.state = CombatModel.Phase.WON
 r.resolve_encounter(c)
 t.check(r.state == RunModel.State.LOOT and r.companion_hp == 0, "later victory persists defeat and never recruits again")
 r.finish_loot()
 t.check(r.companion_hp == 6, "shrine revives ally")
 r.develop_companion(&"ward_pulse")
 c = battle(r)
 t.check(c.enemy_intent().damage == 0 and c.attack_forecast(1).reply == 0, "forecast includes available ward")
 c.request_attack(1)
 c.step(1.55)
 events = c.drain_events()
 t.check(events[1].kind == CombatEvent.Kind.COMPANION_WARD and c.player_hp == 12 and c.companion_hp == 5, "ward blocks reply without changing fatigue")
 for level in range(3):
  r.companion_level = level
  r.companion_ability = &"support_strike"
  for element in range(1,5):
   c = battle(r)
   c.spec.element = element as Element.Type
   t.check(c.support_damage() >= 1+level and c.support_damage() <= 2+level, "support bounds all elements and levels")
 r.state = RunModel.State.TRAINING
 r.companion_trained = false
 r.companion_level = 1
 t.check(r.develop_companion(&"upgrade") and r.companion_level == 2, "companion develops to level three")
 r.companion_trained = false
 t.check(not r.develop_companion(&"upgrade") and not r.develop_companion(&"invalid"), "mastery cap and invalid choice guarded")
 var losing := RunModel.new()
 losing.begin_area_run(42)
 losing.choose_loadout(0,[1,2])
 losing.current_node = 2
 losing.state = RunModel.State.INTRO
 losing.hp = 1
 c = CombatModel.new()
 losing.begin_encounter(c)
 c.request_attack(1)
 c.step(1.55)
 losing.resolve_encounter(c)
 t.check(losing.state == RunModel.State.FAILED and not losing.first_boss_defeated and not losing.companion_joined, "boss defeat never recruits")
 var s = load("res://scenes/duel.tscn").instantiate()
 t.root.add_child(s)
 s.set_process(false)
 s.clock = func(): return 1000000
 s.last_tick_usec = 1000000
 s.run = recruited(3)
 s._refresh()
 await t.process_frame
 t.check(s.modal.visible and not s.area_panel.visible and s.primary_button.text == "Continue with Kira" and s.primary_button.size.y >= 64, "visible touch-sized join modal")
 t.check("Kira has joined" in s.modal.get_node("Panel/Content/Heading").text and s.companion.visible, "explicit join copy and separate hero")
 t.check(s.modal.get_node("RecruitPortrait").visible and not s.modal.get_node("Route").visible, "join presents hero portrait instead of obscuring it")
 s.advance(100)
 t.check(s.run.state == RunModel.State.RECRUIT, "join never automatically skips")
 s._primary()
 s._area_action("loot",0)
 s._area_action("companion",1)
 s._area_action("train",1)
 s._area_action("node",0)
 s._primary()
 t.check(s.model.companion_hp == 6 and s.model.companion_ability == &"ward_pulse", "scene shrine choice persists into battle")
 t.check(s.companion.get_node("Visual/Sprite").sprite_frames == s.run.COMPANION.sprite_frames and s.hud.get_node("CompanionStatus").visible and "Ward Pulse" in s.hud.get_node("CompanionStatus").text, "normal scene loads unique hero and ability HUD")
 t.check(s.companion.position != s.ninja.position and s.companion.get_node("Label").text == "ALLY", "separate ally position and label")
 await t.process_frame
 await t.process_frame
 for available in [Vector2(390,844),Vector2(390,780)]:
  preload("res://scripts/layout_helper.gd").apply(s,available)
  var label: Label = s.hud.get_node("CompanionStatus")
  for line in label.text.split("\n"):
   t.check(label.get_theme_font("font").get_string_size(line,HORIZONTAL_ALIGNMENT_LEFT,-1,label.get_theme_font_size("font_size")).x <= label.size.x, "companion HUD line fits mobile width")
  t.check(label.get_rect().end.y <= s.hud.get_node("Feedback").position.y, "companion HUD does not overlap log")
  t.check(label.position.y >= s.get_node("Arena").position.y + 450, "companion HUD clears fighter feet")
 var frames: SpriteFrames = s.run.COMPANION.sprite_frames
 var pixels: Array[PackedByteArray] = []
 for i in range(4):
  var atlas: AtlasTexture = frames.get_frame_texture(&"support",i)
  var data := atlas.get_image().get_data()
  t.check(atlas.region == Rect2(i*48,0,48,48) and atlas.filter_clip and data not in pixels and not atlas.get_image().is_invisible(), "unique imported hero frame")
  pixels.append(data)
 t.check(frames.get_animation_speed(&"support") == 10 and s.companion.get_node("Visual/Sprite").texture_filter == CanvasItem.TEXTURE_FILTER_NEAREST, "100ms animation nearest filtering")
 var imported: Image = frames.get_frame_texture(&"support",0).atlas.get_image()
 var source := Image.new()
 source.load_png_from_buffer(FileAccess.get_file_as_bytes("res://assets/sprites/heroes/kira_sheet.png"))
 t.check(imported.get_data() == source.get_data(), "imported hero RGBA equals original Aseprite export")
 var cfg := ConfigFile.new()
 cfg.load("res://assets/sprites/heroes/kira_sheet.png.import")
 t.check(cfg.get_value("params","compress/mode") == 0 and not cfg.get_value("params","mipmaps/generate"), "lossless hero import without mipmaps")
 s._title()
 t.check(not s.companion.visible and not s.run.companion_joined, "title removes projected companion")
 s.queue_free()
 await t.process_frame
