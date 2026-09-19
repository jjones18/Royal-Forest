extends Node

const PLAYGROUND := preload("res://game/world/combat_playground.tscn")
const RECORDER := preload("res://game/recording/gameplay_recorder.gd")

var playground: CombatPlayground
var recorder: GameplayRecorder


func _ready() -> void:
	playground = PLAYGROUND.instantiate()
	add_child(playground)
	recorder = RECORDER.new()
	recorder.playground = playground
	add_child(recorder)
