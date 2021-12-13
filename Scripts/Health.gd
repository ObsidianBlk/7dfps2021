extends Node
class_name Health

# -------------------------------------------------------------------------
# Signals
# -------------------------------------------------------------------------
signal health_changed(health, mx_health)
signal hurt(amount)
signal healed(amount)
signal dead(health, mx_health)

# -------------------------------------------------------------------------
# Export Variables
# -------------------------------------------------------------------------
export var max_health : float = 100.0

# -------------------------------------------------------------------------
# Variables
# -------------------------------------------------------------------------
var health : float = 100.0
var immortal : bool = false

# -------------------------------------------------------------------------
# Setters / Getters
# -------------------------------------------------------------------------
func get_max_health() -> float:
	return max_health

func set_max_health(h : float) -> void:
	if h > 0.0:
		max_health = h
		if max_health < health:
			health = max_health

func get_health() -> float:
	return health

func set_health(h : float) -> void:
	if immortal:
		return
	health = min(h, max_health)
	emit_signal("health_changed", health, max_health)
	if health <= 0:
		emit_signal("dead", health, max_health)


# -------------------------------------------------------------------------
# Public Methods
# -------------------------------------------------------------------------
func hurt(amount : float) -> void:
	if health > 0:
		amount = max(0, amount)
		set_health(health - amount)
		emit_signal("hurt", amount)

func heal(amount : float) -> void:
	if health > 0:
		amount = max(0, amount)
		set_health(health + amount)
		emit_signal("healed", amount)

func set_immortal(enable : bool) -> void:
	if health > 0:
		immortal = enable

func is_immortal() -> bool:
	return immortal

func is_alive() -> bool:
	return health > 0

func reset() -> void:
	health = max_health


