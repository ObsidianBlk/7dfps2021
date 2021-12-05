tool
extends EditorPlugin


# -----------------------------------------------------------------------------
# Variables
# -----------------------------------------------------------------------------
var _ZoneMapEditor : Control = null
var _zmd : WeakRef = null
var _is_disk_resource : bool = false

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
func handles(object : Object) -> bool:
	if object is ZoneMapData:
		return true
	elif _zmd != null:
		_zmd = null
		close_editor()
	return false


func edit(object : Object) -> void:
	var zmd : ZoneMapData = object as ZoneMapData
	_zmd = weakref(zmd)
	_is_disk_resource = zmd.resource_path != ""
	open_editor(zmd)


func open_editor(zmd : Object) -> void:
	if not is_instance_valid(_ZoneMapEditor):
		_ZoneMapEditor = preload("./UI/ZoneMapEditor.tscn").instance()
		add_control_to_bottom_panel(_ZoneMapEditor, "Zone Map Editor")
		_ZoneMapEditor.connect("close", self, "close_editor")
	
	_ZoneMapEditor.edit_zone_map(zmd)
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
	if _zmd and _is_disk_resource:
		var zmd = _zmd.get_ref()
		if not zmd or zmd.resource_path == "":
			_zmd = null
			close_editor()
