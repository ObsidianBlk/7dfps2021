extends KinematicBody
tool

# -------------------------------------------------------------------------
# Constants and ENUMs
# -------------------------------------------------------------------------
enum STATE {Idle, Search, Scout, Chase, Attack, Hurt, Dead}
# NOTE: Scout is the enemy going to the player's last known position if lost
#   during a chase.
enum SENSE {Hearing=1, Sight=2}

const FACING_ANGLE_THRESHOLD = deg2rad(2.5)
const DISTANCE_THRESHOLD = 1.5

# -------------------------------------------------------------------------
# Property Variables
# -------------------------------------------------------------------------
var facing = 0.0
var max_health : float = 10.0
var fov_range : float = 10.0
var fov_inner_radius : float = 2.0
var fov_outer_radius : float = 10.0
var hearing_radius : float = 20.0
var turn_speed : float = 180.0
var jump_force : float = 8.0
var speed : float = 120.0
var gravity : float = 12

# -------------------------------------------------------------------------
# Variables
# -------------------------------------------------------------------------
var velocity : Vector3 = Vector3()

var _jumped : bool = false
var _grounded : bool = false

var _state : int = STATE.Idle
var _body : Spatial = null
var _body_sense : int = 0
var _body_attackable : bool = false

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
onready var attackarea_node : Area = get_node("AttackArea")
onready var health_node : Health = get_node("Health")

# -------------------------------------------------------------------------
# Setters
# -------------------------------------------------------------------------
func set_facing(f : float) -> void:
	facing = clamp(f, -180, 180)
	_FaceAngle(facing, true)

func set_max_health(h : float) -> void:
	max_health = h
	if health_node:
		health_node.max_health = max_health

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
		set_max_health(max_health)
		
		health_node.connect("dead", self, "_on_dead")
		health_node.connect("hurt", self, "_on_hurt")
		
		sprite_node.add_animation_set("idle", 1, 1, true, [0, 5, 10, 15, 20])
		sprite_node.add_animation_set("move", 4, 8, true, [0, 5, 10, 15, 20])
		sprite_node.add_animation_set("attack", 2, 8, true, [25, 30, 35, 40, 45])
		sprite_node.add_animation_set("pain", 1, 4, false, [50, 51, 52, 53, 54])
		sprite_node.add_animation_set("die", 5, 8, false, [55])
		
		sprite_node.connect("animation_looping", self, "_on_sprite_anim_looping")
		sprite_node.connect("animation_complete", self, "_on_sprite_anim_complete")
		
		hearing_area_node.connect("body_entered", self, "_on_BodySensed", [SENSE.Hearing])
		hearing_area_node.connect("body_exited", self, "_on_BodySenseLost", [SENSE.Hearing])
	
		fov_node.connect("body_entered", self, "_on_BodySensed", [SENSE.Sight])
		fov_node.connect("body_exited", self, "_on_BodySenseLost", [SENSE.Sight])
		
		navigator_node.connect("path_altered", self, "_on_nav_path_altered")
		
		attackarea_node.connect("body_entered", self, "_on_attackarea_entered")
		attackarea_node.connect("body_exited", self, "_on_attackarea_exited")
	else:
		set_physics_process(false)
	
	set_fov_inner_radius(fov_inner_radius)
	set_fov_outer_radius(fov_outer_radius)
	set_fov_range(fov_range)
	set_hearing_radius(hearing_radius)


func _physics_process(delta : float) -> void:
	if Engine.editor_hint:
		return
	
	_AI(delta)
	velocity = _CalculateVelocity(delta)
	
	var snap = Vector3()
	if _grounded or not _jumped:
		snap = Vector3.DOWN
	
	velocity = move_and_slide_with_snap(velocity, snap, Vector3.UP, true)
	_grounded = is_on_floor()

# -------------------------------------------------------------------------
# Property Methods
# -------------------------------------------------------------------------
func _get(property : String):
	match property:
		"setup/facing":
			return facing
		"movement/speed":
			return speed
		"movement/turn_speed":
			return turn_speed
		"movement/jump_force":
			return jump_force
		"movement/gravity":
			return gravity
		"senses/fov/inner_radius":
			return fov_inner_radius
		"senses/fov/outer_radius":
			return fov_outer_radius
		"senses/fov/range":
			return fov_range
		"senses/hearing_radius":
			return hearing_radius
	return null

func _set(property : String, value) -> bool:
	var success = true
	match property:
		"setup/facing":
			if typeof(value) ==  TYPE_REAL:
				set_facing(value)
			else : success = false
		"movement/speed":
			if typeof(value) ==  TYPE_REAL and value > 0.0:
				speed = value
			else : success = false
		"movement/turn_speed":
			if typeof(value) ==  TYPE_REAL and value > 0.0:
				turn_speed = value
			else : success = false
		"movement/jump_force":
			if typeof(value) ==  TYPE_REAL and value > 0.0:
				jump_force = value
			else : success = false
		"movement/gravity":
			if typeof(value) ==  TYPE_REAL:
				gravity = value
			else : success = false
		"senses/fov/inner_radius":
			if typeof(value) ==  TYPE_REAL:
				set_fov_inner_radius(value)
			else : success = false
		"senses/fov/outer_radius":
			if typeof(value) ==  TYPE_REAL:
				set_fov_outer_radius(value)
			else : success = false
		"senses/fov/range":
			if typeof(value) ==  TYPE_REAL:
				set_fov_range(value)
			else : success = false
		"senses/hearing_radius":
			if typeof(value) ==  TYPE_REAL:
				set_hearing_radius(value)
			else : success = false
		_:
			success = false
	if success:
		property_list_changed_notify()
	return success


func _get_property_list():
	return [
		{
			name = "Enemy Node",
			type = TYPE_NIL,
			usage = PROPERTY_USAGE_CATEGORY
		},
		{
			name = "setup/facing",
			type = TYPE_REAL,
			hint = PROPERTY_HINT_RANGE,
			hint_string = "-180,180",
			usage = PROPERTY_USAGE_DEFAULT
		},
		{
			name = "movement/speed",
			type = TYPE_REAL,
			usage = PROPERTY_USAGE_DEFAULT
		},
		{
			name = "movement/turn_speed",
			type = TYPE_REAL,
			usage = PROPERTY_USAGE_DEFAULT
		},
		{
			name = "movement/jump_force",
			type = TYPE_REAL,
			usage = PROPERTY_USAGE_DEFAULT
		},
		{
			name = "movement/gravity",
			type = TYPE_REAL,
			usage = PROPERTY_USAGE_DEFAULT
		},
		{
			name = "senses/fov/inner_radius",
			type = TYPE_REAL,
			usage = PROPERTY_USAGE_DEFAULT
		},
		{
			name = "senses/fov/outer_radius",
			type = TYPE_REAL,
			usage = PROPERTY_USAGE_DEFAULT
		},
		{
			name = "senses/fov/range",
			type = TYPE_REAL,
			usage = PROPERTY_USAGE_DEFAULT
		},
		{
			name = "senses/hearing_radius",
			type = TYPE_REAL,
			usage = PROPERTY_USAGE_DEFAULT
		}
	]

# -------------------------------------------------------------------------
# Private Methods
# -------------------------------------------------------------------------

func _AngleToFace(position : Vector3, unsigned : bool = false) -> float:
	var dir = global_transform.origin.direction_to(position)
	dir.y = global_transform.basis.z.y
	var angle : float = global_transform.basis.z.angle_to(dir.normalized())
	if unsigned:
		return abs(angle)
	return angle

func _CalculateVelocity(delta : float) -> Vector3:
	var base : Vector3 = Vector3()
	if _state != STATE.Dead:
		if not _IsNearNavPosition():
			if _AngleToFace(_nav_position, true) > deg2rad(1.0):
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
	return _body != null and _body_sense != 0 and _body.is_alive()
	
func _CanHear() -> bool:
	return _body != null and (_body_sense & SENSE.Hearing) == SENSE.Hearing and _body.is_alive()

func _CanSee() -> bool:
	return _body != null and (_body_sense & SENSE.Sight) == SENSE.Sight and _body.is_alive()

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
		STATE.Hurt:
			if sprite_node.get_current_animation() != "pain":
				sprite_node.animate("pain")
		STATE.Dead:
			if sprite_node.get_current_animation() != "die":
				sprite_node.animate("die")

func _AI_Idle(_delta : float) -> void:
	if sprite_node.get_current_animation() != "idle":
		sprite_node.animate("idle")
	if _CanSense():
		if _CanSee():
			navigator_node.set_target(_body)
			_state = STATE.Chase
		elif _CanHear():
			_state = STATE.Search

func _AI_Search(delta : float) -> void:
	if sprite_node.get_current_animation() != "move":
		sprite_node.animate("move")
	if not _CanSense():
		_state = STATE.Idle
		return
	if _CanSee():
		navigator_node.set_target(_body)
		_state = STATE.Chase
		return
	_LookAt(_body.global_transform.origin, delta)

func _AI_Scout(_delta : float) -> void:
	if sprite_node.get_current_animation() != "move":
		sprite_node.animate("move")
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
	if sprite_node.get_current_animation() != "move":
		sprite_node.animate("move")
	if not _CanSense() or not _CanSee():
		navigator_node.set_target(null)
		if navigator_node.end_of_path():
			_nav_position = global_transform.origin
			_state = STATE.Search if _CanHear() else STATE.Idle
		else:
			_state = STATE.Scout
		return
	if _body_attackable:
		_state = STATE.Attack
		return
	
	if _IsNearNavPosition() or _nav_altered:
		_nav_altered = false
		_GetNextNavPosition()

func _AI_Attack(_delta : float) -> void:
	if sprite_node.get_current_animation() != "attack":
		sprite_node.animate("attack")
	if not _body_attackable:
		if _CanSee():
			_state = STATE.Chase
		elif _CanHear():
			_state = STATE.Search
		else:
			_state = STATE.Idle


# -------------------------------------------------------------------------
# Public Methods
# -------------------------------------------------------------------------
func set_navigation(nav : Navigation) -> void:
	navigator_node.set_navigation_node(nav)

func set_observer(observer : Spatial) -> void:
	sprite_node.set_observer(observer)

func get_health() -> Health:
	return health_node

func is_alive() -> bool:
	return _state != STATE.Dead

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

func _on_attackarea_entered(body : Spatial) -> void:
	if body == _body:
		_body_attackable = true

func _on_attackarea_exited(body : Spatial) -> void:
	if body == _body:
		_body_attackable = false

func _on_sprite_anim_looping(anim_name : String) -> void:
	if anim_name == "attack" and _body_attackable and _state == STATE.Attack:
		var h : Health = _body.get_health()
		if h:
			h.hurt(5)
			if h.get_health() <= 0:
				_body_attackable = false

func _on_sprite_anim_complete(anim_name : String) -> void:
	match anim_name:
		"pain":
			_state = STATE.Idle

func _on_hurt(amount : float) -> void:
	if _state != STATE.Dead:
		_state = STATE.Hurt

func _on_dead(health : float, mhealth : float) -> void:
	_state = STATE.Dead
