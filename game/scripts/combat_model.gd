class_name CombatModel
extends RefCounted
## Sole authority for combat time, impacts and pattern advancement.
enum Phase { READY, REST, TELEGRAPH, ENEMY_ATTACK, COUNTER_WINDOW, PLAYER_ATTACK, WON, LOST }
const ATTACK_TIME := 0.6
const IMPACT_TIME := 0.3
const EPS := 0.000000001
const DEFAULT_SPEC = preload("res://data/encounters/gate_guard.tres")
var spec: EncounterSpec = DEFAULT_SPEC
var state: Phase = Phase.READY
var elapsed := 0.0
var player_hp := 5
var player_max_hp := 5
var enemy_hp := 3
var counter_bonus_ms := 0
var pattern_index := 0
var strike_index := 0
var selected_defense: StrikeSpec.Defense = StrikeSpec.Defense.NONE
var all_defended := true
var impact_resolved := false
var attack_blocked := false
var counters := 0
var defenses := 0
var damage := 0
var events: Array[CombatEvent] = []
var block_latched: bool:
	get: return selected_defense != StrikeSpec.Defense.NONE

func reset() -> void:
	configure(DEFAULT_SPEC, 5, 5, 0)

func configure(encounter: EncounterSpec, hp: int, max_hp: int, bonus_ms: int) -> void:
	spec = encounter
	player_hp = hp
	player_max_hp = max_hp
	enemy_hp = spec.enemy_max_hp
	counter_bonus_ms = bonus_ms
	pattern_index = 0
	strike_index = 0
	selected_defense = StrikeSpec.Defense.NONE
	all_defended = true
	impact_resolved = false
	attack_blocked = false
	counters = 0
	defenses = 0
	damage = 0
	events.clear()
	state = Phase.READY
	elapsed = 0.0

func start() -> void:
	if state == Phase.READY:
		_enter(Phase.REST)

func pattern() -> PatternSpec:
	return spec.patterns[pattern_index]

func strike() -> StrikeSpec:
	return pattern().strikes[strike_index]

func request_defense(choice: StrikeSpec.Defense) -> bool:
	if state != Phase.TELEGRAPH or elapsed >= duration() or block_latched or choice == StrikeSpec.Defense.NONE:
		return false
	selected_defense = choice
	_emit(CombatEvent.Kind.DEFENSE_SELECTED)
	return true

func request_block() -> bool:
	return request_defense(StrikeSpec.Defense.BLOCK)

func request_dodge() -> bool:
	return request_defense(StrikeSpec.Defense.DODGE)

func request_strike() -> bool:
	if state != Phase.COUNTER_WINDOW or elapsed >= duration():
		return false
	_enter(Phase.PLAYER_ATTACK)
	return true

func duration() -> float:
	match state:
		Phase.REST: return spec.rest_ms / 1000.0
		Phase.TELEGRAPH: return strike().warning_ms / 1000.0
		Phase.ENEMY_ATTACK, Phase.PLAYER_ATTACK: return ATTACK_TIME
		Phase.COUNTER_WINDOW: return (spec.counter_ms + counter_bonus_ms) / 1000.0
	return 0.0

func is_attack() -> bool:
	return state == Phase.ENEMY_ATTACK or state == Phase.PLAYER_ATTACK

func terminal() -> bool:
	return state == Phase.WON or state == Phase.LOST

func step(delta: float) -> void:
	if not is_finite(delta) or delta <= 0.0:
		return
	var remaining := delta
	while remaining > EPS and duration() > 0.0:
		var boundary := IMPACT_TIME if is_attack() and not impact_resolved else duration()
		var consumed := minf(remaining, maxf(0.0, boundary - elapsed))
		elapsed += consumed
		remaining -= consumed
		if elapsed + EPS < boundary:
			break
		elapsed = boundary
		if is_attack() and not impact_resolved:
			impact_resolved = true
			if state == Phase.ENEMY_ATTACK:
				attack_blocked = selected_defense == strike().defense_required
				all_defended = all_defended and attack_blocked
				if attack_blocked:
					defenses += 1
					_emit(CombatEvent.Kind.DEFENDED)
				else:
					player_hp = maxi(0, player_hp - 1)
					damage += 1
					_emit(CombatEvent.Kind.DAMAGE)
			else:
				enemy_hp = maxi(0, enemy_hp - 1)
				counters += 1
				_emit(CombatEvent.Kind.COUNTER)
		else:
			_advance()

func prepare_resume() -> void:
	if state == Phase.TELEGRAPH or (state == Phase.ENEMY_ATTACK and not impact_resolved):
		_enter(Phase.TELEGRAPH)
	elif state == Phase.COUNTER_WINDOW:
		elapsed = 0.0

func drain_events() -> Array[CombatEvent]:
	var result: Array[CombatEvent] = events.duplicate()
	events.clear()
	return result

func _emit(kind: CombatEvent.Kind) -> void:
	var event := CombatEvent.new()
	event.kind = kind
	event.pattern_index = pattern_index
	event.strike_index = strike_index
	event.defense_required = strike().defense_required
	event.selected_defense = selected_defense
	event.player_hp = player_hp
	event.enemy_hp = enemy_hp
	events.append(event)

func _enter(next: Phase) -> void:
	state = next
	elapsed = 0.0
	if next == Phase.REST or next == Phase.TELEGRAPH:
		selected_defense = StrikeSpec.Defense.NONE
	if is_attack():
		impact_resolved = false
		attack_blocked = false
	if terminal():
		_emit(CombatEvent.Kind.WON if state == Phase.WON else CombatEvent.Kind.LOST)

func _next_pattern() -> void:
	pattern_index = (pattern_index + 1) % spec.patterns.size()
	strike_index = 0
	all_defended = true
	_enter(Phase.REST)

func _advance() -> void:
	match state:
		Phase.REST: _enter(Phase.TELEGRAPH)
		Phase.TELEGRAPH: _enter(Phase.ENEMY_ATTACK)
		Phase.ENEMY_ATTACK:
			if player_hp == 0:
				_enter(Phase.LOST)
			elif strike_index + 1 < pattern().strikes.size():
				strike_index += 1
				_enter(Phase.TELEGRAPH)
			elif all_defended:
				_enter(Phase.COUNTER_WINDOW)
			else:
				_next_pattern()
		Phase.COUNTER_WINDOW: _next_pattern()
		Phase.PLAYER_ATTACK:
			if enemy_hp == 0: _enter(Phase.WON)
			else: _next_pattern()
