extends CharacterBody2D

signal enemy_died

@export var speed: float = 50.0
@export var health: int = 20
@export var damage: int = 5

@onready var sprite = $EnemyRect
@onready var player_detector = $PlayerDetector
@onready var health_label = $HealthLabel

var player: Node2D
var direction: Vector2
var knockback_velocity: Vector2 = Vector2.ZERO
var knockback_decay: float = 0.9

func _ready():
	add_to_group("enemies")
	# Player通过set_target方法设置，不在这里直接获取
	# player = get_parent().get_parent().get_node("Player")
	update_health_display()

func _physics_process(delta):
	if player:
		direction = (player.global_position - global_position).normalized()
		var adjusted_speed = speed * GlobalConfig.entity_scale_multiplier
		velocity = direction * adjusted_speed
		
		# 应用击退效果
		velocity += knockback_velocity
		knockback_velocity *= knockback_decay
		
		# 使用Godot内置物理引擎处理碰撞
		move_and_slide()

func take_damage(amount: int):
	health -= amount
	update_health_display()
	# 简单的受伤反馈
	sprite.color = Color.RED
	create_tween().tween_property(sprite, "color", Color(1, 0, 0, 1), 0.1)
	
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