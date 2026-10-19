extends Control

@onready var btn_play: Button = find_child("btn_play", true, false)
@onready var btn_quit: Button = find_child("btn_quit", true, false)

var vel_play: Vector2 = Vector2(170, 130)
var vel_quit: Vector2 = Vector2(-150, 160)

func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	if btn_play:
		btn_play.pressed.connect(_on_play_pressed)
	if btn_quit:
		btn_quit.pressed.connect(_on_quit_pressed)

func _process(delta: float) -> void:
	var vp_size: Vector2 = get_viewport_rect().size
	
	if btn_play:
		btn_play.position += vel_play * delta
		if btn_play.position.x <= 0 or btn_play.position.x + btn_play.size.x >= vp_size.x:
			vel_play.x = -vel_play.x
		if btn_play.position.y <= 120 or btn_play.position.y + btn_play.size.y >= vp_size.y:
			vel_play.y = -vel_play.y

	if btn_quit:
		btn_quit.position += vel_quit * delta
		if btn_quit.position.x <= 0 or btn_quit.position.x + btn_quit.size.x >= vp_size.x:
			vel_quit.x = -vel_quit.x
		if btn_quit.position.y <= 120 or btn_quit.position.y + btn_quit.size.y >= vp_size.y:
			vel_quit.y = -vel_quit.y

	# Colisión y rebote entre ambos botones
	if btn_play and btn_quit:
		var rect_play := Rect2(btn_play.position, btn_play.size)
		var rect_quit := Rect2(btn_quit.position, btn_quit.size)
		if rect_play.intersects(rect_quit):
			var temp := vel_play
			vel_play = vel_quit
			vel_quit = temp
			# Separar un poco para evitar que se queden pegados
			btn_play.position += vel_play * delta * 2.0
			btn_quit.position += vel_quit * delta * 2.0

func _on_play_pressed() -> void:
	get_tree().change_scene_to_file("res://room_01.tscn")

func _on_quit_pressed() -> void:
	get_tree().quit()
