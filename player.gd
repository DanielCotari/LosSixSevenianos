extends CharacterBody3D

@export var walk_speed: float = 3.5
@export var sprint_speed: float = 6.0
@export var jump_velocity: float = 4.2
@export var gravity: float = 9.8
@export var mouse_sensitivity: float = 0.002

@onready var head: Node3D = $Head
@onready var camera: Camera3D = $Head/Camera3D
@onready var interaction_ray: RayCast3D = $Head/RayCast3D
@onready var flashlight: SpotLight3D = $Head/Flashlight

func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _unhandled_input(event: InputEvent) -> void:
	# Rotación de cámara con el ratón
	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		rotate_y(-event.relative.x * mouse_sensitivity)
		head.rotate_x(-event.relative.y * mouse_sensitivity)
		head.rotation.x = clamp(head.rotation.x, deg_to_rad(-80), deg_to_rad(80))

	# Liberar o capturar el ratón con ESC
	if event.is_action_pressed("ui_cancel"):
		if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		else:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

	# Encender o apagar la linterna con F
	if event.is_action_pressed("toggle_flashlight"):
		flashlight.visible = !flashlight.visible

	# Interactuar con E
	if event.is_action_pressed("interact"):
		check_interaction()

func _physics_process(delta: float) -> void:
	# Gravedad
	if not is_on_floor():
		velocity.y -= gravity * delta

	# Salto con Espacio
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = jump_velocity

	# Velocidad (Caminar o Correr con Shift)
	var speed = sprint_speed if Input.is_action_pressed("sprint") else walk_speed

	# Dirección según hacia dónde mira la cámara
	var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()

	if direction != Vector3.ZERO:
		velocity.x = direction.x * speed
		velocity.z = direction.z * speed
	else:
		velocity.x = move_toward(velocity.x, 0, speed)
		velocity.z = move_toward(velocity.z, 0, speed)

	move_and_slide()

func check_interaction() -> void:
	if interaction_ray.is_colliding():
		var target = interaction_ray.get_collider()
		if target and target.has_method("interact"):
			target.interact()
