extends Node

# -----------------------------------------------------------------------------------------------
# Export Variables
# -----------------------------------------------------------------------------------------------
export var distance_threshold : float = 0.02	setget set_distance_threshold

# -----------------------------------------------------------------------------------------------
# Variables
# -----------------------------------------------------------------------------------------------
var nav_node : Navigation = null
var target_node : WeakRef = null
var last_target_position : Vector3 = Vector3()

var nav_path : PoolVector3Array = PoolVector3Array([])
var nav_path_index = -1

# -----------------------------------------------------------------------------------------------
# Onready Variables
# -----------------------------------------------------------------------------------------------
onready var timer_node : Timer = get_node("Timer")


# -----------------------------------------------------------------------------------------------
# Setters
# -----------------------------------------------------------------------------------------------
func set_distance_threshold(d : float) -> void:
	if d > 0.0:
		distance_threshold = d

# -----------------------------------------------------------------------------------------------
# Override Methods
# -----------------------------------------------------------------------------------------------
func _ready() -> void:
	timer_node.connect("timeout", self, "_on_heartbeat")
	timer_node.start()

# -----------------------------------------------------------------------------------------------
# Private Methods
# -----------------------------------------------------------------------------------------------
func _GetTarget() -> Spatial:
	if target_node != null:
		return target_node.get_ref()
	return null

func _GetParentPosition() -> Vector3:
	var parent = get_parent()
	if parent and parent is Spatial:
		return parent.global_transform.origin
	return Vector3()

func _UpdateNavPath() -> void:
	if not nav_node:
		return
	
	var position : Vector3 = _GetParentPosition()
	
	var target : Spatial = _GetTarget()
	if not target:
		return
	
	print("Nav Distance: ", target.global_transform.origin.distance_to(last_target_position))
	if target.global_transform.origin.distance_to(last_target_position) > distance_threshold:
		print("Last Pos: ", last_target_position, " | Current Pos: ", target.global_transform.origin)
		last_target_position = target.global_transform.origin
		nav_path = nav_node.get_simple_path(position, last_target_position)
		nav_path_index = 0 if nav_path.size() > 0 else -1

# -----------------------------------------------------------------------------------------------
# Public Methods
# -----------------------------------------------------------------------------------------------
func clear() -> void:
	target_node = null
	nav_path = PoolVector3Array([])
	nav_path_index = -1

func set_navigation_node (node : Navigation) -> void:
	nav_node = node

func set_target(target : Spatial) -> void:
	if target == null:
		target_node = null
	else:
		target_node = weakref(target)
		_UpdateNavPath()

func has_target() -> bool:
	return _GetTarget() != null

func next_position() -> Vector3:
	var position = _GetParentPosition()
	var size : int = nav_path.size()
	if size > 0 and nav_path_index < size:
		position = nav_path[nav_path_index]
		nav_path_index += 1
	return position

func end_of_path() -> bool:
	return nav_path.size() <= 0 or nav_path_index == nav_path.size()

# -----------------------------------------------------------------------------------------------
# Handler Methods
# -----------------------------------------------------------------------------------------------
func _on_heartbeat() -> void:
	_UpdateNavPath()

