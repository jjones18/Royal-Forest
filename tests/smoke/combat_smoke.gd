extends Node

const PLAYGROUND := preload("res://game/world/combat_playground.tscn")
const TUNING: PlayerTuning = preload("res://game/data/tuning/player_default.tres")
const ENEMY: EnemyDefinition = preload("res://game/data/enemies/shambler.tres")
var failures := 0
var playground: CombatPlayground

func _ready() -> void:
	playground = PLAYGROUND.instantiate()
	add_child(playground)
	await get_tree().physics_frame
	await get_tree().physics_frame
	check(playground.player != null, "player spawn")
	check(playground.primary_enemy != null, "enemy spawn")
	await _combat_collision_checks()
	_action_and_damage_checks()
	print("SMOKE RESULT: %s (%d failures)" % ["OK" if failures == 0 else "FAIL", failures])
	get_tree().quit(0 if failures == 0 else 1)

func _combat_collision_checks() -> void:
	playground.player.set_physics_process(false)
	playground.primary_enemy.set_physics_process(false)
	playground.primary_enemy.visible = false
	playground.primary_enemy.collision_layer = 0
	var visible := playground.spawn_enemy(Vector3(-0.65, 0, 2.75), "VisibleTarget")
	var visible_second := playground.spawn_enemy(Vector3(-0.05, 0, 2.6), "VisibleTargetSecond")
	var rear := playground.spawn_enemy(Vector3(0, 0, 5.7), "RearTarget")
	var occluded := playground.spawn_enemy(Vector3(0.8, 0, 2.75), "OccludedTarget")
	for enemy in [visible, visible_second, rear, occluded]: enemy.set_physics_process(false)
	playground._box("SmokeOccluder", Vector3(0.4, 1.0, 3.65), Vector3(0.45, 2.0, 0.35), Color(0.4, 0.2, 0.15))
	await get_tree().physics_frame
	var before_visible := visible.hp
	var before_position := visible.global_position
	var attack_command := InputCommand.new()
	attack_command.attack_pressed = true
	playground.player.simulate_command(attack_command, 0.0)
	check(visible.hp == before_visible and visible_second.hp == visible_second.definition.max_hp, "attack input causes no damage during windup")
	playground.player.simulate_command(InputCommand.new(), TUNING.attack_windup_seconds - 0.001)
	check(visible.hp == before_visible, "enemy HP remains unchanged until ACTIVE")
	playground.player.simulate_command(InputCommand.new(), 0.001)
	check(visible.hp < before_visible and visible_second.hp < visible_second.definition.max_hp and visible.state_machine.phase == EnemyStateMachine.Phase.HURT, "attack damages/staggers visible targets at ACTIVE")
	check(visible.global_position.distance_to(before_position) > 0.0 and playground.hud.feedback_label.text.begins_with("HIT"), "connected hit nudges enemy and shows synchronized confirmation")
	check(rear.hp == ENEMY.max_hp, "rear target excluded")
	check(occluded.hp == ENEMY.max_hp, "wall occlusion excluded")
	for enemy in [visible, visible_second, rear, occluded]: enemy.queue_free()
	await get_tree().process_frame

func _action_and_damage_checks() -> void:
	var player := playground.player
	player.actions.reset()
	player.actions.request(PlayerActionRequest.new(PlayerActionRequest.Kind.DODGE))
	var hp_before := player.stats.hp
	player.receive_enemy_damage(30.0)
	check(player.stats.hp == hp_before, "dodge iframe prevents damage")
	player.actions.reset()
	player.stats.stamina = TUNING.dodge_stamina_cost - 0.01
	check(not player.actions.request(PlayerActionRequest.new(PlayerActionRequest.Kind.DODGE)) and player.actions.blocked_reason == "insufficient stamina", "insufficient stamina blocks dodge")
	player.actions.reset()
	var enemy := playground.primary_enemy
	enemy.visible = true
	enemy.collision_layer = 4
	enemy.global_position = player.global_position + Vector3(0, 0, -1.2)
	enemy.state_machine.reset()
	enemy.state_machine.set_awareness(true, true, false)
	enemy.state_machine.request_attack(true, true)
	enemy.state_machine.advance(ENEMY.windup_seconds)
	enemy.committed_strike_direction = (player.global_position - enemy.global_position).normalized()
	hp_before = player.stats.hp
	check(playground.enemy_strike(enemy) > 0.0 and player.stats.hp < hp_before, "enemy active strike can damage")
	player.actions.reset()
	player.stats.stamina = TUNING.max_stamina
	check(player.actions.request(PlayerActionRequest.new(PlayerActionRequest.Kind.GUARD_START)), "guard starts for live strike")
	hp_before = player.stats.hp
	var stamina_before := player.stats.stamina
	var guarded_damage := playground.enemy_strike(enemy)
	check(is_equal_approx(guarded_damage, ENEMY.damage * (1.0 - TUNING.guard_damage_reduction)) and is_equal_approx(hp_before - player.stats.hp, guarded_damage), "live enemy strike applies 80 percent guard reduction as chip")
	check(is_equal_approx(stamina_before - player.stats.stamina, TUNING.guard_impact_stamina_cost), "live guarded strike costs 10 stamina")
	check(player.actions.phase == PlayerActionMachine.Phase.GUARD and playground.hud.feedback_label.text.begins_with("BLOCKED"), "blocked chip feedback is distinct from hurt")
	player.actions.reset()
	player.receive_enemy_damage(999.0)
	check(player.actions.phase == PlayerActionMachine.Phase.DEAD, "death path")
	var command := InputCommand.new()
	command.restart_pressed = true
	player.simulate_command(command, 1.0 / 60.0)
	check(player.actions.phase == PlayerActionMachine.Phase.FREE and player.stats.hp == TUNING.max_hp and enemy.hp == ENEMY.max_hp, "input-driven death/reset path")

func check(condition: bool, label: String) -> void:
	if condition:
		print("PASS: %s" % label)
	else:
		failures += 1
		print("FAIL: %s" % label)
