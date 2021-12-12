extends Spatial

# -------------------------------------------------------------------------
# Export Variables
# -------------------------------------------------------------------------
export var text : String = ""		setget set_text
export (float, 0.0, 360.0) var degrees_per_second = 5.0

# -------------------------------------------------------------------------
# Variables
# -------------------------------------------------------------------------
var _text = ""

# -------------------------------------------------------------------------
# Onready Variables
# -------------------------------------------------------------------------
onready var marquee_node : Spatial = get_node("Marquee")
onready var label_node : Label = get_node("Viewport/CanvasLayer/PanelContainer/Container/Label")

# -------------------------------------------------------------------------
# Setters
# -------------------------------------------------------------------------
func set_text(t : String) -> void:
	_text = t
	if label_node:
		label_node.text = _text

# -------------------------------------------------------------------------
# Onready Variables
# -------------------------------------------------------------------------
func _ready() -> void:
	label_node.text = _text

func _physics_process(delta : float) -> void:
	marquee_node.rotation.y += deg2rad(degrees_per_second * delta)

