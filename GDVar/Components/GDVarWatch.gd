extends MarginContainer

# -----------------------------------------------------------------------------
# Contants
# -----------------------------------------------------------------------------
const WATCHENTRY = preload("res://GDVar/Components/WatchEntry.tscn")

# -----------------------------------------------------------------------------
# Export Variables
# -----------------------------------------------------------------------------
export var auto_remove_invalidated : bool = true

# -----------------------------------------------------------------------------
# Variables
# -----------------------------------------------------------------------------
var _Entries = {}

# -----------------------------------------------------------------------------
# Onready Variables
# -----------------------------------------------------------------------------
onready var watchlist_node : VBoxContainer = get_node("ScrollContainer/WatchList")

# -----------------------------------------------------------------------------
# Override Methods
# -----------------------------------------------------------------------------
func _ready() -> void:
	GDVarCtrl.connect("watch", self, "_on_watch")
	GDVarCtrl.connect("unwatch", self, "_on_unwatch")

# -----------------------------------------------------------------------------
# Private Methods
# -----------------------------------------------------------------------------
func _ClearInvalid() -> void:
	for key in _Entries.keys():
		if not _Entries[key].is_valid():
			var entry = _Entries[key]
			_Entries.erase(key)
			_FreeEntry(entry)

func _FreeEntry(entry) -> void:
	var parent = entry.get_parent()
	if parent != null:
		parent.remove_child(entry)
	entry.disconnect("invalidated", self, "_on_entry_invalidated")
	entry.queue_free()

# -----------------------------------------------------------------------------
# Public Methods
# -----------------------------------------------------------------------------
func watch_variable_count() -> int:
	return _Entries.keys().size()

# -----------------------------------------------------------------------------
# Handler Methods
# -----------------------------------------------------------------------------
func _on_watch(gdvar : GDVar) -> void:
	if gdvar.is_valid() and not gdvar.name() in _Entries:
		var entry = WATCHENTRY.instance()
		entry.set_gdvar(gdvar)
		if entry.is_valid():
			watchlist_node.add_child(entry)
			_Entries[gdvar.name()] = entry
			entry.connect("invalidated", self, "_on_entry_invalidated")

func _on_unwatch(gdvar : GDVar) -> void:
	if gdvar.name() in _Entries:
		var entry : Control = _Entries[gdvar.name()]
		_Entries.erase(gdvar.name())
		_FreeEntry(entry)


func _on_entry_invalidated(entry : Control, varname : String) -> void:
	if auto_remove_invalidated and varname in _Entries:
		_Entries.erase(varname)
		_FreeEntry(entry)

