class_name PlayerActionRequest
extends RefCounted

enum Kind { NONE, ATTACK, CAST, HEAL, DODGE, GUARD_START, GUARD_END }

var kind: Kind = Kind.NONE
var move_direction: Vector2 = Vector2.ZERO

func _init(request_kind: Kind = Kind.NONE, direction: Vector2 = Vector2.ZERO) -> void:
	kind = request_kind
	move_direction = direction
