class_name Player extends CharacterBody2D

@export var run_speed: float = 100.0
@export var sprint_speed: float = 200.0
@export var jump_force: float = 400.0
@export var wall_impulse_force: float = 100.0
@export var slide_force: float = 400.0
@export var slide_cooldown_time: int = 200
@export var slide_max_duration_time: int = 250
@export var aceleration: float = 800.0
@export var deceleration: float = 1000.0
@export var deceleration_on_wall: float = 500.0
@export_range(0, 1) var decelerate_on_jump_release: float = 0.5
@export_range(0, 1) var decelerate_on_slide_release: float = 0.7

@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var sprite: Sprite2D = $Sprite2D

enum PlayerState {
	IDLE,
	RUNNING,
	SPRINTING,
	RISING,
	FALLING,
	SLIDING,
	WALL_SLIDING,
}

var player_state: int = PlayerState.IDLE
var direction: Vector2 = Vector2.ZERO
var speed: float = run_speed
var isSliding: bool = false
var slide_start_time: int = 0
var slide_finish_time: int = 0
var slide_direction: int = 0

func _ready() -> void:
	pass

func _process(delta: float) -> void:
	pass

func _physics_process(delta: float) -> void:
	# Add the gravity.
	if not is_on_floor():
		if is_on_wall() and velocity.y >= 0:
			velocity += Vector2(get_gravity().x, get_gravity().y - deceleration_on_wall) * delta
		else:
			velocity += get_gravity() * delta
	
	direction.x = Input.get_axis("left", "right")
	
	# Handle jump.
	if Input.is_action_just_pressed("jump") and (is_on_floor() or is_on_wall()):
		if is_on_wall():
			velocity.x = -direction.x * wall_impulse_force
		velocity.y = -jump_force
		
	if Input.is_action_just_released("jump") and velocity.y < 0:
		velocity.y *= decelerate_on_jump_release
	
	if is_on_floor():
		if Input.is_action_pressed("sprint") and is_on_floor():
			speed = sprint_speed
		else:
			speed = run_speed
	
	if direction.x:
		sprite.set_flip_h(true if direction.x == -1 else false)
		velocity.x = move_toward(velocity.x, direction.x*speed, aceleration*delta)
	else:
		velocity.x = move_toward(velocity.x, 0, deceleration*delta)
	
	if Input.is_action_just_pressed("slide") and is_on_floor() and direction.x and not isSliding and Time.get_ticks_msec() - slide_finish_time > slide_cooldown_time:
		isSliding = true
		slide_direction = direction.x
		slide_start_time = Time.get_ticks_msec()
	
	if isSliding:
		if Input.is_action_just_released("slide") or is_on_wall() or Time.get_ticks_msec() - slide_start_time > slide_max_duration_time:
			velocity.x *= decelerate_on_slide_release
			isSliding = false
			slide_finish_time = Time.get_ticks_msec()
		else:
			velocity.x = slide_direction * slide_force
	
	move_and_slide()
	
	if update_state():
		update_animation()

func update_state() -> bool:
	var new_state: int
	
	if isSliding:
		new_state = PlayerState.SLIDING	
	elif not is_on_floor():
		if is_on_wall() and velocity.y >= 0:
			new_state = PlayerState.WALL_SLIDING
		elif velocity.y <= 0:
			new_state = PlayerState.RISING
		elif velocity.y > 0:
			new_state = PlayerState.FALLING
	elif direction.x == 0:
		new_state = PlayerState.IDLE
	elif speed == run_speed:
		new_state = PlayerState.RUNNING
	elif speed == sprint_speed:
		new_state = PlayerState.SPRINTING
	
	if new_state != player_state:
		player_state = new_state
		return true
	
	return false

func update_animation() -> void:
	match player_state:
		PlayerState.IDLE:
			animation_player.play("idle")
		PlayerState.RUNNING:
			animation_player.play("running")
		PlayerState.SPRINTING:
			animation_player.play("sprinting")
		PlayerState.RISING:
			animation_player.play("rising")
		PlayerState.FALLING:
			animation_player.play("falling")
		PlayerState.SLIDING:
			animation_player.play("sliding")
		PlayerState.WALL_SLIDING:
			animation_player.play("wall_sliding")
