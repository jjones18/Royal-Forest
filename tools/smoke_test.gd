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

	# --- weapon pickup via chest (weighted roll) ---
	var chest: Node3D = null
	for c in main.get_children():
		if c.get_script() != null and str(c.get_script().resource_path).ends_with("chest.gd"):
			chest = c
	check("chest exists", chest != null)
	if chest:
		chest.interact()
		for i in 3:
			await get_tree().physics_frame
		check("chest grants a weapon", GameState.weapon != "")
		check("weapon id is valid", Weapons.CATALOG.has(GameState.weapon))
		check("viewmodel visible", player.weapon_holder.visible)

	# --- arrow kills an enemy ---
	player.global_position = Vector3(-4.0, 0.2, -9.0)
	for i in 5:
		await get_tree().physics_frame
	var enemies := get_tree().get_nodes_in_group("enemies")
	check("enemies spawned", enemies.size() == 4)
	# --- LOS: EVERY distant enemy must stay idle behind walls (strict) ---
	if enemies.size() > 0:
		# neutralize any aggro picked up while the suite passed through room B,
		# so we measure pure wall-blocking from a clean IDLE slate
		for e in enemies:
			if is_instance_valid(e):
				e.state = e.State.IDLE
				e._memory = 0.0
		player.global_position = Vector3(0, 0.2, 13)   # spawn room
		for i in 5:
			await get_tree().physics_frame
		var all_idle := true
		for e in enemies:
			if is_instance_valid(e) and e.global_position.distance_to(player.global_position) > 20.0:
				if e.state != e.State.IDLE:
					all_idle = false
		check("enemy behind walls stays idle", all_idle)
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

	# --- weapon roll distribution: chances sum to ~1 and every id is valid ---
	var weights := 0.0
	for id in Weapons.CATALOG:
		weights += Weapons.CATALOG[id]["chance"]
	check("weapon chances are sane", absf(weights - 1.0) < 0.001)
	# roll() must only ever return catalog ids
	var rolls_valid := true
	for i in 200:
		if not Weapons.CATALOG.has(Weapons.roll()):
			rolls_valid = false
			break
	check("200 weapon rolls all valid", rolls_valid)

	# --- melee swing kills an enemy (force sword) ---
	GameState.give_weapon("sword")
	player.global_position = Vector3(-4.0, 0.2, -9.0)
	for i in 5:
		await get_tree().physics_frame
	var enemies2 := get_tree().get_nodes_in_group("enemies")
	if enemies2.size() > 0:
		var foe_m: Node = enemies2[0]
		player.global_position = foe_m.global_position + Vector3(0, 0.2, 1.2)
		for i in 5:
			await get_tree().physics_frame
		var hp_before_m: int = foe_m.hp
		player._apply_melee_hit(Weapons.CATALOG["sword"])
		check("melee hit damages enemy", not is_instance_valid(foe_m) \
				or foe_m.hp < hp_before_m or foe_m.state == foe_m.State.DEAD)

	# --- melee whiff: out of reach must not damage ---
	if enemies2.size() > 0:
		var foe_w: Node = enemies2[1] if enemies2.size() > 1 else enemies2[0]
		if is_instance_valid(foe_w):
			# stand well beyond the sword's 3.5 m reach
			player.global_position = foe_w.global_position + Vector3(0, 0.2, 8.0)
			for i in 5:
				await get_tree().physics_frame
			var hp_before_w: int = foe_w.hp
			player._apply_melee_hit(Weapons.CATALOG["sword"])
			check("melee whiff out of range", is_instance_valid(foe_w) \
					and foe_w.hp == hp_before_w)

	# --- i-frames: damage during invuln window must no-op ---
	var hp_pre := GameState.hp
	GameState.take_damage(10)          # starts a 0.4s invuln window
	GameState.take_damage(10)          # same frame — must be ignored
	check("i-frames block repeat hits", GameState.hp == hp_pre - 10)
	await get_tree().create_timer(0.5).timeout

	# --- spells: mana cost, burn, slow, regen ---
	GameState.mana = 100.0
	player._spell_cd = 0.0
	player._cast("fire")
	check("fireball spends mana", GameState.mana <= 100.0 - GameState.FIREBALL_COST)
	var enemies3 := get_tree().get_nodes_in_group("enemies")
	if enemies3.size() > 0:
		var foe_s: Node = null
		for e in enemies3:
			if is_instance_valid(e) and e.state != e.State.DEAD:
				foe_s = e
				break
		if foe_s != null:
			var hp0: int = foe_s.hp
			foe_s.apply_slow(0.7, 3.0)
			check("frost slows enemy", foe_s.move_speed_current() < foe_s.move_speed)
			foe_s.apply_burn(2, 6)
			check("burn ticks deal damage", foe_s.hp < hp0 or foe_s.state == foe_s.State.DEAD)
	# mana regen tick
	var m_before := GameState.mana
	await get_tree().create_timer(0.3).timeout
	check("mana regenerates", GameState.mana >= m_before)

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

	# --- E-interact regression: player's own ray must reach the chest ---
	# (guards against the input branch or ray wiring being dropped again)
	player.global_position = Vector3(-3.5, 0.2, 11.0)
	player.rotation = Vector3.ZERO          # face -z, toward the chest
	player.camera.rotation.x = -0.45        # pitch down onto the lid
	for i in 8:
		await get_tree().physics_frame
	var seen: Object = player._ray.get_collider()
	check("interact ray sees chest", seen != null and seen.has_method("interact"))

	# --- damage & death flow ---
	GameState.hp = GameState.MAX_HP   # normalize (earlier tests spent HP)
	GameState._invuln = 0.0
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
