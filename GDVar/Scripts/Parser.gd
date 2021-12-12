extends Resource


# -----------------------------------------------------------------------------
# ENUMs and Contants
# -----------------------------------------------------------------------------
const LEXER = preload("res://GDVar/Scripts/Lexer.gd")
enum NODE_TYPE {
	VARIABLE,
	NUMBER,
	STRING,
	VECREC,
	ASSIGNMENT,
	BINARY,
	COMMAND
}

# -----------------------------------------------------------------------------
# Variables
# -----------------------------------------------------------------------------
var _lexer = null
var _errors = []
var _ast = null

# -----------------------------------------------------------------------------
# Override Methods
# -----------------------------------------------------------------------------


# -----------------------------------------------------------------------------
# Private Methods
# -----------------------------------------------------------------------------
func _Reset() -> void:
	if _lexer != null:
		_lexer.reset_cursor()
	_errors.clear()
	_ast = null

func _TokenIsEOL(tok : Dictionary) -> bool:
	return tok.type == LEXER.TOKEN_TYPE.EOL

func _NextIsEOL(consume_if_true : bool = false) -> bool:
	var tok = _lexer.peek()
	if tok.type == LEXER.TOKEN_TYPE.EOL:
		if consume_if_true:
			_lexer.consume()
		return true
	return false

func _TokenIsSymbol(tok : Dictionary, sym : String = "") -> bool:
	if tok.type == LEXER.TOKEN_TYPE.SYMBOL:
		return sym == "" or tok.sym == sym
	return false

func _NextIsSymbol(sym : String = "", consume_if_true : bool = false) -> bool:
	var tok = _lexer.peek()
	if _TokenIsSymbol(tok, sym):
		if consume_if_true:
			_lexer.consume()
		return true
	return false


func _ParseAtom():
	if _NextIsSymbol("(", true):
		var e = _ParseExpression()
		if not _NextIsSymbol(")", true):
			_errors.append("Missing symbol \")\".")
			return null
		return e
	elif _NextIsSymbol("["):
		var vals = _ParseDelimited("[", "]")
		if vals == null or vals.size() < 2 or vals.size() > 4:
			_errors.append("Vector or Rect have incorrect number of values.")
			return null
		return {"type":NODE_TYPE.VECREC, "value":vals}
	
	var tok = _lexer.consume()
	if tok.type == LEXER.TOKEN_TYPE.NUMBER:
		return {"type":NODE_TYPE.NUMBER, "value":tok.sym}
	if tok.type == LEXER.TOKEN_TYPE.STRING:
		return {"type":NODE_TYPE.STRING, "value":tok.sym}
	if tok.type == LEXER.TOKEN_TYPE.LABEL:
		return {"type":NODE_TYPE.VARIABLE, "value":tok.sym}

func _ParseDelimited(ssym : String, esym : String):
	var args = []
	if _NextIsSymbol(ssym, true):
		if _NextIsSymbol(esym, true):
			return args # Just in case its an empty list.
		var ast = _ParseExpression()
		while ast != null and _errors.size() <= 0:
			args.append(ast)
			ast = null
			if not _NextIsSymbol(",", true):
				if _NextIsSymbol(esym, true):
					return args
				_errors.append("Unexpected symbol in list.")
			else:
				ast = _ParseExpression()
		if _errors.size() <= 0:
			return args
	return null

func _BinaryAST(last : Dictionary, rast : Dictionary, op : String) -> Dictionary:
	return {
		"type": NODE_TYPE.BINARY,
		"op": op,
		"left": last,
		"right": rast
	}

func _AssignmentAST(last : Dictionary, rast : Dictionary) -> Dictionary:
	return {
		"type": NODE_TYPE.ASSIGNMENT,
		"left": last,
		"right": rast
	}

func _ParseMaybeBinary(last : Dictionary):
	var tok = _lexer.peek()
	if tok.type == LEXER.TOKEN_TYPE.OPERATOR:
		_lexer.consume()
		var rast = _ParseExpression()
		if _errors.size() > 0:
			return null
		
		if tok.sym.length() == 2:
			var op = tok.sym.left(1)
			return _AssignmentAST(last, _BinaryAST(last, rast, op))
		else:
			if tok.sym == "=":
				return _AssignmentAST(last, rast)
			return _BinaryAST(last, rast, tok.sym)
	return last

func _ParseMaybeCommand(ast : Dictionary):
	if ast.type == NODE_TYPE.VARIABLE:
		if _NextIsSymbol("("):
			var args = _ParseDelimited("(", ")")
			if args != null and _errors.size() <= 0:
				return {"type":NODE_TYPE.COMMAND, "cmd":ast.value, "args":args}
			return null
	return _ParseMaybeBinary(ast)

func _ParseExpression(expect_eol : bool = false):
	var ast = _ParseAtom()
	if ast != null and _errors.size() <= 0:
		ast = _ParseMaybeCommand(ast)
		if not (expect_eol and not _NextIsEOL()):
			return ast
		_errors.append("Expected end of line.")
	return null

# -----------------------------------------------------------------------------
# Public Methods
# -----------------------------------------------------------------------------
func is_valid() -> bool:
	return _errors.size() <= 0

func error_count() -> int:
	return _errors.size()

func get_error(idx : int) -> String:
	if idx >= 0 and idx < _errors.size():
		return _errors[idx]
	return ""

func get_ast():
	return _ast

func parse(lex = null) -> bool:
	if lex != null:
		if lex.is_valid():
			_lexer = lex
		else: return false
	if _lexer != null:
		_Reset()
		_ast = _ParseExpression(true)
		if _errors.size() <= 0:
			return true
	return false


