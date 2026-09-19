extends Node

const GAME_ROOT := preload("res://game/app/game_root.tscn")


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	if DisplayServer.get_name() == "headless":
		_fail("probe requires a real display backend")
		return
	var root := GAME_ROOT.instantiate()
	root.restore_save_on_startup = false
	add_child(root)
	await get_tree().physics_frame
	await get_tree().physics_frame
	var player: PlayerController = root.playground.player
	root.playground.primary_enemy.set_physics_process(false)
	player.receive_enemy_damage(player.stats.tuning.max_hp * 2.0)
	var dead_position := player.global_position
	if player.actions.phase != PlayerActionMachine.Phase.DEAD:
		_fail("player did not enter DEAD")
		return
	if not InputMap.action_get_events("release_mouse").any(func(event: InputEvent) -> bool:
		return event is InputEventKey and event.keycode == KEY_ESCAPE
	):
		_fail("release_mouse is not bound to Escape")
		return
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	if Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
		_fail("cursor did not begin captured")
		return
	var press := InputEventAction.new()
	press.action = &"release_mouse"
	press.pressed = true
	Input.parse_input_event(press)
	await get_tree().process_frame
	await get_tree().physics_frame
	await get_tree().process_frame
	var release := InputEventAction.new()
	release.action = &"release_mouse"
	release.pressed = false
	Input.parse_input_event(release)
	if Input.mouse_mode != Input.MOUSE_MODE_VISIBLE:
		_fail("Escape did not release the captured cursor while DEAD")
		return
	if player.actions.phase != PlayerActionMachine.Phase.DEAD:
		_fail("cursor release revived the player")
		return
	if not player.global_position.is_equal_approx(dead_position):
		_fail("cursor release moved the DEAD player")
		return
	print("DEAD CURSOR RELEASE PROBE: PASS")
	get_tree().quit(0)


func _fail(message: String) -> void:
	push_error("DEAD CURSOR RELEASE PROBE: FAIL — %s" % message)
	get_tree().quit(1)
