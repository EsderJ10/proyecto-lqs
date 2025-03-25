extends Camera2D

## Parameters
@export_group("Camera Follow")
@export_range(1.0, 10.0, 0.5) var follow_speed: float = 4.0
@export_range(0.0, 1.0, 0.05) var look_ahead_factor: float = 0.2  # Movement prediction

@export_group("Screen Shake")
@export_range(1.0, 20.0, 0.5) var shake_fade: float = 5.0
@export_range(5.0, 50.0, 1.0) var max_shake_offset: float = 10.0
@export_range(0.01, 0.5, 0.01) var max_shake_roll: float = 0.1
@export_range(10.0, 100.0, 5.0) var noise_shake_speed: float = 30.0
@export_range(10.0, 200.0, 5.0) var noise_shake_strength: float = 60.0

## Variables
var shake_strength: float = 0.0
var noise := FastNoiseLite.new()
var noise_index: float = 0.0

## Lifecycle Methods
func _ready() -> void:
	# Initialize noise for screen shake
	noise.seed = randi()
	noise.frequency = 0.5

func _process(delta: float) -> void:
	_update_screen_shake(delta)

## Screen Shake Methods
func _update_screen_shake(delta: float) -> void:
	if shake_strength <= 0:
		# Reset camera when no shake
		offset = Vector2.ZERO
		rotation = 0.0
		return
	
	# Increment noise index
	noise_index += delta * noise_shake_speed
	
	# Generate noise-based shake
	var shake_x = noise.get_noise_2d(1, noise_index) * shake_strength * noise_shake_strength
	var shake_y = noise.get_noise_2d(100, noise_index) * shake_strength * noise_shake_strength
	
	# Apply the shake with clamping
	offset = Vector2(
		clamp(shake_x, -max_shake_offset, max_shake_offset),
		clamp(shake_y, -max_shake_offset, max_shake_offset)
	)
	rotation = noise.get_noise_2d(500, noise_index) * shake_strength * max_shake_roll
	
	# Reduce shake strength
	shake_strength = max(0, shake_strength - shake_fade * delta)

## Methods for Camera Effects
func add_trauma(amount: float) -> void:
	"""
	Add screen shake trauma. Amount is clamped between 0 and 1.
	Higher values create more intense shakes.
	"""
	shake_strength = min(shake_strength + amount, 1.0)

func start_room_transition(target_position: Vector2, duration: float = 0.5) -> void:
	"""
	Smoothly transition the camera to a new position.
	Useful for multi-room dungeons or scene changes.
	"""
	var tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(self, "global_position", target_position, duration)
