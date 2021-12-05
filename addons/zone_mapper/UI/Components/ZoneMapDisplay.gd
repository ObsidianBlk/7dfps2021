tool
extends Control


# -------------------------------------------------------------------------
# Constants
# -------------------------------------------------------------------------
const MIN_TILE_SIZE : float = 12.0
const MAX_TILE_SIZE : float = 96.0
const TILE_SIZE_DELTA : float = 2.0

const SMALL_TILE_EDGES : float = 4.0
const MED_TILE_EDGES : float = 8.0
const LARGE_TILE_EDGES : float = 16.0

const TILE_MAIN_BODY_COLOR : Color = Color(0.8, 0.8, 0.8)
const TILE_MAIN_EDGE_COLOR : Color = Color(0.8, 1.0, 0.8)
const ZONE_OUTLINE_COLOR : Color = Color(1,1,1,0.5)


# -------------------------------------------------------------------------
# Variables
# -------------------------------------------------------------------------
var _zmd : WeakRef = null
var _update_requested : bool = false

var _zone_index : int = 0

var _tile_size : float = 32
var _offset : Vector2 = Vector2()

# -------------------------------------------------------------------------
# Onready Variables
# -------------------------------------------------------------------------


# -------------------------------------------------------------------------
# Private Drawing Methods ( used by _draw() )
# -------------------------------------------------------------------------
func _InView(trect : Rect2) -> bool:
	var crect = Rect2(_offset, self.rect_size)
	return trect.intersects(crect)


func _DrawTile(zmd : ZoneMapData, zidx : int, x : int, y : int) -> void:
	var edge_size = SMALL_TILE_EDGES
	if _tile_size - (MED_TILE_EDGES * 2) > 1:
		edge_size = MED_TILE_EDGES
		if _tile_size - (LARGE_TILE_EDGES * 2) > 1:
			edge_size = LARGE_TILE_EDGES
	var hedge = edge_size * 0.5
	var body_size = _tile_size - (edge_size * 2)
	var qbody = body_size * 0.25
	
	var tx : float = (float(x) * _tile_size) + _offset.x
	var ty : float = (float(y) * _tile_size) + _offset.y
	if not _InView(Rect2(tx, ty, _tile_size, _tile_size)):
		return # Early out if tile wouldn't be displayed anyway!
	
	var bx : float = tx + edge_size
	var by : float = ty + edge_size
	var fex : float = bx + body_size
	var fey : float = by + body_size
	
	draw_rect(Rect2(bx, by, body_size, body_size), TILE_MAIN_BODY_COLOR)
	
	# NORTH WALL
	var wdef = zmd.get_zone_tile_wall_definition(zidx, Vector2(x, y), zmd.WALL_FACE.North)
	if (wdef.offset_middle >= 0) or (wdef.offset_top >= 0) or (wdef.offset_bottom >= 0):
		if wdef.offset_top >= 0:
			draw_rect(Rect2(bx + qbody, ty + hedge, body_size * 0.5, hedge), TILE_MAIN_EDGE_COLOR)
		if wdef.offset_bottom >= 0:
			draw_rect(Rect2(bx, ty + hedge, qbody, hedge), TILE_MAIN_EDGE_COLOR)
			draw_rect(Rect2(bx + (body_size - qbody), ty + hedge, qbody, hedge), TILE_MAIN_EDGE_COLOR)
	if zmd.zone_has_tile_at(zidx, x, y - 1):
		draw_rect(Rect2(tx, ty, _tile_size, 1), ZONE_OUTLINE_COLOR)
	
	# EAST WALL
	wdef = zmd.get_zone_tile_wall_definition(zidx, Vector2(x, y), zmd.WALL_FACE.East)
	if (wdef.offset_middle >= 0) or (wdef.offset_top >= 0) or (wdef.offset_bottom >= 0):
		if wdef.offset_top >= 0:
			draw_rect(Rect2(fex, by + qbody, hedge, body_size * 0.5), TILE_MAIN_EDGE_COLOR)
		if wdef.offset_bottom >= 0:
			draw_rect(Rect2(fex, by, hedge, qbody), TILE_MAIN_EDGE_COLOR)
			draw_rect(Rect2(fex, by + (body_size - qbody), hedge, qbody), TILE_MAIN_EDGE_COLOR)
	if zmd.zone_has_tile_at(zidx, x + 1, y):
		draw_rect(Rect2(fex + (edge_size - 1), ty, 1, _tile_size), ZONE_OUTLINE_COLOR)
	
	# SOUTH WALL
	wdef = zmd.get_zone_tile_wall_definition(zidx, Vector2(x, y), zmd.WALL_FACE.South)
	if (wdef.offset_middle >= 0) or (wdef.offset_top >= 0) or (wdef.offset_bottom >= 0):
		if wdef.offset_top >= 0:
			draw_rect(Rect2(bx + qbody, fey, body_size * 0.5, hedge), TILE_MAIN_EDGE_COLOR)
		if wdef.offset_bottom >= 0:
			draw_rect(Rect2(bx, fey, qbody, hedge), TILE_MAIN_EDGE_COLOR)
			draw_rect(Rect2(bx + (body_size - qbody), fey, qbody, hedge), TILE_MAIN_EDGE_COLOR)
	if zmd.zone_has_tile_at(zidx, x, y + 1):
		draw_rect(Rect2(tx, fey + (edge_size - 1), _tile_size, 1), ZONE_OUTLINE_COLOR)
	
	# WEST WALL
	wdef = zmd.get_zone_tile_wall_definition(zidx, Vector2(x, y), zmd.WALL_FACE.South)
	if (wdef.offset_middle >= 0) or (wdef.offset_top >= 0) or (wdef.offset_bottom >= 0):
		if wdef.offset_top >= 0:
			draw_rect(Rect2(tx + hedge, by + qbody, hedge, body_size * 0.5), TILE_MAIN_EDGE_COLOR)
		if wdef.offset_bottom >= 0:
			draw_rect(Rect2(tx + hedge, by, hedge, qbody), TILE_MAIN_EDGE_COLOR)
			draw_rect(Rect2(tx + hedge, fey - qbody, hedge, qbody), TILE_MAIN_EDGE_COLOR)
	if zmd.zone_has_tile_at(zidx, x - 1, y):
		draw_rect(Rect2(tx, ty, _tile_size, 1), ZONE_OUTLINE_COLOR)

# -------------------------------------------------------------------------
# Override Methods
# -------------------------------------------------------------------------
func _draw() -> void:
	var zmd : ZoneMapData = _GetZMD()
	if not zmd:
		return
	
	print(zmd.get_zone_rect(_zone_index))
	var zrect : Rect2 = zmd.get_zone_rect(_zone_index)
	if zrect.has_no_area(): return
	
	for i in range(zrect.size.x):
		for j in range(zrect.size.y):
			var x = zrect.position.x + i
			var y = zrect.position.y + j
			if zmd.zone_has_tile_at(_zone_index, x, y):
				_DrawTile(zmd, _zone_index, x, y)

func _ready() -> void:
	connect("mouse_entered", self, "_on_mouse_entered")
	connect("mouse_exited", self, "_on_mouse_exited")

func _process(_delta : float) -> void:
	if _update_requested:
		update()
		_update_requested = false

# -------------------------------------------------------------------------
# Private Methods
# -------------------------------------------------------------------------

func _GetZMD() -> ZoneMapData:
	if _zmd != null:
		var zmd = _zmd.get_ref()
		if zmd: return zmd
	return null

func _WorldToMap(pos : Vector2) -> Vector2:
	return Vector2(
		floor((pos.x + _offset.x) / _tile_size),
		floor((pos.y + _offset.y) / _tile_size)
	)

func _MapToWorld(pos : Vector2) -> Vector2:
	return Vector2(
		(floor(pos.x) * _tile_size) + _offset.x,
		(floor(pos.y) * _tile_size) + _offset.y
	)

# -------------------------------------------------------------------------
# Public Methods
# -------------------------------------------------------------------------
func set_offset(offset : Vector2) -> void:
	_offset = offset
	_update_requested = true

func set_zone_map_data(zmd : ZoneMapData) -> void:
	if _zmd != null:
		if _zmd.get_ref():
			_zmd.get_ref().disconnect("changed", self, "_on_zmd_changed")
	_zmd = weakref(zmd)
	zmd.connect("changed", self, "_on_zmd_changed")
	_update_requested = true

func set_active_zone(zidx : int) -> void:
	var zmd : ZoneMapData = _GetZMD()
	if not zmd: return
	if zidx >= 0 and zidx < zmd.get_zone_count():
		if _zone_index != zidx:
			_zone_index = zidx
			_update_requested = true


# -------------------------------------------------------------------------
# Handler Methods
# -------------------------------------------------------------------------
func _on_zmd_changed() -> void:
	_update_requested = true


func _on_mouse_entered() -> void:
	print("Mouse On")


func _on_mouse_exited() -> void:
	print("Mouse Off")


