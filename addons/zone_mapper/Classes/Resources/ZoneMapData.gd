tool
extends Resource
class_name ZoneMapData


# -----------------------------------------------------------------------------
# Signals
# -----------------------------------------------------------------------------
signal zone_added(new_zone_index)
signal zone_removed(new_zone_index)

# -------------------------------------------------------------------------
# Export Variables
# -------------------------------------------------------------------------
export var texture : Texture = null		setget set_texture
export var pix_size : int = 64			setget set_pix_size
export var minimum_height : float = 2.0	setget set_minimum_height

# -------------------------------------------------------------------------
# Variables
# -------------------------------------------------------------------------
var _Zones : Dictionary = {}
var _dirty : bool = false

var _texture_blocks_across : int = 0
var _texture_blocks_down : int = 0
var _texture_blocks_total : int = 0

# -------------------------------------------------------------------------
# Onready Variables
# -------------------------------------------------------------------------


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

func set_minimum_height(h : float) -> void:
	if h > 0.0:
		minimum_height = h

# -------------------------------------------------------------------------
# Override Methods
# -------------------------------------------------------------------------


# -------------------------------------------------------------------------
# Private Methods
# -------------------------------------------------------------------------
func _RecalculateTextureBlocks() -> void:
	if texture != null and pix_size > 0:
		var tsize = texture.get_size()
		_texture_blocks_across = int(floor(tsize.x / pix_size))
		_texture_blocks_down = int(floor(tsize.y / pix_size))
	else:
		_texture_blocks_across = 0
		_texture_blocks_down = 0
	_texture_blocks_total = _texture_blocks_across * _texture_blocks_down


# -------------------------------------------------------------------------
# Public Methods
# -------------------------------------------------------------------------
func is_dirty() -> bool:
	return _dirty

func get_class() -> String:
	return "ZoneMapData"

func add_zone(zname : String, f : float, c : float) -> void:
	if not zname in _Zones and c > f and c - f >= minimum_height:
		var zone = {
			"floor": f,
			"ceiling": c,
			"rect":Rect2(),
			"tiles":{}
		}

# -------------------------------------------------------------------------
# Handler Methods
# -------------------------------------------------------------------------


