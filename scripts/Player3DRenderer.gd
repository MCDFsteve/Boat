@tool
extends SubViewport

@onready var camera = $Camera3D
@onready var player_model_container = $PlayerModel

var player_model: Node3D
var current_direction: Vector2 = Vector2.DOWN
var equipment_nodes: Dictionary = {}

# 描边效果配置
enum OutlineStyle {
	NONE,
	SIMPLE,
	PIXEL
}
var current_outline_style: OutlineStyle = OutlineStyle.PIXEL

# 四个方向的模型旋转角度（让模型转向摄像机）
var model_angles = {
	"down": Vector3(0, 0, 0),      # 正面朝向摄像机
	"up": Vector3(0, 180, 0),      # 背面朝向摄像机
	"left": Vector3(0, -90, 0),    # 左侧朝向摄像机（修复反向）
	"right": Vector3(0, 90, 0)     # 右侧朝向摄像机（修复反向）
}

func _ready():
	# 加载玩家3D模型
	load_player_model()
	
	# 设置透明背景 - 在Godot 4.4中使用render_target_clear_mode
	render_target_clear_mode = SubViewport.CLEAR_MODE_ALWAYS
	transparent_bg = true

func load_player_model():
	# 清理之前的模型
	if player_model:
		player_model.queue_free()
		player_model = null
	
	# 清空容器
	for child in player_model_container.get_children():
		child.queue_free()
	
	# 等待清理完成
	if Engine.is_editor_hint():
		await get_tree().process_frame
	
	# 加载你的player.glb模型
	var gltf_path = "res://assets/player/player.glb"
	
	if ResourceLoader.exists(gltf_path):
		var gltf_scene = load(gltf_path)
		if gltf_scene:
			player_model = gltf_scene.instantiate()
			player_model_container.add_child(player_model)
			
			# 调整模型缩放 - 根据需要修改这个值
			player_model.scale = Vector3(0.5, 0.5, 0.5)  # 缩小到50%
			
			# 应用简化的三渲二材质
			apply_toon_material()
			
			# 在编辑器中强制渲染一帧
			if Engine.is_editor_hint():
				await get_tree().process_frame
				render_target_update_mode = SubViewport.UPDATE_ONCE
				await get_tree().process_frame
				render_target_update_mode = SubViewport.UPDATE_ALWAYS
		else:
			create_fallback_model()
	else:
		create_fallback_model()

func create_fallback_model():
	# 创建一个简单的立方体作为后备
	var mesh_instance = MeshInstance3D.new()
	var box_mesh = BoxMesh.new()
	box_mesh.size = Vector3(1, 1, 1)
	mesh_instance.mesh = box_mesh
	
	player_model = mesh_instance
	player_model_container.add_child(player_model)
	
	# 应用简化的三渲二材质
	apply_toon_material()

func update_direction(direction: Vector2):
	if direction == current_direction:
		return
		
	current_direction = direction
	
	# 根据方向旋转模型
	var target_rotation = Vector3.ZERO
	if direction.x > 0.5:  # 右
		target_rotation = model_angles["right"]
	elif direction.x < -0.5:  # 左
		target_rotation = model_angles["left"]
	elif direction.y > 0.5:  # 下
		target_rotation = model_angles["down"]
	elif direction.y < -0.5:  # 上
		target_rotation = model_angles["up"]
	
	# 平滑旋转
	if player_model:
		var tween = create_tween()
		tween.tween_property(player_model, "rotation_degrees", target_rotation, 0.1)

func add_equipment(equipment_type: String, equipment_model_path: String):
	# 添加装备模型
	if equipment_nodes.has(equipment_type):
		# 移除旧装备
		equipment_nodes[equipment_type].queue_free()
	
	# 加载新装备
	var equipment_scene = load(equipment_model_path)
	if equipment_scene:
		var equipment_node = equipment_scene.instantiate()
		player_model.add_child(equipment_node)
		equipment_nodes[equipment_type] = equipment_node

func remove_equipment(equipment_type: String):
	if equipment_nodes.has(equipment_type):
		equipment_nodes[equipment_type].queue_free()
		equipment_nodes.erase(equipment_type)

func apply_toon_material():
	# 只使用卡通材质，不在3D阶段做描边
	var toon_material = load("res://assets/player/extreme_toon_material.tres")
	if not toon_material:
		# 如果无法加载toon材质，使用标准材质
		create_standard_material()
		return
	
	# 递归应用材质到所有网格
	apply_material_recursive(player_model, toon_material)

func create_standard_material():
	# 创建标准材质作为备用
	var material = StandardMaterial3D.new()
	material.albedo_color = Color.WHITE
	
	# 尝试加载纹理
	var texture = load("res://assets/player/texture.png")
	if texture:
		material.albedo_texture = texture
	
	# 应用材质
	apply_material_recursive(player_model, material)

func apply_material_recursive(node: Node, material: Material):
	# 如果是MeshInstance3D节点，应用材质
	if node is MeshInstance3D:
		var mesh_instance = node as MeshInstance3D
		mesh_instance.material_override = material
	
	# 递归处理子节点
	for child in node.get_children():
		apply_material_recursive(child, material)

func apply_dual_material_recursive(node: Node, toon_material: Material, outline_material: Material):
	# 先收集所有原始子节点，避免处理新创建的描边节点
	var original_children = []
	for child in node.get_children():
		original_children.append(child)
	
	# 如果是MeshInstance3D节点，创建双材质效果
	if node is MeshInstance3D:
		var mesh_instance = node as MeshInstance3D
		
		# 清理之前可能存在的描边节点
		for child in node.get_children():
			if child.name.begins_with("_outline_"):
				child.queue_free()
		
		# 如果描边材质存在，需要创建两个网格实例实现描边效果
		if outline_material:
			# 先创建描边层（放大的背面）
			var outline_instance = MeshInstance3D.new()
			outline_instance.name = "_outline_" + mesh_instance.name
			outline_instance.mesh = mesh_instance.mesh
			outline_instance.material_override = outline_material
			
			# 将描边层作为子节点添加到原网格的父节点
			var parent_node = mesh_instance.get_parent()
			if parent_node:
				parent_node.add_child(outline_instance)
				outline_instance.owner = mesh_instance.owner
				# 确保描边层在原网格之前渲染
				parent_node.move_child(outline_instance, mesh_instance.get_index())
		
		# 应用卡通材质到原网格
		mesh_instance.material_override = toon_material
	
	# 只递归处理原始子节点，避免处理新创建的描边节点
	for child in original_children:
		apply_dual_material_recursive(child, toon_material, outline_material)

func set_outline_style(style: OutlineStyle):
	# 切换描边样式
	current_outline_style = style

func get_rendered_texture() -> ImageTexture:
	# 获取渲染的纹理
	await RenderingServer.frame_post_draw
	var image = get_texture().get_image()
	var texture = ImageTexture.new()
	texture.set_image(image)
	return texture 