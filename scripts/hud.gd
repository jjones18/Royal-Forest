extends CanvasLayer
## HUD: health bar, hint line, message log, damage vignette, death/win screens.

@onready var hp_bar: ColorRect = $Root/HpBack/HpFill
@onready var hp_label: Label = $Root/HpLabel
@onready var hint_label: Label = $Root/Hint
@onready var msg_label: Label = $Root/Message
@onready var vignette: ColorRect = $Root/Vignette
@onready var death_panel: ColorRect = $Root/DeathPanel
@onready var win_panel: ColorRect = $Root/WinPanel

var _msg_t := 0.0


func _ready() -> void:
	GameState.hp_changed.connect(_on_hp_changed)
	GameState.message.connect(_on_message)
	GameState.hint_changed.connect(_on_hint)
	GameState.hurt.connect(_flash_vignette)
	GameState.died.connect(_on_died)
	GameState.won.connect(_on_won)
	_on_hp_changed(GameState.hp, GameState.MAX_HP)
	death_panel.visible = false
	win_panel.visible = false


func _process(delta: float) -> void:
	if _msg_t > 0.0:
		_msg_t -= delta
		if _msg_t <= 0.0:
			msg_label.text = ""
	vignette.modulate.a = maxf(vignette.modulate.a - delta * 1.5, 0.0)


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("restart") and (GameState.dead or GameState.game_won):
		get_tree().reload_current_scene()
		GameState.reset()


func _on_hp_changed(hp: int, max_hp: int) -> void:
	hp_bar.size.x = 300.0 * float(hp) / float(max_hp)
	hp_label.text = "HP %d / %d" % [hp, max_hp]


func _on_message(text: String) -> void:
	msg_label.text = text
	_msg_t = 3.5 if text != "" else 0.0


func _on_hint(text: String) -> void:
	hint_label.text = text


func _flash_vignette() -> void:
	vignette.modulate.a = 0.85


func _on_died() -> void:
	msg_label.text = ""
	hint_label.text = ""
	death_panel.visible = true


func _on_won() -> void:
	win_panel.visible = true
