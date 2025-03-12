extends StaticBody2D

@export_enum("Front", "Left", "Right") var chest_perspective: String = "Front"
@export var interaction_distance: float = 53.0

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var interaction_area: Area2D = $InteractionArea

var is_open: bool = false
var player_in_range: bool = false
var player: Node2D = null
var front_collision_size: Vector2 = Vector2(58, 33) 
var side_collision_size: Vector2 = Vector2(31, 54)   

func _ready() -> void:
	is_open = false
	update_chest_appearance()

func _process(_delta: float) -> void:
	if player_in_range and player and Input.is_action_just_pressed("open_chest"):
		open_chest()

func update_chest_appearance() -> void:
	var state = "closed"
	if is_open:
		state = "open"
	
	var animation_name = chest_perspective.to_lower() + "_" + state
	animated_sprite.play(animation_name)
	
	update_collision_shape()

func update_collision_shape() -> void:
	var rect_shape = collision_shape.shape as RectangleShape2D
	
	if rect_shape:
		match chest_perspective:
			"Front":
				rect_shape.size = front_collision_size
				collision_shape.position = Vector2(0, 0)
			"Left", "Right":
				rect_shape.size = side_collision_size
				if chest_perspective == "Left":
					collision_shape.position = Vector2(-4, 0)  
				else:
					collision_shape.position = Vector2(4, 0)   

func open_chest() -> void:
	if is_open:
		return
	
	is_open = true
	update_chest_appearance()
	
	# TODO: Implement sound effect
	
	# Todo: Implement animation
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
