extends RefCounted

const Assertions = preload("res://tests/support/assertions.gd")
const HUD := preload("res://game/ui/hud/game_hud_responsive.tscn")

func test_layout_stays_inside_1280x720_and_960x540(assertions: Assertions, fixture: RefCounted) -> bool:
	for viewport_size in [Vector2i(1280, 720), Vector2i(960, 540)]:
		var viewport := SubViewport.new()
		viewport.size = viewport_size
		fixture.add_node(viewport)
		var hud: ResponsiveGameHud = HUD.instantiate()
		viewport.add_child(hud)
		await fixture.process_frames(2)
		for panel: Control in [hud.status_panel, hud.instruction_panel]:
			var rect: Rect2 = panel.get_global_rect()
			assertions.is_true(rect.position.x >= 0.0 and rect.position.y >= 0.0, "panel origin must remain visible at %s" % viewport_size)
			assertions.is_true(rect.end.x <= viewport_size.x and rect.end.y <= viewport_size.y, "panel must not clip at %s" % viewport_size)
		for control in hud.root_control.find_children("*", "Control", true, false):
			assertions.equal(control.mouse_filter, Control.MOUSE_FILTER_IGNORE, "HUD control %s must not intercept gameplay mouse input" % control.name)
		assertions.equal(hud.root_control.mouse_filter, Control.MOUSE_FILTER_IGNORE, "HUD root must not intercept gameplay mouse input")
		assertions.is_true(hud.mana_bar != null, "HUD must include a mana bar")
		var all_text := ""
		for label in hud.root_control.find_children("*", "Label", true, false):
			all_text += (label as Label).text + "\n"
		assertions.is_true(all_text.contains("M2 FIRST PLAYABLE"), "HUD header must identify M2 first playable")
		assertions.is_true(all_text.contains("Q / Right Shoulder: Spectral Bolt"), "HUD instructions must show keyboard/controller cast parity")
		assertions.is_true(all_text.contains("F / D-pad Up: healing vessel"), "HUD instructions must show keyboard/controller heal parity")
		assertions.is_true(all_text.contains("VESSEL 3 / 3"), "HUD must show authored vessel charges")
		viewport.queue_free()
		await fixture.process_frames(1)
	return true


func test_vessel_charge_text_updates_live(assertions: Assertions, fixture: RefCounted) -> bool:
	var viewport := SubViewport.new()
	viewport.size = Vector2i(960, 540)
	fixture.add_node(viewport)
	var player := PlayerController.new()
	viewport.add_child(player)
	var hud: ResponsiveGameHud = HUD.instantiate()
	hud.player = player
	viewport.add_child(hud)
	await fixture.process_frames(2)
	assertions.equal(hud.vessel_label.text, "VESSEL 3 / 3")
	player.vessel.spend_charge()
	await fixture.process_frames(1)
	assertions.equal(hud.vessel_label.text, "VESSEL 2 / 3", "vessel charge HUD must update live")
	return true
