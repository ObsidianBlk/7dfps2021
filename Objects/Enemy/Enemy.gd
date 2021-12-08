extends KinematicBody

# -------------------------------------------------------------------------
# ENUMs
# -------------------------------------------------------------------------
enum STATE {Idle, Search, Scout, Chase, Attack}
# NOTE: Scout is the enemy going to the player's last known position if lost
#   during a chase.

# -------------------------------------------------------------------------
# Export Variables
# -------------------------------------------------------------------------
export var jump_force : float = 8.0
export var acceleration : float = 80.0
export var friction : float = 0.2
export var gravity : float = 12

# -------------------------------------------------------------------------
# Variables
# -------------------------------------------------------------------------
var velocity : Vector3 = Vector3()

var _jumped : bool = false
var _grounded : bool = false

var _state : int = STATE.Idle
var _body : Spatial = null

# -------------------------------------------------------------------------
# Onready Variables
# -------------------------------------------------------------------------
onready var hearing_area_node : Area = get_node("Hearing_Area")

# -------------------------------------------------------------------------
# Override Methods
# -------------------------------------------------------------------------
func _ready() -> void:
	hearing_area_node.connect("body_entered", self, "_on_body_entered")
	hearing_area_node.connect("body_exited", self, "_on_body_exited")


func _physics_process(delta : float) -> void:
	_AI(delta)
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
func _CalculateDeltaVelocity(delta : float) -> Vector3:
	var base = Vector3(
		0.0,
		0.0,
		0.0
	).normalized().rotated(Vector3.UP, rotation.y)
	return base * acceleration * delta

func _AI(delta : float) -> void:
	match _state:
		STATE.Idle:
			_AI_Idle(delta)
		STATE.Search:
			_AI_Search(delta)
		STATE.Scout:
			_AI_Scout(delta)
		STATE.Chase:
			_AI_Chase(delta)
		STATE.Attack:
			_AI_Attack(delta)

func _AI_Idle(_delta : float) -> void:
	# TODO: Replace this with a check for "sound level"
	if _body != null:
		_state = STATE.Search

func _AI_Search(_delta : float) -> void:
	if not _body:
		_state = STATE.Idle
		return
	var t : Transform = get_transform()
	t = t.looking_at(_body.global_transform.origin, Vector3.UP)
	transform.basis.z = transform.basis.z.linear_interpolate(t.basis.z, 0.2)
	print(transform.basis.z)
	#transform.basis.z = lerp(transform.basis.z, t.basis.z, 0.2)

func _AI_Scout(_delta : float) -> void:
	pass

func _AI_Chase(_delta : float) -> void:
	pass

func _AI_Attack(_delta : float) -> void:
	pass


# -------------------------------------------------------------------------
# Handler Methods
# -------------------------------------------------------------------------
func _on_body_entered(body : Spatial) -> void:
	if body.is_in_group("Player") and _body == null:
		_body = body

func _on_body_exited(body : Spatial) -> void:
	if body.is_in_group("Player") and body == _body:
		_state = STATE.Idle
		_body = null


