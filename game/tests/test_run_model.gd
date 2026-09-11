extends RefCounted
const R = preload("res://scripts/run_model.gd")
const C = preload("res://scripts/combat_model.gd")
const E = Element.Type
func run(t) -> void:
	for first in [&"mend",&"long_breath"]:
		for second in [&"mend",&"iron_resolve"]:
			var r := R.new()
			var m := C.new()
			t.check(not r.begin_encounter(m) and not r.choose_reward(first) and not r.resolve_encounter(m),"invalid title actions inert")
			t.check(r.begin_run() and not r.begin_run() and r.hp==5 and r.max_hp==5,"initial run")
			for index in range(8):
				t.check(r.encounter_index==index and r.spec().enemy_max_hp==[3,4,5,3,4,4,5,5][index] and r.spec().element==[2,1,3,4,2,1,3,2][index],"fixed encounter order/hp/element")
				var starting_hp := r.hp
				t.check(r.begin_encounter(m) and not r.begin_encounter(m),"fresh encounter once")
				t.check(m.player_hp==starting_hp and m.turn_number==1 and m.selected_element==E.NONE and m.player_affinity==E.NONE,"health carry/fresh turn")
				t.check(not r.choose_reward(first) and not r.resolve_encounter(m),"fight cannot choose/handoff early")
				while not m.terminal():
					t.check(m.request_attack(Element.weakness(r.spec().element)),"run weakness accepted")
					m.step(100)
				t.check(r.resolve_encounter(m) and not r.resolve_encounter(m),"handoff once")
				t.check(r.seals==index+1 and r.hp==m.player_hp,"one seal and final health copied")
				if index<7:
					var id: StringName = first if index==0 else (second if index==1 else &"mend")
					var before := r.hp
					var max_before := r.max_hp
					t.check(r.choose_reward(id) and not r.choose_reward(id),"reward one tap once")
					t.check(r.hp==(mini(r.max_hp,before+2) if id==&"mend" else before+1),"reward numeric healing")
					t.check(r.max_hp==max_before+int(id!=&"mend"),"reward numeric max health")
			t.check(r.state==R.State.CLEARED and r.seals==8 and r.attacks==19 and r.damage==11 and not r.begin_encounter(m),"no ninth encounter; nineteen effective attacks/eleven enemy hits")
			t.check(r.max_hp==5+int(first==&"long_breath")+int(second==&"iron_resolve"),"upgrade combinations stack")
			r.begin_run()
			t.check(r.hp==5 and r.max_hp==5 and r.seals==0 and r.upgrades.is_empty() and r.attacks==0 and r.damage==0,"full reset")
	var r := R.new()
	var m := C.new()
	r.begin_run()
	r.begin_encounter(m)
	# Isolate the full-health reward guard from combat balance.
	m.enemy_hp=1
	m.request_attack(E.WIND)
	m.step(100)
	r.resolve_encounter(m)
	t.check(not r.can_choose(&"mend") and not r.choose_reward(&"mend") and r.can_choose(&"long_breath"),"full health mend disabled")
	r.hp=4
	t.check(r.choose_reward(&"mend") and r.hp==5,"healing clamps")
	r.begin_encounter(m)
	m.player_hp=1
	m.request_attack(E.FIRE)
	m.step(100)
	t.check(r.resolve_encounter(m) and r.state==R.State.FAILED and r.seals==1 and r.damage==1,"loss retains earned seal and actual damage")
	r.begin_run()
	t.check(r.encounter_index==0 and r.seals==0,"retry no checkpoint")
	t.check(r.return_to_title() and r.state==R.State.TITLE and not r.return_to_title(),"return discards run")
	# A real neutral-only run exhausts health on the sentinel, without injected HP.
	for reward in [&"mend", &"long_breath"]:
		r=R.new()
		m=C.new()
		r.begin_run()
		for index in range(3):
			r.begin_encounter(m)
			while not m.terminal():
				t.check(m.request_attack(r.spec().element), "neutral-only run attack")
				m.step(100)
				r.resolve_encounter(m)
			if index<2: r.choose_reward(reward if index==0 else (&"mend" if reward==&"mend" else &"iron_resolve"))
		t.check(r.state==R.State.FAILED and r.seals==2 and r.hp==0, "natural neutral-only loss retains two seals")
		t.check(m.combat_log.size()==3, "combat log bounded to three newest impacts")
