extends RefCounted
## Pure deterministic state machine. Views never resolve damage.
enum Phase { READY, REST, TELEGRAPH, ENEMY_ATTACK, COUNTER_WINDOW, PLAYER_ATTACK, WON, LOST }
const REST_TIME := 0.7
const WARNING_TIME := 0.9
const ATTACK_TIME := 0.6
const COUNTER_TIME := 1.2
const IMPACT_TIME := 0.3
const EPS := 0.000000001
var state: Phase = Phase.READY
var elapsed := 0.0
var player_hp := 3
var enemy_hp := 3
var block_latched := false
var impact_resolved := false
var attack_blocked := false
var events: Array[String] = []

func reset() -> void:
	state = Phase.READY
	elapsed = 0.0
	player_hp = 3
	enemy_hp = 3
	block_latched = false
	impact_resolved = false
	attack_blocked = false
	events.clear()

func start() -> void:
	reset()
	_enter(Phase.REST)

func request_block() -> bool:
	if state != Phase.TELEGRAPH or elapsed >= WARNING_TIME or block_latched:
		return false
	block_latched = true
	events.append("guard")
	return true

func request_strike() -> bool:
	if state != Phase.COUNTER_WINDOW or elapsed >= COUNTER_TIME:
		return false
	_enter(Phase.PLAYER_ATTACK)
	return true

func duration() -> float:
	match state:
		Phase.REST: return REST_TIME
		Phase.TELEGRAPH: return WARNING_TIME
		Phase.ENEMY_ATTACK, Phase.PLAYER_ATTACK: return ATTACK_TIME
		Phase.COUNTER_WINDOW: return COUNTER_TIME
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
		var boundary := duration()
		if is_attack() and not impact_resolved:
			boundary = IMPACT_TIME
		var consumed := minf(remaining, maxf(0.0, boundary - elapsed))
		elapsed += consumed
		remaining -= consumed
		if elapsed + EPS < boundary:
			break
		elapsed = boundary
		if is_attack() and not impact_resolved:
			impact_resolved = true
			if state == Phase.ENEMY_ATTACK:
				attack_blocked = block_latched
				if attack_blocked:
					events.append("blocked")
				else:
					player_hp = maxi(0, player_hp - 1)
					events.append("hit")
			else:
				enemy_hp = maxi(0, enemy_hp - 1)
				events.append("counter")
		else:
			_advance()

func prepare_resume() -> void:
	# Called on pause, with no simulation until the explicit Resume tap.
	block_latched = false
	if state == Phase.TELEGRAPH or (state == Phase.ENEMY_ATTACK and not impact_resolved):
		_enter(Phase.TELEGRAPH)
	elif state == Phase.COUNTER_WINDOW:
		elapsed = 0.0

func drain_events() -> Array[String]:
	var result := events.duplicate()
	events.clear()
	return result

func _enter(next: Phase) -> void:
	state = next
	elapsed = 0.0
	if next == Phase.REST or next == Phase.TELEGRAPH:
		block_latched = false
	if is_attack():
		impact_resolved = false
		attack_blocked = false
	if terminal():
		events.append("won" if state == Phase.WON else "lost")

func _advance() -> void:
	match state:
		Phase.REST: _enter(Phase.TELEGRAPH)
		Phase.TELEGRAPH: _enter(Phase.ENEMY_ATTACK)
		Phase.ENEMY_ATTACK:
			if player_hp == 0:
				_enter(Phase.LOST)
			elif attack_blocked:
				_enter(Phase.COUNTER_WINDOW)
			else:
				_enter(Phase.REST)
		Phase.COUNTER_WINDOW: _enter(Phase.REST)
		Phase.PLAYER_ATTACK: _enter(Phase.WON if enemy_hp == 0 else Phase.REST)
