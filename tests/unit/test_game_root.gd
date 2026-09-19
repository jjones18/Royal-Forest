extends RefCounted

const Assertions = preload("res://tests/support/assertions.gd")
const GAME_ROOT := preload("res://game/app/game_root.tscn")

func test_game_root_instantiates_combat_playground(assertions: Assertions, fixture: RefCounted) -> bool:
	var root := GAME_ROOT.instantiate()
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


func test_mouse_motion_yaws_player_with_hud_present(assertions: Assertions, fixture: RefCounted) -> bool:
	var root := GAME_ROOT.instantiate()
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
