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
	
	set_process_input(false)

func _notification(what: int) -> void:
	if what == NOTIFICATION_PREDELETE:
		_cleanup_resources()

func _cleanup_resources() -> void:
	_unregister_input_handlers()
	
	# Clean up dialog resources
	if dialog_instance:
		var dialog_manager = get_node("/root/dialog_Manager")
		if dialog_manager:
			dialog_manager.remove_dialog(get_instance_id())

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
	if is_dialog_open and dialog_instance:
		_position_dialog()

func _position_dialog() -> void:
	var viewport_size = get_viewport_rect().size
	dialog_instance.position.y = viewport_size.y - 100

func _register_input_handlers() -> void:
	input_connected = true
	set_process_input(true)

func _unregister_input_handlers() -> void:
	input_connected = false
	set_process_input(false)

func _create_dialog_if_needed() -> void:
	if not dialog_instance:
		var dialog_manager = get_node_or_null("/root/dialog_Manager")
		if not dialog_manager:
			push_error("* ERROR: DialogManager autoload is not available!")
			return
			
		dialog_instance = dialog_manager.create_dialog(get_instance_id(), sign_text)
		dialog_box = dialog_instance.get_node("DialogBox")
		dialog_label = dialog_instance.get_node_or_null("DialogBox/Label")

func show_dialog() -> void:
	_create_dialog_if_needed()
	
	if not dialog_instance:
		return
		
	dialog_instance.visible = true
	is_dialog_open = true
	
	# Reset initial properties
	var viewport_size = get_viewport_rect().size
	dialog_instance.position.y = viewport_size.y
	dialog_box.scale = Vector2(1.0, 0.1)
	
	var show_tween = create_tween()
	show_tween.set_parallel()
	
	show_tween.tween_property(dialog_instance, "position:y", viewport_size.y - 100, 0.2)
	show_tween.set_ease(Tween.EASE_OUT)
	show_tween.set_trans(Tween.TRANS_BACK)
	
	show_tween.tween_property(dialog_box, "scale", Vector2(1.0, 1.0), 0.25)
	show_tween.set_ease(Tween.EASE_OUT)
	show_tween.set_trans(Tween.TRANS_CUBIC)

func hide_dialog() -> void:
	if not dialog_instance:
		return
		
	var hide_tween = create_tween()
	hide_tween.set_parallel()
	
	var viewport_size = get_viewport_rect().size
	hide_tween.tween_property(dialog_instance, "position:y", viewport_size.y, 0.2)
	hide_tween.set_ease(Tween.EASE_IN)
	hide_tween.set_trans(Tween.TRANS_BACK)
	
	hide_tween.tween_property(dialog_box, "scale", Vector2(1.0, 0.1), 0.2)
	hide_tween.set_ease(Tween.EASE_IN)
	hide_tween.set_trans(Tween.TRANS_CUBIC)
	
	# Add callback after animations
	hide_tween.chain().tween_callback(func(): 
		dialog_instance.visible = false
		is_dialog_open = false
	)

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
