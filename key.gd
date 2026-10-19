extends Area3D

signal key_picked_up

var player_nearby: bool = false

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("player") or body.name == "Player":
		player_nearby = true

func _on_body_exited(body: Node3D) -> void:
	if body.is_in_group("player") or body.name == "Player":
		player_nearby = false

func _unhandled_input(event: InputEvent) -> void:
	if player_nearby and event is InputEventKey and event.pressed and not event.echo and event.physical_keycode == KEY_E:
		interact()

func interact() -> void:
	print("¡Ofrenda recogida!")
	key_picked_up.emit()
	queue_free()
