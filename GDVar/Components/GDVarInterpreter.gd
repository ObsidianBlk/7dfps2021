extends Control

# -----------------------------------------------------------------------------
# Signals
# -----------------------------------------------------------------------------
signal close_request()

# -----------------------------------------------------------------------------
# Export Variables
# -----------------------------------------------------------------------------
export var auto_log_command : bool = true
export var auto_log_color : Color = Color(1.0, 0.8, 0.0)
export var action_name : String = ""

# -----------------------------------------------------------------------------
# Variables
# -----------------------------------------------------------------------------


# -----------------------------------------------------------------------------
# Onready Variables
# -----------------------------------------------------------------------------
onready var cmd_node : LineEdit = get_node("Cmd")


# -----------------------------------------------------------------------------
# Override Methods
# -----------------------------------------------------------------------------
func _ready() -> void:
	cmd_node.connect("text_entered", self, "_on_command_entered")
	cmd_node.connect("gui_input", self, "_on_gui_input")


# -----------------------------------------------------------------------------
# Private Methods
# -----------------------------------------------------------------------------
func grab_focus() -> void:
	cmd_node.grab_focus()

# -----------------------------------------------------------------------------
# Handler Methods
# -----------------------------------------------------------------------------
func _on_command_entered(cmd : String) -> void:
	if auto_log_command:
		GDVarCtrl.info("[i][color=#%s]%s[/color][/i]"%[auto_log_color.to_html(false), cmd])
	cmd_node.text = ""
	GDVarCtrl.interpret(cmd)


func _on_gui_input(event : InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		cmd_node.release_focus()
	if action_name != "":
		if cmd_node.has_focus() and event.is_action_pressed("terminal"):
			cmd_node.text = ""
			emit_signal("close_request")
