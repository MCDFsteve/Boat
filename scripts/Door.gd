@tool
extends StaticBody2D

enum Direction {
	DOWN,   # 默认朝下
	UP,     # 朝上
	LEFT,   # 朝左
	RIGHT   # 朝右
}

@export var direction: Direction = Direction.DOWN : set = set_direction
@export var force_update_collision: bool = false : set = set_force_update_collision

@onready var sprite = $Sprite2D
@onready var collision = $CollisionShape2D
@onready var detection_area = $DetectionArea

var players_in_area: Array = []  # 追踪在检测区域内的玩家

func _ready():
	# 在编辑器和游戏中都运行，保持一致性
	update_door_rotation()
	update_door_scale()
	update_collision_shape()
	
	# 连接Area2D信号（只在游戏模式下）
	if not Engine.is_editor_hint() and detection_area:
		detection_area.body_entered.connect(_on_detection_area_body_entered)
		detection_area.body_exited.connect(_on_detection_area_body_exited)
	
	# 在游戏模式下再次确保缩放正确
	if not Engine.is_editor_hint():
		# 延迟一帧，确保其他初始化完成
		await get_tree().process_frame
		update_door_scale()

func set_direction(new_direction: Direction):
	direction = new_direction
	# 延迟调用，确保节点完全初始化
	if is_inside_tree():
		call_deferred("update_door_rotation")
		call_deferred("update_door_scale") 
		call_deferred("update_collision_shape")

func update_door_rotation():
	var sprite_node = get_node_or_null("Sprite2D")
	if not sprite_node:
		return
	
	# 根据方向旋转门的贴图（彻底修正方向）
	match direction:
		Direction.DOWN:  # 朝下，旋转180度（如果原图是朝上的）
			sprite_node.rotation_degrees = 180
		Direction.UP:    # 朝上，不旋转（假设原图是朝上的）
			sprite_node.rotation_degrees = 0
		Direction.LEFT:  # 朝左，旋转-90度
			sprite_node.rotation_degrees = -90
		Direction.RIGHT: # 朝右，旋转90度
			sprite_node.rotation_degrees = 90

func update_door_scale():
	# 设置门的缩放，编辑器和游戏保持一致
	# 使用全局配置的游戏缩放，保持与房间一致
	if GlobalConfig:
		scale = GlobalConfig.get_game_scale()
	else:
		scale = Vector2(8.0, 8.0)  # 后备默认值

func update_collision_shape():
	# 强制更新碰撞箱的大小
	var collision_node = get_node_or_null("CollisionShape2D")
	if not collision_node:
		return
	
	# 重新创建形状，确保更新生效
	var new_shape = RectangleShape2D.new()
	
	match direction:
		Direction.UP:
			# 上门：横着的碰撞箱
			new_shape.size = Vector2(49, 16)
		Direction.DOWN:
			# 下门：横着的碰撞箱
			new_shape.size = Vector2(49, 16)
		Direction.LEFT:
			# 左门：竖着的碰撞箱
			new_shape.size = Vector2(16, 49)
		Direction.RIGHT:
			# 右门：竖着的碰撞箱
			new_shape.size = Vector2(16, 49)
	
	# 强制重新分配shape
	collision_node.shape = new_shape

func set_force_update_collision(value: bool):
	# 强制更新碰撞箱按钮
	if value:
		force_update_collision = false  # 重置按钮
		print("Force updating collision for direction: ", direction)
		update_collision_shape()
		# 检查结果
		var collision_node = get_node_or_null("CollisionShape2D")
		if collision_node and collision_node.shape and collision_node.shape is RectangleShape2D:
			var rect_shape = collision_node.shape as RectangleShape2D
			print("Final collision size: ", rect_shape.size)
		if Engine.is_editor_hint():
			notify_property_list_changed()

func get_door_position() -> Vector2:
	# 返回门的世界位置，供其他系统使用
	return global_position 

# 新增：获取归一化的门位置（0-1范围）
func get_normalized_door_position() -> Vector2:
	var screen_size = get_viewport().get_visible_rect().size
	var normalized_pos = Vector2.ZERO
	
	match direction:
		Direction.UP:
			normalized_pos = Vector2(global_position.x / screen_size.x, 0.0)
		Direction.DOWN:
			normalized_pos = Vector2(global_position.x / screen_size.x, 1.0)
		Direction.LEFT:
			normalized_pos = Vector2(0.0, global_position.y / screen_size.y)
		Direction.RIGHT:
			normalized_pos = Vector2(1.0, global_position.y / screen_size.y)
	
	return normalized_pos

# 新增：获取门内侧位置（玩家进入后应该站立的位置）
func get_door_inside_position(door_offset: float = 0.0) -> Vector2:
	var door_pos = global_position
	var inside_pos = door_pos
	
	# 计算到房间内侧的距离，确保玩家在房间内
	var room_inside_distance = 100.0 + door_offset  # 基础距离确保在房间内
	
	match direction:
		Direction.UP:    # 上门，玩家应该在门的下方更深入房间内
			inside_pos.y += room_inside_distance
		Direction.DOWN:  # 下门，玩家应该在门的上方更深入房间内
			inside_pos.y -= room_inside_distance
		Direction.LEFT:  # 左门，玩家应该在门的右方更深入房间内
			inside_pos.x += room_inside_distance
		Direction.RIGHT: # 右门，玩家应该在门的左方更深入房间内
			inside_pos.x -= room_inside_distance
	
	return inside_pos

# 新增：根据门的方向字符串获取门的方向枚举
func get_direction_from_string(dir_string: String) -> Direction:
	match dir_string:
		"north":
			return Direction.UP
		"south":
			return Direction.DOWN
		"west":
			return Direction.LEFT
		"east":
			return Direction.RIGHT
		_:
			return Direction.DOWN

func _on_detection_area_body_entered(body):
	# 玩家进入门的检测区域
	if body.is_in_group("player") or body.name == "Player":
		if body not in players_in_area:
			players_in_area.append(body)

func _on_detection_area_body_exited(body):
	# 玩家离开门的检测区域
	if body in players_in_area:
		players_in_area.erase(body)

func is_player_in_area() -> bool:
	# 检查是否有玩家在门的检测区域内
	return players_in_area.size() > 0

func get_players_in_area() -> Array:
	# 返回在检测区域内的玩家列表
	return players_in_area 