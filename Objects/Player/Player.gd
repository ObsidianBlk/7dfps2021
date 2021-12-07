extends KinematicBody

# -------------------------------------------------------------------------
# Export Variables
# -------------------------------------------------------------------------
export var jump_force : float = 8.0
export var acceleration : float = 100.0
export var friction : float = 0.2
export var gravity : float = 12

# -------------------------------------------------------------------------
# Variables
# -------------------------------------------------------------------------
var velocity : Vector3 = Vector3()

var _grounded : bool = false
var _jumped : bool = false
var _is = {
	"l":0, "r": 0, "f": 0, "b": 0, "axis": Vector2()
}

# -------------------------------------------------------------------------
# Onready Variables
# -------------------------------------------------------------------------
onready var gimble_node : Spatial = get_node("Gimble")

# -------------------------------------------------------------------------
# Override Methods
# -------------------------------------------------------------------------
func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _unhandled_input(event) -> void:
	if event is InputEventMouseMotion:
		var dx = -event.relative.x * 0.5
		var dy = -event.relative.y * 0.5
		rotation_degrees.y += dx
		if gimble_node != null:
			gimble_node.rotation_degrees.x = clamp(gimble_node.rotation_degrees.x + dy, -90, 90)
	elif event is InputEventJoypadMotion:
		if event.axis == 2: # Look Left / Right (R Thumbstick)
			_is.axis.x = _JoyAxisDeadzoned(event.axis_value, -5)
		elif event.axis == 3: # Look Up / Down (R Thumbstick)
			_is.axis.y = _JoyAxisDeadzoned(event.axis_value, -5)
		elif event.axis == 0: # Strafe Left / Right (L Thumbstick)
			var val = _JoyAxisDeadzoned(event.axis_value, 1.0)
			_is.r = val if val > 0 else 0
			_is.l = val if val < 0 else 0
		elif event.axis == 1: # Move Forward / Backward (L Thumbstick)
			var val = _JoyAxisDeadzoned(event.axis_value, 1.0)
			_is.f = val if val < 0 else 0
			_is.b = val if val > 0 else 0
	else:
		if event.is_action_pressed("forward"):
			_is.f = -1.0
		elif event.is_action_released("forward"):
			_is.f = 0.0
		
		if event.is_action_pressed("backward"):
			_is.b = 1.0
		elif event.is_action_released("backward"):
			_is.b = 0.0
		
		if event.is_action_pressed("left"):
			_is.l = -1.0
		elif event.is_action_released("left"):
			_is.l = 0.0
		
		if event.is_action_pressed("right"):
			_is.r = 1.0
		elif event.is_action_released("right"):
			_is.r = 0.0
		
		if event.is_action_pressed("jump") and _grounded and not _jumped:
			_jumped = true

func _physics_process(delta : float) -> void:
	_ProcessJoypadLook()
	var dv = _CalculateDeltaVelocity(delta)
	
	var snap = Vector3()
	if not _grounded:
		dv.y = -gravity * delta
	elif _jumped:
		_jumped = false
		dv.y = jump_force
	else:
		snap = Vector3.DOWN
	
	var drag = velocity * Vector3(friction, 0.0, friction)
	velocity += dv - drag
	velocity = move_and_slide_with_snap(velocity, snap, Vector3.UP, true)
	_grounded = is_on_floor()

# -------------------------------------------------------------------------
# Private Methods
# -------------------------------------------------------------------------
func _JoyAxisDeadzoned(value : float, speed : float = 1.0) -> float:
	if abs(value) < 0.2:
		value = 0
	elif abs(value) > 0.8:
		value = sign(value)
	return value * speed

func _ProcessJoypadLook() -> void:
	rotation_degrees.y += _is.axis.x
	if gimble_node != null:
		gimble_node.rotation_degrees.x = clamp(gimble_node.rotation_degrees.x + _is.axis.y, -85, 85)

func _CalculateDeltaVelocity(delta : float) -> Vector3:
	var base = Vector3(
		(_is.l + _is.r),
		0.0,
		(_is.f + _is.b)
	).normalized().rotated(Vector3.UP, rotation.y)
	return base * acceleration * delta

# -------------------------------------------------------------------------
# Public Methods
# -------------------------------------------------------------------------



# -------------------------------------------------------------------------
# Handler Methods
# -------------------------------------------------------------------------


