extends Enemy
class_name Slime

# Node references
@onready var animation_player: AnimationPlayer = $AnimationPlayer

const animation_cache: Dictionary = {
	"move_left": "slime_move_left",
	"move_right": "slime_move_right",
	"move_up": "slime_move_up",
	"move_down": "slime_move_down",
	"idle_left": "slime_idle_left",
	"idle_right": "slime_idle_right",
	"idle_up": "slime_idle_up",
	"idle_down": "slime_idle_down"
}

func initialize() -> void:
	super.initialize()
	
	# TODO: Check if is needed specify something about the slime

func _ready() -> void:
	super._ready()
	
	if not enemy_died.is_connected(_on_slime_died):
		enemy_died.connect(_on_slime_died)

func update_animation() -> void:
	if not animated_sprite:
		return
		
	match current_state:
		EnemyState.DEAD:
			animated_sprite.play("death")
			return
			
		EnemyState.STUNNED:
			animated_sprite.play("hurt")
			return
	
	var is_moving: bool = velocity.length_squared() > 100
	
	var direction: String
	if is_moving:
		direction = get_direction_name(velocity)
		animated_sprite.play(animation_cache["move_" + direction])
	else:
		# Only calculate player direction when needed
		direction = get_direction_name(get_player_direction())
		animated_sprite.play(animation_cache["idle_" + direction])

func attack_player() -> void:
	if current_state == EnemyState.DEAD or not player:
		return
		
	super.attack_player()
	
	if animated_sprite:
		animated_sprite.play("attack")

func _on_slime_died() -> void:
	if animation_player and animation_player.has_animation("dissolve"):
		animation_player.play("dissolve")
