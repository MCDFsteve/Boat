extends Node2D
class_name RoomManager

# 房间管理器：负责房间切换和Player与房间的交互

@onready var player: CharacterBody2D
var current_room: Node2D
var room_scenes = {
	"room01": preload("res://scenes/Room01.tscn"),
	"room02": preload("res://scenes/Room01.tscn"),  # 暂时使用Room01作为room02
	"room03": preload("res://scenes/Room01.tscn"),  # 暂时使用Room01作为room03
	# 未来可以创建专门的room02和room03场景
}

func _ready():
	# 获取Player引用
	player = get_node("../Player")
	
	# 连接GameManager的房间切换信号
	if GameManager.room_changed.is_connected(_on_room_changed):
		GameManager.room_changed.disconnect(_on_room_changed)
	GameManager.room_changed.connect(_on_room_changed)
	
	# 加载初始房间
	load_room("room01")

func load_room(room_id: String):
	# 清理当前房间
	if current_room:
		current_room.queue_free()
		await current_room.tree_exited
	
	# 解析房间ID（移除坐标后缀）
	var base_room_id = room_id.split("_")[0]  # "room01_0,0" -> "room01"
	
	# 加载新房间
	if room_scenes.has(base_room_id):
		current_room = room_scenes[base_room_id].instantiate()
		add_child(current_room)
		
		# 等待房间完全初始化
		await get_tree().process_frame
		
		# 将Player作为房间的子弹添加目标
		if current_room.has_method("set_player_reference"):
			current_room.set_player_reference(player)
		
		# 手动触发房间数据设置，确保新房间接收到当前房间配置
		if current_room.has_method("_on_room_changed"):
			var room_config = GameManager.get_current_room_data()
			current_room._on_room_changed(room_id, room_config, GameManager.last_entry_direction)
	else:
		print("Room not found: ", base_room_id)

func _on_room_changed(new_room_id: String, room_config: Dictionary, entry_direction: String):
	# 只加载房间场景，不重复调用房间的_on_room_changed（已在load_room中处理）
	load_room(new_room_id)

func get_current_room() -> Node2D:
	return current_room

# 新增：根据方向获取门的精确位置（用于玩家进入时的位置设置）
func get_door_by_direction(direction: String) -> Node:
	if not current_room:
		return null
	
	var exits_container = current_room.get_node_or_null("Exits")
	if not exits_container:
		return null
	
	# 根据进入方向找到对应的门
	match direction:
		"north":  # 从北边进入，找上门
			return find_door_by_direction_enum(exits_container, 1)  # Direction.UP
		"south":  # 从南边进入，找下门
			return find_door_by_direction_enum(exits_container, 0)  # Direction.DOWN
		"west":   # 从西边进入，找左门
			return find_door_by_direction_enum(exits_container, 2)  # Direction.LEFT
		"east":   # 从东边进入，找右门
			return find_door_by_direction_enum(exits_container, 3)  # Direction.RIGHT
		_:
			return null

func find_door_by_direction_enum(exits_container: Node2D, target_direction: int) -> Node:
	# 在门容器中找到指定方向枚举的门
	for door in exits_container.get_children():
		if door.has_method("get_door_position"):
			# 直接检查门的方向属性
			if "direction" in door and door.direction == target_direction:
				return door
	return null

# 新增：获取玩家应该在指定方向门内侧的位置
func get_entry_position_for_direction(entry_direction: String) -> Vector2:
	var target_door = get_door_by_direction(entry_direction)
	
	if target_door and target_door.has_method("get_door_inside_position"):
		# 距离门0.0（完全贴着门）
		return target_door.get_door_inside_position(0.0)
	else:
		# 备用位置系统
		return get_fallback_position(entry_direction)

func get_fallback_position(entry_direction: String) -> Vector2:
	# 如果找不到实际门位置，使用屏幕比例位置
	var screen_size = get_viewport().get_visible_rect().size
	
	match entry_direction:
		"north":
			return Vector2(screen_size.x * 0.5, screen_size.y * 0.1)
		"south":
			return Vector2(screen_size.x * 0.5, screen_size.y * 0.9)
		"west":
			return Vector2(screen_size.x * 0.1, screen_size.y * 0.5)
		"east":
			return Vector2(screen_size.x * 0.9, screen_size.y * 0.5)
		_:
			return Vector2(screen_size.x * 0.5, screen_size.y * 0.5) 