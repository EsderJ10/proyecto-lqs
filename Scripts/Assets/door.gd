extends StaticBody2D
class_name Door

# State Machine
enum DoorState { CLOSED, OPENING, OPENED }
var current_state: DoorState = DoorState.CLOSED

# Node references
@export var auto_register_slimes: bool = true
@export_group("Components")
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var open_timer: Timer = $OpenTimer

# Variables
var active_slimes: int = 0
var registered_slimes: Array[Slime] = []

func _ready() -> void:
	set_state(DoorState.CLOSED)
	
	if !open_timer.timeout.is_connected(_on_open_timer_timeout):
		open_timer.timeout.connect(_on_open_timer_timeout)
	
	if auto_register_slimes:
		register_all_slimes()

# Register all slimes in the scene
func register_all_slimes() -> void:
	var slimes = get_tree().get_nodes_in_group("slimes")
	for slime in slimes:
		register_slime(slime)

# Register an individual slime
func register_slime(slime: Slime) -> void:
	if slime == null or not is_instance_valid(slime):
		return
	
	# Only register if not already registered
	if not slime in registered_slimes:
		registered_slimes.append(slime)
		active_slimes += 1
		
		# Ensure slime is in the slimes group
		if not slime.is_in_group("slimes"):
			slime.add_to_group("slimes")
		
		# Connect to the died signal if not already connected
		if not slime.slime_died.is_connected(_on_slime_died):
			slime.slime_died.connect(_on_slime_died)

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
			# Calculate animation duration
			var animation_duration = _calculate_animation_duration("open_door")
			open_timer.start(animation_duration)
		DoorState.OPENED:
			animated_sprite.play("opened")
			collision_shape.set_deferred("disabled", true)

# Calculate animation duration in seconds
func _calculate_animation_duration(animation_name: String) -> float:
	var frames = animated_sprite.sprite_frames.get_frame_count(animation_name)
	var speed = animated_sprite.sprite_frames.get_animation_speed(animation_name)
	
	return (frames / speed)

func _on_slime_died() -> void:
	active_slimes = max(0, active_slimes - 1)
	
	# Check if we should open the door
	if active_slimes <= 0 and current_state == DoorState.CLOSED:
		open_door()

func open_door() -> void:
	if current_state == DoorState.CLOSED:
		set_state(DoorState.OPENING)

# Called when the opening animation should be complete
func _on_open_timer_timeout() -> void:
	if current_state == DoorState.OPENING:
		set_state(DoorState.OPENED)
