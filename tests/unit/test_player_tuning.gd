extends RefCounted

const Assertions = preload("res://tests/support/assertions.gd")
const DEFAULT_TUNING := preload("res://game/data/tuning/player_default.tres")

func test_locked_defaults_are_exact(assertions: Assertions, _fixture: RefCounted) -> bool:
	assertions.equal(DEFAULT_TUNING.walk_speed, 3.2, "walk_speed locked default drifted")
	assertions.equal(DEFAULT_TUNING.fov, 70.0, "fov locked default drifted")
	assertions.equal(DEFAULT_TUNING.mouse_sensitivity, 0.0022, "mouse_sensitivity locked default drifted")
	return true
