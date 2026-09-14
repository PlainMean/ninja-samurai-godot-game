extends RefCounted
func run(t) -> void:
 var s = load("res://scenes/duel.tscn").instantiate()
 t.root.add_child(s)
 s.set_process(false)
 s.clock = func(): return 1000000
 s.last_tick_usec = 1000000
 s._primary()
 s._area_action("pair",0)
 var grouped: Array[int] = []
 for n in range(12):
  var spec: EncounterSpec = s.run.area_encounters[n]
  var original: EncounterSpec = load("res://data/encounters/areas/%s.tres" % spec.unit.unit_id)
  t.check(original.party.is_empty(), "all twelve original single-enemy regressions retained")
  if not spec.party.is_empty():
   grouped.append(n)
   t.check(spec.party.size() in [2,3] and spec.party[0] == original, "party references preserved leader")
   var ids := []
   for member in spec.party:
    t.check(member is EncounterSpec and member.party.is_empty() and member.unit.unit_id not in ids and member.enemy_max_hp > 0, "unique configured non-nested party unit")
    ids.append(member.unit.unit_id)
 t.check(grouped == [1,4,7,10,11], "one ordinary group per area and final boss minion")
 # Real scene projection with a recruited ally, three slots and all controls.
 s.run.companion_joined = true
 s.run.companion_hp = 6
 s.run.current_node = 10
 s.run.state = RunModel.State.INTRO
 s._primary()
 var ui = s.combat_controls
 t.check(s.model.enemies.size() == 3 and ui.targets.all(func(b): return b.visible), "all target cards visible")
 for slot in range(3):
  var member: EnemyState = s.model.enemies[slot]
  t.check(s.enemy_views()[slot].visible and s.enemy_views()[slot].selected_unit == member.spec.unit and s.enemy_views()[slot].sprite.sprite_frames == member.spec.unit.attack_animation, "each party sprite uses its own unit frames")
  t.check(member.spec.display_name.replace(" ","\n") in ui.targets[slot].text and "%d/%d HP" % [member.hp,member.spec.enemy_max_hp] in ui.targets[slot].text, "individual named HP card")
 ui.choose_target(1)
 ui.choose_actor(&"kira")
 t.check(s.model.target_slot == 1 and s.model.selected_actor == &"kira" and s.run.selected_actor == &"kira", "UI actor target selection persists")
 t.check(ui.tide_button.visible and not s.hud.get_node("Actions").visible and "TIDE ARC" in ui.tide_button.text, "separate WATER Tide Arc action")
 ui.use_tide()
 s.advance(0.3)
 t.check(s.model.enemies[1].hp == 0 and s.model.enemies[0].hp == 8 and s.model.enemies[2].hp == 3, "Kira touches only selected enemy")
 s.advance(3)
 t.check(not s.model.select_target(1) and ui.targets[1].disabled and "FALLEN" in ui.targets[1].text, "fallen card disabled")
 ui.choose_actor(&"main")
 ui.open_skills()
 t.check(ui.sheet.visible and s.attack_buttons.all(func(b): return b.disabled) and ui.targets.all(func(b): return b.disabled), "skills modal disables underlying raw input")
 t.check(ui.skill_buttons.size() == 3 and ui.skill_buttons.all(func(b): return b.size.y >= 48), "three touch-sized skills")
 ui.toggle_auto()
 t.check(not s.model.auto_companion and not s.run.auto_companion, "auto switch persists")
 ui.use_skill(&"stone_guard")
 t.check(s.model.active_skill == &"stone_guard" and not ui.sheet.visible, "skill button commits model action")
 s.advance(3)
 for height in [844,780]:
  preload("res://scripts/layout_helper.gd").apply(s,Vector2(390,height))
  s._refresh()
  await t.process_frame
  await t.process_frame
  var controls: Array = ui.targets + [ui.main_button,ui.kira_button,ui.skills_button]
  for control in controls:
   var rect: Rect2 = control.get_global_rect()
   t.check(rect.size.x >= 48 and rect.size.y >= 48 and rect.position.x >= 0 and rect.end.x <= 390 and rect.end.y <= height, "portrait touch bounds at %d" % height)
  for i in range(controls.size()):
   for j in range(i+1,controls.size()): t.check(not controls[i].get_global_rect().intersects(controls[j].get_global_rect()), "target and actor controls disjoint")
  t.check(ui.targets[0].get_global_rect().end.y <= s.enemy_views()[0].global_position.y-58, "cards clear enemy sprites")
  t.check(ui.main_button.get_rect().end.y <= s.hud.get_node("Feedback").position.y, "actor row clears log")
  t.check(s.hud.get_node("Feedback").get_rect().end.y <= s.hud.get_node("Hint").position.y, "log clears weapon hint")
  t.check(s.hud.get_node("Hint").get_rect().end.y <= s.hud.get_node("Actions").position.y, "hint clears attacks")
  ui.open_skills()
  for button in ui.skill_buttons + [ui.auto_button,ui.close_button]:
   t.check(button.get_global_rect().end.x <= 390 and button.get_global_rect().end.y <= height and button.size.y >= 48, "modal buttons fit portrait")
  ui.close_skills()
 # Inspect all party cards with actual Godot font metrics, including the boss.
 for node in grouped:
  s.run.current_node = node
  s.run.state = RunModel.State.INTRO
  s._primary()
  await t.process_frame
  await t.process_frame
  for slot in range(s.model.enemies.size()):
   var card: Button = ui.targets[slot]
   var member: EnemyState = s.model.enemies[slot]
   t.check(member.spec.unit.role in card.text and "Next: " + Element.label(member.intent_element(1)) in card.text, "role and elemental intent visible on each card")
   t.check(("BOSS" in card.text) == member.spec.unit.boss, "per-card boss marker")
   for line in card.text.split("\n"):
    t.check(card.get_theme_font("font").get_string_size(line,HORIZONTAL_ALIGNMENT_LEFT,-1,card.get_theme_font_size("font_size")).x <= card.size.x-4, "every card line fits actual mobile font metrics")
  var bodies: Array[Rect2] = []
  for fighter in s.enemy_views():
   if not fighter.visible: continue
   var sprite: AnimatedSprite2D = fighter.sprite
   var rect := Rect2(sprite.global_position, sprite.sprite_frames.get_frame_texture(&"attack",0).get_size() * sprite.global_scale)
   bodies.append(rect)
   t.check(rect.position.x >= 0 and rect.end.x <= 390, "full enemy frame bounds stay on canvas")
  for i in range(bodies.size()):
   for j in range(i+1,bodies.size()): t.check(not bodies[i].intersects(bodies[j]), "full enemy frames disjoint at rest")
 # Raw touch drives new controls, rejects held/repeated downs and hidden inputs.
 var tap := InputEventScreenTouch.new()
 tap.index = 0
 tap.pressed = true
 tap.position = ui.kira_button.get_global_rect().get_center()
 ui.kira_button._input(tap)
 t.check(s.model.selected_actor == &"kira", "native touch class selects Kira")
 tap.pressed = false
 ui.kira_button._input(tap)
 tap.pressed = true
 tap.position = ui.tide_button.get_global_rect().get_center()
 ui.tide_button._input(tap)
 ui.tide_button._input(tap)
 t.check(s.model.state == CombatModel.Phase.PLAYER_ATTACK and s.model.attacks == 0, "repeated native down commits exactly one pending action")
 tap.pressed = false
 ui.tide_button._input(tap)
 s.advance(0.3)
 t.check(s.model.attacks == 1, "single native touch impact")
 s.advance(3)
 s.pause_duel()
 t.check(not ui.visible and not ui.skills_open, "pause hides combat overlays")
 s._primary()
 s._title()
 t.check(s.run.selected_actor == &"main" and s.run.auto_companion and not ui.visible and not s.companion.visible, "scene reset removes selections and overlays")
 s.queue_free()
 await t.process_frame
