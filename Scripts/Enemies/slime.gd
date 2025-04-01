extends Enemy
class_name Slime

# Node references
var animation_player: AnimationPlayer

func _ready() -> void:
	# Parent class handles initialization
	super._ready()
	
	animation_player = get_node_or_null("AnimationPlayer")
	
	# Connect parent signal to local method for custom behavior
	enemy_died.connect(_on_slime_died)

# Cache for animation names
var animation_cache = {
	"move_left": "move_left",
	"move_right": "move_right",
	"move_up": "move_up",
	"move_down": "move_down",
	"idle_left": "idle_left",
	"idle_right": "idle_right",
	"idle_up": "idle_up",
	"idle_down": "idle_down"
}

# Override update_animation with optimized animations
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
	
	# Use squared length comparison to avoid square root calculation
	if velocity.length_squared() > 100:
		var direction = get_direction_name(velocity)
		animated_sprite.play(animation_cache["move_" + direction])
	else:
		# Cache and reuse direction
		var face_direction
		if player:
			face_direction = get_direction_name(get_player_direction())
		else:
			face_direction = "down"
		animated_sprite.play(animation_cache["idle_" + face_direction])

# Override attack_player with slime-specific attack behavior
func attack_player() -> void:
	# Only proceed if in valid state
	if current_state == EnemyState.DEAD or not player:
		return
		
	# Call parent implementation
	super.attack_player()
	
	# Add slime-specific attack behavior
	if animated_sprite:
		animated_sprite.play("attack")

func _on_slime_died() -> void:
	if animation_player:
		animation_player.play("dissolve")
