class_name PlayerStats
extends RefCounted

var tuning: PlayerTuning
var hp: float
var stamina: float
var stamina_recovery_delay_remaining: float = 0.0

func _init(source_tuning: PlayerTuning = null) -> void:
	tuning = source_tuning if source_tuning != null else load("res://game/data/tuning/player_default.tres")
	hp = tuning.max_hp
	stamina = tuning.max_stamina

func spend_stamina(amount: float) -> bool:
	if amount < 0.0 or stamina + 0.00001 < amount:
		return false
	stamina = maxf(0.0, stamina - amount)
	stamina_recovery_delay_remaining = tuning.stamina_recovery_delay
	return true

func advance(delta: float, recovery_allowed: bool = true) -> void:
	if delta <= 0.0:
		return
	var recover_delta := delta
	if stamina_recovery_delay_remaining > 0.0:
		var delayed := minf(recover_delta, stamina_recovery_delay_remaining)
		stamina_recovery_delay_remaining -= delayed
		recover_delta -= delayed
	if recovery_allowed and recover_delta > 0.0:
		stamina = minf(tuning.max_stamina, stamina + recover_delta * tuning.max_stamina / tuning.stamina_full_recovery_seconds)

func apply_damage(amount: float) -> float:
	var applied := minf(hp, maxf(amount, 0.0))
	hp -= applied
	return applied

func heal(amount: float) -> float:
	var before := hp
	hp = minf(tuning.max_hp, hp + maxf(amount, 0.0))
	return hp - before

func reset() -> void:
	hp = tuning.max_hp
	stamina = tuning.max_stamina
	stamina_recovery_delay_remaining = 0.0

func is_dead() -> bool:
	return hp <= 0.0
