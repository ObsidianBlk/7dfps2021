tool
extends StaticBody
class_name ZoneMap

# -------------------------------------------------------------------------
# Export Variables
# -------------------------------------------------------------------------

# -------------------------------------------------------------------------
# Variables
# -------------------------------------------------------------------------
var _zmd : ZoneMapData = null
var _meshinstance_node : MeshInstance = null

# -------------------------------------------------------------------------
# Onready Variables
# -------------------------------------------------------------------------


# -------------------------------------------------------------------------
# Override Methods
# -------------------------------------------------------------------------

func _get(property : String):
	match property:
		"zone_map_data":
			return _zmd
	return null

func _set(property : String, value) -> bool:
	var success = true
	match property:
		"zone_map_data":
			if value is ZoneMapData or value == null:
				_SetZMD(value)
			else : success = false
		_:
			success = false

	if success:
		property_list_changed_notify()
	return success

func _get_property_list() -> Array:
	return [
		{
			name = "Zone Map",
			type = TYPE_NIL,
			usage = PROPERTY_USAGE_CATEGORY
		},
		{
			name = "zone_map_data",
			type = TYPE_OBJECT,
			hint = PROPERTY_HINT_RESOURCE_TYPE,
			hint_string = "ZoneMapData",
			usage = PROPERTY_USAGE_DEFAULT
		}
	]

# -------------------------------------------------------------------------
# Private Methods
# -------------------------------------------------------------------------
func _SetZMD(zmd : ZoneMapData) -> void:
	if _zmd:
		_zmd.disconnect("changed", self, "_on_zmd_changed")
	_zmd = zmd
	if _zmd:
		_zmd.connect("changed", self, "_on_zmd_changed")


# -------------------------------------------------------------------------
# Public Methods
# -------------------------------------------------------------------------


# -------------------------------------------------------------------------
# Handler Methods
# -------------------------------------------------------------------------
func _on_zmd_changed() -> void:
	pass

