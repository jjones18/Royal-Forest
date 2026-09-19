extends RefCounted

const Assertions = preload("res://tests/support/assertions.gd")
const GAME_ROOT := preload("res://game/app/game_root.tscn")
const ROOT_CHECKPOINT: CheckpointDefinition = preload("res://game/data/checkpoints/root_tree.tres")

func test_game_root_instantiates_combat_playground(assertions: Assertions, fixture: RefCounted) -> bool:
	var root := GAME_ROOT.instantiate()
	root.restore_save_on_startup = false
	fixture.add_node(root)
	await fixture.process_frames(1)
	assertions.is_true(root is Node, "GameRoot must instantiate as a Node")
	assertions.equal(root.name, &"GameRoot")
	assertions.is_true(root.playground is CombatPlayground, "M1 GameRoot must launch the combat playground")
	assertions.is_true(root.playground.player is PlayerController)
	assertions.is_true(root.playground.primary_enemy is EnemyController)
	assertions.is_true(root.recorder is GameplayRecorder, "M1 GameRoot must include the diagnostic recorder")
	assertions.equal(root.recorder.playground, root.playground, "recorder must observe the live playground")
	return true


func test_dead_escape_releases_captured_mouse_without_reviving_or_moving(assertions: Assertions, fixture: RefCounted) -> bool:
	if DisplayServer.get_name() == "headless":
		# Headless forces mouse mode visible. The complete verification suite runs
		# this production InputRouter path under Xvfb with real capture semantics.
		return true
	var root := GAME_ROOT.instantiate()
	root.restore_save_on_startup = false
	fixture.add_node(root)
	await fixture.physics_frames(2)
	var player: PlayerController = root.playground.player
	root.playground.primary_enemy.set_physics_process(false)
	player.receive_enemy_damage(player.stats.tuning.max_hp * 2.0)
	var dead_position := player.global_position
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	assertions.equal(Input.mouse_mode, Input.MOUSE_MODE_CAPTURED, "real-display DEAD cursor test must begin captured")
	var escape_is_bound := InputMap.action_get_events("release_mouse").any(func(event: InputEvent) -> bool:
		return event is InputEventKey and event.keycode == KEY_ESCAPE
	)
	assertions.is_true(escape_is_bound, "release_mouse must remain bound to Escape")
	var release_command := InputCommand.new()
	release_command.release_mouse_pressed = true
	player.simulate_command(release_command, 1.0 / 60.0)
	assertions.equal(Input.mouse_mode, Input.MOUSE_MODE_VISIBLE, "M2C_DEAD_CURSOR_RELEASE: Escape command must release the captured cursor while DEAD")
	assertions.equal(player.actions.phase, PlayerActionMachine.Phase.DEAD, "cursor release must not revive the player")
	assertions.equal(player.global_position, dead_position, "cursor release must not move the DEAD player")
	return true


func test_game_root_reports_unrecoverable_startup_load_failure(assertions: Assertions, fixture: RefCounted) -> bool:
	var directory := "user://m2c-tests/root-load-failure-%d" % Time.get_ticks_usec()
	_cleanup(directory)
	var save_path := "%s/profile.json" % directory
	var absolute_directory := ProjectSettings.globalize_path(directory)
	assertions.equal(DirAccess.make_dir_recursive_absolute(absolute_directory), OK)
	var corrupt := FileAccess.open(save_path, FileAccess.WRITE)
	assertions.is_true(corrupt != null)
	if corrupt != null:
		corrupt.store_string("{broken")
		corrupt.close()
	var root := GAME_ROOT.instantiate()
	root.save_path = save_path
	fixture.add_node(root)
	await fixture.physics_frames(3)
	assertions.equal(root.save_manager.last_status, &"load_failed")
	assertions.equal(root.session.status_kind, &"load_failed", "M2C_STARTUP_LOAD_FAILURE_VISIBLE: unrecoverable startup load must report load_failed")
	assertions.equal(root.session.status_text, "SAVE LOAD FAILED — STARTING FRESH")
	assertions.equal(root.playground.hud.feedback_label.text, "SAVE LOAD FAILED — STARTING FRESH", "M2C_STARTUP_LOAD_FAILURE_VISIBLE: HUD must show unrecoverable startup failure")
	assertions.is_true(root.playground.hud.feedback_label.visible, "M2C_STARTUP_LOAD_FAILURE_VISIBLE: startup failure feedback must be visible")
	assertions.equal(root.world_state.snapshot(), WorldState.new().snapshot(), "rejected startup save must not partially mutate world state")
	assertions.equal(root.narrative_state.snapshot(), NarrativeState.new().snapshot(), "rejected startup save must not partially mutate narrative state")
	assertions.equal(root.playground.player.global_transform, root.playground.player.spawn_transform, "rejected startup save must leave the player at authored spawn")
	assertions.is_true(FileAccess.file_exists(save_path), "corrupt save must remain on disk for diagnosis or manual recovery")
	assertions.equal(FileAccess.get_file_as_string(save_path), "{broken")
	_cleanup(directory)
	return true


func test_game_root_recovers_valid_backup_on_startup(assertions: Assertions, fixture: RefCounted) -> bool:
	var directory := "user://m2c-tests/root-backup-%d" % Time.get_ticks_usec()
	_cleanup(directory)
	var registry := ContentRegistry.new()
	registry.register_checkpoint(ROOT_CHECKPOINT)
	var world := WorldState.new()
	var narrative := NarrativeState.new()
	world.activate_checkpoint(ROOT_CHECKPOINT.id)
	world.open_shortcut(&"shortcut.backup")
	var manager := SaveManager.new("%s/profile.json" % directory, registry)
	assertions.is_true(manager.save_game(world, narrative, ROOT_CHECKPOINT.id, 4.0))
	assertions.is_true(manager.save_game(world, narrative, ROOT_CHECKPOINT.id, 5.0))
	var corrupt := FileAccess.open(manager.save_path, FileAccess.WRITE)
	corrupt.store_string("{broken")
	corrupt.close()
	var root := GAME_ROOT.instantiate()
	root.save_path = manager.save_path
	fixture.add_node(root)
	await fixture.physics_frames(3)
	assertions.equal(root.save_manager.last_status, &"recovered_backup")
	assertions.equal(root.session.status_kind, &"backup_recovered")
	assertions.equal(root.session.status_text, "SAVE RECOVERED FROM BACKUP")
	assertions.equal(root.playground.hud.feedback_label.text, "SAVE RECOVERED FROM BACKUP")
	assertions.is_true(root.playground.hud.feedback_label.visible)
	assertions.equal(root.world_state.current_checkpoint_id, ROOT_CHECKPOINT.id)
	assertions.is_true(root.world_state.has_opened_shortcut(&"shortcut.backup"))
	assertions.equal(root.playground.player.global_transform, ROOT_CHECKPOINT.respawn_transform)
	assertions.equal(root.playground.player.actions.phase, PlayerActionMachine.Phase.FREE)
	assertions.equal(root.playground.primary_enemy.state_machine.phase, EnemyStateMachine.Phase.IDLE)
	_cleanup(directory)
	return true


func test_spawn_flow_can_activate_root_tree_after_normal_physics_frames(assertions: Assertions, fixture: RefCounted) -> bool:
	var directory := "user://m2c-tests/root-flow-%d" % Time.get_ticks_usec()
	_cleanup(directory)
	var root := GAME_ROOT.instantiate()
	root.save_path = "%s/profile.json" % directory
	fixture.add_node(root)
	await fixture.physics_frames(6)
	assertions.is_true(root.playground.primary_enemy.is_physics_processing(), "root-tree safety must not disable enemy simulation")
	assertions.equal(root.playground.primary_enemy.state_machine.phase, EnemyStateMachine.Phase.IDLE, "the physical root tree must occlude the spawn without a no-aggro aura")
	assertions.is_false(root.playground.primary_enemy.has_line_of_sight_to_player(), "the root tree trunk must provide real spawn LOS cover")
	assertions.is_true(root.world_state is WorldState)
	assertions.is_true(root.narrative_state is NarrativeState)
	assertions.is_true(root.save_manager is SaveManager)
	assertions.is_true(root.content_registry is ContentRegistry)
	assertions.is_true(root.session is GameSession)
	assertions.is_true(root.playground.living_tree.can_interact(root.playground.player.global_position), "spawn must begin within the bounded root-tree interaction radius")
	var interact := InputCommand.new()
	interact.interact_pressed = true
	root.playground.player.simulate_command(interact, 0.0)
	assertions.equal(root.world_state.current_checkpoint_id, &"checkpoint.root_tree", "normal startup physics must not race enemy aggro and permanently block the tree")
	assertions.equal(root.session.status_kind, &"save_success")
	assertions.is_true(FileAccess.file_exists(root.save_manager.save_path))
	_cleanup(directory)
	return true


func test_mouse_motion_yaws_player_with_hud_present(assertions: Assertions, fixture: RefCounted) -> bool:
	var root := GAME_ROOT.instantiate()
	root.restore_save_on_startup = false
	fixture.add_node(root)
	await fixture.physics_frames(2)
	var player: PlayerController = root.playground.player
	if DisplayServer.get_name() == "headless":
		# Headless cannot enter captured mouse mode; the complete verification
		# suite repeats this test under Xvfb with a real display backend.
		return true
	var yaw_before := player.rotation.y
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	assertions.equal(Input.mouse_mode, Input.MOUSE_MODE_CAPTURED, "real-display test must capture the mouse")
	var motion := InputEventMouseMotion.new()
	motion.relative = Vector2(120.0, 0.0)
	player.get_viewport().push_input(motion)
	await fixture.physics_frames(2)
	assertions.is_true(absf(player.rotation.y - yaw_before) > 0.001, "mouse motion must yaw the player through the production input path with the HUD present")
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	return true


func _cleanup(directory: String) -> void:
	var absolute := ProjectSettings.globalize_path(directory)
	if not DirAccess.dir_exists_absolute(absolute):
		return
	var dir := DirAccess.open(absolute)
	if dir != null:
		for file in dir.get_files():
			dir.remove(file)
	DirAccess.remove_absolute(absolute)
