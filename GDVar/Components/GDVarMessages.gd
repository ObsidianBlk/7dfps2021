extends Control

# -----------------------------------------------------------------------------
# Signals
# -----------------------------------------------------------------------------
signal meta_object_clicked(meta)

# -----------------------------------------------------------------------------
# Export Variables
# -----------------------------------------------------------------------------
export var max_messages : int = 100

# -----------------------------------------------------------------------------
# Variables
# -----------------------------------------------------------------------------
var _messages : Array = []

# -----------------------------------------------------------------------------
# Onready Variables
# -----------------------------------------------------------------------------
onready var messages_node : VBoxContainer = get_node("Scroll/Messages")

# -----------------------------------------------------------------------------
# Setters / Getters
# -----------------------------------------------------------------------------
func set_max_messages(m : int) -> void:
	if m > 0:
		max_messages = m
		_CleanMessages()

# -----------------------------------------------------------------------------
# Override Methods
# -----------------------------------------------------------------------------
func _ready() -> void:
	GDVarCtrl.define_command({
		"name":"clear_messages",
		"description":"Clear all messages in the terminal window.",
		"owner":self,
		"method":"_CMD_ClearMessages"
	})
	GDVarCtrl.connect("message", self, "_on_gdvar_message")

# -----------------------------------------------------------------------------
# GDVarCommand Methods
# -----------------------------------------------------------------------------
func _CMD_ClearMessages() -> void:
	clear_messages()

# -----------------------------------------------------------------------------
# Private Methods
# -----------------------------------------------------------------------------
func _CleanMessages() -> void:
	while _messages.size() > max_messages:
		var msg : Node = _messages.pop_front()
		msg.get_parent().remove_child(msg)
		msg.queue_free()

func _ThemeLabel(type : int, lbl : RichTextLabel) -> void:
	if has_font("normal_font", "GDVarMessage"):
		lbl.add_font_override("normal_font", get_font("normal_font", "GDVarMessage"))
	if has_font("italics_font", "GDVarMessage"):
		lbl.add_font_override("italics_font", get_font("italics_font", "GDVarMessage"))
	if has_font("bold_font", "GDVarMessage"):
		lbl.add_font_override("bold_font", get_font("bold_font", "GDVarMessage"))
	if has_font("bold_italics_font", "GDVarMessage"):
		lbl.add_font_override("bold_italics_font", get_font("bold_italics_font", "GDVarMessage"))
	if has_font("mono_font", "GDVarMessage"):
		lbl.add_font_override("mono_font", get_font("mono_font", "GDVarMessage"))

	var style : StyleBox = null
	var color : Color = Color(1,1,1,1)
	match type:
		GDVarCtrl.LOG_TYPE.INFO:
			if has_stylebox("info", "GDVarMessage"):
				style = get_stylebox("info", "GDVarMessage")
			if has_color("info", "GDVarMessage"):
				color = get_color("info", "GDVarMessage")
		GDVarCtrl.LOG_TYPE.DEBUG:
			if has_stylebox("debug", "GDVarMessage"):
				style = get_stylebox("debug", "GDVarMessage")
			if has_color("debug", "GDVarMessage"):
				color = get_color("debug", "GDVarMessage")
		GDVarCtrl.LOG_TYPE.WARNING:
			if has_stylebox("warning", "GDVarMessage"):
				style = get_stylebox("warning", "GDVarMessage")
			if has_color("warning", "GDVarMessage"):
				color = get_color("warning", "GDVarMessage")
		GDVarCtrl.LOG_TYPE.ERROR:
			if has_stylebox("error", "GDVarMessage"):
				style = get_stylebox("error", "GDVarMessage")
			if has_color("error", "GDVarMessage"):
				color = get_color("error", "GDVarMessage")
	
	if style != null:
		lbl.add_stylebox_override("normal", style)
		lbl.add_stylebox_override("focus", style)
		lbl.add_color_override("default_color", color)

# -----------------------------------------------------------------------------
# Public Methods
# -----------------------------------------------------------------------------
func clear_messages() -> void:
	while _messages.size() > 0:
		var msg : Node = _messages.pop_front()
		msg.get_parent().remove_child(msg)
		msg.queue_free()

# -----------------------------------------------------------------------------
# Handler Methods
# -----------------------------------------------------------------------------
func _on_gdvar_message(type : int , msg : String) -> void:
	var lbl : RichTextLabel = RichTextLabel.new()
	lbl.scroll_active = false
	lbl.meta_underlined = false
	lbl.fit_content_height = true
	lbl.bbcode_enabled = true
	_messages.append(lbl)
	messages_node.add_child(lbl)
	lbl.bbcode_text = msg
	_ThemeLabel(type, lbl)
	_CleanMessages()

func _on_meta_clicked(meta) -> void:
	if typeof(meta) == TYPE_STRING:
		var jres = JSON.parse(meta)
		if jres.error == OK:
			emit_signal("meta_object_clicked", jres.result)
		else: # Assume it's an URL:
			OS.shell_open(meta)

