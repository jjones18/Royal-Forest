class_name ResponsiveGameHud
extends CanvasLayer

const TUNING: PlayerTuning = preload("res://game/data/tuning/player_default.tres")

var player: PlayerController
var hp_bar: ProgressBar
var stamina_bar: ProgressBar
var mana_bar: ProgressBar
var state_label: Label
var guard_label: Label
var feedback_label: Label
var feedback_remaining := 0.0
var root_control: Control
var status_panel: PanelContainer
var instruction_panel: PanelContainer


func _ready() -> void:
	root_control = Control.new()
	root_control.name = "SafeLayout"
	root_control.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(root_control)

	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 20)
	margin.add_theme_constant_override("margin_top", 20)
	margin.add_theme_constant_override("margin_right", 20)
	margin.add_theme_constant_override("margin_bottom", 20)
	root_control.add_child(margin)

	var vertical := VBoxContainer.new()
	vertical.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vertical.size_flags_vertical = Control.SIZE_EXPAND_FILL
	margin.add_child(vertical)

	var top_row := HBoxContainer.new()
	top_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vertical.add_child(top_row)
	status_panel = _build_status_panel()
	top_row.add_child(status_panel)
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top_row.add_child(spacer)
	instruction_panel = _build_instruction_panel()
	top_row.add_child(instruction_panel)
	var vertical_spacer := Control.new()
	vertical_spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vertical.add_child(vertical_spacer)
	state_label = _label("ACTION: FREE")
	vertical.add_child(state_label)

	var crosshair := Label.new()
	crosshair.text = "+"
	crosshair.add_theme_font_size_override("font_size", 24)
	crosshair.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	crosshair.position -= Vector2(9, 16)
	root_control.add_child(crosshair)

	feedback_label = Label.new()
	feedback_label.set_anchors_preset(Control.PRESET_CENTER)
	feedback_label.position = Vector2(-210, 42)
	feedback_label.size = Vector2(420, 54)
	feedback_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	feedback_label.add_theme_font_size_override("font_size", 28)
	feedback_label.add_theme_color_override("font_outline_color", Color(0.02, 0.02, 0.02))
	feedback_label.add_theme_constant_override("outline_size", 7)
	feedback_label.visible = false
	root_control.add_child(feedback_label)

	guard_label = Label.new()
	guard_label.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	guard_label.position = Vector2(-230, -70)
	guard_label.size = Vector2(460, 42)
	guard_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	guard_label.add_theme_font_size_override("font_size", 18)
	guard_label.add_theme_color_override("font_color", Color(0.72, 0.9, 1.0))
	root_control.add_child(guard_label)

	_set_mouse_passthrough(root_control)
	if player != null:
		player.combat_feedback.connect(_on_combat_feedback)


func _process(delta: float) -> void:
	if player == null:
		return
	hp_bar.value = player.stats.hp
	stamina_bar.value = player.stats.stamina
	mana_bar.value = player.stats.mana
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


func _build_status_panel() -> PanelContainer:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(330, 148)
	var rows := VBoxContainer.new()
	rows.add_child(_label("ROYAL FOREST — M2 FIRST PLAYABLE"))
	var hp := _resource_row("HP", Color(0.72, 0.12, 0.1))
	hp_bar = hp["bar"]
	rows.add_child(hp["row"])
	var stamina := _resource_row("STAMINA", Color(0.2, 0.68, 0.3))
	stamina_bar = stamina["bar"]
	rows.add_child(stamina["row"])
	var mana := _resource_row("MANA", Color(0.2, 0.45, 0.9))
	mana_bar = mana["bar"]
	rows.add_child(mana["row"])
	panel.add_child(rows)
	return panel


func _build_instruction_panel() -> PanelContainer:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(410, 122)
	var label := _label("WASD / Left Stick: move  •  Mouse / Right Stick: look\nLMB / RT: attack  •  Q / Right Shoulder: Spectral Bolt\nSpace / A: dodge  •  RMB / LT: guard  •  R / Y: reset")
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_color_override("font_color", Color(0.95, 0.9, 0.7))
	panel.add_child(label)
	return panel


func _resource_row(label_text: String, color: Color) -> Dictionary:
	var row := HBoxContainer.new()
	var label := _label(label_text)
	label.custom_minimum_size.x = 76
	row.add_child(label)
	var bar := ProgressBar.new()
	bar.custom_minimum_size = Vector2(225, 22)
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
	row.add_child(bar)
	return {"row": row, "bar": bar}


func _set_mouse_passthrough(node: Node) -> void:
	if node is Control:
		(node as Control).mouse_filter = Control.MOUSE_FILTER_IGNORE
	for child in node.get_children():
		_set_mouse_passthrough(child)


func _label(text_value: String) -> Label:
	var label := Label.new()
	label.text = text_value
	return label
