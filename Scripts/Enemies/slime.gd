extends Enemy
class_name Slime

# Signals
signal slime_died

# Slime specific properties
@export_group("Movement")
@export var speed_value: int = 157
@export var max_speed_value: int = 211
@export var follow_smoothing_value: float = 5.0

@export_group("Combat")
@export var damage_value: int = 1
@export var attack_cooldown_value: float = 1.0
@export var stun_time_value: float = 0.2
@export var attack_range_value: float = 60.0 

@export_group("Health")
@export var health_points_value: int = 5
@export var hit_knockback_force_value: float = 200.0
@export var hit_flash_duration_value: float = 0.15

# Node references defined with @onready
@onready var slime_animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var slime_detection_area: Area2D = $DetectionArea
@onready var slime_collision_shape: CollisionShape2D = $DetectionArea/CollisionShape2D
@onready var slime_stun_timer: Timer = $StunTimer
@onready var slime_attack_cooldown_timer: Timer = $AttackCooldownTimer

func _ready() -> void:
	# Set properties from exported values
	speed = speed_value
	max_speed = max_speed_value
	follow_smoothing = follow_smoothing_value
	damage = damage_value
	attack_cooldown = attack_cooldown_value
	stun_time = stun_time_value
	attack_range = attack_range_value
	health_points = health_points_value
	hit_knockback_force = hit_knockback_force_value
	hit_flash_duration = hit_flash_duration_value
	
	# Assign node references before initializing
	animated_sprite = slime_animated_sprite
	detection_area = slime_detection_area
	collision_shape = slime_collision_shape
	stun_timer = slime_stun_timer
	attack_cooldown_timer = slime_attack_cooldown_timer
	
	# Initialize the enemy with node references already assigned
	initialize()
	
	# Slime-specific initialization
	add_to_group("slimes")

# Override initialize to customize setup if needed
func initialize() -> void:
	# Call parent's initialize to set up timers and signals
	super.initialize()
	
	# Add any slime-specific initialization here

func update_animation() -> void:
	if current_state == EnemyState.DEAD:
		# TODO: DEAD Animation
		return
		
	# Determine animation based on movement direction
	if velocity.length() > 10:  
		animated_sprite.play(get_direction_name(velocity))
	else:
		# Use the last direction when idle
		var face_direction = get_player_direction() if player and is_instance_valid(player) else Vector2.DOWN
		animated_sprite.play(get_direction_name(face_direction))

func die() -> void:
	# Call the parent implementation
	super.die()
	
	# Emit slime-specific signal
	slime_died.emit()
