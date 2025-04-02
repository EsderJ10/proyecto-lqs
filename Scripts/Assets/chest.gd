extends StaticBody2D
class_name Chest

# Signals
signal chest_opened(chest_position)

enum ChestPerspective {
	FRONT,
	LEFT,
	RIGHT
}

# Parameters
@export var chest_perspective: ChestPerspective = ChestPerspective.FRONT
@export var interaction_distance: float = 53.0

# Nodes references
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var interaction_area: Area2D = $InteractionArea
@onready var interaction_shape: CollisionShape2D = $InteractionArea/InteractionShape

# State variables
var is_open: bool = false
var player_in_range: bool = false
var player: Player = null

# Constants for collision and interaction shapes
const DIMENSIONS = {
	ChestPerspective.FRONT: {
		"collision": Vector2(58, 33),
		"interaction": Vector2(65, 35),
		"offset": Vector2.ZERO
	},
	ChestPerspective.LEFT: {
		"collision": Vector2(31, 54),
		"interaction": Vector2(35, 65),
		"offset": Vector2(-4, 0)
	},
	ChestPerspective.RIGHT: {
		"collision": Vector2(31, 54),
		"interaction": Vector2(35, 65),
		"offset": Vector2(4, 0)
	}
}

func _ready() -> void:
	create_unique_shapes()
	initialize_chest()

func _process(_delta: float) -> void:
	if player_in_range and player and Input.is_action_just_pressed("interact") and not is_open:
		open_chest()

func create_unique_shapes() -> void:
	# Prevent shared resources from chests
	collision_shape.shape = RectangleShape2D.new()
	interaction_shape.shape = RectangleShape2D.new()

func initialize_chest() -> void:
	is_open = false
	update_chest_appearance()

func update_chest_appearance() -> void:
	var state = "closed" if not is_open else "open"
	var animation_name = _get_perspective_name() + "_" + state
	
	if animated_sprite.sprite_frames.has_animation(animation_name):
		animated_sprite.play(animation_name)
	else:
		push_warning("CHEST: Missing animation '%s'" % animation_name)
		# Fallback to a default animation if available
		if animated_sprite.sprite_frames.has_animation("front_closed"):
			animated_sprite.play("front_closed")
	
	update_shapes()

func _get_perspective_name() -> String:
	match chest_perspective:
		ChestPerspective.FRONT:
			return "front"
		ChestPerspective.LEFT:
			return "left"
		ChestPerspective.RIGHT:
			return "right"
		_:
			return "front" # Default fallback

func update_shapes() -> void:
	var collision_rect_shape = collision_shape.shape as RectangleShape2D
	var interaction_rect_shape = interaction_shape.shape as RectangleShape2D
	
	if not collision_rect_shape or not interaction_rect_shape:
		push_error("CHEST: Shape resources not properly created")
		return
	
	var settings = DIMENSIONS.get(chest_perspective, DIMENSIONS[ChestPerspective.FRONT])
	
	collision_rect_shape.size = settings["collision"]
	collision_shape.position = settings["offset"]
	
	interaction_rect_shape.size = settings["interaction"]
	interaction_shape.position = settings["offset"]

func open_chest() -> void:
	if is_open:
		return
	
	is_open = true
	update_chest_appearance()
	play_open_animation()
	
	# Emit signal with chest position
	chest_opened.emit(global_position)

func play_open_animation() -> void:
	var tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_ELASTIC)
	tween.tween_property(animated_sprite, "scale", Vector2(1.1, 1.1), 0.1)
	tween.tween_property(animated_sprite, "scale", Vector2(1.0, 1.0), 0.1)

func _on_interaction_area_body_entered(body: Node2D) -> void: 
	if body is Player:
		player_in_range = true
		player = body

func _on_interaction_area_body_exited(body: Node2D) -> void:
	if body is Player:
		player_in_range = false
		player = null

func set_perspective(perspective: ChestPerspective) -> void:
	chest_perspective = perspective
	update_chest_appearance()
