class_name LivingTree
extends Node3D

const TRUNK_COLLISION_RADIUS := 0.55

@export var definition: CheckpointDefinition
@export_range(0.5, 4.0, 0.05) var interaction_radius := 2.75

func _ready() -> void:
	name = "LivingTree"
	var trunk := MeshInstance3D.new()
	trunk.name = "Trunk"
	var trunk_mesh := CylinderMesh.new()
	trunk_mesh.top_radius = 0.34
	trunk_mesh.bottom_radius = TRUNK_COLLISION_RADIUS
	trunk_mesh.height = 2.8
	trunk.mesh = trunk_mesh
	trunk.position.y = 1.4
	var bark := StandardMaterial3D.new()
	bark.albedo_color = Color(0.31, 0.18, 0.08)
	trunk.material_override = bark
	add_child(trunk)
	var trunk_body := StaticBody3D.new()
	trunk_body.name = "TrunkBody"
	trunk_body.collision_layer = 1
	trunk_body.collision_mask = 0
	var trunk_collision := CollisionShape3D.new()
	var trunk_shape := CylinderShape3D.new()
	trunk_shape.radius = TRUNK_COLLISION_RADIUS
	trunk_shape.height = 2.8
	trunk_collision.shape = trunk_shape
	trunk_collision.position.y = 1.4
	trunk_body.add_child(trunk_collision)
	add_child(trunk_body)
	var crown := MeshInstance3D.new()
	crown.name = "LivingCrown"
	var crown_mesh := SphereMesh.new()
	crown_mesh.radius = 1.15
	crown_mesh.height = 2.3
	crown.mesh = crown_mesh
	crown.position.y = 3.0
	var leaves := StandardMaterial3D.new()
	leaves.albedo_color = Color(0.2, 0.72, 0.34)
	leaves.emission_enabled = true
	leaves.emission = Color(0.06, 0.32, 0.12)
	leaves.emission_energy_multiplier = 1.7
	crown.material_override = leaves
	add_child(crown)
	var light := OmniLight3D.new()
	light.light_color = Color(0.38, 1.0, 0.55)
	light.light_energy = 2.0
	light.omni_range = 4.5
	light.position.y = 2.4
	add_child(light)

func can_interact(player_position: Vector3) -> bool:
	return global_position.distance_to(player_position) <= interaction_radius
