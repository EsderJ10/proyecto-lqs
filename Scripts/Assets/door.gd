extends StaticBody2D
class_name Door

# State Machine
enum DoorState { CLOSED, OPENING, OPENED }
var current_state: DoorState = DoorState.CLOSED

# Node references
@export var auto_register_enemies: bool = true
@export var open_when_cleared: bool = true

@export_group("Components")
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var open_timer: Timer = $OpenTimer

# Variables
var active_enemies: int = 0
var registered_enemies: Array[Enemy] = []
var animation_durations: Dictionary = {}

func _ready() -> void:
	set_state(DoorState.CLOSED)
	
	# Connect timer signal properly
	if open_timer and !open_timer.timeout.is_connected(_on_open_timer_timeout):
		open_timer.timeout.connect(_on_open_timer_timeout)
	
	# Cache animation durations
	cache_animation_durations()
	
	# Wait one frame to ensure all enemies are initialized
	await get_tree().process_frame
	
	if auto_register_enemies:
		register_all_enemies()

func _exit_tree() -> void:
	# Clean up signal connections to prevent memory leaks
	for enemy in registered_enemies:
		if is_instance_valid(enemy) and enemy.enemy_died.is_connected(_on_enemy_died):
			enemy.enemy_died.disconnect(_on_enemy_died)
	registered_enemies.clear()

# Cached animation durations for better performance
func cache_animation_durations() -> void:
	if not animated_sprite or not animated_sprite.sprite_frames:
		return
		
	for anim_name in animated_sprite.sprite_frames.get_animation_names():
		var frames = animated_sprite.sprite_frames.get_frame_count(anim_name)
		var speed = animated_sprite.sprite_frames.get_animation_speed(anim_name)
		animation_durations[anim_name] = (frames / speed) if speed > 0 else 1.0

# Register all enemies in the scene
func register_all_enemies() -> void:
	var enemies = get_tree().get_nodes_in_group("enemies")
	active_enemies = 0
	
	for enemy in enemies:
		register_enemy(enemy)
	
	print("** Total of %d enemies" % active_enemies)

# Register an individual enemy
func register_enemy(enemy: Enemy) -> void:
	if not is_instance_valid(enemy):
		return
	
	# Only register if not already registered
	if not enemy in registered_enemies:
		registered_enemies.append(enemy)
		active_enemies += 1
		
		# Connect to the enemy_died signal
		if not enemy.enemy_died.is_connected(_on_enemy_died):
			enemy.enemy_died.connect(_on_enemy_died.bind(enemy))

# Sets the door state and updates visuals/physics
func set_state(new_state: DoorState) -> void:
	if current_state == new_state:
		return
	
	current_state = new_state
	
	match current_state:
		DoorState.CLOSED:
			animated_sprite.play("closed")
			collision_shape.set_deferred("disabled", false)
		DoorState.OPENING:
			animated_sprite.play("open_door")
			# Use cached animation duration
			var animation_duration = animation_durations.get("open_door", 1.0)
			open_timer.start(animation_duration)
		DoorState.OPENED:
			animated_sprite.play("opened")
			collision_shape.set_deferred("disabled", true)

# Called when any registered enemy dies
func _on_enemy_died(enemy: Enemy = null) -> void:
	# Remove from registered list if specified
	if is_instance_valid(enemy) and enemy in registered_enemies:
		registered_enemies.erase(enemy)
		enemy.enemy_died.disconnect(_on_enemy_died)
	
	active_enemies = max(0, active_enemies - 1)
	print("** Enemy defeated. Enemies left: %d" % active_enemies)
	
	# Check if we should open the door
	if open_when_cleared and active_enemies <= 0 and current_state == DoorState.CLOSED:
		open_door()

func open_door() -> void:
	if current_state == DoorState.CLOSED:
		set_state(DoorState.OPENING)

# Called when the opening animation completes
func _on_open_timer_timeout() -> void:
	if current_state == DoorState.OPENING:
		set_state(DoorState.OPENED)

# Manually register a new enemy
func add_enemy(enemy: Enemy) -> void:
	register_enemy(enemy)

# Force the door to open regardless of enemy count
func force_open() -> void:
	open_door()

# Manual override to close an open door
func close_door() -> void:
	if current_state != DoorState.CLOSED:
		set_state(DoorState.CLOSED)
