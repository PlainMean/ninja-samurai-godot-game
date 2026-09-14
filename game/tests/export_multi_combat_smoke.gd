extends SceneTree
## Independent release-pack entry point: executes mixed-actor full campaigns.
var checks := 0
func verify(ok: bool) -> void:
 checks += 1
 assert(ok)
func _initialize() -> void:
 call_deferred("run")
func run() -> void:
 var scene = load("res://scenes/duel.tscn").instantiate()
 root.add_child(scene)
 scene.set_process(false)
 scene.clock = func(): return 1000000
 scene.last_tick_usec = 1000000
 await process_frame
 var manual_actions := 0
 var skill_actions := 0
 var party_clears := 0
 for seed_value in [1,42,98765]:
  scene._title()
  scene.run.begin_area_run(seed_value)
  verify(scene.run.choose_loadout(0,[1,2]))
  for step in range(12):
   var choices: Array[int] = scene.run.next_nodes()
   verify(scene.run.choose_node(choices.back() if seed_value == 42 else choices.front()))
   scene._primary()
   var c: CombatModel = scene.model
   var party_size := c.enemies.size()
   verify(party_size in [1,2,3])
   for member in c.enemies:
    verify(member.spec.unit.attack_animation.get_frame_texture(&"attack",0).get_size() == Vector2(48,48))
   var rounds := 0
   while not c.terminal() and rounds < 24:
    verify(c.state == CombatModel.Phase.PLAYER_TURN)
    var slot: int = c.living_slots().back()
    scene.combat_controls.choose_target(slot)
    verify(c.target_slot == slot and scene.snapshot().enemy_max_hp == c.enemies[slot].spec.enemy_max_hp)
    if c.companion_hp > 0 and rounds%3 == 0:
     scene.combat_controls.choose_actor(&"kira")
     verify(scene.combat_controls.tide_button.visible)
     scene.combat_controls.use_tide()
     manual_actions += 1
     verify(c.active_skill == &"tide_arc")
    else:
     scene.combat_controls.choose_actor(&"main")
     var chosen: StringName = &""
     for skill in c.SKILLS:
      verify(skill.resource_path.begins_with("res://data/skills/") and not c.skill_forecast(skill.id).is_empty())
      if c.skill_available(skill.id) and chosen == &"": chosen = skill.id
     if chosen != &"":
      scene.combat_controls.open_skills()
      verify(scene.combat_controls.sheet.visible and scene.attack_buttons.all(func(b): return b.disabled))
      scene.combat_controls.use_skill(chosen)
      verify(c.active_skill == chosen and not scene.combat_controls.sheet.visible)
      skill_actions += 1
     else: scene._attack(Element.Type.FIRE)
    verify(c.state == CombatModel.Phase.PLAYER_ATTACK)
    scene.advance(0.6)
    while c.state in [CombatModel.Phase.ENEMY_TURN,CombatModel.Phase.ENEMY_ATTACK]: scene.advance(0.95)
    rounds += 1
   verify(c.state == CombatModel.Phase.WON and c.enemies.all(func(e): return e.hp == 0))
   if party_size > 1: party_clears += 1
   scene.advance(0.4)
   if scene.run.state == RunModel.State.RECRUIT:
    verify(scene.run.bosses_defeated() == 1 and scene.run.first_boss_defeated and not scene.combat_controls.visible)
    scene._primary()
   verify(scene.run.state == RunModel.State.LOOT)
   scene._area_action("loot",0)
   if scene.run.skill_level < 2: scene._area_action("skills",0)
   var element := 1
   while element < 5 and scene.run.techniques[element] == 3: element += 1
   scene._area_action("train",0 if element == 5 else element)
  verify(scene.run.state == RunModel.State.CLEARED and scene.run.seals == 12 and scene.run.bosses_defeated() == 4)
 verify(manual_actions > 0 and skill_actions > 0 and party_clears == 15)
 print("PASS independent exported multi-combat: %d checks, 3 full campaigns, %d party clears, %d Tide Arcs, %d skills" % [checks,party_clears,manual_actions,skill_actions])
 scene.queue_free()
 await process_frame
 quit()
