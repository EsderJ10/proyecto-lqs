extends CharacterBody2D
class_name Slime

# Properties
@export_group("Movement")
@export var speed: int = 157
@export var max_speed: int = 211
@export var follow_smoothing: float = 5.0

@export_group("Combat")
@export var health_points: int = 5
@export var knockback_force: float = 200.0
@export var stun_time: float = 0.2

# Nodes references
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var detection_area: Area2D = $DetectionArea
@onready var collision_shape: CollisionShape2D = $DetectionArea/CollisionShape2D
@onready var stun_timer: Timer = $StunTimer

# State Machine
enum SlimeState { IDLE, CHASING, STUNNED, DEAD }

# State variables
var current_state: SlimeState = SlimeState.IDLE
var player: Player = null
var target_velocity: Vector2 = Vector2.ZERO

func _ready() -> void:
	stun_timer.wait_time = stun_time

func _physics_process(delta: float) -> void:
	match current_state:
		SlimeState.DEAD:
			return
		SlimeState.STUNNED:
			# Apply friction when is stunned
			velocity = velocity.lerp(Vector2.ZERO, 0.1)
			move_and_slide()
			return
		SlimeState.CHASING:
			if player:
				chase_player(delta)
			else:
				transition_to_state(SlimeState.IDLE)
		SlimeState.IDLE:
			# Slow down if not chasing
			velocity = velocity.lerp(Vector2.ZERO, 0.2)
	
	move_and_slide()
	update_animation()

func chase_player(delta: float) -> void:
	var direction_to_player = (player.position - position).normalized()
	target_velocity = direction_to_player * speed
	
	velocity = velocity.lerp(target_velocity, delta * follow_smoothing)
	
	# Cap to max speed
	if velocity.length() > max_speed:
		velocity = velocity.normalized() * max_speed

func update_animation() -> void:
	if current_state == SlimeState.DEAD:
		#animated_sprite.play("death") TODO: Death Animation
		return
	
	# Determine animation based on movement direction
	if velocity.length() > 10:  
		animated_sprite.play(get_direction_name(velocity))
	#else:
		#animated_sprite.play("idle") TODO: Idle Animation

func get_direction_name(direction: Vector2) -> String:
	# Get cardinal direction name based on vector2
	if abs(direction.x) > abs(direction.y):
		return "right" if direction.x > 0 else "left"
	else:
		return "down" if direction.y > 0 else "up"

func _on_detection_area_body_entered(body: Node2D) -> void:
	if body is Player and current_state != SlimeState.DEAD:
		player = body as Player
		transition_to_state(SlimeState.CHASING)

func _on_detection_area_body_exited(body: Node2D) -> void:
	if body is Player and body == player:
		player = null
		transition_to_state(SlimeState.IDLE)

func take_damage(damage_received: int) -> void:
	if current_state == SlimeState.DEAD:
		return
		
	health_points -= damage_received
	
	if health_points <= 0:
		die()
		return
	
	apply_knockback()
	transition_to_state(SlimeState.STUNNED)
	stun_timer.start()

func apply_knockback() -> void:
	if player:
		var knockback_direction = (position - player.position).normalized()
		velocity = knockback_direction * knockback_force

func _on_stun_timer_timeout() -> void:
	if current_state == SlimeState.STUNNED:
		transition_to_state(SlimeState.CHASING if player else SlimeState.IDLE)

func die() -> void:
	transition_to_state(SlimeState.DEAD)
	collision_shape.set_deferred("disabled", true)
	
	# Create tween for fade out effect
	var tween = create_tween()
	tween.tween_property(animated_sprite, "modulate", Color(1, 1, 1, 0), 0.5)
	tween.tween_callback(queue_free)

func transition_to_state(new_state: SlimeState) -> void:
	match current_state:
		SlimeState.STUNNED:
			animated_sprite.modulate = Color(1, 1, 1) # TODO: Change for VFX?
	
	# Update the state
	current_state = new_state
	
	# New State
	match new_state:
		SlimeState.STUNNED:
			animated_sprite.modulate = Color(1, 0.5, 0.5)  # TODO: Change for VFX?
