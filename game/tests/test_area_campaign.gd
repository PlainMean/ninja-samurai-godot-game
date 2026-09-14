extends RefCounted
func run(t) -> void:
 var r := RunModel.new()
 r.begin_area_run(42)
 t.check(r.area_encounters.size() == 12 and r.WEAPONS.size() == 6, "twelve migrated nodes and six swords")
 t.check(not r.choose_loadout(0,[1,1]), "reject duplicate starting techniques")
 t.check(r.choose_loadout(0,[1,2]), "choose starting pair and sword")
 t.check(r.next_nodes() == [0,1] and not r.choose_node(2), "normal fork before locked boss")
 var sequence: Array[int] = []
 for i in range(100): sequence.append(r.roll_weapon())
 t.check(sequence.min() == 1 and sequence.max() == 4, "inclusive roll bounds")
 r.begin_area_run(42)
 for roll in sequence: t.check(r.roll_weapon() == roll, "seed reset reproduces stream")
 r.begin_area_run(43)
 var other: Array[int] = []
 for i in range(100): other.append(r.roll_weapon())
 t.check(other != sequence, "seed variation")
 r.begin_area_run(42)
 r.choose_loadout(0,[1,2])
 for step in range(12):
  t.check(r.choose_node(r.next_nodes()[0]), "full clear reachable choice")
  var c := CombatModel.new()
  t.check(r.begin_encounter(c), "configure encounter")
  while not c.terminal():
   var e := 1
   var forecast := c.attack_forecast(e)
   t.check(c.request_attack(e), "unlocked technique accepted")
   c.step(0.3)
   for event in c.drain_events():
    if event.kind == CombatEvent.Kind.PLAYER_HIT:
     t.check(event.roll >= 1 and event.roll <= 4, "strike roll bounded")
     t.check(event.weapon_bonus == 1 + event.roll % 2, "same element parity bonus")
     t.check(event.damage == event.roll + event.weapon_bonus + event.technique_level - 1 + event.matchup_bonus, "additive damage")
     t.check(event.damage >= forecast.min and event.damage <= forecast.max, "forecast encloses actual")
   c.step(1.25 + 0.95 * (c.enemies.size() - 1))
  t.check(c.state == CombatModel.Phase.WON and r.resolve_encounter(c), "balanced full clear victory")
  if r.state == RunModel.State.RECRUIT: t.check(r.continue_recruit(), "explicit first-boss join acknowledgment")
  t.check(r.pending_loot in r.inventory and r.equip_weapon(0), "loot inventory and switch")
  t.check(r.finish_loot(), "loot confirmation shrine healing")
  var train_element := 1
  while train_element < 5 and r.techniques[train_element] == 3: train_element += 1
  if train_element == 5: train_element = 0
  t.check(r.train(train_element), "unlock or develop at shrine")
 t.check(r.state == RunModel.State.CLEARED and r.bosses_defeated() == 4, "all four bosses cleared")
 r.begin_area_run(42)
 t.check(r.cleared_nodes.is_empty() and r.rng_state == 42 and r.techniques == [0,0,0,0,0], "complete reset")
 # Every starting pair, sword and both traversal orders must support a clear.
 for pair in [[1,2],[1,3],[1,4],[2,3],[2,4],[3,4]]:
  for sword in range(4):
   for seed_value in [1,42,98765]:
    r.begin_area_run(seed_value)
    r.choose_loadout(sword,pair)
    for step in range(12):
     var nodes := r.next_nodes()
     t.check(not nodes.is_empty(), "no full-clear dead end")
     if nodes.is_empty(): return
     var n: int = nodes.back() if seed_value == 42 else nodes.front()
     t.check(r.choose_node(n), "alternate frontier accepted")
     var c := CombatModel.new()
     r.begin_encounter(c)
     var strikes := 0
     while not c.terminal() and strikes < 32:
      var e: int = pair[0]
      for candidate in range(1,5):
       if r.techniques[candidate] > 0 and c.attack_forecast(candidate).min > c.attack_forecast(e).min: e = candidate
      c.request_attack(e)
      c.step(1.55 + 0.95 * (c.enemies.size() - 1))
      strikes += 1
     t.check(c.state == CombatModel.Phase.WON, "all starting builds deterministic victory")
     if c.state != CombatModel.Phase.WON: return
     r.resolve_encounter(c)
     if r.state == RunModel.State.RECRUIT: t.check(r.continue_recruit(), "explicit first-boss join acknowledgment")
     t.check(r.WEAPONS[r.pending_loot].element == r.spec().element, "opponent sword matches affinity")
     r.finish_loot()
     var e := 1
     while e < 5 and r.techniques[e] == 3: e += 1
     r.train(0 if e == 5 else e)
    t.check(r.seals == 12 and r.bosses_defeated() == 4, "all-build full clear")
 var elements: Array[int] = []
 var ids: Array[StringName] = []
 for w in r.WEAPONS:
  t.check(w.id not in ids and not w.display_name.is_empty() and w.base_descriptor == "Seeded 1–4", "unique named weapon metadata")
  ids.append(w.id)
  if w.element not in elements: elements.append(w.element)
 elements.sort()
 t.check(elements == [1,2,3,4], "all four weapon elements")
 # Exhaustive additive forecast/actual matrix across weapons, levels and elements.
 for sword in range(6):
  for level in range(1,4):
   for e in range(1,5):
    for affinity in range(1,5):
     r.begin_area_run(42)
     r.inventory.assign([0,1,2,3,4,5])
     r.choose_loadout(sword,[1,2])
     r.techniques.assign([0,level,level,level,level])
     r.choose_node(0)
     var c := CombatModel.new()
     var fixture: EncounterSpec = r.spec().duplicate()
     fixture.element = affinity as Element.Type
     fixture.enemy_max_hp = 100
     c.configure(fixture,12,12)
     c.configure_weapon(r)
     c.start()
     var state_before := r.rng_state
     var forecast := c.attack_forecast(e)
     t.check(r.rng_state == state_before, "forecast does not consume RNG")
     c.request_attack(e)
     t.check(not c.request_attack(e) and r.rng_state == state_before, "rejected attack never rolls")
     c.step(0.3)
     for event in c.drain_events():
      if event.kind != CombatEvent.Kind.PLAYER_HIT: continue
      var same: bool = r.equipped_weapon().element == e
      t.check(event.weapon_bonus == (1 + event.roll % 2 if same else 0), "all sword element bonuses")
      t.check(event.matchup_bonus == int(Element.resolve(e,affinity)) and event.technique_level == level, "typed matchup and technique")
      t.check(event.damage == event.roll + event.weapon_bonus + level - 1 + event.matchup_bonus, "complete additive matrix")
      t.check(event.damage >= forecast.min and event.damage <= forecast.max, "complete forecast matrix")
      t.check(event.element == e and Element.effect_color(e) == [Color("ef493c"),Color("328ee6"),Color("a47746"),Color.WHITE][e-1], "typed effect exact color metadata")
 r.begin_area_run(42)
 r.choose_loadout(0,[1,2])
 r.cleared_nodes.assign([0,1])
 t.check(r.choose_node(2), "boss unlock after both guards")
 var boss := CombatModel.new()
 r.hp = 1
 r.begin_encounter(boss)
 t.check(not boss.request_attack(4), "locked technique rejected by model")
 boss.request_attack(1)
 boss.step(1.55)
 t.check(boss.state == CombatModel.Phase.LOST and r.resolve_encounter(boss) and r.state == RunModel.State.FAILED, "boss loss")
 t.check(not r.resolve_encounter(boss) and not r.equip_weapon(1), "terminal resolution idempotent and equip phase guarded")
 r.begin_area_run(42)
 t.check(r.hp == 12 and r.state == RunModel.State.LOADOUT and r.rng_state == 42 and r.cleared_nodes.is_empty(), "boss retry reset")
