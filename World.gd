extends Spatial

const INITIAL_LEVEL = "res://Levels/Demo Level.tscn"
const LEVEL1 = "res://Levels/Level One.tscn"

# -------------------------------------------------------------------------
# Variables
# -------------------------------------------------------------------------
var level : Spatial = null

# -------------------------------------------------------------------------
# Onready Variables
# -------------------------------------------------------------------------
onready var player_node : KinematicBody = get_node("Player")

# -------------------------------------------------------------------------
# Override Methods
# -------------------------------------------------------------------------
func _ready() -> void:
	#_LoadLevel(INITIAL_LEVEL)
	_LoadLevel(LEVEL1)

# -------------------------------------------------------------------------
# Private Methods
# -------------------------------------------------------------------------
func _LoadLevel(path : String) -> void:
	var LEVEL_SCENE = load(path)
	if not LEVEL_SCENE:
		print("WARNING: Failed to load level \"", path, "\".")
		return
	
	
	var lvl = LEVEL_SCENE.instance()
	if not lvl.has_method("attach_player"):
		print("WARNING: Level scene does not appear valid.")
		lvl.queue_free()
		return
	
	
	if level != null:
		level.detach_player(self)
		remove_child(level)
		level.queue_free()
	
	level = lvl
	self.add_child(level)
	level.attach_player(player_node)

# -------------------------------------------------------------------------
# Handler Methods
# -------------------------------------------------------------------------

