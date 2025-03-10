extends CharacterBody2D

@export var speed: int = 421
@export var is_attacking: bool = false
@export var attack_duration: float = 0.3
@export var attack_cooldown: float = 0.5
@export var dash_speed: int = 1200 
@export var dash_duration: float = 0.3
@export var dash_cooldown: float = 1.0  

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var hitbox_attack: Area2D = $HitboxAttack
@onready var attack_cooldown_timer: Timer = $AttackCooldownTimer
@onready var attack_timer: Timer = $AttackTimer
@onready var dash_timer: Timer = $DashTimer
@onready var dash_cooldown_timer: Timer = $DashCooldownTimer

var can_attack: bool = true
var can_dash: bool = true
var is_dashing: bool = false
var current_direction: String = "down"
var dash_direction: Vector2 = Vector2.ZERO

func _ready() -> void:
	hitbox_attack.monitoring = false
	
	attack_timer.timeout.connect(_on_attack_timer_timeout)
	attack_cooldown_timer.timeout.connect(_on_attack_cooldown_timer_timeout)
	hitbox_attack.body_entered.connect(_on_hitbox_attack_body_entered)
	dash_timer.timeout.connect(_on_dash_timer_timeout)
	dash_cooldown_timer.timeout.connect(_on_dash_cooldown_timer_timeout)

func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("player_attack") and can_attack and !is_dashing:
		attack()
	
	# Check for dash input
	if Input.is_action_just_pressed("player_dash") and can_dash and !is_attacking:
		dash()

func _physics_process(_delta: float) -> void:
	var movement = Vector2.ZERO # Vector de movimiento del personaje (x,y)
	
	if !is_attacking and !is_dashing:
		if Input.is_action_pressed("move_right"):
			movement.x += 1
			animated_sprite.play("right")
			current_direction = "right"
		if Input.is_action_pressed("move_left"):
			movement.x -= 1
			animated_sprite.play("left")
			current_direction = "left"
		if Input.is_action_pressed("move_up"):
			movement.y -= 1
			animated_sprite.play("up")
			current_direction = "up"
		if Input.is_action_pressed("move_down"):
			movement.y += 1
			animated_sprite.play("down")
			current_direction = "down"
		
		if movement.length() > 0:
			movement = movement.normalized() * speed  # Normalizamos para evitar que vaya a mayor velocidad en diagonal
			
	elif is_dashing:
		movement = dash_direction * dash_speed
	
	velocity = movement
	move_and_slide()
	
func attack() -> void:
	is_attacking = true
	can_attack = false
	
	position_hitbox()
	hitbox_attack.monitoring = true
	
	# Inicializar temporizadores
	attack_timer.start()
	attack_cooldown_timer.start()

func dash() -> void:
	is_dashing = true
	can_dash = false
	
	dash_direction = Vector2.ZERO
	
	if Input.is_action_pressed("move_right"):
		dash_direction.x += 1
	if Input.is_action_pressed("move_left"):
		dash_direction.x -= 1
	if Input.is_action_pressed("move_up"):
		dash_direction.y -= 1
	if Input.is_action_pressed("move_down"):
		dash_direction.y += 1
		
	# If no keys are pressed, use instead the current direction
	if dash_direction == Vector2.ZERO:
		match current_direction:
			"right":
				dash_direction = Vector2(1, 0)
			"left":
				dash_direction = Vector2(-1, 0)
			"up":
				dash_direction = Vector2(0, -1)
			"down":
				dash_direction = Vector2(0, 1)
	
	# Normalize the direction
	if dash_direction.length() > 0:
		dash_direction = dash_direction.normalized()
	
	# TODO: Add dash animation.
	
	# Start timers
	dash_timer.start(dash_duration)
	dash_cooldown_timer.start(dash_cooldown)

func position_hitbox() -> void:
	# Adjust hitbox position/rotation based in the current direction
	match current_direction:
		"right":
			hitbox_attack.rotation_degrees = -90
			hitbox_attack.position = Vector2(20, 0)
		"left":
			hitbox_attack.rotation_degrees = 90
			hitbox_attack.position = Vector2(-20, 0)
		"up":
			hitbox_attack.rotation_degrees = 180
			hitbox_attack.position = Vector2(0, -20)
		"down":
			hitbox_attack.rotation_degrees = 0
			hitbox_attack.position = Vector2(0, 20)

func _on_attack_timer_timeout() -> void:
	# Disable the hitbox after attack
	hitbox_attack.monitoring = false
	is_attacking = false

func _on_attack_cooldown_timer_timeout() -> void:
	can_attack = true

func _on_dash_timer_timeout() -> void:
	is_dashing = false
	
func _on_dash_cooldown_timer_timeout() -> void:
	can_dash = true

func _on_hitbox_attack_body_entered(body: Node2D) -> void:
	if body.has_method("take_damage"):
		body.take_damage(1)

# Función para que los enemigos detecten al personaje/jugador
func player():
	pass
