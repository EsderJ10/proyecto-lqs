extends CharacterBody2D

# Properties
@export var speed: int = 157
@export var health_points: int = 5
@export var knockback_force: float = 200.0
@export var stun_time: float = 0.2
@export var follow_smoothing: float = 5.0
@export var max_speed: int = 211

# Nodes references
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var detection_area: Area2D = $DetectionArea
@onready var collision_shape: CollisionShape2D = $DetectionArea/CollisionShape2D
@onready var stun_timer: Timer = $StunTimer

# State variables
var is_dead: bool = false
var player_in_area: bool = false
var player: Node2D = null
var is_stunned: bool = false
var target_velocity: Vector2 = Vector2.ZERO

func _ready() -> void:
	is_dead = false
	stun_timer.wait_time = stun_time

func _physics_process(delta: float) -> void:
	if is_dead or is_stunned:
		# Apply the friction when stunned
		if is_stunned:
			velocity = velocity.lerp(Vector2.ZERO, 0.1)
			move_and_slide()
		return
	
	if player_in_area and player:
		chase_player(delta)
	else:
		# Slow down when not chasing the player
		velocity = velocity.lerp(Vector2.ZERO, 0.2)
	
	move_and_slide()
	update_animation()

func chase_player(delta: float) -> void:
	var direction_to_player = (player.position - position).normalized()
	target_velocity = direction_to_player * speed
	
	# Smooth interpolation of current velocity toward target velocity
	velocity = velocity.lerp(target_velocity, delta * follow_smoothing)
	
	# Apply max speed
	if velocity.length() > max_speed:
		velocity = velocity.normalized() * max_speed

func update_animation() -> void:
	if is_dead or is_stunned:
		return
	
	# Determine the animation direction based on movement
	animated_sprite.play(get_direction_name(velocity))

func get_direction_name(direction: Vector2) -> String:
	# Get the cardinal direction name based on vector2
	if abs(direction.x) > abs(direction.y):
		return "right" if direction.x > 0 else "left"
	else:
		return "down" if direction.y > 0 else "up"

func _on_detection_area_body_entered(body: Node2D) -> void:
	if body.has_method("player"):
		player_in_area = true
		player = body

func _on_detection_area_body_exited(body: Node2D) -> void:
	if body.has_method("player"):
		player_in_area = false
		player = null

func take_damage(damage_received: int) -> void:
	health_points -= damage_received
	
	if health_points <= 0:
		die()
		return
	
	apply_knockback()
	apply_stun()

func apply_knockback() -> void:
	if player:
		var knockback_direction = (position - player.position).normalized()
		velocity = knockback_direction * knockback_force

func apply_stun() -> void:
	is_stunned = true
	animated_sprite.modulate = Color(1, 0.5, 0.5)  # TODO: Change for VFX
	stun_timer.start()

func _on_stun_timer_timeout() -> void:
	is_stunned = false
	animated_sprite.modulate = Color(1, 1, 1)  # TODO: Change when VFX added

func die() -> void:
	is_dead = true
	collision_shape.set_deferred("disabled", true)
	
	# TODO: Change for Fade out effect with VFX, not manually
	var tween = create_tween()
	tween.tween_property(animated_sprite, "modulate", Color(1, 1, 1, 0), 0.5)
	tween.tween_callback(queue_free)
