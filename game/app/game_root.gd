extends Node

const PLAYGROUND := preload("res://game/world/combat_playground.tscn")
const RECORDER := preload("res://game/recording/gameplay_recorder.gd")
const ROOT_CHECKPOINT: CheckpointDefinition = preload("res://game/data/checkpoints/root_tree.tres")

var playground: CombatPlayground
var recorder: GameplayRecorder
var world_state: WorldState
var narrative_state: NarrativeState
var save_manager: SaveManager
var content_registry: ContentRegistry
var session: GameSession
var save_path := SaveManager.DEFAULT_SAVE_PATH
var restore_save_on_startup := true

func _ready() -> void:
	playground = PLAYGROUND.instantiate()
	add_child(playground)
	content_registry = ContentRegistry.new()
	content_registry.register_checkpoint(ROOT_CHECKPOINT)
	world_state = WorldState.new()
	narrative_state = NarrativeState.new()
	save_manager = SaveManager.new(save_path, content_registry)
	session = GameSession.new()
	add_child(session)
	session.configure(playground, world_state, narrative_state, save_manager, content_registry)
	if restore_save_on_startup and save_manager.has_any_save():
		session.restore_startup()
	recorder = RECORDER.new()
	recorder.playground = playground
	add_child(recorder)
