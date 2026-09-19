class_name GameSession
extends Node

signal status_changed(kind: StringName, text: String)

var playground: CombatPlayground
var world_state: WorldState
var narrative_state: NarrativeState
var save_manager: SaveManager
var registry: ContentRegistry
var status_kind: StringName = &"idle"
var status_text := ""
var playtime_seconds := 0.0

func configure(source_playground: CombatPlayground, world: WorldState, narrative: NarrativeState, manager: SaveManager, content_registry: ContentRegistry) -> void:
	playground = source_playground
	world_state = world
	narrative_state = narrative
	save_manager = manager
	registry = content_registry
	playground.bind_session(self)

func _process(delta: float) -> void:
	playtime_seconds += maxf(delta, 0.0)

func rest_at(definition: CheckpointDefinition) -> bool:
	if not _valid_checkpoint(definition):
		_report(&"save_failed", "TREE INVALID — SAVE FAILED")
		return false
	if playground.player.actions.phase != PlayerActionMachine.Phase.FREE or _ordinary_enemy_in_combat():
		_report(&"rest_blocked", "CANNOT REST DURING COMBAT")
		return false
	playground.player.reset_renewable_state()
	playground.reset_ordinary_enemies()
	world_state.activate_checkpoint(definition.id)
	if not save_manager.save_game(world_state, narrative_state, definition.id, playtime_seconds):
		_report(&"save_failed", "TREE ACTIVE — SAVE FAILED")
		return false
	_report(&"save_success", "ROOT TREE ACTIVE — SAVED")
	return true

func respawn_from_checkpoint() -> void:
	var definition: CheckpointDefinition = null
	if world_state.current_checkpoint_id != &"":
		definition = registry.checkpoint(world_state.current_checkpoint_id)
	playground.player.reset_renewable_state()
	playground.reset_ordinary_enemies()
	if definition != null:
		playground.player.global_transform = definition.respawn_transform
	else:
		playground.player.transform = playground.player.spawn_transform
	_report(&"checkpoint_ready", "CHECKPOINT READY")

func restore_startup() -> bool:
	if not save_manager.load_game(world_state, narrative_state):
		_report(&"load_failed", "SAVE LOAD FAILED — STARTING FRESH")
		return false
	playtime_seconds = save_manager.loaded_playtime_seconds
	var definition := registry.checkpoint(world_state.current_checkpoint_id)
	if definition == null:
		_report(&"load_failed", "SAVE LOAD FAILED — STARTING FRESH")
		return false
	playground.player.reset_renewable_state()
	playground.reset_ordinary_enemies()
	playground.player.global_transform = definition.respawn_transform
	if save_manager.last_status == &"recovered_backup":
		_report(&"backup_recovered", "SAVE RECOVERED FROM BACKUP")
	else:
		_report(&"checkpoint_ready", "CHECKPOINT READY — SAVE LOADED")
	return true

func _valid_checkpoint(definition: CheckpointDefinition) -> bool:
	return definition != null and definition.validation_errors().is_empty() and registry.checkpoint(definition.id) == definition

func _ordinary_enemy_in_combat() -> bool:
	for node in playground.get_tree().get_nodes_in_group("combat_targets"):
		var enemy := node as EnemyController
		if enemy != null and playground.is_ancestor_of(enemy) and enemy.state_machine.phase not in [EnemyStateMachine.Phase.IDLE, EnemyStateMachine.Phase.RETURN, EnemyStateMachine.Phase.DEAD]:
			return true
	return false

func _report(kind: StringName, text: String) -> void:
	status_kind = kind
	status_text = text
	status_changed.emit(kind, text)
	if playground != null and playground.player != null:
		playground.player.combat_feedback.emit(kind, text)
