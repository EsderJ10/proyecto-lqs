extends CharacterBody2D

@export var speed: int = 157
@export var health_points: int = 5

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var detection_area: Area2D = $DetectionArea
@onready var collision_shape: CollisionShape2D = $DetectionArea/CollisionShape2D

var is_dead: bool = false
var player_in_area: bool = false
var player: Node2D = null

func _ready() -> void:
	is_dead = false

func _physics_process(delta: float) -> void:
	if not is_dead:
		collision_shape.disabled = false
		if player_in_area and player:
			# Dirección relativa del personaje/jugador
			var direction_to_player = (player.position - position).normalized()
		
			position += direction_to_player * speed * delta
			# Actualizar la animación según la posición relativa del personaje/jugador
			_update_animation(direction_to_player)
	else:
		collision_shape.disabled = true

func _update_animation(direction: Vector2) -> void:
	# Comprobamos si hay que moverse vertical u horizontalmente
	if abs(direction.x) > abs(direction.y):
		if direction.x > 0:
			animated_sprite.play("right")
		else:
			animated_sprite.play("left")
	else:
		if direction.y > 0:
			animated_sprite.play("down")
		else:
			animated_sprite.play("up")

# Personaje/jugador entra en el area
func _on_detection_area_body_entered(body: Node2D) -> void:
	if body.has_method("player"):
		player_in_area = true
		player = body

# Personaje/jugador sale del area
func _on_detection_area_body_exited(body: Node2D) -> void:
	if body.has_method("player"):
		player_in_area = false
		player = null
