tool
extends EditorPlugin


# -----------------------------------------------------------------------------
# Variables
# -----------------------------------------------------------------------------
var _ZoneMapEditor : Control = null


# -----------------------------------------------------------------------------
# Override Methods
# -----------------------------------------------------------------------------
func _enter_tree():
	get_editor_interface().get_resource_filesystem().connect("filesystem_changed", self, "_on_filesystem_changed")

func _exit_tree():
	close_editor()

# -----------------------------------------------------------------------------
# Public Methods
# -----------------------------------------------------------------------------
func open_editor(zmd : Object) -> void:
	if not is_instance_valid(_ZoneMapEditor):
		_ZoneMapEditor = preload("./UI/ZoneMapEditor.tscn").instance()
		add_control_to_bottom_panel(_ZoneMapEditor, "Zone Map Editor")
		_ZoneMapEditor.connect("close", self, "close_editor")
	
	#_ZoneMapEditor.edit_zone(zmd)
	make_bottom_panel_item_visible(_ZoneMapEditor)

func close_editor() -> void:
	if is_instance_valid(_ZoneMapEditor):
		#_ZoneMapEditor.save_now()
		hide_bottom_panel()
		remove_control_from_bottom_panel(_ZoneMapEditor)
		_ZoneMapEditor.queue_free()

# -----------------------------------------------------------------------------
# Handler Methods
# -----------------------------------------------------------------------------
func _on_filesystem_changed() -> void:
	pass
