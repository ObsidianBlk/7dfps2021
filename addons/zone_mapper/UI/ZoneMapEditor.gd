tool
extends Control



# -------------------------------------------------------------------------
# Signals
# -------------------------------------------------------------------------
signal close

# -------------------------------------------------------------------------
# Constants
# -------------------------------------------------------------------------


# -------------------------------------------------------------------------
# Variables
# -------------------------------------------------------------------------
var _zmd : WeakRef = null
var _timer : Timer = null

# -------------------------------------------------------------------------
# Onready Variables
# -------------------------------------------------------------------------
onready var zonemapdisplay_node = get_node("ZoneMapDisplay")

# -------------------------------------------------------------------------
# Override Methods
# -------------------------------------------------------------------------
func _ready() -> void:
	_timer = Timer.new()
	_timer.one_shot = true
	add_child(_timer)
	_timer.connect("timeout", self, "_on_save_timer_timeout")
	
	var zmd = _GetZMD()
	if zmd:
		zonemapdisplay_node.set_zone_map_data(zmd)

# -------------------------------------------------------------------------
# Private Methods
# -------------------------------------------------------------------------
func _GetZMD() -> ZoneMapData:
	if _zmd != null:
		var zmd = _zmd.get_ref()
		if zmd: return zmd
	return null


func _SaveZMD() -> void:
	var zmd = _GetZMD()
	if zmd:
		if zmd.resource_path != "":
			var err = ResourceSaver.save(zmd.resource_path, zmd)
			if err != OK:
				push_error("Failed to save ZoneMapData to path \"%s\". Error Code: %s"%[zmd.resource_path, String(err)])
			else:
				print("Saved ZoneMapData: %s"%[zmd.resource_path])
	else:
		emit_signal("close")

# -------------------------------------------------------------------------
# Public Methods
# -------------------------------------------------------------------------
func edit_zone_map(zmd : ZoneMapData) -> void:
	if _zmd:
		save(true)
	_zmd = weakref(zmd)
	if zonemapdisplay_node:
		zonemapdisplay_node.set_zone_map_data(zmd)


func save(immediate : bool = false) -> void:
	if not is_inside_tree():
		return
	if immediate:
		_timer.stop()
		_SaveZMD()
	_timer.start(2.5)


# -------------------------------------------------------------------------
# Handler Methods
# -------------------------------------------------------------------------
func _on_save_timer_timeout() -> void:
	_SaveZMD()

