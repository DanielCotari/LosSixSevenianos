extends Area3D

signal key_picked_up

func interact() -> void:
	print("¡Llave recogida!")
	key_picked_up.emit()
	queue_free()
