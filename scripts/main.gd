extends Node3D
## Royal Forest main — builds the dungeon from the layout tables below,
## then drops in the player, props, enemies, lights, and HUD.
##
## Layout is data-driven so we can reshape rooms without touching the editor.
## Coordinates: x = east(+)/west(-), z = south(+)/north(-). Player faces -z.

const WALL_H := 3.5
const WALL_T := 0.5

# Each wall: [cx, cz, size_x, size_z]
var WALLS := [
	# --- Room A (spawn room) ---
	[-4.0,   4.0, 4.0, WALL_T], [4.0,   4.0, 4.0, WALL_T],   # north wall w/ corridor gap
	[ 0.0,  16.0, 12.0, WALL_T],                              # south wall
	[ 6.0,  10.0, WALL_T, 12.0], [-6.0, 10.0, WALL_T, 12.0],  # east / west
	# --- corridor A->B ---
	[-2.0, 0.0, WALL_T, 8.0], [2.0, 0.0, WALL_T, 8.0],
	# --- Room B (central hall) ---
	[-5.0, -4.0, 6.0, WALL_T], [5.0, -4.0, 6.0, WALL_T],      # south wall w/ gap
	[ 0.0, -16.0, 16.0, WALL_T],                               # north wall
	[ 8.0, -10.0, WALL_T, 12.0],                               # east
	# west wall with door gap (gap z -11.5..-8.5)
	[-8.0, -13.75, WALL_T, 4.5], [-8.0, -6.25, WALL_T, 4.5],
	# --- corridor B->C ---
	[-11.0, -11.5, 6.0, WALL_T], [-11.0, -8.5, 6.0, WALL_T],
	# --- Room C (shrine / exit) ---
	[-18.0, -14.0, 8.0, WALL_T], [-18.0, -6.0, 8.0, WALL_T],
	[-22.0, -10.0, WALL_T, 8.0],
	[-14.0, -12.75, WALL_T, 2.5], [-14.0, -7.25, WALL_T, 2.5],
]

# Warm point lights: [x, z, energy]
var LIGHTS := [
	[0.0, 10.0, 1.1],     # room A
	[0.0,  0.0, 0.7],     # corridor
	[0.0, -10.0, 1.1],    # room B
	[-18.0, -10.0, 1.4],  # room C — brighter, cold
]

const PLAYER_SPAWN := Vector3(0, 0.2, 13)
const CHEST_POS := Vector3(-3.5, 0, 9)
const KEY_POS := Vector3(6.0, 0, -14.0)
const DOOR_POS := Vector3(-8.0, 0, -10.0)
const WIN_ZONE := Vector3(-20.0, 0, -10.0)

# Enemy spawns: [script_texture_key, x, z]
var ENEMIES := [
	["shambler", 0.0, -1.0],
	["shambler", -4.0, -9.0],
	["shambler", 3.0, -13.0],
	["crawler", -17.0, -10.0],   # guards the shrine
]


func _ready() -> void:
	_build_environment()
	_build_floor()
	for w in WALLS:
		_wall(w[0], w[1], w[2], w[3])
	_build_props()
	_build_enemies()
	_build_player()
	_build_hud()


# --------------------------------------------------------------- environment

func _build_environment() -> void:
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.01, 0.01, 0.02)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.20, 0.20, 0.30)
	env.ambient_light_energy = 0.45
	env.fog_enabled = true
	env.fog_light_color = Color(0.04, 0.04, 0.07)
	env.fog_density = 0.055
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)


func _stone_material(tiling: float) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_texture = load("res://assets/sprites/wall_stone.png")
	mat.uv1_triplanar = true
	mat.uv1_scale = Vector3.ONE * tiling
	mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST_WITH_MIPMAPS
	mat.roughness = 1.0
	return mat


func _box_body(pos: Vector3, size: Vector3, mat: Material) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.position = pos
	var mesh_i := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	mesh.material = mat
	mesh_i.mesh = mesh
	body.add_child(mesh_i)
	var col := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	col.shape = shape
	body.add_child(col)
	add_child(body)
	return body


func _build_floor() -> void:
	_box_body(Vector3(0, -0.25, 0), Vector3(48, 0.5, 40), _stone_material(0.35))


func _wall(cx: float, cz: float, sx: float, sz: float) -> void:
	_box_body(Vector3(cx, WALL_H * 0.5, cz), Vector3(sx, WALL_H, sz),
			_stone_material(0.55))


# --------------------------------------------------------------------- props

func _sprite_prop(texture_path: String, pixel_size: float) -> Sprite3D:
	var spr := Sprite3D.new()
	spr.texture = load(texture_path)
	spr.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	spr.shaded = true
	spr.alpha_cut = SpriteBase3D.ALPHA_CUT_DISCARD
	spr.pixel_size = pixel_size
	return spr


func _build_props() -> void:
	# chest
	var chest := StaticBody3D.new()
	chest.position = CHEST_POS
	chest.set_script(load("res://scripts/chest.gd"))
	var cs := CollisionShape3D.new()
	var cshape := BoxShape3D.new()
	cshape.size = Vector3(0.9, 0.8, 0.65)
	cs.shape = cshape
	cs.position.y = 0.4
	chest.add_child(cs)
	var ch_spr := _sprite_prop("res://assets/sprites/chest_closed.png", 0.024)
	ch_spr.name = "Sprite"
	ch_spr.position.y = 0.44
	chest.add_child(ch_spr)
	add_child(chest)

	# key (Area3D pickup)
	var key := Area3D.new()
	key.position = KEY_POS
	key.monitoring = true
	key.collision_layer = 0
	key.collision_mask = 2  # player layer
	key.set_script(load("res://scripts/key_pickup.gd"))
	var kc := CollisionShape3D.new()
	var ksphere := SphereShape3D.new()
	ksphere.radius = 0.7
	kc.shape = ksphere
	kc.position.y = 0.9
	key.add_child(kc)
	var k_spr := _sprite_prop("res://assets/sprites/key.png", 0.03)
	k_spr.shaded = false
	k_spr.name = "Sprite"
	k_spr.position.y = 0.9
	key.add_child(k_spr)
	key.body_entered.connect(key._on_body_entered)
	add_child(key)

	# locked door (fills the west-wall gap of room B)
	var door := StaticBody3D.new()
	door.position = DOOR_POS
	door.set_script(load("res://scripts/locked_door.gd"))
	var dc := CollisionShape3D.new()
	var dshape := BoxShape3D.new()
	dshape.size = Vector3(WALL_T + 0.1, 3.0, 3.0)
	dc.shape = dshape
	dc.position.y = 1.5
	door.add_child(dc)
	var d_spr := _sprite_prop("res://assets/sprites/door_locked.png", 0.062)
	d_spr.name = "Sprite"
	d_spr.rotation_degrees.y = 90.0   # face east/west along the corridor axis
	d_spr.position.y = 1.5
	door.add_child(d_spr)
	add_child(door)

	# win zone
	var win := Area3D.new()
	win.position = WIN_ZONE
	win.collision_layer = 0
	win.collision_mask = 2
	var wc := CollisionShape3D.new()
	var wshape := BoxShape3D.new()
	wshape.size = Vector3(2.5, 3.0, 8.0)
	wc.shape = wshape
	wc.position.y = 1.5
	win.add_child(wc)
	win.body_entered.connect(_on_win_zone_entered)
	add_child(win)


func _on_win_zone_entered(body: Node3D) -> void:
	if body.is_in_group("player") and not GameState.game_won:
		GameState.win()


# ------------------------------------------------------------------- enemies

func _build_enemies() -> void:
	var EnemyScript := load("res://scripts/sprite_enemy.gd")
	for e in ENEMIES:
		var mob: CharacterBody3D = EnemyScript.new()
		mob.position = Vector3(e[1], 0.05, e[2])
		if e[0] == "crawler":
			mob.sprite_texture = load("res://assets/sprites/crawler.png")
			mob.max_hp = 35
			mob.move_speed = 2.6
			mob.attack_damage = 10
			mob.attack_range = 1.3
			mob.windup_time = 0.3    # fast little thing — shorter tell, less damage
			mob.recover_time = 0.5
			mob.sight_range = 11.0
			mob.sprite_pixel_size = 0.034
		else:
			mob.sprite_texture = load("res://assets/sprites/shambler.png")
			mob.max_hp = 60
			mob.move_speed = 1.5
			mob.attack_damage = 15
			mob.windup_time = 0.6
			mob.recover_time = 0.9
			mob.sight_range = 8.0
			mob.sprite_pixel_size = 0.030
		add_child(mob)


# ------------------------------------------------------------ player and UI

func _build_player() -> void:
	var PlayerScript := load("res://scripts/player.gd")
	var p: CharacterBody3D = PlayerScript.new()
	p.position = PLAYER_SPAWN
	add_child(p)


func _build_hud() -> void:
	var hud: CanvasLayer = load("res://scenes/hud.tscn").instantiate()
	add_child(hud)
