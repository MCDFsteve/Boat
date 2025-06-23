extends CharacterBody2D

signal enemy_died

@export var speed: float = 40.0
@export var health: int = 100
@export var damage: int = 15

@onready var sprite = $BossRect
@onready var attack_timer = $AttackTimer
@onready var health_label = $HealthLabel

var player: Node2D
var is_attacking: bool = false
var knockback_velocity: Vector2 = Vector2.ZERO
var knockback_decay: float = 0.95  # Boss更抗击退

func _ready():
	add_to_group("enemies")
	# Player通过set_target方法设置，不在这里直接获取
	# player = get_parent().get_parent().get_node("Player")
	attack_timer.wait_time = 2.0
	attack_timer.timeout.connect(_on_attack_timer_timeout)
	attack_timer.start()
	update_health_display()

func _physics_process(delta):
	if player and not is_attacking:
		var direction = (player.global_position - global_position).normalized()
		var adjusted_speed = speed * GlobalConfig.entity_scale_multiplier
		velocity = direction * adjusted_speed
		
		# 应用击退效果（Boss抗击退能力更强）
		velocity += knockback_velocity * 0.5
		knockback_velocity *= knockback_decay
		
		# 使用Godot内置物理引擎处理碰撞
		move_and_slide()

func _on_attack_timer_timeout():
	if player:
		charge_attack()

func charge_attack():
	is_attacking = true
	var charge_direction = (player.global_position - global_position).normalized()
	
	# 快速冲向玩家
	var tween = create_tween()
	tween.tween_method(charge_move, Vector2.ZERO, charge_direction * 200, 0.3)
	await tween.finished
	
	is_attacking = false
	attack_timer.start()

func charge_move(offset: Vector2):
	velocity = offset * 10
	move_and_slide()

func take_damage(amount: int):
	health -= amount
	update_health_display()
	sprite.color = Color.RED
	create_tween().tween_property(sprite, "color", Color(0.8, 0, 0.8, 1), 0.2)
	
	if health <= 0:
		die()

func apply_knockback(force: Vector2):
	# Boss受到的击退效果减半
	knockback_velocity = force * 0.3
	#print("Boss ", name, " received reduced knockback: ", knockback_velocity)

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