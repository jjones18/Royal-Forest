extends Node3D
## Wall torch: wooden arm leaning off the wall, flame sprite + flickering
## warm omni light at the tip. Structure is built by main.gd:
##   Torch/Arm/Stick, Torch/Arm/Tip/{Flame, Light}

@export var energy := 1.35
@export var light_range := 7.0

var _t := randf() * TAU

@onready var light: OmniLight3D = $Arm/Tip/Light
@onready var flame: Sprite3D = $Arm/Tip/Flame


func _ready() -> void:
	light.light_energy = energy
	light.omni_range = light_range
	# desync each torch so they don't flicker in unison
	_t += global_position.x * 3.1 + global_position.z * 1.7


func _process(delta: float) -> void:
	_t += delta
	var flicker := 1.0 \
			+ 0.10 * sin(_t * 9.0) \
			+ 0.06 * sin(_t * 23.0 + 1.3) \
			+ 0.04 * sin(_t * 41.0)
	light.light_energy = energy * flicker
	var s := 1.0 + (flicker - 1.0) * 0.5
	flame.scale = Vector3(s, s, s)
	# gentle sway of the whole arm, like wind through the dungeon
	var arm: Node3D = $Arm
	arm.rotation.z = 0.03 * sin(_t * 5.0)
