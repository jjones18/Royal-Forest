extends RefCounted

const Assertions = preload("res://tests/support/assertions.gd")
const TUNING := preload("res://game/data/tuning/player_default.tres")

func test_spend_rejects_insufficient_and_accepts_exact(assertions: Assertions, _fixture: RefCounted) -> bool:
	var stats := PlayerStats.new(TUNING)
	assertions.is_true(stats.spend_stamina(100.0))
	assertions.equal(stats.stamina, 0.0)
	assertions.is_false(stats.spend_stamina(0.01))
	return true

func test_recovery_honors_delay_and_full_bar_time(assertions: Assertions, _fixture: RefCounted) -> bool:
	var stats := PlayerStats.new(TUNING)
	stats.spend_stamina(100.0)
	stats.advance(0.35)
	assertions.equal(stats.stamina, 0.0)
	stats.advance(2.75)
	assertions.equal(stats.stamina, 100.0)
	return true

func test_hp_has_no_passive_recovery_and_resets(assertions: Assertions, _fixture: RefCounted) -> bool:
	var stats := PlayerStats.new(TUNING)
	stats.apply_damage(40.0)
	stats.advance(10.0)
	assertions.equal(stats.hp, 60.0)
	stats.reset()
	assertions.equal(stats.hp, 100.0)
	return true

func test_mana_spend_rejects_negative_and_insufficient(assertions: Assertions, _fixture: RefCounted) -> bool:
	var stats := PlayerStats.new(TUNING)
	assertions.equal(stats.mana, 100.0)
	assertions.is_false(stats.spend_mana(-1.0))
	assertions.is_false(stats.spend_mana(100.01))
	assertions.equal(stats.mana, 100.0)
	assertions.is_true(stats.spend_mana(25.0))
	assertions.equal(stats.mana, 75.0)
	return true

func test_mana_regen_delay_rate_and_large_delta_are_deterministic(assertions: Assertions, _fixture: RefCounted) -> bool:
	var stats := PlayerStats.new(TUNING)
	stats.spend_mana(25.0)
	stats.advance(2.0)
	assertions.equal(stats.mana, 75.0)
	stats.advance(1.0)
	assertions.equal(stats.mana, 77.5)
	var single_step := PlayerStats.new(TUNING)
	single_step.spend_mana(25.0)
	single_step.advance(3.0)
	assertions.equal(single_step.mana, stats.mana, "large delta must consume delay then regenerate deterministically")
	return true

func test_damage_resets_mana_delay_and_reset_refills_all(assertions: Assertions, _fixture: RefCounted) -> bool:
	var stats := PlayerStats.new(TUNING)
	stats.spend_mana(25.0)
	stats.advance(1.5)
	stats.apply_damage(10.0)
	stats.advance(2.0)
	assertions.equal(stats.mana, 75.0, "damage must restart the full mana delay")
	stats.advance(1.0)
	assertions.equal(stats.mana, 77.5)
	stats.stamina = 1.0
	stats.reset()
	assertions.equal(stats.mana, 100.0)
	assertions.equal(stats.stamina, 100.0)
	assertions.equal(stats.hp, 100.0)
	return true
