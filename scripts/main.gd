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

# Wall torches: [x, z, yaw_degrees] — yaw aims local -Z into the room,
# the arm then pitches 35 deg off that wall. Positions sit just inside
# each wall's inner surface.
var TORCHES := [
	# room A (walls at x = +/-6)
	[-5.7, 6.0, -90.0], [5.7, 6.0, 90.0],
	[-5.7, 13.0, -90.0], [5.7, 13.0, 90.0],
	# corridor A->B (walls at x = +/-2)
	[-1.75, 3.0, -90.0], [1.75, -2.0, 90.0],
	# room B — side walls clear of the south-wall slab seam
	[-7.7, -6.5, -90.0], [7.7, -6.5, 90.0],
	[-4.0, -15.7, 180.0], [4.0, -15.7, 180.0],
	[7.7, -12.0, 90.0],
	# corridor B->C (inner faces of the z=-12 and z=-8 wall slabs)
	[-10.0, -11.2, 180.0], [-12.0, -8.8, 0.0],
	# room C shrine (walls at x = -22 and x = -14)
	[-21.7, -12.5, -90.0], [-13.7, -12.5, 90.0],
	[-21.7, -7.5, -90.0], [-13.7, -7.5, 90.0],
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
	_build_lights()
	_build_floor()
	for w in WALLS:
		_wall(w[0], w[1], w[2], w[3])
	_build_props()
	_build_torches()
	_build_enemies()
	_build_player()
	_build_hud()


func _build_lights() -> void:
	# soft fill lights from the LIGHTS table — keep energy low so torches
	# stay the primary light source
	for l in LIGHTS:
		var light := OmniLight3D.new()
		light.position = Vector3(l[0], 2.2, l[1])
		light.light_energy = l[2] * 0.7
		light.omni_range = 4.0   # stays inside each room — no through-wall bleed
		light.light_color = Color(0.9, 0.85, 0.8)
		light.shadow_enabled = false   # cheap fill; torches cast the shadows
		add_child(light)


# -------------------------------------------------------------------- torches

func _build_torches() -> void:
	var torch_script := load("res://scripts/torch.gd")
	var flame_tex: Texture2D = load("res://assets/sprites/torch.png")
	var stick_mat := StandardMaterial3D.new()
	stick_mat.albedo_color = Color(0.36, 0.24, 0.12)
	stick_mat.roughness = 1.0
	var band_mat := StandardMaterial3D.new()
	band_mat.albedo_color = Color(0.30, 0.31, 0.34)
	band_mat.metallic = 0.6
	band_mat.roughness = 0.6

	for t in TORCHES:
		var x: float = t[0]
		var z: float = t[1]
		var rot_y: float = deg_to_rad(t[2])

		var torch := Node3D.new()
		torch.set_script(torch_script)
		# origin sits ON the wall surface; arm leans out into the room
		torch.position = Vector3(x, 1.55, z)
		torch.rotation.y = rot_y

		# iron mounting band flat against the wall
		var band := MeshInstance3D.new()
		var bmesh := BoxMesh.new()
		bmesh.size = Vector3(0.14, 0.20, 0.04)
		bmesh.material = band_mat
		band.mesh = bmesh
		band.position = Vector3(0, 0.06, 0.01)
		band.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		torch.add_child(band)

		# wooden arm, pitched 45 degrees off the wall — tip UP and out into
		# the room (negative pitch = toward local -Z = away from the wall)
		var arm := Node3D.new()
		arm.name = "Arm"
		arm.rotation_degrees = Vector3(-45.0, 0, 0)
		torch.add_child(arm)

		var stick := MeshInstance3D.new()
		var smesh := BoxMesh.new()
		smesh.size = Vector3(0.06, 0.60, 0.06)
		smesh.material = stick_mat
		stick.mesh = smesh
		stick.position = Vector3(0, 0.26, 0)
		stick.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF  # no self-shadow smear
		arm.add_child(stick)

		# flame + light live at the arm's tip
		var tip := Node3D.new()
		tip.name = "Tip"
		tip.position = Vector3(0, 0.56, 0)
		arm.add_child(tip)

		var light := OmniLight3D.new()
		light.name = "Light"
		light.light_color = Color(1.0, 0.78, 0.48)   # warm firelight
		light.shadow_enabled = true
		light.position.y = 0.08
		tip.add_child(light)

		var spr := Sprite3D.new()
		spr.name = "Flame"
		spr.texture = flame_tex
		spr.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
		spr.shaded = false            # flames glow — ignore darkness
		spr.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		spr.pixel_size = 0.017
		spr.position.y = 0.10         # flame heart above the stick end
		spr.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		tip.add_child(spr)

		add_child(torch)


# --------------------------------------------------------------- environment

func _build_environment() -> void:
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.01, 0.01, 0.02)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.38, 0.37, 0.44)
	env.ambient_light_energy = 1.05
	env.fog_enabled = true
	env.fog_light_color = Color(0.07, 0.06, 0.09)
	env.fog_density = 0.038
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
	# chest — real 3D geometry: wooden base + hinged lid + iron bands
	var wood_mat := StandardMaterial3D.new()
	wood_mat.albedo_color = Color(0.45, 0.30, 0.16)
	wood_mat.roughness = 1.0
	var wood_dark := StandardMaterial3D.new()
	wood_dark.albedo_color = Color(0.34, 0.22, 0.11)
	wood_dark.roughness = 1.0
	var iron_mat := StandardMaterial3D.new()
	iron_mat.albedo_color = Color(0.42, 0.44, 0.48)
	iron_mat.metallic = 0.7
	iron_mat.roughness = 0.5

	var chest := StaticBody3D.new()
	chest.position = CHEST_POS
	chest.set_script(load("res://scripts/chest.gd"))

	var cs := CollisionShape3D.new()
	var cshape := BoxShape3D.new()
	cshape.size = Vector3(1.0, 0.85, 0.7)
	cs.shape = cshape
	cs.position.y = 0.425
	chest.add_child(cs)

	# base box
	var base_mi := MeshInstance3D.new()
	var base_mesh := BoxMesh.new()
	base_mesh.size = Vector3(1.0, 0.55, 0.7)
	base_mesh.material = wood_mat
	base_mi.mesh = base_mesh
	base_mi.position.y = 0.275
	chest.add_child(base_mi)
	# corner trim (dark verticals)
	for sx in [-0.47, 0.47]:
		for sz in [-0.32, 0.32]:
			var post := MeshInstance3D.new()
			var pmesh := BoxMesh.new()
			pmesh.size = Vector3(0.07, 0.56, 0.07)
			pmesh.material = wood_dark
			post.mesh = pmesh
			post.position = Vector3(sx, 0.28, sz)
			chest.add_child(post)

	# lid on a rear hinge pivot
	var lid_pivot := Node3D.new()
	lid_pivot.name = "LidPivot"
	lid_pivot.position = Vector3(0, 0.55, -0.35)   # back top edge of the base
	chest.add_child(lid_pivot)
	var lid_mi := MeshInstance3D.new()
	var lid_mesh := BoxMesh.new()
	lid_mesh.size = Vector3(1.02, 0.22, 0.72)
	lid_mesh.material = wood_dark
	lid_mi.mesh = lid_mesh
	lid_mi.position = Vector3(0, 0.10, 0.35)       # forward of the hinge
	lid_pivot.add_child(lid_mi)
	var strap := MeshInstance3D.new()
	var strap_mesh := BoxMesh.new()
	strap_mesh.size = Vector3(1.06, 0.24, 0.08)
	strap_mesh.material = iron_mat
	strap.mesh = strap_mesh
	strap.position = Vector3(0, 0.10, 0.35)
	lid_pivot.add_child(strap)

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
