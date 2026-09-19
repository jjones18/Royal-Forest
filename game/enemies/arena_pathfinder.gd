class_name ArenaPathfinder
extends RefCounted

## Deterministic gray-box navigation fallback. Obstacles are XZ Rect2 bounds.
static func next_corner(start: Vector3, destination: Vector3, obstacles: Array[Rect2], clearance: float) -> Vector3:
	var from := Vector2(start.x, start.z)
	var target := Vector2(destination.x, destination.z)
	var blocking := _first_blocking_obstacle(from, target, obstacles, clearance)
	if blocking.size == Vector2.ZERO:
		return destination
	var corners := [
		blocking.position - Vector2(0.05, 0.05),
		blocking.position + Vector2(blocking.size.x + 0.05, -0.05),
		blocking.position + Vector2(-0.05, blocking.size.y + 0.05),
		blocking.end + Vector2(0.05, 0.05),
	]
	var best := target
	var best_distance := INF
	for corner in corners:
		if _segment_blocked(from, corner, obstacles, clearance) or _segment_blocked(corner, target, obstacles, clearance):
			continue
		var distance: float = from.distance_to(corner) + corner.distance_to(target)
		if distance < best_distance:
			best_distance = distance
			best = corner
	if best_distance == INF:
		# A stable fallback still steers around the first obstacle instead of into it.
		for corner in corners:
			var distance: float = from.distance_to(corner)
			if distance < best_distance:
				best_distance = distance
				best = corner
	return Vector3(best.x, destination.y, best.y)

static func _first_blocking_obstacle(from: Vector2, target: Vector2, obstacles: Array[Rect2], clearance: float) -> Rect2:
	for obstacle in obstacles:
		var expanded := obstacle.grow(clearance)
		if _segment_intersects_rect(from, target, expanded):
			return expanded
	return Rect2()

static func _segment_blocked(from: Vector2, target: Vector2, obstacles: Array[Rect2], clearance: float) -> bool:
	for obstacle in obstacles:
		if _segment_intersects_rect(from, target, obstacle.grow(clearance)):
			return true
	return false

static func _segment_intersects_rect(from: Vector2, target: Vector2, rect: Rect2) -> bool:
	if rect.has_point(from) or rect.has_point(target):
		return true
	var a := rect.position
	var b := rect.position + Vector2(rect.size.x, 0.0)
	var c := rect.end
	var d := rect.position + Vector2(0.0, rect.size.y)
	return Geometry2D.segment_intersects_segment(from, target, a, b) != null \
		or Geometry2D.segment_intersects_segment(from, target, b, c) != null \
		or Geometry2D.segment_intersects_segment(from, target, c, d) != null \
		or Geometry2D.segment_intersects_segment(from, target, d, a) != null
