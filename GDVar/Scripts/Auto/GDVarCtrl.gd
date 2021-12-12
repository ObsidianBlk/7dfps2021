extends Node

# -----------------------------------------------------------------------------
# Signals
# -----------------------------------------------------------------------------
signal message(type, msg)
signal watch(gdvar)
signal unwatch(gdvar)


# -----------------------------------------------------------------------------
# Contants and ENUMs
# -----------------------------------------------------------------------------

const LEXER = preload("res://GDVar/Scripts/Lexer.gd")
const PARSER = preload("res://GDVar/Scripts/Parser.gd")

const ALLOWED_TYPES = [
	TYPE_BOOL,
	TYPE_COLOR,
	TYPE_INT,
	TYPE_REAL,
	TYPE_STRING,
	TYPE_VECTOR2,
	TYPE_VECTOR3,
	TYPE_RECT2
]

enum LOG_TYPE {
	INFO,
	DEBUG,
	WARNING,
	ERROR
}


# -----------------------------------------------------------------------------
# Variables
# -----------------------------------------------------------------------------
var __Commands : Dictionary = {}
var __Variables : Dictionary = {}

var __interpreter_error : bool = false
var __ierrors : Array = []


# -----------------------------------------------------------------------------
# Override Methods
# -----------------------------------------------------------------------------
func _ready() -> void:
#	define_command({
#		"name":"watch",
#		"description":"Add or remove variable to or from the watch tab.",
#		"owner":self,
#		"method":"_CMDWatch",
#		"args":[
#			{"name":"name", "type":TYPE_STRING},
#			{"name":"watch", "type":TYPE_BOOL, "default":true}
#		]
#	})
#
#	define_command({
#		"name":"variables",
#		"description":"List the available variables.",
#		"owner":self,
#		"method":"_CMDVariableList",
#		"args":[
#			{"name": "owner", "type":TYPE_STRING, "default":""}
#		]
#	})
	
	define_command({
		"name":"commands",
		"description":"List the available commands.",
		"owner":self,
		"method":"_CMDCommandList",
		"args":[
			{"name":"full", "type":TYPE_BOOL, "default":false}
		]
	})


# -----------------------------------------------------------------------------
# Special Command Methods
# -----------------------------------------------------------------------------
func _CMDWatch(vname : String, watch : bool = true) -> void:
	if vname in __Variables:
		if watch:
			emit_signal("watch", __Variables[vname])
		else:
			emit_signal("unwatch", __Variables[vname])
	else:
		error("No variable named \"%s\". Nothing to watch."%[vname])


func _CMDVariableList(owner_name : String = "") -> void:
	_CleanInvalidVariables()
	var keylist = __Variables.keys()
	info("--------------------------------")
	if owner_name != "":
		info("Variables ownen by '%s':"%[owner_name])
	var listed : int = 0
	for key in keylist:
		if __Variables[key].is_valid() and (owner_name == "" or __Variables[key].owner_name() == owner_name):
			info("%s%s [ %s ]"%["" if owner_name == "" else "  ", key, _TypeToName(__Variables[key].type)])
			listed += 1
	if listed <= 0:
		if owner_name != "":
			info("There are no variabled owned by '%s'."%[owner_name])
		else:
			info("There are no variables available.")
	info("--------------------------------")

func _CMDCommandList(full : bool = false) -> void:
	_CleanInvalidCommands()
	info("--------------------------------")
	for key in __Commands.keys():
		info(__Commands[key].get_description(full))
	info("--------------------------------")

# -----------------------------------------------------------------------------
# Private Methods
# -----------------------------------------------------------------------------
func _StoreInterpError(msg) -> void:
	__ierrors.append(msg)
	__interpreter_error = true

func _TypeToName(type : int) -> String:
	match type:
		TYPE_ARRAY:
			return "Array"
		TYPE_BOOL:
			return "Bool"
		TYPE_COLOR:
			return "Color"
		TYPE_INT:
			return "Integer"
		TYPE_REAL:
			return "Float"
		TYPE_NIL:
			return "Void"
		TYPE_RECT2:
			return "Rect2"
		TYPE_STRING:
			return "String"
		TYPE_VECTOR2:
			return "Vector2"
		TYPE_VECTOR3:
			return "Vector3"
	return ""

func _ValidLogType(t : int) -> bool:
	for key in LOG_TYPE.keys():
		if LOG_TYPE[key] == t:
			return true
	return false

func _CleanInvalidVariables() -> void:
	for key in __Variables.keys():
		if not __Variables[key].is_valid():
			__Variables.erase(key)

func _CleanInvalidCommands() -> void:
	for key in __Commands.keys():
		if not __Commands[key].is_valid():
			__Commands.erase(key)

func _HandleVariable(ast : Dictionary):
	if ast.value == "true":
		return true
	if ast.value == "false":
		return false
	if ast.value.left(1) == "#":
		if ast.value.size() != 4 and ast.value.size() != 7:
			_StoreInterpError("Is this supposed to be a color or a variable? I think you're confused.")
			return null
		var col = ast.value.substr(1)
		if not col.is_valid_hex_number():
			_StoreInterpError("That value, friend... that's totally NOT a color value.")
			return null
		return Color(ast.value)
	
	if ast.value in __Variables:
		if __Variables[ast.value].is_valid():
			return __Variables[ast.value]
	
	# Ok... it's not a variable... let's just check if this is an argument-less (or optional arg only)
	# command.
	if ast.value in __Commands and __Commands[ast.value].is_valid():
		if __Commands[ast.value].arg_count(true) == 0:
			var res = __Commands[ast.value].execute()
			if __Commands[ast.value].error_count() > 0:
				for i in range(__Commands[ast.value].error_count()):
					_StoreInterpError(__Commands[ast.value].get_error(i))
					return null
			return res
	
	_StoreInterpError("Unable to find variable named '" + ast.value + "'.")
	return null

func _HandleVECREC(ast : Dictionary):
	var vals = []
	for v in ast.value:
		var val = _HandleAST(v)
		if __interpreter_error: return null
		if typeof(val) != TYPE_INT and typeof(val) != TYPE_REAL:
			_StoreInterpError("Expected an int or float value.")
			return null
		vals.append(val)
	if vals.size() == 2:
		return Vector2(vals[0], vals[1])
	if vals.size() == 3:
		return Vector3(vals[0], vals[1], vals[2])
	if vals.size() == 4:
		return Rect2(vals[0], vals[1], vals[2], vals[3])
	_StoreInterpError("I honestly have no idea what went wrong here, but this is not a Vector or a Rect.")
	return null


func _HandleAssignment(ast : Dictionary) -> void:
	var left = _HandleAST(ast.left)
	if __interpreter_error: return
	if not (left is GDVar):
		_StoreInterpError("I... I can't assign to whatever it is you have on the left hand side.")
		return
	var right = _HandleAST(ast.right)
	if __interpreter_error: return
	var rtype = typeof(right)
	if (rtype == TYPE_INT or rtype == TYPE_REAL or rtype == TYPE_BOOL) and (left.type == TYPE_INT or left.type == TYPE_REAL):
		if left.type == TYPE_INT:
			if rtype == TYPE_BOOL:
				left.value = 1 if right == true else 0
			else:
				left.value = int(right)
		else:
			if rtype == TYPE_BOOL:
				left.value = 1.0 if right == true else 0.0
			else:
				left.value = float(right)
		return
	if rtype != left.type:
		_StoreInterpError("That variable does not take that kind of value.")
		return
	left.value = right


func _HandleBinAdd(left, right):
	match typeof(left):
		TYPE_INT:
			match typeof(right):
				TYPE_INT:
					return left + right
				TYPE_REAL:
					return left + int(right)
				TYPE_STRING:
					if right.is_valid_integer():
						return left + right.to_integer()
					_StoreInterpError("Adding a string! HA! Nice! ... No, though.")
				_:
					_StoreInterpError("How am I supposed to add these values? This doesn't make sense!")
		TYPE_REAL:
			match typeof(right):
				TYPE_INT:
					return left + float(right)
				TYPE_REAL:
					return left + right
				TYPE_STRING:
					if right.is_valid_float():
						return left + right.to_float()
					_StoreInterpError("Strings and numbers aren't exactly in the math book you know...")
				_:
					_StoreInterpError("You can't exactly add these values together I'm afraid.")
		TYPE_STRING:
			if typeof(right) == TYPE_COLOR:
				return left + right.to_html(true)
			return left + String(right)
		TYPE_VECTOR2:
			if typeof(right) == TYPE_VECTOR2:
				return left + right
			_StoreInterpError("Vectors don't add up like that. Sorry.")
		TYPE_VECTOR3:
			if typeof(right) == TYPE_VECTOR3:
				return left + right
			_StoreInterpError("Can't quite add the vector like that.")
		TYPE_COLOR:
			match typeof(right):
				TYPE_INT:
					if right < 0:
						return left.darkened(float(right)/255.0)
					else:
						return left.lightened(float(right)/255.0)
				TYPE_REAL:
					if right < 0:
						return left.darkened(right)
					else:
						return left.lightened(right)
				_:
					_StoreInterpError("How am I supposed to mix THAT into the color?")
		_:
			_StoreInterpError("Love your enthusiasm, but I can't add those together.")
	return null


func _HandleBinSub(left, right):
	match typeof(left):
		TYPE_INT:
			match typeof(right):
				TYPE_INT:
					return left - right
				TYPE_REAL:
					return left - int(right)
				TYPE_STRING:
					if right.is_valid_integer():
						return left - right.to_integer()
					_StoreInterpError("Not exactly sure how to remove the string from that number.")
				_:
					_StoreInterpError("Physics in your universe must be really cool to allow subtractions like that!")
		TYPE_REAL:
			match typeof(right):
				TYPE_INT:
					return left - float(right)
				TYPE_REAL:
					return left - right
				TYPE_STRING:
					if right.is_valid_float():
						return left - right.to_float()
					_StoreInterpError("You want me to subtract by the number of characters in the string? Or... ?")
				_:
					_StoreInterpError("Those don't... I can't see how... I'm out.")
		TYPE_VECTOR2:
			if typeof(right) == TYPE_VECTOR2:
				return left - right
			_StoreInterpError("Ooof... You can't do that to vectors! Just not right!")
		TYPE_VECTOR3:
			if typeof(right) == TYPE_VECTOR3:
				return left - right
			_StoreInterpError("Even in 3D space, that's illegal for vectors, I'm afraid.")
		TYPE_COLOR:
			match typeof(right):
				TYPE_INT:
					if right < 0:
						return left.lightened(float(right)/255.0)
					else:
						return left.darkened(float(right)/255.0)
				TYPE_REAL:
					if right < 0:
						return left.lightened(right)
					else:
						return left.darkened(right)
				_:
					_StoreInterpError("Subtracting that would create the color out of space and... well... that just does not end well!")
		_:
			_StoreInterpError("You really thought those values could be subtracted from one another?")
	return null


func _HandleBinDiv(left, right):
	match typeof(left):
		TYPE_INT:
			match typeof(right):
				TYPE_INT:
					if right != 0:
						return left / right
					_StoreInterpError("You do realize that dividing by 0 isn't possible, right?")
				TYPE_REAL:
					if right != 0.0:
						return left / int(right)
					_StoreInterpError("There is a zero on the right which I just cannot work with.")
				_:
					_StoreInterpError("Not sure how to divide that right value into that integer.")
		TYPE_REAL:
			match typeof(right):
				TYPE_INT:
					if right != 0:
						return left / float(right)
					_StoreInterpError("How many times DOES zero go into a number? I think... never!")
				TYPE_REAL:
					if right != 0.0:
						return left / right
					_StoreInterpError("Divide by zero? Really? You know I can't do that.")
				_:
					_StoreInterpError("Dividing these two values is against the laws of reality and I just cannot.")
		TYPE_VECTOR2:
			match typeof(right):
				TYPE_VECTOR2:
					if right.length() != 0:
						return left / right
					_StoreInterpError("Sure let me just divide by a ZERO length vector! I'd roll my eyes if I had any.")
				TYPE_INT, TYPE_REAL:
					if right != 0:
						return left / float(right)
					_StoreInterpError("No dividing by zero! No! NO! You just CAN'T DO IT!")
			_StoreInterpError("I can't divide a vector by a value like that.")
		TYPE_VECTOR3:
			match typeof(right):
				TYPE_VECTOR3:
					if right.length() != 0:
						return left / right
					_StoreInterpError("Yes, you're dividing by a vector, but it is still a zero length vector, so... no.")
				TYPE_INT, TYPE_REAL:
					if right != 0:
						return left / float(right)
					_StoreInterpError("Just because you're dividing a scalar into a vector does not mean you can divide by zero.")
			_StoreInterpError("The cartesian coordinant system strictly forbids that from being divided into such a vector.")
		_:
			_StoreInterpError("Can you divide those two value types? I have no idea how.")
	return null


func _HandleBinMult(left, right):
	match typeof(left):
		TYPE_INT:
			match typeof(right):
				TYPE_INT:
					return left * right
				TYPE_REAL:
					return left * int(right)
				_:
					_StoreInterpError("Can't multiply that right hand value into an integer.")
		TYPE_REAL:
			match typeof(right):
				TYPE_INT:
					return left * float(right)
				TYPE_REAL:
					return left * right
				_:
					_StoreInterpError("How many times does that right hand value go into a number? Is it even possible?")
		TYPE_VECTOR2:
			match typeof(right):
				TYPE_VECTOR2:
					return left * right
				TYPE_INT, TYPE_REAL:
					return left * float(right)
				_:
					_StoreInterpError("There is just no way I can multiply a vector by whatever value type that is.")
		TYPE_VECTOR3:
			match typeof(right):
				TYPE_VECTOR3:
					return left * right
				TYPE_INT, TYPE_REAL:
					return left * float(right)
				_:
					_StoreInterpError("Multiplying a vector by that value type is like mixing oil and water. Not even gonna bother.")
		_:
			_StoreInterpError("I get that these values are legit, but, that doesn't mean they can be multiplied together!")
	return null


func _HandleBinary(ast : Dictionary):
	var left = _HandleAST(ast.left)
	if __interpreter_error : return null
	if left is GDVar:
		left = left.value
	if ALLOWED_TYPES.find(typeof(left)) < 0:
		_StoreInterpError("Left hand value is not something I can work with here.")
		return null
	var right = _HandleAST(ast.right)
	if __interpreter_error : return null
	if right is GDVar:
		right = right.value
	if ALLOWED_TYPES.find(typeof(right)) < 0:
		_StoreInterpError("Right hand value is not something I can work with here.")
		return null
	match ast.op:
		"+":
			return _HandleBinAdd(left, right)
		"-":
			return _HandleBinSub(left, right)
		"/":
			return _HandleBinDiv(left, right)
		"*":
			return _HandleBinMult(left, right)
	return null

func _HandleCommand(ast : Dictionary):
	if ast.cmd in __Commands and __Commands[ast.cmd].is_valid():
		var args = []
		for arg in ast.args:
			var val = _HandleAST(arg)
			if __interpreter_error: return null
			if val is GDVar:
				val = val.value
			args.append(val)
		var res = __Commands[ast.cmd].execute(args)
		if __Commands[ast.cmd].error_count() > 0:
			for i in range(__Commands[ast.cmd].error_count()):
				_StoreInterpError(__Commands[ast.cmd].get_error(i))
				return null
		return res
	else:
		_StoreInterpError("I am unaware of the command '%s'."%[ast.cmd])

func _HandleAST(ast : Dictionary):
	match ast.type:
		PARSER.NODE_TYPE.VECREC:
			return _HandleVECREC(ast)
		PARSER.NODE_TYPE.STRING:
			return ast.value
		PARSER.NODE_TYPE.NUMBER:
			return ast.value.to_float()
		PARSER.NODE_TYPE.VARIABLE:
			return _HandleVariable(ast)
		PARSER.NODE_TYPE.BINARY:
			return _HandleBinary(ast)
		PARSER.NODE_TYPE.ASSIGNMENT:
			_HandleAssignment(ast)
		PARSER.NODE_TYPE.COMMAND:
			_HandleCommand(ast)
		_:
			_StoreInterpError("I have no idea how to interpret that... so I won't bother!")
	return null

# -----------------------------------------------------------------------------
# Public Methods
# -----------------------------------------------------------------------------

func log(type : int, msg : String, args : Dictionary = {}) -> void:
	if not _ValidLogType(type):
		return
	emit_signal("message", type, msg.format(args))

func info(msg : String, args : Dictionary = {}) -> void:
	self.log(LOG_TYPE.INFO, msg, args)

func debug(msg : String, args : Dictionary = {}) -> void:
	self.log(LOG_TYPE.DEBUG, msg, args)

func warning(msg : String, args : Dictionary = {}) -> void:
	self.log(LOG_TYPE.WARNING, msg, args)

func error(msg : String, args : Dictionary = {}) -> void:
	self.log(LOG_TYPE.ERROR, msg, args)

func define_command(cmd_def : Dictionary) -> bool:
	var cmd = GDVarCommand.new(cmd_def)
	return add_command(cmd)

func add_command(cmd : GDVarCommand) -> bool:
	if cmd.is_valid() and not cmd.name() in __Commands:
		__Commands[cmd.name()] = cmd
		cmd.connect("invalidated", self, "_invalidated_command")
		return true
	return false

func call_command(cmd_name : String, args : Array = []):
	if cmd_name in __Commands:
		return __Commands[cmd_name].execute(args)
	return null

func define_variable(owner : Node, name : String, value, callback : String = ""):
	if not name in __Variables:
		var gdv :GDVar = GDVar.new(owner, name, value)
		if add_variable(gdv):
			if callback != "":
				gdv.connect("value_changed", owner, callback)
			return gdv
	return null

func add_variable(gdvar : GDVar) -> bool:
	if gdvar.is_valid() and not gdvar.name() in __Variables:
		gdvar.connect("invalidated", self, "_invalidated_gdvar")
		gdvar.connect("watch", self, "watch_variable")
		__Variables[gdvar.name()] = gdvar
		return true
	return false

func watch_variable(name : String, watch : bool = true) -> void:
	if name in __Variables and __Variables[name].is_valid():
		if watch:
			emit_signal("watch", __Variables[name])
		else:
			emit_signal("unwatch", __Variables[name])

func variable_list() -> Array:
	return __Variables.keys()

func interpret(line : String) -> void:
	__ierrors.clear()
	__interpreter_error = false
	var lexer = LEXER.new()
	if lexer.tokenize(line):
		var parser = PARSER.new()
		if parser.parse(lexer):
			var ast = parser.get_ast()
			if ast == null:
				info("That... meant nothing to me...")
			else:
				var res = _HandleAST(ast)
				if __interpreter_error:
					for err in __ierrors:
						error(err)
				elif res != null:
					if res is GDVar:
						res = res.value
					if typeof(res) == TYPE_STRING:
						info(res)
					else:
						info(String(res))
		else:
			for i in range(parser.error_count()):
				error("Failed to Interpret: " + parser.get_error(i))
	else:
		error("Failed to Interpret: " + lexer.get_error(0))

# -----------------------------------------------------------------------------
# Handler Methods
# -----------------------------------------------------------------------------

func _invalidated_gdvar(gdvar : GDVar) -> void:
	if gdvar.name() in __Variables:
		__Variables.erase(gdvar.name())

func _invalidated_command(cmd : GDVarCommand) -> void:
	if cmd.name() in __Commands:
		__Commands.erase(cmd.name())
