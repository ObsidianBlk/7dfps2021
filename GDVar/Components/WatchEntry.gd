extends Control

# -----------------------------------------------------------------------------
# Signals
# -----------------------------------------------------------------------------
signal invalidated(entry, varname)

# -----------------------------------------------------------------------------
# Variables
# -----------------------------------------------------------------------------
var _var : GDVar = null

# -----------------------------------------------------------------------------
# Onready Variables
# -----------------------------------------------------------------------------
onready var lbl_varname_node : Label = get_node("LBL_VarName")
onready var lbl_varvalue_node : Label = get_node("LBL_VarValue")

# -----------------------------------------------------------------------------
# Override Methods
# -----------------------------------------------------------------------------


# -----------------------------------------------------------------------------
# Private Methods
# -----------------------------------------------------------------------------
func _GetFont(fname : String) -> Font:
	if has_font(fname, "GDVarWatch"):
		return get_font(fname, "GDVarWatch")
	return null

func _GetStyleBox(sname : String) -> StyleBox:
	if has_stylebox(sname, "GDVarWatch"):
		return get_stylebox(sname, "GDVarWatch")
	return null

func _GetColor(cname : String) -> Color:
	if has_color(cname, "GDVarWatch"):
		return get_color(cname, "GDVarWatch")
	return Color(1,1,1,1)

func _UpdateTheme() -> void:
	var base = "normal"
	if _var == null:
		base = "invalid"
	
	var font_name : Font = _GetFont("name_%s_font"%[base])
	var font_value : Font = _GetFont("value_%s_font"%[base])
	
	var style_name : StyleBox = _GetStyleBox("name_%s"%[base])
	var style_value : StyleBox = _GetStyleBox("value_%s"%[base])
	
	var color_name_font : Color = _GetColor("name_%s_font"%[base])
	var color_value_font : Color = _GetColor("value_%s_font"%[base])
	
	lbl_varname_node.add_font_override("font", font_name)
	lbl_varname_node.add_stylebox_override("normal", style_name)
	lbl_varname_node.add_color_override("font_color", color_name_font)
	
	lbl_varvalue_node.add_font_override("font", font_value)
	lbl_varvalue_node.add_stylebox_override("normal", style_value)
	lbl_varvalue_node.add_color_override("font_color", color_value_font)

# -----------------------------------------------------------------------------
# Public Methods
# -----------------------------------------------------------------------------
func is_valid() -> bool:
	return _var != null


func set_gdvar(v : GDVar) -> void:
	if _var != v and v.is_valid():
		if _var != null:
			_var.disconnect("value_changed", self, "_on_value_changed")
			_var.disconnect("invalidated", self, "_on_invalidated")
		_var = v
		_var.connect("value_changed", self, "_on_value_changed")
		_var.connect("invalidated", self, "_on_invalidated")
		if not lbl_varname_node or not lbl_varvalue_node:
			call_deferred("_on_value_changed", _var.name(), _var.value, null)
			call_deferred("_UpdateTheme")
		else:
			_on_value_changed(_var.name(), _var.value, null)
			_UpdateTheme()


# -----------------------------------------------------------------------------
# Handler Methods
# -----------------------------------------------------------------------------

func _on_value_changed(name : String, value, old_value) -> void:
	lbl_varname_node.text = name
	lbl_varvalue_node.text = String(value)

func _on_invalidated(inv_var : GDVar) -> void:
	if inv_var == _var: # Technically, this should always be true.
		_var.disconnect("value_changed", self, "_on_value_changed")
		_var.disconnect("invalidated", self, "_on_invalidated")
		_var = null
		_UpdateTheme()
		emit_signal("invalidated", self, lbl_varname_node.text)

