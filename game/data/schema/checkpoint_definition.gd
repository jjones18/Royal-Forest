class_name CheckpointDefinition
extends Resource

@export var id: StringName = &""
@export var display_name := ""
@export var respawn_transform := Transform3D.IDENTITY

func validation_errors() -> PackedStringArray:
	var errors := PackedStringArray()
	if not ContentId.is_namespace(id, "checkpoint"):
		errors.append("checkpoint id must use stable lowercase checkpoint.<slug>")
	if display_name.strip_edges().is_empty():
		errors.append("display_name is required")
	if not respawn_transform.is_finite():
		errors.append("respawn_transform must be finite")
	return errors

func is_valid() -> bool:
	return validation_errors().is_empty()
