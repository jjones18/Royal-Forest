extends RefCounted

const Assertions = preload("res://tests/support/assertions.gd")

func test_snapshot_is_deterministic_deduped_and_round_trips(assertions: Assertions, _fixture: RefCounted) -> bool:
	var state := NarrativeState.new()
	state.add_note(&"note.brother_hunt_01")
	state.add_note(&"note.brother_hunt_01")
	state.add_echo(&"echo.root_memory")
	state.learn_truth(&"truth.crown_cost")
	state.complete_release_step(&"release_step.crowned_hunt")
	state.set_brother_state(NarrativeState.BROTHER_MISSING)
	state.add_ending_flag(&"ending_flag.cost_understood")
	var snapshot := state.snapshot()
	assertions.equal(snapshot["note_ids"], ["note.brother_hunt_01"])
	var restored := NarrativeState.new()
	assertions.is_true(restored.apply_snapshot(snapshot))
	assertions.equal(restored.snapshot(), snapshot)
	return true

func test_malformed_namespace_stable_id_and_brother_state_reject_atomically(assertions: Assertions, _fixture: RefCounted) -> bool:
	var state := NarrativeState.new()
	state.add_note(&"note.keep")
	var before := state.snapshot()
	var malformed := before.duplicate(true)
	malformed["echo_ids"] = ["note.wrong"]
	assertions.is_false(state.apply_snapshot(malformed))
	assertions.equal(state.snapshot(), before)
	malformed = before.duplicate(true)
	malformed["brother_state"] = "invented"
	assertions.is_false(state.apply_snapshot(malformed))
	assertions.equal(state.snapshot(), before)
	malformed = before.duplicate(true)
	malformed["unknown_field"] = []
	assertions.is_false(state.apply_snapshot(malformed))
	assertions.equal(state.snapshot(), before)
	malformed = before.duplicate(true)
	malformed["note_ids"] = [true]
	assertions.is_false(state.apply_snapshot(malformed))
	assertions.equal(state.snapshot(), before)
	return true
