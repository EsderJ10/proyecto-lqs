extends CharacterBody2D
class_name Enemy

# Signals
signal enemy_died

# State machine
enum EnemyState { IDLE, CHASING, STUNNED, DEAD }
var current_state: EnemyState = EnemyState.IDLE

# Properties
var speed: int
var max_speed: int
var follow_smoothing: float
var damage: int
var attack_cooldown: float
var stun_time: float
var attack_range: float
var health_points: int
var hit_knockback_force: float
var hit_flash_duration: float

# State tracking variables
var player: Player = null
var target_velocity: Vector2 = Vector2.ZERO
var can_attack: bool = true

# Node references
# Child classes will assign these in their initialize method
var animated_sprite: AnimatedSprite2D
var detection_area: Area2D
var collision_shape: CollisionShape2D
var stun_timer: Timer
var attack_cooldown_timer: Timer

func _ready() -> void:
	# Child classes must implement _ready() and call initialize with their nodes
	pass

# Initialize function that child classes must call
# Child classes should override this, not call it with parameters
func initialize() -> void:
	# Configure timers
	stun_timer.wait_time = stun_time
	attack_cooldown_timer.wait_time = attack_cooldown

func _physics_process(delta: float) -> void:
	match current_state:
		EnemyState.DEAD:
			return
		EnemyState.STUNNED:
			# Apply friction when stunned
			velocity = velocity.lerp(Vector2.ZERO, 0.1)
		EnemyState.CHASING:
			if player and is_instance_valid(player):
				chase_player(delta)
				# Try to attack if close enough and can attack
				if can_attack and global_position.distance_to(player.global_position) <= attack_range:
					attack_player()
			else:
				transition_to_state(EnemyState.IDLE)
		EnemyState.IDLE:
			# Slow down if not chasing
			velocity = velocity.lerp(Vector2.ZERO, 0.2)
	
	move_and_slide()
	update_animation()

func chase_player(delta: float) -> void:
	if not is_instance_valid(player):
		player = null
		transition_to_state(EnemyState.IDLE)
		return
		
	var direction_to_player = (player.global_position - global_position).normalized()
	target_velocity = direction_to_player * speed
	
	velocity = velocity.lerp(target_velocity, delta * follow_smoothing)
	
	# Cap to max speed
	if velocity.length() > max_speed:
		velocity = velocity.normalized() * max_speed

# Must be implemented by child classes
func update_animation() -> void:
	assert(false, "Function 'update_animation' must be implemented by the child class")

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
	if body is Player and current_state != EnemyState.DEAD:
		player = body as Player
		transition_to_state(EnemyState.CHASING)

func _on_detection_area_body_exited(body: Node2D) -> void:
	if body is Player and body == player:
		player = null
		transition_to_state(EnemyState.IDLE)

func take_damage(damage_received: int) -> void:
	if current_state == EnemyState.DEAD:
		return
		
	health_points -= damage_received
	
	# Flash effect on hit
	flash_on_hit()
	
	if health_points <= 0:
		die()
		return
	
	apply_knockback()
	transition_to_state(EnemyState.STUNNED)
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

# Must be implemented by child classes if they have specific attack behavior
func attack_player() -> void:
	if not player or not is_instance_valid(player) or current_state == EnemyState.DEAD:
		return
		
	# Cooldown
	can_attack = false
	attack_cooldown_timer.start()
	
	player.take_damage(damage, global_position)
	
	var lunge_direction = get_player_direction()
	velocity += lunge_direction * 100

func _on_stun_timer_timeout() -> void:
	if current_state == EnemyState.STUNNED:
		transition_to_state(EnemyState.CHASING if player and is_instance_valid(player) else EnemyState.IDLE)

func _on_attack_cooldown_timer_timeout() -> void:
	can_attack = true

# Can be overridden by child classes for custom death behavior
func die() -> void:
	transition_to_state(EnemyState.DEAD)
	collision_shape.set_deferred("disabled", true)
	set_collision_layer_value(1, false)  # Disable collisions
	
	# Emit signal
	enemy_died.emit()
	
	# Fade out effect
	var tween = create_tween()
	tween.tween_property(animated_sprite, "modulate", Color(1, 1, 1, 0), 0.5)
	tween.tween_callback(queue_free)

func transition_to_state(new_state: EnemyState) -> void:
	# Exit current state
	match current_state:
		EnemyState.STUNNED:
			animated_sprite.modulate = Color(1, 1, 1) # Reset color
	
	# Update the state
	current_state = new_state
	
	# Enter new state
	match new_state:
		EnemyState.STUNNED:
			animated_sprite.modulate = Color(1, 0.5, 0.5)  # Red tint when stunned
