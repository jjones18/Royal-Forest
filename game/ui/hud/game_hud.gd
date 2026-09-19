class_name GameHud
extends CanvasLayer

const TUNING: PlayerTuning = preload("res://game/data/tuning/player_default.tres")

var hp_bar: ProgressBar
var stamina_bar: ProgressBar
var state_label: Label
var guard_label: Label
var feedback_label: Label
var feedback_remaining := 0.0
var message_label: Label
var player: PlayerController

func _ready() -> void:
	var panel := ColorRect.new()
	panel.color = Color(0.03, 0.04, 0.03, 0.82)
	panel.position = Vector2(22, 20)
	panel.size = Vector2(330, 122)
	add_child(panel)
	var title := Label.new()
	title.text = "ROYAL FOREST — M1 COMBAT PROOF"
	title.position = Vector2(34, 28)
	add_child(title)
	hp_bar = _bar("HP", Vector2(34, 58), Color(0.72, 0.12, 0.1))
	stamina_bar = _bar("STAMINA", Vector2(34, 91), Color(0.2, 0.68, 0.3))
	state_label = Label.new()
	state_label.position = Vector2(22, 154)
	add_child(state_label)
	guard_label = Label.new()
	guard_label.position = Vector2(455, 620)
	guard_label.size = Vector2(370, 48)
	guard_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	guard_label.add_theme_font_size_override("font_size", 18)
	guard_label.add_theme_color_override("font_color", Color(0.72, 0.9, 1.0))
	add_child(guard_label)
	feedback_label = Label.new()
	feedback_label.position = Vector2(430, 400)
	feedback_label.size = Vector2(420, 54)
	feedback_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	feedback_label.add_theme_font_size_override("font_size", 28)
	feedback_label.add_theme_color_override("font_outline_color", Color(0.02, 0.02, 0.02))
	feedback_label.add_theme_constant_override("outline_size", 7)
	add_child(feedback_label)
	if player != null:
		player.combat_feedback.connect(_on_combat_feedback)
	message_label = Label.new()
	message_label.text = "WASD / Left Stick: move  •  Mouse / Right Stick: look\nLMB / RT: attack  •  Space / A: dodge\nRMB / LT: guard  •  R / Y: reset"
	message_label.position = Vector2(816, 36)
	message_label.size = Vector2(438, 70)
	message_label.add_theme_color_override("font_color", Color(0.95, 0.9, 0.7))
	var instruction_panel := ColorRect.new()
	instruction_panel.color = Color(0.02, 0.025, 0.02, 0.82)
	instruction_panel.position = Vector2(802, 20)
	instruction_panel.size = Vector2(466, 102)
	add_child(instruction_panel)
	add_child(message_label)
	var crosshair := Label.new()
	crosshair.text = "+"
	crosshair.position = Vector2(636, 346)
	crosshair.add_theme_font_size_override("font_size", 24)
	add_child(crosshair)

func _process(delta: float) -> void:
	if player == null: return
	hp_bar.value = player.stats.hp
	stamina_bar.value = player.stats.stamina
	state_label.text = "ACTION: %s%s" % [PlayerActionMachine.Phase.keys()[player.actions.phase], (" — " + player.actions.blocked_reason) if not player.actions.blocked_reason.is_empty() else ""]
	guard_label.text = "SHIELD RAISED  •  %.0f%% BLOCK  •  CHIP DAMAGE" % (TUNING.guard_damage_reduction * 100.0) if player.actions.phase == PlayerActionMachine.Phase.GUARD else ""
	if feedback_remaining > 0.0:
		feedback_remaining = maxf(0.0, feedback_remaining - delta)
		feedback_label.visible = feedback_remaining > 0.0

func _on_combat_feedback(kind: StringName, text: String) -> void:
	feedback_label.text = text
	feedback_label.visible = true
	feedback_remaining = TUNING.hit_confirm_seconds if kind == &"hit" else TUNING.damage_feedback_seconds
	match kind:
		&"hit": feedback_label.add_theme_color_override("font_color", Color(1.0, 0.9, 0.35))
		&"blocked": feedback_label.add_theme_color_override("font_color", Color(0.45, 0.85, 1.0))
		&"guard_broken": feedback_label.add_theme_color_override("font_color", Color(1.0, 0.35, 0.1))
		_: feedback_label.add_theme_color_override("font_color", Color(1.0, 0.2, 0.15))

func _bar(label_text: String, position_value: Vector2, color: Color) -> ProgressBar:
	var label := Label.new()
	label.text = label_text
	label.position = position_value
	label.size = Vector2(75, 24)
	add_child(label)
	var bar := ProgressBar.new()
	bar.position = position_value + Vector2(76, 0)
	bar.size = Vector2(225, 22)
	bar.max_value = 100.0
	bar.value = 100.0
	bar.show_percentage = false
	var fill := StyleBoxFlat.new()
	fill.bg_color = color
	bar.add_theme_stylebox_override("fill", fill)
	var background := StyleBoxFlat.new()
	background.bg_color = Color(0.13, 0.15, 0.13, 1.0)
	background.border_color = Color(0.78, 0.82, 0.74, 1.0)
	background.set_border_width_all(2)
	bar.add_theme_stylebox_override("background", background)
	add_child(bar)
	return bar
