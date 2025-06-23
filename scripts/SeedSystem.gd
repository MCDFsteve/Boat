extends Node

# 种子系统 - 独立的种子管理单例
# 使用方法：将此脚本添加到项目设置 -> 自动加载中，名称为 "SeedSystem"

var current_seed: int = 0
var rng: RandomNumberGenerator

func _ready():
	rng = RandomNumberGenerator.new()
	generate_new_seed()

# 生成新的种子
func generate_new_seed():
	current_seed = Time.get_unix_time_from_system()
	rng.seed = current_seed

# 设置指定的种子
func set_seed(seed: int):
	current_seed = seed
	rng.seed = seed

# 获取当前种子
func get_current_seed() -> int:
	return current_seed

# 生成随机整数 (替代 randi())
func randi() -> int:
	return rng.randi()

# 生成指定范围内的随机整数 (替代 randi() % max)
func randi_range(from: int, to: int) -> int:
	return rng.randi_range(from, to)

# 生成随机浮点数 (替代 randf())
func randf() -> float:
	return rng.randf()

# 生成指定范围内的随机浮点数 (替代 randf_range())
func randf_range(from: float, to: float) -> float:
	return rng.randf_range(from, to)

# 从数组中随机选择一个元素
func choose_random(array: Array):
	if array.size() == 0:
		return null
	return array[randi_range(0, array.size() - 1)]

# 格式化种子显示（用于UI显示）
func get_seed_display_string() -> String:
	return "Seed: " + str(current_seed)

# 重新生成所有随机内容（用于调试或重置）
func regenerate_with_current_seed():
	rng.seed = current_seed

# 获取当前随机数生成器状态（用于调试）
func get_debug_info() -> String:
	return "Current seed: " + str(current_seed) + ", RNG initialized: " + str(rng != null) 