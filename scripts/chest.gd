extends StaticBody3D
## Chest: interact to open. First open grants the sword.
## Built from 3D boxes (base + hinged lid); lid swings open on first use.

@onready var lid_pivot: Node3D = $LidPivot

var opened := false


func interact_hint() -> String:
	return "" if opened else "Open chest"


func interact() -> void:
	if opened:
		return
	opened = true
	GameState.give_sword()
	GameState.say("An old blade, still keen. (Left-click to swing)")
	var tw := create_tween()
	tw.tween_property(lid_pivot, "rotation_degrees:x", -105.0, 0.5)\
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
