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
