extends Spatial

const INITIAL_LEVEL = "res://Levels/Demo Level.tscn"
const LEVEL1 = "res://Levels/Level One.tscn"
const LEVEL2 = "res://Levels/Level Two.tscn"

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
	GDVarCtrl.define_command({
		name = "about_music",
		description = "Get your musical attributions right here!",
		owner = self,
		method = "_CMD_AboutMusic"
	})
	
	AudioCtrl.add_music_track("Moonlight", "res://Assets/Audio/Music/Cyberpunk Moonlight Sonata v2.ogg")
	AudioCtrl.add_music_track("Arcade3", "res://Assets/Audio/Music/cyberpunk_arcade_3.ogg")
	AudioCtrl.add_music_track("StreetUrchins", "res://Assets/Audio/Music/cyber_street_urchins.ogg")
	AudioCtrl.add_music_track("LinesOfCode", "res://Assets/Audio/Music/Lines of Code.ogg")
	AudioCtrl.set_bus_volume(AudioCtrl.BUS.MUSIC, 0.5)
	player_node.set_terminal_node(terminal_node)
	#_LoadLevel(INITIAL_LEVEL)
	_LoadLevel(LEVEL1)

# -------------------------------------------------------------------------
# Terminal Commands
# -------------------------------------------------------------------------
func _CMD_Quit() -> void:
	get_tree().quit()

func _CMD_AboutMusic() -> void:
	var msg = [
		"Track: [i][b]Moonlight[/b][/i]\n",
		"Song: [i][b]Cyberpunk Moonlight Sonata v2[/b][/i]\n",
		"Author: [i][b]Joth[/b][/i]\n",
		"Source: [url]https://opengameart.org/content/cyberpunk-moonlight-sonata[/url]\n",
		"\n",
		"Track: [i][b]LinesOfCode[/b][/i]\n",
		"Song: [i][b]Lines of Code[/b][/i]\n",
		"Author: [i][b]Trevor Lentz[/b][/i]\n",
		"Source: [url]https://opengameart.org/content/lines-of-code[/url]\n",
		"\n",
		"Track: [i][b]StreetUrchins[/b][/i]\n",
		"Song: [i][b]Cyber Street Urchans[/b][/i]\n",
		"Author: [i][b]Eric Matyas[/b][/i]\n",
		"Source: [url]https://opengameart.org/content/cyber-street-urchins-looping[/url]\n",
		"\n",
		"Track: [i][b]Arcade3[/b][/i]\n",
		"Song: [i][b]Cyberpunk Arcade 3[/b][/i]\n",
		"Author: [i][b]Eric Matyas[/b][/i]\n",
		"Source: [url]https://opengameart.org/content/cyberpunk-arcade-3-looping[/url]\n"
	]
	GDVarCtrl.call_command("clear_messages")
	GDVarCtrl.info(PoolStringArray(msg).join(""))

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
