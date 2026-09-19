extends Node
## Dependency-free deterministic runner with explicit suite registration.

const Assertions = preload("res://tests/support/assertions.gd")
const SimulationFixture = preload("res://tests/support/simulation_fixture.gd")
const SUITES: Array[Script] = [
	preload("res://tests/unit/test_runner_self.gd"),
	preload("res://tests/unit/test_game_root.gd"),
	preload("res://tests/unit/test_gameplay_recorder.gd"),
	preload("res://tests/unit/test_player_tuning.gd"),
	preload("res://tests/unit/test_player_stats.gd"),
	preload("res://tests/unit/test_spell_definition.gd"),
	preload("res://tests/unit/test_content_registry.gd"),
	preload("res://tests/unit/test_player_action_machine.gd"),
	preload("res://tests/unit/test_spell_projectile.gd"),
	preload("res://tests/unit/test_enemy_state_machine.gd"),
	preload("res://tests/unit/test_enemy_definition.gd"),
	preload("res://tests/unit/test_enemy_strike_geometry.gd"),
	preload("res://tests/unit/test_enemy_controller.gd"),
	preload("res://tests/unit/test_responsive_hud.gd"),
	preload("res://tests/unit/test_combat_playground.gd"),
]


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	var discovery := _discover_tests()
	var tests: Array[Dictionary] = discovery["tests"]
	var passed := 0
	var failed: int = discovery["empty_suites"].size()
	for empty_suite in discovery["empty_suites"]:
		print("FAIL: %s -- registered suite contains no test_ methods" % empty_suite)
	if tests.is_empty():
		failed += 1
		print("FAIL: test discovery -- no tests discovered")
	for test_case in tests:
		var assertions := Assertions.new()
		var suite: RefCounted = test_case["suite"].new()
		var fixture := SimulationFixture.new(get_tree(), self, test_case["id"])
		@warning_ignore("redundant_await")
		var completed: Variant = await suite.call(test_case["method"], assertions, fixture)
		fixture.teardown()
		if completed != true:
			failed += 1
			print("FAIL: %s -- test did not complete with `return true`" % test_case["id"])
		elif assertions.has_failures():
			failed += 1
			print("FAIL: %s -- %s" % [test_case["id"], "; ".join(assertions.failures())])
		else:
			passed += 1
			print("PASS: %s" % test_case["id"])
		suite = null
	var status := "PASS" if failed == 0 else "FAIL"
	print("RESULT: %s (%d tests, %d passed, %d failed)" % [status, tests.size(), passed, failed])
	get_tree().quit(0 if failed == 0 else 1)


func _discover_tests() -> Dictionary:
	var tests: Array[Dictionary] = []
	var empty_suites: Array[String] = []
	for suite_script in SUITES:
		var method_names: Array[String] = []
		for method in suite_script.get_script_method_list():
			var method_name: String = method["name"]
			if method_name.begins_with("test_"):
				method_names.append(method_name)
		method_names.sort()
		var suite_name := suite_script.resource_path.get_file().get_basename()
		print("DISCOVERED: %s (%d tests)" % [suite_name, method_names.size()])
		if method_names.is_empty():
			empty_suites.append(suite_name)
		for method_name in method_names:
			tests.append({
				"id": "%s.%s" % [suite_name, method_name],
				"method": method_name,
				"suite": suite_script,
			})
	return {"tests": tests, "empty_suites": empty_suites}
