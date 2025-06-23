extends Camera2D

# 摄像机跟随目标
var target: Node2D
# 跟随速度（0-1之间，1为瞬间跟随，越小越平滑）
@export var follow_speed: float = 0.4  # 提高跟随速度
# 是否启用平滑跟随
@export var smooth_follow: bool = true
# 当目标距离摄像机超过此值时，瞬间跟随（防止房间切换时的延迟）
@export var instant_follow_distance: float = 100.0  # 降低瞬间跟随阈值
# 是否暂停跟随（用于过渡动画）
var following_paused: bool = false
# 高速移动阈值
@export var high_speed_threshold: float = 300.0

func _ready():
	# 设置为当前摄像机
	enabled = true
	# 寻找玩家节点作为跟随目标
	target = get_node("../Player")
	
	if target:
		# 立即将摄像机位置设置为玩家位置
		global_position = target.global_position
		
		# 连接房间切换信号，在房间切换时立即跟随
		if GameManager:
			GameManager.room_changed.connect(_on_room_changed)

func _physics_process(delta):
	# 改用physics_process与玩家移动同步
	if target and not following_paused:
		var distance_to_target = global_position.distance_to(target.global_position)
		
		# 如果目标距离太远（比如房间切换），立即跟随
		if distance_to_target > instant_follow_distance:
			global_position = target.global_position
		elif smooth_follow:
			# 检查玩家移动速度，调整跟随策略
			var player_speed = 0.0
			if target.has_method("get") and target.get("velocity") != null:
				player_speed = target.velocity.length()
			
			# 高速移动时使用更强的跟随
			var dynamic_follow_speed = follow_speed
			if player_speed > high_speed_threshold:
				dynamic_follow_speed = min(follow_speed * 2.0, 0.8)  # 高速时加快跟随
			
			# 平滑跟随
			global_position = global_position.lerp(target.global_position, dynamic_follow_speed)
		else:
			# 瞬间跟随
			global_position = target.global_position

func _on_room_changed(room_id: String, room_config: Dictionary, entry_direction: String):
	# 房间切换时立即跟随玩家
	if target:
		call_deferred("sync_to_target")

func sync_to_target():
	# 同步摄像机位置到目标位置
	if target:
		global_position = target.global_position 

func pause_following():
	# 暂停跟随（用于过渡动画）
	following_paused = true

func resume_following():
	# 恢复跟随
	following_paused = false 