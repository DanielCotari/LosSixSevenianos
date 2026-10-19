extends CharacterBody3D

@export var walk_speed: float = 4.0
@export var sprint_speed: float = 7.0
@export var crouch_speed: float = 2.0
@export var jump_velocity: float = 6.2
@export var mouse_sensitivity: float = 0.003
@export var gravity: float = 14.0

# Alturas de vista
@export var normal_height: float = 1.6
@export var crouch_height: float = 0.8
@export var crouch_transition_speed: float = 10.0

var cam: Camera3D
var head: Node3D
var flashlight: Light3D
var interaction_ray: RayCast3D
var collision_shape: CollisionShape3D

var is_crouching: bool = false

func _ready() -> void:
	head = find_child("Head", true, false) as Node3D
	cam = find_child("Camera3D", true, false) as Camera3D
	flashlight = find_child("SpotLight3D", true, false) as Light3D
	if not flashlight:
		flashlight = find_child("Flashlight", true, false) as Light3D
		
	interaction_ray = find_child("RayCast3D", true, false) as RayCast3D
	collision_shape = find_child("CollisionShape3D", true, false) as CollisionShape3D
	
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	# Pega esto al final de func _ready() en player.gd:
	var tut = find_child("TutorialText", true, false)
	if tut:
		await get_tree().create_timer(9.0).timeout
		tut.visible = false

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		rotate_y(-event.relative.x * mouse_sensitivity)
		if cam:
			cam.rotate_x(-event.relative.y * mouse_sensitivity)
			cam.rotation.x = clamp(cam.rotation.x, deg_to_rad(-80), deg_to_rad(80))

	if event.is_action_pressed("ui_cancel"):
		if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		else:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

	if event is InputEventKey and event.pressed and not event.echo and event.physical_keycode == KEY_F:
		if flashlight:
			flashlight.visible = !flashlight.visible

	# Recoger / Interactuar con E
	if event is InputEventKey and event.pressed and not event.echo and event.physical_keycode == KEY_E:
		check_interaction()

func _physics_process(delta: float) -> void:
	# 1. Aplicar Gravedad
	if not is_on_floor():
		velocity.y -= gravity * delta

	# 2. Agacharse (CTRL o C)
	is_crouching = Input.is_physical_key_pressed(KEY_CTRL) or Input.is_physical_key_pressed(KEY_C)
	
	# Transición suave de la cámara
	var target_cam_y = crouch_height if is_crouching else normal_height
	if head:
		head.position.y = lerp(head.position.y, target_cam_y, crouch_transition_speed * delta)
	elif cam:
		cam.position.y = lerp(cam.position.y, target_cam_y, crouch_transition_speed * delta)

	# Transición de la colisión física (Altura y Adelgazamiento dinámico)
	if collision_shape and collision_shape.shape is CapsuleShape3D:
		var target_height = 0.7 if is_crouching else 1.8
		var target_pos_y = 0.35 if is_crouching else 0.9
		var target_radius = 0.22 if is_crouching else 0.25

		collision_shape.shape.height = lerp(collision_shape.shape.height, target_height, crouch_transition_speed * delta)
		collision_shape.position.y = lerp(collision_shape.position.y, target_pos_y, crouch_transition_speed * delta)
		collision_shape.shape.radius = lerp(collision_shape.shape.radius, target_radius, crouch_transition_speed * delta)

	# 3. Salto (solo de pie y en suelo)
	if Input.is_physical_key_pressed(KEY_SPACE) and is_on_floor() and not is_crouching:
		velocity.y = jump_velocity

	# 4. Velocidad según estado
	var current_speed: float = walk_speed
	if is_crouching:
		current_speed = crouch_speed
	elif Input.is_physical_key_pressed(KEY_SHIFT):
		current_speed = sprint_speed

	# 5. Movimiento WASD
	var input_vector := Vector2.ZERO
	if Input.is_physical_key_pressed(KEY_W):
		input_vector.y -= 1.0
	if Input.is_physical_key_pressed(KEY_S):
		input_vector.y += 1.0
	if Input.is_physical_key_pressed(KEY_A):
		input_vector.x -= 1.0
	if Input.is_physical_key_pressed(KEY_D):
		input_vector.x += 1.0

	input_vector = input_vector.normalized()
	var move_dir := (transform.basis * Vector3(input_vector.x, 0.0, input_vector.y)).normalized()

	if move_dir != Vector3.ZERO:
		velocity.x = move_dir.x * current_speed
		velocity.z = move_dir.z * current_speed
	else:
		velocity.x = move_toward(velocity.x, 0.0, current_speed)
		velocity.z = move_toward(velocity.z, 0.0, current_speed)

	move_and_slide()
	
func check_interaction() -> void:
	if not interaction_ray:
		print("ERROR: No se encontró el RayCast3D")
		return

	if interaction_ray.is_colliding():
		var target = interaction_ray.get_collider()
		print("Rayo chocó con: ", target.name)
		
		# 1. Intentar interactuar con el objeto directo
		if target.has_method("interact"):
			target.interact()
			return
			
		# 2. Si chocó con la colisión interna, buscar en su padre
		var parent = target.get_parent()
		if parent and parent.has_method("interact"):
			parent.interact()
			return
			
		# 3. Si chocó con el modelo, buscar en los hijos
		for child in target.get_children():
			if child.has_method("interact"):
				child.interact()
				return
	else:
		print("El rayo no está chocando con nada (acércate más)")
