extends StaticBody3D

@export var is_locked: bool = true
var is_flushing: bool = false
var player_nearby: bool = false

@export_file("*.tscn") var next_scene_path: String = ""
@onready var glow_light: OmniLight3D = get_node_or_null("GlowLight")

func _ready() -> void:
	var trigger = get_node_or_null("TriggerArea")
	if trigger:
		trigger.body_entered.connect(_on_body_entered)
		trigger.body_exited.connect(_on_body_exited)

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
	if is_locked:
		print("Falta la ofrenda para activar el desagüe...")
		return
	
	if not is_flushing:
		flush_player()

func unlock() -> void:
	is_locked = false
	print("¡Descarga activada! El inodoro brilla.")
	if glow_light:
		var tween = create_tween()
		tween.tween_property(glow_light, "light_energy", 3.0, 0.4)

func flush_player() -> void:
	is_flushing = true
	print("¡Descarga en progreso!")

	var player = get_tree().get_first_node_in_group("player")
	if not player:
		player = get_parent().find_child("Player", true, false)

	# 1. Crear un telón negro en pantalla para el efecto de transición (fade/diapositiva)
	var canvas = CanvasLayer.new()
	var fade_rect = ColorRect.new()
	fade_rect.color = Color(0, 0, 0, 0)
	fade_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	canvas.add_child(fade_rect)
	add_child(canvas)

	if player:
		player.set_physics_process(false)
		var target_pos = global_position + Vector3(0, 0.4, 0)
		
		# Animación simultánea: Espiral hacia la taza + Fundido a negro tipo transición
		var tween = create_tween().set_parallel(true)
		tween.tween_property(player, "global_position", target_pos, 0.7).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		tween.tween_property(player, "rotation_degrees:y", player.rotation_degrees.y + 720.0, 0.7)
		tween.tween_property(player, "scale", Vector3(0.1, 0.1, 0.1), 0.7)
		tween.tween_property(fade_rect, "color:a", 1.0, 0.6) # Fundido a negro suave
		await tween.finished
	else:
		var tween = create_tween()
		tween.tween_property(fade_rect, "color:a", 1.0, 0.5)
		await tween.finished

	# 2. Cargar el siguiente nivel
	if next_scene_path != "":
		get_tree().change_scene_to_file(next_scene_path)
	else:
		get_tree().reload_current_scene()
