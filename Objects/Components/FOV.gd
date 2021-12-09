extends Spatial
tool

# -------------------------------------------------------------------------
# Signals
# -------------------------------------------------------------------------
signal body_entered(body)
signal body_exited(body)

# -------------------------------------------------------------------------
# Export Variables
# -------------------------------------------------------------------------
export var fov_range : float = 10.0			setget set_fov_range
export var fov_radius : float = 10.0		setget set_fov_radius

# -------------------------------------------------------------------------
# Variables
# -------------------------------------------------------------------------
var _rdy : bool = false

# -------------------------------------------------------------------------
# Onready Variables
# -------------------------------------------------------------------------
onready var area_node : Area = get_node("Area")
onready var collisionshape_node : CollisionShape = get_node("Area/CollisionShape")
onready var sightcheck_ray : RayCast = get_node("SightCheck")

# -------------------------------------------------------------------------
# Setters / Getters
# -------------------------------------------------------------------------
func set_fov_range(r : float) -> void:
	if r > 0:
		fov_range = r
		if _rdy:
			collisionshape_node.shape.points = _BuildCone()
			sightcheck_ray.cast_to = Vector3(0, 0, fov_range)

func set_fov_radius(r : float) -> void:
	if r > 0:
		fov_radius = r
		if _rdy:
			collisionshape_node.shape.points = _BuildCone()

# -------------------------------------------------------------------------
# Override Methods
# -------------------------------------------------------------------------
func _ready() -> void:
	_rdy = true
	area_node.connect("body_entered", self, "_on_body_entered")
	area_node.connect("body_exited", self, "_on_body_exited")

# -------------------------------------------------------------------------
# Private Methods
# -------------------------------------------------------------------------
func _BuildCone() -> Array:
	var points = [Vector3()]
	var dangle = deg2rad(45.0)
	for i in range(8):
		var v = Vector2(0, 1).rotated(i * dangle) * fov_radius
		points.append(Vector3(v.x, v.y, fov_range))
	return points


# -------------------------------------------------------------------------
# Public Methods
# -------------------------------------------------------------------------
func can_see(body : Spatial) -> bool:
	# NOTE: Can't seem to align raycast
	if area_node.overlaps_body(body):
		print("In Area")
		var gt : Transform = sightcheck_ray.global_transform
		gt = gt.looking_at(body.global_transform.origin + Vector3(0, 0.5, 0), Vector3.UP)
		sightcheck_ray.global_transform = gt
		#sightcheck_ray.look_at(body.global_transform.origin + Vector3(0, 0.5, 0.0), Vector3.UP)
		sightcheck_ray.force_raycast_update()
		if sightcheck_ray.collide_with_bodies:
			print("Collisions: ", sightcheck_ray.get_collider(), " | ", body)
			return sightcheck_ray.get_collider() == body
	return false


# -------------------------------------------------------------------------
# Handler Methods
# -------------------------------------------------------------------------
func _on_body_entered(body : Spatial) -> void:
	emit_signal("body_entered", body)

func _on_body_exited(body : Spatial) -> void:
	emit_signal("body_exited", body)

