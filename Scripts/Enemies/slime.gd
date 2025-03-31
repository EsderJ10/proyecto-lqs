extends Enemy
class_name Slime

# Signals
signal slime_died

# Node references
@onready var animation_player: AnimationPlayer = $AnimationPlayer if has_node("AnimationPlayer") else null

func _ready() -> void:
	# Add to group for easier management
	add_to_group("enemies")
	
	# Parent class handles initialization through _ready and initialize()
	super._ready()

func initialize() -> void:
	super.initialize()


# Override update_animation with slime-specific animations
func update_animation() -> void:
	if not is_instance_valid(animated_sprite):
		return
		
	match current_state:
		EnemyState.DEAD:
			animated_sprite.play("death")
			return
			
		EnemyState.STUNNED:
			animated_sprite.play("hurt")
			return
	
	# Determine animation based on movement
	if velocity.length() > 10:
		var direction = get_direction_name(velocity)
		animated_sprite.play("move_" + direction)
	else:
		# Use face direction when idle
		var face_direction = get_player_direction() if is_instance_valid(player) else Vector2.DOWN
		animated_sprite.play("idle_" + get_direction_name(face_direction))

# Override attack_player with slime-specific attack behavior
func attack_player() -> void:
	# Call parent implementation
	super.attack_player()
	
	# Add slime-specific attack behavior
	if is_instance_valid(animated_sprite):
		animated_sprite.play("attack")

# Override die with slime-specific death behavior
func die() -> void:
	# Call parent implementation
	super.die()
	
	# Emit slime-specific signal
	slime_died.emit()
