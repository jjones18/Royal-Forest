extends RefCounted
## Per-test owner for deterministic time and temporary SceneTree nodes.

var elapsed_seconds := 0.0
var step_count := 0
var _tree: SceneTree
var _root: Node


func _init(tree: SceneTree, host: Node, test_id: String) -> void:
	_tree = tree
	_root = Node.new()
	_root.name = "Fixture_%s" % test_id.replace(".", "_")
	host.add_child(_root)


func reset() -> void:
	elapsed_seconds = 0.0
	step_count = 0


func advance(delta: float, step: Callable = Callable()) -> bool:
	if delta < 0.0:
		return false
	elapsed_seconds += delta
	step_count += 1
	if step.is_valid():
		step.call(delta)
	return true


func add_node(node: Node) -> Node:
	_root.add_child(node)
	return node


func process_frames(count: int = 1) -> void:
	for _frame in range(maxi(count, 0)):
		await _tree.process_frame


func physics_frames(count: int = 1) -> void:
	for _frame in range(maxi(count, 0)):
		await _tree.physics_frame


func teardown() -> void:
	if is_instance_valid(_root):
		_root.free()
	_root = null
