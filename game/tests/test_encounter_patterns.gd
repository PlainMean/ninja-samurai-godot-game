extends RefCounted
const C = preload("res://scripts/combat_model.gd")
const R = preload("res://scripts/run_model.gd")
const D = StrikeSpec.Defense
const K = CombatEvent.Kind

func make(index := 0, hp := 5, bonus := 0) -> CombatModel:
	var m := C.new()
	m.configure(R.ENCOUNTERS[index], hp, maxi(5, hp), bonus)
	m.start()
	return m

func values(m: CombatModel) -> Array:
	return m.drain_events().map(func(e: CombatEvent): return e.values())

func count_events(m: CombatModel, kind: CombatEvent.Kind) -> int:
	return m.drain_events().filter(func(e: CombatEvent): return e.kind == kind).size()

func defend_pattern(m: CombatModel) -> void:
	if m.state == C.Phase.REST: m.step(m.duration())
	while m.state == C.Phase.TELEGRAPH:
		m.request_defense(m.strike().defense_required)
		m.step(m.duration() + 0.6)

func run(t) -> void:
	var m := C.new()
	t.check(m.state == C.Phase.READY and m.player_hp == 5 and m.enemy_hp == 3, "ready health")
	m.step(99)
	t.check(m.state == C.Phase.READY and not m.request_block() and not m.request_dodge() and not m.request_strike(), "ready inert")
	for index in range(3):
		for hz in [30, 60, 120]:
			m = make(index)
			var a := make(index)
			a.step(100)
			for i in range(100 * hz): m.step(1.0 / hz)
			t.check(m.state == a.state and m.player_hp == a.player_hp and values(m) == values(a), "coarse/fine events %d %dHz" % [index,hz])
		for p in range(R.ENCOUNTERS[index].patterns.size()):
			for s in range(R.ENCOUNTERS[index].patterns[p].strikes.size()):
				for choice in [D.NONE, D.BLOCK, D.DODGE]:
					m = make(index)
					m.pattern_index = p
					m.strike_index = s
					m.step(m.duration())
					var expected: bool = choice == m.strike().defense_required
					m.step(m.duration() - 0.001)
					if choice != D.NONE:
						t.check(m.request_defense(choice) and not m.request_defense(D.BLOCK) and not m.request_defense(D.DODGE), "last ms defense irreversible")
					m.step(0.001)
					t.check(not m.request_block() and not m.request_dodge() and not m.request_strike(), "exact warning deadline/early strike rejected")
					m.step(0.299)
					t.check(m.player_hp == 5 and not m.impact_resolved, "299ms no impact")
					m.step(0.001)
					t.check(m.player_hp == (5 if expected else 4) and m.impact_resolved, "300ms correct impact")
					t.check(count_events(m, K.DEFENDED if expected else K.DAMAGE) == 1, "one typed impact event")
					m.step(0.299)
					t.check(m.state == C.Phase.ENEMY_ATTACK, "599ms still attacking")
					m.step(0.001)
					t.check(m.state != C.Phase.ENEMY_ATTACK and count_events(m, K.DAMAGE) == 0, "600ms recovery without duplicate")
		for bonus in [0,300]:
			for late in [false,true]:
				m = make(index,5,bonus)
				defend_pattern(m)
				t.check(m.state == C.Phase.COUNTER_WINDOW and is_equal_approx(m.duration(), (m.spec.counter_ms+bonus)/1000.0), "one opening exact configured length")
				m.step(m.duration() - (0.0 if late else 0.001))
				t.check(m.request_strike() == not late and not m.request_strike(), "counter half-open deadline")
				if not late:
					m.step(0.299)
					t.check(m.enemy_hp == m.spec.enemy_max_hp, "counter 299ms")
					m.step(0.001)
					t.check(m.enemy_hp == m.spec.enemy_max_hp-1 and count_events(m,K.COUNTER)==1, "counter 300ms once")
					m.step(0.299)
					t.check(m.state == C.Phase.PLAYER_ATTACK, "counter 599ms")
					m.step(0.001)
					t.check(m.state == C.Phase.REST and m.player_hp == 5, "counter full recovery")
	# Every double-cut outcome, including independent second defense and no early opening.
	for first in [false,true]:
		for second in [false,true]:
			m = make(1)
			m.step(0.65)
			if first: m.request_block()
			m.step(1.45)
			t.check(m.state == C.Phase.TELEGRAPH and m.strike_index==1 and not m.block_latched and not m.request_strike(), "second fresh warning no intervening opening")
			if second: m.request_block()
			m.step(1.3)
			t.check(m.player_hp == 5-int(not first)-int(not second), "combo independent damage")
			t.check((m.state == C.Phase.COUNTER_WINDOW) == (first and second), "all strikes required for opening")
	for lethal_strike in [0,1]:
		m = make(1,1)
		m.step(0.65)
		if lethal_strike==1:
			m.request_block()
			m.step(1.45)
		m.step(m.duration()+0.3)
		t.check(m.player_hp==0 and m.state==C.Phase.ENEMY_ATTACK and m.strike_index==lethal_strike,"lethal combo waits")
		m.step(0.299)
		t.check(not m.terminal(),"lethal recovery 599ms")
		m.step(0.001)
		t.check(m.state==C.Phase.LOST and count_events(m,K.LOST)==1,"lethal cancels remaining combo once")
		m.step(100)
		t.check(m.drain_events().is_empty(),"terminal frozen")
	# Master advancement occurs only at pattern resolution.
	for outcome in ["miss","expire","counter"]:
		m = make(2,100)
		for cycle in range(9):
			t.check(m.pattern_index==cycle%3,"master cycle "+outcome)
			m.step(m.duration())
			while m.state==C.Phase.TELEGRAPH:
				if outcome!="miss": m.request_defense(m.strike().defense_required)
				m.step(m.duration()+0.6)
			if outcome=="expire": m.step(m.duration())
			if outcome=="counter":
				m.enemy_hp=5
				m.request_strike()
				m.step(0.599)
				t.check(m.pattern_index==cycle%3,"accepted strike defers advancement")
				m.step(0.001)
	# Pause both sides of impacts in each strike and every phase.
	for index in range(3):
		for p in range(R.ENCOUNTERS[index].patterns.size()):
			for s in range(R.ENCOUNTERS[index].patterns[p].strikes.size()):
				for at in [0.0,0.299,0.3,0.599]:
					for correct in [false,true]:
						m=make(index)
						m.pattern_index=p
						m.step(m.duration())
						if s==1: m.step(m.duration()+0.6)
						var prior := m.all_defended
						if correct: m.request_defense(m.strike().defense_required)
						m.step(m.duration()+at)
						var hp := m.player_hp
						var defended := m.all_defended
						m.prepare_resume()
						t.check(m.pattern_index==p and m.strike_index==s and m.player_hp==hp,"pause preserves identity/hp")
						if at<0.3:
							t.check(m.state==C.Phase.TELEGRAPH and m.elapsed==0 and not m.block_latched and m.all_defended==prior,"unresolved restart preserves earlier combo outcome")
						else:
							t.check(m.state==C.Phase.ENEMY_ATTACK and m.impact_resolved and m.all_defended==defended,"resolved pause retains result")
							m.step(0.6-at)
							t.check(m.player_hp==hp,"resolved resume no duplicate damage")
		m=make(index)
		m.step(0.2)
		m.prepare_resume()
		t.check(is_equal_approx(m.elapsed,0.2),"rest pause retains time")
		m.step(m.duration()-m.elapsed)
		m.request_defense(m.strike().defense_required)
		m.step(0.1)
		m.prepare_resume()
		t.check(m.elapsed==0 and not m.block_latched,"warning pause resets latch")
		defend_pattern(m)
		m.step(0.2)
		m.prepare_resume()
		t.check(m.elapsed==0 and m.state==C.Phase.COUNTER_WINDOW,"opening restarts")
		m.request_strike()
		for at in [0.299,0.3,0.599]:
			m.step(at-m.elapsed)
			m.prepare_resume()
			t.check(is_equal_approx(m.elapsed,at),"player pause retains elapsed")
		m.step(0.001)
		t.check(count_events(m,K.COUNTER)==1,"player pause single impact")
	m=make()
	for delta in [0.0,-1.0,NAN,INF,-INF]: m.step(delta)
	t.check(m.elapsed==0 and m.state==C.Phase.REST,"invalid delta inert")
	for i in range(3):
		defend_pattern(m)
		m.request_strike()
		m.step(0.3)
		t.check(m.state==C.Phase.PLAYER_ATTACK,"lethal counter waits")
		m.step(0.3)
	t.check(m.state==C.Phase.WON and m.counters==3 and count_events(m,K.WON)==1,"three gate counters win once")
	m.step(100)
	t.check(m.drain_events().is_empty(),"won frozen")
