extends Reference
class_name GDVar

# -----------------------------------------------------------------------------
# Signals
# -----------------------------------------------------------------------------
signal value_changed(var_name, new_value, old_value)
signal watch(vname, enable)
signal invalidated(gdvar)


const ALLOWED_TYPES = [
	TYPE_BOOL,
	TYPE_COLOR,
	TYPE_INT,
	TYPE_REAL,
	TYPE_STRING,
	TYPE_VECTOR2,
	TYPE_VECTOR3,
	TYPE_RECT2
]

# -----------------------------------------------------------------------------
# Variables
# -----------------------------------------------------------------------------
var __value = null
var __type : int = TYPE_NIL
var __name : String = "GDVar"
var __owner : Node = null

# -----------------------------------------------------------------------------
# Override Methods
# -----------------------------------------------------------------------------
func _init(owner : Node, name : String, value) -> void:
	var type = typeof(value)
	if type in ALLOWED_TYPES:
		__value = value
		__type = type
		__name = name
		__owner = owner

func _get(property : String):
	if is_valid():
		match property:
			"value":
				return __value
			"type":
				return __type
	return null

func _set(property : String, value) -> bool:
	if is_valid():
		if property == "value" and typeof(value) == __type:
			var old_val = __value
			__value = value
			emit_signal("value_changed", __name, __value, old_val)
			return true
	return false

func _get_property_list() -> Array:
	var properties = []
	if is_valid():
		properties.append({
			name = "value",
			type = __type,
			usage = PROPERTY_USAGE_DEFAULT
		})
		properties.append({
			name = "type",
			type = TYPE_INT,
			usage = PROPERTY_USAGE_DEFAULT
		})
	return properties

# -----------------------------------------------------------------------------
# Private Methods
# -----------------------------------------------------------------------------


# -----------------------------------------------------------------------------
# Public Methods
# -----------------------------------------------------------------------------
func is_valid() -> bool:
	if __owner != null:
		if not is_instance_valid(__owner):
			__owner = null
			emit_signal("invalidated", self)
	return __owner != null and __type != TYPE_NIL and __value != null

func name() -> String:
	return __name

func owner_name() -> String:
	if is_valid():
		return __owner.name
	return ""

func watch(enable : bool = true) -> void:
	emit_signal("watch", __name, enable)

func release() -> void:
	__owner = null
	emit_signal("invalidated", self)
