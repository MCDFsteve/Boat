extends CharacterBody2D

signal enemy_died

@export var speed: float = 30.0
@export var health: int = 30
@export var damage: int = 8

@onready var sprite = $EnemyRect
@onready var move_timer = $MoveTimer
@onready var health_label = $HealthLabel

var player: Node2D
var move_direction: Vector2
var is_moving: bool = false
var knockback_velocity: Vector2 = Vector2.ZERO
var knockback_decay: float = 0.9

func _ready():
	add_to_group("enemies")
	# Player通过set_target方法设置，不在这里直接获取
	# player = get_parent().get_parent().get_node("Player")
	move_timer.wait_time = SeedSystem.randf_range(1.0, 3.0)
	move_timer.timeout.connect(_on_move_timer_timeout)
	move_timer.start()
	update_health_display()

func _physics_process(delta):
	if is_moving:
		var adjusted_speed = speed * GlobalConfig.entity_scale_multiplier
		velocity = move_direction * adjusted_speed
		
		# 应用击退效果
		velocity += knockback_velocity
		knockback_velocity *= knockback_decay
		
		# 使用Godot内置物理引擎处理碰撞
		move_and_slide()

func _on_move_timer_timeout():
	if player:
		move_direction = (player.global_position - global_position).normalized()
		is_moving = true
		
		# 移动一小段时间后停止
		await get_tree().create_timer(0.5).timeout
		is_moving = false
		
		# 重新设置计时器
		move_timer.wait_time = SeedSystem.randf_range(1.5, 4.0)
		move_timer.start()

func take_damage(amount: int):
	health -= amount
	update_health_display()
	sprite.color = Color.RED
	create_tween().tween_property(sprite, "color", Color(0.5, 0.2, 0, 1), 0.1)
	
	if health <= 0:
		die()

func apply_knockback(force: Vector2):
	knockback_velocity = force
	#print("Enemy ", name, " received knockback: ", force)

func update_health_display():
	if health_label:
		health_label.text = str(health)

func set_target(target: Node2D):
	# 设置玩家目标
	player = target

func die():
	enemy_died.emit()
	queue_free()

# 不再需要手动检查位置，Godot物理引擎会处理碰撞

func _on_area_2d_body_entered(body):
	if body.name == "Player":
		GameManager.take_damage(damage) 