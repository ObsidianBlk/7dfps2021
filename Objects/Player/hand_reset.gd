extends Viewport

onready var idlehand_node : TextureRect = get_node("CanvasLayer/IdleHand")
onready var attackhand_node : TextureRect = get_node("CanvasLayer/AttackHand")

func _ready() -> void:
	idlehand_node.rect_size = Vector2(1920, 1080)
	attackhand_node.rect_size = Vector2(1920, 1080)
