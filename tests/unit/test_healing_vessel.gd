extends RefCounted

const Assertions = preload("res://tests/support/assertions.gd")
const PLAYGROUND := preload("res://game/world/combat_playground.tscn")
const TUNING: PlayerTuning = preload("res://game/data/tuning/player_default.tres")


func _machine(stats: PlayerStats = null, vessel: HealingVessel = null) -> PlayerActionMachine:
	var source_stats := stats if stats != null else PlayerStats.new(TUNING)
	var source_vessel := vessel if vessel != null else HealingVessel.new()
	return PlayerActionMachine.new(source_stats, TUNING, null, source_vessel)


func test_vessel_authored_values_spend_refill_and_scaling(assertions: Assertions, _fixture: RefCounted) -> bool:
	var vessel := HealingVessel.new()
	assertions.equal(vessel.max_charges, 3, "M2B_MAX_CHARGES_EXACT: vessel must start with exactly three maximum charges")
	assertions.equal(HealingVessel.HEAL_FRACTION, 0.40, "vessel must restore the authored max-HP fraction")
	assertions.equal(HealingVessel.HEAL_WINDUP, 0.80, "vessel windup must match the authored provisional timing")
	assertions.equal(HealingVessel.HEAL_ACTIVE, 0.08, "vessel active window must match the authored provisional timing")
	assertions.equal(HealingVessel.HEAL_RECOVERY, 0.52, "vessel recovery must match the authored provisional timing")
	assertions.equal(vessel.charges, 3, "vessel must start full")
	assertions.is_true(vessel.spend_charge())
	assertions.is_true(vessel.spend_charge())
	assertions.is_true(vessel.spend_charge())
	assertions.equal(vessel.charges, 0)
	assertions.is_false(vessel.spend_charge(), "empty vessel must reject spending")
	vessel.refill()
	assertions.equal(vessel.charges, 3, "refill API must restore all charges")
	assertions.equal(vessel.heal_amount(100.0), 40.0)
	assertions.equal(vessel.heal_amount(200.0), 80.0)
	assertions.equal(vessel.heal_amount(-100.0), 0.0, "heal scaling must reject negative max HP")
	return true


func test_heal_rejects_full_health_and_starts_damaged_with_spend(assertions: Assertions, _fixture: RefCounted) -> bool:
	var machine := _machine()
	assertions.is_false(machine.request(PlayerActionRequest.new(PlayerActionRequest.Kind.HEAL)))
	assertions.equal(machine.blocked_reason, "full health")
	assertions.equal(machine.vessel.charges, 3, "rejected full-health request must not spend")
	machine.stats.hp = 50.0
	assertions.is_true(machine.request(PlayerActionRequest.new(PlayerActionRequest.Kind.HEAL)))
	assertions.equal(machine.phase, PlayerActionMachine.Phase.HEAL_WINDUP)
	assertions.equal(machine.vessel.charges, 2, "accepted heal must spend at commitment start")
	return true


func test_heal_frame_exact_once_and_large_delta_persistence(assertions: Assertions, _fixture: RefCounted) -> bool:
	var machine := _machine()
	machine.stats.hp = 10.0
	machine.request(PlayerActionRequest.new(PlayerActionRequest.Kind.HEAL))
	machine.advance(HealingVessel.HEAL_WINDUP - 0.001)
	assertions.is_false(machine.consume_heal_tick(), "M2B_EXACT_HEAL_FRAME: heal must not release during windup")
	machine.advance(0.001)
	assertions.equal(machine.phase, PlayerActionMachine.Phase.HEAL_ACTIVE)
	assertions.is_true(machine.consume_heal_tick(), "heal tick must become available at active entry")
	assertions.is_false(machine.consume_heal_tick(), "heal tick must be consumable exactly once")

	var large_delta := _machine()
	large_delta.stats.hp = 10.0
	large_delta.request(PlayerActionRequest.new(PlayerActionRequest.Kind.HEAL))
	large_delta.advance(HealingVessel.HEAL_WINDUP + HealingVessel.HEAL_ACTIVE + HealingVessel.HEAL_RECOVERY)
	assertions.equal(large_delta.phase, PlayerActionMachine.Phase.FREE)
	assertions.is_true(large_delta.consume_heal_tick(), "large delta must preserve the heal event until consumed")
	assertions.is_false(large_delta.consume_heal_tick())
	return true


func test_heal_commitment_and_final_buffer_defer_spend(assertions: Assertions, _fixture: RefCounted) -> bool:
	var machine := _machine()
	machine.stats.hp = 20.0
	machine.request(PlayerActionRequest.new(PlayerActionRequest.Kind.HEAL))
	assertions.is_false(machine.request(PlayerActionRequest.new(PlayerActionRequest.Kind.ATTACK)), "heal windup must block attack")
	machine.advance(HealingVessel.HEAL_WINDUP)
	assertions.is_false(machine.request(PlayerActionRequest.new(PlayerActionRequest.Kind.DODGE)), "heal active must block dodge")
	machine.advance(HealingVessel.HEAL_ACTIVE)
	assertions.is_false(machine.request(PlayerActionRequest.new(PlayerActionRequest.Kind.CAST)), "early heal recovery must block cast")
	machine.advance(HealingVessel.HEAL_RECOVERY - 0.10)
	assertions.is_true(machine.request(PlayerActionRequest.new(PlayerActionRequest.Kind.HEAL)), "final 0.15 seconds must accept a buffered heal")
	assertions.equal(machine.vessel.charges, 2, "buffering must defer the second charge spend")
	machine.advance(0.10)
	assertions.equal(machine.phase, PlayerActionMachine.Phase.HEAL_WINDUP)
	assertions.equal(machine.vessel.charges, 1, "buffered heal spends only when its commitment starts")
	return true


func test_heal_start_is_blocked_during_other_commitments_guard_hurt_and_death(assertions: Assertions, _fixture: RefCounted) -> bool:
	var cases: Array[Dictionary] = []

	var attack_windup := _machine()
	attack_windup.stats.apply_damage(40.0)
	attack_windup.request(PlayerActionRequest.new(PlayerActionRequest.Kind.ATTACK))
	cases.append({"label": "ATTACK_WINDUP", "machine": attack_windup, "reason": "committed"})

	var attack_active := _machine()
	attack_active.stats.apply_damage(40.0)
	attack_active.request(PlayerActionRequest.new(PlayerActionRequest.Kind.ATTACK))
	attack_active.advance(TUNING.attack_windup_seconds)
	cases.append({"label": "ATTACK_ACTIVE", "machine": attack_active, "reason": "committed"})

	var attack_recovery := _machine()
	attack_recovery.stats.apply_damage(40.0)
	attack_recovery.request(PlayerActionRequest.new(PlayerActionRequest.Kind.ATTACK))
	attack_recovery.advance(TUNING.attack_windup_seconds + TUNING.attack_active_seconds)
	cases.append({"label": "early ATTACK_RECOVERY", "machine": attack_recovery, "reason": "committed"})

	var cast_windup := _machine()
	cast_windup.stats.apply_damage(40.0)
	cast_windup.request(PlayerActionRequest.new(PlayerActionRequest.Kind.CAST))
	cases.append({"label": "CAST_WINDUP", "machine": cast_windup, "reason": "committed"})

	var cast_active := _machine()
	cast_active.stats.apply_damage(40.0)
	cast_active.request(PlayerActionRequest.new(PlayerActionRequest.Kind.CAST))
	cast_active.advance(cast_active.spell.cast_windup_seconds)
	cases.append({"label": "CAST_ACTIVE", "machine": cast_active, "reason": "committed"})

	var cast_recovery := _machine()
	cast_recovery.stats.apply_damage(40.0)
	cast_recovery.request(PlayerActionRequest.new(PlayerActionRequest.Kind.CAST))
	cast_recovery.advance(cast_recovery.spell.cast_windup_seconds + cast_recovery.spell.cast_active_seconds)
	cases.append({"label": "early CAST_RECOVERY", "machine": cast_recovery, "reason": "committed"})

	var dodge := _machine()
	dodge.stats.apply_damage(40.0)
	dodge.request(PlayerActionRequest.new(PlayerActionRequest.Kind.DODGE))
	cases.append({"label": "early DODGE", "machine": dodge, "reason": "committed"})

	var guard := _machine()
	guard.stats.apply_damage(40.0)
	guard.request(PlayerActionRequest.new(PlayerActionRequest.Kind.GUARD_START))
	cases.append({"label": "GUARD", "machine": guard, "reason": "committed"})

	var hurt := _machine()
	hurt.stats.apply_damage(40.0)
	hurt.receive_damage(1.0)
	cases.append({"label": "HURT", "machine": hurt, "reason": "committed"})

	var dead := _machine()
	dead.stats.apply_damage(40.0)
	dead.receive_damage(1000.0)
	cases.append({"label": "DEAD", "machine": dead, "reason": "dead"})

	for case in cases:
		var machine: PlayerActionMachine = case["machine"]
		var charges_before := machine.vessel.charges
		assertions.is_false(machine.request(PlayerActionRequest.new(PlayerActionRequest.Kind.HEAL)), "M2B_HEAL_COMMITMENT_BLOCKED: heal must be blocked during %s" % case["label"])
		assertions.equal(machine.blocked_reason, case["reason"], "%s must report the correct heal block reason" % case["label"])
		assertions.equal(machine.vessel.charges, charges_before, "%s must not spend a charge for blocked healing" % case["label"])
		assertions.is_false(machine.consume_heal_tick(), "%s must not leak a deferred heal tick" % case["label"])
	return true


func test_buffered_heal_rechecks_health_and_charge(assertions: Assertions, _fixture: RefCounted) -> bool:
	var full_machine := _machine()
	full_machine.stats.hp = 20.0
	full_machine.request(PlayerActionRequest.new(PlayerActionRequest.Kind.ATTACK))
	full_machine.advance(TUNING.attack_windup_seconds + TUNING.attack_active_seconds + TUNING.attack_recovery_seconds - 0.1)
	assertions.is_true(full_machine.request(PlayerActionRequest.new(PlayerActionRequest.Kind.HEAL)))
	full_machine.stats.hp = TUNING.max_hp
	full_machine.advance(0.1)
	assertions.equal(full_machine.phase, PlayerActionMachine.Phase.FREE)
	assertions.equal(full_machine.vessel.charges, 3)
	assertions.equal(full_machine.blocked_reason, "full health")

	var empty_machine := _machine()
	empty_machine.stats.hp = 20.0
	empty_machine.request(PlayerActionRequest.new(PlayerActionRequest.Kind.ATTACK))
	empty_machine.advance(TUNING.attack_windup_seconds + TUNING.attack_active_seconds + TUNING.attack_recovery_seconds - 0.1)
	assertions.is_true(empty_machine.request(PlayerActionRequest.new(PlayerActionRequest.Kind.HEAL)))
	while empty_machine.vessel.spend_charge():
		pass
	empty_machine.advance(0.1)
	assertions.equal(empty_machine.phase, PlayerActionMachine.Phase.FREE)
	assertions.equal(empty_machine.blocked_reason, "empty vessel")
	return true


func test_damage_interrupts_windup_clears_tick_and_loses_charge(assertions: Assertions, _fixture: RefCounted) -> bool:
	var machine := _machine()
	machine.stats.hp = 50.0
	machine.request(PlayerActionRequest.new(PlayerActionRequest.Kind.HEAL))
	machine.advance(HealingVessel.HEAL_WINDUP - 0.01)
	machine.receive_damage(1.0)
	assertions.equal(machine.phase, PlayerActionMachine.Phase.HURT, "M2B_INTERRUPTION_ENTERS_HURT: windup damage must cancel the pending heal")
	assertions.is_false(machine.consume_heal_tick(), "M2B_INTERRUPTION_CLEARS_PENDING_HEAL: windup damage must clear pending heal")
	assertions.equal(machine.vessel.charges, 2, "interrupted committed charge remains lost")
	return true


func test_damage_after_consumed_heal_does_not_undo_applied_hp(assertions: Assertions, _fixture: RefCounted) -> bool:
	var machine := _machine()
	machine.stats.hp = 20.0
	machine.request(PlayerActionRequest.new(PlayerActionRequest.Kind.HEAL))
	machine.advance(HealingVessel.HEAL_WINDUP)
	assertions.is_true(machine.consume_heal_tick())
	machine.stats.heal(machine.vessel.heal_amount(machine.stats.tuning.max_hp))
	assertions.equal(machine.stats.hp, 60.0)
	machine.receive_damage(5.0)
	assertions.equal(machine.phase, PlayerActionMachine.Phase.HURT)
	assertions.equal(machine.stats.hp, 55.0, "post-heal damage may hurt but cannot undo already applied healing")
	return true


func test_controller_heal_command_feedback_and_reset_refill(assertions: Assertions, fixture: RefCounted) -> bool:
	var playground: CombatPlayground = PLAYGROUND.instantiate()
	fixture.add_node(playground)
	await fixture.physics_frames(2)
	var player := playground.player
	player.set_physics_process(false)
	player.stats.hp = 20.0
	var feedback := {"count": 0, "kind": &"", "text": ""}
	player.combat_feedback.connect(func(kind: StringName, text: String) -> void:
		if kind == &"healed":
			feedback["count"] += 1
			feedback["kind"] = kind
			feedback["text"] = text
	)
	var command := InputCommand.new()
	command.heal_pressed = true
	player.simulate_command(command, 0.0)
	assertions.equal(player.actions.phase, PlayerActionMachine.Phase.HEAL_WINDUP)
	player.simulate_command(InputCommand.new(), HealingVessel.HEAL_WINDUP - 0.001)
	assertions.equal(player.stats.hp, 20.0, "controller must not heal before exact frame")
	player.simulate_command(InputCommand.new(), 0.001)
	assertions.equal(player.stats.hp, 60.0, "controller must apply 40 percent max HP at heal frame")
	assertions.equal(feedback["count"], 1, "controller must emit healed feedback exactly once")
	assertions.equal(feedback["kind"], &"healed")
	player.simulate_command(InputCommand.new(), HealingVessel.HEAL_ACTIVE + HealingVessel.HEAL_RECOVERY)
	assertions.equal(feedback["count"], 1)
	player.vessel.spend_charge()
	player.reset_player()
	assertions.equal(player.vessel.charges, player.vessel.max_charges, "combat-playground reset must refill vessel")
	return true


func test_heal_input_map_has_f_and_dpad_up(assertions: Assertions, _fixture: RefCounted) -> bool:
	assertions.is_true(InputMap.has_action("heal"), "heal input action must exist")
	var has_f := false
	var has_dpad_up := false
	for event in InputMap.action_get_events("heal"):
		if event is InputEventKey and event.physical_keycode == KEY_F:
			has_f = true
		if event is InputEventJoypadButton and event.button_index == 11:
			has_dpad_up = true
	assertions.is_true(has_f, "heal input must bind physical F")
	assertions.is_true(has_dpad_up, "heal input must bind controller D-pad up button 11")
	return true
