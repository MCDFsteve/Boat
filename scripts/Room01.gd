@tool
extends Node2D

@onready var enemies_container = $Enemies
@onready var items_container = $Items
@onready var exits_container = $Exits
@onready var background_sprite = $Background/BackgroundSprite
@onready var wall_collisions = $WallCollisions

var room_id: String = "room01"
var room_data: Dictionary
var is_cleared: bool = false
var door_areas: Array = []
var is_setting_up: bool = false
var player_reference: CharacterBody2D  # Player引用，用于敌人瞄准等

# 背景相关信息
var background_scale: float = 1.0
var background_offset: Vector2 = Vector2.ZERO
var background_size: Vector2 = Vector2.ZERO

var enemy_scenes = {
	"enemy_fly": preload("res://scenes/enemies/EnemyFly.tscn"),
	"enemy_spider": preload("res://scenes/enemies/EnemySpider.tscn"),
	"boss_spider": preload("res://scenes/enemies/BossSpider.tscn")
}

var item_scenes = {
	"heart": preload("res://scenes/items/Heart.tscn"),
	"key": preload("res://scenes/items/Key.tscn")
}

# 直接编辑的墙壁配置 - 编辑器修改这些参数就会直接保存
@export_group("墙壁开关")
@export var top_wall_enabled: bool = true : set = set_top_wall_enabled
@export var bottom_wall_enabled: bool = true : set = set_bottom_wall_enabled
@export var left_wall_enabled: bool = true : set = set_left_wall_enabled
@export var right_wall_enabled: bool = true : set = set_right_wall_enabled

func _ready():
	# 统一的初始化逻辑
	setup_background_unified()
	# 墙壁状态由scene file中的节点直接控制，不需要额外设置
	
	if not Engine.is_editor_hint():
		# 游戏模式：连接房间切换信号，等待GameManager提供房间数据
		if not GameManager.room_changed.is_connected(_on_room_changed):
			GameManager.room_changed.connect(_on_room_changed)
		# 不在这里立即设置游戏逻辑，等待GameManager的房间数据

func setup_background_unified():
	# 统一的背景设置逻辑，编辑器和游戏都使用
	if background_sprite:
		var texture = load("res://assets/background/room01.png")
		if texture:
			background_sprite.texture = texture
			
			# 使用固定的屏幕尺寸，避免编辑器和游戏不一致
			var screen_size = Vector2(1280, 720)
			var texture_size = texture.get_size()
			
			# 使用全局配置的游戏缩放
			if GlobalConfig:
				background_scale = GlobalConfig.game_scale_multiplier
			else:
				background_scale = 8.0  # 后备默认值
			background_sprite.scale = Vector2(background_scale, background_scale)
			
			# 计算实际显示尺寸
			background_size = texture_size * background_scale
			
			# 计算居中偏移量
			background_offset = (screen_size - background_size) * 0.5
			background_sprite.position = background_offset + background_size * 0.5
			
			# 只在游戏模式下更新全局配置
			if not Engine.is_editor_hint():
				GlobalConfig.update_scale_config(background_scale, background_offset)
	
	# 更新场景中门的缩放
	update_doors_scale()

# 简化的墙壁开关setter方法
func set_top_wall_enabled(value: bool):
	top_wall_enabled = value
	if Engine.is_editor_hint() and wall_collisions:
		var wall_node = wall_collisions.get_node_or_null("TopWall")
		if wall_node:
			wall_node.visible = value
			wall_node.set_collision_layer(1 if value else 0)
			wall_node.set_collision_mask(1 if value else 0)

func set_bottom_wall_enabled(value: bool):
	bottom_wall_enabled = value
	if Engine.is_editor_hint() and wall_collisions:
		var wall_node = wall_collisions.get_node_or_null("BottomWall")
		if wall_node:
			wall_node.visible = value
			wall_node.set_collision_layer(1 if value else 0)
			wall_node.set_collision_mask(1 if value else 0)

func set_left_wall_enabled(value: bool):
	left_wall_enabled = value
	if Engine.is_editor_hint() and wall_collisions:
		var wall_node = wall_collisions.get_node_or_null("LeftWall")
		if wall_node:
			wall_node.visible = value
			wall_node.set_collision_layer(1 if value else 0)
			wall_node.set_collision_mask(1 if value else 0)

func set_right_wall_enabled(value: bool):
	right_wall_enabled = value
	if Engine.is_editor_hint() and wall_collisions:
		var wall_node = wall_collisions.get_node_or_null("RightWall")
		if wall_node:
			wall_node.visible = value
			wall_node.set_collision_layer(1 if value else 0)
			wall_node.set_collision_mask(1 if value else 0)

func setup_game_logic():
	if is_setting_up:
		return
	is_setting_up = true
	
	# 重置房间清理状态
	is_cleared = false
	
	# 清理房间
	clear_room_deferred()
	await get_tree().process_frame
	
	# 确保墙壁状态正确应用到游戏中
	apply_wall_states_to_game()
	
	# 隐藏所有门（等待房间清理完成后再显示）
	hide_all_doors()
	
	spawn_enemies()
	spawn_items()
	
	# 检查是否是已清理的房间
	if room_data.has("enemies") and room_data.enemies.size() == 0:
		is_cleared = true
		# 如果房间已经清理，立即生成随机门
		generate_random_doors()
	
	# 特殊处理：初始房间总是显示门（玩家需要能够离开）
	var room_coord = GameManager.current_room_coordinate
	if room_coord == Vector2(0, 0):
		generate_random_doors()
	
	is_setting_up = false

func apply_wall_states_to_game():
	# 确保游戏运行时墙壁状态与@export参数一致
	if wall_collisions:
		var walls = [
			{"node": "TopWall", "enabled": top_wall_enabled},
			{"node": "BottomWall", "enabled": bottom_wall_enabled},
			{"node": "LeftWall", "enabled": left_wall_enabled},
			{"node": "RightWall", "enabled": right_wall_enabled}
		]
		
		for wall_data in walls:
			var wall_node = wall_collisions.get_node_or_null(wall_data.node)
			if wall_node:
				wall_node.visible = wall_data.enabled
				wall_node.set_collision_layer(1 if wall_data.enabled else 0)
				wall_node.set_collision_mask(1 if wall_data.enabled else 0)

func clear_room_deferred():
	# 安全删除敌人
	for child in enemies_container.get_children():
		child.queue_free()
	# 安全删除物品
	for child in items_container.get_children():
		child.queue_free()
	
	await get_tree().process_frame

func spawn_enemies():
	if not room_data.has("enemies"):
		return
	
	var enemies = room_data.enemies
	if enemies.size() == 0:
		return
	
	for enemy_config in enemies:
		var enemy_type = enemy_config.type
		if enemy_scenes.has(enemy_type):
			var enemy = enemy_scenes[enemy_type].instantiate()
			enemies_container.add_child(enemy)
			
			if enemy_config.has("position"):
				var normalized_pos = Vector2(enemy_config.position[0], enemy_config.position[1])
				enemy.position = convert_normalized_to_screen_position(normalized_pos)
			else:
				enemy.position = Vector2(640, 360)  # 固定中心位置
			
			enemy.scale = GlobalConfig.get_entity_scale()
			
			if enemy_config.has("health"):
				enemy.health = enemy_config.health
				if enemy.has_method("update_health_display"):
					enemy.update_health_display()
			
			# 设置Player引用作为目标
			if player_reference and enemy.has_method("set_target"):
				enemy.set_target(player_reference)
			
			enemy.connect("enemy_died", _on_enemy_died)

func spawn_items():
	if not room_data.has("items"):
		return
	
	var items = room_data.items
	if items.size() == 0:
		return
	
	for item_config in items:
		var item_type = item_config.type
		if item_scenes.has(item_type):
			var item = item_scenes[item_type].instantiate()
			items_container.add_child(item)
			
			if item_config.has("position"):
				var normalized_pos = Vector2(item_config.position[0], item_config.position[1])
				item.position = convert_normalized_to_screen_position(normalized_pos)
			else:
				item.position = Vector2(640, 360)  # 固定中心位置
			
			item.scale = GlobalConfig.get_entity_scale()

func convert_normalized_to_screen_position(normalized_pos: Vector2) -> Vector2:
	# 将归一化坐标转换为屏幕内的实际位置
	var screen_size = Vector2(1280, 720)  # 使用固定屏幕尺寸
	var margin = screen_size * 0.1  # 10%边界
	var usable_area = screen_size - margin * 2
	
	var pos = Vector2(
		margin.x + normalized_pos.x * usable_area.x,
		margin.y + normalized_pos.y * usable_area.y
	)
	
	return pos

func get_door_areas() -> Array:
	return door_areas

func is_room_cleared() -> bool:
	return is_cleared

func _on_enemy_died():
	check_room_clear()

func check_room_clear():
	await get_tree().process_frame
	
	if enemies_container.get_child_count() == 0:
		if not is_cleared:
			is_cleared = true
			GameManager.mark_room_cleared()
			# 房间清理完成，生成随机门
			generate_random_doors()

func _on_room_changed(new_room_id: String, room_config: Dictionary, entry_direction: String):
	# 更新房间数据并设置游戏逻辑（适应所有房间类型）
	room_data = room_config
	call_deferred("setup_game_logic")

func clear_tears():
	var tears = get_tree().get_nodes_in_group("tears")
	for tear in tears:
		if tear and is_instance_valid(tear):
			tear.queue_free()
	
	for child in get_children():
		if child is Tear:
			child.queue_free()

func set_player_reference(player: CharacterBody2D):
	player_reference = player
	
	# 将Player引用传递给所有敌人
	if enemies_container:
		for enemy in enemies_container.get_children():
			if enemy.has_method("set_target"):
				enemy.set_target(player)

func update_doors_scale():
	# 更新场景中所有门的缩放，使用全局配置
	if exits_container:
		var game_scale = GlobalConfig.get_game_scale() if GlobalConfig else Vector2(8.0, 8.0)
		for door in exits_container.get_children():
			if door:
				door.scale = game_scale

func hide_all_doors():
	# 隐藏所有门并禁用它们的功能
	if exits_container:
		for door in exits_container.get_children():
			door.visible = false
			# 禁用门的碰撞检测
			var collision = door.get_node_or_null("CollisionShape2D")
			if collision:
				collision.disabled = true
			# 禁用门的检测区域
			var detection_area = door.get_node_or_null("DetectionArea")
			if detection_area:
				detection_area.monitoring = false
				detection_area.monitorable = false

func generate_random_doors():
	# 使用种子生成随机门
	# 为这个房间创建确定性的随机数生成器
	var room_coord = GameManager.current_room_coordinate
	var room_seed = SeedSystem.get_current_seed() + int(room_coord.x * 1000 + room_coord.y)
	
	var room_rng = RandomNumberGenerator.new()
	room_rng.seed = room_seed
	
	# 随机生成1-4个门
	var door_count = room_rng.randi_range(1, 4)
	
	# 可用的门位置（上、下、左、右）
	var available_directions = [0, 1, 2, 3]  # 对应Direction.DOWN, UP, LEFT, RIGHT
	
	# 随机选择门的方向
	var selected_directions = []
	for i in range(door_count):
		if available_directions.size() > 0:
			var random_index = room_rng.randi() % available_directions.size()
			var direction = available_directions[random_index]
			selected_directions.append(direction)
			available_directions.remove_at(random_index)
	
	# 显示选中的门，隐藏其他门
	if exits_container:
		var door_names = ["BottomDoor", "TopDoor", "LeftDoor", "RightDoor"]
		for i in range(door_names.size()):
			var door = exits_container.get_node_or_null(door_names[i])
			if door:
				var is_enabled = (i in selected_directions)
				door.visible = is_enabled
				
				# 启用/禁用门的碰撞检测
				var collision = door.get_node_or_null("CollisionShape2D")
				if collision:
					collision.disabled = not is_enabled
				
				# 启用/禁用门的检测区域
				var detection_area = door.get_node_or_null("DetectionArea")
				if detection_area:
					detection_area.monitoring = is_enabled
					detection_area.monitorable = is_enabled
	
	# 更新门区域数组
	setup_door_areas(selected_directions)

func setup_door_areas(selected_directions: Array):
	# 设置门区域，只包含生成的门
	door_areas = []
	
	var door_positions = [
		Vector2(640, 808),   # BottomDoor
		Vector2(644, -89),   # TopDoor  
		Vector2(-64, 361),   # LeftDoor
		Vector2(1343, 359)   # RightDoor
	]
	
	for direction in selected_directions:
		if direction < door_positions.size():
			door_areas.append(door_positions[direction]) 