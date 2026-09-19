class_name EnemyDefinition
extends Resource

@export_group("Identity")
@export var id: StringName = &""
@export var display_name := ""

@export_group("Survivability and awareness")
@export var max_hp := 80.0
@export var detection_range := 11.0
@export var leash_range := 15.0
@export var line_of_sight_grace_seconds := 1.0
@export var search_duration_seconds := 5.0

@export_group("Movement")
@export var move_speed := 2.0
@export var search_speed_multiplier := 0.8
@export var pursuit_turn_speed_degrees := 540.0
@export var windup_turn_speed_degrees := 45.0
@export var active_turn_speed_degrees := 0.0
@export var home_arrival_tolerance := 0.15
@export var navigation_clearance := 0.65
@export var hit_nudge_distance := 0.12

@export_group("Attack")
@export var attack_range := 1.65
@export var attack_reach_lenience := 0.35
@export var attack_arc_degrees := 55.0
@export var windup_seconds := 0.65
@export var active_seconds := 0.16
@export var recovery_seconds := 0.72
@export var damage := 24.0

func validation_errors() -> PackedStringArray:
	var errors := PackedStringArray()
	var id_text := String(id)
	if id_text.is_empty():
		errors.append("enemy id is required")
	elif not id_text.begins_with("enemy.") or id_text.length() <= 6:
		errors.append("enemy id must use enemy.<slug>")
	elif not _is_lowercase_id(id_text):
		errors.append("enemy id must contain only lowercase letters, digits, underscores, and one namespace dot")
	if display_name.strip_edges().is_empty(): errors.append("display_name is required")
	if max_hp <= 0.0: errors.append("max_hp must be positive")
	if detection_range <= 0.0: errors.append("detection_range must be positive")
	if leash_range < detection_range: errors.append("leash_range must be at least detection_range")
	if move_speed <= 0.0: errors.append("move_speed must be positive")
	if attack_range <= 0.0: errors.append("attack_range must be positive")
	if attack_reach_lenience < 0.0: errors.append("attack_reach_lenience cannot be negative")
	if attack_arc_degrees <= 0.0 or attack_arc_degrees > 180.0: errors.append("attack_arc_degrees must be in (0, 180]")
	if windup_seconds <= 0.0 or active_seconds <= 0.0 or recovery_seconds <= 0.0: errors.append("attack timings must be positive")
	if line_of_sight_grace_seconds < 0.0 or search_duration_seconds <= 0.0: errors.append("LOS memory timings are invalid")
	if search_speed_multiplier <= 0.0 or search_speed_multiplier > 1.0: errors.append("search_speed_multiplier must be in (0, 1]")
	if pursuit_turn_speed_degrees < 0.0 or windup_turn_speed_degrees < 0.0: errors.append("turn speeds cannot be negative")
	if not is_zero_approx(active_turn_speed_degrees): errors.append("active_turn_speed_degrees must remain zero for a committed strike")
	if home_arrival_tolerance <= 0.0: errors.append("home_arrival_tolerance must be positive")
	return errors

func is_valid() -> bool:
	return validation_errors().is_empty()

func _is_lowercase_id(value: String) -> bool:
	if value.count(".") != 1:
		return false
	for character in value:
		if not (character >= "a" and character <= "z") and not (character >= "0" and character <= "9") and character != "_" and character != ".":
			return false
	return true
