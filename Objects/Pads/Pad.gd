extends Spatial

# -------------------------------------------------------------------------
# Signals
# -------------------------------------------------------------------------
signal pad_triggered()

# -------------------------------------------------------------------------
# Export Variables
# -------------------------------------------------------------------------
export var message : String = ""
export var clear_messages : bool = true
export var chime_on_trigger : bool = true
export var one_shot : bool = true

# -------------------------------------------------------------------------
# Variables
# -------------------------------------------------------------------------

# -------------------------------------------------------------------------
# Onready Variables
# -------------------------------------------------------------------------
onready var area_node : Area = get_node("Area")

# -------------------------------------------------------------------------
# Override Methods
# -------------------------------------------------------------------------
func _ready() -> void:
	area_node.connect("body_entered", self, "_on_body_entered")

# -------------------------------------------------------------------------
# Private Methods
# -------------------------------------------------------------------------
func _SendMessage() -> void:
	print("Sending message: ", message)
	if message != "":
		if clear_messages:
			GDVarCtrl.call_command("clear_messages")
		GDVarCtrl.info(message)
		if chime_on_trigger:
			AudioCtrl.play_sfx("res://Assets/Audio/SFX/terminal_chime.wav")
	emit_signal("pad_triggered")
	if one_shot:
		call_deferred("_die")

func _die() -> void:
	var parent = get_parent()
	if parent:
		parent.remove_child(self)
	call_deferred("queue_free")


# -------------------------------------------------------------------------
# Public Methods
# -------------------------------------------------------------------------


# -------------------------------------------------------------------------
# Handler Methods
# -------------------------------------------------------------------------
func _on_body_entered(body : Spatial) -> void:
	if body.is_in_group("Player"):
		_SendMessage()
