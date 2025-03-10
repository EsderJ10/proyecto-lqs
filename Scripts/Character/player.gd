extends CharacterBody2D

@export var speed: int = 421
@export var is_attacking: bool = false
@export var attack_duration: float = 0.3
@export var attack_cooldown: float = 0.5

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var hitbox_attack: Area2D = $HitboxAttack
@onready var attack_cooldown_timer: Timer = $AttackCooldownTimer
@onready var attack_timer: Timer = $AttackTimer

var can_attack: bool = true
var current_direction: String = "down"

func _ready() -> void:
	hitbox_attack.monitoring = false
	
	attack_timer.timeout.connect(_on_attack_timer_timeout)
	attack_cooldown_timer.timeout.connect(_on_attack_cooldown_timer_timeout)
	hitbox_attack.body_entered.connect(_on_hitbox_attack_body_entered)

func _process(_float) -> void:
	if Input.is_action_just_pressed("player_attack") and can_attack:
		attack()

func _physics_process(_delta: float) -> void:
	var movement = Vector2.ZERO # Vector de movimiento del personaje (x,y)
	
	if !is_attacking:
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

func _on_hitbox_attack_body_entered(body: Node2D) -> void:
	if body.has_method("take_damage"):
		body.take_damage(1)

# Función para que los enemigos detecten al personaje/jugador
func player():
	pass
