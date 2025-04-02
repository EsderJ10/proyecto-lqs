extends StaticBody2D
class_name Sign

const DIALOG_SCENE = preload("res://Scenes/UI/dialog_scroll.tscn")

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
var viewport_size: Vector2

# State variables
var player_in_range: bool = false
var player: Player = null



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

# Shared dialog canvas layer
static var dialog_canvas_layer: CanvasLayer = null

func _ready() -> void:
	viewport_size = get_viewport_rect().size
	
	create_shapes_if_needed()
	initialize_sign()

func _process(_delta: float) -> void:
	if player_in_range and player:
		if Input.is_action_just_pressed("interact") and not is_dialog_open:
			show_dialog()
		elif Input.is_action_just_pressed("ui_close") and is_dialog_open:
			hide_dialog()

func create_shapes_if_needed() -> void:
	if not collision_shape.shape:
		collision_shape.shape = RectangleShape2D.new()
	if not interaction_shape.shape:
		interaction_shape.shape = RectangleShape2D.new()

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
		push_error("* SIGN: Shape resources not properly created")
		return
	
	var settings = DIMENSIONS.get(actual_perspective, DIMENSIONS[SignPerspective.FRONT])
	
	collision_rect_shape.size = settings["collision"]
	collision_shape.position = settings["offset"]
	
	interaction_rect_shape.size = settings["interaction"]
	interaction_shape.position = settings["offset"]

func get_or_create_canvas_layer() -> CanvasLayer:
	if not dialog_canvas_layer:
		dialog_canvas_layer = CanvasLayer.new()
		dialog_canvas_layer.layer = 10
		dialog_canvas_layer.name = "DialogLayer"
		get_tree().root.add_child(dialog_canvas_layer)
	return dialog_canvas_layer

func create_dialog_instance() -> void:
	if dialog_instance:
		return
		
	dialog_instance = DIALOG_SCENE.instantiate()
	get_or_create_canvas_layer().add_child(dialog_instance)
	
	# Node references
	dialog_box = dialog_instance.get_node("DialogBox")
	dialog_label = dialog_instance.get_node_or_null("DialogBox/Label")
	
	if dialog_label:
		dialog_label.text = sign_text
	
	# Initially hide the dialog
	dialog_instance.visible = false

func show_dialog() -> void:
	if not dialog_instance:
		create_dialog_instance()
	
	dialog_instance.visible = true
	is_dialog_open = true
	
	var tween = create_tween()
	
	# Position animation
	dialog_instance.position.y = viewport_size.y
	tween.set_parallel()
	tween.tween_property(dialog_instance, "position:y", viewport_size.y - 100, 0.2)
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_BACK)
	
	# Scale animation
	dialog_box.scale = Vector2(1.0, 0.1)
	tween.tween_property(dialog_box, "scale", Vector2(1.0, 1.0), 0.25)
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_CUBIC)

func hide_dialog() -> void:
	if not dialog_instance:
		return
		
	var tween = create_tween()
	
	# Position animation
	tween.set_parallel()
	tween.tween_property(dialog_instance, "position:y", viewport_size.y, 0.2)
	tween.set_ease(Tween.EASE_IN)
	tween.set_trans(Tween.TRANS_BACK)
	
	# Scale animation
	tween.tween_property(dialog_box, "scale", Vector2(1.0, 0.1), 0.2)
	tween.set_ease(Tween.EASE_IN)
	tween.set_trans(Tween.TRANS_CUBIC)
	
	# Separate sequence callback after all parallel animations
	tween.chain().tween_callback(func(): 
		dialog_instance.visible = false
		is_dialog_open = false
	)

func _on_interaction_area_body_entered(body: Node2D) -> void: 
	if body is Player:
		player_in_range = true
		player = body

func _on_interaction_area_body_exited(body: Node2D) -> void:
	if body is Player:
		player_in_range = false
		player = null
		if is_dialog_open:
			hide_dialog()

func set_perspective(perspective: SignPerspective) -> void:
	actual_perspective = perspective
	update_sign_appearance()
