extends CharacterBody2D

@export var speed: int = 157
@export var health_points: int = 5
@export var knockback_force: float = 200.0
@export var stun_time: float = 0.2

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var detection_area: Area2D = $DetectionArea
@onready var collision_shape: CollisionShape2D = $DetectionArea/CollisionShape2D
@onready var stun_timer: Timer = $StunTimer

var is_dead: bool = false
var player_in_area: bool = false
var player: Node2D = null
var is_stunned: bool = false

func _ready() -> void:
	is_dead = false

func _physics_process(delta: float) -> void:
	if is_dead or is_stunned:
		return
	
	if not is_dead:
		collision_shape.disabled = false
		if player_in_area and player:
			# Dirección relativa del personaje/jugador
			var direction_to_player = (player.position - position).normalized()
			velocity += direction_to_player * speed * delta
			move_and_slide()
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

func take_damage(damage_received: int) -> void:
	health_points -= damage_received
	
	if player:
		var knockback_direction = (position - player.position).normalized()
		velocity = knockback_direction * knockback_force
		move_and_slide()
		
		is_stunned = true
		stun_timer.start()
		
		animated_sprite.modulate = Color(1,0.5,0.5)		# TODO: Add VFX to show it
		
		if health_points <= 0:
			die()

func _on_stun_timer_timeout() -> void:
	is_stunned = false
	animated_sprite.modulate = Color(1,1,1)		# TODO: Remove when added VFX

func die() -> void:
	is_dead = true
	collision_shape.disabled = true
	
	# TODO: Modify for death animation
	
	var tween = create_tween()
	tween.tween_property(animated_sprite, "modulate", Color(1,1,1,0), 0.5)
	tween.tween_callback(queue_free)
