extends RefCounted
## Real tests for the assertion collector, including isolated failure capture.

const Assertions = preload("res://tests/support/assertions.gd")


func test_pass(assertions: Assertions, _fixture: RefCounted) -> bool:
	assertions.is_true(true, "A true condition must pass")
	return true


func test_equality(assertions: Assertions, _fixture: RefCounted) -> bool:
	assertions.equal({"crown": 1}, {"crown": 1})
	return true


func test_failure_capture(assertions: Assertions, _fixture: RefCounted) -> bool:
	var captured := Assertions.new()
	captured.is_true(false, "captured sentinel failure")
	assertions.equal(captured.failure_count(), 1, "A failed assertion must be captured")
	assertions.equal(captured.failures()[0], "captured sentinel failure")
	return true


func test_async_completion(assertions: Assertions, fixture: RefCounted) -> bool:
	await fixture.process_frames(1)
	assertions.is_true(true, "Assertions after await must run before pass evaluation")
	return true
