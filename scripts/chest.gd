extends StaticBody3D
## Chest: interact to open. First open grants the sword.

@onready var sprite: Sprite3D = $Sprite

var opened := false


func interact_hint() -> String:
	return "" if opened else "Open chest"


func interact() -> void:
	if opened:
		return
	opened = true
	sprite.texture = load("res://assets/sprites/chest_open.png")
	GameState.give_sword()
	GameState.say("An old blade, still keen. (Left-click to swing)")
