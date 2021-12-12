extends PanelContainer
tool

# -------------------------------------------------------------------------
# Signals
# -------------------------------------------------------------------------
signal term_visible()
signal term_hidden()

# -------------------------------------------------------------------------
# Constants and ENUMs
# -------------------------------------------------------------------------
enum EDGE { LEFT, RIGHT, TOP, BOTTOM }
enum ANCHOR { LEFT_TOP, MIDDLE, RIGHT_BOTTOM }

# -------------------------------------------------------------------------
# Property Variables
# -------------------------------------------------------------------------
var __config_start_hidden : bool = true
var __config_scale_width : float = 1.0
var __config_scale_height : float = 1.0

var __animation_slide_out : bool = true
var __animation_duration : float = 0.25
var __animation_edge : int = EDGE.TOP
var __animation_anchor : int = ANCHOR.LEFT_TOP

# -------------------------------------------------------------------------
# Variables
# -------------------------------------------------------------------------
var __ready = false
var __animating : int = 0

# -------------------------------------------------------------------------
# Onready Variables
# -------------------------------------------------------------------------
onready var tween_node : Tween = get_node("Tween")

# -------------------------------------------------------------------------
# Override Methods
# -------------------------------------------------------------------------
func _ready() -> void:
	__ready = true
	_UpdateScale()
	if not Engine.editor_hint:
		var parent = get_parent()
		if parent:
			parent.connect("resized", self, "_on_resized")
		if __config_start_hidden:
			_SlideOut(true)
		else:
			_SlideIn(true)
		tween_node.connect("tween_all_completed", self, "_on_tween_complete")


func _get(property : String):
	match property:
		"animation/slide_out":
			return __animation_slide_out
		"animation/duration":
			return __animation_duration
		"animation/edge":
			return __animation_edge
		"animation/anchor":
			return __animation_anchor
		"config/start_hidden":
			return __config_start_hidden
		"config/scale_width":
			return __config_scale_width
		"config/scale_height":
			return __config_scale_height
	return null


func _set(property : String, value) -> bool:
	var success = true
	match property:
		"animation/slide_out":
			if typeof(value) == TYPE_BOOL:
				__animation_slide_out = value
			else: success = false
		"animation/duration":
			if typeof(value) == TYPE_REAL:
				__animation_duration = 0.0 if value < 0.0 else value
			else : success = false
		"animation/edge":
			if typeof(value) == TYPE_INT and EDGE.values().find(value) >= 0:
				__animation_edge = value
				if __ready or Engine.editor_hint:
					if visible:
						_SlideIn(not __animation_slide_out)
					else:
						_SlideOut(not __animation_slide_out)
			else : success = false
		"animation/anchor":
			if typeof(value) == TYPE_INT and ANCHOR.values().find(value) >= 0:
				__animation_anchor = value
				if __ready or Engine.editor_hint:
					if visible:
						_SlideIn(not __animation_slide_out)
					else:
						_SlideOut(not __animation_slide_out)
			else : success = false
		"config/start_hidden":
			if typeof(value) == TYPE_BOOL:
				__config_start_hidden = value
			else : success = false
		"config/scale_width":
			if typeof(value) == TYPE_REAL:
				if value >= 0.01 and value <= 1.0:
					__config_scale_width = value
					if __ready or Engine.editor_hint:
						_UpdateScale()
				else : success = false
			else : success = false
		"config/scale_height":
			if typeof(value) == TYPE_REAL:
				if value >= 0.01 and value <= 1.0:
					__config_scale_height = value
					if __ready or Engine.editor_hint:
						_UpdateScale()
				else : success = false
			else : success = false
		_:
			success = false
	
	if success:
		property_list_changed_notify()
	return success


func _get_property_list():
	return [
		{
			name = "Sliding Terminal",
			type = TYPE_NIL,
			usage = PROPERTY_USAGE_CATEGORY
		},
		{
			name = "config/start_hidden",
			type = TYPE_BOOL,
			usage = PROPERTY_USAGE_DEFAULT
		},
		{
			name = "config/scale_width",
			type = TYPE_REAL,
			hint = PROPERTY_HINT_RANGE,
			hint_string = "0.01, 1.0",
			usage = PROPERTY_USAGE_DEFAULT
		},
		{
			name = "config/scale_height",
			type = TYPE_REAL,
			hint = PROPERTY_HINT_RANGE,
			hint_string = "0.01, 1.0",
			usage = PROPERTY_USAGE_DEFAULT
		},
		{
			name = "animation/slide_out",
			type = TYPE_BOOL,
			usage = PROPERTY_USAGE_DEFAULT
		},
		{
			name = "animation/edge",
			type = TYPE_INT,
			hint = PROPERTY_HINT_ENUM,
			hint_string = EDGE,
			usage = PROPERTY_USAGE_DEFAULT
		},
		{
			name = "animation/anchor",
			type = TYPE_INT,
			hint = PROPERTY_HINT_ENUM,
			hint_string = ANCHOR,
			usage = PROPERTY_USAGE_DEFAULT
		},
		{
			name = "animation/duration",
			type = TYPE_REAL,
			usage = PROPERTY_USAGE_DEFAULT
		}
	]

# -------------------------------------------------------------------------
# Private Methods
# -------------------------------------------------------------------------
func _OverrideStyle(ctrl : Control, target : String, source : String, theme_type : String) -> void:
	if not ctrl.has_stylebox_override(target):
		var style : StyleBox = _get("theme_overrides/styles/" + source)
		if style != null:
			ctrl.add_stylebox_override(target, style)
		elif ctrl.has_stylebox(source, theme_type):
			ctrl.add_stylebox_override(target, get_stylebox(source, theme_type))

func _UpdateStyles() -> void:
	if Engine.editor_hint:
		return
	_OverrideStyle(self, "panel", "normal", "GDVarSlidingTerminal")

func _UpdateScale() -> void:
	#if Engine.editor_hint and not is_inside_tree():
	#	return
	
	var screen_size = get_viewport_rect().size
	rect_size = Vector2(
		screen_size.x * __config_scale_width,
		screen_size.y * __config_scale_height
	)
	if visible:
		_SlideIn(true)
	else:
		_SlideOut(true)


func _GetAnimPositions() -> Dictionary:
	if Engine.editor_hint and not is_inside_tree():
		return {
			"hidden":Vector2(),
			"visible":Vector2(),
			"distance":0
		}
	var screen_size = get_viewport_rect().size
	var hidden_pos : Vector2 = Vector2()
	var visible_pos : Vector2 = Vector2()
	
	var mid_y = (screen_size.y - rect_size.y) * 0.5
	var lower_y = screen_size.y - rect_size.y
	var mid_x = (screen_size.x - rect_size.x) * 0.5
	var far_x = screen_size.x - rect_size.x
	
	match __animation_edge:
		EDGE.LEFT:
			match __animation_anchor:
				ANCHOR.LEFT_TOP:
					hidden_pos.x = -rect_size.x
				ANCHOR.MIDDLE:
					hidden_pos = Vector2(-rect_size.x, mid_y)
					visible_pos.y = mid_y
				ANCHOR.RIGHT_BOTTOM:
					hidden_pos = Vector2(-rect_size.x, lower_y)
					visible_pos.y = lower_y
		EDGE.RIGHT:
			match __animation_anchor:
				ANCHOR.LEFT_TOP:
					hidden_pos.x = screen_size.x
					visible_pos.x = far_x
				ANCHOR.MIDDLE:
					hidden_pos = Vector2(screen_size.x, mid_y)
					visible_pos = Vector2(far_x, mid_y)
				ANCHOR.RIGHT_BOTTOM:
					hidden_pos = Vector2(screen_size.x, lower_y)
					visible_pos = Vector2(far_x, lower_y)
		EDGE.TOP:
			match __animation_anchor:
				ANCHOR.LEFT_TOP:
					hidden_pos.y = -rect_size.y
				ANCHOR.MIDDLE:
					hidden_pos = Vector2(mid_x, -rect_size.y)
					visible_pos.x = mid_x
				ANCHOR.RIGHT_BOTTOM:
					hidden_pos = Vector2(far_x, -rect_size.y)
					visible_pos.x = far_x
		EDGE.BOTTOM:
			match __animation_anchor:
				ANCHOR.LEFT_TOP:
					hidden_pos.y = screen_size.y
					visible_pos.y = lower_y
				ANCHOR.MIDDLE:
					hidden_pos = Vector2(mid_x, screen_size.y)
					visible_pos = Vector2(mid_x, lower_y)
				ANCHOR.RIGHT_BOTTOM:
					hidden_pos = Vector2(far_x, screen_size.y)
					visible_pos = Vector2(far_x, lower_y)
	
	return {
		"hidden":hidden_pos,
		"visible":visible_pos,
		"distance":hidden_pos.distance_to(visible_pos)
	}


func _SlideOut(instant : bool = false) -> void:
	if Engine.editor_hint or not tween_node:
		instant = true
	if tween_node:
		tween_node.stop_all()
	var apos = _GetAnimPositions()
	if Engine.editor_hint or instant:
		rect_position = apos.hidden
		visible = false
	elif not Engine.editor_hint:
		__animating = 0
		var cdistance = rect_position.distance_to(apos.hidden)
		var duration = __animation_duration * (cdistance / apos.distance)
		tween_node.interpolate_property(
			self, "rect_position",
			rect_position, apos.hidden,
			duration,
			Tween.TRANS_LINEAR, Tween.EASE_IN_OUT
		)
		emit_signal("term_hidden")
		tween_node.start()


func _SlideIn(instant : bool = false) -> void:
	if Engine.editor_hint or not tween_node:
		instant = true
	if tween_node:
		tween_node.stop_all()
	var apos = _GetAnimPositions()
	if instant:
		rect_position = apos.visible
		visible = true
	elif not Engine.editor_hint:
		__animating = 1
		visible = true
		var cdistance = rect_position.distance_to(apos.visible)
		var duration = __animation_duration * (cdistance / apos.distance)
		tween_node.interpolate_property(
			self, "rect_position",
			rect_position, apos.visible,
			duration,
			Tween.TRANS_LINEAR, Tween.EASE_IN_OUT
		)
		emit_signal("term_visible")
		tween_node.start()


# -------------------------------------------------------------------------
# Public Methods
# -------------------------------------------------------------------------
func toggle() -> void:
	if visible:
		_SlideOut(not __animation_slide_out)
	else:
		_SlideIn(not __animation_slide_out)


# -------------------------------------------------------------------------
# Handler Methods
# -------------------------------------------------------------------------
func _on_resized() -> void:
	_UpdateScale()


func _on_tween_complete() -> void:
	if __animating == 0:
		visible = false

