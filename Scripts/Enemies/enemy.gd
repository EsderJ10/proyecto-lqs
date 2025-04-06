extends CharacterBody2D
class_name Enemy

# Signals
signal enemy_died

# State machine
enum EnemyState { IDLE, CHASING, STUNNED, DEAD }
var current_state: EnemyState = EnemyState.IDLE

# Properties
@export_group("Movement")
@export var speed: int = 150
@export var max_speed: int = 200
@export var follow_smoothing: float = 5.0

@export_group("Combat")
@export var damage: int = 1
@export var attack_cooldown: float = 1.0
@export var stun_time: float = 0.3
@export var attack_range: float = 50.0

@export_group("Health")
@export var health_points: int = 3
@export var hit_knockback_force: float = 200.0
@export var hit_flash_duration: float = 0.15

# Node references 
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var detection_area: Area2D = $DetectionArea
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var stun_timer: Timer = $StunTimer
@onready var attack_cooldown_timer: Timer = $AttackCooldownTimer

# State tracking variables
var player: Player = null
var target_velocity: Vector2 = Vector2.ZERO
var can_attack: bool = true

# Cached values
var direction_to_player: Vector2 = Vector2.DOWN
var player_distance: float = 0.0
var knockback_direction: Vector2 = Vector2.ZERO
var speed_squared: float = 0.0

func _ready() -> void:
	initialize()
	
	add_to_group("enemies")
	
	# Precalculate squared values
	speed_squared = max_speed * max_speed

# Clean up any signal connections
func _exit_tree() -> void:
	if player and player.has_signal("player_died") and player.is_connected("player_died", _on_player_died):
		player.disconnect("player_died", _on_player_died)

# Initialize function that child classes can override
func initialize() -> void:
	if stun_timer:
		stun_timer.wait_time = stun_time
		stun_timer.one_shot = true
	
	if attack_cooldown_timer:
		attack_cooldown_timer.wait_time = attack_cooldown
		attack_cooldown_timer.one_shot = true

func _physics_process(delta: float) -> void:
	match current_state:
		EnemyState.DEAD:
			return
		EnemyState.STUNNED:
			# Apply friction when stunned
			velocity = velocity.lerp(Vector2.ZERO, 0.1)
		EnemyState.CHASING:
			if player:
				update_player_data()
				chase_player(delta)
				
				# Add separation force when too close
				if player_distance < 40.0:
					var separation: Vector2 = (global_position - player.global_position).normalized() * 25.0
					velocity += separation

				# Try to attack if close enough and can attack
				if can_attack and player_distance <= attack_range:
					attack_player()
			else:
				transition_to_state(EnemyState.IDLE)
		EnemyState.IDLE:
			# Slow down if not chasing
			velocity = velocity.lerp(Vector2.ZERO, 0.2)

	# Handle collision
	var collision: KinematicCollision2D = move_and_collide(velocity * delta, true)
	if collision and collision.get_collider() is Player:
		global_position += collision.get_normal() * collision.get_depth()
		velocity = velocity.bounce(collision.get_normal()) * 0.6

	move_and_slide()
	update_animation()

# Update cached player data
func update_player_data() -> void:
	if player:
		var to_player: Vector2 = player.global_position - global_position
		player_distance = to_player.length()
		if player_distance > 0:
			direction_to_player = to_player / player_distance
		else:
			direction_to_player = Vector2.DOWN

func chase_player(delta: float) -> void:
	if not player:
		transition_to_state(EnemyState.IDLE)
		return

	# Use cached direction
	target_velocity = direction_to_player * speed

	# Add repulsion vector when very close to player
	if player_distance < 30.0:
		target_velocity = target_velocity.lerp(-direction_to_player * speed, 0.5)

	velocity = velocity.lerp(target_velocity, delta * follow_smoothing)

	# Cap to max speed
	if velocity.length_squared() > speed_squared:
		velocity = velocity.normalized() * max_speed
	
func update_animation() -> void:
	push_error("** ERROR: Function 'update_animation' must be implemented by %s" % [get_class()])

func get_direction_name(direction: Vector2) -> String:
	# Get cardinal direction name based on vector2
	if abs(direction.x) > abs(direction.y):
		return "right" if direction.x > 0 else "left"
	else:
		return "down" if direction.y > 0 else "up"

func get_player_direction() -> Vector2:
	return direction_to_player if player else Vector2.DOWN

func _on_detection_area_body_entered(body: Node2D) -> void:
	if body is Player and current_state != EnemyState.DEAD:
		player = body
		
		# Connect to player signals if available
		if player.has_signal("player_died") and not player.is_connected("player_died", _on_player_died):
			player.connect("player_died", _on_player_died)
			
		# Initial player data update
		update_player_data()
		transition_to_state(EnemyState.CHASING)

func _on_detection_area_body_exited(body: Node2D) -> void:
	if body is Player and body == player:
		# Clean up player connections
		if player.has_signal("player_died") and player.is_connected("player_died", _on_player_died):
			player.disconnect("player_died", _on_player_died)
				
		player = null
		transition_to_state(EnemyState.IDLE)

# Callback for player death
func _on_player_died() -> void:
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
	if not animated_sprite:
		return
		
	# Hit flash effect
	animated_sprite.modulate = Color(1.5, 1.5, 1.5, 1)  # Bright white flash
	
	var tween: Tween = create_tween()
	tween.tween_property(animated_sprite, "modulate", Color(1, 1, 1, 1), hit_flash_duration)

func apply_knockback() -> void:
	if player:
		knockback_direction = (global_position - player.global_position).normalized()
		velocity = knockback_direction * hit_knockback_force

func attack_player() -> void:
	if not player or current_state == EnemyState.DEAD:
		return
		
	can_attack = false
	attack_cooldown_timer.start()

	player.take_damage(damage, global_position)
	
	# Add a little lunge effect
	velocity += direction_to_player * 100

func _on_stun_timer_timeout() -> void:
	if current_state == EnemyState.STUNNED:
		transition_to_state(EnemyState.CHASING if player else EnemyState.IDLE)

func _on_attack_cooldown_timer_timeout() -> void:
	can_attack = true

# Method for death behavior
func die() -> void:
	transition_to_state(EnemyState.DEAD)
	
	if collision_shape:
		collision_shape.set_deferred("disabled", true)
	set_collision_layer_value(1, false)  
	
	# Emit signal
	enemy_died.emit()
	
	# Fade out effect
	if animated_sprite:
		var tween: Tween = create_tween()
		tween.tween_property(animated_sprite, "modulate", Color(1, 1, 1, 0), 0.5)
		tween.tween_callback(queue_free)

func transition_to_state(new_state: EnemyState) -> void:
	if current_state == new_state:
		return
		
	# Exit current state
	match current_state:
		EnemyState.STUNNED:
			if animated_sprite:
				animated_sprite.modulate = Color(1, 1, 1) # Reset color
	
	# Update the state
	current_state = new_state
	
	# Enter new state
	match new_state:
		EnemyState.STUNNED:
			if animated_sprite:
				animated_sprite.modulate = Color(1, 0.5, 0.5)  # Red tint when stunned
