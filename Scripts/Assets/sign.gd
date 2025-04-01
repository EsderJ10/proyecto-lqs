extends StaticBody2D
class_name Sign

enum SignPerspective {
	FRONT,
	LEFT,
	RIGHT
}

# Parameters
@export var sign_perspective: SignPerspective = SignPerspective.FRONT
@export var sign_text: String = "I was wandering why the baseball was getting bigger. Then it hit me."
@export var interaction_distance: float = 53.0

# Nodes references
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var interaction_area: Area2D = $InteractionArea
@onready var interaction_shape: CollisionShape2D = $InteractionArea/InteractionShape

# UI Elements
var dialog_container: Control
var dialog_box: Panel
var label: Label
var is_dialog_open: bool = false
var font_color = Color(0.4, 0.25, 0.1, 1.0)  

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

func _ready() -> void:
	create_unique_shapes()
	initialize_sign()
	setup_dialog_ui()
	

func _process(_delta: float) -> void:
	if player_in_range and player:
		if Input.is_action_just_pressed("interact") and not is_dialog_open:
			show_dialog()
		elif Input.is_action_just_pressed("ui_close") and is_dialog_open:
			hide_dialog()

func create_unique_shapes() -> void:
	# Prevent shared resources
	collision_shape.shape = RectangleShape2D.new()
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
	match sign_perspective:
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
	
	var settings = DIMENSIONS.get(sign_perspective, DIMENSIONS[SignPerspective.FRONT])
	
	collision_rect_shape.size = settings["collision"]
	collision_shape.position = settings["offset"]
	
	interaction_rect_shape.size = settings["interaction"]
	interaction_shape.position = settings["offset"]

func setup_dialog_ui() -> void:
	# Create a container for all dialog elements
	dialog_container = Control.new()
	dialog_container.visible = false
	dialog_container.size = Vector2(get_viewport_rect().size.x, 100)
	dialog_container.position = Vector2(0, get_viewport_rect().size.y - 100)
	dialog_container.name = "DialogContainer"
	
	# Create dialog box with papyrus style
	dialog_box = Panel.new()
	dialog_box.size = Vector2(get_viewport_rect().size.x - 40, 80)  # Slightly smaller than container
	dialog_box.position = Vector2(20, 10)  # Centered in container
	
	# Create papyrus style for the panel
	var papyrus_style = StyleBoxFlat.new()
	papyrus_style.bg_color = Color(0.95, 0.9, 0.7, 1.0)  # Sandy papyrus color
	papyrus_style.border_width_left = 5
	papyrus_style.border_width_top = 5
	papyrus_style.border_width_right = 5
	papyrus_style.border_width_bottom = 5
	papyrus_style.border_color = Color(0.85, 0.75, 0.55, 1.0)  # Darker edge
	papyrus_style.corner_radius_top_left = 8
	papyrus_style.corner_radius_top_right = 8
	papyrus_style.corner_radius_bottom_left = 8
	papyrus_style.corner_radius_bottom_right = 8
	papyrus_style.shadow_color = Color(0.0, 0.0, 0.0, 0.3)
	papyrus_style.shadow_size = 5
	papyrus_style.shadow_offset = Vector2(3, 3)
	
	dialog_box.add_theme_stylebox_override("panel", papyrus_style)
	
	# Create text label
	label = Label.new()
	label.text = sign_text
	label.position = Vector2(15, 15)
	label.size = Vector2(dialog_box.size.x - 30, dialog_box.size.y - 30)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	
	label.add_theme_color_override("font_color", font_color)
	
	# Add label to dialog box
	dialog_box.add_child(label)
	
	# Add dialog box to container
	dialog_container.add_child(dialog_box)
	add_scroll_decorations(dialog_container, dialog_box)
	
	# Add container to scene tree
	var canvas_layer = CanvasLayer.new()
	canvas_layer.layer = 10  # Higher layer to display above other elements
	get_tree().root.call_deferred("add_child", canvas_layer)
	canvas_layer.add_child(dialog_container)

func add_scroll_decorations(container: Control, dialog: Panel) -> void:
	# Add left scroll cap
	var left_cap = Panel.new()
	left_cap.size = Vector2(15, dialog.size.y - 20)
	left_cap.position = Vector2(dialog.position.x - 5, dialog.position.y + 10)
	
	var left_style = StyleBoxFlat.new()
	left_style.bg_color = Color(0.85, 0.75, 0.55, 1.0)
	left_style.corner_radius_top_left = 10
	left_style.corner_radius_bottom_left = 10
	left_cap.add_theme_stylebox_override("panel", left_style)
	
	# Add right scroll cap
	var right_cap = Panel.new()
	right_cap.size = Vector2(15, dialog.size.y - 20)
	right_cap.position = Vector2(dialog.position.x + dialog.size.x - 10, dialog.position.y + 10)
	
	var right_style = StyleBoxFlat.new()
	right_style.bg_color = Color(0.85, 0.75, 0.55, 1.0)  # Darker brown
	right_style.corner_radius_top_right = 10
	right_style.corner_radius_bottom_right = 10
	right_cap.add_theme_stylebox_override("panel", right_style)
	
	container.add_child(left_cap)
	container.add_child(right_cap)
	
	# Ensure caps are behind the main dialog
	dialog.z_index = 1
	left_cap.z_index = 0
	right_cap.z_index = 0

func show_dialog() -> void:
	dialog_container.visible = true
	is_dialog_open = true
	
	var tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	dialog_container.position.y = get_viewport_rect().size.y  # Start from below screen
	tween.tween_property(dialog_container, "position:y", get_viewport_rect().size.y - 100, 0.3)
	
	# Add a small unroll animation
	dialog_box.scale = Vector2(1.0, 0.1)
	var scale_tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	scale_tween.tween_property(dialog_box, "scale", Vector2(1.0, 1.0), 0.25)

func hide_dialog() -> void:
	var tween = create_tween().set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_BACK)
	tween.tween_property(dialog_container, "position:y", get_viewport_rect().size.y, 0.2)
	
	# Add a roll up animation
	var scale_tween = create_tween().set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_CUBIC)
	scale_tween.tween_property(dialog_box, "scale", Vector2(1.0, 0.1), 0.2)
	
	tween.tween_callback(func(): 
		dialog_container.visible = false
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
	sign_perspective = perspective
	update_sign_appearance()
