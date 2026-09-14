extends RefCounted
func battle(count := 2) -> CombatModel:
 var r := RunModel.new()
 r.begin_area_run(42)
 r.choose_loadout(0,[1,2])
 r.companion_joined = true
 r.companion_hp = 6
 var encounter: EncounterSpec = r.area_encounters[0].duplicate()
 encounter.party = []
 for i in range(count):
  var member: EncounterSpec = r.area_encounters[i].duplicate()
  member.enemy_max_hp = 12
  member.party = []
  encounter.party.append(member)
 var c := CombatModel.new()
 c.configure(encounter,12,12)
 c.configure_weapon(r)
 c.configure_companion(r)
 c.configure_actions(r)
 c.start()
 return c
func run(t) -> void:
 var solo := CombatModel.new()
 solo.start()
 t.check(not solo.select_actor(&"kira") and solo.select_actor(&"main"), "absent Kira rejected, main remains available")
 for count in [1,2,3]:
  var c := battle(count)
  t.check(c.enemies.size() == count and c.target_slot == 0, "typed party default target")
  t.check(c.select_target(count-1) and not c.select_target(count), "explicit living target bounds")
  t.check(c.select_actor(&"kira"), "Kira selectable")
  var seed_before := c.weapon_run.rng_state
  t.check(c.request_kira_attack() and not c.select_actor(&"main") and not c.select_target(0), "actor and target locked at action commit")
  c.step(0.3)
  var event: CombatEvent = c.drain_events()[0]
  t.check(event.kind == CombatEvent.Kind.KIRA_ATTACK and event.actor == &"kira" and event.skill_id == &"tide_arc" and event.target_slot == count-1, "typed Tide Arc identity")
  t.check(event.damage == 4 and event.element == Element.Type.WATER and event.party_hp[count-1] == 8 and c.weapon_run.rng_state == seed_before, "Tide Arc WATER advantage without sword RNG")
  c.step(100)
  var replies := c.drain_events().filter(func(e): return e.kind == CombatEvent.Kind.ENEMY_HIT)
  t.check(replies.size() == count and c.turn_number == 2 and c.state == CombatModel.Phase.PLAYER_TURN, "exactly one reply per living slot, then player turn")
  for i in range(count): t.check(replies[i].target_slot == i and replies[i].turn == 1, "stable reply slot order")
 for skill in CombatModel.SKILLS:
  var c := battle(3)
  c.set_auto_companion(false)
  var before := c.weapon_run.rng_state
  var forecast := c.skill_forecast(skill.id)
  t.check(c.request_skill(skill.id) and not c.request_skill(skill.id), "skill accepted once")
  c.step(100)
  var stream := c.drain_events()
  t.check(stream[0].kind == CombatEvent.Kind.SKILL and stream[0].skill_id == skill.id and stream[0].damage == forecast.damage, "typed skill agrees with forecast")
  t.check(c.player_hp == 12-forecast.reply and c.weapon_run.rng_state == before, "skill guard evade forecast and zero RNG")
  t.check(c.cooldowns[skill.id] == 2 and not c.skill_available(skill.id), "two intervening turns cooldown")
  for turn in range(2):
   c.select_actor(&"main")
   c.request_attack(Element.Type.WATER)
   c.step(100)
   c.select_actor(&"main")
  t.check(c.skill_available(skill.id), "cooldown expires after two other actions")
  c.reset()
  t.check(c.cooldowns.is_empty() and c.guard == 0 and not c.evade and c.selected_actor == &"main", "combat reset clears action state")
 var c := battle(2)
 c.enemies[0].hp = 1
 c.enemies[1].hp = 1
 c.select_actor(&"kira")
 c.request_kira_attack()
 c.step(100)
 t.check(c.target_slot == 1 and not c.select_target(0) and c.player_hp == 11, "dead target fallback and lethal slot suppression")
 c.request_kira_attack()
 c.step(100)
 t.check(c.state == CombatModel.Phase.WON and c.player_hp == 11, "full party clear suppresses final reply")
 var a := battle(3)
 var b := battle(3)
 a.select_target(2)
 b.select_target(2)
 a.request_skill(&"windstep")
 b.request_skill(&"windstep")
 a.step(100)
 for i in range(1000): b.step(0.01)
 t.check(a.drain_events().map(func(e): return e.values()) == b.drain_events().map(func(e): return e.values()), "complete typed replay equality across step partitions")
 var r := RunModel.new()
 r.begin_area_run()
 r.state = RunModel.State.TRAINING
 t.check(r.develop_skills() and not r.develop_skills() and r.skill_level == 1, "one shrine skill development")
 r.begin_area_run()
 t.check(r.skill_level == 0 and not r.skill_trained and r.selected_actor == &"main" and r.auto_companion, "run reset action preferences and development")
