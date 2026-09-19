extends Node3D
## Wall torch: wooden arm leaning off the wall, flame sprite + flickering
## warm omni light at the tip. Structure is built by main.gd:
##   Torch/Arm/Stick, Torch/Arm/Tip/{Flame, Light}

@export var energy := 1.35
## Kept under half the narrowest wall spacing (~4 m corridors) so the light
## sphere never crosses geometry — no bleed-through into other rooms.
@export var light_range := 4.2
@export var light_attenuation := 2.0

const FLAME_REST_Y := 0.10

var _t := randf() * TAU

@onready var light: OmniLight3D = $Arm/Tip/Light
@onready var flame: Sprite3D = $Arm/Tip/Flame


func _ready() -> void:
	light.light_energy = energy
	light.omni_range = light_range
	light.omni_attenuation = light_attenuation
	# desync each torch so they don't flicker in unison
	_t += global_position.x * 3.1 + global_position.z * 1.7


func _process(delta: float) -> void:
	_t += delta
	var flicker := 1.0 \
			+ 0.10 * sin(_t * 9.0) \
			+ 0.06 * sin(_t * 23.0 + 1.3) \
			+ 0.04 * sin(_t * 41.0)
	light.light_energy = energy * flicker
	# the STICK never moves — only the flame dances like it's burning
	var s := 1.0 + (flicker - 1.0) * 0.6
	flame.scale = Vector3(s, s, s)
	flame.position.y = FLAME_REST_Y \
			+ 0.012 * sin(_t * 11.0) \
			+ 0.008 * sin(_t * 27.0 + 0.7)
	flame.position.x = 0.006 * sin(_t * 17.0 + 2.1)
