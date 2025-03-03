extends CharacterBody2D

@export var speed = 127.0
@onready var animated_sprite = $AnimatedSprite2D
enum Direction {
	UP,
	DOWN,
	LEFT,
	RIGHT
}

var current_dir: Direction = Direction.DOWN 

func _physics_process(delta: float) -> void:
	var motion: Vector2 = Vector2.ZERO
	
	match current_dir:
		Direction.UP:
			motion = Vector2.UP
			animated_sprite.play("up")
		Direction.DOWN:
			motion = Vector2.DOWN
			animated_sprite.play("down")
		Direction.LEFT:
			motion = Vector2.LEFT
			animated_sprite.play("left")
		Direction.RIGHT:
			motion = Vector2.RIGHT
			animated_sprite.play("right")
	
	if not animated_sprite.is_playing():
		animated_sprite.play()
	
	var movement: Vector2 = motion * speed * delta
	
	var collision = move_and_collide(movement)
	
	if collision:
		var new_dir: int = randi_range(0,3)
		while new_dir == current_dir:
			new_dir = randi_range(0,3)
		current_dir = Direction.values()[new_dir]
