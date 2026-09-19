class_name CombatPlayground
extends Node3D

const PLAYER_SCENE := preload("res://game/player/player_controller.tscn")
const ENEMY_SCENE := preload("res://game/enemies/enemy_controller.tscn")
const HUD_SCENE := preload("res://game/ui/hud/game_hud_responsive.tscn")
const TUNING: PlayerTuning = preload("res://game/data/tuning/player_default.tres")

var player: PlayerController
var primary_enemy: EnemyController
var hud: ResponsiveGameHud
var navigation_obstacles: Array[Rect2] = [
	Rect2(Vector2(2.15, -2.15), Vector2(1.3, 1.3)),
	Rect2(Vector2(-5.05, -3.9), Vector2(2.5, 0.8)),
]

func _ready() -> void:
	_build_environment()
	player = PLAYER_SCENE.instantiate()
	player.position = Vector3(0, 0, 4.5)
	add_child(player)
	player.attack_requested.connect(perform_player_attack)
	player.restart_requested.connect(reset_encounter)
	primary_enemy = spawn_enemy(Vector3(0, 0, 0.5), "Shambler")
	hud = HUD_SCENE.instantiate()
	hud.player = player
	add_child(hud)

func spawn_enemy(at: Vector3, enemy_name: String = "Shambler") -> EnemyController:
	var enemy: EnemyController = ENEMY_SCENE.instantiate()
	enemy.name = enemy_name
	enemy.position = at
	enemy.player = player
	enemy.configure_navigation_obstacles(navigation_obstacles)
	add_child(enemy)
	return enemy

func perform_player_attack() -> int:
	var hits := 0
	var origin := player.camera.global_position
	var forward := -player.camera.global_transform.basis.z
	for node in get_tree().get_nodes_in_group("combat_targets"):
		var enemy := node as EnemyController
		if enemy == null or enemy.state_machine.phase == EnemyStateMachine.Phase.DEAD:
			continue
		var target := enemy.global_position + Vector3.UP * 0.85
		var to_target := target - origin
		var horizontal := Vector3(to_target.x, 0.0, to_target.z)
		if to_target.length() > TUNING.attack_range:
			continue
		if horizontal.is_zero_approx() or Vector3(forward.x, 0.0, forward.z).normalized().dot(horizontal.normalized()) < cos(deg_to_rad(TUNING.attack_arc_degrees * 0.5)):
			continue
		var ray := PhysicsRayQueryParameters3D.create(origin, target, 1)
		var collision := get_world_3d().direct_space_state.intersect_ray(ray)
		if not collision.is_empty():
			continue
		enemy.take_hit(TUNING.attack_damage, player.global_position)
		hits += 1
	player.confirm_player_hit(hits, TUNING.attack_damage)
	return hits

func enemy_strike(enemy: EnemyController) -> float:
	if enemy.state_machine.phase != EnemyStateMachine.Phase.ACTIVE:
		return 0.0
	if not enemy.can_committed_strike_hit(player.global_position):
		return 0.0
	if not enemy.has_line_of_sight_to_player():
		return 0.0
	return player.receive_enemy_damage(enemy.definition.damage)

func reset_encounter() -> void:
	player.reset_player()
	for node in get_tree().get_nodes_in_group("combat_targets"):
		var enemy := node as EnemyController
		if enemy != null:
			enemy.reset_enemy()

func _build_environment() -> void:
	var environment := WorldEnvironment.new()
	var settings := Environment.new()
	settings.background_mode = Environment.BG_COLOR
	settings.background_color = Color(0.025, 0.04, 0.035)
	settings.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	settings.ambient_light_color = Color(0.42, 0.48, 0.42)
	settings.ambient_light_energy = 1.1
	environment.environment = settings
	add_child(environment)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-55, -25, 0)
	sun.light_color = Color(1.0, 0.86, 0.65)
	sun.light_energy = 1.7
	sun.shadow_enabled = true
	add_child(sun)
	_box("Floor", Vector3(0, -0.25, 0), Vector3(16, 0.5, 18), Color(0.19, 0.22, 0.18))
	_box("NorthWall", Vector3(0, 2, -9), Vector3(16, 4, 0.5), Color(0.24, 0.28, 0.23))
	_box("SouthWall", Vector3(0, 2, 9), Vector3(16, 4, 0.5), Color(0.24, 0.28, 0.23))
	_box("WestWall", Vector3(-8, 2, 0), Vector3(0.5, 4, 18), Color(0.20, 0.25, 0.20))
	_box("EastWall", Vector3(8, 2, 0), Vector3(0.5, 4, 18), Color(0.20, 0.25, 0.20))
	_box("OccludingPillar", Vector3(2.8, 1.5, -1.5), Vector3(1.3, 3, 1.3), Color(0.33, 0.26, 0.17))
	_box("LowBlock", Vector3(-3.8, 0.6, -3.5), Vector3(2.5, 1.2, 0.8), Color(0.30, 0.25, 0.18))

func _box(node_name: String, at: Vector3, size: Vector3, color: Color) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.name = node_name
	body.position = at
	body.collision_layer = 1
	body.collision_mask = 0
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	collision.shape = shape
	body.add_child(collision)
	var mesh_instance := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	mesh_instance.mesh = mesh
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.9
	mesh_instance.material_override = material
	body.add_child(mesh_instance)
	add_child(body)
	return body
