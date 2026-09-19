extends RefCounted

const Assertions = preload("res://tests/support/assertions.gd")
const DEFINITION: EnemyDefinition = preload("res://game/data/enemies/shambler.tres")

func test_detection_los_grace_search_reacquire_and_return(assertions: Assertions, _fixture: RefCounted) -> bool:
	var machine := EnemyStateMachine.new()
	machine.configure(DEFINITION)
	machine.update_awareness(true, true, false, 0.0)
	assertions.equal(machine.phase, EnemyStateMachine.Phase.PURSUIT)
	machine.update_awareness(false, true, false, DEFINITION.line_of_sight_grace_seconds * 0.5)
	assertions.equal(machine.phase, EnemyStateMachine.Phase.PURSUIT, "brief occlusion must preserve pursuit")
	machine.update_awareness(false, true, false, DEFINITION.line_of_sight_grace_seconds * 0.5)
	assertions.equal(machine.phase, EnemyStateMachine.Phase.SEARCH, "LOS grace expiry must enter search")
	machine.update_awareness(true, true, false, 0.0)
	assertions.equal(machine.phase, EnemyStateMachine.Phase.PURSUIT, "search must reacquire immediately")
	machine.update_awareness(false, true, false, DEFINITION.line_of_sight_grace_seconds)
	machine.update_awareness(false, true, false, DEFINITION.search_duration_seconds)
	assertions.equal(machine.phase, EnemyStateMachine.Phase.RETURN, "search expiry must return home")
	machine.arrive_home()
	assertions.equal(machine.phase, EnemyStateMachine.Phase.IDLE)
	return true

func test_leash_forces_return_but_visible_target_reacquires_inside_leash(assertions: Assertions, _fixture: RefCounted) -> bool:
	var machine := EnemyStateMachine.new()
	machine.configure(DEFINITION)
	machine.update_awareness(true, true, false, 0.0)
	machine.update_awareness(true, true, true, 0.0)
	assertions.equal(machine.phase, EnemyStateMachine.Phase.RETURN)
	machine.update_awareness(true, true, false, 0.0)
	assertions.equal(machine.phase, EnemyStateMachine.Phase.PURSUIT, "RETURN must re-engage a visible target inside detection and leash range")
	return true

func test_strike_only_once_during_active(assertions: Assertions, _fixture: RefCounted) -> bool:
	var machine := EnemyStateMachine.new()
	machine.configure(DEFINITION)
	machine.update_awareness(true, true, false, 0.0)
	assertions.is_true(machine.request_attack(true, true))
	assertions.is_false(machine.consume_strike())
	machine.advance(DEFINITION.windup_seconds)
	assertions.equal(machine.phase, EnemyStateMachine.Phase.ACTIVE)
	assertions.is_true(machine.consume_strike())
	assertions.is_false(machine.consume_strike())
	machine.advance(DEFINITION.active_seconds)
	assertions.equal(machine.phase, EnemyStateMachine.Phase.RECOVERY)
	return true

func test_hurt_death_and_reset(assertions: Assertions, _fixture: RefCounted) -> bool:
	var machine := EnemyStateMachine.new()
	machine.stagger()
	assertions.equal(machine.phase, EnemyStateMachine.Phase.HURT)
	machine.die()
	assertions.equal(machine.phase, EnemyStateMachine.Phase.DEAD)
	machine.reset()
	assertions.equal(machine.phase, EnemyStateMachine.Phase.IDLE)
	return true
