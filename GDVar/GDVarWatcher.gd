extends "res://GDVar/Components/SlidingTerminal.gd"
tool

# -----------------------------------------------------------------------------
# Property Variables
# -----------------------------------------------------------------------------


# -------------------------------------------------------------------------
# Variables
# -------------------------------------------------------------------------


# -------------------------------------------------------------------------
# Onready Variables
# -------------------------------------------------------------------------
onready var gdvarwatch_node = get_node("PC/GDVarWatch")
onready var panel_node = get_node("PC")

# -------------------------------------------------------------------------
# Override Methods
# -------------------------------------------------------------------------
func _ready():
	_UpdateStyles()
	GDVarCtrl.connect("watch", self, "_on_watch")
	GDVarCtrl.connect("unwatch", self, "_on_unwatch")

# -------------------------------------------------------------------------
# Private Methods
# -------------------------------------------------------------------------
func _CheckToDisplay() -> void:
	if gdvarwatch_node:
		var count = gdvarwatch_node.watch_variable_count()
		if visible and count <= 0:
			_SlideOut(not __animation_slide_out)
		elif not visible and count > 0:
			_SlideIn(not __animation_slide_out) 


# -------------------------------------------------------------------------
# Public Methods
# -------------------------------------------------------------------------
func _UpdateStyles() -> void:
	if Engine.editor_hint:
		return
	._UpdateStyles()
	_OverrideStyle(panel_node, "panel", "panel", "GDVarWatcher")

# -------------------------------------------------------------------------
# Handler Methods
# -------------------------------------------------------------------------
func _on_watch(_v : GDVar) -> void:
	call_deferred("_CheckToDisplay")

func _on_unwatch(_v : GDVar) -> void:
	call_deferred("_CheckToDisplay")


