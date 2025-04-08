extends StaticBody2D
class_name Sign

enum SignPerspective {
	FRONT,
	LEFT,
	RIGHT
}

# Parameters
@export var actual_perspective: SignPerspective = SignPerspective.FRONT
@export var sign_text: String = "I was wandering why the baseball was getting bigger. Then it hit me."
@export var interaction_distance: float = 53.0

# Nodes references
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var interaction_area: Area2D = $InteractionArea
@onready var interaction_shape: CollisionShape2D = $InteractionArea/InteractionShape

# UI Elements
var dialog_instance: Control = null
var dialog_box: Panel = null
var dialog_label: Label = null
var is_dialog_open: bool = false

# Cached animation parameters
var show_dialog_tween: Tween = null
var hide_dialog_tween: Tween = null

# State variables
var player_in_range: bool = false
var player: Player = null
var input_connected: bool = false

# Constants for collision and interaction shapes
const DIMENSIONS = {
	SignPerspective.FRONT: {
		"collision": Vector2(30, 30),
		"interaction": Vector2(50, 50),
		"offset": Vector2.ZERO
	},
	SignPerspective.LEFT: {
		"collision": Vector2(30, 30),
		"interaction": Vector2(30, 30),
		"offset": Vector2(-4, 0)
	},
	SignPerspective.RIGHT: {
		"collision": Vector2(30, 30),
		"interaction": Vector2(30, 30),
		"offset": Vector2(4, 0)
	}
}

func _ready() -> void:
	initialize_sign()
	
	# Connect to viewport size changed signal
	get_viewport().size_changed.connect(_on_viewport_size_changed)

func _notification(what: int) -> void:
	if what == NOTIFICATION_PREDELETE:
		_cleanup_resources()

func _cleanup_resources() -> void:
	# Remove any input handlers
	_unregister_input_handlers()
	
	# Clean up dialog resources
	var dialog_manager = DialogManager.get_instance()
	dialog_manager.remove_dialog(get_instance_id())
	
	# Clean up any remaining tweens
	if show_dialog_tween and show_dialog_tween.is_running():
		show_dialog_tween.kill()
	if hide_dialog_tween and hide_dialog_tween.is_running():
		hide_dialog_tween.kill()

# Input processing - replaces the previous _process function
func _input(event: InputEvent) -> void:
	if not player_in_range:
		return
		
	if event.is_action_pressed("interact") and not is_dialog_open:
		show_dialog()
	elif event.is_action_pressed("ui_close") and is_dialog_open:
		hide_dialog()

func initialize_sign() -> void:
	update_sign_appearance()

func update_sign_appearance() -> void:
	var animation_name = _get_perspective_name()
	
	if animated_sprite.sprite_frames.has_animation(animation_name):
		animated_sprite.play(animation_name)
	else:
		push_warning("* SIGN: Missing animation '%s'" % animation_name)
		# Fallback to a default animation if available
		if animated_sprite.sprite_frames.has_animation("front"):
			animated_sprite.play("front")
	
	update_shapes()

func _get_perspective_name() -> String:
	match actual_perspective:
		SignPerspective.FRONT:
			return "front"
		SignPerspective.LEFT:
			return "left"
		SignPerspective.RIGHT:
			return "right"
		_:
			return "front" # Default fallback

func update_shapes() -> void:
	var collision_rect_shape = collision_shape.shape as RectangleShape2D
	var interaction_rect_shape = interaction_shape.shape as RectangleShape2D
	
	if not collision_rect_shape or not interaction_rect_shape:
		push_error("* SIGN: Shape resources not properly created in editor")
		return
	
	var settings = DIMENSIONS.get(actual_perspective, DIMENSIONS[SignPerspective.FRONT])
	
	collision_rect_shape.size = settings["collision"]
	collision_shape.position = settings["offset"]
	
	interaction_rect_shape.size = settings["interaction"]
	interaction_shape.position = settings["offset"]

func _on_viewport_size_changed() -> void:
	# Update dialog positioning if open
	if is_dialog_open and dialog_instance:
		_position_dialog()

func _position_dialog() -> void:
	# Calculate position based on current viewport size
	var viewport_size = get_viewport_rect().size
	dialog_instance.position.y = viewport_size.y - 100
	
	# Center horizontally
	dialog_instance.position.x = (viewport_size.x - dialog_box.size.x) / 2

func _register_input_handlers() -> void:
	# Instead of connecting callable, we'll use the _input function
	# The _input function will check player_in_range
	input_connected = true
	set_process_input(true)

func _unregister_input_handlers() -> void:
	input_connected = false
	set_process_input(false)

func _create_dialog_if_needed() -> void:
	if not dialog_instance:
		var dialog_manager = DialogManager.get_instance()
		dialog_instance = dialog_manager.create_dialog(get_instance_id(), sign_text)
		dialog_box = dialog_instance.get_node("DialogBox")
		dialog_label = dialog_instance.get_node_or_null("DialogBox/Label")
		
		# Pre-configure tweens
		_setup_dialog_tweens()

func _setup_dialog_tweens() -> void:
	# Show dialog tween
	show_dialog_tween = create_tween()
	show_dialog_tween.set_parallel()
	
	var viewport_size = get_viewport_rect().size
	show_dialog_tween.tween_property(dialog_instance, "position:y", viewport_size.y - 100, 0.2)
	show_dialog_tween.set_ease(Tween.EASE_OUT)
	show_dialog_tween.set_trans(Tween.TRANS_BACK)
	
	show_dialog_tween.tween_property(dialog_box, "scale", Vector2(1.0, 1.0), 0.25)
	show_dialog_tween.set_ease(Tween.EASE_OUT)
	show_dialog_tween.set_trans(Tween.TRANS_CUBIC)
	
	show_dialog_tween.stop()
	
	# Hide dialog tween
	hide_dialog_tween = create_tween()
	hide_dialog_tween.set_parallel()
	
	hide_dialog_tween.tween_property(dialog_instance, "position:y", viewport_size.y, 0.2)
	hide_dialog_tween.set_ease(Tween.EASE_IN)
	hide_dialog_tween.set_trans(Tween.TRANS_BACK)
	
	hide_dialog_tween.tween_property(dialog_box, "scale", Vector2(1.0, 0.1), 0.2)
	hide_dialog_tween.set_ease(Tween.EASE_IN)
	hide_dialog_tween.set_trans(Tween.TRANS_CUBIC)
	
	# Add callback after animations
	hide_dialog_tween.chain().tween_callback(func(): 
		dialog_instance.visible = false
		is_dialog_open = false
	)
	
	hide_dialog_tween.stop()

func show_dialog() -> void:
	_create_dialog_if_needed()
	
	# Reset any running tweens
	if hide_dialog_tween and hide_dialog_tween.is_running():
		hide_dialog_tween.stop()
	
	dialog_instance.visible = true
	is_dialog_open = true
	
	# Reset initial properties
	var viewport_size = get_viewport_rect().size
	dialog_instance.position.y = viewport_size.y
	dialog_box.scale = Vector2(1.0, 0.1)
	
	# Position horizontally
	dialog_instance.position.x = (viewport_size.x - dialog_box.size.x) / 2
	
	# Start the show animation
	show_dialog_tween.restart()

func hide_dialog() -> void:
	if not dialog_instance:
		return
		
	# Reset any running tweens
	if show_dialog_tween and show_dialog_tween.is_running():
		show_dialog_tween.stop()
		
	# Start the hide animation  
	hide_dialog_tween.restart()

func _on_interaction_area_body_entered(body: Node2D) -> void: 
	if body is Player:
		player_in_range = true
		player = body
		_register_input_handlers()

func _on_interaction_area_body_exited(body: Node2D) -> void:
	if body is Player:
		player_in_range = false
		player = null
		_unregister_input_handlers()
		
		if is_dialog_open:
			hide_dialog()

func set_perspective(perspective: SignPerspective) -> void:
	actual_perspective = perspective
	update_sign_appearance()
