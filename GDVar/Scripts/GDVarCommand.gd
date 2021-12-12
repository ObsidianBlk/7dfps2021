extends Resource
class_name GDVarCommand

# -----------------------------------------------------------------------------
# DEFINING A COMMAND...
# Command Definitions are Dictionary objects with the following properties...
#
# "name" [String] -			The name of the command.
# "description" [String] -	(OPTIONAL) A description of what the command does.
# "owner" [Node] -			The Node object from which the command is called from.
# "method" [String] -		The name of the method/function from the <owner> that is called.
# "args" [Array] -			(OPTIONAL) An array of argument definition dictionaries (described below).
# "return_type" [Integer] -	(OPTIONAL) A TYPE_* value identifying what the function is supposed to return.
#							Default value is TYPE_NIL
#
# EXAMPLE Command definition dictionary without Arguments:
# {
#   "name":			"example",
#   "description":	"This command does something exciting!"
#   "owner":		self 									# Assuming <self> is a Node-based object.
#   "method":		"_CMD_Example"
#   "return_type":	TYPE_INT
# }
# -----------------------------------------------------------------------------
#
# -----------------------------------------------------------------------------
# DEFINING COMMAND ARGUMENTS
# For commands that require arguments, an array of argument definitions need to be passed to the
# "args" property of the Command Definition Dictionary.
#
# Argument Definition Dictionaries have the following properties...
#
# "name" [String] -			The name of the argument.
# "type" [Integer] -		The TYPE_* value identifying the value type expected.
# "description" [String] -	(OPTIONAL) A description of the argument and/or it's intent.
# "default" [Variant] -		(OPTIONAL) The default value for the argument if no value is given.
#								NOTE: The value must be of the same TYPE_* as defined by the "type" property.
#
# The order the arguments are defined in the array is the order they are passed to the command
# when the command is executed. As such, all argument definitions that contain the
# <default> property *must* be defined at the end of the array.
#
# Example (Bad):
# [
#   {"name":"Arg1", "type":TYPE_INT, "default":5},
#   {"name":"Arg2", "type":TYPE_INT}
# ] # This is NOT valid and will cause the command definition to fail. Defaults *must* come last.
#
# Example (Good):
# [
#   {"name":"Arg1", "type":TYPE_INT},
#   {"name":"Arg2", "type":TYPE_INT, "default":5}
# ] # This is perfectly valid, as the default argument is the last in the list.
#
# FINAL NOTE:
# The name given to an argument *does not* need to match the argument name in the actual function
# being called. However, it is a good idea to do so anyway, so as not to get confused during development.
#
# -----------------------------------------------------------------------------



# -----------------------------------------------------------------------------
# Signals
# -----------------------------------------------------------------------------
signal invalidated(cmd)

# -----------------------------------------------------------------------------
# Variables
# -----------------------------------------------------------------------------
var __name : String = ""
var __description : String = ""
var __return_type : int = TYPE_NIL
var __owner : Node = null
var __method : String = ""
var __argdef = null

var _errors = []

# -----------------------------------------------------------------------------
# Override Methods
# -----------------------------------------------------------------------------
func _init(cmd_def : Dictionary) -> void:
	var res = _VerifyCmdDictionary(cmd_def)
	if res != "":
		print(res)
		__name = ""
		__owner = null
		__method = ""

func _get(property : String):
	match property:
		"name":
			return __name
		"return_type":
			return __return_type
	return null

func _get_property_list():
	var properties = []
	if is_valid():
		properties.append({
			name = "name",
			type = TYPE_STRING,
			usage = PROPERTY_USAGE_DEFAULT
		})
		properties.append({
			name = "return_type",
			type = TYPE_INT,
			usage = PROPERTY_USAGE_DEFAULT
		})
	return properties

# -----------------------------------------------------------------------------
# Private Methods
# -----------------------------------------------------------------------------
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


func _VerifyCmdDictionary(cmd_def : Dictionary) -> String:
	if not ("name" in cmd_def):
		return "ERROR: Missing 'name' property."
	if typeof(cmd_def.name) != TYPE_STRING:
		return "ERROR: Property 'name' expected to be a string type."
	if not ("owner" in cmd_def):
		return "ERROR: Missing 'owner' property."
	if typeof(cmd_def.owner) != TYPE_OBJECT:
		return "ERROR: Property 'owner' expected to be an Object type."
	if not ("method" in cmd_def):
		return "ERROR: Missing 'method' property."
	if typeof(cmd_def.method) != TYPE_STRING:
		return "ERROR: property 'method' expected to be a string type."
	if not cmd_def.owner.has_method(cmd_def.method):
		return "ERROR: Owner object does not have method '" + cmd_def.method + "'."
	if "return_type" in cmd_def:
		if typeof(cmd_def.return_type) != TYPE_INT:
			return "ERROR: Property 'return_type' expected to be an integer type."
		if cmd_def.return_type < 0: # I should, really, test against ALL types...
			return "ERROR: Property 'return_type' contains invalid value."
		__return_type = cmd_def.return_type
	if "args" in cmd_def:
		if typeof(cmd_def.args) != TYPE_ARRAY:
			return "ERROR: Arguments expected to be in an Array."
		var res = _VerifyCmdArg(cmd_def.args)
		if res != "":
			return res
		__argdef = cmd_def.args
	if "description" in cmd_def:
		if typeof(cmd_def.description) != TYPE_STRING:
			return "ERROR: Property 'description' expected to be a string type."
		__description = cmd_def.description
	__name = cmd_def.name
	__owner = cmd_def.owner
	__method = cmd_def.method
	return ""


func _VerifyCmdArg(arg_def : Array) -> String:
	var expect_default = false
	for arg in arg_def:
		if typeof(arg) != TYPE_DICTIONARY:
			return "ERROR: Argument definition expected to be a Dictionary."
		if not ("name" in arg and typeof(arg.name) == TYPE_STRING):
			return "ERROR: Command argument definition 'name' property missing or invalid value type."
		if not ("type" in arg and typeof(arg.type) == TYPE_INT):
			return "ERROR: Command argument definition 'type' property missing or invalid value type."
		if "description" in arg:
			if typeof(arg.description) != TYPE_STRING:
				return "ERROR: Command argument 'description' property expected to be a string type."
		if "default" in arg:
			expect_default = true
			if typeof(arg.default) != arg.type:
				return "ERROR: Command argument '%s' definition 'default' property value type does not match defined type value for argument."%[arg.name]
		elif expect_default:
			return "ERROR: Arguments without default values must be defined before arguments with default values."
	return ""

func _FixForNumbers(type, arg):
	var atype = typeof(arg)
	if type == TYPE_INT and atype == TYPE_REAL:
		return int(arg)
	if type == TYPE_REAL and atype == TYPE_INT:
		return float(arg)
	return arg
	

func _ValidateArgList(given_args : Array) -> Array:
	var args = []
	if __argdef == null:
		if given_args.size() > 0:
			_errors.append("Unexpected number of arguments given.")
	else:
		if given_args.size() > __argdef.size():
			_errors.append("Unexpected number of arguments given.")
			return []
		for i in range(__argdef.size()):
			var adef = __argdef[i]
			if i < given_args.size():
				var arg = _FixForNumbers(adef.type, given_args[i])
				if typeof(arg) != adef.type:
					_errors.append("Argument '%s' invalid type."%[adef.name])
					return []
				args.append(arg)
			elif "default" in adef:
				args.append(adef.default)
			else:
				_errors.append("Missing expected value for argument '%s'."%[adef.name])
				return []
	return args

func _ArgumentListToString() -> String:
	var argstr = ""
	if __argdef != null:
		for i in range(__argdef.size()):
			var arg = __argdef[i]
			var format = "{name} : {type}" + (", " if i < __argdef.size() - 1 else "")
			if "default" in arg:
				format = "[ {name} : {type}, ]" if i < __argdef.size() -1 else "[{name} : {type}]"
			argstr += format.format({"name":arg.name, "type":_TypeToName(arg.type)})
	return argstr

func _ArgumentDescriptions() -> String:
	var argstr = ""
	if __argdef != null:
		for arg in __argdef:
			var desc = "description" in arg
			var default = "default" in arg
			var def = "%s [ %s ]"%[arg.name, _TypeToName(arg.type)]
			if desc or default:
				def += ":    "
				if default:
					def += "(OPTIONAL) "
				if desc:
					def += arg.description
			argstr += def + "\n"
	return argstr


# -----------------------------------------------------------------------------
# Public Methods
# -----------------------------------------------------------------------------
func is_valid() -> bool:
	if __owner != null:
		if not is_instance_valid(__owner):
			__owner = null
			emit_signal("invalidated", self)
	return __name != "" and __owner != null and __method != ""

func name() -> String:
	return __name

func owner_name() -> String:
	if is_valid():
		return __owner.name
	return ""

func arg_count(required_only : bool = false) -> int:
	var count = 0
	if __argdef != null:
		if required_only:
			for arg in __argdef:
				if not "default" in arg:
					count += 1
		else:
			count = __argdef.size()
	return count

func error_count() -> int:
	return _errors.size()

func get_error(idx : int) -> String:
	if idx >= 0 and idx < _errors.size():
		return _errors[idx]
	return ""

func get_description(full_description : bool = false) -> String:
	if not is_valid():
		return ""
	var cmd = "{name} ( {args} ) -> {return_type}".format({
		"name":__name,
		"args":_ArgumentListToString(),
		"return_type":_TypeToName(__return_type)
	})
	if full_description:
		cmd = "{description}\n{cmd}\n{arguments}\n\n".format({
			"description":__description,
			"cmd":cmd,
			"arguments":_ArgumentDescriptions()
		})
	return cmd

func execute(args : Array = []):
	_errors.clear()
	if not is_valid():
		return null
	args = _ValidateArgList(args)
	if _errors.size() <= 0:
		return __owner.callv(__method, args)
	return null


