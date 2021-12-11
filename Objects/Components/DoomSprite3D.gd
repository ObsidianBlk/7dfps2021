extends Sprite3D

# ------------------------------------------------------------------------------------------------
# Signals
# ------------------------------------------------------------------------------------------------
signal animation_complete(animation_name)
signal animation_looping(animation_name)

# ------------------------------------------------------------------------------------------------
# Constants and ENUMs
# ------------------------------------------------------------------------------------------------
enum ANGLE {All=0, Forward=0, FLeft=1, Left=2, BLeft=3, Backward=4, FRight=5, Right=6, BRight=7}


# ------------------------------------------------------------------------------------------------
# Variables
# ------------------------------------------------------------------------------------------------
var _observer : Spatial = null
var _anim : Dictionary = {}
var _active_anim : String = ""
var _active_angle : int = ANGLE.All
var _frame : int = -1
var _dtime : float = 0

# ------------------------------------------------------------------------------------------------
# Override Methods
# ------------------------------------------------------------------------------------------------
func _ready():
	billboard = SpatialMaterial.BILLBOARD_FIXED_Y
	transparent = true
	double_sided = true

func _process(delta : float) -> void:
	if _active_anim == "":
		return

	_AngleFromObserver()
	var offset = _GetAnimOffset(_active_anim, _active_angle)
	if offset < 0:
		return

	_dtime += delta
	var advance : int = 0
	while _dtime >= _anim[_active_anim].duration:
		_dtime -= _anim[_active_anim].duration
		advance += 1
	if advance > 0:
		if _anim[_active_anim].loop:
			_frame += advance
			if _frame >= _anim[_active_anim].frames:
				emit_signal("animation_looping", _active_anim)
			_frame = _frame % _anim[_active_anim].frames
		else:
			_frame = min(_anim[_active_anim].frames - 1, _frame + advance)
			if _frame == _anim[_active_anim].frames - 1:
				emit_signal("animation_complete", _active_anim)
	
	if offset + _frame < hframes * vframes:
		frame = offset + _frame
	
	
# ------------------------------------------------------------------------------------------------
# Private Methods
# ------------------------------------------------------------------------------------------------
func _GetAnimOffset(anim_name : String, targ_angle : int) -> int:
	if targ_angle in _anim[anim_name].offset:
		if flip_h:
			flip_h = false
		return _anim[anim_name].offset[targ_angle]
	if targ_angle > 0:
		if targ_angle >= ANGLE.Backward:
			targ_angle -= ANGLE.Backward
		else:
			targ_angle += ANGLE.Backward
		if targ_angle in _anim[anim_name].offset:
			flip_h = targ_angle != ANGLE.Forward
			return _anim[anim_name].offset[targ_angle]
	return -1

func _AngleFromObserver() -> void:
	if _observer == null:
		_active_angle = ANGLE.All
		return
	
	var zdot = global_transform.basis.z.dot(-_observer.global_transform.basis.z)
	var xdot = global_transform.basis.x.dot(_observer.global_transform.basis.z)

	if zdot > 0.84 and zdot <= 1.0:
		_active_angle = ANGLE.Backward
	elif zdot < -0.84 and zdot >= -1.0:
		_active_angle = ANGLE.Forward
	elif zdot > 0.16 and zdot <= 0.84:
		_active_angle = ANGLE.BLeft if xdot >= 0 else ANGLE.BRight
	elif zdot > -0.16 and zdot <= 0.16:
		_active_angle = ANGLE.Left if xdot >= 0 else ANGLE.Right
	elif zdot >= -0.84 and zdot <= -0.16:
		_active_angle = ANGLE.FLeft if xdot >= 0 else ANGLE.FRight


# ------------------------------------------------------------------------------------------------
# Public Methods
# ------------------------------------------------------------------------------------------------
func add_animation_set(anim_name : String, frames: int, fps : float, loop : bool, offsets : Array = []):
	_anim[anim_name] = {
		"fps":fps,
		"duration": 1.0 / float(fps),
		"frames":frames,
		"loop": loop,
		"offset":{}
	}
	if offsets.size() > 0:
		for i in range(8):
			if i >= offsets.size():
				break
			_anim[anim_name].offset[i] = offsets[i]
	
	if _active_anim == "":
		_active_anim = anim_name
		_frame = 0


func set_animation_angle_offset(anim_name : String, angle : int, offset : int) -> void:
	if not anim_name in _anim:
		print("No animation \"", anim_name, "\" defined.")
		return
	if ANGLE.values().find(angle) < 0:
		print("Invalid angle index ", angle)
		return
	_anim[anim_name].offset[angle] = offset


func set_observer(observer : Spatial) -> void:
	_observer = observer

func get_current_animation() -> String:
	return _active_anim

func animate(anim_name: String) -> void:
	if anim_name in _anim:
		_active_anim = anim_name
		_frame = 0


# ------------------------------------------------------------------------------------------------
# Handler Methods
# ------------------------------------------------------------------------------------------------

