class_name Tear
extends Area2D

# 子弹属性，可以从外部设置
var direction: Vector2 = Vector2.ZERO
var speed: float = 1200.0  # 提高默认速度
var damage: int = 10
var lifetime: float = 1.5
var knockback_force: float = 100.0

# 弹道效果
var bullet_gravity: float = 50.0  # 重力加速度 - 大幅降低，让子弹表现更像子弹而不是液体
var velocity: Vector2 = Vector2.ZERO  # 当前速度

# 内部变量
var has_hit: bool = false

func _ready():
	# 添加到tears组
	add_to_group("tears")
	
	#print("Tear created: direction=", direction, " speed=", speed, " damage=", damage)
	
	# 连接信号
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)
	
	# 设置生命周期
	var timer = Timer.new()
	timer.wait_time = lifetime
	timer.one_shot = true
	timer.timeout.connect(_on_lifetime_expired)
	add_child(timer)
	timer.start()

func _physics_process(delta):
	# 子弹移动带有重力效果
	if direction != Vector2.ZERO:
		# 应用重力（只在Y轴）
		velocity.y += bullet_gravity * delta
		
		# 计算总的移动向量
		var movement = (direction * speed + velocity) * delta
		position += movement

# 设置子弹属性的函数
func setup(dir: Vector2, spd: float = 1200.0, dmg: int = 10, life: float = 1.5, knockback: float = 100.0):
	direction = dir.normalized()
	speed = spd
	damage = dmg
	lifetime = life
	knockback_force = knockback
	
	# 初始化速度（给向上射击的子弹一个初始向上的速度）
	if direction.y < 0:  # 向上射击
		velocity.y = direction.y * speed * 0.3  # 给一个初始向上速度
	
	#print("Tear setup with: direction=", direction, " speed=", speed, " damage=", damage)

func _on_body_entered(body):
	if has_hit:
		return
	
	# 忽略玩家
	if body.name == "Player":
		#print("Ignoring player collision")
		return
		
	#print("Tear hit body: ", body.name, " groups: ", body.get_groups())
	
	# 检查是否击中敌人
	if body.is_in_group("enemies"):
		#print("Hit enemy: ", body.name)
		if body.has_method("take_damage"):
			body.take_damage(damage)
			#print("Dealt ", damage, " damage to ", body.name)
		
		# 击退效果
		if body.has_method("apply_knockback"):
			body.apply_knockback(direction * knockback_force)
		elif body is CharacterBody2D:
			# 简单的击退效果
			body.velocity += direction * knockback_force
		
		has_hit = true
		destroy()
	
	# 如果撞到墙壁
	elif body is StaticBody2D:
		#print("Hit wall")
		has_hit = true
		destroy()

func _on_area_entered(area):
	if has_hit:
		return
	
	# 忽略玩家的Area2D组件
	if area.get_parent() and area.get_parent().name == "Player":
		#print("Ignoring player area collision")
		return
		
	#print("Tear hit area: ", area.name)
	
	# 检查是否是敌人的Area2D
	if area.is_in_group("enemies") or (area.get_parent() and area.get_parent().is_in_group("enemies")):
		var enemy = area.get_parent() if area.get_parent().is_in_group("enemies") else area
		#print("Hit enemy area: ", enemy.name)
		if enemy.has_method("take_damage"):
			enemy.take_damage(damage)
			#print("Dealt ", damage, " damage to ", enemy.name)
		
		# 击退效果
		if enemy.has_method("apply_knockback"):
			enemy.apply_knockback(direction * knockback_force)
		
		has_hit = true
		destroy()
		return
	
	# 对于其他类型的区域，暂时不销毁子弹
	#print("Hit unknown area, continuing...")

func _on_lifetime_expired():
	#print("Tear lifetime expired")
	destroy()

func destroy():
	# 添加销毁效果（可选）
	queue_free() 