class_name PlayerViewmodel
extends Node3D

const TUNING: PlayerTuning = preload("res://game/data/tuning/player_default.tres")
const VIEWMODEL_LAYER := 1 << 19

var player: PlayerController
var sword: MeshInstance3D
var shield: MeshInstance3D
var _block_recoil_remaining := 0.0
var _block_recoil_seconds := 0.0


func _ready() -> void:
	name = "PlayerViewmodel"
	sword = MeshInstance3D.new()
	sword.name = "Sword"
	var blade := BoxMesh.new()
	blade.size = Vector3(0.075, 0.72, 0.055)
	sword.mesh = blade
	sword.position = Vector3(0.0, 0.36, 0.0)
	sword.layers = VIEWMODEL_LAYER
	sword.material_override = _material(Color(0.62, 0.65, 0.68), 2.2)
	add_child(sword)
	var guard := MeshInstance3D.new()
	guard.name = "SwordGuard"
	var guard_mesh := BoxMesh.new()
	guard_mesh.size = Vector3(0.3, 0.055, 0.075)
	guard.mesh = guard_mesh
	guard.position = Vector3(0.0, 0.03, 0.0)
	guard.layers = VIEWMODEL_LAYER
	guard.material_override = _material(Color(0.28, 0.19, 0.10), 1.5)
	sword.add_child(guard)
	shield = MeshInstance3D.new()
	shield.name = "Shield"
	var shield_mesh := BoxMesh.new()
	shield_mesh.size = Vector3(0.38, 0.50, 0.065)
	shield.mesh = shield_mesh
	shield.position = Vector3(-0.32, 0.04, -0.16)
	shield.rotation_degrees = Vector3(-8.0, 18.0, -8.0)
	shield.layers = VIEWMODEL_LAYER
	shield.material_override = _material(Color(0.22, 0.28, 0.24), 2.0)
	add_child(shield)


func _process(delta: float) -> void:
	if player == null:
		return
	apply_action_pose(player.actions.phase, player.actions.normalized_phase_progress())
	if _block_recoil_remaining > 0.0:
		_block_recoil_remaining = maxf(0.0, _block_recoil_remaining - delta)
		var recoil := _block_recoil_remaining / maxf(_block_recoil_seconds, 0.0001)
		position += Vector3(0.04, -0.08, 0.14) * recoil
		rotation_degrees += Vector3(8.0, 0.0, 10.0) * recoil


func play_block_recoil(duration: float) -> void:
	_block_recoil_seconds = maxf(duration, 0.0001)
	_block_recoil_remaining = _block_recoil_seconds


func apply_action_pose(phase: PlayerActionMachine.Phase, progress: float) -> void:
	var from_position := TUNING.viewmodel_free_position
	var to_position := TUNING.viewmodel_free_position
	var from_rotation := TUNING.viewmodel_free_rotation_degrees
	var to_rotation := TUNING.viewmodel_free_rotation_degrees
	match phase:
		PlayerActionMachine.Phase.ATTACK_WINDUP:
			to_position = TUNING.viewmodel_windup_position
			to_rotation = TUNING.viewmodel_windup_rotation_degrees
		PlayerActionMachine.Phase.ATTACK_ACTIVE:
			from_position = TUNING.viewmodel_windup_position
			to_position = TUNING.viewmodel_active_position
			from_rotation = TUNING.viewmodel_windup_rotation_degrees
			to_rotation = TUNING.viewmodel_active_rotation_degrees
		PlayerActionMachine.Phase.ATTACK_RECOVERY:
			from_position = TUNING.viewmodel_active_position
			to_position = TUNING.viewmodel_recovery_position
			from_rotation = TUNING.viewmodel_active_rotation_degrees
			to_rotation = TUNING.viewmodel_recovery_rotation_degrees
		PlayerActionMachine.Phase.GUARD:
			from_position = TUNING.viewmodel_guard_position
			to_position = from_position
			from_rotation = TUNING.viewmodel_guard_rotation_degrees
			to_rotation = from_rotation
		PlayerActionMachine.Phase.GUARD_BROKEN:
			from_position = TUNING.viewmodel_guard_position
			to_position = TUNING.viewmodel_guard_broken_position
			from_rotation = TUNING.viewmodel_guard_rotation_degrees
			to_rotation = TUNING.viewmodel_guard_broken_rotation_degrees
		PlayerActionMachine.Phase.HURT:
			to_position = TUNING.viewmodel_hurt_position
			to_rotation = TUNING.viewmodel_hurt_rotation_degrees
	position = from_position.lerp(to_position, clampf(progress, 0.0, 1.0))
	rotation_degrees = from_rotation.lerp(to_rotation, clampf(progress, 0.0, 1.0))
	shield.visible = phase in [PlayerActionMachine.Phase.GUARD, PlayerActionMachine.Phase.GUARD_BROKEN]
	sword.visible = phase not in [PlayerActionMachine.Phase.GUARD, PlayerActionMachine.Phase.GUARD_BROKEN]


func _material(color: Color, emission_energy: float) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.metallic = 0.35
	material.roughness = 0.48
	material.emission_enabled = true
	material.emission = color * 0.24
	material.emission_energy_multiplier = emission_energy
	material.no_depth_test = true
	material.render_priority = 127
	return material
