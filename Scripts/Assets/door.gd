extends StaticBody2D
class_name Door

# State Machine
enum DoorState { CLOSED, OPENING, OPENED }
var current_state: DoorState = DoorState.CLOSED

# Variables
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var open_timer: Timer = $OpenTimer 

# Slime tracking
var active_slimes: int = 0

func _ready() -> void:
	# Start with closed door
	current_state = DoorState.CLOSED
	animated_sprite.play("closed")
	
	
	# Connect the timer signal
	if !open_timer.timeout.is_connected(_on_open_timer_timeout):
		open_timer.timeout.connect(_on_open_timer_timeout)
	
	# Count all existing slimes in the scene
	var slimes = get_tree().get_nodes_in_group("slimes")
	active_slimes = slimes.size()
	
	# Connect to each slime's died signal
	for slime in slimes:
		if slime is Slime and not slime.slime_died.is_connected(_on_slime_died):
			slime.slime_died.connect(_on_slime_died)
			# Add slimes to the group if not already added
			if not slime.is_in_group("slimes"):
				slime.add_to_group("slimes")

func _on_slime_died() -> void:
	active_slimes -= 1
	
	# If all slimes are defeated, open the door
	if active_slimes <= 0:
		open_door()

func open_door() -> void:
	if current_state != DoorState.CLOSED:
		return
		
	current_state = DoorState.OPENING
	animated_sprite.play("open_door")
	
	# Time until the animation is finished
	open_timer.wait_time = animated_sprite.sprite_frames.get_animation_speed("open_door") * animated_sprite.sprite_frames.get_frame_count("open_door") / 300.0
	
	# Start the timer
	open_timer.start()

func _on_open_timer_timeout() -> void:
	if current_state == DoorState.OPENING:
		current_state = DoorState.OPENED
		animated_sprite.play("opened")
		
		# Disable collision to let player through
		collision_shape.set_deferred("disabled", true)
