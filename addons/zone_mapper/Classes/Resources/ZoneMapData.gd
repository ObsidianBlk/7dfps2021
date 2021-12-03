extends Resource
class_name ZoneMapData

# -----------------------------------------------------------------------------
# Signals
# -----------------------------------------------------------------------------


# -----------------------------------------------------------------------------
# ENUMs
# -----------------------------------------------------------------------------
enum WALL_FACE {North=1, East=2, South=4, West=8}
enum WALL_SURF {Top=1, Middle=2, Bottom=4, Edges=5, Full=7}

# -----------------------------------------------------------------------------
# Export Variables
# -----------------------------------------------------------------------------


# -----------------------------------------------------------------------------
# Variables
# -----------------------------------------------------------------------------
var _Map : Array = []
var _dirty : bool = false

# -----------------------------------------------------------------------------
# Override Methods
# -----------------------------------------------------------------------------
func _ready():
	pass


# -----------------------------------------------------------------------------
# Private Methods
# -----------------------------------------------------------------------------
func _SetDirty() -> void:
	_dirty = true
	emit_changed()


func _GetZoneDimension(zidx : int) -> Dictionary:
	if zidx >= 0 and zidx < _Map.size():
		return {
			"floor": _Map[zidx]["floor"],
			"ceiling": _Map[zidx]["ceiling"],
			"height": _Map[zidx]["ceiling"] - _Map[zidx]["floor"]
		}
	return {height = -1}

func _TilePositionOverlaps(zidx : int, tposition : Vector2) -> bool:
	if zidx >= 0 and zidx < _Map.size():
		var szone = _Map[zidx]
		for i in range(_Map.size()):
			if i == zidx: continue
			var zone = _Map[i]
			if zone["ceiling"] > szone["floor"] and zone["floor"] < szone["ceiling"]:
				if tposition in zone.tiles:
					return true
			if zone["floor"] >= szone["ceiling"]:
				# The zone array should be ordered by floor height, so, if we've passed
				# the ceiling of this zone, then there's no way for an overlap from this point on.
				break
	return false

# -----------------------------------------------------------------------------
# Public Methods
# -----------------------------------------------------------------------------
func is_dirty() -> bool:
	return _dirty

func zone_count() -> int:
	return _Map.size()

func add_zone(f : int, c : int) -> void:
	if f > 0 and c > 0 and c > f:
		var zone = {
			"floor": f,
			"ceiling": c,
			"rect":Rect2(),
			"tiles":{}
		}
		for i in range(_Map.size()):
			var dim = _GetZoneDimension(i)
			if dim.height > 0:
				if dim["floor"] > f:
					_Map.insert(0 if i == 0 else i - 1, zone)
					_SetDirty()
					return
		_Map.append(zone)
		_SetDirty()

func remove_zone(zidx : int) -> void:
	if zidx >= 0 and zidx < _Map.size():
		_Map.remove(zidx)
		_SetDirty()

func add_tile(zidx : int, position : Vector2) -> void:
	if zidx >= 0 and zidx < _Map.size():
		if _TilePositionOverlaps(zidx, position):
			return
			
		var zone = _Map[zidx]
		# TODO: Finish this!!

# -----------------------------------------------------------------------------
# Handler Methods
# -----------------------------------------------------------------------------


