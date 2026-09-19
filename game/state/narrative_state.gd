class_name NarrativeState
extends RefCounted

const BROTHER_UNKNOWN := "unknown"
const BROTHER_MISSING := "missing"
const BROTHER_FOUND := "found"
const BROTHER_RELEASED := "released"
const BROTHER_STATES := [BROTHER_UNKNOWN, BROTHER_MISSING, BROTHER_FOUND, BROTHER_RELEASED]
const SET_NAMESPACES := {
	"note_ids": "note",
	"echo_ids": "echo",
	"learned_truth_ids": "truth",
	"release_step_ids": "release_step",
	"ending_flag_ids": "ending_flag",
}

var brother_state := BROTHER_UNKNOWN
var _sets: Dictionary = {}
var last_error := ""

func _init() -> void:
	for key in SET_NAMESPACES: _sets[key] = {}

func add_note(id: StringName) -> bool: return _add_id("note_ids", id)
func add_echo(id: StringName) -> bool: return _add_id("echo_ids", id)
func learn_truth(id: StringName) -> bool: return _add_id("learned_truth_ids", id)
func complete_release_step(id: StringName) -> bool: return _add_id("release_step_ids", id)
func add_ending_flag(id: StringName) -> bool: return _add_id("ending_flag_ids", id)
func has_note(id: StringName) -> bool: return _sets["note_ids"].has(id)
func has_echo(id: StringName) -> bool: return _sets["echo_ids"].has(id)
func has_learned_truth(id: StringName) -> bool: return _sets["learned_truth_ids"].has(id)
func has_release_step(id: StringName) -> bool: return _sets["release_step_ids"].has(id)
func has_ending_flag(id: StringName) -> bool: return _sets["ending_flag_ids"].has(id)

func set_brother_state(value: String) -> bool:
	last_error = ""
	if value not in BROTHER_STATES: return _fail("invalid brother state")
	brother_state = value
	return true

func snapshot() -> Dictionary:
	var result := {"brother_state": brother_state}
	for key in SET_NAMESPACES:
		var values: Array = _sets[key].keys()
		values = values.map(func(value: Variant) -> String: return String(value))
		values.sort()
		result[key] = values
	return result

func apply_snapshot(value: Variant) -> bool:
	last_error = ""
	if typeof(value) != TYPE_DICTIONARY: return _fail("narrative_state must be a dictionary")
	var source: Dictionary = value
	var expected := SET_NAMESPACES.keys()
	expected.append("brother_state")
	if source.size() != expected.size(): return _fail("narrative_state has missing or unknown fields")
	for key in expected:
		if not source.has(key): return _fail("narrative_state missing %s" % key)
	if typeof(source["brother_state"]) != TYPE_STRING or source["brother_state"] not in BROTHER_STATES:
		return _fail("invalid brother state")
	var candidate := {}
	for key in SET_NAMESPACES:
		var parsed := _parse_id_array(source[key], SET_NAMESPACES[key])
		if not parsed["ok"]: return _fail("%s contains malformed IDs or has wrong type" % key)
		candidate[key] = parsed["set"]
	brother_state = source["brother_state"]
	_sets = candidate
	return true

func _add_id(key: String, id: StringName) -> bool:
	last_error = ""
	if not ContentId.is_namespace(id, SET_NAMESPACES[key]): return _fail("id must use %s namespace" % SET_NAMESPACES[key])
	_sets[key][id] = true
	return true

func _parse_id_array(value: Variant, expected_namespace: String) -> Dictionary:
	if typeof(value) != TYPE_ARRAY: return {"ok": false}
	var result := {}
	for entry in value:
		if typeof(entry) != TYPE_STRING: return {"ok": false}
		var id := StringName(entry)
		if not ContentId.is_namespace(id, expected_namespace): return {"ok": false}
		result[id] = true
	return {"ok": true, "set": result}

func _fail(message: String) -> bool:
	last_error = message
	return false
