extends Resource
class_name RoomConfig

# 房间配置管理器，从JSON文件加载房间配置
static func load_room_config(room_id: String) -> Dictionary:
	var config_path = "res://data/rooms/" + room_id + ".json"
	var file = FileAccess.open(config_path, FileAccess.READ)
	
	if file == null:
		#print("Failed to load room config: ", config_path)
		return {}
	
	var json_string = file.get_as_text()
	file.close()
	
	var json = JSON.new()
	var parse_result = json.parse(json_string)
	
	if parse_result != OK:
		#print("Failed to parse room config JSON: ", config_path)
		return {}
	
	return json.data

# 解析遮罩图片，生成碰撞形状
static func create_collision_shapes_from_mask(mask_path: String, parent_node: Node2D, scale_factor: float, offset: Vector2) -> Dictionary:
	# 先尝试使用load函数加载资源
	var texture = load(mask_path)
	var image = null
	
	if texture != null and texture is Texture2D:
		image = texture.get_image()
	
	if image == null:
		#print("Failed to load collision mask: ", mask_path)
		return {"door_areas": []}
	
	var door_areas = []
	
	#print("Creating collision shapes from mask: ", mask_path, " Size: ", image.get_width(), "x", image.get_height())
	
	# 创建一个简化的碰撞系统：只在边界创建碰撞体
	create_border_collision_bodies(image, parent_node, scale_factor, offset)
	
	# 只检测边界的门区域，减少门区域数量
	door_areas = find_border_doors(image, scale_factor, offset)
	
	#print("Found door areas: ", door_areas.size())
	
	return {
		"door_areas": door_areas
	}

# 查找所有绿色门区域（不仅仅是边界）
static func find_border_doors(image: Image, scale_factor: float, offset: Vector2) -> Array:
	var door_areas = []
	var width = image.get_width()
	var height = image.get_height()
	
	# #print("Searching for doors in image ", width, "x", height, " with scale_factor: ", scale_factor, " offset: ", offset)
	
	# 扫描整个图像寻找绿色区域（门）
	for x in range(0, width, 5):  # 每5个像素检查一次
		for y in range(0, height, 5):
			var pixel = image.get_pixel(x, y)
			# 检查是否是绿色(00ff00)
			if pixel.r < 0.1 and pixel.g > 0.9 and pixel.b < 0.1:
				var world_pos = Vector2(x, y)
				var scaled_pos = world_pos * scale_factor + offset
				door_areas.append(scaled_pos)
				# #print("Found door at image pos: ", world_pos, " -> screen pos: ", scaled_pos)
	
	# 如果没找到门，检查边界的绿色像素
	if door_areas.size() == 0:
		#print("No doors found in full scan, checking borders...")
		# 检查四个边界的门区域
		# 顶部和底部边界
		for x in range(width):
			# 顶部
			if x % 5 == 0:  # 每5个像素检查一次
				var pixel_top = image.get_pixel(x, 0)
				if pixel_top.r < 0.1 and pixel_top.g > 0.9 and pixel_top.b < 0.1:
					var world_pos = Vector2(x, 0)
					var scaled_pos = world_pos * scale_factor + offset
					door_areas.append(scaled_pos)
					#print("Found door at top border: ", world_pos, " -> ", scaled_pos)
			
			# 底部
			if x % 5 == 0:
				var pixel_bottom = image.get_pixel(x, height - 1)
				if pixel_bottom.r < 0.1 and pixel_bottom.g > 0.9 and pixel_bottom.b < 0.1:
					var world_pos = Vector2(x, height - 1)
					var scaled_pos = world_pos * scale_factor + offset
					door_areas.append(scaled_pos)
					#print("Found door at bottom border: ", world_pos, " -> ", scaled_pos)
		
		# 左侧和右侧边界
		for y in range(height):
			# 左侧
			if y % 5 == 0:
				var pixel_left = image.get_pixel(0, y)
				if pixel_left.r < 0.1 and pixel_left.g > 0.9 and pixel_left.b < 0.1:
					var world_pos = Vector2(0, y)
					var scaled_pos = world_pos * scale_factor + offset
					door_areas.append(scaled_pos)
					#print("Found door at left border: ", world_pos, " -> ", scaled_pos)
			
			# 右侧
			if y % 5 == 0:
				var pixel_right = image.get_pixel(width - 1, y)
				if pixel_right.r < 0.1 and pixel_right.g > 0.9 and pixel_right.b < 0.1:
					var world_pos = Vector2(width - 1, y)
					var scaled_pos = world_pos * scale_factor + offset
					door_areas.append(scaled_pos)
					#print("Found door at right border: ", world_pos, " -> ", scaled_pos)
	
	#print("Total doors found: ", door_areas.size())
	return door_areas

# 创建边界碰撞体（更高效的方法）
static func create_border_collision_bodies(image: Image, parent_node: Node2D, scale_factor: float, offset: Vector2):
	var wall_container = Node2D.new()
	wall_container.name = "WallCollisions"
	parent_node.add_child(wall_container)
	
	var width = image.get_width()
	var height = image.get_height()
	
	# 创建四个边界墙壁
	var border_thickness = 10  # 边界厚度
	
	# 顶部边界
	create_wall_rect(wall_container, 
		Vector2(0, -border_thickness) * scale_factor + offset,
		Vector2(width * scale_factor, border_thickness * scale_factor))
	
	# 底部边界  
	create_wall_rect(wall_container,
		Vector2(0, height) * scale_factor + offset,
		Vector2(width * scale_factor, border_thickness * scale_factor))
	
	# 左侧边界
	create_wall_rect(wall_container,
		Vector2(-border_thickness, 0) * scale_factor + offset,
		Vector2(border_thickness * scale_factor, height * scale_factor))
	
	# 右侧边界
	create_wall_rect(wall_container,
		Vector2(width, 0) * scale_factor + offset,
		Vector2(border_thickness * scale_factor, height * scale_factor))
	
	# 扫描内部墙壁区域（采样检查，不是每个像素）
	var sample_step = 8  # 每8个像素检查一次，进一步减少碰撞体
	for x in range(0, width, sample_step):
		for y in range(0, height, sample_step):
			var pixel = image.get_pixel(x, y)
			
			# 非红色且非绿色区域 - 墙壁
			if not (pixel.r > 0.9 and pixel.g < 0.1 and pixel.b < 0.1) and not (pixel.r < 0.1 and pixel.g > 0.9 and pixel.b < 0.1):
				# 创建小的墙壁块
				create_wall_rect(wall_container,
					Vector2(x, y) * scale_factor + offset,
					Vector2(sample_step * scale_factor, sample_step * scale_factor))

# 创建单个矩形墙壁碰撞体
static func create_wall_rect(parent: Node2D, pos: Vector2, size: Vector2):
	var static_body = StaticBody2D.new()
	var collision_shape = CollisionShape2D.new()
	var rect_shape = RectangleShape2D.new()
	
	rect_shape.size = size
	collision_shape.shape = rect_shape
	
	static_body.position = pos + size * 0.5  # 中心位置
	static_body.add_child(collision_shape)
	parent.add_child(static_body) 