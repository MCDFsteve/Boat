extends Area2D

@export var heal_amount: int = 20

func _ready():
	add_to_group("items")
	body_entered.connect(_on_body_entered)

func _on_body_entered(body):
	if body.name == "Player":
		GameManager.heal(heal_amount)
		queue_free() 