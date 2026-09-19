extends RefCounted

const Assertions = preload("res://tests/support/assertions.gd")
const DEFINITION: EnemyDefinition = preload("res://game/data/enemies/shambler.tres")
const StrikeGeometry = preload("res://game/enemies/enemy_strike_geometry.gd")


func test_shared_sector_geometry_has_exact_range_and_arc_boundaries(assertions: Assertions, _fixture: RefCounted) -> bool:
	var reach := DEFINITION.attack_range + DEFINITION.attack_reach_lenience
	var half_arc := deg_to_rad(DEFINITION.attack_arc_degrees * 0.5)
	var inside_radius := reach - 0.001
	var inside_angle := half_arc - 0.001
	var outside_angle := half_arc + 0.001
	var forward := Vector3.FORWARD
	var center := Vector3(0.0, 0.0, -inside_radius)
	var inside_edge := Vector3(sin(inside_angle) * inside_radius, 0.0, -cos(inside_angle) * inside_radius)
	var outside_edge := Vector3(sin(outside_angle) * inside_radius, 0.0, -cos(outside_angle) * inside_radius)
	assertions.is_true(StrikeGeometry.contains_world_offset(center, forward, reach, DEFINITION.attack_arc_degrees), "center lane inside reach must hit")
	assertions.is_true(StrikeGeometry.contains_world_offset(inside_edge, forward, reach, DEFINITION.attack_arc_degrees), "point just inside visible arc must hit")
	assertions.is_false(StrikeGeometry.contains_world_offset(outside_edge, forward, reach, DEFINITION.attack_arc_degrees), "point just outside visible arc must miss")
	assertions.is_false(StrikeGeometry.contains_world_offset(Vector3(0.0, 0.0, -(reach + 0.001)), forward, reach, DEFINITION.attack_arc_degrees), "point just beyond visible reach must miss")
	return true


func test_indicator_mesh_uses_same_reach_and_arc_envelope(assertions: Assertions, fixture: RefCounted) -> bool:
	var enemy := EnemyController.new()
	enemy.definition = DEFINITION
	fixture.add_node(enemy)
	await fixture.process_frames(1)
	var reach := DEFINITION.attack_range + DEFINITION.attack_reach_lenience
	var half_arc := deg_to_rad(DEFINITION.attack_arc_degrees * 0.5)
	var expected_half_width := sin(half_arc) * reach
	var aabb := enemy.attack_indicator.mesh.get_aabb()
	assertions.is_true(absf(aabb.position.z + reach) < 0.001, "indicator must extend to the exact damaging reach")
	assertions.is_true(absf(aabb.size.x * 0.5 - expected_half_width) < 0.01, "indicator width must derive from the exact damaging arc")
	var arrays := enemy.attack_indicator.mesh.surface_get_arrays(0)
	var normals: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
	assertions.is_true(not normals.is_empty(), "indicator must provide normals")
	for normal in normals:
		assertions.is_true(normal.dot(Vector3.UP) > 0.999, "indicator normals must face upward")
	assertions.is_true(enemy.can_committed_strike_hit(enemy.global_position + Vector3(0.0, 0.0, -reach)) == false, "uncommitted attacks must never hit")
	enemy.rotation.y = 0.0
	enemy.commit_strike_direction()
	assertions.is_true(enemy.can_committed_strike_hit(enemy.global_position + Vector3(0.0, 0.0, -reach)), "visible wedge tip must be damaging after commitment")
	return true
