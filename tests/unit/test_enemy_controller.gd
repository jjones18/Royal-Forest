extends RefCounted

const Assertions = preload("res://tests/support/assertions.gd")
const DEFINITION: EnemyDefinition = preload("res://game/data/enemies/shambler.tres")

func test_pursuit_and_windup_turn_caps_and_active_freeze(assertions: Assertions, fixture: RefCounted) -> bool:
	var enemy := EnemyController.new()
	enemy.definition = DEFINITION
	fixture.add_node(enemy)
	enemy.rotation.y = 0.0
	enemy.turn_toward_position(Vector3(10.0, 0.0, 0.0), DEFINITION.pursuit_turn_speed_degrees, 0.1)
	assertions.is_true(absf(absf(enemy.rotation.y) - deg_to_rad(54.0)) < 0.0001, "pursuit and green recovery turn must cap at 540 degrees/second")
	enemy.rotation.y = 0.0
	enemy.turn_toward_position(Vector3(10.0, 0.0, 0.0), DEFINITION.windup_turn_speed_degrees, 0.25)
	assertions.is_true(absf(absf(enemy.rotation.y) - deg_to_rad(11.25)) < 0.0001, "windup turn must cap at 45 degrees/second")
	var active_yaw := enemy.rotation.y
	enemy.turn_toward_position(Vector3(-10.0, 0.0, 0.0), DEFINITION.active_turn_speed_degrees, 1.0)
	assertions.is_true(absf(enemy.rotation.y - active_yaw) < 0.000001, "ACTIVE yaw delta must be zero")
	return true

func test_committed_strike_direction_excludes_flank(assertions: Assertions, fixture: RefCounted) -> bool:
	var enemy := EnemyController.new()
	enemy.definition = DEFINITION
	fixture.add_node(enemy)
	enemy.rotation.y = 0.0
	enemy.commit_strike_direction()
	assertions.is_true(enemy.committed_strike_direction.is_equal_approx(Vector3.FORWARD), "ACTIVE entry must snapshot the body-facing strike direction")
	enemy.rotation.y = deg_to_rad(90.0)
	assertions.is_true(enemy.can_committed_strike_hit(Vector3(0.0, 0.0, -1.4)), "target in committed lane should be hit even if body rotation later differs")
	assertions.is_false(enemy.can_committed_strike_hit(Vector3(1.4, 0.0, 0.0)), "flank dodge outside committed arc must avoid damage")
	return true

func test_search_and_return_preserve_damage(assertions: Assertions, fixture: RefCounted) -> bool:
	var enemy := EnemyController.new()
	enemy.definition = DEFINITION
	fixture.add_node(enemy)
	await fixture.process_frames(1)
	enemy.hp = DEFINITION.max_hp - 25.0
	enemy.state_machine.set_awareness(true, true, false)
	enemy.state_machine.update_awareness(false, false, false, DEFINITION.line_of_sight_grace_seconds)
	assertions.equal(enemy.state_machine.phase, EnemyStateMachine.Phase.SEARCH, "lost LOS must enter SEARCH")
	assertions.equal(enemy.hp, DEFINITION.max_hp - 25.0, "SEARCH must preserve enemy damage")
	enemy.state_machine.update_awareness(false, false, false, DEFINITION.search_duration_seconds)
	assertions.equal(enemy.state_machine.phase, EnemyStateMachine.Phase.RETURN, "expired search must enter RETURN")
	assertions.equal(enemy.hp, DEFINITION.max_hp - 25.0, "RETURN must preserve enemy damage")
	return true


func test_search_scan_rotates_after_reaching_last_known_position(assertions: Assertions, fixture: RefCounted) -> bool:
	var enemy := EnemyController.new()
	enemy.definition = DEFINITION
	fixture.add_node(enemy)
	await fixture.process_frames(1)
	enemy.rotation.y = 0.0
	enemy.state_machine._enter(EnemyStateMachine.Phase.SEARCH)
	enemy.state_machine.search_elapsed = 0.5
	enemy._scan_for_player(0.25)
	assertions.is_true(absf(enemy.rotation.y) > 0.01, "SEARCH at the last-known position must visibly scan rather than freeze")
	return true


func test_pillar_pathfinder_routes_around_blocker(assertions: Assertions, _fixture: RefCounted) -> bool:
	var obstacle := Rect2(Vector2(-0.5, -0.5), Vector2(1.0, 1.0))
	var start := Vector3(0.0, 0.0, 2.0)
	var destination := Vector3(0.0, 0.0, -2.0)
	var waypoint := ArenaPathfinder.next_corner(start, destination, [obstacle], 0.5)
	assertions.is_false(Vector2(waypoint.x, waypoint.z).is_equal_approx(Vector2(destination.x, destination.z)), "blocked route must select an around-pillar waypoint")
	assertions.is_true(absf(waypoint.x) >= 1.0, "waypoint must clear the expanded pillar edge")
	return true
