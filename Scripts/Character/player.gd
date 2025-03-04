extends CharacterBody2D

@export var speed = 421
@onready var animated_sprite = $AnimatedSprite2D

func _process(delta):
	var movement = Vector2.ZERO # Vector de movimiento del personaje (x,y)
	
	if Input.is_action_pressed("move_right"):
		movement.x += 1
		animated_sprite.play("right")
	if Input.is_action_pressed("move_left"):
		movement.x -= 1
		animated_sprite.play("left")
	if Input.is_action_pressed("move_up"):
		movement.y -= 1
		animated_sprite.play("up")
	if Input.is_action_pressed("move_down"):
		movement.y += 1
		animated_sprite.play("down")

	if movement.length() > 0:
		movement = movement.normalized() * speed  # Normalizamos para evitar que vaya a mayor velocidad en diagonal

	move_and_collide(movement * delta) # Movimiento mientras detecta colisiones
	
# Función para que los enemigos detecten al personaje/jugador
func player():
	pass
