extends Area2D

@export var speed = 300
var screen_size

func _ready() -> void:
	screen_size = get_viewport_rect().size

func _process(delta: float) -> void:
	var position = Vector2.ZERO # Vector de movimiento del personaje (x,y)
	
	if Input.is_action_just_pressed("ui_right"):
		position.x += 1
	elif Input.is_action_just_pressed("ui_left"):
		position.x -= 1
	elif Input.is_action_just_pressed("ui_up"):
		position.y -= 1
	elif Input.is_action_just_pressed("ui_down"):
		position.y += 1

	if position.length() > 0:
		position = position.normalized() * speed  # Normalizamos para evitar que vaya a mayor velocidad en diagonal

	position += position * delta
	position = position.clamp(Vector2.ZERO, screen_size) # Evitamos que el personaje salga de pantalla
	 
