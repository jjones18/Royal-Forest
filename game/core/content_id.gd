class_name ContentId
extends RefCounted

static func is_valid(value: StringName) -> bool:
	var text := String(value)
	if text.count(".") != 1:
		return false
	var parts := text.split(".")
	if parts.size() != 2 or parts[0].is_empty() or parts[1].is_empty():
		return false
	for character in text:
		if not (character >= "a" and character <= "z") and not (character >= "0" and character <= "9") and character != "_" and character != "-" and character != ".":
			return false
	return true

static func is_namespace(value: StringName, expected_namespace: String) -> bool:
	return is_valid(value) and String(value).begins_with(expected_namespace + ".")
