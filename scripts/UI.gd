extends CanvasLayer

@onready var health_label = $UIControl/HealthLabel
@onready var room_label = $UIControl/RoomLabel
@onready var seed_label = $UIControl/SeedLabel

func _ready():
	GameManager.room_changed.connect(_on_room_changed)

func _process(delta):
	update_ui()

func update_ui():
	if health_label:
		health_label.text = "Health: " + str(GameManager.player_health)
	if room_label:
		var coordinate_text = "(" + str(GameManager.current_room_coordinate.x) + "," + str(GameManager.current_room_coordinate.y) + ")"
		room_label.text = "Room: " + GameManager.current_room_type + " " + coordinate_text
	if seed_label:
		seed_label.text = SeedSystem.get_seed_display_string()

func _on_room_changed(room_id: String, room_config: Dictionary, entry_direction: String):
	if room_label:
		var coordinate_text = "(" + str(GameManager.current_room_coordinate.x) + "," + str(GameManager.current_room_coordinate.y) + ")"
		room_label.text = "Room: " + GameManager.current_room_type + " " + coordinate_text 