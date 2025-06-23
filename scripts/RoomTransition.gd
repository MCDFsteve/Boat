extends Node

# 房间过渡管理器 - 处理门穿越的视觉效果
signal transition_complete

var camera: Camera2D
var player: Node2D
var transition_duration: float = 0.1  # 过渡动画总时长
var is_transitioning: bool = false

# 过渡阶段
enum TransitionPhase {
	NONE,
	MOVING_OUT,    # 向门外移动
	BLACK_SCREEN,  # 黑屏阶段
	MOVING_IN      # 进入新房间
}

var current_phase: TransitionPhase = TransitionPhase.NONE
var transition_tween: Tween

func setup_references(cam: Camera2D, plr: Node2D):
	camera = cam
	player = plr

func start_transition(exit_direction: String):
	if is_transitioning:
		return
		
	is_transitioning = true
	current_phase = TransitionPhase.MOVING_OUT
	
	# 创建Tween动画
	if transition_tween:
		transition_tween.kill()
	transition_tween = create_tween()
	
	# 计算摄像机移动方向（与出门方向相同）
	var camera_move_direction = get_camera_move_direction(exit_direction)
	var move_distance = 800.0  # 摄像机移动距离
	
	# 第一阶段：摄像机快速向门外移动（出房间）
	var start_pos = camera.global_position
	var out_pos = start_pos + camera_move_direction * move_distance
	
	transition_tween.tween_method(
		_update_camera_position, 
		start_pos, 
		out_pos, 
		0.02 # 0.1秒出房间
	)
	transition_tween.tween_callback(_start_black_screen_phase.bind(exit_direction))

func _update_camera_position(pos: Vector2):
	if camera:
		camera.global_position = pos

func _start_black_screen_phase(exit_direction: String):
	current_phase = TransitionPhase.BLACK_SCREEN
	
	# 创建黑屏效果
	var black_screen = ColorRect.new()
	black_screen.color = Color.BLACK
	black_screen.size = get_viewport().get_visible_rect().size * 2  # 稍微大一点确保覆盖
	black_screen.position = -get_viewport().get_visible_rect().size * 0.5
	black_screen.z_index = 1000  # 确保在最前面
	get_tree().root.add_child(black_screen)
	
	# 黑屏持续时间
	await get_tree().create_timer(0.05).timeout
	
	# 触发实际的房间切换
	GameManager.change_room(exit_direction)
	
	# 等待房间切换完成
	await get_tree().create_timer(0.02).timeout
	
	# 开始进入新房间的动画
	_start_moving_in_phase(exit_direction, black_screen)

func _start_moving_in_phase(exit_direction: String, black_screen: ColorRect):
	current_phase = TransitionPhase.MOVING_IN
	
	if not player or not camera:
		_cleanup_transition(black_screen)
		return
	
	# 计算新房间的玩家起始位置（对应的门口）
	var entry_direction = get_opposite_direction(exit_direction)
	var player_start_pos = get_actual_entry_door_position(entry_direction)
	
	# 设置玩家到新房间的门口位置
	player.global_position = player_start_pos
	
	# 计算摄像机的起始和目标位置
	var camera_move_direction = get_camera_move_direction(entry_direction)
	var move_distance = 800.0
	
	# 摄像机的目标位置是玩家位置
	var camera_target_pos = player_start_pos
	var camera_start_pos = camera_target_pos + camera_move_direction * move_distance
	
	camera.global_position = camera_start_pos
	
	# 第三阶段：摄像机从入口方向移动到玩家位置（进入新房间）
	transition_tween = create_tween()
	transition_tween.tween_method(
		_update_camera_position,
		camera_start_pos,
		camera_target_pos,
		0.1  # 0.1秒进入新房间
	)
	transition_tween.tween_callback(_cleanup_transition.bind(black_screen))

func _cleanup_transition(black_screen: ColorRect):
	current_phase = TransitionPhase.NONE
	is_transitioning = false
	
	# 移除黑屏
	if black_screen and is_instance_valid(black_screen):
		black_screen.queue_free()
	
	# 重新启用摄像机的正常跟随
	if camera and camera.has_method("resume_following"):
		camera.resume_following()
	
	transition_complete.emit()

func get_camera_move_direction(direction: String) -> Vector2:
	match direction:
		"north":
			return Vector2.UP
		"south":
			return Vector2.DOWN
		"east":
			return Vector2.RIGHT
		"west":
			return Vector2.LEFT
		_:
			return Vector2.ZERO

func get_opposite_direction(direction: String) -> String:
	match direction:
		"north":
			return "south"
		"south":
			return "north"
		"east":
			return "west"
		"west":
			return "east"
		_:
			return direction

# 新的实际门位置获取系统，距离门的距离为0.0
func get_actual_entry_door_position(entry_direction: String) -> Vector2:
	# 直接从根节点获取RoomManager
	var room_manager = get_node("/root/Main/RoomManager")
	if not room_manager:
		return get_fallback_entry_position(entry_direction)
	
	# 使用RoomManager的统一方法获取门的位置
	return room_manager.get_entry_position_for_direction(entry_direction)

# 备用位置系统（如果找不到实际门的位置）
func get_fallback_entry_position(entry_direction: String) -> Vector2:
	match entry_direction:
		"north":  # 从北边进入，玩家应该在顶部门口
			return Vector2(640, 50)   
		"south":  # 从南边进入，玩家应该在底部门口  
			return Vector2(640, 670)   
		"west":   # 从西边进入，玩家应该在左侧门口
			return Vector2(50, 360)   
		"east":   # 从东边进入，玩家应该在右侧门口
			return Vector2(1230, 360)  
		_:
			return Vector2(640, 360)   # 默认中心位置 