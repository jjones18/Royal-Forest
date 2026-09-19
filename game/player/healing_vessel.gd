class_name HealingVessel
extends RefCounted

const MAX_CHARGES := 3
const HEAL_FRACTION := 0.40
const HEAL_WINDUP := 0.80
const HEAL_ACTIVE := 0.08
const HEAL_RECOVERY := 0.52

var max_charges := MAX_CHARGES
var charges := MAX_CHARGES


func spend_charge() -> bool:
	if charges <= 0:
		return false
	charges -= 1
	return true


func refill() -> void:
	charges = max_charges


func heal_amount(max_hp: float) -> float:
	return maxf(max_hp, 0.0) * HEAL_FRACTION
