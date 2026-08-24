extends StaticBody3D
## Locked door: needs the key. Opens (slides up + fades) when unlocked.

@onready var sprite: Sprite3D = $Sprite

var opened := false


func interact_hint() -> String:
	if opened:
		return ""
	return "Locked — a keyhole" if not GameState.has_key else "Unlock door"


func interact() -> void:
	if opened:
		return
	if GameState.has_key:
		opened = true
		GameState.say("The lock gives way.")
		# visuals slide up; collision drops immediately so the opening door
		# can't sweep a player standing in the doorway
		set_deferred("collision_layer", 0)
		for c in get_children():
			if c is CollisionShape3D:
				c.set_deferred("disabled", true)
		var tw := create_tween()
		tw.tween_property(self, "position:y", position.y + 2.6, 1.2)\
				.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
		tw.parallel().tween_property(sprite, "modulate:a", 0.0, 1.2)
		tw.tween_callback(queue_free)
	else:
		GameState.say("Locked fast. There must be a key.")


func _update_hint() -> void:
	pass  # hint text is pulled fresh via interact_hint() each frame
