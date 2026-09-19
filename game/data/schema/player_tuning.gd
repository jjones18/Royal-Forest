class_name PlayerTuning
extends Resource

@export_group("Locked movement")
@export var walk_speed: float = 0.0
@export var fov: float = 0.0
@export var mouse_sensitivity: float = 0.0
@export var stick_look_speed: float = 2.2
@export var stick_deadzone: float = 0.18

@export_group("Movement")
@export var strafe_speed: float = 2.9
@export var backpedal_speed: float = 2.5
@export var acceleration: float = 10.0

@export_group("Resources")
@export var max_hp: float = 100.0
@export var max_stamina: float = 100.0
@export var max_mana: float = 100.0
@export var mana_recovery_delay: float = 2.0
@export var mana_recovery_per_second: float = 2.5
@export var attack_stamina_cost: float = 25.0
@export var dodge_stamina_cost: float = 30.0
@export var guard_drain_per_second: float = 10.0
@export var stamina_recovery_delay: float = 0.35
@export var stamina_full_recovery_seconds: float = 2.75

@export_group("Attack")
@export var attack_windup_seconds: float = 0.22
@export var attack_active_seconds: float = 0.12
@export var attack_recovery_seconds: float = 0.46
@export var attack_damage: float = 34.0
@export var attack_range: float = 2.25
@export var attack_arc_degrees: float = 70.0
@export var hit_confirm_seconds: float = 0.24

@export_group("Viewmodel poses")
@export var viewmodel_free_position := Vector3(0.43, -0.43, -0.72)
@export var viewmodel_free_rotation_degrees := Vector3(-18.0, 4.0, -18.0)
@export var viewmodel_windup_position := Vector3(0.53, -0.31, -0.62)
@export var viewmodel_windup_rotation_degrees := Vector3(-42.0, 18.0, -58.0)
@export var viewmodel_active_position := Vector3(-0.20, -0.16, -0.75)
@export var viewmodel_active_rotation_degrees := Vector3(14.0, -20.0, 72.0)
@export var viewmodel_recovery_position := Vector3(0.34, -0.49, -0.70)
@export var viewmodel_recovery_rotation_degrees := Vector3(-10.0, 5.0, 8.0)
@export var viewmodel_guard_position := Vector3(-0.02, -0.34, -0.78)
@export var viewmodel_guard_rotation_degrees := Vector3(-6.0, -6.0, -18.0)
@export var viewmodel_guard_broken_position := Vector3(0.32, -0.68, -0.78)
@export var viewmodel_guard_broken_rotation_degrees := Vector3(30.0, 15.0, 38.0)
@export var viewmodel_hurt_position := Vector3(0.55, -0.57, -0.64)
@export var viewmodel_hurt_rotation_degrees := Vector3(24.0, 8.0, -42.0)

@export_group("Dodge")
@export var dodge_distance: float = 2.4
@export var dodge_move_seconds: float = 0.34
@export var dodge_iframe_seconds: float = 0.20
@export var dodge_total_recovery_seconds: float = 0.75

@export_group("Guard")
@export var guard_damage_reduction: float = 0.8
@export var guard_impact_stamina_cost: float = 10.0
@export var guard_move_multiplier: float = 0.4
@export var guard_break_seconds: float = 0.7
@export var guard_block_recoil_seconds: float = 0.18
@export var player_hurt_seconds: float = 0.35
@export var damage_feedback_seconds: float = 0.55
