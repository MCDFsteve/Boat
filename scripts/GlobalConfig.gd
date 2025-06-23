extends Node

# 全局配置管理器
var background_scale: float = 1.0
var background_offset: Vector2 = Vector2.ZERO
var screen_size: Vector2 = Vector2.ZERO
var room_center: Vector2 = Vector2.ZERO

# 统一的游戏缩放倍数 - 用于房间背景、门等静态元素
var game_scale_multiplier: float = 8.0

# 实体基础缩放倍数
var entity_scale_multiplier: float = 4.0  # 从2.0增加到4.0，让实体更大

func _ready():
	# 获取实际屏幕尺寸
	await get_tree().process_frame
	if get_viewport():
		screen_size = get_viewport().get_visible_rect().size
	else:
		screen_size = Vector2(1024, 768)  # 默认屏幕尺寸
	room_center = screen_size * 0.5   # 初始化房间中心
	##print("GlobalConfig initialized with screen_size: ", screen_size)

func update_scale_config(bg_scale: float, bg_offset: Vector2):
	background_scale = bg_scale
	background_offset = bg_offset
	screen_size = get_viewport().get_visible_rect().size
	room_center = screen_size * 0.5
	
	# 实体缩放不再跟随背景缩放，使用固定的合适大小
	# entity_scale_multiplier 保持为固定值

func world_to_screen_position(world_pos: Vector2) -> Vector2:
	return world_pos * background_scale + background_offset

func get_player_spawn_position() -> Vector2:
	# 使用固定的屏幕中心位置，与Room01保持一致
	var spawn_position = Vector2(640, 360)
	##print("Player spawn position calculated: ", spawn_position)
	return spawn_position

func get_entity_scale() -> Vector2:
	return Vector2(entity_scale_multiplier, entity_scale_multiplier) 

func get_game_scale() -> Vector2:
	# 返回统一的游戏缩放，用于房间、门等静态元素
	return Vector2(game_scale_multiplier, game_scale_multiplier) 