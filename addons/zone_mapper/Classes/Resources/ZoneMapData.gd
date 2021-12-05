tool
extends Resource
class_name ZoneMapData

# -----------------------------------------------------------------------------
# Signals
# -----------------------------------------------------------------------------
signal zone_added(new_zone_index)
signal zone_removed(new_zone_index)

# -----------------------------------------------------------------------------
# ENUMs
# -----------------------------------------------------------------------------
enum WALL_FACE {North=1, East=2, South=3, West=4}
enum WALL_SEC {Middle=1, Top=2, Bottom=3, Edges=4, Full=5}

# -----------------------------------------------------------------------------
# Export Variables
# -----------------------------------------------------------------------------
export var texture : Texture = null
export var pix_size : int = 64			setget set_pix_size

# -----------------------------------------------------------------------------
# Variables
# -----------------------------------------------------------------------------
var _Map : Array = []
var _dirty : bool = false

var _texture_blocks_across : int = 0
var _texture_blocks_down : int = 0
var _texture_blocks_total : int = 0



# -----------------------------------------------------------------------------
# Setter / Getter
# -----------------------------------------------------------------------------
func set_texture(t : Texture) -> void:
	if not t is AtlasTexture:
		texture = t
		var ts = texture.get_size()
		var tsize = ts.x if ts.x >= ts.y else ts.y
		if pix_size > tsize:
			pix_size = tsize
		_RecalculateTextureBlocks()


func set_pix_size(ps : int) -> void:
	if ps > 0:
		if texture != null:
			var ts = texture.get_size()
			ts = ts.x if ts.x >= ts.y else ts.y
			if ps > ts:
				ps = ts
		pix_size = ps
		_RecalculateTextureBlocks()

# -----------------------------------------------------------------------------
# Override Methods
# -----------------------------------------------------------------------------
func _init():
	pass


# -----------------------------------------------------------------------------
# Private Methods
# -----------------------------------------------------------------------------
func _RecalculateTextureBlocks() -> void:
	if texture != null and pix_size > 0:
		var tsize = texture.get_size()
		_texture_blocks_across = int(floor(tsize.x / pix_size))
		_texture_blocks_down = int(floor(tsize.y / pix_size))
	else:
		_texture_blocks_across = 0
		_texture_blocks_down = 0
	_texture_blocks_total = _texture_blocks_across * _texture_blocks_down


func _GetOverlappingZoneNear(zidx : int, tposition : Vector2, include_self : bool = false) -> int:
	if zidx >= 0 and zidx < _Map.size():
		var szone = _Map[zidx]
		for i in range(_Map.size()):
			if i == zidx and not include_self: continue
			var zone = _Map[i]
			if zone["ceiling"] > szone["floor"] and zone["floor"] < szone["ceiling"]:
				return zidx
			if zone["floor"] >= szone["ceiling"]:
				# The zone array should be ordered by floor height, so, if we've passed
				# the ceiling of this zone, then there's no way for an overlap from this point on.
				break
	return -1

func _RecalculateZoneRect(zidx : int) -> void:
	if zidx >= 0 and zidx < _Map.size():
		var rect : Rect2 = Rect2()
		for key in _Map[zidx].tiles.keys():
			var trect : Rect2 = Rect2(key, Vector2(1,1))
			if rect.has_no_area():
				rect = trect
			else:
				rect = rect.merge(trect)
		_Map[zidx].rect = rect 

func _UpdateWallVisibility(zidx : int, tposition : Vector2, wall : int) -> void:
	var ztile = null
	if tposition in _Map[zidx].tiles:
		ztile = _Map[zidx].tiles[tposition]
	
	var direction : Vector2 = Vector2()
	var owall = -1
	match wall:
		WALL_FACE.North:
			direction = Vector2.UP
			owall = WALL_FACE.South
		WALL_FACE.East:
			direction = Vector2.RIGHT
			owall = WALL_FACE.West
		WALL_FACE.South:
			direction = Vector2.DOWN
			owall = WALL_FACE.North
		WALL_FACE.West:
			direction = Vector2.LEFT
			owall = WALL_FACE.East
	
	var oposition = tposition + direction
	var oidx = _GetOverlappingZoneNear(zidx, oposition, true)
	if oidx < 0:
		if ztile != null:
			ztile.w[wall].o = [0, 0, 0]
			if ztile.w[wall].tid < 0:
				ztile.w[wall].tid = 0
	else:
		var otile = _Map[oidx].tiles[oposition]
		if ztile == null:
			otile.w[owall].c = true
			otile.w[owall].o = [0, 0, 0]
		else:
			if zidx == oidx:
				otile.w[owall].c = false
				otile.w[owall].o = [-1,-1,-1]
				ztile.w[wall].c = false
				ztile.w[wall].o = [-1,-1,-1]
			else:
				ztile.w[wall].c = false
				ztile.w[wall].o = [
					-1,
					0 if _Map[oidx].ceiling < _Map[zidx].ceiling else -1,
					0 if _Map[oidx].floor > _Map[zidx].floor else -1
				]
				otile.w[owall].c = false
				otile.w[owall].o = [
					-1,
					0 if _Map[zidx].ceiling < _Map[oidx].ceiling else -1,
					0 if _Map[zidx].floor > _Map[oidx].floor else -1
				]
				
		_dirty = true

# -----------------------------------------------------------------------------
# Public Methods
# -----------------------------------------------------------------------------
func is_dirty() -> bool:
	return _dirty

func get_class() -> String:
	return "ZoneMapData"

func get_rect() -> Rect2:
	var rect : Rect2 = Rect2()
	for zone in _Map:
		if rect.has_no_area():
			rect = zone.rect
		else:
			rect = rect.merge(zone.rect)
	return rect

func get_zone_count() -> int:
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
			var dim = get_zone_dimensions(i)
			if dim.height > 0:
				if dim["floor"] > f:
					var nzidx : int = 0 if i == 0 else i - 1
					_Map.insert(nzidx, zone)
					_dirty = true
					emit_signal("zone_added", nzidx)
					emit_changed()
					return
		_Map.append(zone)
		_dirty = true
		emit_signal("zone_added", _Map.size() - 1)
		emit_changed()

func remove_zone(zidx : int) -> void:
	if zidx >= 0 and zidx < _Map.size():
		_Map.remove(zidx)
		_dirty = true
		emit_signal("zone_removed", zidx)
		emit_changed()

func get_zone_rect(zidx : int) -> Rect2:
	if zidx >= 0 and zidx < _Map.size():
		return _Map[zidx].rect
	return Rect2()

func get_zone_dimensions(zidx : int):
	if zidx >= 0 and zidx < _Map.size():
		return {
			"floor": _Map[zidx]["floor"],
			"ceiling": _Map[zidx]["ceiling"],
			"height": _Map[zidx]["ceiling"] - _Map[zidx]["floor"]
		}
	return null

func get_zone_index_at(x : int, y : int) -> int:
	return get_zone_index_atv(Vector2(x, y))

func get_zone_index_atv(position : Vector2) -> int:
	for i in range(_Map.size()):
		if position in _Map[i].tiles:
			return i
	return -1

func add_tile(zidx : int, x : int, y : int) -> void:
	add_tilev(zidx, Vector2(x, y))

func add_tilev(zidx : int, position : Vector2) -> void:
	if zidx >= 0 and zidx < _Map.size():
		if _GetOverlappingZoneNear(zidx, position) >= 0:
			return
			
		var zone = _Map[zidx]
		# "c"ollision, "t"op, "m"iddle, "b"ottom
		# "tid" = "Texture ID"
		var tile = {
			"f":{"c":true, "tid":-1, "r":-1},
			"c":{"c":true, "tid":-1, "r":-1},
			"w":[
				{"c":false, "tid":-1, "o":[-1, -1, -1]},
				{"c":false, "tid":-1, "o":[-1, -1, -1]},
				{"c":false, "tid":-1, "o":[-1, -1, -1]},
				{"c":false, "tid":-1, "o":[-1, -1, -1]}
			]
		}
		zone.tiles[position] = tile
		var trect : Rect2 = Rect2(position, Vector2(1,1))
		if zone.rect.has_no_area():
			zone.rect = trect
		else:
			zone.rect = zone.rect.merge(trect)
		_UpdateWallVisibility(zidx, position, WALL_FACE.North)
		_UpdateWallVisibility(zidx, position, WALL_FACE.East)
		_UpdateWallVisibility(zidx, position, WALL_FACE.South)
		_UpdateWallVisibility(zidx, position, WALL_FACE.West)
		_dirty = true
		emit_changed()

func remove_tile(zidx : int, x : int, y : int) -> void:
	remove_tilev(zidx, Vector2(x, y))

func remove_tilev(zidx : int, position : Vector2) -> void:
	if zidx >= 0 and zidx < _Map.size():
		if position in _Map[zidx].tiles:
			_Map[zidx].tiles.erase(position)
			_UpdateWallVisibility(zidx, position, WALL_FACE.North)
			_UpdateWallVisibility(zidx, position, WALL_FACE.East)
			_UpdateWallVisibility(zidx, position, WALL_FACE.South)
			_UpdateWallVisibility(zidx, position, WALL_FACE.West)
			_RecalculateZoneRect(zidx)
			_dirty = true
			emit_changed()

func zone_has_tile_at(zidx : int, x: int, y: int) -> bool:
	return zone_has_tile_atv(zidx, Vector2(x, y))

func zone_has_tile_atv(zidx : int, tposition : Vector2) -> bool:
	if zidx >= 0 and zidx < _Map.size():
		return tposition in _Map[zidx].tiles
	return false

func get_zone_tile_count(zidx : int) -> int:
	if zidx >= 0 and zidx < _Map.size():
		return _Map[zidx].tiles.keys().size()
	return 0

func get_tile_count() -> int:
	var count : int = 0
	for i in range(_Map.size()):
		count += _Map[i].tiles.keys().size()
	return count

func get_zone_tile_wall_collidable(zidx : int, tposition : Vector2, wall : int) -> bool:
	if zidx >= 0 and zidx < _Map.size() and WALL_FACE.keys().find(wall) >= 0:
		var zone = _Map[zidx]
		tposition = tposition.floor()
		if tposition in zone.tiles:
			return zone.tiles[tposition].w[wall].c
	return false

func get_zone_tile_wall_surface(zidx : int, tposition : Vector2, wall : int) -> int:
	if zidx >= 0 and zidx < _Map.size() and WALL_FACE.keys().find(wall) >= 0:
		var zone = _Map[zidx]
		tposition = tposition.floor()
		if tposition in zone.tiles:
			return zone.tiles[tposition].w[wall].tid
	return -1

func get_zone_tile_wall_offset(zidx : int, tposition : Vector2, wall : int, sec : int) -> int:
	if zidx >= 0 and zidx < _Map.size() and WALL_FACE.keys().find(wall) >= 0:
		var zone = _Map[zidx]
		tposition = tposition.floor()
		if tposition in zone.tiles:
			var tile = zone.tiles[tposition]
			match sec:
				WALL_SEC.Middle:
					return tile.w[wall].o[0]
				WALL_SEC.Top:
					return tile.w[wall].o[1]
				WALL_SEC.Bottom:
					return tile.w[wall].o[2]
	return -1

func get_zone_tile_wall_definition(zidx : int, tposition : Vector2, wall : int):
	if zidx >= 0 and zidx < _Map.size() and WALL_FACE.keys().find(wall) >= 0:
		var zone = _Map[zidx]
		tposition = tposition.floor()
		if tposition in zone.tiles:
			return {
				"collision": zone.tiles[tposition].w[wall].c,
				"surface_id": zone.tiles[tposition].w[wall].tid,
				"offset_middle": zone.tiles[tposition].w[wall].o[0],
				"offset_top": zone.tiles[tposition].w[wall].o[1],
				"offset_bottom": zone.tiles[tposition].w[wall].o[2]
			}
	return null

func set_zone_tile_wall_collidable(zidx : int, tposition : Vector2, wall : int, enable : bool = true) -> void:
	if zidx >= 0 and zidx < _Map.size() and WALL_FACE.keys().find(wall) >= 0:
		var zone = _Map[zidx]
		tposition = tposition.floor()
		if tposition in zone.tiles:
			zone.tiles[tposition].w[wall].c = enable
			_dirty = true
			emit_changed()

func set_zone_tile_wall_surface(zidx : int, tposition : Vector2, wall : int, tid : int) -> void:
	if zidx >= 0 and zidx < _Map.size() and WALL_FACE.keys().find(wall) >= 0:
		if tid >= 0 and tid < _texture_blocks_total:
			var zone = _Map[zidx]
			tposition = tposition.floor()
			if tposition in zone.tiles:
				zone.tiles[tposition].w[wall].tid = tid
				_dirty = true
				emit_changed()

func set_zone_tile_wall_offset(zidx : int, tposition : Vector2, wall : int, sec : int, offset : int) -> void:
	if zidx >= 0 and zidx < _Map.size() and WALL_FACE.keys().find(wall) >= 0:
		var zone = _Map[zidx]
		tposition = tposition.floor()
		if tposition in zone.tiles and zone.tiles[tposition].w[wall].tid >= 0:
			var zwall = zone.tiles[tposition].w[wall]
			if sec == WALL_SEC.Middle or sec == WALL_SEC.Full:
				if zwall.o[0] >= 0:
					zwall.o[0] = offset
					_dirty = true
			
			if sec == WALL_SEC.Top or sec == WALL_SEC.Edges or sec == WALL_SEC.Full:
				if zwall.o[1] >= 0:
					zwall.o[1] = offset
					_dirty = true
			
			if sec == WALL_SEC.Bottom or sec == WALL_SEC.Edges or sec == WALL_SEC.Full:
				if zwall.o[2] >= 0:
					zwall.o[2] = offset
					_dirty = true
			
			if _dirty:
				emit_changed()

# -----------------------------------------------------------------------------
# Handler Methods
# -----------------------------------------------------------------------------


