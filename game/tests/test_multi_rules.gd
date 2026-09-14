extends RefCounted
const Fixture = preload("res://tests/test_multi_combat.gd")
func run(t) -> void:
 # Independent WATER oracle: not derived from CombatModel.kira_damage/forecast.
 for sword in range(6):
  for level in range(3):
   for defender in range(1,5):
    for seed_value in [1,42,98765]:
     var c := Fixture.new().battle(2)
     c.weapon_run.equipped = sword
     c.weapon_run.rng_state = seed_value
     c.weapon_run.techniques.assign([0,0,0,0,0])
     c.companion_level = level
     c.enemies[1].spec.element = defender as Element.Type
     c.select_target(1)
     c.select_actor(&"kira")
     var before := c.weapon_run.rng_state
     var expected := 3 + level + int(defender == Element.Type.FIRE)
     var f := c.attack_forecast(Element.Type.WATER)
     t.check(f.min == expected and f.max == expected and c.weapon_run.rng_state == before, "Kira exact independent WATER oracle and pure forecast")
     t.check(c.request_kira_attack(), "Tide Arc independent of every sword and locked techniques")
     c.step(0.3)
     var events := c.drain_events()
     t.check(events.size() == 1 and events[0].damage == expected and events[0].roll == 0 and events[0].weapon_bonus == 0, "manual action never double-supports or rolls")
     t.check(events[0].target_slot == 1 and events[0].target_actor == &"enemy" and events[0].party_hp == [12,12-expected], "Kira exact per-slot snapshot")
     t.check(c.weapon_run.rng_state == seed_value and c.attacks == 1 and c.companion_hp == 6, "Kira action consumes a turn without fatigue before reply")
 var c := Fixture.new().battle(3)
 c.companion_hp = 1
 c.select_actor(&"kira")
 c.request_kira_attack()
 c.step(100)
 var kinds := c.drain_events().map(func(e): return e.kind)
 t.check(kinds == [CombatEvent.Kind.KIRA_ATTACK,CombatEvent.Kind.ENEMY_HIT,CombatEvent.Kind.COMPANION_HURT,CombatEvent.Kind.ENEMY_HIT,CombatEvent.Kind.ENEMY_HIT], "exact manual phase event ordering with one-HP Kira")
 t.check(c.companion_hp == 0 and c.selected_actor == &"main" and c.run_owner.selected_actor == &"main", "fallen Kira selects and persists main fallback")
 t.check(not c.select_actor(&"kira") and not c.request_kira_attack() and c.request_attack(Element.Type.FIRE), "fallen ally unavailable while hero continues")
 c.step(100)
 t.check(c.companion_hp == 0, "fallen HP never becomes negative")
 for skill in CombatModel.SKILLS:
  for level in range(3):
   for defender in range(1,5):
    for count in [1,2,3]:
     c = Fixture.new().battle(count)
     c.set_auto_companion(false)
     c.skill_level = level
     c.select_target(count-1)
     c.enemies[count-1].spec.element = defender as Element.Type
     var effective := int([0,3,1,4,2][skill.element] == defender)
     var expected: int = skill.base_damage + level + effective if skill.base_damage > 0 else 0
     var expected_block: int = 3+level if skill.id == &"stone_guard" else 0
     var expected_incoming := maxi(0,count-expected_block-int(skill.id == &"windstep"))
     var seed_before := c.weapon_run.rng_state
     t.check(c.select_actor(&"kira") and not c.request_skill(skill.id), "main skills reject Kira actor")
     c.select_actor(&"main")
     var f := c.skill_forecast(skill.id)
     t.check(f.damage == expected and f.guard == expected_block and f.reply == expected_incoming, "independent exact skill formula and reply forecast")
     t.check(c.request_skill(skill.id), "all three skill resources available independent of technique locks")
     c.step(0.3)
     var action: CombatEvent = c.drain_events()[0]
     t.check(action.kind == CombatEvent.Kind.SKILL and action.actor == &"main" and action.target_slot == count-1 and action.skill_id == skill.id and action.damage == expected and action.guard == expected_block, "skill event full identity and effect snapshot")
     t.check(c.enemies[count-1].hp == 12-expected, "skill exact selected HP mutation")
     c.step(100)
     t.check(c.player_hp == 12-expected_incoming and c.companion_hp == 6-count+int(skill.evade) and c.weapon_run.rng_state == seed_before, "skill effect and fatigue resolve without RNG")
     t.check(c.guard == 0 and not c.evade and c.cooldowns[skill.id] == 2, "defense expires after reply phase and cooldown advances once per round")
 # Mixed elemental replies, ordered guard depletion and Ward Pulse applied only once.
 c = Fixture.new().battle(3)
 c.player_affinity = Element.Type.FIRE
 c.enemies[0].spec.attack_elements.assign([Element.Type.WATER])
 c.enemies[1].spec.attack_elements.assign([Element.Type.WATER])
 c.companion_ability = &"ward_pulse"
 c.request_skill(&"stone_guard")
 c.step(100)
 var replies := c.drain_events().filter(func(e): return e.kind == CombatEvent.Kind.ENEMY_HIT)
 t.check(replies.map(func(e): return e.damage) == [0,1,1] and c.player_hp == 10, "guard pool then one Ward Pulse in stable mixed reply order")
 # A lethal selected slot must not manufacture an auto ward for other enemies.
 c = Fixture.new().battle(2)
 c.companion_ability = &"ward_pulse"
 c.enemies[0].hp = 1
 var f := c.attack_forecast(Element.Type.FIRE)
 t.check(f.reply == 1, "lethal-target forecast does not invent support ward")
 c.request_attack(Element.Type.FIRE)
 c.step(100)
 t.check(c.player_hp == 11 and c.target_slot == 1, "lethal slot skipped but other slot replies")
 c = Fixture.new().battle(3)
 c.player_hp = 1
 c.request_attack(Element.Type.WATER)
 c.step(100)
 var stream := c.drain_events()
 t.check(c.state == CombatModel.Phase.LOST and stream.filter(func(e): return e.kind == CombatEvent.Kind.ENEMY_HIT).size() == 1 and stream.back().kind == CombatEvent.Kind.LOST, "player death cancels remaining reply queue")
 # Every old area encounter is still independently playable as a single opponent.
 var r := RunModel.new()
 r.begin_area_run(42)
 r.choose_loadout(0,[1,2])
 for area_spec in r.area_encounters:
  var original: EncounterSpec = load("res://data/encounters/areas/%s.tres" % area_spec.unit.unit_id)
  c = CombatModel.new()
  c.configure(original,12,12)
  c.configure_weapon(r)
  c.start()
  t.check(c.enemies.size() == 1 and c.spec == original, "original area single encounter remains executable")
  while not c.terminal():
   t.check(c.request_attack(Element.Type.FIRE), "single normal attack remains available")
   c.step(1.55)
  t.check(c.state == CombatModel.Phase.WON, "single original area clear regression")
 # Actor preference, disabled auto and upgrades survive loot, shrine and map.
 r.begin_area_run(42)
 r.choose_loadout(0,[1,2])
 r.companion_joined = true
 r.companion_hp = 6
 r.choose_node(0)
 c = CombatModel.new()
 r.begin_encounter(c)
 c.select_actor(&"kira")
 c.set_auto_companion(false)
 c.enemies[0].hp = 1
 c.request_kira_attack()
 c.step(100)
 t.check(r.resolve_encounter(c) and r.selected_actor == &"kira" and not r.auto_companion and r.companion_hp == 6, "manual choice carried into loot")
 r.finish_loot()
 t.check(r.develop_skills() and r.train(1) and r.selected_actor == &"kira", "skill development preserves actor and existing training")
 r.choose_node(1)
 r.begin_encounter(c)
 t.check(c.selected_actor == &"kira" and not c.auto_companion and c.skill_level == 1 and c.cooldowns.is_empty(), "new fight restores preferences and clears per-encounter cooldowns")
 r.state = RunModel.State.TRAINING
 r.skill_trained = false
 t.check(r.develop_skills() and r.skill_level == 2, "skill development reaches cap")
 r.skill_trained = false
 t.check(not r.develop_skills(), "skill development cannot exceed cap")
 r.return_to_title()
 t.check(r.skill_level == 0 and r.selected_actor == &"main" and r.auto_companion and not r.companion_joined, "title resets complete progression")
 # Full replay with alternating actors, targets, auto, skills and normal seeded rolls.
 var first := replay()
 var second := replay()
 t.check(first == second and first.size() > 15, "full mixed-action deterministic event stream equality")
func replay() -> Array:
 var c := Fixture.new().battle(3)
 c.player_hp = 40
 c.player_max_hp = 40
 c.companion_hp = 30
 var result := []
 var actions := [&"windstep",&"kira",&"fire",&"stone_guard",&"flame_dash"]
 var turn := 0
 while not c.terminal() and turn < 20:
  c.select_target(c.living_slots().back())
  c.set_auto_companion(turn%2 == 0)
  var id: StringName = actions[turn%actions.size()]
  c.select_actor(&"kira" if id == &"kira" else &"main")
  if id == &"kira": assert(c.request_kira_attack())
  elif id == &"fire": assert(c.request_attack(Element.Type.FIRE))
  else: assert(c.request_skill(id))
  c.step(100)
  result.append_array(c.drain_events().map(func(e): return e.values()))
  turn += 1
 assert(c.state == CombatModel.Phase.WON)
 return result
