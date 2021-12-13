extends "res://Scripts/Level.gd"

# -------------------------------------------------------------------------
# Export Variables
# -------------------------------------------------------------------------


# -------------------------------------------------------------------------
# Variables
# -------------------------------------------------------------------------
var _passcode : String = ""

# -------------------------------------------------------------------------
# Onready Variables
# -------------------------------------------------------------------------
onready var pads_container_node : Spatial = get_node("Pads")

# -------------------------------------------------------------------------
# Commands Methods
# -------------------------------------------------------------------------
func _CMD_Passcode(code : String) -> void:
	if code == _passcode:
		var msg = [
			"Nice! You found the pass code!!! Well done!!\n",
			"\n",
			"I mean, seriously... you got to the end! I'm grateful!\n",
			"\n",
			"...\n",
			"[i]Really[/i] grateful?\n",
			"...\n",
			"\n",
			"Ok... look... this is as far as I got. There're no more levels. ",
			"I'm sorry. I just got derailed a lot this jam.\n",
			"\n",
			"I really appreciate you giving [color=#22AA22][i][b]TermLiminal[/b][/i][/color] ",
			"a playthrough... and actually finishing! That's awesome!\n",
			"\n",
			"Thank you very much for playing!"
		]
		GDVarCtrl.call_command("clear_messages")
		GDVarCtrl.info(PoolStringArray(msg).join(""))
		AudioCtrl.play_sfx("res://Assets/Audio/SFX/terminal_chime.wav")
	else:
		GDVarCtrl.call_command("clear_messages")
		GDVarCtrl.info("Yeeeeah... [b][color=#FF0000]NO[/color][/b]")
		AudioCtrl.play_sfx("res://Assets/Audio/SFX/terminal_chime.wav")

# -------------------------------------------------------------------------
# Override Methods
# -------------------------------------------------------------------------
func _ready() -> void:
	connect("player_attached", self, "_on_player_attached")
	_GeneratePasscode()
	AudioCtrl.play_music_track("LinesOfCode")
	call_deferred("_InitialMessage")


# -------------------------------------------------------------------------
# Private Methods
# -------------------------------------------------------------------------
func _InitialMessage() -> void:
	var msg = [
		"Hey look! I gave you a [b]HAND[/b]!!\n",
		"\n",
		"Look... that's the height of my humor. Sorry!\n",
		"\n",
		"Ok... Same as before, but I kinda left a few of my baddies laying ",
		"around for you. The new hand should come in useful for that. ",
		"Don't worry, they're not [i]too[/i] bright... and you might even ",
		"be able to sneak by them if they're not looking, and, well, if ",
		"you care to do anything other than stabby, stabby.\n",
		"\n",
		"Same game... There's a four digit pass code out there. But this time ",
		"some of those pads are duds. One does hold some player cheats for you ",
		"so, I guess that's a little incentive.\n",
		"\n",
		"Good luck!"
	]
	GDVarCtrl.call_command("clear_messages")
	GDVarCtrl.info(PoolStringArray(msg).join(""))
	AudioCtrl.play_sfx("res://Assets/Audio/SFX/terminal_chime.wav")
	
	_UpdatePads()


func _GeneratePasscode() -> void:
	_passcode = ""
	var rng = RandomNumberGenerator.new()
	rng.randomize()
	var nums = ["0", "1", "2", "3", "4", "5", "6", "7", "8", "9"]
	for i in range(4):
		var idx = rng.randi_range(0, nums.size()-1)
		_passcode += nums[idx]
		nums.remove(idx)
	print("Passcode: ", _passcode)


func _UpdatePads() -> void:
	var rng = RandomNumberGenerator.new()
	rng.randomize()
	var children = pads_container_node.get_children()
	for idx in range(4):
		var cidx = rng.randi_range(0, children.size() - 1)
		var child = children[cidx]
		children.remove(cidx)
		var msg = ""
		match idx:
			0:
				msg = "To begin, the number [color=#00aa00][b]%s[/b][/color] is expected." % [_passcode.substr(idx, 1)]
			1:
				msg = "Substitue place two for [color=#00aa00][b]%s[/b][/color]." % [_passcode.substr(idx, 1)]
			2:
				msg = "[color=#00aa00][b]%s[/b][/color] should be the penultimate number." % [_passcode.substr(idx, 1)]
			3:
				msg = "A value of [color=#00aa00][b]%s[/b][/color] shall bring you home." % [_passcode.substr(idx, 1)]
		child.message = msg
		child.one_shot = false
		idx += 1
	
	#var cidx = rng.randi_range(0, children.size() - 1)
	#var player_cheat_pad = children[cidx]
	#children.remove(cidx)
	#player_cheat_pad.one_shot = false
	#player_cheat_pad.message = "Hi"
	#player_cheat_pad.connect("pad_triggered", self, "_on_cheats_triggered", [player_cheat_pad])
	
	
	for child in children:
		child.one_shot = true
		child.message = "Oh... a dud. That sucks!"



# -------------------------------------------------------------------------
# Public Methods
# -------------------------------------------------------------------------


# -------------------------------------------------------------------------
# Handler Methods
# -------------------------------------------------------------------------
func _on_cheats_triggered(pad : Spatial) -> void:
	print("PLayer CHeats!!")
	if _player != null:
		#_player.enable_cheats()
		var pparent = pad.get_parent()
		if pparent:
			pparent.remove_child(pad)
			pad.queue_free()
		var msg = [
			"Hey [b]Player[/b]!\n",
			"I've decided to give you a couple cheats. ",
			"Check out [i][color=#aa8800]commands[/color][/i] to sus out what ",
			"they might be!\n",
			"\n",
			"Don't say I never gave you anything!"
		]
		GDVarCtrl.call_command("clear_messages")
		GDVarCtrl.info(PoolStringArray(msg).join(""))
		AudioCtrl.play_sfx("res://Assets/Audio/SFX/terminal_chime.wav")


func _on_player_attached() -> void:
	_player.enable_hands()
	_player.enable_cheats()
