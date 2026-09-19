class_name PlayerStance
extends RefCounted

const STANDING_EYE_HEIGHT := 1.62
const CROUCHED_EYE_HEIGHT := 0.95
const STANDING_CAPSULE_HEIGHT := 1.8
const CROUCHED_CAPSULE_HEIGHT := 1.10
const TRANSITION_SPEED := 4.0
const CROUCH_SPEED_MULTIPLIER := 0.40

var crouching := false
var current_eye_height := STANDING_EYE_HEIGHT
var current_capsule_height := STANDING_CAPSULE_HEIGHT


func toggle() -> void:
	crouching = not crouching


func request_crouch() -> void:
	crouching = true


func request_stand() -> void:
	crouching = false


func force_standing() -> void:
	crouching = false
	current_eye_height = STANDING_EYE_HEIGHT
	current_capsule_height = STANDING_CAPSULE_HEIGHT


func advance(delta: float) -> void:
	var distance := TRANSITION_SPEED * maxf(delta, 0.0)
	var target_eye := CROUCHED_EYE_HEIGHT if crouching else STANDING_EYE_HEIGHT
	var target_capsule := CROUCHED_CAPSULE_HEIGHT if crouching else STANDING_CAPSULE_HEIGHT
	current_eye_height = move_toward(current_eye_height, target_eye, distance)
	current_capsule_height = move_toward(current_capsule_height, target_capsule, distance)


func speed_multiplier() -> float:
	return CROUCH_SPEED_MULTIPLIER if crouching else 1.0
