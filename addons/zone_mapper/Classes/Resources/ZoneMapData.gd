extends Resource
class_name ZoneMapData

# -----------------------------------------------------------------------------
# Signals
# -----------------------------------------------------------------------------


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
func _ready():
	pass


# -----------------------------------------------------------------------------
# Private Methods
# -----------------------------------------------------------------------------
func _SetDirty() -> void:
	_dirty = true
	emit_changed()

func _RecalculateTextureBlocks() -> void:
	if texture != null and pix_size > 0:
		var tsize = texture.get_size()
		_texture_blocks_across = int(floor(tsize.x / pix_size))
		_texture_blocks_down = int(floor(tsize.y / pix_size))
	else:
		_texture_blocks_across = 0
		_texture_blocks_down = 0
	_texture_blocks_total = _texture_blocks_across * _texture_blocks_down


func _GetZoneDimension(zidx : int) -> Dictionary:
	if zidx >= 0 and zidx < _Map.size():
		return {
			"floor": _Map[zidx]["floor"],
			"ceiling": _Map[zidx]["ceiling"],
			"height": _Map[zidx]["ceiling"] - _Map[zidx]["floor"]
		}
	return {height = -1}

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
			_SetDirty()
	else:
		var dirty = false
		var otile = _Map[oidx].tiles[oposition]
		if zidx == oidx:
			dirty = true
			otile.w[owall].c = ztile == null
			if ztile == null:
				otile.w[owall].o = [0, 0, 0]
			else:
				otile.w[owall].o = [-1,-1,-1]
				ztile.w[wall].c = false
				ztile.w[wall].o = [-1,-1,-1]
		else:
			pass # TODO: Either figure out which edges are enabled based on the difference
			# in height between the two zones... or move the wall into it's own resource?

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
		#tile.w[0].c = not _TilePositionOverlaps(zidx, position + Vector2.UP)
		#tile.w[1].c = not _TilePositionOverlaps(zidx, position + Vector2.RIGHT)
		#tile.w[2].c = not _TilePositionOverlaps(zidx, position + Vector2.DOWN)
		#tile.w[3].c = not _TilePositionOverlaps(zidx, position + Vector2.LEFT)

func get_zone_tile_wall_collidable(zidx : int, tposition : Vector2, wall : int) -> bool:
	if zidx >= 0 and zidx < _Map.size() and WALL_FACE.keys().find(wall) >= 0:
		var zone = _Map[zidx]
		tposition = tposition.floor()
		if tposition in zone.tiles:
			return zone.tiles[tposition].w[wall].c
	return false

func set_zone_tile_wall_collidable(zidx : int, tposition : Vector2, wall : int, enable : bool = true) -> void:
	if zidx >= 0 and zidx < _Map.size() and WALL_FACE.keys().find(wall) >= 0:
		var zone = _Map[zidx]
		tposition = tposition.floor()
		if tposition in zone.tiles:
			zone.tiles[tposition].w[wall].c = enable
			_SetDirty()

func set_zone_tile_wall_surface(zidx : int, tposition : Vector2, wall : int, tid : int) -> void:
	if zidx >= 0 and zidx < _Map.size() and WALL_FACE.keys().find(wall) >= 0:
		if tid >= 0 and tid < _texture_blocks_total:
			var zone = _Map[zidx]
			tposition = tposition.floor()
			if tposition in zone.tiles:
				zone.tiles[tposition].w[wall].tid = tid
				_SetDirty()

func set_zone_tile_wall_offset(zidx : int, tposition : Vector2, wall : int, sec : int, offset : int) -> void:
	if zidx >= 0 and zidx < _Map.size() and WALL_FACE.keys().find(wall) >= 0:
		var zone = _Map[zidx]
		tposition = tposition.floor()
		if tposition in zone.tiles and zone.tiles[tposition].w[wall].tid >= 0:
			var zwall = zone.tiles[tposition].w[wall]
			var dirty = false
			if sec == WALL_SEC.Middle or sec == WALL_SEC.Full:
				if zwall.o[0] >= 0:
					zwall.o[0] = offset
					dirty = true
			
			if sec == WALL_SEC.Top or sec == WALL_SEC.Edges or sec == WALL_SEC.Full:
				if zwall.o[1] >= 0:
					zwall.o[1] = offset
					dirty = true
			
			if sec == WALL_SEC.Bottom or sec == WALL_SEC.Edges or sec == WALL_SEC.Full:
				if zwall.o[2] >= 0:
					zwall.o[2] = offset
					dirty = true
			
			if dirty:
				_SetDirty()

# -----------------------------------------------------------------------------
# Handler Methods
# -----------------------------------------------------------------------------


