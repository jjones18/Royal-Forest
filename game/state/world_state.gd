class_name WorldState
extends RefCounted

const SET_NAMESPACES := {
	"activated_checkpoint_ids": "checkpoint",
	"opened_shortcut_ids": "shortcut",
	"activated_mechanism_ids": "mechanism",
	"defeated_guardian_ids": "guardian",
	"collected_unique_pickup_ids": "pickup",
	"discovered_map_area_ids": "map_area",
	"region_seal_ids": "seal",
}

var current_checkpoint_id: StringName = &""
var _sets: Dictionary = {}
var last_error := ""

func _init() -> void:
	for key in SET_NAMESPACES:
		_sets[key] = {}

func activate_checkpoint(id: StringName) -> bool:
	if not _add_id("activated_checkpoint_ids", id): return false
	current_checkpoint_id = id
	return true

func open_shortcut(id: StringName) -> bool: return _add_id("opened_shortcut_ids", id)
func activate_mechanism(id: StringName) -> bool: return _add_id("activated_mechanism_ids", id)
func defeat_guardian(id: StringName) -> bool: return _add_id("defeated_guardian_ids", id)
func collect_unique_pickup(id: StringName) -> bool: return _add_id("collected_unique_pickup_ids", id)
func discover_map_area(id: StringName) -> bool: return _add_id("discovered_map_area_ids", id)
func add_region_seal(id: StringName) -> bool: return _add_id("region_seal_ids", id)

func has_activated_checkpoint(id: StringName) -> bool: return _has_id("activated_checkpoint_ids", id)
func has_opened_shortcut(id: StringName) -> bool: return _has_id("opened_shortcut_ids", id)
func has_activated_mechanism(id: StringName) -> bool: return _has_id("activated_mechanism_ids", id)
func has_defeated_guardian(id: StringName) -> bool: return _has_id("defeated_guardian_ids", id)
func has_collected_unique_pickup(id: StringName) -> bool: return _has_id("collected_unique_pickup_ids", id)
func has_discovered_map_area(id: StringName) -> bool: return _has_id("discovered_map_area_ids", id)
func has_region_seal(id: StringName) -> bool: return _has_id("region_seal_ids", id)

func snapshot() -> Dictionary:
	var result := {"current_checkpoint_id": String(current_checkpoint_id)}
	for key in SET_NAMESPACES:
		var values: Array = _sets[key].keys()
		values = values.map(func(value: Variant) -> String: return String(value))
		values.sort()
		result[key] = values
	return result

func apply_snapshot(value: Variant) -> bool:
	last_error = ""
	if typeof(value) != TYPE_DICTIONARY:
		return _fail("world_state must be a dictionary")
	var source: Dictionary = value
	var expected := SET_NAMESPACES.keys()
	expected.append("current_checkpoint_id")
	if source.size() != expected.size():
		return _fail("world_state has missing or unknown fields")
	for key in expected:
		if not source.has(key): return _fail("world_state missing %s" % key)
	if typeof(source["current_checkpoint_id"]) != TYPE_STRING:
		return _fail("current_checkpoint_id must be a string")
	var checkpoint := StringName(source["current_checkpoint_id"])
	if checkpoint != &"" and not ContentId.is_namespace(checkpoint, "checkpoint"):
		return _fail("current checkpoint id is malformed")
	var candidate: Dictionary = {}
	for key in SET_NAMESPACES:
		var parsed := _parse_id_array(source[key], SET_NAMESPACES[key])
		if not parsed["ok"]:
			return _fail("%s contains malformed IDs or has wrong type" % key)
		candidate[key] = parsed["set"]
	if checkpoint != &"" and not candidate["activated_checkpoint_ids"].has(checkpoint):
		return _fail("current checkpoint must be activated")
	current_checkpoint_id = checkpoint
	_sets = candidate
	return true

func _add_id(key: String, id: StringName) -> bool:
	last_error = ""
	if not ContentId.is_namespace(id, SET_NAMESPACES[key]):
		return _fail("id must use %s namespace" % SET_NAMESPACES[key])
	_sets[key][id] = true
	return true

func _has_id(key: String, id: StringName) -> bool:
	return _sets[key].has(id)

func _parse_id_array(value: Variant, expected_namespace: String) -> Dictionary:
	if typeof(value) != TYPE_ARRAY:
		return {"ok": false}
	var result := {}
	for entry in value:
		if typeof(entry) != TYPE_STRING:
			return {"ok": false}
		var id := StringName(entry)
		if not ContentId.is_namespace(id, expected_namespace):
			return {"ok": false}
		result[id] = true
	return {"ok": true, "set": result}

func _fail(message: String) -> bool:
	last_error = message
	return false
