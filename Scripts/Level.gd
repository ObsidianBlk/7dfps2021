extends Spatial

# -------------------------------------------------------------------------
# Signals
# -------------------------------------------------------------------------
signal level_change(next_level_src)

# -------------------------------------------------------------------------
# Export Variables
# -------------------------------------------------------------------------
export var enemy_container_path : NodePath = ""
export var player_container_path : NodePath = ""
export var navigation_path : NodePath = ""
export var player_start_path : NodePath = ""
export var reset_depth : float = 20.0
export (String, FILE) var next_level_src = ""

# -------------------------------------------------------------------------
# Variables
# -------------------------------------------------------------------------
var enemy_container_node : Spatial = null
var player_container_node : Spatial = null
var navigation_node : Navigation = null
var player_start_node : Position3D = null

var _player : Spatial = null

# -------------------------------------------------------------------------
# Setters
# -------------------------------------------------------------------------
func set_enemy_container_path (path : NodePath) -> void:
	var ecn : Spatial = null
	if path != "":
		ecn = get_node_or_null(path)
	enemy_container_path = path if ecn != null else ""
	enemy_container_node = ecn

func set_player_container_path (path : NodePath) -> void:
	var pcn : Spatial = null
	if path != "":
		pcn = get_node_or_null(path)
	player_container_path = path if pcn != null else ""
	player_container_node = pcn

func set_navigation_path (path : NodePath) -> void:
	var nav : Spatial = null
	if path != "":
		nav = get_node_or_null(path)
	navigation_path = path if nav != null and nav is Navigation else ""
	navigation_node = nav

func set_player_start_path (path : NodePath) -> void:
	var start : Spatial = null
	if path != "":
		start = get_node_or_null(path)
	player_start_path = path if start != null and start is Position3D else ""
	player_start_node = start

# -------------------------------------------------------------------------
# Override Methods
# -------------------------------------------------------------------------
func _ready() -> void:
	set_enemy_container_path(enemy_container_path)
	set_player_container_path(player_container_path)
	set_navigation_path(navigation_path)
	set_player_start_path(player_start_path)
	_GiveEnemiesNavigation()

func _process(_delta : float) -> void:
	if _player != null:
		if _player.global_transform.origin.y <= -reset_depth:
			_player.global_transform.origin = player_start_node.global_transform.origin

# -------------------------------------------------------------------------
# Private Methods
# -------------------------------------------------------------------------
func _GiveEnemiesNavigation() -> void:
	if not navigation_node:
		print("WARNING: Missing navigation node.")
		return
	if not enemy_container_node:
		print("WARNING: Missing enemy container node.")
		return
	
	var children = enemy_container_node.get_children()
	for child in children:
		if child.has_method("set_navigation"):
			child.set_navigation(navigation_node)

func _GiveEnemiesAnObserver(observer : Spatial) -> void:
	if not enemy_container_node:
		print("WARNING: Missing enemy container node.")
		return
	for child in enemy_container_node.get_children():
		if child.has_method("set_observer"):
			child.set_observer(observer) 


# -------------------------------------------------------------------------
# Public Methods
# -------------------------------------------------------------------------
func attach_player(player : Spatial) -> void:
	if not player_container_node:
		print("WARNING: No defined player container node.")
		return
	if not player_start_node:
		print("WARNING: No player start position node.")
		return
	
	var parent : Spatial = player.get_parent()
	if parent:
		parent.remove_child(player)
	player_container_node.add_child(player)
	player.global_transform.origin = player_start_node.global_transform.origin
	_GiveEnemiesAnObserver(player)
	_player = player


func detach_player(container : Spatial) -> void:
	if not player_container_node:
		print("WARNING: No defined player container node.")
		return
	
	var children = player_container_node.get_children()
	for child in children:
		if child.is_in_group("Player"):
			player_container_node.remove_child(child)
			container.add_child(child)


func call_next_level() -> void:
	emit_signal("level_change", next_level_src)

# -------------------------------------------------------------------------
# Handler Methods
# -------------------------------------------------------------------------


