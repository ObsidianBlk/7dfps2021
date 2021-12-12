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
onready var terminal_node : Control = get_node("VarTerminal/Control/GDVarTerminal")

# -------------------------------------------------------------------------
# Override Methods
# -------------------------------------------------------------------------
func _ready() -> void:
	GDVarCtrl.define_command({
		name = "quit",
		description = "When you've had just about [color=#ee8800]enough of this shit![/color]",
		owner = self,
		method = "_CMD_Quit"
	})
	player_node.set_terminal_node(terminal_node)
	#_LoadLevel(INITIAL_LEVEL)
	_LoadLevel(LEVEL1)

# -------------------------------------------------------------------------
# Terminal Commands
# -------------------------------------------------------------------------
func _CMD_Quit() -> void:
	get_tree().quit()

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
		level.disconnect("level_change", self, "_on_level_change")
		level.detach_player(self)
		remove_child(level)
		level.queue_free()
	
	level = lvl
	self.add_child(level)
	level.connect("level_change", self, "_on_level_change")
	level.attach_player(player_node)

# -------------------------------------------------------------------------
# Handler Methods
# -------------------------------------------------------------------------
func _on_level_change(src : String) -> void:
	_LoadLevel(src)
