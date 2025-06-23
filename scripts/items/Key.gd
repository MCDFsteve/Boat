extends Area2D

func _ready():
	add_to_group("items")
	body_entered.connect(_on_body_entered)

func _on_body_entered(body):
	if body.name == "Player":
		# 这里可以添加钥匙收集逻辑
		queue_free() 