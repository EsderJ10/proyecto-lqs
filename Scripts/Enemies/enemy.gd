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

var directions = {
	"right": "right",
	"left": "left", 
	"up": "up",
	"down": "down"
}

func _ready() -> void:
	# Initialize the enemy
	initialize()
	
	# Add to group for easier management
	add_to_group("enemies")
	
	# Precalculate squared values for more efficient comparisons
	speed_squared = max_speed * max_speed

func _exit_tree() -> void:
	# Clean up any signal connections
	if player and player.has_signal("player_died"):
		if player.is_connected("player_died", _on_player_died):
			player.disconnect("player_died", _on_player_died)

# Initialize function that child classes can override
func initialize() -> void:
	# Configure timers
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
				# Cache player information
				update_player_data()
				
				# Process chase behavior
				chase_player(delta)
				
				# Try to attack if close enough and can attack
				if can_attack and player_distance <= attack_range:
					attack_player()
			else:
				transition_to_state(EnemyState.IDLE)
		EnemyState.IDLE:
			# Slow down if not chasing
			velocity = velocity.lerp(Vector2.ZERO, 0.2)
	
	move_and_slide()
	update_animation()

# Update cached player data
func update_player_data() -> void:
	if player:
		var to_player = player.global_position - global_position
		player_distance = to_player.length()
		direction_to_player = to_player / player_distance if player_distance > 0 else Vector2.DOWN

func chase_player(delta: float) -> void:
	if not player:
		transition_to_state(EnemyState.IDLE)
		return
	
	# Use cached direction
	target_velocity = direction_to_player * speed
	
	# Improved smoothing with delta
	velocity = velocity.lerp(target_velocity, delta * follow_smoothing)
	
	# Cap to max speed using squared length for efficiency
	if velocity.length_squared() > speed_squared:
		velocity = velocity.normalized() * max_speed

# Method for animation updates
func update_animation() -> void:
	push_error("Function 'update_animation' must be implemented by the child class")

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
		if player.has_signal("player_died"):
			if player.is_connected("player_died", _on_player_died):
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
	
	# Return to normal after a short duration using a tween
	var tween = create_tween()
	tween.tween_property(animated_sprite, "modulate", Color(1, 1, 1, 1), hit_flash_duration)

func apply_knockback() -> void:
	if player:
		knockback_direction = (global_position - player.global_position).normalized()
		velocity = knockback_direction * hit_knockback_force

func attack_player() -> void:
	if not player or current_state == EnemyState.DEAD:
		return
		
	# Cooldown
	can_attack = false
	attack_cooldown_timer.start()
	
	# Apply damage to player
	player.take_damage(damage, global_position)
	
	# Add a little lunge effect - use cached direction
	velocity += direction_to_player * 100

func _on_stun_timer_timeout() -> void:
	if current_state == EnemyState.STUNNED:
		transition_to_state(EnemyState.CHASING if player else EnemyState.IDLE)

func _on_attack_cooldown_timer_timeout() -> void:
	can_attack = true

# Virtual method for death behavior
func die() -> void:
	transition_to_state(EnemyState.DEAD)
	
	# Disable collisions
	if collision_shape:
		collision_shape.set_deferred("disabled", true)
	set_collision_layer_value(1, false)  
	
	# Emit signal
	enemy_died.emit()
	
	# Fade out effect
	if animated_sprite:
		var tween = create_tween()
		tween.tween_property(animated_sprite, "modulate", Color(1, 1, 1, 0), 0.5)
		tween.tween_callback(queue_free)

func transition_to_state(new_state: EnemyState) -> void:
	# Skip if state is unchanged
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
