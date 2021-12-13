extends "res://Scripts/Level.gd"

# -------------------------------------------------------------------------
# Constants
# -------------------------------------------------------------------------
const RESET_MESSAGES = [
	"Really? You had to take a swan dive?",
	"You realize you can't fly, right?",
	"Have a nice trip? See you next fall!",
	"Honestly, friend, there's nothing down there.",
	"Down, down, down... you just fell DOWN!"
]

# -------------------------------------------------------------------------
# Variables
# -------------------------------------------------------------------------
var _passcode : String = ""

# -------------------------------------------------------------------------
# Onready Variables
# -------------------------------------------------------------------------
onready var pads_container_node : Spatial = get_node("Pads")
onready var msgcube_node : Spatial = get_node("Decorations/MessageCube")

# -------------------------------------------------------------------------
# Override Methods
# -------------------------------------------------------------------------
func _ready() -> void:
	connect("player_attached", self, "_on_player_attached")
	connect("player_position_reset", self, "_on_player_pos_reset")
	GDVarCtrl.define_command({
		name = "passcode",
		description = "Find the passcode and you'll be able to exit the level!",
		owner = self,
		method = "_CMD_Passcode",
		args = [
			{name = "code", type=TYPE_STRING}
		]
	})
	_GeneratePasscode()
	AudioCtrl.play_music_track("Moonlight")
	call_deferred("_InitialMessage")


# -------------------------------------------------------------------------
# Commands Methods
# -------------------------------------------------------------------------
func _CMD_Passcode(code : String) -> void:
	GDVarCtrl.call_command("clear_messages")
	var messages : Array = []
	if code == "1234":
		messages = [
			"Really?! You tried \"1234\"? ",
			"Did you honestly think it was going to be [i]that[/i] easy?\n",
			"\n",
			"Well, it wasn't. You're going to actually have to find the answer, ",
			"or... quit, if you don't think you can hack it :)"
		]
	elif code != "" and code == _passcode:
		GDVarCtrl.define_command({
			name = "exit_level",
			description = "Well... might be that it's written on the tin.",
			owner = self,
			method = "_CMD_ExitLevel"
		})
		messages = [
			"Nice! Well done!\n",
			"You might be ready to progress to the next level. I've made the ",
			"command available to you, so you can leave in your own time.\n",
			"...\n",
			"What? You want me to just [i]tell[/i] you what the command is? ",
			"Nah. You'll have to figure it out yourself... like, by using...\n",
			"[color=#aa8800][i]commands[/i][/color]\n"
		]
	else:
		messages = [
			"Nope... that's not the right passcode."
		]
	
	GDVarCtrl.info(PoolStringArray(messages).join(""))

func _CMD_ExitLevel() -> void:
	call_next_level()

# -------------------------------------------------------------------------
# Private Methods
# -------------------------------------------------------------------------
func _InitialMessage() -> void:
	var messages : PoolStringArray = PoolStringArray([
		"Welcome to [color=#22AA22][i][b]TermLiminal[/b][/i][/color]!\n",
		"Where one foolish developers lack of 3D skills lead to a three day ",
		"battle with Blender (which he lost) and another loss of two days ",
		"following a rabbit hole of an idea before finally realizing it wasn't ",
		"worth the time... has lead to this hobbled together idea!\n",
		"\n",
		"That little chime you heard when the level started was an indicator that ",
		"a new message is available here in the terminal! So come check it out, if ",
		"you hear it again!\n",
		"\n",
		"To progress, you're going to need a passcode! Look for the glowing ",
		"areas. When you step on one, you'll get a message here in the terminal ",
		"with a piece of the passcode!\n",
		"\n",
		"There are four digits to find. Once you have them, enter them like...\n",
		"[color=#AA8800][i]passcode(\"1234\")[/i][/color]\n",
		"... of course, the passcode isn't \"1234\". That would be... silly!\n",
		"\n",
		"Oh! I also left a few of my friends hangin about. They should be easy enough to avoid..."
	])
	GDVarCtrl.info(messages.join(""))
	AudioCtrl.play_sfx("res://Assets/Audio/SFX/terminal_chime.wav")
	_UpdatePads()


func _GeneratePasscode(default : String = "4876") -> void:
	_passcode = ""
	var rng = RandomNumberGenerator.new()
	rng.randomize()
	var nums = ["0", "1", "2", "3", "4", "5", "6", "7", "8", "9"]
	for i in range(4):
		var idx = rng.randi_range(0, nums.size()-1)
		_passcode += nums[idx]
		nums.remove(idx)
	if _passcode == "1234":
		_passcode = default
	print("Passcode: ", _passcode)

func _UpdatePads() -> void:
	var idx : int = 0
	for child in pads_container_node.get_children():
		if idx >= 4:
			return # We're done!
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
		idx += 1

# -------------------------------------------------------------------------
# Public Methods
# -------------------------------------------------------------------------


# -------------------------------------------------------------------------
# Handler Methods
# -------------------------------------------------------------------------
func _on_player_attached() -> void:
	_player.connect("dead", self, "_on_player_dead")


func _on_player_pos_reset() -> void:
	var rng = RandomNumberGenerator.new()
	rng.randomize()
	var idx = rng.randi_range(0, RESET_MESSAGES.size() - 1)
	msgcube_node.text = RESET_MESSAGES[idx]


func _on_player_dead() -> void:
	msgcube_node.text = "Ha! One of my baddies got ya! That's funny!"
	_player.global_transform.origin = player_start_node.global_transform.origin
	_player.revive()
