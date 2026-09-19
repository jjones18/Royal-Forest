class_name InputCommand
extends RefCounted

var move: Vector2 = Vector2.ZERO
var look: Vector2 = Vector2.ZERO
var look_rate: Vector2 = Vector2.ZERO
var attack_pressed := false
var cast_pressed := false
var heal_pressed := false
var crouch_pressed := false
var dodge_pressed := false
var guard_pressed := false
var guard_released := false
var guard_held := false
var interact_pressed := false
var restart_pressed := false
var release_mouse_pressed := false
