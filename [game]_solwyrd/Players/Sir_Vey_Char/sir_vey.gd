extends CharacterBody2D

@export var speed: float = 300.0
@export var backflip_speed: float = 600.0 
@export var backflip_duration: float = 0.7

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D


var is_backflipping: bool = false
var is_recovering: bool = false        
var can_backflip: bool = true


var last_direction := Vector2.DOWN
var backflip_direction := Vector2.ZERO

func _physics_process(_delta: float) -> void:
	var current_direction := Vector2.ZERO
	current_direction.x = Input.get_axis("a", "d")
	current_direction.y = Input.get_axis("w", "s")

	if is_backflipping:
		if current_direction != Vector2.ZERO:
			backflip_direction = current_direction.normalized()
		velocity = backflip_direction * backflip_speed
		move_and_slide()
		return

	if is_recovering:
		velocity = Vector2.ZERO
		move_and_slide()
		return

	if Input.is_action_just_pressed("space") and can_backflip and current_direction != Vector2.ZERO:
		start_backflip(current_direction)
		return

	if current_direction != Vector2.ZERO:
		var move_dir = current_direction.normalized()
		velocity = move_dir * speed
		last_direction = move_dir
	else:
		velocity = velocity.move_toward(Vector2.ZERO, speed)

	move_and_slide()
	update_animation(current_direction)


func start_backflip(initial_dir: Vector2) -> void:
	is_backflipping = true
	can_backflip = false
	backflip_direction = initial_dir.normalized()
	
	play_backflip_animation(backflip_direction)

	var time_passed = 0.0
	while time_passed < backflip_duration:
		play_backflip_animation(backflip_direction)
		await get_tree().process_frame
		time_passed += get_process_delta_time()
	
	is_backflipping = false
	
	is_recovering = true
	update_animation(Vector2.ZERO) 
	await get_tree().create_timer(0.01).timeout
	is_recovering = false

	await get_tree().create_timer(1.3).timeout
	can_backflip = true


func play_backflip_animation(dir: Vector2) -> void:
	animated_sprite.flip_h = false
	if dir.y < 0:
		animated_sprite.play("backflip_back")
	elif dir.y > 0:
		animated_sprite.play("backflip_front")
	elif dir.x > 0:
		animated_sprite.play("backflip_right")
	elif dir.x < 0:
		animated_sprite.play("backflip_right")
		animated_sprite.flip_h = true


func update_animation(dir: Vector2) -> void:
	if dir != Vector2.ZERO:
		animated_sprite.flip_h = false
		
		if dir.y < 0 and dir.x > 0:
			animated_sprite.play("walk_back_left")
			animated_sprite.flip_h = true
		elif dir.y < 0 and dir.x < 0:
			animated_sprite.play("walk_back_left")
		elif dir.y > 0 and dir.x > 0:
			animated_sprite.play("walk_front_right")
		elif dir.y > 0 and dir.x < 0:
			animated_sprite.play("walk_front_right")
			animated_sprite.flip_h = true
			
		elif dir.y < 0:
			animated_sprite.play("walk_back")
		elif dir.y > 0:
			animated_sprite.play("walk_front")
		elif dir.x > 0:
			animated_sprite.play("walk_left_right")
		elif dir.x < 0:
			animated_sprite.play("walk_left_right")
			animated_sprite.flip_h = true

	else:
		animated_sprite.flip_h = false
		
		if last_direction.y < 0 and last_direction.x > 0:
			animated_sprite.play("idle_back_left")
			animated_sprite.flip_h = true
		elif last_direction.y < 0 and last_direction.x < 0:
			animated_sprite.play("idle_back_left")
		elif last_direction.y > 0 and last_direction.x > 0:
			animated_sprite.play("idle_front_right")
		elif last_direction.y > 0 and last_direction.x < 0:
			animated_sprite.play("idle_front_right")
			animated_sprite.flip_h = true
		elif last_direction.y < 0:
			animated_sprite.play("idle_back")
		elif last_direction.y > 0:
			animated_sprite.play("idle_front")
		elif last_direction.x > 0:
			animated_sprite.play("idle_left_right")
		elif last_direction.x < 0:
			animated_sprite.play("idle_left_right")
			animated_sprite.flip_h = true
