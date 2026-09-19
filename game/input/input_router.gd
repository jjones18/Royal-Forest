class_name InputRouter
extends Node

const TUNING: PlayerTuning = preload("res://game/data/tuning/player_default.tres")

var _look_accumulator := Vector2.ZERO
var _suppress_attack_once := false

func _input(event: InputEvent) -> void:
	# Gameplay look must run before GUI dispatch; a full-screen HUD must not be
	# able to consume mouse motion before the camera sees it.
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		_look_accumulator += event.relative
	elif event is InputEventMouseButton and event.pressed and Input.mouse_mode == Input.MOUSE_MODE_VISIBLE:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		_suppress_attack_once = true
		get_viewport().set_input_as_handled()

func sample() -> InputCommand:
	var command := InputCommand.new()
	command.move = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	command.look = _look_accumulator
	var raw_stick_look := Vector2(Input.get_joy_axis(0, JOY_AXIS_RIGHT_X), Input.get_joy_axis(0, JOY_AXIS_RIGHT_Y))
	command.look_rate = raw_stick_look if raw_stick_look.length() > TUNING.stick_deadzone else Vector2.ZERO
	_look_accumulator = Vector2.ZERO
	command.attack_pressed = Input.is_action_just_pressed("attack") and not _suppress_attack_once
	_suppress_attack_once = false
	command.dodge_pressed = Input.is_action_just_pressed("dodge")
	command.guard_pressed = Input.is_action_just_pressed("guard")
	command.guard_released = Input.is_action_just_released("guard")
	command.guard_held = Input.is_action_pressed("guard")
	command.interact_pressed = Input.is_action_just_pressed("interact")
	command.restart_pressed = Input.is_action_just_pressed("restart")
	command.release_mouse_pressed = Input.is_action_just_pressed("release_mouse")
	return command
