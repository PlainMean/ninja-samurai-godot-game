extends RefCounted
const IDS = ["cinder_rival","ash_monk","ash_shogun","gate_guard","twin_cut_retainer","moonlit_master","earth_sentinel","iron_vanguard","mountain_regent","gale_assassin","coast_ronin","tempest_sovereign"]
const NAMES = ["Cinder Rival","Ash Monk","Ash Shogun","Gate Guard","Twin-cut Retainer","Moonlit Master","Earth Sentinel","Iron Vanguard","Mountain Regent","Gale Assassin","Coast Ronin","Tempest Sovereign"]
const ROLES = ["Fire duelist","Staff monk","Helmed warlord","Spear guardian","Dual blades","Moon fan master","Shield sentinel","Hammer vanguard","Stone axe regent","Sickle assassin","Straw-hat ronin","Storm glaive lord"]
func run(t) -> void:
 var manifest = JSON.parse_string(FileAccess.get_file_as_string("res://tests/unit_asset_manifest.json"))
 for path in manifest.sha256:
  t.check(FileAccess.get_sha256("res://../" + path) == manifest.sha256[path], "unit source/runtime hash " + path)
 var s = load("res://scenes/duel.tscn").instantiate()
 t.root.add_child(s)
 s.set_process(false)
 s.clock = func(): return 1000000
 s.last_tick_usec = 1000000
 s._primary()
 s._area_action("pair",0)
 var seen: Array[StringName] = []
 var player_frames = s.ninja.frames
 for i in range(12):
  var spec: EncounterSpec = s.run.area_encounters[i]
  var u: UnitSpec = spec.unit
  t.check(u != null and u.unit_id == IDS[i] and u.unit_id not in seen, "unique ordered unit mapping")
  seen.append(u.unit_id)
  t.check(spec.id == StringName("area_%d" % i) and spec.display_name == NAMES[i] and u.display_name == NAMES[i], "identity and encounter mapping")
  t.check(u.role == ROLES[i] and u.element == i/3+1 and spec.element == u.element, "area element and role")
  t.check(u.boss == (i%3 == 2) and spec.enemy_max_hp == (16 if u.boss else 8), "all boss mappings and unchanged HP")
  var expected_elements: Array = [u.element,u.element%4+1,(u.element+1)%4+1,u.element] if u.boss else [u.element,u.element%4+1,u.element]
  t.check(spec.attack_elements == expected_elements, "unchanged enemy intent cycle")
  var f := u.attack_animation
  t.check(f.resource_path == "res://assets/frames/units/%s_frames.tres" % IDS[i], "unit animation resource")
  t.check(f.get_frame_count("attack") == 4 and f.get_animation_speed("attack") == 10 and not f.get_animation_loop("attack"), "100ms attack tag")
  var pixels: Array[PackedByteArray] = []
  for j in range(4):
   var atlas: AtlasTexture = f.get_frame_texture("attack",j)
   var data := atlas.get_image().get_data()
   t.check(atlas.region == Rect2(j*48,0,48,48) and atlas.filter_clip and f.get_frame_duration("attack",j) == 1, "48px atlas and timing")
   t.check(data not in pixels and not atlas.get_image().is_invisible(), "distinct imported nonempty pose")
   pixels.append(data)
  for tag in [&"idle",&"hurt",&"defeat",&"guard"]: t.check(f.has_animation(tag), "unit support pose available")
  s._area_action("area",i/3)
  await t.process_frame
  await t.process_frame
  t.check(s.area_panel.content.size.x <= 326 and s.area_panel.content.size.y <= s.area_panel.scroll.size.y, "every region map fits 390x844 panel")
  var map_text := ""
  for child in s.area_panel.content.get_children():
   if child is Button:
    map_text += child.text
    t.check(child.size.x <= 326 and child.size.y >= 60, "all region node touch bounds")
  t.check(u.display_name in map_text and u.role in map_text and "BOSS" in map_text, "map unit names roles and boss marker")
  s._area_action("node",i)
  t.check(s.run.state == RunModel.State.INTRO and u.role in s.modal.get_node("Panel/Content/Instructions").text, "unit intro role")
  t.check(("BOSS" in s.modal.get_node("Panel/Content/Heading").text) == u.boss, "intro boss marker")
  s._primary()
  t.check(s.samurai.selected_unit == u and s.samurai.frames == f and s.samurai.sprite.sprite_frames == f, "normal scene selects unit resource")
  t.check(s.samurai.get_node("Visual").scale == Vector2.ONE*u.visual_scale and u.visual_scale == (3.0 if u.boss else 2.5), "boss readable scale")
  t.check(s.samurai.sprite.texture_filter == CanvasItem.TEXTURE_FILTER_NEAREST and s.ninja.frames == player_frames and s.ninja.selected_unit == null, "nearest enemy and preserved ninja")
  t.check(s.hud.get_node("UnitRole").text == u.role and ("BOSS" in s.hud.get_node("EnemyName").text) == u.boss, "HUD role boss marker")
  while not s.model.terminal():
   s._attack(1)
   s.advance(1.55)
  s.advance(0.4)
  if s.run.state == RunModel.State.RECRUIT:
   assert(s.run.first_boss_defeated and s.primary_button.text == "Continue with Kira")
   s._primary()
  t.check(s.run.state == RunModel.State.LOOT and u.role in s.run.node_label(i), "unit victory loot identity")
  s._area_action("loot",0)
  var e := 1
  while e < 5 and s.run.techniques[e] == 3: e += 1
  s._area_action("train",0 if e == 5 else e)
 t.check(s.run.state == RunModel.State.CLEARED and s.run.bosses_defeated() == 4 and seen.size() == 12, "complete distinct unit campaign")
 s._title()
 t.check(s.samurai.selected_unit == null and s.samurai.frames.resource_path == "res://assets/frames/samurai_frames.tres", "legacy presentation restored on title")
 s.queue_free()
 await t.process_frame
