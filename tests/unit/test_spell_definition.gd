extends RefCounted

const Assertions = preload("res://tests/support/assertions.gd")
const SPELL: SpellDefinition = preload("res://game/data/spells/spectral_bolt.tres")

func test_authored_spectral_bolt_values_and_validation(assertions: Assertions, _fixture: RefCounted) -> bool:
	assertions.equal(SPELL.id, &"spell.spectral-bolt")
	assertions.equal(SPELL.mana_cost, 25.0)
	assertions.equal(SPELL.damage, 30.0)
	assertions.equal(SPELL.projectile_speed, 16.0)
	assertions.equal(SPELL.max_range, 24.0)
	assertions.equal(SPELL.projectile_radius, 0.16)
	assertions.is_true(SPELL.is_valid())
	return true

func test_input_map_has_q_and_right_shoulder_cast_bindings(assertions: Assertions, _fixture: RefCounted) -> bool:
	var has_q := false
	var has_right_shoulder := false
	for event in InputMap.action_get_events("cast"):
		if event is InputEventKey and (event as InputEventKey).physical_keycode == KEY_Q:
			has_q = true
		if event is InputEventJoypadButton and (event as InputEventJoypadButton).button_index == 10:
			has_right_shoulder = true
	assertions.is_true(has_q, "cast must bind physical Q")
	assertions.is_true(has_right_shoulder, "cast must bind controller right shoulder button 10")
	return true

func test_malformed_spell_rejects_namespace_and_nonpositive_fields(assertions: Assertions, _fixture: RefCounted) -> bool:
	var malformed := SpellDefinition.new()
	malformed.id = &"enemy.Bad"
	malformed.display_name = "Bad"
	malformed.mana_cost = 0.0
	malformed.damage = -1.0
	malformed.cast_windup_seconds = 0.0
	malformed.projectile_speed = 0.0
	malformed.max_range = 0.0
	malformed.projectile_radius = 0.0
	var errors := malformed.validation_errors()
	assertions.is_true(errors.size() >= 6, "all malformed ranged fields must be rejected")
	return true
