extends StaticBody3D
## Chest: interact to open. Grants a weapon — weighted random roll
## (see Weapons.CATALOG for the chances). Lid swings open on first use.

@onready var lid_pivot: Node3D = $LidPivot

var opened := false


func interact_hint() -> String:
	return "" if opened else "Open chest"


func interact() -> void:
	if opened:
		return
	opened = true
	var weapon_id: String = Weapons.roll()
	GameState.give_weapon(weapon_id)
	var info: Dictionary = Weapons.CATALOG[weapon_id]
	GameState.say(info["pickup_text"])
	var tw := create_tween()
	tw.tween_property(lid_pivot, "rotation_degrees:x", -105.0, 0.5) \
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
