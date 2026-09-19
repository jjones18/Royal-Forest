extends RefCounted

const Assertions = preload("res://tests/support/assertions.gd")

func test_snapshot_is_deterministic_deduped_and_round_trips(assertions: Assertions, _fixture: RefCounted) -> bool:
	var state := WorldState.new()
	state.activate_checkpoint(&"checkpoint.root_tree")
	state.activate_checkpoint(&"checkpoint.root_tree")
	state.open_shortcut(&"shortcut.hunt_return_gate")
	state.activate_mechanism(&"mechanism.hunt_road_seal")
	state.defeat_guardian(&"guardian.hound_king")
	state.collect_unique_pickup(&"pickup.hunt_shield")
	state.discover_map_area(&"map_area.root_tree")
	state.add_region_seal(&"seal.crowned_hunt")
	var snapshot := state.snapshot()
	assertions.equal(snapshot["activated_checkpoint_ids"], ["checkpoint.root_tree"])
	assertions.equal(snapshot["opened_shortcut_ids"], ["shortcut.hunt_return_gate"])
	var restored := WorldState.new()
	assertions.is_true(restored.apply_snapshot(snapshot))
	assertions.equal(restored.snapshot(), snapshot)
	return true

func test_malformed_namespace_and_type_reject_atomically(assertions: Assertions, _fixture: RefCounted) -> bool:
	var state := WorldState.new()
	state.activate_checkpoint(&"checkpoint.root_tree")
	state.open_shortcut(&"shortcut.keep")
	var before := state.snapshot()
	var malformed := before.duplicate(true)
	malformed["opened_shortcut_ids"] = ["checkpoint.wrong"]
	assertions.is_false(state.apply_snapshot(malformed))
	assertions.equal(state.snapshot(), before, "malformed namespace must not partially mutate WorldState")
	malformed = before.duplicate(true)
	malformed["region_seal_ids"] = "seal.not-an-array"
	assertions.is_false(state.apply_snapshot(malformed))
	assertions.equal(state.snapshot(), before)
	malformed = before.duplicate(true)
	malformed["unknown_field"] = []
	assertions.is_false(state.apply_snapshot(malformed))
	assertions.equal(state.snapshot(), before)
	malformed = before.duplicate(true)
	malformed["current_checkpoint_id"] = "checkpoint.not_activated"
	assertions.is_false(state.apply_snapshot(malformed))
	assertions.equal(state.snapshot(), before)
	malformed = before.duplicate(true)
	malformed["current_checkpoint_id"] = true
	assertions.is_false(state.apply_snapshot(malformed))
	assertions.equal(state.snapshot(), before)
	return true
