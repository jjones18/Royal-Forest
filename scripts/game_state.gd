extends Node
## Global game state — health, inventory, run flow. Autoloaded as `GameState`.

signal hp_changed(hp: int, max_hp: int)
signal message(text: String)
signal hint_changed(text: String)
signal hurt
signal died
signal won

const MAX_HP := 100

var hp: int = MAX_HP
var has_sword := false
var has_key := false
var dead := false
var game_won := false
var _invuln := 0.0


func _process(delta: float) -> void:
	_invuln = maxf(0.0, _invuln - delta)


func reset() -> void:
	hp = MAX_HP
	has_sword = false
	has_key = false
	dead = false
	game_won = false


func take_damage(amount: int) -> void:
	if dead or game_won or _invuln > 0.0:
		return
	_invuln = 0.4
	hp = maxi(hp - amount, 0)
	hp_changed.emit(hp, MAX_HP)
	hurt.emit()
	if hp == 0:
		dead = true
		died.emit()


func give_sword() -> void:
	has_sword = true


func give_key() -> void:
	has_key = true


func say(text: String) -> void:
	message.emit(text)


func set_hint(text: String) -> void:
	hint_changed.emit(text)


func win() -> void:
	if dead or game_won:
		return
	game_won = true
	won.emit()
