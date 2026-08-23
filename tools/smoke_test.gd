extends Node
## Automated smoke test for Royal Forest's core loop.
## Run: ~/.local/opt/godot --headless res://tools/smoke_test.tscn
## Prints PASS/FAIL per check; exits 0 only if everything passes.

var failures := 0


func check(name: String, cond: bool) -> void:
	if cond:
		print("PASS: " + name)
	else:
		failures += 1
		print("FAIL: " + name)


func _ready() -> void:
	await _run()
	print("SMOKE RESULT: %s (%d failures)" % ["OK" if failures == 0 else "BROKEN", failures])
	get_tree().quit(0 if failures == 0 else 1)


func _run() -> void:
	var main: Node3D = load("res://scenes/main.tscn").instantiate()
	add_child(main)
	for i in 30:
		await get_tree().physics_frame

	var players := get_tree().get_nodes_in_group("player")
	check("player spawned", players.size() == 1)
	if players.is_empty():
		return
	var player: CharacterBody3D = players[0]

	# --- bow pickup via chest ---
	var chest: Node3D = null
	for c in main.get_children():
		if c.get_script() != null and str(c.get_script().resource_path).ends_with("chest.gd"):
			chest = c
	check("chest exists", chest != null)
	if chest:
		chest.interact()
		for i in 3:
			await get_tree().physics_frame
		check("chest gives bow", GameState.has_bow)
		check("bow viewmodel visible", player.bow_holder.visible)

	# --- arrow kills an enemy ---
	player.global_position = Vector3(-4.0, 0.2, -9.0)
	for i in 5:
		await get_tree().physics_frame
	var enemies := get_tree().get_nodes_in_group("enemies")
	check("enemies spawned", enemies.size() == 4)
	# --- LOS: an enemy with a wall between it and the player must NOT aggro ---
	if enemies.size() > 0:
		player.global_position = Vector3(0, 0.2, 13)   # spawn room
		for i in 5:
			await get_tree().physics_frame
		var wall_blocked := false
		for e in enemies:
			if is_instance_valid(e) and e.global_position.distance_to(player.global_position) > 20.0:
				wall_blocked = e.state == e.State.IDLE or wall_blocked
		check("enemy behind walls stays idle", wall_blocked)
	if enemies.size() > 0:
		var foe: Node = null
		for e in enemies:
			if is_instance_valid(e) and e.state != e.State.DEAD \
					and e.global_position.distance_to(player.global_position) < 3.0:
				foe = e
				break
		if foe == null:
			foe = enemies[0]
		player.global_position = foe.global_position + Vector3(0, 0.2, 4.0)
		for i in 5:
			await get_tree().physics_frame
		var hp_before: int = foe.hp
		# fire an arrow straight at the foe from the player's camera
		var dir: Vector3 = (foe.global_position + Vector3(0, 0.8, 0)) \
				- (player.global_position + Vector3(0, 1.6, 0))
		var arrow := Arrow.make(player.global_position + Vector3(0, 1.6, 0), dir)
		main.add_child(arrow)
		var frames := 0
		while is_instance_valid(foe) and foe.hp == hp_before and frames < 120:
			await get_tree().physics_frame
			frames += 1
		check("arrow hit damages enemy", is_instance_valid(foe) == false or foe.hp < hp_before or foe.state == foe.State.DEAD)
		# finish it off to confirm death path
		while is_instance_valid(foe) and foe.state != foe.State.DEAD:
			foe.take_damage(100, player.global_position)
		check("enemy dies", not is_instance_valid(foe) or foe.state == foe.State.DEAD)

	# --- door locked without key ---
	GameState.has_key = false
	var door: Node3D = null
	for c in main.get_children():
		if c.get_script() != null and str(c.get_script().resource_path).ends_with("locked_door.gd"):
			door = c
	check("door exists", door != null)
	if door:
		door.interact()
		check("door stays locked w/o key", not door.opened)
		GameState.give_key()
		door.interact()
		check("door opens with key", door.opened)

	# --- key pickup area works ---
	var key_area: Area3D = null
	for c in main.get_children():
		if c is Area3D and c.has_method("_on_body_entered") and not c.is_in_group("player"):
			key_area = c
	check("key pickup exists", key_area != null)

	# --- damage & death flow ---
	GameState.take_damage(30)
	check("damage reduces hp", GameState.hp == GameState.MAX_HP - 30)
	await get_tree().create_timer(0.5).timeout   # past the i-frame window
	GameState.take_damage(9999)
	check("death at 0 hp", GameState.dead)

	# --- win zone ---
	GameState.reset()
	if players.size() > 0:
		player.global_position = Vector3(-20.0, 0.2, -10.0)
		for i in 20:
			await get_tree().physics_frame
		check("win zone triggers victory", GameState.game_won)
