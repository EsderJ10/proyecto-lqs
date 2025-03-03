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
			motion = Vector2(0, -1)
			animated_sprite.play("up")
		Direction.DOWN:
			motion = Vector2(0, 1)
			animated_sprite.play("down")
		Direction.LEFT:
			motion = Vector2(1, 0)
			animated_sprite.play("left")
		Direction.RIGHT:
			motion = Vector2(-1, 0)
			animated_sprite.play("right")
	
	if not animated_sprite.is_playing():
		animated_sprite.play()
	
	var movement: Vector2 = motion * speed
	
	if (get_slide_collision_count() > 0):
		print(get_slide_collision_count())
		var new_dir: int = randi() % 4
		print(new_dir)
		while new_dir == int(current_dir):
			new_dir = randi() % 4
			current_dir = new_dir
	
	move_and_collide(movement * delta)
