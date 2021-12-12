extends "res://GDVar/Components/SlidingTerminal.gd"
tool


# -----------------------------------------------------------------------------
# Signals
# -----------------------------------------------------------------------------
signal meta_object_clicked(meta)

# -----------------------------------------------------------------------------
# Constants and ENUMs
# -----------------------------------------------------------------------------
const THEME_TYPE = "GDVarTerminal"


# -----------------------------------------------------------------------------
# Property Variables
# -----------------------------------------------------------------------------
var __themestyle_messages : StyleBox = null
var __themestyle_command : StyleBox = null

var __action_name : String = ""
var __auto_log_command : bool = true
var __auto_log_color : Color = Color(1.0, 0.8, 0.0)


# -----------------------------------------------------------------------------
# Variables
# -----------------------------------------------------------------------------


# -----------------------------------------------------------------------------
# Onready Variables
# -----------------------------------------------------------------------------
onready var messages_node : PanelContainer = get_node("Messenger/Messages")
onready var commands_node : PanelContainer = get_node("Messenger/Commands")
onready var interpreter_node = get_node("Messenger/Commands/GDVarInterpreter")

# -----------------------------------------------------------------------------
# Override Methods
# -----------------------------------------------------------------------------
func _ready() -> void:
	_UpdateStyles()
	if not Engine.editor_hint:
		$Messenger/Messages/GDVarMessages.connect("meta_object_clicked", self, "_on_meta_object_clicked")
		interpreter_node.connect("close_request", self, "_on_close_request")
		if interpreter_node.auto_log_command != __auto_log_command:
			interpreter_node.auto_log_command = __auto_log_command
		if interpreter_node.auto_log_color != __auto_log_color:
			interpreter_node.auto_log_color = __auto_log_color
		if interpreter_node.action_name != __action_name:
			interpreter_node.action_name = __action_name

func _get(property : String):
	match property:
		"config/action_name":
			return __action_name
		"config/auto_log_command":
			return __auto_log_command
		"config/auto_log_color":
			return __auto_log_color
		"theme_overrides/styles/messages":
			return __themestyle_messages
		"theme_overrides/styles/command":
			return __themestyle_command
	return null

func _set(property : String, value) -> bool:
	var success = true
	match property:
		"config/action_name":
			if typeof(value) == TYPE_STRING:
				if interpreter_node:
					interpreter_node.action_name = value
				__action_name = value
			else : success = false
		"config/auto_log_command":
			if typeof(value) == TYPE_BOOL:
				if interpreter_node:
					interpreter_node.auto_log_command = value
				__auto_log_command = value
			else : success = false
		"config/auto_log_color":
			if typeof(value) == TYPE_COLOR:
				if interpreter_node:
					interpreter_node.auto_log_color = value
				__auto_log_color = value
			else : success = false
		"theme_overrides/styles/messages":
			if value is StyleBox:
				__themestyle_messages = value
				if __ready or Engine.editor_hint:
					_UpdateStyles()
			else: success = false
		"theme_overrides/styles/commands":
			if value is StyleBox:
				__themestyle_command = value
				if __ready or Engine.editor_hint:
					_UpdateStyles()
			else: success = false
		_:
			success = false
	
	if success:
		property_list_changed_notify()
	return success


func _get_property_list():
	return [
		{
			name = "GDVar Terminal",
			type = TYPE_NIL,
			usage = PROPERTY_USAGE_CATEGORY
		},
		{
			name = "config/action_name",
			type = TYPE_STRING,
			usage = PROPERTY_USAGE_DEFAULT
		},
		{
			name = "config/auto_log_command",
			type = TYPE_BOOL,
			usage = PROPERTY_USAGE_DEFAULT
		},
		{
			name = "config/auto_log_color",
			type = TYPE_COLOR,
			usage = PROPERTY_USAGE_DEFAULT
		},
		{
			name = "theme_overrides/styles/messages",
			type = TYPE_OBJECT,
			hint = PROPERTY_HINT_RESOURCE_TYPE,
			hint_string = "StyleBox",
			usage = PROPERTY_USAGE_DEFAULT
		},
		{
			name = "theme_overrides/styles/command",
			type = TYPE_OBJECT,
			hint = PROPERTY_HINT_RESOURCE_TYPE,
			hint_string = "StyleBox",
			usage = PROPERTY_USAGE_DEFAULT
		}
	]

# -----------------------------------------------------------------------------
# Private Methods
# -----------------------------------------------------------------------------
func _UpdateStyles() -> void:
	if Engine.editor_hint:
		return
	._UpdateStyles()
	_OverrideStyle(messages_node, "panel", "messages", THEME_TYPE)
	_OverrideStyle(commands_node, "panel", "command", THEME_TYPE)

func _SlideIn(instant : bool = false) -> void:
	if interpreter_node:
		interpreter_node.grab_focus()
	._SlideIn(instant)


# -----------------------------------------------------------------------------
# Public Methods
# -----------------------------------------------------------------------------
func clear_messages() -> void:
	messages_node.clear_messages()

# -----------------------------------------------------------------------------
# Handler Methods
# -----------------------------------------------------------------------------
func _on_close_request() -> void:
	if visible:
		_SlideOut(not __animation_slide_out)

func _on_meta_object_clicked(meta : Dictionary) -> void:
	# A simple passthrough signal handler.
	emit_signal("meta_object_clicked", meta)


