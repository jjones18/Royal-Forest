extends RefCounted

const Assertions = preload("res://tests/support/assertions.gd")
const DEFINITION: EnemyDefinition = preload("res://game/data/enemies/shambler.tres")

func test_shambler_has_stable_valid_enemy_id(assertions: Assertions, _fixture: RefCounted) -> bool:
	assertions.equal(DEFINITION.id, &"enemy.shambler")
	assertions.is_true(DEFINITION.is_valid(), "; ".join(DEFINITION.validation_errors()))
	return true

func test_definition_validation_rejects_wrong_namespace_and_active_tracking(assertions: Assertions, _fixture: RefCounted) -> bool:
	var invalid := DEFINITION.duplicate() as EnemyDefinition
	invalid.id = &"item.shambler"
	invalid.active_turn_speed_degrees = 1.0
	var errors := invalid.validation_errors()
	assertions.is_true(errors.size() >= 2, "wrong namespace and active tracking must both be rejected")
	return true
