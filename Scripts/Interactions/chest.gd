extends StaticBody2D

# Parameters
@export_enum("Front", "Left", "Right") var chest_perspective: String = "Front"
@export var interaction_distance: float = 53.0

# Nodes references
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var interaction_area: Area2D = $InteractionArea
@onready var interaction_shape: CollisionShape2D = $InteractionArea/InteractionShape

# State variables
var is_open: bool = false
var player_in_range: bool = false
var player: Node2D = null

# Dimensions for different perspectives
const FRONT_COLLISION_SIZE: Vector2 = Vector2(58, 33)
const SIDE_COLLISION_SIZE: Vector2 = Vector2(31, 54)
const FRONT_INTERACTION_SIZE: Vector2 = Vector2(65, 35)
const SIDE_INTERACTION_SIZE: Vector2 = Vector2(35, 65)

func _ready() -> void:
	is_open = false
	# Create unique shape resources for this instance
	create_unique_shapes()
	# Apply the correct perspective
	update_chest_appearance()

func create_unique_shapes() -> void:
	# Create a new unique RectangleShape2D for collision
	var new_collision_shape = RectangleShape2D.new()
	collision_shape.shape = new_collision_shape
	
	# Create a new unique RectangleShape2D for interaction
	var new_interaction_shape = RectangleShape2D.new()
	interaction_shape.shape = new_interaction_shape

func _process(delta: float) -> void:
	if player_in_range and player and Input.is_action_just_pressed("open_chest"):
		open_chest()

func update_chest_appearance() -> void:
	var state = "closed"
	if is_open:
		state = "open"
	
	var animation_name = chest_perspective.to_lower() + "_" + state
	animated_sprite.play(animation_name)
	
	update_shapes()

func update_shapes() -> void:
	var collision_rect_shape = collision_shape.shape as RectangleShape2D
	
	if collision_rect_shape:
		match chest_perspective:
			"Front":
				collision_rect_shape.size = FRONT_COLLISION_SIZE
				collision_shape.position = Vector2(0, 0)
			"Left":
				collision_rect_shape.size = SIDE_COLLISION_SIZE
				collision_shape.position = Vector2(-4, 0)
			"Right":
				collision_rect_shape.size = SIDE_COLLISION_SIZE
				collision_shape.position = Vector2(4, 0)
	
	var interaction_rect_shape = interaction_shape.shape as RectangleShape2D
	
	if interaction_rect_shape:
		match chest_perspective:
			"Front":
				interaction_rect_shape.size = FRONT_INTERACTION_SIZE
				interaction_shape.position = Vector2(0, 0)
			"Left":
				interaction_rect_shape.size = SIDE_INTERACTION_SIZE
				interaction_shape.position = Vector2(-4, 0)
			"Right":
				interaction_rect_shape.size = SIDE_INTERACTION_SIZE
				interaction_shape.position = Vector2(4, 0)

func open_chest() -> void:
	if is_open:
		return
	
	is_open = true
	update_chest_appearance()
	
	# TODO: Implement sound effect
	
	# Animation
	var tween = create_tween()
	tween.tween_property(animated_sprite, "scale", Vector2(1.1, 1.1), 0.1)
	tween.tween_property(animated_sprite, "scale", Vector2(1.0, 1.0), 0.1)

func _on_interaction_area_body_entered(body: Node2D) -> void:
	if body.has_method("player"):
		player_in_range = true
		player = body

func _on_interaction_area_body_exited(body: Node2D) -> void:
	if body.has_method("player"):
		player_in_range = false
		player = null

func set_perspective(perspective: String) -> void:
	if perspective in ["Front", "Left", "Right"]:
		chest_perspective = perspective
		update_chest_appearance()
