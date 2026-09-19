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
	var affordable := _machine()
	affordable.stats.stamina = TUNING.dodge_stamina_cost - 0.000005
	assertions.is_true(affordable.request(PlayerActionRequest.new(PlayerActionRequest.Kind.DODGE)), "shared epsilon boundary must allow dodge commitment")
	assertions.equal(affordable.phase, PlayerActionMachine.Phase.DODGE)
	assertions.equal(affordable.stats.stamina, 0.0)

	var insufficient := _machine()
	insufficient.stats.stamina = TUNING.dodge_stamina_cost - 0.01
	var stamina_before := insufficient.stats.stamina
	assertions.is_false(insufficient.request(PlayerActionRequest.new(PlayerActionRequest.Kind.DODGE)))
	assertions.equal(insufficient.blocked_reason, "insufficient stamina")
	assertions.equal(insufficient.stats.stamina, stamina_before, "rejected dodge must not spend stamina")
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

func test_first_buffered_dodge_preserves_requested_direction(assertions: Assertions, _fixture: RefCounted) -> bool:
	var machine := _machine()
	machine.request(PlayerActionRequest.new(PlayerActionRequest.Kind.ATTACK))
	var attack_total := TUNING.attack_windup_seconds + TUNING.attack_active_seconds + TUNING.attack_recovery_seconds
	machine.advance(attack_total - 0.1)
	assertions.is_true(machine.request(PlayerActionRequest.new(PlayerActionRequest.Kind.DODGE, Vector2.RIGHT)))
	machine.advance(0.1)
	assertions.equal(machine.phase, PlayerActionMachine.Phase.DODGE)
	assertions.is_true(machine.dodge_direction.is_equal_approx(Vector2.RIGHT), "M2B1_BUFFERED_DODGE_DIRECTION: first buffered dodge must retain requested direction")
	return true


func test_buffered_dodge_replaces_stale_previous_direction(assertions: Assertions, _fixture: RefCounted) -> bool:
	var machine := _machine()
	machine.request(PlayerActionRequest.new(PlayerActionRequest.Kind.DODGE, Vector2.LEFT))
	machine.advance(TUNING.dodge_total_recovery_seconds - 0.1)
	assertions.equal(machine.phase, PlayerActionMachine.Phase.DODGE)
	assertions.is_true(machine.request(PlayerActionRequest.new(PlayerActionRequest.Kind.DODGE, Vector2.RIGHT)))
	machine.advance(0.1)
	assertions.equal(machine.phase, PlayerActionMachine.Phase.DODGE)
	assertions.is_true(machine.dodge_direction.is_equal_approx(Vector2.RIGHT), "M2B1_BUFFERED_DODGE_DIRECTION: buffered dodge must replace stale prior direction")
	return true


func test_large_delta_walks_attack_phases_deterministically(assertions: Assertions, _fixture: RefCounted) -> bool:
	var machine := _machine()
	machine.request(PlayerActionRequest.new(PlayerActionRequest.Kind.ATTACK))
	machine.advance(TUNING.attack_windup_seconds + TUNING.attack_active_seconds + TUNING.attack_recovery_seconds)
	assertions.equal(machine.phase, PlayerActionMachine.Phase.FREE)
	return true

func test_cast_spends_on_accept_and_releases_once_at_active(assertions: Assertions, _fixture: RefCounted) -> bool:
	var machine := _machine()
	var spell := machine.spell
	assertions.is_true(machine.request(PlayerActionRequest.new(PlayerActionRequest.Kind.CAST)))
	assertions.equal(machine.stats.mana, 100.0 - spell.mana_cost)
	assertions.equal(machine.phase, PlayerActionMachine.Phase.CAST_WINDUP)
	assertions.is_false(machine.consume_cast_release())
	machine.advance(spell.cast_windup_seconds)
	assertions.equal(machine.phase, PlayerActionMachine.Phase.CAST_ACTIVE)
	assertions.is_true(machine.consume_cast_release())
	assertions.is_false(machine.consume_cast_release(), "cast release must be available exactly once")
	machine.advance(spell.cast_active_seconds)
	assertions.equal(machine.phase, PlayerActionMachine.Phase.CAST_RECOVERY)
	machine.advance(spell.cast_recovery_seconds)
	assertions.equal(machine.phase, PlayerActionMachine.Phase.FREE)
	return true

func test_large_delta_preserves_cast_release_event(assertions: Assertions, _fixture: RefCounted) -> bool:
	var machine := _machine()
	var spell := machine.spell
	assertions.is_true(machine.request(PlayerActionRequest.new(PlayerActionRequest.Kind.CAST)))
	machine.advance(spell.cast_windup_seconds + spell.cast_active_seconds + spell.cast_recovery_seconds)
	assertions.equal(machine.phase, PlayerActionMachine.Phase.FREE)
	assertions.is_true(machine.consume_cast_release(), "a single large frame must not drop the cast release event")
	assertions.is_false(machine.consume_cast_release(), "preserved release event must still be consumed exactly once")
	return true

func test_interruption_clears_pending_attack_and_cast_events(assertions: Assertions, _fixture: RefCounted) -> bool:
	var attack_machine := _machine()
	attack_machine.request(PlayerActionRequest.new(PlayerActionRequest.Kind.ATTACK))
	attack_machine.advance(TUNING.attack_windup_seconds)
	assertions.equal(attack_machine.phase, PlayerActionMachine.Phase.ATTACK_ACTIVE)
	attack_machine.receive_damage(1.0)
	assertions.equal(attack_machine.phase, PlayerActionMachine.Phase.HURT)
	assertions.is_false(attack_machine.consume_attack_hit(), "interrupted attack must not retain a deferred hit")
	var cast_machine := _machine()
	cast_machine.request(PlayerActionRequest.new(PlayerActionRequest.Kind.CAST))
	cast_machine.advance(cast_machine.spell.cast_windup_seconds)
	assertions.equal(cast_machine.phase, PlayerActionMachine.Phase.CAST_ACTIVE)
	cast_machine.receive_damage(1.0)
	assertions.equal(cast_machine.phase, PlayerActionMachine.Phase.HURT)
	assertions.is_false(cast_machine.consume_cast_release(), "interrupted cast must not retain a deferred release")
	return true

func test_cast_rejects_insufficient_mana_before_commitment(assertions: Assertions, _fixture: RefCounted) -> bool:
	var machine := _machine()
	machine.stats.mana = machine.spell.mana_cost - 0.01
	assertions.is_false(machine.request(PlayerActionRequest.new(PlayerActionRequest.Kind.CAST)))
	assertions.equal(machine.phase, PlayerActionMachine.Phase.FREE)
	assertions.equal(machine.blocked_reason, "insufficient mana")
	return true

func test_cast_is_blocked_during_dodge(assertions: Assertions, _fixture: RefCounted) -> bool:
	var machine := _machine()
	machine.request(PlayerActionRequest.new(PlayerActionRequest.Kind.DODGE))
	var mana_before := machine.stats.mana
	assertions.is_false(machine.request(PlayerActionRequest.new(PlayerActionRequest.Kind.CAST)), "cast must be blocked during DODGE commitment")
	assertions.equal(machine.stats.mana, mana_before, "dodge-blocked cast must not spend mana")
	return true

func test_cast_is_blocked_during_other_commitments(assertions: Assertions, _fixture: RefCounted) -> bool:
	var cases: Array[PlayerActionMachine] = []
	var attacking := _machine()
	attacking.request(PlayerActionRequest.new(PlayerActionRequest.Kind.ATTACK))
	cases.append(attacking)
	var guarding := _machine()
	guarding.request(PlayerActionRequest.new(PlayerActionRequest.Kind.GUARD_START))
	cases.append(guarding)
	var hurt := _machine()
	hurt.receive_damage(1.0)
	cases.append(hurt)
	var dead := _machine()
	dead.receive_damage(1000.0)
	cases.append(dead)
	for machine in cases:
		var mana_before := machine.stats.mana
		assertions.is_false(machine.request(PlayerActionRequest.new(PlayerActionRequest.Kind.CAST)), "cast must be blocked during %s" % PlayerActionMachine.Phase.keys()[machine.phase])
		assertions.equal(machine.stats.mana, mana_before, "blocked cast must not spend mana")
	return true

func test_cast_buffers_only_in_last_recovery_window(assertions: Assertions, _fixture: RefCounted) -> bool:
	var machine := _machine()
	machine.request(PlayerActionRequest.new(PlayerActionRequest.Kind.ATTACK))
	machine.advance(TUNING.attack_windup_seconds + TUNING.attack_active_seconds + TUNING.attack_recovery_seconds - 0.1)
	assertions.is_true(machine.request(PlayerActionRequest.new(PlayerActionRequest.Kind.CAST)))
	assertions.equal(machine.stats.mana, 100.0, "buffering must defer spend until commitment starts")
	machine.advance(0.1)
	assertions.equal(machine.phase, PlayerActionMachine.Phase.CAST_WINDUP)
	assertions.equal(machine.stats.mana, 75.0)
	return true

func test_buffered_cast_fails_closed_if_mana_is_gone_at_commitment(assertions: Assertions, _fixture: RefCounted) -> bool:
	var machine := _machine()
	machine.request(PlayerActionRequest.new(PlayerActionRequest.Kind.ATTACK))
	machine.advance(TUNING.attack_windup_seconds + TUNING.attack_active_seconds + TUNING.attack_recovery_seconds - 0.1)
	assertions.is_true(machine.request(PlayerActionRequest.new(PlayerActionRequest.Kind.CAST)))
	machine.stats.mana = 0.0
	machine.advance(0.1)
	assertions.equal(machine.phase, PlayerActionMachine.Phase.FREE, "buffered cast without mana must remain uncommitted")
	assertions.equal(machine.blocked_reason, "insufficient mana")
	assertions.is_false(machine.consume_cast_release())
	return true
