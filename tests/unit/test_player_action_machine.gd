extends RefCounted

const Assertions = preload("res://tests/support/assertions.gd")
const TUNING := preload("res://game/data/tuning/player_default.tres")

func _machine() -> PlayerActionMachine:
	return PlayerActionMachine.new(PlayerStats.new(TUNING), TUNING)

func test_attack_boundaries_and_commitment(assertions: Assertions, _fixture: RefCounted) -> bool:
	var machine := _machine()
	assertions.is_true(machine.request(PlayerActionRequest.new(PlayerActionRequest.Kind.ATTACK)))
	assertions.equal(machine.stats.stamina, 75.0, "attack must spend shared stamina")
	assertions.equal(machine.phase, PlayerActionMachine.Phase.ATTACK_WINDUP)
	assertions.is_false(machine.request(PlayerActionRequest.new(PlayerActionRequest.Kind.DODGE)))
	machine.advance(TUNING.attack_windup_seconds - 0.001)
	assertions.is_false(machine.consume_attack_hit())
	machine.advance(0.001)
	assertions.equal(machine.phase, PlayerActionMachine.Phase.ATTACK_ACTIVE)
	assertions.is_true(machine.consume_attack_hit())
	assertions.is_false(machine.consume_attack_hit())
	return true

func test_insufficient_stamina_reports_reason(assertions: Assertions, _fixture: RefCounted) -> bool:
	var machine := _machine()
	machine.stats.stamina = TUNING.dodge_stamina_cost - 0.01
	assertions.is_false(machine.request(PlayerActionRequest.new(PlayerActionRequest.Kind.DODGE)))
	assertions.equal(machine.blocked_reason, "insufficient stamina")
	return true

func test_dodge_iframe_recovery_and_non_chain(assertions: Assertions, _fixture: RefCounted) -> bool:
	var machine := _machine()
	assertions.is_true(machine.request(PlayerActionRequest.new(PlayerActionRequest.Kind.DODGE, Vector2.RIGHT)))
	assertions.equal(machine.dodge_speed() * TUNING.dodge_move_seconds, TUNING.dodge_distance, "dodge motion must cover configured distance")
	assertions.is_true(machine.is_invulnerable())
	assertions.is_false(machine.request(PlayerActionRequest.new(PlayerActionRequest.Kind.DODGE)))
	machine.advance(TUNING.dodge_iframe_seconds)
	assertions.is_false(machine.is_invulnerable())
	assertions.equal(machine.phase, PlayerActionMachine.Phase.DODGE)
	machine.advance(TUNING.dodge_total_recovery_seconds - TUNING.dodge_iframe_seconds)
	assertions.equal(machine.phase, PlayerActionMachine.Phase.FREE)
	return true

func test_guard_requires_shield_drains_and_breaks(assertions: Assertions, _fixture: RefCounted) -> bool:
	var machine := _machine()
	machine.has_shield = false
	assertions.is_false(machine.request(PlayerActionRequest.new(PlayerActionRequest.Kind.GUARD_START)))
	assertions.equal(machine.blocked_reason, "shield required")
	machine.has_shield = true
	machine.stats.stamina = 5.0
	assertions.is_true(machine.request(PlayerActionRequest.new(PlayerActionRequest.Kind.GUARD_START)))
	machine.advance(0.5)
	assertions.equal(machine.phase, PlayerActionMachine.Phase.GUARD_BROKEN)
	assertions.equal(machine.stats.stamina, 0.0)
	return true

func test_guard_hit_reduces_damage_spends_stamina_and_breaks(assertions: Assertions, _fixture: RefCounted) -> bool:
	var machine := _machine()
	machine.stats.stamina = TUNING.guard_impact_stamina_cost + 5.0
	assertions.is_true(machine.request(PlayerActionRequest.new(PlayerActionRequest.Kind.GUARD_START)))
	var applied := machine.receive_damage(20.0)
	assertions.is_true(is_equal_approx(applied, 4.0), "guard must reduce incoming damage by 80 percent")
	assertions.equal(machine.stats.stamina, 5.0, "guard impact must spend shared stamina")
	assertions.equal(machine.phase, PlayerActionMachine.Phase.GUARD)
	machine.receive_damage(20.0)
	assertions.equal(machine.stats.stamina, 0.0)
	assertions.equal(machine.phase, PlayerActionMachine.Phase.GUARD_BROKEN)
	return true

func test_buffer_near_recovery_runs_after_commitment(assertions: Assertions, _fixture: RefCounted) -> bool:
	var machine := _machine()
	machine.request(PlayerActionRequest.new(PlayerActionRequest.Kind.ATTACK))
	machine.advance(TUNING.attack_windup_seconds + TUNING.attack_active_seconds + TUNING.attack_recovery_seconds - 0.1)
	assertions.equal(machine.phase, PlayerActionMachine.Phase.ATTACK_RECOVERY)
	assertions.is_true(machine.request(PlayerActionRequest.new(PlayerActionRequest.Kind.ATTACK)))
	machine.advance(0.1)
	assertions.equal(machine.phase, PlayerActionMachine.Phase.ATTACK_WINDUP)
	assertions.equal(machine.stats.stamina, 50.0)
	return true

func test_large_delta_walks_attack_phases_deterministically(assertions: Assertions, _fixture: RefCounted) -> bool:
	var machine := _machine()
	machine.request(PlayerActionRequest.new(PlayerActionRequest.Kind.ATTACK))
	machine.advance(TUNING.attack_windup_seconds + TUNING.attack_active_seconds + TUNING.attack_recovery_seconds)
	assertions.equal(machine.phase, PlayerActionMachine.Phase.FREE)
	return true
