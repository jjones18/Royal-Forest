class_name ContentRegistry
extends RefCounted

var _spells: Dictionary = {}
var _checkpoints: Dictionary = {}
var last_error := ""

func register_spell(definition: SpellDefinition) -> bool:
	last_error = ""
	if definition == null:
		last_error = "spell definition is required"
		return false
	var errors := definition.validation_errors()
	if not errors.is_empty():
		last_error = errors[0]
		return false
	if _spells.has(definition.id):
		last_error = "duplicate content id: %s" % definition.id
		return false
	_spells[definition.id] = definition
	return true

func spell(id: StringName) -> SpellDefinition:
	return _spells.get(id) as SpellDefinition

func spell_count() -> int:
	return _spells.size()

func register_checkpoint(definition: CheckpointDefinition) -> bool:
	last_error = ""
	if definition == null:
		last_error = "checkpoint definition is required"
		return false
	var errors := definition.validation_errors()
	if not errors.is_empty():
		last_error = errors[0]
		return false
	if _checkpoints.has(definition.id):
		last_error = "duplicate content id: %s" % definition.id
		return false
	_checkpoints[definition.id] = definition
	return true

func checkpoint(id: StringName) -> CheckpointDefinition:
	return _checkpoints.get(id) as CheckpointDefinition

func checkpoint_count() -> int:
	return _checkpoints.size()
