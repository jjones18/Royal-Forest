class_name PlayerActionMachine
extends RefCounted

enum Phase { FREE, ATTACK_WINDUP, ATTACK_ACTIVE, ATTACK_RECOVERY, CAST_WINDUP, CAST_ACTIVE, CAST_RECOVERY, HEAL_WINDUP, HEAL_ACTIVE, HEAL_RECOVERY, DODGE, GUARD, GUARD_BROKEN, HURT, DEAD }

var tuning: PlayerTuning
var stats: PlayerStats
var spell: SpellDefinition
var vessel: HealingVessel
var phase: Phase = Phase.FREE
var elapsed := 0.0
var has_shield := true
var accepted := false
var blocked_reason := ""
var attack_hit_available := false
var cast_release_available := false
var heal_tick_available := false
var dodge_direction := Vector2.ZERO
var _buffered: PlayerActionRequest.Kind = PlayerActionRequest.Kind.NONE

func _init(source_stats: PlayerStats, source_tuning: PlayerTuning = null, source_spell: SpellDefinition = null, source_vessel: HealingVessel = null) -> void:
	stats = source_stats
	tuning = source_tuning if source_tuning != null else source_stats.tuning
	spell = source_spell if source_spell != null else load("res://game/data/spells/spectral_bolt.tres")
	vessel = source_vessel if source_vessel != null else HealingVessel.new()

func request(request_data: PlayerActionRequest) -> bool:
	accepted = false
	blocked_reason = ""
	if phase == Phase.DEAD:
		return _block("dead")
	if request_data.kind == PlayerActionRequest.Kind.GUARD_END and phase == Phase.GUARD:
		_enter(Phase.FREE)
		return _accept()
	if phase != Phase.FREE:
		if phase in [Phase.ATTACK_RECOVERY, Phase.CAST_RECOVERY, Phase.HEAL_RECOVERY, Phase.DODGE] and _remaining() <= 0.15 and request_data.kind in [PlayerActionRequest.Kind.ATTACK, PlayerActionRequest.Kind.DODGE, PlayerActionRequest.Kind.CAST, PlayerActionRequest.Kind.HEAL] and _buffered == PlayerActionRequest.Kind.NONE:
			_buffered = request_data.kind
			return _accept()
		return _block("committed")
	match request_data.kind:
		PlayerActionRequest.Kind.ATTACK:
			if not stats.spend_stamina(tuning.attack_stamina_cost): return _block("insufficient stamina")
			attack_hit_available = false
			_enter(Phase.ATTACK_WINDUP)
		PlayerActionRequest.Kind.CAST:
			if spell == null or not spell.is_valid(): return _block("invalid spell")
			if not stats.spend_mana(spell.mana_cost): return _block("insufficient mana")
			cast_release_available = false
			_enter(Phase.CAST_WINDUP)
		PlayerActionRequest.Kind.HEAL:
			if stats.hp + 0.00001 >= stats.tuning.max_hp: return _block("full health")
			if not vessel.spend_charge(): return _block("empty vessel")
			heal_tick_available = false
			_enter(Phase.HEAL_WINDUP)
		PlayerActionRequest.Kind.DODGE:
			if not stats.spend_stamina(tuning.dodge_stamina_cost): return _block("insufficient stamina")
			dodge_direction = request_data.move_direction.normalized() if request_data.move_direction.length() > 0.0 else Vector2(0.0, -1.0)
			_enter(Phase.DODGE)
		PlayerActionRequest.Kind.GUARD_START:
			if not has_shield: return _block("shield required")
			if stats.stamina <= 0.0: return _block("insufficient stamina")
			_enter(Phase.GUARD)
		_:
			return _block("no action")
	return _accept()

func advance(delta: float) -> void:
	var remaining := maxf(delta, 0.0)
	if phase == Phase.GUARD:
		if not stats.spend_stamina(minf(stats.stamina, tuning.guard_drain_per_second * remaining)) or stats.stamina <= 0.00001:
			stats.stamina = 0.0
			_enter(Phase.GUARD_BROKEN)
		stats.advance(remaining, false)
		return
	stats.advance(remaining, phase == Phase.FREE)
	while remaining > 0.000001:
		var duration := _duration()
		if duration < 0.0:
			break
		var step := minf(remaining, maxf(duration - elapsed, 0.0))
		elapsed += step
		remaining -= step
		if elapsed + 0.000001 >= duration:
			match phase:
				Phase.ATTACK_WINDUP:
					_enter(Phase.ATTACK_ACTIVE)
					attack_hit_available = true
				Phase.ATTACK_ACTIVE:
					_enter(Phase.ATTACK_RECOVERY)
				Phase.CAST_WINDUP:
					_enter(Phase.CAST_ACTIVE)
					cast_release_available = true
				Phase.CAST_ACTIVE:
					_enter(Phase.CAST_RECOVERY)
				Phase.HEAL_WINDUP:
					_enter(Phase.HEAL_ACTIVE)
					heal_tick_available = true
				Phase.HEAL_ACTIVE:
					_enter(Phase.HEAL_RECOVERY)
				Phase.ATTACK_RECOVERY, Phase.CAST_RECOVERY, Phase.HEAL_RECOVERY, Phase.DODGE, Phase.GUARD_BROKEN, Phase.HURT:
					_enter(Phase.FREE)
					_consume_buffer()
				_:
					break

func consume_attack_hit() -> bool:
	if not attack_hit_available:
		return false
	attack_hit_available = false
	return true

func consume_cast_release() -> bool:
	if not cast_release_available:
		return false
	cast_release_available = false
	return true

func consume_heal_tick() -> bool:
	if not heal_tick_available:
		return false
	heal_tick_available = false
	return true

func normalized_phase_progress() -> float:
	var duration := _duration()
	if duration <= 0.0:
		return 0.0
	return clampf(elapsed / duration, 0.0, 1.0)

func is_invulnerable() -> bool:
	return phase == Phase.DODGE and elapsed < tuning.dodge_iframe_seconds

func dodge_speed() -> float:
	if phase != Phase.DODGE or elapsed >= tuning.dodge_move_seconds:
		return 0.0
	return tuning.dodge_distance / tuning.dodge_move_seconds

func receive_damage(amount: float) -> float:
	if is_invulnerable() or phase == Phase.DEAD:
		blocked_reason = "invulnerable" if phase != Phase.DEAD else "dead"
		return 0.0
	var effective := amount
	var guard_broken := false
	if phase == Phase.GUARD:
		effective *= 1.0 - tuning.guard_damage_reduction
		if not stats.spend_stamina(tuning.guard_impact_stamina_cost):
			stats.stamina = 0.0
		if stats.stamina <= 0.00001:
			_enter(Phase.GUARD_BROKEN)
			guard_broken = true
	var applied := stats.apply_damage(effective)
	if stats.is_dead(): _enter(Phase.DEAD)
	elif phase != Phase.GUARD and not guard_broken: _enter(Phase.HURT)
	return applied

func reset() -> void:
	stats.reset()
	_buffered = PlayerActionRequest.Kind.NONE
	attack_hit_available = false
	cast_release_available = false
	heal_tick_available = false
	_enter(Phase.FREE)

func _consume_buffer() -> void:
	if _buffered == PlayerActionRequest.Kind.NONE:
		return
	var next := _buffered
	_buffered = PlayerActionRequest.Kind.NONE
	request(PlayerActionRequest.new(next, dodge_direction))

func _duration() -> float:
	match phase:
		Phase.ATTACK_WINDUP: return tuning.attack_windup_seconds
		Phase.ATTACK_ACTIVE: return tuning.attack_active_seconds
		Phase.ATTACK_RECOVERY: return tuning.attack_recovery_seconds
		Phase.CAST_WINDUP: return spell.cast_windup_seconds
		Phase.CAST_ACTIVE: return spell.cast_active_seconds
		Phase.CAST_RECOVERY: return spell.cast_recovery_seconds
		Phase.HEAL_WINDUP: return HealingVessel.HEAL_WINDUP
		Phase.HEAL_ACTIVE: return HealingVessel.HEAL_ACTIVE
		Phase.HEAL_RECOVERY: return HealingVessel.HEAL_RECOVERY
		Phase.DODGE: return tuning.dodge_total_recovery_seconds
		Phase.GUARD_BROKEN: return tuning.guard_break_seconds
		Phase.HURT: return tuning.player_hurt_seconds
		_: return -1.0

func _remaining() -> float:
	return maxf(0.0, _duration() - elapsed)

func _enter(next: Phase) -> void:
	var previous := phase
	phase = next
	elapsed = 0.0
	if next in [Phase.HURT, Phase.GUARD_BROKEN, Phase.DEAD]:
		attack_hit_available = false
		cast_release_available = false
		if previous == Phase.HEAL_WINDUP:
			heal_tick_available = false

func _accept() -> bool:
	accepted = true
	return true

func _block(reason: String) -> bool:
	blocked_reason = reason
	return false
