extends RefCounted
func run(t) -> void:
 var expected := [1,2,3,4,1,2]
 var resources := []
 var pixels := []
 for e in range(1,5):
  var v: WeaponVisualSpec = WeaponSpec.VISUALS[e]
  t.check(v.element == e and v.grip == Vector2(24,39), "sword data element and grip")
  t.check(v.frames.get_frame_count(&"sword") == 4 and v.frames.get_animation_speed(&"sword") == 10, "four 100ms sword frames")
  t.check(v.frames not in resources, "four distinct sword resources")
  resources.append(v.frames)
  var rgba = v.frames.get_frame_texture(&"sword",0).get_image().get_data()
  t.check(rgba not in pixels, "four different sword pixel graphics")
  pixels.append(rgba)
  for f in range(4):
   t.check(v.frames.get_frame_texture(&"sword",f).get_size() == Vector2(48,48) and v.frames.get_frame_duration(&"sword",f) == 1, "native sword cell and duration")
 for i in range(6):
  var w: WeaponSpec = RunModel.WEAPONS[i]
  t.check(w.element == expected[i] and w.visual() == WeaponSpec.VISUALS[expected[i]], "six weapon element mappings")
 var s = load("res://scenes/duel.tscn").instantiate()
 t.root.add_child(s)
 s.set_process(false)
 s.clock = func(): return 1000000
 s.last_tick_usec = 1000000
 for i in range(4):
  s._title()
  s._primary()
  s._area_action("sword",i)
  t.check(s.run.equipped == 0, "loadout preview does not change equip rules")
  t.check(s.area_panel.content.get_child(0).get_child(0).texture == RunModel.WEAPONS[i].visual().frames.get_frame_texture(&"sword",0), "loadout preview icon")
  s._area_action("pair",0)
  t.check(s.ninja.sword.sprite_frames == RunModel.WEAPONS[i].visual().frames, "loadout selection immediately swaps sword")
 # Grant deterministic fixtures for all six inventory paths; production ownership stays untouched.
 s.run.inventory.assign([0,1,2,3,4,5])
 for state in [RunModel.State.MAP,RunModel.State.LOOT,RunModel.State.TRAINING,RunModel.State.LOADOUT]:
  s.run.state = state
  s.run.pending_loot = 5
  for i in range(6):
   var seed_before: int = s.run.rng_state
   var owned_before: Array = s.run.inventory.duplicate()
   s._area_action("equip",i)
   t.check(s.run.rng_state == seed_before and s.run.inventory == owned_before, "visual equip neither rolls nor changes ownership")
   var w: WeaponSpec = RunModel.WEAPONS[i]
   t.check(s.run.equipped == i and s.ninja.weapon_visual == w.visual(), "all six legal equip paths immediately project")
   t.check(s.ninja.sword.sprite_frames == w.visual().frames and s.ninja.sword.visible, "normal scene equipped SpriteFrames selection")
   t.check(s.hud.get_node("EquippedSwordIcon").texture == w.visual().frames.get_frame_texture(&"sword",0), "combat HUD icon projection")
   if state != RunModel.State.LOADOUT:
    t.check(s.area_panel.content.get_child(0).get_child(0).texture == w.visual().frames.get_frame_texture(&"sword",0), "loot map shrine equipped icon")
   t.check(s.samurai.weapon_visual == null and not s.companion.has_node("Visual/EquippedSword"), "Kira poleblade and enemy remain separate")
 s.run.state = RunModel.State.MAP
 s.run.inventory.assign([0,1,2,3])
 s._area_action("equip",0)
 s._area_action("equip",5)
 t.check(s.run.equipped == 0 and s.ninja.weapon_visual.element == Element.Type.FIRE, "unowned equip cannot change visual")
 s._area_action("node",0)
 s._primary()
 s._area_action("equip",1)
 t.check(s.run.equipped == 0, "fight equip still rejected")
 for tag in [&"idle",&"guard",&"dodge",&"hurt",&"defeat",&"attack"]:
  for f in range(6 if tag == &"attack" else 2):
   s.ninja.present(tag,f*0.1,tag == &"attack",f*0.1,false)
   t.check(s.ninja.sprite.sprite_frames == (s.ninja.PlayerAttack if tag == &"attack" else s.ninja.PlayerSupport), "normal attack and support use preserved body exports")
   t.check(s.ninja.sword.sprite_frames == WeaponSpec.VISUALS[1].frames and s.ninja.sword.texture_filter == CanvasItem.TEXTURE_FILTER_NEAREST, "all poses retain nearest equipped sword")
 s.run.equipped = 3
 s.run.state = RunModel.State.FAILED
 s._primary()
 t.check(s.run.equipped == 0 and s.ninja.weapon_visual.element == Element.Type.FIRE, "retry restores default sword immediately")
 for available in [Vector2(390,844),Vector2(390,780)]:
  preload("res://scripts/layout_helper.gd").apply(s,available)
  s._refresh()
  var icon: TextureRect = s.hud.get_node("EquippedSwordIcon")
  t.check(icon.position.y == s.hud.get_node("Hint").position.y and icon.get_rect().end.y <= s.hud.get_node("Actions").position.y, "sword HUD follows compact layout above touch controls")
 s.queue_free()
 await t.process_frame
