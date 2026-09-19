class_name PlayerStats
extends RefCounted

var tuning: PlayerTuning
var hp: float
var stamina: float
var mana: float
var stamina_recovery_delay_remaining := 0.0
var mana_recovery_delay_remaining := 0.0

func _init(source_tuning: PlayerTuning = null) -> void:
	tuning = source_tuning if source_tuning != null else load("res://game/data/tuning/player_default.tres")
	hp = tuning.max_hp
	stamina = tuning.max_stamina
	mana = tuning.max_mana

func spend_stamina(amount: float) -> bool:
	if amount < 0.0 or stamina + 0.00001 < amount:
		return false
	stamina = maxf(0.0, stamina - amount)
	stamina_recovery_delay_remaining = tuning.stamina_recovery_delay
	return true

func spend_mana(amount: float) -> bool:
	if amount < 0.0 or mana + 0.00001 < amount:
		return false
	mana = maxf(0.0, mana - amount)
	mana_recovery_delay_remaining = tuning.mana_recovery_delay
	return true

func advance(delta: float, stamina_recovery_allowed: bool = true) -> void:
	if delta <= 0.0:
		return
	var stamina_delta := _consume_delay(delta, "stamina")
	if stamina_recovery_allowed and stamina_delta > 0.0:
		stamina = minf(tuning.max_stamina, stamina + stamina_delta * tuning.max_stamina / tuning.stamina_full_recovery_seconds)
	var mana_delta := _consume_delay(delta, "mana")
	if mana_delta > 0.0:
		mana = minf(tuning.max_mana, mana + mana_delta * tuning.mana_recovery_per_second)

func _consume_delay(delta: float, resource_kind: String) -> float:
	var delay := stamina_recovery_delay_remaining if resource_kind == "stamina" else mana_recovery_delay_remaining
	var delayed := minf(delta, delay)
	delay -= delayed
	if resource_kind == "stamina":
		stamina_recovery_delay_remaining = delay
	else:
		mana_recovery_delay_remaining = delay
	return delta - delayed

func apply_damage(amount: float) -> float:
	var applied := minf(hp, maxf(amount, 0.0))
	hp -= applied
	if applied > 0.0:
		mana_recovery_delay_remaining = tuning.mana_recovery_delay
	return applied

func heal(amount: float) -> float:
	var before := hp
	hp = minf(tuning.max_hp, hp + maxf(amount, 0.0))
	return hp - before

func reset() -> void:
	hp = tuning.max_hp
	stamina = tuning.max_stamina
	mana = tuning.max_mana
	stamina_recovery_delay_remaining = 0.0
	mana_recovery_delay_remaining = 0.0

func is_dead() -> bool:
	return hp <= 0.0
