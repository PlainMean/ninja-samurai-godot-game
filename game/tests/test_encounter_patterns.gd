extends RefCounted
## Element matrix and exhaustive resolution boundaries replace reactive patterns.
const C = preload("res://scripts/combat_model.gd")
const R = preload("res://scripts/run_model.gd")
const E = Element.Type

func make(index := 0, hp := 5, affinity: Element.Type = E.NONE) -> CombatModel:
	var m := C.new()
	m.configure(R.ENCOUNTERS[index], hp, maxi(5, hp), affinity)
	m.start()
	return m

func values(m: CombatModel) -> Array:
	return m.drain_events().map(func(e: CombatEvent): return e.values())

func run(t) -> void:
	# Independent literal oracle: rows/columns FIRE WATER EARTH WIND.
	var matrix := [[1,1,2,1],[2,1,1,1],[1,1,1,2],[1,2,1,1]]
	for attacker in range(1,5):
		for defender in range(1,5):
			var expected: int = matrix[attacker-1][defender-1]
			t.check(Element.damage_for(attacker,defender)==expected, "exact directed damage matrix %d/%d" % [attacker,defender])
			t.check(Element.resolve(attacker,defender)==(Element.Matchup.EFFECTIVE if expected==2 else Element.Matchup.NEUTRAL), "exact matchup label")
	for element in range(5):
		t.check(Element.damage_for(element,E.NONE)==1 and Element.resolve(element,E.NONE)==Element.Matchup.NEUTRAL,"no affinity neutral")
	var m := C.new()
	m.step(1000)
	t.check(m.state==C.Phase.READY and not m.request_attack(E.WIND),"intro rejects time/input")
	for index in range(3):
		t.check(R.ENCOUNTERS[index].element==E.WATER,"all current guardians WATER")
		for element in range(1,5):
			for affinity in range(5):
				m=make(index,5,affinity)
				m.step(100000)
				t.check(m.state==C.Phase.PLAYER_TURN and m.player_hp==5 and m.turn_number==1 and m.elapsed==0,"unlimited player decision")
				t.check(not m.request_attack(E.NONE),"no empty attack")
				t.check(m.request_attack(element) and not m.request_attack(E.WIND),"attack accepts once and locks selection")
				t.check(m.selected_element==element and m.player_affinity==affinity,"attack selection does not invent affinity")
				m.step(0.299)
				t.check(m.enemy_hp==[3,4,5][index] and not m.impact_resolved,"player before impact")
				m.step(0.001)
				var dealt: int = matrix[element-1][1]
				t.check(m.enemy_hp==[3,4,5][index]-dealt and m.attacks==1,"player exact impact")
				var events := m.drain_events()
				t.check(events.size()==1 and events[0].kind==CombatEvent.Kind.PLAYER_HIT and events[0].element==element and events[0].damage==dealt and events[0].turn==1,"typed player event")
				m.prepare_resume()
				m.step(0.3)
				t.check(m.state==C.Phase.ENEMY_TURN and m.enemy_hp==[3,4,5][index]-dealt and not m.request_attack(E.WIND),"enemy turn automatic after recovery; no duplicate")
				m.step(0.35)
				t.check(m.state==C.Phase.ENEMY_ATTACK and not m.request_attack(E.FIRE),"enemy resolves without input")
				m.step(0.299)
				t.check(m.player_hp==5,"enemy before impact")
				m.step(0.001)
				var received := 2 if affinity==E.FIRE else 1
				t.check(m.player_hp==5-received and m.damage==received,"WATER versus current affinity exact damage")
				events=m.drain_events()
				t.check(events.size()==1 and events[0].kind==CombatEvent.Kind.ENEMY_HIT and events[0].element==E.WATER and events[0].damage==received,"typed water event")
				m.prepare_resume()
				m.step(0.3)
				t.check(m.state==C.Phase.PLAYER_TURN and m.turn_number==2 and m.player_hp==5-received and m.drain_events().is_empty(),"one enemy attack then next player turn")
			for hz in [30,60,120]:
				var a := make(index)
				var b := make(index)
				a.request_attack(element)
				b.request_attack(element)
				a.step(100)
				for frame in range(3*hz): b.step(1.0/hz)
				t.check(a.state==b.state and a.player_hp==b.player_hp and a.enemy_hp==b.enemy_hp and a.turn_number==b.turn_number and values(a)==values(b),"coarse/fine full event determinism")
		# Pause at all meaningful boundaries, both attackers, enemy announcement.
		for at in [0.0,0.299,0.3,0.599,0.6,0.949,0.95,1.249,1.25,1.549]:
			m=make(index)
			m.request_attack(E.FIRE)
			m.step(at)
			var before := [m.state,m.elapsed,m.player_hp,m.enemy_hp,m.impact_resolved]
			m.prepare_resume()
			t.check(before==[m.state,m.elapsed,m.player_hp,m.enemy_hp,m.impact_resolved],"pause preserves exact phase/impact")
			m.step(100)
			t.check(m.player_hp==4 and m.enemy_hp==[2,3,4][index] and m.attacks==1 and m.damage==1,"resume no duplicate impacts")
	m=make()
	for delta in [0.0,-1.0,NAN,INF,-INF]: m.step(delta)
	t.check(m.state==C.Phase.PLAYER_TURN and m.elapsed==0,"invalid delta inert")
	m.request_attack(E.WIND)
	m.step(100)
	m.request_attack(E.WIND)
	m.step(0.3)
	t.check(m.enemy_hp==0 and m.state==C.Phase.PLAYER_ATTACK,"lethal impact preserves animation")
	m.step(100)
	t.check(m.state==C.Phase.WON and m.player_hp==4 and m.turn_number==2 and m.attacks==2,"lethal player cancels enemy turn")
	var events := m.drain_events()
	t.check(events.filter(func(e): return e.kind==CombatEvent.Kind.WON).size()==1,"one win event")
	m.step(100)
	t.check(m.drain_events().is_empty() and not m.request_attack(E.WIND),"win frozen")
	m=make(2,1,E.FIRE)
	m.request_attack(E.FIRE)
	m.step(1.25)
	t.check(m.player_hp==0 and m.damage==1 and m.state==C.Phase.ENEMY_ATTACK,"lethal WATER clamps hp and actual damage statistics")
	m.step(100)
	t.check(m.state==C.Phase.LOST and m.turn_number==1,"loss no next player turn")
	events=m.drain_events()
	t.check(events.filter(func(e): return e.kind==CombatEvent.Kind.LOST).size()==1,"one loss event")
	m.step(100)
	t.check(m.drain_events().is_empty() and not m.request_attack(E.WIND),"loss frozen")
	t.check(m.combat_log.size()==2 and 'EFFECTIVE' in m.combat_log[1] and '2 dmg' in m.combat_log[1],"log keeps nominal effective damage")
