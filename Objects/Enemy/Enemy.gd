extends KinematicBody
tool

# -------------------------------------------------------------------------
# Constants and ENUMs
# -------------------------------------------------------------------------
enum STATE {Idle, Search, Scout, Chase, Attack}
# NOTE: Scout is the enemy going to the player's last known position if lost
#   during a chase.
enum SENSE {Hearing=1, Sight=2}

const FACING_ANGLE_THRESHOLD = deg2rad(2.5)
const DISTANCE_THRESHOLD = 1.5

# -------------------------------------------------------------------------
# Export Variables
# -------------------------------------------------------------------------
export (float, -180, 180) var facing = 0.0		setget set_facing
export var fov_range : float = 10.0				setget set_fov_range
export var fov_inner_radius : float = 2.0		setget set_fov_inner_radius
export var fov_outer_radius : float = 10.0		setget set_fov_outer_radius
export var hearing_radius : float = 20.0		setget set_hearing_radius
export var turn_speed : float = 180.0
export var jump_force : float = 8.0
export var speed : float = 120.0
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

var _nav_position : Vector3 = Vector3()
var _nav_altered : bool = false

# -------------------------------------------------------------------------
# Onready Variables
# -------------------------------------------------------------------------
onready var sprite_node = get_node("DoomSprite3D")
onready var hearing_area_node : Area = get_node("Hearing_Area")
onready var hearing_area_shape : CollisionShape = get_node("Hearing_Area/CollisionShape")
onready var fov_node = get_node("FOV")
onready var navigator_node = get_node("Navigator")

# -------------------------------------------------------------------------
# Setters
# -------------------------------------------------------------------------
func set_facing(f : float) -> void:
	facing = clamp(f, -180, 180)
	_FaceAngle(facing, true)

func set_fov_range(r : float) -> void:
	if r > 0:
		fov_range = r
		if fov_node:
			fov_node.fov_range = fov_range

func set_fov_inner_radius(r : float) -> void:
	if r >= 0:
		fov_inner_radius = r
		if fov_node:
			fov_node.fov_inner_radius = fov_inner_radius

func set_fov_outer_radius(r : float) -> void:
	if r > 0:
		fov_outer_radius = r
		if fov_node:
			fov_node.fov_outer_radius = fov_outer_radius

func set_hearing_radius(r : float) -> void:
	if r > 0:
		hearing_radius = r
		if hearing_area_shape:
			hearing_area_shape.shape.radius = hearing_radius
		

# -------------------------------------------------------------------------
# Override Methods
# -------------------------------------------------------------------------
func _ready() -> void:
	_nav_position = global_transform.origin
	
	if not Engine.editor_hint:
		sprite_node.add_animation_set("idle", 1, 1, true, [0, 5, 10, 15, 20])
		sprite_node.add_animation_set("walk", 4, 12, true, [0, 5, 10, 15, 20])
		sprite_node.add_animation_set("attack", 2, 12, true, [25, 30, 35, 40, 45])
		sprite_node.add_animation_set("pain", 1, 12, false, [50, 51, 52, 53, 54])
		sprite_node.add_animation_set("die", 5, 12, true, [55])
		
		hearing_area_node.connect("body_entered", self, "_on_BodySensed", [SENSE.Hearing])
		hearing_area_node.connect("body_exited", self, "_on_BodySenseLost", [SENSE.Hearing])
	
		fov_node.connect("body_entered", self, "_on_BodySensed", [SENSE.Sight])
		fov_node.connect("body_exited", self, "_on_BodySenseLost", [SENSE.Sight])
		
		navigator_node.connect("path_altered", self, "_on_nav_path_altered")
	else:
		set_physics_process(false)
	
	set_fov_inner_radius(fov_inner_radius)
	set_fov_outer_radius(fov_outer_radius)
	set_fov_range(fov_range)
	set_hearing_radius(hearing_radius)


func _physics_process(delta : float) -> void:
	if Engine.editor_hint:
		return
	
	#_AI(delta)
	velocity = _CalculateVelocity(delta)
	
	var snap = Vector3()
	if _grounded or not _jumped:
		snap = Vector3.DOWN
	
	velocity = move_and_slide_with_snap(velocity, snap, Vector3.UP, true)
	_grounded = is_on_floor()

# -------------------------------------------------------------------------
# Private Methods
# -------------------------------------------------------------------------

func _AngleToFace(position : Vector3, unsigned : bool = false) -> float:
	var dir = global_transform.origin.direction_to(position)
	dir.y = global_transform.basis.z.y
	var angle : float = global_transform.basis.z.angle_to(dir.normalized())
	if unsigned:
		#print("Angle: ", rad2deg(angle))
		return abs(angle)
	return angle

func _CalculateVelocity(delta : float) -> Vector3:
	var base : Vector3 = Vector3()
	if not _IsNearNavPosition():
		if _AngleToFace(_nav_position, true) > deg2rad(1.0):
			#print("Facing")
			_LookAt(_nav_position, delta)
		else:
			base = global_transform.basis.z
	base *= speed * delta
	
	if not _grounded:
		base.y = velocity.y - (gravity * delta)
	elif _jumped:
		_jumped = false
		base.y = jump_force
	
	return base

func _FaceAngle(angle : float, inDeg : bool = false) -> void:
	if inDeg:
		angle = deg2rad(angle)
	_FaceDir(Vector3(0,0,1).rotated(Vector3.UP, angle))

func _FacePosition(position : Vector3) -> void:
	_FaceDir(global_transform.origin.direction_to(position))

func _FaceDir(dir : Vector3) -> void:
	rotation.y = atan2(dir.x, dir.z)

func _LookAt(position : Vector3, delta : float) -> void:
	_LookTo(global_transform.origin.direction_to(position), delta)

func _LookTo(dir : Vector3, delta : float) -> void:
	dir.y = global_transform.basis.z.y
	var dangle : float = abs(global_transform.basis.z.angle_to(dir))
	var turn_right = sign(global_transform.basis.x.dot(dir))
	var max_turn_angle = deg2rad(turn_speed) * delta
	if dangle < max_turn_angle:
		rotation.y = atan2(dir.x, dir.z)
	else:
		rotation.y += max_turn_angle * turn_right

func _GetNextNavPosition() -> void:
	_nav_position = navigator_node.next_position()
	if abs(_nav_position.y - global_transform.origin.y) < 0.3:
		_nav_position.y = global_transform.origin.y

func _IsNearNavPosition() -> bool:
	if global_transform.origin.distance_to(_nav_position) < 1.0:
		var pos = Vector2(global_transform.origin.x, global_transform.origin.z)
		var mpos = Vector2(_nav_position.x, _nav_position.z)
		if pos.distance_to(mpos) < DISTANCE_THRESHOLD:
			return true
	return false

func _CanSense() -> bool:
	return _body != null and _body_sense != 0
	
func _CanHear() -> bool:
	return _body != null and (_body_sense & SENSE.Hearing) == SENSE.Hearing

func _CanSee() -> bool:
	return _body != null and (_body_sense & SENSE.Sight) == SENSE.Sight

func _AI(delta : float) -> void:
	match _state:
		STATE.Idle:
			#print("Idle")
			_AI_Idle(delta)
		STATE.Search:
			#print("Search")
			_AI_Search(delta)
		STATE.Scout:
			#print("Scout")
			_AI_Scout(delta)
		STATE.Chase:
			#print("Chase")
			_AI_Chase(delta)
		STATE.Attack:
			#print("Attack")
			_AI_Attack(delta)

func _AI_Idle(_delta : float) -> void:
	# TODO: Replace this with a check for "sound level"
	if _body != null:
		if _body_sense & SENSE.Sight == SENSE.Sight:
			navigator_node.set_target(_body)
			_state = STATE.Chase
		elif _body_sense & SENSE.Hearing == SENSE.Hearing:
			_state = STATE.Search

func _AI_Search(delta : float) -> void:
	if not _CanSense():
		_state = STATE.Idle
		return
	if _CanSee():
		navigator_node.set_target(_body)
		_state = STATE.Chase
		return
	_LookAt(_body.global_transform.origin, delta)

func _AI_Scout(_delta : float) -> void:
	if _CanSee():
		navigator_node.set_target(_body)
		_state = STATE.Chase
		return
	if _IsNearNavPosition():
		if not navigator_node.end_of_path():
			_GetNextNavPosition()
		elif _CanHear():
			_state = STATE.Search
		else:
			_state = STATE.Idle
		

func _AI_Chase(_delta : float) -> void:
	if not _CanSense() or not _CanSee():
		navigator_node.set_target(null)
		if navigator_node.end_of_path():
			_nav_position = global_transform.origin
			_state = STATE.Search if _CanHear() else STATE.Idle
		else:
			_state = STATE.Scout
		return
	
	if _IsNearNavPosition() or _nav_altered:
		_nav_altered = false
		_GetNextNavPosition()

func _AI_Attack(_delta : float) -> void:
	pass


# -------------------------------------------------------------------------
# Public Methods
# -------------------------------------------------------------------------
func set_navigation(nav : Navigation) -> void:
	navigator_node.set_navigation_node(nav)

func set_observer(observer : Spatial) -> void:
	sprite_node.set_observer(observer)


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

func _on_nav_path_altered() -> void:
	_nav_altered = true

