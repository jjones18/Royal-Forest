extends RefCounted

const Assertions = preload("res://tests/support/assertions.gd")
const PLAYGROUND := preload("res://game/world/combat_playground.tscn")
const ROOT_CHECKPOINT: CheckpointDefinition = preload("res://game/data/checkpoints/root_tree.tres")

func test_tree_interaction_refills_clears_resets_activates_saves_and_reports(assertions: Assertions, fixture: RefCounted) -> bool:
	var context := await _session_context("rest", fixture)
	var playground: CombatPlayground = context["playground"]
	var player := playground.player
	var enemy := playground.primary_enemy
	player.stats.hp = 3.0
	player.stats.stamina = 4.0
	player.stats.mana = 5.0
	player.vessel.charges = 0
	player.stance.request_crouch()
	player.stance.advance(1.0)
	player.velocity = Vector3(2.0, 0.0, 3.0)
	enemy.take_hit(enemy.definition.max_hp * 2.0, player.global_position)
	enemy.global_position += Vector3(2.0, 0.0, 1.0)
	player.global_transform = playground.living_tree.global_transform
	var command := InputCommand.new()
	command.interact_pressed = true
	player.simulate_command(command, 0.0)
	assertions.equal(player.stats.hp, player.stats.tuning.max_hp)
	assertions.equal(player.stats.stamina, player.stats.tuning.max_stamina)
	assertions.equal(player.stats.mana, player.stats.tuning.max_mana)
	assertions.equal(player.vessel.charges, player.vessel.max_charges)
	assertions.is_false(player.stance.crouching, "M2C_TRANSIENT_STANCE_EXCLUDED")
	assertions.equal(player.actions.phase, PlayerActionMachine.Phase.FREE)
	assertions.equal(player.velocity, Vector3.ZERO)
	assertions.equal(enemy.hp, enemy.definition.max_hp, "M2C_ORDINARY_ENEMY_RESET")
	assertions.equal(enemy.global_position, enemy.home_position)
	assertions.equal(enemy.state_machine.phase, EnemyStateMachine.Phase.IDLE)
	assertions.equal(context["world"].current_checkpoint_id, ROOT_CHECKPOINT.id)
	assertions.is_true(FileAccess.file_exists(context["manager"].save_path))
	assertions.equal(context["session"].status_kind, &"save_success")
	assertions.is_true(playground.hud.feedback_label.text.contains("SAVED"))
	_cleanup(context["dir"])
	return true

func test_rest_rejects_committed_action_and_active_combat_without_mutation(assertions: Assertions, fixture: RefCounted) -> bool:
	var context := await _session_context("reject", fixture)
	var session: GameSession = context["session"]
	var playground: CombatPlayground = context["playground"]
	playground.player.stats.hp = 12.0
	playground.primary_enemy.hp = 31.0
	playground.primary_enemy.global_position += Vector3(0.5, 0.0, 0.0)
	playground.player.actions.request(PlayerActionRequest.new(PlayerActionRequest.Kind.ATTACK))
	var action_player_hp := playground.player.stats.hp
	var action_enemy_hp := playground.primary_enemy.hp
	var action_enemy_position := playground.primary_enemy.global_position
	var action_world: Dictionary = context["world"].snapshot()
	var action_narrative: Dictionary = context["narrative"].snapshot()
	assertions.is_false(session.rest_at(ROOT_CHECKPOINT))
	assertions.equal(playground.player.stats.hp, action_player_hp)
	assertions.equal(playground.primary_enemy.hp, action_enemy_hp)
	assertions.equal(playground.primary_enemy.global_position, action_enemy_position)
	assertions.equal(context["world"].snapshot(), action_world)
	assertions.equal(context["narrative"].snapshot(), action_narrative)
	assertions.is_false(FileAccess.file_exists(context["manager"].save_path))
	playground.player.actions.reset()
	playground.player.stats.hp = 12.0
	playground.primary_enemy.state_machine._enter(EnemyStateMachine.Phase.WINDUP)
	var combat_world: Dictionary = context["world"].snapshot()
	var combat_narrative: Dictionary = context["narrative"].snapshot()
	assertions.is_false(session.rest_at(ROOT_CHECKPOINT))
	assertions.equal(playground.player.stats.hp, 12.0)
	assertions.equal(playground.primary_enemy.hp, action_enemy_hp)
	assertions.equal(playground.primary_enemy.global_position, action_enemy_position)
	assertions.equal(context["world"].snapshot(), combat_world)
	assertions.equal(context["narrative"].snapshot(), combat_narrative)
	assertions.is_false(FileAccess.file_exists(context["manager"].save_path))
	assertions.equal(session.status_kind, &"rest_blocked")
	_cleanup(context["dir"])
	return true

func test_death_restart_respawns_at_checkpoint_and_retains_durable_flags(assertions: Assertions, fixture: RefCounted) -> bool:
	var context := await _session_context("death", fixture)
	var session: GameSession = context["session"]
	var playground: CombatPlayground = context["playground"]
	var player := playground.player
	var world: WorldState = context["world"]
	var narrative: NarrativeState = context["narrative"]
	assertions.is_true(session.rest_at(ROOT_CHECKPOINT))
	world.open_shortcut(&"shortcut.keep")
	world.add_region_seal(&"seal.keep")
	narrative.add_note(&"note.keep")
	player.receive_enemy_damage(player.stats.tuning.max_hp * 2.0)
	assertions.equal(player.actions.phase, PlayerActionMachine.Phase.DEAD)
	var dead_transform := player.global_transform
	await fixture.process_frames(1)
	assertions.equal(player.global_transform, dead_transform, "session fixture must preserve the DEAD transform until restart input; production-physics inertness is covered by test_combat_playground")
	playground.primary_enemy.take_hit(playground.primary_enemy.definition.max_hp * 2.0, player.global_position)
	var restart := InputCommand.new()
	restart.restart_pressed = true
	player.simulate_command(restart, 0.0)
	assertions.equal(player.global_transform, ROOT_CHECKPOINT.respawn_transform)
	assertions.equal(player.stats.hp, player.stats.tuning.max_hp)
	assertions.equal(player.actions.phase, PlayerActionMachine.Phase.FREE)
	assertions.is_false(player.stance.crouching)
	assertions.equal(playground.primary_enemy.hp, playground.primary_enemy.definition.max_hp)
	assertions.is_true(world.has_opened_shortcut(&"shortcut.keep"))
	assertions.is_true(world.has_region_seal(&"seal.keep"))
	assertions.is_true(narrative.has_note(&"note.keep"))
	assertions.is_true(playground.find_children("*Dropped*", "Node", true, false).is_empty(), "death must not spawn dropped-resource/corpse nodes")
	_cleanup(context["dir"])
	return true

func test_save_failure_keeps_runtime_checkpoint_but_fresh_session_uses_previous_disk(assertions: Assertions, fixture: RefCounted) -> bool:
	var context := await _session_context("save-failure", fixture)
	var session: GameSession = context["session"]
	var world: WorldState = context["world"]
	world.open_shortcut(&"shortcut.on_disk")
	assertions.is_true(session.rest_at(ROOT_CHECKPOINT))
	world.open_shortcut(&"shortcut.runtime_only")
	context["manager"].inject_fail_save_once = true
	assertions.is_false(session.rest_at(ROOT_CHECKPOINT))
	assertions.equal(session.status_kind, &"save_failed")
	assertions.equal(session.status_text, "TREE ACTIVE — SAVE FAILED")
	assertions.equal(context["playground"].hud.feedback_label.text, "TREE ACTIVE — SAVE FAILED")
	context["playground"].player.receive_enemy_damage(999.0)
	var restart := InputCommand.new()
	restart.restart_pressed = true
	context["playground"].player.simulate_command(restart, 0.0)
	assertions.equal(context["playground"].player.global_transform, ROOT_CHECKPOINT.respawn_transform, "failed disk save may still provide current-process respawn")
	var fresh_world := WorldState.new()
	var fresh_narrative := NarrativeState.new()
	var fresh_manager := SaveManager.new(context["manager"].save_path, context["registry"])
	assertions.is_true(fresh_manager.load_game(fresh_world, fresh_narrative))
	assertions.is_true(fresh_world.has_opened_shortcut(&"shortcut.on_disk"))
	assertions.is_false(fresh_world.has_opened_shortcut(&"shortcut.runtime_only"), "failed save must not leak runtime-only state into a fresh process")
	_cleanup(context["dir"])
	return true


func test_restart_preserves_live_reset_and_pre_activation_death_uses_spawn_fallback(assertions: Assertions, fixture: RefCounted) -> bool:
	var context := await _session_context("restart-routes", fixture)
	var playground: CombatPlayground = context["playground"]
	var player := playground.player
	var living_position := player.global_transform.translated(Vector3(2.0, 0.0, 0.0))
	player.global_transform = living_position
	var restart := InputCommand.new()
	restart.restart_pressed = true
	player.stats.hp = 12.0
	playground.primary_enemy.hp = 7.0
	player.simulate_command(restart, 0.0)
	assertions.equal(player.global_transform, player.spawn_transform, "live R/Y must preserve the existing playtest encounter reset")
	assertions.equal(player.stats.hp, player.stats.tuning.max_hp)
	assertions.equal(playground.primary_enemy.hp, playground.primary_enemy.definition.max_hp)
	player.receive_enemy_damage(999.0)
	player.global_position = Vector3(3.0, 0.0, 3.0)
	var restart_and_attack := InputCommand.new()
	restart_and_attack.restart_pressed = true
	restart_and_attack.attack_pressed = true
	player.simulate_command(restart_and_attack, 0.0)
	assertions.equal(player.global_transform, player.spawn_transform, "pre-activation death must use the original spawn fallback")
	assertions.equal(player.actions.phase, PlayerActionMachine.Phase.FREE, "restart command must not also begin an attack")
	assertions.equal(context["world"].current_checkpoint_id, &"", "fallback respawn must not falsely activate a checkpoint")
	assertions.is_false(FileAccess.file_exists(context["manager"].save_path), "fallback respawn must not save")
	_cleanup(context["dir"])
	return true


func test_checkpoint_feedback_uses_intentional_long_duration_and_semantic_colors(assertions: Assertions, fixture: RefCounted) -> bool:
	var context := await _session_context("feedback", fixture)
	var hud: ResponsiveGameHud = context["playground"].hud
	hud._on_combat_feedback(&"save_success", "ROOT TREE ACTIVE — SAVED")
	assertions.is_true(hud.feedback_label.visible)
	assertions.is_true(hud.feedback_remaining > hud.TUNING.damage_feedback_seconds, "checkpoint/save feedback must outlast damage feedback")
	assertions.is_true(hud.feedback_label.get_theme_color("font_color").g > hud.feedback_label.get_theme_color("font_color").r, "save success must be green/pale")
	hud._on_combat_feedback(&"backup_recovered", "SAVE RECOVERED FROM BACKUP")
	assertions.is_true(hud.feedback_remaining > hud.TUNING.damage_feedback_seconds, "backup recovery feedback must remain visible long enough to read")
	assertions.is_true(hud.feedback_label.get_theme_color("font_color").g > hud.feedback_label.get_theme_color("font_color").r, "backup recovery must be green/pale")
	hud._on_combat_feedback(&"load_failed", "SAVE LOAD FAILED — STARTING FRESH")
	assertions.is_true(hud.feedback_remaining > hud.TUNING.damage_feedback_seconds, "load failure feedback must remain visible long enough to read")
	assertions.is_true(hud.feedback_label.get_theme_color("font_color").r > hud.feedback_label.get_theme_color("font_color").g, "load failure must be amber/red")
	hud._on_combat_feedback(&"rest_blocked", "CANNOT REST DURING COMBAT")
	assertions.is_true(hud.feedback_label.get_theme_color("font_color").r > hud.feedback_label.get_theme_color("font_color").g, "blocked rest must be amber/red")
	hud._on_combat_feedback(&"death", "DEAD")
	assertions.is_true(hud.feedback_label.get_theme_color("font_color").r > hud.feedback_label.get_theme_color("font_color").g, "death must be red")
	_cleanup(context["dir"])
	return true


func test_enemy_combat_filter_is_bounded_to_active_playground_descendants(assertions: Assertions, fixture: RefCounted) -> bool:
	var context := await _session_context("combat-filter", fixture)
	var session: GameSession = context["session"]
	var enemy: EnemyController = context["playground"].primary_enemy
	enemy.state_machine._enter(EnemyStateMachine.Phase.RETURN)
	assertions.is_false(session._ordinary_enemy_in_combat(), "RETURN is disengaging and must not permanently block rest")
	enemy.state_machine.die()
	assertions.is_false(session._ordinary_enemy_in_combat(), "DEAD ordinary enemies reset at rest and must not block it")
	enemy.state_machine._enter(EnemyStateMachine.Phase.WINDUP)
	assertions.is_true(session._ordinary_enemy_in_combat(), "genuinely active combat must block rest")
	enemy.reset_enemy()
	var external := preload("res://game/enemies/enemy_controller.tscn").instantiate() as EnemyController
	fixture.add_node(external)
	await fixture.physics_frames(1)
	external.state_machine._enter(EnemyStateMachine.Phase.WINDUP)
	assertions.is_false(session._ordinary_enemy_in_combat(), "combat-target groups outside this playground must be ignored")
	_cleanup(context["dir"])
	return true


func test_process_restart_load_restores_checkpoint_and_durable_sets(assertions: Assertions, fixture: RefCounted) -> bool:
	var context_a := await _session_context("restart", fixture)
	var session_a: GameSession = context_a["session"]
	var world_a: WorldState = context_a["world"]
	var narrative_a: NarrativeState = context_a["narrative"]
	world_a.open_shortcut(&"shortcut.persisted")
	narrative_a.learn_truth(&"truth.persisted")
	assertions.is_true(session_a.rest_at(ROOT_CHECKPOINT))
	var registry := _registry()
	var world_b := WorldState.new()
	var narrative_b := NarrativeState.new()
	var manager_b := SaveManager.new(context_a["manager"].save_path, registry)
	var playground_b: CombatPlayground = PLAYGROUND.instantiate()
	fixture.add_node(playground_b)
	await fixture.physics_frames(2)
	playground_b.player.set_physics_process(false)
	playground_b.primary_enemy.set_physics_process(false)
	var session_b := GameSession.new()
	fixture.add_node(session_b)
	session_b.configure(playground_b, world_b, narrative_b, manager_b, registry)
	playground_b.player.stats.hp = 1.0
	playground_b.player.stats.stamina = 2.0
	playground_b.player.stats.mana = 3.0
	playground_b.player.vessel.charges = 0
	playground_b.primary_enemy.hp = 1.0
	playground_b.primary_enemy.global_position += Vector3(1.0, 0.0, 0.0)
	playground_b.primary_enemy.state_machine._enter(EnemyStateMachine.Phase.WINDUP)
	assertions.is_true(session_b.restore_startup())
	assertions.equal(world_b.current_checkpoint_id, ROOT_CHECKPOINT.id)
	assertions.is_true(world_b.has_opened_shortcut(&"shortcut.persisted"))
	assertions.is_true(narrative_b.has_learned_truth(&"truth.persisted"))
	assertions.equal(playground_b.player.global_transform, ROOT_CHECKPOINT.respawn_transform)
	assertions.equal(playground_b.player.stats.hp, playground_b.player.stats.tuning.max_hp)
	assertions.equal(playground_b.player.stats.stamina, playground_b.player.stats.tuning.max_stamina)
	assertions.equal(playground_b.player.stats.mana, playground_b.player.stats.tuning.max_mana)
	assertions.equal(playground_b.player.vessel.charges, playground_b.player.vessel.max_charges)
	assertions.equal(playground_b.player.actions.phase, PlayerActionMachine.Phase.FREE)
	assertions.equal(playground_b.primary_enemy.hp, playground_b.primary_enemy.definition.max_hp)
	assertions.equal(playground_b.primary_enemy.global_position, playground_b.primary_enemy.home_position)
	assertions.equal(playground_b.primary_enemy.state_machine.phase, EnemyStateMachine.Phase.IDLE)
	_cleanup(context_a["dir"])
	return true

func _session_context(label: String, fixture: RefCounted) -> Dictionary:
	var directory := "user://m2c-tests/session-%s-%d" % [label, Time.get_ticks_usec()]
	_cleanup(directory)
	var registry := _registry()
	var world := WorldState.new()
	var narrative := NarrativeState.new()
	var manager := SaveManager.new("%s/profile.json" % directory, registry)
	var playground: CombatPlayground = PLAYGROUND.instantiate()
	fixture.add_node(playground)
	await fixture.physics_frames(2)
	playground.player.set_physics_process(false)
	playground.primary_enemy.set_physics_process(false)
	playground.primary_enemy.reset_enemy()
	var session := GameSession.new()
	fixture.add_node(session)
	session.configure(playground, world, narrative, manager, registry)
	return {"dir": directory, "registry": registry, "world": world, "narrative": narrative, "manager": manager, "playground": playground, "session": session}

func _registry() -> ContentRegistry:
	var registry := ContentRegistry.new()
	registry.register_checkpoint(ROOT_CHECKPOINT)
	return registry

func _cleanup(directory: String) -> void:
	var absolute := ProjectSettings.globalize_path(directory)
	if not DirAccess.dir_exists_absolute(absolute): return
	var dir := DirAccess.open(absolute)
	if dir != null:
		for file in dir.get_files(): dir.remove(file)
	DirAccess.remove_absolute(absolute)
