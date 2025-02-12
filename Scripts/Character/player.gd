extends Area2D

@export var speed = 421
var screen_size

func _ready() -> void:
	screen_size = get_viewport_rect().size

func _process(delta):
	var velocity = Vector2.ZERO # Vector de movimiento del personaje (x,y)
	
	if Input.is_action_pressed("move_right"):
		velocity.x += 1
	if Input.is_action_pressed("move_left"):
		velocity.x -= 1
	if Input.is_action_pressed("move_up"):
		velocity.y -= 1
	if Input.is_action_pressed("move_down"):
		velocity.y += 1

	if velocity.length() > 0:
		velocity = velocity.normalized() * speed  # Normalizamos para evitar que vaya a mayor velocidad en diagonal

	position += velocity * delta
	position = position.clamp(Vector2.ZERO, screen_size)
