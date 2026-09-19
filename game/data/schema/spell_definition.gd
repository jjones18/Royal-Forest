class_name SpellDefinition
extends Resource

@export_group("Identity")
@export var id: StringName = &""
@export var display_name := ""

@export_group("Cast")
@export var mana_cost := 25.0
@export var damage := 30.0
@export var cast_windup_seconds := 0.28
@export var cast_active_seconds := 0.08
@export var cast_recovery_seconds := 0.44

@export_group("Projectile")
@export var projectile_speed := 16.0
@export var max_range := 24.0
@export var projectile_radius := 0.16

func validation_errors() -> PackedStringArray:
	var errors := PackedStringArray()
	if not ContentId.is_namespace(id, "spell"):
		errors.append("spell id must use stable lowercase spell.<slug>")
	if display_name.strip_edges().is_empty(): errors.append("display_name is required")
	if mana_cost <= 0.0: errors.append("mana_cost must be positive")
	if damage <= 0.0: errors.append("damage must be positive")
	if cast_windup_seconds <= 0.0 or cast_active_seconds <= 0.0 or cast_recovery_seconds <= 0.0:
		errors.append("cast timings must be positive")
	if projectile_speed <= 0.0: errors.append("projectile_speed must be positive")
	if max_range <= 0.0: errors.append("max_range must be positive")
	if projectile_radius <= 0.0: errors.append("projectile_radius must be positive")
	return errors

func is_valid() -> bool:
	return validation_errors().is_empty()
