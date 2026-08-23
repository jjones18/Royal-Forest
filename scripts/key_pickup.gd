extends Area3D
## Floating key pickup — touch to collect.

@onready var sprite: Sprite3D = $Sprite

var _t := 0.0
var taken := false


func _process(delta: float) -> void:
	_t += delta
	sprite.position.y = 0.9 + sin(_t * 2.2) * 0.08
	sprite.rotate_y(delta * 1.6)


func _on_body_entered(body: Node3D) -> void:
	if taken or not body.is_in_group("player"):
		return
	taken = true
	GameState.give_key()
	GameState.say("A rusted key. Somewhere, a lock waits.")
	queue_free()
