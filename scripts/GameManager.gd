extends Node

signal room_changed(room_id, room_config, entry_direction)

# 房间系统：支持房间类型+坐标的实例化
var current_room_coordinate: Vector2 = Vector2(0, 0)  # 当前房间坐标
var current_room_type: String = "room01"  # 当前房间类型
var current_room_config: Dictionary = {}
var visited_rooms: Dictionary = {}  # 记录已访问的房间实例
var player_health: int = 100
var player_damage: int = 10
var last_entry_direction: String = ""  # 玩家进入房间的方向



func _ready():
	# 设置GameManager为自动加载单例
	load_room_at_coordinate(current_room_coordinate, current_room_type)

func load_room_at_coordinate(coordinate: Vector2, room_type: String = ""):
	current_room_coordinate = coordinate
	
	# 检查是否已经访问过这个坐标的房间
	var room_key = str(coordinate.x) + "," + str(coordinate.y)
	
	if visited_rooms.has(room_key):
		# 加载已访问房间的状态（敌人可能已被清理）
		current_room_config = visited_rooms[room_key]
		current_room_type = visited_rooms[room_key].get("room_type", "room01")
	else:
		# 为新房间随机选择类型（如果没有指定）
		if room_type == "":
			var room_types = ["room01", "room02", "room03"]
			room_type = SeedSystem.choose_random(room_types)
		
		current_room_type = room_type
		
		# 加载新房间配置
		var room_config_script = preload("res://scripts/RoomConfig.gd")
		current_room_config = room_config_script.load_room_config(room_type)
		
		# 检查是否是初始房间（0,0坐标）
		if coordinate == Vector2(0, 0):
			# 初始房间不生成怪物和道具
			current_room_config.enemies = []
			current_room_config.items = []
		else:
			# 其他房间随机选择一个预设配置生成怪物和道具
			select_random_preset()
		
		# 记录房间类型
		current_room_config["room_type"] = room_type
		# 记录这个房间实例
		visited_rooms[room_key] = current_room_config.duplicate(true)
	
	var room_id = current_room_type + "_" + room_key
	room_changed.emit(room_id, current_room_config, last_entry_direction)

func select_random_preset():
	# 从预设配置中随机选择一个
	if current_room_config.has("presets") and current_room_config.presets.size() > 0:
		var selected_preset = SeedSystem.choose_random(current_room_config.presets)
		
		# 将选中的预设的敌人和物品复制到房间配置中
		current_room_config.enemies = selected_preset.get("enemies", [])
		current_room_config.items = selected_preset.get("items", [])
	else:
		current_room_config.enemies = []
		current_room_config.items = []

func get_enemy_health(enemy_type: String) -> int:
	match enemy_type:
		"enemy_fly":
			return 20
		"enemy_spider":
			return 30
		"boss_spider":
			return 100
		_:
			return 20

func change_room(direction: String):
	var new_coordinate = current_room_coordinate
	
	# 根据方向计算新坐标
	match direction:
		"north":
			new_coordinate.y -= 1
			last_entry_direction = "south"  # 从南边进入新房间
		"south":
			new_coordinate.y += 1
			last_entry_direction = "north"  # 从北边进入新房间
		"east":
			new_coordinate.x += 1
			last_entry_direction = "west"   # 从西边进入新房间
		"west":
			new_coordinate.x -= 1
			last_entry_direction = "east"   # 从东边进入新房间
	
	# 加载新坐标的房间（随机选择房间类型）
	load_room_at_coordinate(new_coordinate)

# 当房间被清理时，更新已访问房间的状态
func mark_room_cleared():
	var room_key = str(current_room_coordinate.x) + "," + str(current_room_coordinate.y)
	if visited_rooms.has(room_key):
		visited_rooms[room_key].enemies = []  # 清空敌人列表

func get_current_room_data():
	return current_room_config



func take_damage(amount: int):
	player_health -= amount
	if player_health <= 0:
		game_over()

func heal(amount: int):
	player_health = min(player_health + amount, 100)

func game_over():
	# 重新生成种子为下一局游戏做准备
	SeedSystem.generate_new_seed()
	get_tree().reload_current_scene() 