class_name EnemyStrikeGeometry
extends RefCounted

const DEFAULT_SEGMENTS := 12


static func contains_world_offset(
	world_offset: Vector3,
	committed_forward: Vector3,
	reach: float,
	arc_degrees: float
) -> bool:
	var flat_offset := Vector3(world_offset.x, 0.0, world_offset.z)
	if flat_offset.length() > reach:
		return false
	if flat_offset.is_zero_approx():
		return true
	var flat_forward := Vector3(committed_forward.x, 0.0, committed_forward.z)
	if flat_forward.is_zero_approx():
		return false
	var minimum_dot := cos(deg_to_rad(arc_degrees * 0.5))
	return flat_forward.normalized().dot(flat_offset.normalized()) >= minimum_dot


static func build_wedge_mesh(reach: float, arc_degrees: float, segments: int = DEFAULT_SEGMENTS) -> ArrayMesh:
	var segment_count := maxi(segments, 2)
	var vertices := PackedVector3Array([Vector3.ZERO])
	var normals := PackedVector3Array([Vector3.UP])
	var indices := PackedInt32Array()
	var half_arc := deg_to_rad(arc_degrees * 0.5)
	for index in range(segment_count + 1):
		var weight := float(index) / float(segment_count)
		var angle := lerpf(-half_arc, half_arc, weight)
		vertices.append(Vector3(sin(angle) * reach, 0.0, -cos(angle) * reach))
		normals.append(Vector3.UP)
		if index > 0:
			# Reverse fan order so the horizontal wedge faces upward toward the camera.
			indices.append(0)
			indices.append(index + 1)
			indices.append(index)
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_INDEX] = indices
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return mesh
