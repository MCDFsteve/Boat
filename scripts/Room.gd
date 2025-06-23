extends Node2D

@onready var enemies_container = $Enemies
@onready var items_container = $Items
@onready var exits_container = $Exits
@onready var background_sprite = $Background/BackgroundSprite

var room_id: String
var room_data: Dictionary
var is_cleared: bool = false
var door_areas: Array = []
var is_setting_up: bool = false  # 防止重复设置

var enemy_scenes = {
	"enemy_fly": preload("res://scenes/enemies/EnemyFly.tscn"),
	"enemy_spider": preload("res://scenes/enemies/EnemySpider.tscn"),
	"boss_spider": preload("res://scenes/enemies/BossSpider.tscn")
}

var item_scenes = {
	"heart": preload("res://scenes/items/Heart.tscn"),
	"key": preload("res://scenes/items/Key.tscn")
}

func _ready():
	GameManager.room_changed.connect(_on_room_changed)
	# 初始化第一个房间
	call_deferred("setup_room", "room01_0,0", GameManager.current_room_config)

func setup_room(new_room_id: String, config: Dictionary = {}):
	if is_setting_up:
		return
	is_setting_up = true
	
	room_id = new_room_id
	room_data = config
	
	# 重置房间清理状态
	is_cleared = false
	
	# 延迟清理房间，避免在物理回调中删除
	call_deferred("clear_room_deferred")
	await get_tree().process_frame
	
	setup_background()
	setup_collision_mask()
	spawn_enemies()
	spawn_items()
	setup_exits()
	
	# 检查是否是已清理的房间（没有敌人）
	if room_data.has("enemies") and room_data.enemies.size() == 0:
		is_cleared = true
		#print("Room already cleared (no enemies)")
	
	is_setting_up = false

func clear_room_deferred():
	# 安全删除敌人
	for child in enemies_container.get_children():
		child.queue_free()
	# 安全删除物品
	for child in items_container.get_children():
		child.queue_free()
	# 安全删除旧的墙壁碰撞体
	var wall_container = get_node_or_null("WallCollisions")
	if wall_container:
		wall_container.queue_free()
	
	# 等待一帧确保删除完成
	await get_tree().process_frame

func setup_background():
	if room_data.has("background_image"):
		var texture = load(room_data.background_image)
		if texture and background_sprite:
			background_sprite.texture = texture
			
			# 获取屏幕尺寸
			var screen_size = get_viewport().get_visible_rect().size
			var texture_size = texture.get_size()
			
			# 计算缩放比例，使房间图片上下顶满屏幕
			var background_scale = screen_size.y / texture_size.y
			background_sprite.scale = Vector2(background_scale, background_scale)
			
			# 计算偏移量（居中显示）
			var scaled_texture_size = texture_size * background_scale
			var background_offset = (screen_size - scaled_texture_size) * 0.5
			background_sprite.position = background_offset + scaled_texture_size * 0.5
			
			# 更新全局配置
			GlobalConfig.update_scale_config(background_scale, background_offset)

func setup_collision_mask():
	if room_data.has("collision_mask"):
		#print("Setting up collision mask for path: ", room_data.collision_mask)
		var room_config_script = preload("res://scripts/RoomConfig.gd")
		
		# 获取背景缩放信息
		var background_scale = GlobalConfig.background_scale
		var background_offset = GlobalConfig.background_offset
		
		# 创建碰撞体和获取门区域
		var result = room_config_script.create_collision_shapes_from_mask(
			room_data.collision_mask, 
			self, 
			background_scale, 
			background_offset
		)
		
		door_areas = result.get("door_areas", [])
		#print("Setup complete. Door areas: ", door_areas.size())

func spawn_enemies():
	if not room_data.has("enemies"):
		return
	
	for enemy_config in room_data.enemies:
		var enemy_type = enemy_config.type
		if enemy_scenes.has(enemy_type):
			var enemy = enemy_scenes[enemy_type].instantiate()
			enemies_container.add_child(enemy)
			
			# 设置位置，使用归一化坐标(0-1)
			if enemy_config.has("position"):
				var normalized_pos = Vector2(enemy_config.position[0], enemy_config.position[1])
				enemy.position = convert_normalized_to_screen_position(normalized_pos)
				#print("Enemy ", enemy_type, " positioned at normalized: ", normalized_pos, " screen: ", enemy.position)
			else:
				# 如果没有位置信息，使用屏幕中心
				enemy.position = Vector2(get_viewport().size.x * 0.5, get_viewport().size.y * 0.5)
			
			# 设置缩放
			enemy.scale = GlobalConfig.get_entity_scale()
			
			# 设置血量
			if enemy_config.has("health"):
				enemy.health = enemy_config.health
				if enemy.has_method("update_health_display"):
					enemy.update_health_display()
			
			enemy.connect("enemy_died", _on_enemy_died)

func spawn_items():
	if not room_data.has("items"):
		return
	
	for item_config in room_data.items:
		var item_type = item_config.type
		if item_scenes.has(item_type):
			var item = item_scenes[item_type].instantiate()
			items_container.add_child(item)
			
			# 设置位置，使用归一化坐标(0-1)
			if item_config.has("position"):
				var normalized_pos = Vector2(item_config.position[0], item_config.position[1])
				item.position = convert_normalized_to_screen_position(normalized_pos)
				#print("Item ", item_type, " positioned at normalized: ", normalized_pos, " screen: ", item.position)
			else:
				# 如果没有位置信息，使用屏幕中心
				item.position = Vector2(get_viewport().size.x * 0.5, get_viewport().size.y * 0.5)
			
			# 设置缩放
			item.scale = GlobalConfig.get_entity_scale()

func setup_exits():
	# 创建房间出口的可视化指示
	pass

func get_door_areas() -> Array:
	return door_areas

func is_room_cleared() -> bool:
	return is_cleared

func convert_normalized_to_screen_position(normalized_pos: Vector2) -> Vector2:
	# 将归一化坐标(0-1)转换为屏幕坐标
	# 考虑可活动区域（排除边界）
	var screen_size = get_viewport().get_visible_rect().size
	var margin = Vector2(screen_size.x * 0.1, screen_size.y * 0.1)  # 10%边界
	var usable_area = screen_size - margin * 2
	
	var screen_pos = Vector2(
		margin.x + normalized_pos.x * usable_area.x,
		margin.y + normalized_pos.y * usable_area.y
	)
	
	return screen_pos

func get_random_walkable_position() -> Vector2:
	# 现在由于我们创建了墙壁碰撞体，可以在任意位置生成敌人
	# Godot的物理引擎会自动处理碰撞检测
	var room_width = get_viewport().size.x * 0.8
	var room_height = get_viewport().size.y * 0.8
	return Vector2(
		SeedSystem.randf_range(get_viewport().size.x * 0.1, room_width),
		SeedSystem.randf_range(get_viewport().size.y * 0.1, room_height)
	)

func _on_enemy_died():
	check_room_clear()

func check_room_clear():
	# 等待一帧确保敌人已经被完全移除
	await get_tree().process_frame
	
	if enemies_container.get_child_count() == 0:
		if not is_cleared:
			is_cleared = true
			#print("Room cleared! All enemies defeated.")
			# 通知GameManager房间已清理
			GameManager.mark_room_cleared()
			# 房间清理完毕，可以开启出口或奖励

func _on_room_changed(new_room_id: String, room_config: Dictionary, entry_direction: String):
	call_deferred("setup_room", new_room_id, room_config)

func clear_tears():
	# 清理房间中的所有子弹
	var tears = get_tree().get_nodes_in_group("tears")
	for tear in tears:
		if tear and is_instance_valid(tear):
			tear.queue_free()
	
	# 也清理直接添加到Main节点下的子弹
	for child in get_children():
		if child is Tear:
			child.queue_free()