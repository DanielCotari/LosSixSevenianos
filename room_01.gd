extends Node3D

@onready var toilet_portal = $ToiletPortal
@onready var key = $Key

func _ready() -> void:
	if key:
		key.key_picked_up.connect(_on_key_picked_up)

func _on_key_picked_up() -> void:
	if toilet_portal:
		toilet_portal.unlock()
