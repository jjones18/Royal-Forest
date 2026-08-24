extends Node
## Global game state — health, inventory, run flow. Autoloaded as `GameState`.

signal hp_changed(hp: int, max_hp: int)
signal mana_changed(mana: float, max_mana: float)
signal message(text: String)
signal hint_changed(text: String)
signal hurt
signal died
signal won

const MAX_HP := 100
const MAX_MANA := 100
const MANA_REGEN := 8.0        # per second
const FIREBALL_COST := 30
const FROST_COST := 20

var hp: int = MAX_HP
var mana: float = MAX_MANA
var has_bow := false
var has_melee := false
var weapon := ""          # id from Weapons.CATALOG; "" = unarmed
var has_key := false
var dead := false
var game_won := false
var _invuln := 0.0


func _process(delta: float) -> void:
	_invuln = maxf(0.0, _invuln - delta)
	if mana < MAX_MANA and not dead:
		mana = minf(mana + MANA_REGEN * delta, float(MAX_MANA))
		mana_changed.emit(mana, MAX_MANA)


## Try to spend mana; returns false (and spends nothing) if short.
func try_spend_mana(cost: float) -> bool:
	if dead or game_won or mana < cost:
		return false
	mana -= cost
	mana_changed.emit(mana, MAX_MANA)
	return true


func reset() -> void:
	hp = MAX_HP
	mana = MAX_MANA
	has_bow = false
	has_melee = false
	weapon = ""
	has_key = false
	dead = false
	game_won = false
	_invuln = 0.0   # don't carry i-frames into a fresh run


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


func give_weapon(id: String) -> void:
	weapon = id
	if Weapons.CATALOG[id]["ranged"]:
		has_bow = true
	else:
		has_melee = true


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
