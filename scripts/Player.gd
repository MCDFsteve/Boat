@tool
extends CharacterBody2D

@export var speed: float = 400.0
@export var tears_speed: float = 600.0  # 提高子弹速度
@export var tears_damage: int = 10
@export var tears_knockback: float = 150.0

# 移除所有碰撞箱相关的导出变量，直接使用编辑器中的设置

@export var force_update_sprite: bool = false : set = set_force_update_sprite

@onready var sprite = $PlayerRect
@onready var collision = $CollisionShape2D
@onready var tears_spawn_point = $TearsSpawnPoint
@onready var player_3d_renderer = $Player3DRenderer

var tears_scene = preload("res://scenes/Tear.tscn")
var last_movement_direction = Vector2.DOWN
var room_transition_cooldown = 0.0  # 房间切换冷却时间
var room_transition_delay = 1.0     # 冷却时间长度
var room_transition: Node  # 房间过渡管理器引用

func _ready():
	# 检查是否在编辑器中
	if Engine.is_editor_hint():
		# 编辑器模式：只设置3D渲染和碰撞箱
		setup_editor_mode()
		return
	
	# 游戏模式：完整初始化
	# 等待几帧，确保GlobalConfig和场景完全初始化
	await get_tree().process_frame
	await get_tree().process_frame
	
	# 设置玩家缩放
	reset_player_scale()
	# 设置玩家初始位置为屏幕中心
	reset_player_position()
	
	# 设置子弹发射点位置到玩家中心
	setup_tears_spawn_point()
	
	# 连接房间切换信号，在房间切换后重新定位玩家
	if GameManager:
		GameManager.room_changed.connect(_on_room_changed)
	
	# 初始化3D渲染器
	if player_3d_renderer:
		# 连接3D渲染器的纹理到2D精灵
		update_sprite_from_3d_render()
		# 初始化描边效果
		apply_outline_to_sprite()
	
	# 设置房间过渡管理器
	setup_room_transition()
	
	# 不再修改碰撞箱，使用编辑器中的设置

func reset_player_position():
	# 重置玩家到屏幕中心
	var spawn_pos = GlobalConfig.get_player_spawn_position()
	position = spawn_pos
	##print("Player position set to: ", position, " (spawn_pos: ", spawn_pos, ")")

func reset_player_position_by_entry(entry_direction: String):
	# 根据进入方向设置玩家位置 - 使用实际的门位置
	var player_start_pos = get_actual_entry_door_position(entry_direction)
	position = player_start_pos

# 新的实际门位置获取系统，使用RoomManager
func get_actual_entry_door_position(entry_direction: String) -> Vector2:
	# Player是Main的子节点，RoomManager也是Main的子节点
	var room_manager = get_parent().get_node_or_null("RoomManager")
	if not room_manager:
		return get_fallback_entry_position(entry_direction)
	
	# 使用RoomManager的统一方法获取门的位置
	return room_manager.get_entry_position_for_direction(entry_direction)

# 备用位置系统（如果找不到实际门的位置）
func get_fallback_entry_position(entry_direction: String) -> Vector2:
	var screen_size = get_viewport().get_visible_rect().size
	var spawn_pos = Vector2.ZERO
	
	match entry_direction:
		"north":  # 从北边进入，玩家出现在靠近上门的位置
			spawn_pos = Vector2(screen_size.x * 0.5, screen_size.y * 0.15)
		"south":  # 从南边进入，玩家出现在靠近下门的位置
			spawn_pos = Vector2(screen_size.x * 0.5, screen_size.y * 0.85)
		"east":   # 从东边进入，玩家出现在靠近右门的位置
			spawn_pos = Vector2(screen_size.x * 0.85, screen_size.y * 0.5)
		"west":   # 从西边进入，玩家出现在靠近左门的位置
			spawn_pos = Vector2(screen_size.x * 0.15, screen_size.y * 0.5)
		_:        # 默认情况（第一次进入房间）
			spawn_pos = GlobalConfig.get_player_spawn_position()
	
	return spawn_pos

func reset_player_scale():
	# 重置玩家缩放
	scale = GlobalConfig.get_entity_scale()

func _on_room_changed(room_id: String, room_config: Dictionary, entry_direction: String):
	# 房间切换后，重新定位玩家并重置缩放
	#print("Room changed signal received: ", room_id, " from direction: ", entry_direction)
	call_deferred("reset_player_scale")
	call_deferred("reset_player_position_by_entry", entry_direction)
	
	# 清理旧房间的子弹
	call_deferred("clear_old_tears")

func _physics_process(delta):
	# 在编辑器模式下不运行游戏逻辑
	if Engine.is_editor_hint():
		return
	
	handle_movement()
	handle_shooting()
	
	# 使用Godot内置的物理引擎处理碰撞
	move_and_slide()
	
	# 更新房间切换冷却时间
	if room_transition_cooldown > 0:
		room_transition_cooldown -= delta
	
	check_room_transition()

func handle_movement():
	# 确保不在编辑器模式下运行
	if Engine.is_editor_hint():
		return
		
	var input_vector = Vector2.ZERO
	
	# 检查动作是否存在再使用
	if InputMap.has_action("move_left") and Input.is_action_pressed("move_left"):
		input_vector.x -= 1
	if InputMap.has_action("move_right") and Input.is_action_pressed("move_right"):
		input_vector.x += 1
	if InputMap.has_action("move_up") and Input.is_action_pressed("move_up"):
		input_vector.y -= 1
	if InputMap.has_action("move_down") and Input.is_action_pressed("move_down"):
		input_vector.y += 1
	
	if input_vector != Vector2.ZERO:
		last_movement_direction = input_vector.normalized()
		# 使用固定的移动速度，不再根据缩放调整
		velocity = input_vector.normalized() * speed
		
		# 更新3D模型方向
		if player_3d_renderer:
			player_3d_renderer.update_direction(last_movement_direction)
	else:
		velocity = Vector2.ZERO

func handle_shooting():
	# 确保不在编辑器模式下运行
	if Engine.is_editor_hint():
		return
		
	# 使用独立的if语句检测射击方向
	if InputMap.has_action("shoot_left") and Input.is_action_just_pressed("shoot_left"):
		#print("Shooting LEFT")
		shoot_tear(Vector2.LEFT)
		return
	
	if InputMap.has_action("shoot_right") and Input.is_action_just_pressed("shoot_right"):
		#print("Shooting RIGHT")
		shoot_tear(Vector2.RIGHT)
		return
	
	if InputMap.has_action("shoot_up") and Input.is_action_just_pressed("shoot_up"):
		#print("Shooting UP")
		shoot_tear(Vector2.UP)
		return
	
	if InputMap.has_action("shoot_down") and Input.is_action_just_pressed("shoot_down"):
		#print("Shooting DOWN")
		shoot_tear(Vector2.DOWN)
		return

func shoot_tear(direction: Vector2):
	#print("Creating tear with direction: ", direction)
	var tear = tears_scene.instantiate()
	get_parent().add_child(tear)
	tear.position = tears_spawn_point.global_position
	
	# 使用新的setup函数设置子弹属性
	tear.setup(direction, tears_speed, tears_damage, 1.5, tears_knockback)
	
	# 设置子弹缩放
	tear.scale = GlobalConfig.get_entity_scale()

func check_room_transition():
	# 编辑器模式下不处理房间切换
	if Engine.is_editor_hint():
		return
		
	# 如果在冷却时间内，不检查房间切换
	if room_transition_cooldown > 0:
		return
	
	# 通过RoomManager获取当前房间
	var room_manager = get_parent().get_node_or_null("RoomManager")
	if not room_manager:
		return
	
	var room_node = room_manager.get_current_room()
	if not room_node:
		return
	
	# 检查房间是否已清理 - 降低要求，未清理也可以通过门
	# 这样玩家可以在任何时候通过门
	var can_pass = true
	if room_node.has_method("is_room_cleared"):
		# 可以选择是否要求房间清理才能通过门
		# can_pass = room_node.is_room_cleared()
		can_pass = true  # 暂时允许随时通过门
	
	if not can_pass:
		return
	
	# 新的门检测逻辑：检测玩家朝门方向移动时是否被门阻挡
	var current_input = Vector2.ZERO
	var exit_direction = ""
	
	# 获取当前输入方向（只允许单一方向移动触发门切换）
	var up_pressed = InputMap.has_action("move_up") and Input.is_action_pressed("move_up")
	var down_pressed = InputMap.has_action("move_down") and Input.is_action_pressed("move_down")
	var left_pressed = InputMap.has_action("move_left") and Input.is_action_pressed("move_left")
	var right_pressed = InputMap.has_action("move_right") and Input.is_action_pressed("move_right")
	
	# 只在单一方向移动时触发门切换，避免斜向移动的误触
	var pressed_count = 0
	if up_pressed: pressed_count += 1
	if down_pressed: pressed_count += 1
	if left_pressed: pressed_count += 1
	if right_pressed: pressed_count += 1
	
	# 只有在按住单一方向键时才触发门切换
	if pressed_count == 1:
		if up_pressed:
			current_input = Vector2(0, -1)
			exit_direction = "north"
		elif down_pressed:
			current_input = Vector2(0, 1)
			exit_direction = "south"
		elif left_pressed:
			current_input = Vector2(-1, 0)
			exit_direction = "west"
		elif right_pressed:
			current_input = Vector2(1, 0)
			exit_direction = "east"
	
	# 如果没有单一方向输入，不检测门
	if current_input == Vector2.ZERO:
		return
	
	# 检查是否被门阻挡
	if is_blocked_by_door(current_input, room_node):
		# 设置冷却时间
		room_transition_cooldown = room_transition_delay
		
		# 使用过渡动画切换房间
		start_room_transition(exit_direction)

func is_blocked_by_door(input_direction: Vector2, room_node: Node2D) -> bool:
	# 检查玩家是否足够接近对应方向的门并朝该门方向移动
	var exits_container = room_node.get_node_or_null("Exits")
	if not exits_container:
		return false
	
	# 根据输入方向确定对应的门方向
	var target_door_direction = -1
	match input_direction:
		Vector2(0, -1):  # 向上移动，应该对应上门
			target_door_direction = 1  # Direction.UP
		Vector2(0, 1):   # 向下移动，应该对应下门
			target_door_direction = 0  # Direction.DOWN
		Vector2(-1, 0):  # 向左移动，应该对应左门
			target_door_direction = 2  # Direction.LEFT
		Vector2(1, 0):   # 向右移动，应该对应右门
			target_door_direction = 3  # Direction.RIGHT
		_:
			return false  # 不是纯方向移动，不触发门切换
	
	# 只检查对应方向的门
	for door in exits_container.get_children():
		if not door:
			continue
			
		# 检查门是否可见且启用
		if not door.visible:
			continue
		
		# 检查门的检测区域是否启用
		var detection_area = door.get_node_or_null("DetectionArea")
		if detection_area and not detection_area.monitoring:
			continue
		
		# 检查门的方向是否匹配
		if "direction" in door and door.direction == target_door_direction:
			var door_pos = door.global_position
			var distance = global_position.distance_to(door_pos)
			
			# 如果玩家距离对应方向的门足够近
			if distance < 200:  # 调整这个距离
				# 检查输入方向是否朝向门
				var to_door = (door_pos - global_position).normalized()
				var dot_product = input_direction.dot(to_door)
				
				# 如果玩家朝门方向移动（dot_product > 0.5 表示角度小于60度）
				if dot_product > 0.5:
					return true
	
	return false

func update_sprite_from_3d_render():
	# 将3D渲染的纹理应用到2D精灵
	if player_3d_renderer and sprite:
		# 等待渲染完成
		await get_tree().process_frame
		var texture = player_3d_renderer.get_texture()
		if texture:
			sprite.texture = texture
			# 应用2D后处理描边
			apply_outline_to_sprite()

func add_equipment(equipment_type: String, equipment_model_path: String):
	# 添加装备到3D模型
	if player_3d_renderer:
		player_3d_renderer.add_equipment(equipment_type, equipment_model_path)
		# 更新2D精灵
		call_deferred("update_sprite_from_3d_render")

func remove_equipment(equipment_type: String):
	# 从3D模型移除装备
	if player_3d_renderer:
		player_3d_renderer.remove_equipment(equipment_type)
		# 更新2D精灵
		call_deferred("update_sprite_from_3d_render")

func _on_area_2d_body_entered(body):
	if body.has_method("take_damage"):
		GameManager.take_damage(10)

func setup_room_transition():
	# 创建房间过渡管理器
	var transition_scene = preload("res://scripts/RoomTransition.gd")
	room_transition = transition_scene.new()
	get_parent().add_child(room_transition)
	
	# 设置引用
	var camera = get_parent().get_node("Camera2D")
	if camera and room_transition:
		room_transition.setup_references(camera, self)

func start_room_transition(exit_direction: String):
	# 开始房间过渡动画
	if room_transition:
		# 暂停摄像机跟随
		var camera = get_parent().get_node("Camera2D")
		if camera and camera.has_method("pause_following"):
			camera.pause_following()
		
		# 开始过渡动画
		room_transition.start_transition(exit_direction)

func apply_outline_to_sprite():
	# 根据Player3DRenderer的描边样式应用2D后处理
	if player_3d_renderer and sprite:
		var outline_style = player_3d_renderer.current_outline_style
		match outline_style:
			player_3d_renderer.OutlineStyle.NONE:
				sprite.material = null
			player_3d_renderer.OutlineStyle.SIMPLE, player_3d_renderer.OutlineStyle.PIXEL:
				var outline_material = load("res://assets/player/outline_post_process_material.tres")
				if outline_material:
					sprite.material = outline_material

func setup_tears_spawn_point():
	# 将子弹发射点设置到玩家的垂直中心
	if tears_spawn_point:
		tears_spawn_point.position = Vector2.ZERO  # 设置到玩家中心

func set_outline_style(style):
	# 设置描边样式
	if player_3d_renderer:
		player_3d_renderer.set_outline_style(style)
		# 重新应用描边到精灵
		apply_outline_to_sprite()

# 移除所有碰撞箱设置函数

func set_force_update_sprite(value: bool):
	# 强制更新精灵（编辑器中使用）
	if value and Engine.is_editor_hint():
		force_update_sprite = false  # 重置按钮
		call_deferred("force_refresh_sprite")

func setup_editor_mode():
	# 编辑器模式的初始化
	if player_3d_renderer:
		# 在编辑器中也运行3D渲染
		await get_tree().process_frame
		update_sprite_from_3d_render_editor()
	
	# 编辑器模式下不修改碰撞箱，让用户在Inspector中直接编辑
	
	# 启用调试绘制
	set_notify_transform(true)

func update_sprite_from_3d_render_editor():
	# 编辑器中的3D渲染更新
	if player_3d_renderer and sprite:
		await get_tree().process_frame
		await get_tree().process_frame
		var texture = player_3d_renderer.get_texture()
		if texture:
			sprite.texture = texture
			# 通知编辑器更新
			notify_property_list_changed()

func force_refresh_sprite():
	# 强制刷新精灵纹理
	if Engine.is_editor_hint() and player_3d_renderer and sprite:
		player_3d_renderer.load_player_model()
		await get_tree().process_frame
		await get_tree().process_frame
		await get_tree().process_frame
		var texture = player_3d_renderer.get_texture()
		if texture:
			sprite.texture = texture
			# 强制更新显示
			sprite.queue_redraw()
			queue_redraw()
			notify_property_list_changed()

# 完全移除setup_collision函数，让编辑器和游戏使用相同的碰撞箱设置

func clear_old_tears():
	# 清理旧房间的子弹
	var room_node = get_parent()
	if room_node.has_method("clear_tears"):
		room_node.clear_tears()

