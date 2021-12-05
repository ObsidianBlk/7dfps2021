extends Control

# -------------------------------------------------------------------------
# Signals
# -------------------------------------------------------------------------
signal zone_index_selected(zone_index)

# -------------------------------------------------------------------------
# Variables
# -------------------------------------------------------------------------
var _zmd : WeakRef = null
var _selected_zidx : int = -1

# -------------------------------------------------------------------------
# Onready Variables
# -------------------------------------------------------------------------
onready var zoneindexdrop_node : OptionButton = get_node("VBC/ZoneList/ZoneIndexDrop")
onready var removezone_btn : Button = get_node("VBC/ZoneList/RemoveZone")
onready var addzone_btn : Button = get_node("VBC/ZoneList/AddZone")

onready var floorheight_node : LineEdit = get_node("VBC/ZoneSettings/FloorHeight")
onready var ceilingheight_node : LineEdit = get_node("VBC/ZoneSettings/CeilingHeight")

# -------------------------------------------------------------------------
# Override Methods
# -------------------------------------------------------------------------
func _ready() -> void:
	if has_icon("Add", "EditorIcons"):
		addzone_btn.icon = get_icon("Add", "EditorIcons")
	else:
		addzone_btn.text = "+"
	addzone_btn.connect("pressed", self, "_on_add_zone")
	
	if has_icon("Close", "EditorIcons"):
		removezone_btn.icon = get_icon("Close", "EditorIcons")
	else:
		removezone_btn.text = "x"
	removezone_btn.connect("pressed", self, "_on_remove_zone")
	
	zoneindexdrop_node.connect("item_selected", self, "_on_item_selected")

# -------------------------------------------------------------------------
# Private Methods
# -------------------------------------------------------------------------
func _GetZMD() -> ZoneMapData:
	if _zmd != null:
		var zmd = _zmd.get_ref()
		if zmd: return zmd
	return null

func _UpdateZoneList() -> void:
	var zmd = _GetZMD()
	if not zmd:
		zoneindexdrop_node.clear()
		_selected_zidx = -1
		return
	
	if zmd.get_zone_count() > 0:
		for i in range(zmd.get_zone_count()):
			var zdim = zmd.get_zone_dimensions(i)
			if zdim != null:
				var lbl = "%s - Floor ( %s ) : Ceiling ( %s )"%[i, zdim.floor, zdim.height]
				zoneindexdrop_node.add_item("", i)
		if _selected_zidx < 0:
			_selected_zidx = 0
		zoneindexdrop_node.select(_selected_zidx)
		_UpdateZoneSettings()
	else:
		_selected_zidx = -1

func _UpdateZoneSettings() -> void:
	var zmd = _GetZMD()
	if zmd and _selected_zidx >= 0:
		var zdim = zmd.get_zone_dimensions(_selected_zidx)
		if zdim != null:
			floorheight_node.text = String(zdim.floor)
			floorheight_node.editable = true
			ceilingheight_node.text = String(zdim.ceiling)
			ceilingheight_node.editable = true
	else:
		floorheight_node.text = ""
		floorheight_node.editable = false
		ceilingheight_node.text = ""
		ceilingheight_node.editable = false

# -------------------------------------------------------------------------
# Public Methods
# -------------------------------------------------------------------------
func set_zone_map_data(zmd : ZoneMapData) -> void:
	if _zmd != null:
		var ref = _zmd.get_ref()
		if ref:
			ref.disconnect("zone_added", self, "_on_zmd_zone_added")
			ref.disconnect("zone_removed", self, "_on_zmd_zone_removed")
	_zmd = weakref(zmd)
	zmd.connect("zone_added", self, "_on_zmd_zone_added")
	zmd.connect("zone_removed", self, "_on_zmd_zone_removed")


# -------------------------------------------------------------------------
# Handler Methods
# -------------------------------------------------------------------------
func _on_add_zone() -> void:
	pass

func _on_remove_zone() -> void:
	pass


func _on_zmd_zone_added(new_zone_index : int) -> void:
	var sel_changed = false
	if _selected_zidx > 0 and new_zone_index <= _selected_zidx:
		_selected_zidx += 1
		sel_changed = true
	_UpdateZoneList()
	if sel_changed:
		emit_signal("zone_index_selected", _selected_zidx)

func _on_zmd_zone_removed(old_zone_index : int) -> void:
	var sel_changed = false
	if _selected_zidx > 0 and old_zone_index < _selected_zidx:
		_selected_zidx -= 1
		sel_changed = true
	_UpdateZoneList()
	if sel_changed:
		emit_signal("zone_index_selected", _selected_zidx)


func _on_item_selected(item : int) -> void:
	var zmd = _GetZMD()
	if zmd:
		if item >= 0 and item < zmd.get_zone_count():
			_selected_zidx = item
			_UpdateZoneSettings()


