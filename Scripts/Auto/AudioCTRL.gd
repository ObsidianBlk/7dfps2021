extends Node

# -------------------------------------------------------------------------
# ENUMs, Consts, and Signals
# -------------------------------------------------------------------------
signal bus_volume_change(bus_id, volume)

enum BUS {MASTER, MUSIC, SFX}

# -------------------------------------------------------------------------
# Variables
# -------------------------------------------------------------------------
var _Music = {}
var _current_music_track : String = ""

var _rng : RandomNumberGenerator = null

var _track_delay : float = 60.0
var _fade_time : float = 0.4

var _track_timer : Timer = null
var _fade_tween : Tween = null

# -------------------------------------------------------------------------
# Onready Variables
# -------------------------------------------------------------------------
onready var _BUS = {
	BUS.MASTER : AudioServer.get_bus_index("Master"),
	BUS.MUSIC : AudioServer.get_bus_index("Music"),
	BUS.SFX : AudioServer.get_bus_index("SFX")
}

onready var music_node : AudioStreamPlayer = get_node("/root/World/AudioMusic")
onready var sfx_node : AudioStreamPlayer = get_node("/root/World/AudioSFX")

# -------------------------------------------------------------------------
# Override Methods
# -------------------------------------------------------------------------
func _ready() -> void:
	music_node.connect("finished", self, "_on_music_finished")
	_rng = RandomNumberGenerator.new()
	_rng.randomize()
	
	_track_timer = Timer.new()
	_track_timer.one_shot = true
	_fade_tween = Tween.new()
	add_child(_track_timer)
	add_child(_fade_tween)
	
	_ExposeAudioCtrlToGDVar()

# -------------------------------------------------------------------------
# GDVar Command Methods
# -------------------------------------------------------------------------
func _CMD_GetVolume() -> void:
	var v_master = get_bus_volume(BUS.MASTER)
	var v_sfx = get_bus_volume(BUS.SFX)
	var v_music = get_bus_volume(BUS.MUSIC)
	GDVarCtrl.info("Master: [b][color=#AA8800]%s[/color][/b]" % [v_master * 100])
	GDVarCtrl.info("SFX: [b][color=#AA8800]%s[/color][/b]" % [v_sfx * 100])
	GDVarCtrl.info("Music: [b][color=#AA8800]%s[/color][/b]" % [v_music * 100])

func _CMD_SetVolume(bus : String, volume : float) -> void:
	bus = bus.to_lower()
	volume = max(0.0, min(1.0, volume / 100.0))
	match bus:
		"master":
			set_bus_volume(BUS.MASTER, volume)
		"sfx":
			set_bus_volume(BUS.SFX, volume)
		"music":
			set_bus_volume(BUS.MUSIC, volume)
		_:
			GDVarCtrl.error("No audio bus named '[i][color=#aa8800]%s[/color][/i]'." % [bus])

func _CMD_ListMusicTracks() -> void:
	if _Music.empty():
		GDVarCtrl.info("There are currently [b]no[/b] music tracks available.")
	else:
		for track in _Music.keys():
			GDVarCtrl.info("[i]%s[/i]" % [track])

# -------------------------------------------------------------------------
# Private Methods
# -------------------------------------------------------------------------
func _ExposeAudioCtrlToGDVar() -> void:
	if GDVarCtrl:
		GDVarCtrl.define_command({
			name = "get_volume",
			description = "Discover the current audio volumes.",
			owner = self,
			method = "_CMD_GetVolume"
		})
		GDVarCtrl.define_command({
			name = "set_volume",
			description = "Set the volume for one of the audio busses.",
			owner = self,
			method = "_CMD_SetVolume",
			args = [
				{"name":"bus", "type":TYPE_STRING},
				{"name":"level", "type":TYPE_REAL}
			]
		})
		GDVarCtrl.define_command({
			name = "list_music_tracks",
			description = "List the available music tracks.",
			owner = self,
			method = "_CMD_ListMusicTracks"
		})
		GDVarCtrl.define_command({
			name = "play_random_music_track",
			description = "Play a random track from the available music tracks.",
			owner = self,
			method = "play_random_music_track"
		})
		GDVarCtrl.define_command({
			name = "play_music_track",
			description = "Play the given music track.",
			owner = self,
			method = "play_music_track",
			args = [
				{"name":"track_name", "type":TYPE_STRING}
			]
		})
	else:
		call_deferred("_ExposeAudioCtrlToGDVar")


func _wrapi(low : int, high : int, v :int) -> int:
	if v < low:
		return high
	if v > high:
		return low
	return v

func _Play(music_name : String) -> void:
	music_node.stream = _Music[music_name].stream
	_current_music_track = music_name
	music_node.play()

# -------------------------------------------------------------------------
# Public Methods
# -------------------------------------------------------------------------
func add_music_track(music_name : String, src : String, auto_play : bool = false) -> bool:
	if not music_name in _Music:
		var stream = load(src)
		if stream:
			_Music[music_name] = {
				"source" : src,
				"stream" : stream
			}
			if auto_play:
				play_music_track(music_name)
			return true
	return false

func remove_music_track(music_name : String, change_track_if_playing : bool = false) -> bool:
	if music_name in _Music:
		if _current_music_track == music_name and change_track_if_playing:
			play_random_music_track()
		_Music.erase(music_name)
		return true
	return false

func remove_all_music_tracks() -> void:
	if music_node.playing:
		music_node.stop()
		music_node.stream = null
	_Music.clear()

func play_music_track(music_name : String) -> void:
	if music_name in _Music and music_name != _current_music_track:
		if music_node.stream == null:
			_Play(music_name)
		#elif not music_node.playing:
		else:
			if not _track_timer.is_stopped():
				_track_timer.stop()
				_on_track_delay_timeout()
			else:
				_Play(music_name)

func play_random_music_track() -> void:
	var tracklist = _Music.keys()
	var tlsize = tracklist.size()
	if tlsize > 0:
		if tlsize > 1:
			var idx = _rng.randi_range(0, tlsize-1)
			if tracklist[idx] == _current_music_track:
				idx = _wrapi(0, tlsize - 1, idx + 1)
			_Play(tracklist[idx])
		elif _current_music_track != tracklist[0]:
			_Play(tracklist[0])
		elif not music_node.playing:
			music_node.play()


func set_track_delay_time(time : float) -> void:
	if time >= 0.0:
		var _otd = _track_delay
		_track_delay = time
		if _track_delay < _otd and not _track_timer.is_stopped():
			_track_timer.stop()
			_on_track_delay_timeout()

func get_track_delay_time() -> float:
	return _track_delay

func play_sfx(src : String, interrupt : bool = false) -> void:
	if not interrupt and sfx_node.playing:
		return
	var audio = load(src)
	if audio is AudioStreamSample:
		sfx_node.stream = audio
		sfx_node.play()
	else:
		print("play_sfx: Source not found or not an AudioStreamSample")

func get_bus_volume(bus_id : int) -> float:
	if bus_id in _BUS:
		return db2linear(AudioServer.get_bus_volume_db(_BUS[bus_id]))
	return 0.0

func set_bus_volume(bus_id : int, volume : float) -> void:
	if bus_id in _BUS:
		volume = max(0.0, min(1.0, volume))
		AudioServer.set_bus_volume_db(_BUS[bus_id], linear2db(volume))
		emit_signal("bus_volume_change", bus_id, volume)



# ------------------------------------------------------------------------
# Handler Methods
# ------------------------------------------------------------------------

func _on_track_delay_timeout() -> void:
	play_random_music_track()

func _on_music_finished() -> void:
	if _track_delay > 0.0:
		_track_timer.start(_track_delay)
	else:
		play_random_music_track()

