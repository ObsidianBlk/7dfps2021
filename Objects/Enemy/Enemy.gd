extends KinematicBody

# -------------------------------------------------------------------------
# ENUMs
# -------------------------------------------------------------------------
enum STATE {Idle, Search, Scout, Chase, Attack}
# NOTE: Scout is the enemy going to the player's last known position if lost
#   during a chase.
enum SENSE {Hearing=1, Sight=2}

# -------------------------------------------------------------------------
# Export Variables
# -------------------------------------------------------------------------
export var fov_range : float = 10.0			setget set_fov_range
export var fov_radius : float = 10.0		setget set_fov_radius
export var hearing_radius : float = 20.0	setget set_hearing_radius
export var turn_speed : float = 50.0
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
var _body_sense : int = 0


var _nav_node : Navigation = null

# -------------------------------------------------------------------------
# Onready Variables
# -------------------------------------------------------------------------
onready var hearing_area_node : Area = get_node("Hearing_Area")
onready var hearing_area_shape : CollisionShape = get_node("Hearing_Area/CollisionShape")
onready var fov_node = get_node("FOV")

# -------------------------------------------------------------------------
# Setters
# -------------------------------------------------------------------------
func set_fov_range(r : float) -> void:
	if r > 0:
		fov_range = r
		if fov_node:
			fov_node.fov_range = fov_range

func set_fov_radius(r : float) -> void:
	if r > 0:
		fov_radius = r
		if fov_node:
			fov_node.fov_radius = fov_radius

func set_hearing_radius(r : float) -> void:
	if r > 0:
		hearing_radius = r
		if hearing_area_shape:
			hearing_area_shape.shape.radius = hearing_radius
		

# -------------------------------------------------------------------------
# Override Methods
# -------------------------------------------------------------------------
func _ready() -> void:
	hearing_area_node.connect("body_entered", self, "_on_BodySensed", [SENSE.Hearing])
	hearing_area_node.connect("body_exited", self, "_on_BodySenseLost", [SENSE.Hearing])
	
	fov_node.connect("body_entered", self, "_on_BodySensed", [SENSE.Sight])
	fov_node.connect("body_exited", self, "_on_BodySenseLost", [SENSE.Sight])
	
	set_fov_radius(fov_radius)
	set_fov_range(fov_range)
	set_hearing_radius(hearing_radius)


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

func _LookDir(dir : Vector3, delta : float) -> void:
	var dangle : float = global_transform.basis.z.angle_to(dir)
	var turn_right = sign(global_transform.basis.x.dot(dir))
	var max_turn_angle = deg2rad(turn_speed) * delta
	if abs(dangle) < max_turn_angle:
		rotation.y = atan2(dir.x, dir.z)
	else:
		rotation.y += max_turn_angle * turn_right

func _AI(delta : float) -> void:
	if _nav_node == null:
		return
	
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
		if _body_sense & SENSE.Sight == SENSE.Sight:
			_state = STATE.Chase
		elif _body_sense & SENSE.Hearing == SENSE.Hearing:
			_state = STATE.Search

func _AI_Search(delta : float) -> void:
	if not _body or _body_sense == 0:
		_state = STATE.Idle
		return
	if _body_sense & SENSE.Sight == SENSE.Sight:
		_state = STATE.Chase
		return
	_LookDir(global_transform.origin - _body.global_transform.origin, delta)

func _AI_Scout(_delta : float) -> void:
	pass

func _AI_Chase(_delta : float) -> void:
	if not _body or _body_sense == 0:
		_state == STATE.Idle
		return
	if _body_sense & SENSE.Sight != SENSE.Sight:
		_state == STATE.Idle # TODO: This is only temp.

func _AI_Attack(_delta : float) -> void:
	pass


# -------------------------------------------------------------------------
# Public Methods
# -------------------------------------------------------------------------
func set_navigation(nav : Navigation) -> void:
	_nav_node = nav


# -------------------------------------------------------------------------
# Handler Methods
# -------------------------------------------------------------------------
func _on_BodySensed(body : Spatial, sense : int) -> void:
	if body.is_in_group("Player"):
		if _body == null:
			_body = body
		if _body == body:
			_body_sense = _body_sense | sense
	#print("Sense (gain): ", _body_sense)

func _on_BodySenseLost(body : Spatial, sense : int) -> void:
	if body.is_in_group("Player") and body == _body:
		_body_sense = _body_sense & (~sense)
		if _body_sense == 0:
			_body = null
	#print("Sense (lost): ", _body_sense)



