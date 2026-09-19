class_name EnemyStateMachine
extends RefCounted

enum Phase { IDLE, PURSUIT, WINDUP, ACTIVE, RECOVERY, HURT, DEAD, SEARCH, RETURN }

var phase: Phase = Phase.IDLE
var elapsed := 0.0
var windup_seconds := 0.65
var active_seconds := 0.16
var recovery_seconds := 0.72
var hurt_seconds := 0.22
var los_grace_seconds := 1.0
var search_duration_seconds := 5.0
var los_lost_elapsed := 0.0
var search_elapsed := 0.0
var strike_available := false

func configure(definition: EnemyDefinition) -> void:
	windup_seconds = definition.windup_seconds
	active_seconds = definition.active_seconds
	recovery_seconds = definition.recovery_seconds
	los_grace_seconds = definition.line_of_sight_grace_seconds
	search_duration_seconds = definition.search_duration_seconds

func update_awareness(has_line_of_sight: bool, in_detection_range: bool, beyond_leash: bool, delta: float) -> void:
	if phase in [Phase.DEAD, Phase.HURT, Phase.WINDUP, Phase.ACTIVE, Phase.RECOVERY]:
		return
	if beyond_leash:
		_enter(Phase.RETURN)
		return
	# RETURN is not deaf: a visible player inside both detection and leash range
	# must re-engage immediately instead of waiting for the enemy to reach home.
	if has_line_of_sight and in_detection_range:
		los_lost_elapsed = 0.0
		search_elapsed = 0.0
		_enter(Phase.PURSUIT)
		return
	if phase == Phase.RETURN:
		return
	if phase == Phase.PURSUIT:
		los_lost_elapsed += maxf(delta, 0.0)
		if los_lost_elapsed + 0.000001 >= los_grace_seconds:
			_enter(Phase.SEARCH)
	elif phase == Phase.SEARCH:
		search_elapsed += maxf(delta, 0.0)
		if search_elapsed + 0.000001 >= search_duration_seconds:
			_enter(Phase.RETURN)

func set_awareness(has_line_of_sight: bool, in_detection_range: bool, beyond_leash: bool) -> void:
	update_awareness(has_line_of_sight, in_detection_range, beyond_leash, 0.0)

func request_attack(in_range: bool, has_line_of_sight: bool) -> bool:
	if phase != Phase.PURSUIT or not in_range or not has_line_of_sight:
		return false
	_enter(Phase.WINDUP)
	return true

func advance(delta: float) -> void:
	var remaining := maxf(delta, 0.0)
	while remaining > 0.000001:
		var duration := _duration()
		if duration < 0.0:
			break
		var step := minf(remaining, maxf(duration - elapsed, 0.0))
		elapsed += step
		remaining -= step
		if elapsed + 0.000001 >= duration:
			if phase == Phase.WINDUP:
				_enter(Phase.ACTIVE)
				strike_available = true
			elif phase == Phase.ACTIVE:
				_enter(Phase.RECOVERY)
			elif phase in [Phase.RECOVERY, Phase.HURT]:
				_enter(Phase.PURSUIT)
			else:
				break

func consume_strike() -> bool:
	if phase != Phase.ACTIVE or not strike_available:
		return false
	strike_available = false
	return true

func stagger() -> void:
	if phase != Phase.DEAD:
		_enter(Phase.HURT)

func die() -> void:
	_enter(Phase.DEAD)

func reset() -> void:
	_enter(Phase.IDLE)

func arrive_home() -> void:
	if phase == Phase.RETURN:
		_enter(Phase.IDLE)

func _enter(next: Phase) -> void:
	if phase == next:
		return
	phase = next
	elapsed = 0.0
	strike_available = false
	# Every phase transition starts a fresh LOS grace period. In particular,
	# reacquiring PURSUIT must not inherit time from an earlier occlusion.
	los_lost_elapsed = 0.0
	if next != Phase.SEARCH:
		search_elapsed = 0.0

func _duration() -> float:
	match phase:
		Phase.WINDUP: return windup_seconds
		Phase.ACTIVE: return active_seconds
		Phase.RECOVERY: return recovery_seconds
		Phase.HURT: return hurt_seconds
		_: return -1.0
