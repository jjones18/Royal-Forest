extends RefCounted
## Small dependency-free assertion collector used by the deterministic test runner.

var _failures: Array[String] = []


func is_true(condition: bool, message: String = "Expected condition to be true") -> void:
	if not condition:
		_failures.append(message)


func is_false(condition: bool, message: String = "Expected condition to be false") -> void:
	if condition:
		_failures.append(message)


func equal(actual: Variant, expected: Variant, message: String = "") -> void:
	if actual == expected:
		return
	var detail := message
	if detail.is_empty():
		detail = "Expected %s, got %s" % [str(expected), str(actual)]
	_failures.append(detail)


func fail(message: String) -> void:
	_failures.append(message)


func has_failures() -> bool:
	return not _failures.is_empty()


func failure_count() -> int:
	return _failures.size()


func failures() -> Array[String]:
	return _failures.duplicate()
