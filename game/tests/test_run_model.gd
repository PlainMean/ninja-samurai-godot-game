extends RefCounted
const R = preload("res://scripts/run_model.gd")
const C = preload("res://scripts/combat_model.gd")
const Patterns = preload("res://tests/test_encounter_patterns.gd")

func run(t) -> void:
	for first in [&"mend",&"long_breath"]:
		for second in [&"mend",&"iron_resolve"]:
			var r := R.new()
			var m := C.new()
			t.check(not r.begin_encounter(m) and not r.choose_reward(first) and not r.resolve_encounter(m),"invalid title actions inert")
			t.check(r.begin_run() and not r.begin_run() and r.hp==5 and r.max_hp==5,"initial run")
			for index in range(3):
				t.check(r.encounter_index==index and r.spec().enemy_max_hp==[3,4,5][index],"fixed encounter order/hp")
				var starting_hp := r.hp
				t.check(r.begin_encounter(m) and not r.begin_encounter(m),"fresh encounter once")
				t.check(m.player_hp==starting_hp and m.pattern_index==0 and m.strike_index==0,"health carry/fresh indices")
				t.check(not r.choose_reward(first) and not r.resolve_encounter(m),"fight cannot choose/handoff early")
				# Sustain a real missed pattern to make both healing branches available.
				m.step(m.duration())
				while m.state==C.Phase.TELEGRAPH: m.step(m.duration()+0.6)
				for hit in range(m.spec.enemy_max_hp):
					Patterns.new().defend_pattern(m)
					m.request_strike()
					m.step(0.6)
				t.check(r.resolve_encounter(m) and not r.resolve_encounter(m),"handoff once")
				t.check(r.seals==index+1 and r.hp==m.player_hp,"one seal and final health copied")
				if index<2:
					var id: StringName = first if index==0 else second
					var before := r.hp
					t.check(r.choose_reward(id) and not r.choose_reward(id),"reward one tap once")
					t.check(r.hp==(mini(r.max_hp,before+2) if id==&"mend" else (before+1 if id==&"iron_resolve" else before)),"reward numeric effect")
			t.check(r.state==R.State.CLEARED and r.seals==3 and r.counters==12 and not r.begin_encounter(m),"no fourth encounter; 12 landed counters")
			t.check(r.max_hp==(6 if second==&"iron_resolve" else 5) and r.counter_bonus_ms==(300 if first==&"long_breath" else 0),"upgrade combinations")
			r.begin_run()
			t.check(r.hp==5 and r.max_hp==5 and r.seals==0 and r.upgrades.is_empty() and r.counters==0 and r.defenses==0 and r.damage==0 and r.counter_bonus_ms==0,"full reset")
	var r := R.new()
	var m := C.new()
	r.begin_run()
	r.begin_encounter(m)
	for i in range(3):
		Patterns.new().defend_pattern(m)
		m.request_strike()
		m.step(0.6)
	r.resolve_encounter(m)
	t.check(not r.can_choose(&"mend") and not r.choose_reward(&"mend") and r.can_choose(&"long_breath"),"full health mend disabled")
	r.hp=4
	t.check(r.choose_reward(&"mend") and r.hp==5,"healing clamps")
	r.begin_encounter(m)
	m.step(100)
	t.check(r.resolve_encounter(m) and r.state==R.State.FAILED and r.seals==1 and r.damage==5,"loss statistics actual hp")
	r.begin_run()
	t.check(r.encounter_index==0 and r.seals==0,"retry no checkpoint")
	t.check(r.return_to_title() and r.state==R.State.TITLE and not r.return_to_title(),"return discards run")
	for spec in R.ENCOUNTERS:
		t.check(spec.enemy_max_hp in [3,4,5] and spec.patterns[0].strikes[0].warning_ms>0,"shared specs remain unchanged")
