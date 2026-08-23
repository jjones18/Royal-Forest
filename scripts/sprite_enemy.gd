class_name SpriteEnemy
extends CharacterBody3D
## Billboarded sprite enemy: idle until it sees the player, chase, windup,
## strike. Red flash + knockback on being hit; dies with a fade.

signal enemy_died

enum State { IDLE, CHASE, WINDUP, RECOVER, DEAD }

@export var max_hp := 60
@export var move_speed := 1.6
@export var attack_damage := 15
@export var sight_range := 9.0
@export var attack_range := 1.5
@export var windup_time := 0.55   # telegraph — the "tell" players learn to punish
@export var recover_time := 0.8
## How long the enemy keeps hunting your last known position after losing
## sight before giving up and going back to idle.
@export var memory_time := 2.5
@export var sprite_texture: Texture2D
@export var sprite_pixel_size := 0.028

var hp: int
var state: int = State.IDLE
var _sprite: Sprite3D
var _timer := 0.0
var _bob_t := 0.0
var _player: Node3D
var _los_ray: RayCast3D          # world-only line-of-sight probe
var _sees_player := false
var _memory := 0.0               # seconds of hunt left after losing sight
var _last_known := Vector3.ZERO
var _pending_knockback := Vector3.ZERO   # applied next physics tick (signal-safe)
var _flash_tw: Tween                     # red-flash tween, killed on death


func _ready() -> void:
	hp = max_hp
	add_to_group("enemies")
	collision_layer = 4
	collision_mask = 1 | 2   # world + player

	var shape := CollisionShape3D.new()
	var cap := CapsuleShape3D.new()
	cap.radius = 0.35
	cap.height = 1.4
	shape.shape = cap
	shape.position = Vector3(0, 0.7, 0)
	add_child(shape)

	_sprite = Sprite3D.new()
	if sprite_texture != null:
		_sprite.texture = sprite_texture
	_sprite.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y
	_sprite.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	_sprite.shaded = true
	_sprite.alpha_cut = SpriteBase3D.ALPHA_CUT_DISCARD
	_sprite.pixel_size = sprite_pixel_size
	_sprite.position.y = 0.85
	add_child(_sprite)

	# world-only LOS probe: chest height, ignores enemies/player layers
	_los_ray = RayCast3D.new()
	_los_ray.enabled = false
	_los_ray.position.y = 1.1
	_los_ray.collision_mask = 1
	_los_ray.collide_with_areas = false
	add_child(_los_ray)


func _physics_process(delta: float) -> void:
	if state == State.DEAD:
		return
	if _player == null or not is_instance_valid(_player):
		var nodes := get_tree().get_nodes_in_group("player")
		_player = nodes[0] if nodes.size() > 0 else null

	_timer -= delta
	_bob_t += delta
	_update_sight(delta)

	# knockback is queued by take_damage (a physics callback) and applied here,
	# with collision — no more teleporting through walls
	if _pending_knockback.length() > 0.01:
		move_and_collide(_pending_knockback)
		_pending_knockback = Vector3.ZERO

	match state:
		State.IDLE:
			if _sees_player:
				state = State.CHASE
				GameState.say("")  # (music/sting hook later)
		State.CHASE:
			if _player == null or (not _sees_player and _memory <= 0.0):
				state = State.IDLE
				return
			var to_p := _flat_to_player()
			var dist := to_p.length()
			if dist <= attack_range and _sees_player:
				_enter_windup()
			else:
				# hunt last known position while sight is lost, not the player
				var target := _player.global_position if _sees_player else _last_known
				var to_t := target - global_position
				to_t.y = 0.0
				if to_t.length() < 0.4 and not _sees_player:
					state = State.IDLE   # reached where you were; give up
					return
				var dir := to_t.normalized()
				velocity.y -= 14.0 * delta   # gravity — stay glued to the floor
				velocity.x = dir.x * move_speed
				velocity.z = dir.z * move_speed
				move_and_slide()
				# shamble bob
				_sprite.position.y = 0.85 + absf(sin(_bob_t * 6.0)) * 0.06
		State.WINDUP:
			velocity.x = 0
			velocity.z = 0
			if _player != null:  # keep facing
				look_at_flat(_player.global_position)
			if _timer <= 0.0:
				_strike()
		State.RECOVER:
			velocity.x = 0
			velocity.z = 0
			if _timer <= 0.0:
				state = State.CHASE


## True when the player is within sight range AND nothing solid blocks the
## way. Refreshes the hunt memory while sight is held.
func _update_sight(delta: float) -> void:
	if _player == null or not is_instance_valid(_player) \
			or GameState.dead or GameState.game_won:
		_sees_player = false
		return
	var to_p := _flat_to_player()
	if to_p.length() > sight_range:
		_sees_player = false
	else:
		_los_ray.target_position = _los_ray.to_local(
				_player.global_position + Vector3(0, 1.2, 0))
		_los_ray.force_raycast_update()
		_sees_player = not _los_ray.is_colliding()

	if _sees_player:
		_memory = memory_time
		_last_known = _player.global_position
	elif _memory > 0.0 and state != State.IDLE:
		_memory -= delta


func _flat_to_player() -> Vector3:
	if _player == null:
		return Vector3.ZERO
	var v := _player.global_position - global_position
	v.y = 0.0
	return v


func look_at_flat(target: Vector3) -> void:
	var v := target - global_position
	v.y = 0.0
	if v.length() > 0.01:
		rotation.y = atan2(-v.x, -v.z)


func _enter_windup() -> void:
	state = State.WINDUP
	_timer = windup_time
	# lunge-back tell: quick recoil before the strike
	var tw := create_tween()
	tw.tween_property(_sprite, "position:z", 0.18, windup_time * 0.6)
	tw.tween_property(_sprite, "position:z", -0.12, windup_time * 0.25)
	tw.tween_property(_sprite, "position:z", 0.0, windup_time * 0.15)


func _strike() -> void:
	if _player == null:
		state = State.RECOVER
		_timer = recover_time
		return
	var dist := _flat_to_player().length()
	if dist <= attack_range * 1.35 and not GameState.dead and not GameState.game_won:
		GameState.take_damage(attack_damage)
	state = State.RECOVER
	_timer = recover_time


func take_damage(amount: int, from_pos: Vector3) -> void:
	if state == State.DEAD:
		return
	hp -= amount
	# being hit wakes it up, even from full stealth (arrow from beyond sight)
	if state == State.IDLE:
		state = State.CHASE
		_sees_player = false
		_memory = memory_time
		_last_known = from_pos
		GameState.say("")
	# red flash (store the tween so a killing blow can't fight the death fade)
	_sprite.modulate = Color(1, 0.25, 0.25)
	_flash_tw = create_tween()
	_flash_tw.tween_property(_sprite, "modulate", Color.WHITE, 0.22)
	# knockback away from the player — queued and applied next physics tick
	# through move_and_collide(), so walls stop it (no more clipping through)
	var push := global_position - from_pos
	push.y = 0.0
	if push.length() > 0.01:
		_pending_knockback += push.normalized() * 0.45
	if hp <= 0:
		_die()


func _die() -> void:
	state = State.DEAD
	set_physics_process(false)
	collision_layer = 0
	collision_mask = 1
	if _flash_tw != null and _flash_tw.is_valid():
		_flash_tw.kill()   # stop the flash from fighting the death fade
	enemy_died.emit()
	var tw := create_tween()
	tw.tween_property(_sprite, "modulate:a", 0.0, 0.7)
	tw.parallel().tween_property(_sprite, "position:y", 0.25, 0.7)
	tw.tween_callback(queue_free)
