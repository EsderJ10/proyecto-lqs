extends CharacterBody2D
class_name Slime

# Signals
signal slime_died

# Properties
@export_group("Movement")
@export var speed: int = 157
@export var max_speed: int = 211
@export var follow_smoothing: float = 5.0

@export_group("Combat")
@export var damage: int = 1
@export var attack_cooldown: float = 1.0
@export var stun_time: float = 0.2
@export var attack_range: float = 60.0 

@export_group("Health")
@export var health_points: int = 5
@export var hit_knockback_force: float = 200.0
@export var hit_flash_duration: float = 0.15

# Nodes references
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var detection_area: Area2D = $DetectionArea
@onready var collision_shape: CollisionShape2D = $DetectionArea/CollisionShape2D
@onready var stun_timer: Timer = $StunTimer
@onready var attack_cooldown_timer: Timer = $AttackCooldownTimer

# State Machine
enum SlimeState { IDLE, CHASING, STUNNED, DEAD }

# State variables
var current_state: SlimeState = SlimeState.IDLE
var player: Player = null
var target_velocity: Vector2 = Vector2.ZERO
var can_attack: bool = true

func _ready() -> void:
	# Configure timers
	stun_timer.wait_time = stun_time
	attack_cooldown_timer.wait_time = attack_cooldown

func _physics_process(delta: float) -> void:
	match current_state:
		SlimeState.DEAD:
			return
		SlimeState.STUNNED:
			# Apply friction when stunned
			velocity = velocity.lerp(Vector2.ZERO, 0.1)
		SlimeState.CHASING:
			if player and is_instance_valid(player):
				chase_player(delta)
				# Try to attack if close enough and can attack
				if can_attack and global_position.distance_to(player.global_position) <= attack_range:
					attack_player()
			else:
				transition_to_state(SlimeState.IDLE)
		SlimeState.IDLE:
			# Slow down if not chasing
			velocity = velocity.lerp(Vector2.ZERO, 0.2)
	
	move_and_slide()
	update_animation()

func chase_player(delta: float) -> void:
	if not is_instance_valid(player):
		player = null
		transition_to_state(SlimeState.IDLE)
		return
		
	var direction_to_player = (player.global_position - global_position).normalized()
	target_velocity = direction_to_player * speed
	
	velocity = velocity.lerp(target_velocity, delta * follow_smoothing)
	
	# Cap to max speed
	if velocity.length() > max_speed:
		velocity = velocity.normalized() * max_speed

func update_animation() -> void:
	if current_state == SlimeState.DEAD:
		# TODO: DEAD Animation
		return
	# Determine animation based on movement direction
	if velocity.length() > 10:  
		animated_sprite.play(get_direction_name(velocity))
	else:
		# Use the last direction when idle
		var face_direction = get_player_direction() if player and is_instance_valid(player) else Vector2.DOWN
		animated_sprite.play(get_direction_name(face_direction))

func get_direction_name(direction: Vector2) -> String:
	# Get cardinal direction name based on vector2
	if abs(direction.x) > abs(direction.y):
		return "right" if direction.x > 0 else "left"
	else:
		return "down" if direction.y > 0 else "up"

func get_player_direction() -> Vector2:
	if player and is_instance_valid(player):
		return (player.global_position - global_position).normalized()
	return Vector2.DOWN

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
	
	# Flash effect on hit
	flash_on_hit()
	
	if health_points <= 0:
		die()
		return
	
	apply_knockback()
	transition_to_state(SlimeState.STUNNED)
	stun_timer.start()

func flash_on_hit() -> void:
	# Hit flash effect
	animated_sprite.modulate = Color(1.5, 1.5, 1.5, 1)  # Bright white flash
	
	# Return to normal after a short duration
	var tween = create_tween()
	tween.tween_property(animated_sprite, "modulate", Color(1, 1, 1, 1), hit_flash_duration)

func apply_knockback() -> void:
	if player and is_instance_valid(player):
		var knockback_direction = (global_position - player.global_position).normalized()
		velocity = knockback_direction * hit_knockback_force

func attack_player() -> void:
	if not player or not is_instance_valid(player) or current_state == SlimeState.DEAD:
		return
		
	# Cooldown
	can_attack = false
	attack_cooldown_timer.start()
	
	player.take_damage(damage, global_position)
	
	var lunge_direction = get_player_direction()
	velocity += lunge_direction * 100

func _on_stun_timer_timeout() -> void:
	if current_state == SlimeState.STUNNED:
		transition_to_state(SlimeState.CHASING if player and is_instance_valid(player) else SlimeState.IDLE)

func _on_attack_cooldown_timer_timeout() -> void:
	can_attack = true

func die() -> void:
	transition_to_state(SlimeState.DEAD)
	collision_shape.set_deferred("disabled", true)
	set_collision_layer_value(1, false)  # Disable collisions
	
	# Emit signal
	slime_died.emit()
	
	# Fade out effect
	var tween = create_tween()
	tween.tween_property(animated_sprite, "modulate", Color(1, 1, 1, 0), 0.5)
	tween.tween_callback(queue_free)

func transition_to_state(new_state: SlimeState) -> void:
	# Exit current state
	match current_state:
		SlimeState.STUNNED:
			animated_sprite.modulate = Color(1, 1, 1) # Reset color
	
	# Update the state
	current_state = new_state
	
	# Enter new state
	match new_state:
		SlimeState.STUNNED:
			animated_sprite.modulate = Color(1, 0.5, 0.5)  # Red tint when stunned
