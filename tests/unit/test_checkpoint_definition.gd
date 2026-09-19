extends RefCounted

const Assertions = preload("res://tests/support/assertions.gd")
const ROOT_CHECKPOINT: CheckpointDefinition = preload("res://game/data/checkpoints/root_tree.tres")

func test_authored_checkpoint_schema_and_typed_registry_lookup(assertions: Assertions, _fixture: RefCounted) -> bool:
	assertions.equal(ROOT_CHECKPOINT.id, &"checkpoint.root_tree")
	assertions.is_true(ROOT_CHECKPOINT.validation_errors().is_empty())
	var registry := ContentRegistry.new()
	assertions.is_true(registry.register_checkpoint(ROOT_CHECKPOINT))
	assertions.equal(registry.checkpoint(&"checkpoint.root_tree"), ROOT_CHECKPOINT)
	assertions.equal(registry.checkpoint_count(), 1)
	return true

func test_registry_rejects_duplicate_and_malformed_checkpoint(assertions: Assertions, _fixture: RefCounted) -> bool:
	var registry := ContentRegistry.new()
	assertions.is_true(registry.register_checkpoint(ROOT_CHECKPOINT))
	assertions.is_false(registry.register_checkpoint(ROOT_CHECKPOINT))
	var malformed := CheckpointDefinition.new()
	malformed.id = &"scene.not-stable"
	malformed.display_name = "Wrong"
	assertions.is_false(registry.register_checkpoint(malformed))
	var non_finite := CheckpointDefinition.new()
	non_finite.id = &"checkpoint.non_finite"
	non_finite.display_name = "Non-finite"
	var invalid_transform := Transform3D.IDENTITY
	invalid_transform.origin.x = NAN
	non_finite.respawn_transform = invalid_transform
	assertions.is_false(registry.register_checkpoint(non_finite))
	var blank_name := CheckpointDefinition.new()
	blank_name.id = &"checkpoint.blank_name"
	blank_name.display_name = "   "
	assertions.is_false(registry.register_checkpoint(blank_name))
	assertions.equal(registry.checkpoint_count(), 1)
	return true
