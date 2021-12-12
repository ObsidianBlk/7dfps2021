extends Resource


# -----------------------------------------------------------------------------
# ENUMs and Contants
# -----------------------------------------------------------------------------
enum TOKEN_TYPE {
	LABEL,
	STRING,
	NUMBER,
	SYMBOL,
	OPERATOR,
	EOL
}

# -----------------------------------------------------------------------------
# Variables
# -----------------------------------------------------------------------------
var _tokens = []
var _errors = []
var _cursor : int = 0

var _data = null

# -----------------------------------------------------------------------------
# Override Methods
# -----------------------------------------------------------------------------


# -----------------------------------------------------------------------------
# Private Methods
# -----------------------------------------------------------------------------
func _Reset() -> void:
	_tokens.clear()
	_errors.clear()
	_cursor = 0


func _IsSymbol(c : String) -> bool:
	if [",", "[", "]", "(", ")", "{", "}"].find(c) >= 0:
		return true
	return false

func _IsOperator(c : String) -> bool:
	if ["+", "-", "/", "*", "=", "+=", "-=", "/=", "*="].find(c) >= 0:
		return true
	return false

func _IsCharLetter(c : String) -> bool:
	var letters :String = "abcdefghijklmnopqrstuvwxyz"
	return letters.find(c) >= 0 or letters.to_upper().find(c) >= 0

func _IsCharNumber(c : String) -> bool:
	return "0123456789".find(c) >= 0

func _IsSymbolValidLabel(sym : String) -> bool:
	# NOTE: I could probably do this with a RegEx, but not sure it'll save THAT much time
	#  for such a relatively simple check.
	for i in range(sym.length()):
		var c = sym.substr(i, 1)
		if i == 0 and ("_$#".find(c) < 0 and not _IsCharLetter(c)):
			return false
		elif c != "_" and c != "$" and not _IsCharLetter(c) and not _IsCharNumber(c):
			return false
	return true

func _IsSymbolFullString(sym : String) -> bool:
	if sym.left(1) == "\"" and sym.length() >= 2:
		var r = sym.substr(sym.length() - 1)
		var _r = sym.substr(sym.length() - 2)
		return r == "\"" and _r != "\\\""
	return false

func _IsSymbolNumber(sym : String) -> bool:
	if _IsCharNumber(sym.left(1)):
		return sym.is_valid_integer() or sym.is_valid_float()
	return false

func _StoreNumOrLabel(sym : String) -> bool:
	if _IsSymbolNumber(sym):
		_StoreToken(TOKEN_TYPE.NUMBER, sym)
		return true
	elif _IsSymbolValidLabel(sym):
		_StoreToken(TOKEN_TYPE.LABEL, sym)
		return true
	_errors.append("Invalid symbol '" + sym + "'.")
	return false

func _StoreToken(type : int, sym : String = "") -> void:
	_tokens.append({"type":type, "sym":sym})

func _TokenizeLine(line : String) -> bool:
	var sym = ""
	var i : int = 0
	while i < line.length():
		var c : String = line.substr(i, 1)
		var sym_in_string = sym != "" and sym.left(1) == "\""
		
		if c == "\"" or sym_in_string:
			sym += c
			if _IsSymbolFullString(sym):
				_StoreToken(TOKEN_TYPE.STRING, sym.substr(1, sym.length()-2))
				sym = ""
		elif c == " ":
			if sym != "":
				if not _StoreNumOrLabel(sym):
					return false
				sym = ""
		elif _IsOperator(c):
			if sym != "":
				if not _StoreNumOrLabel(sym):
					return false
				sym = ""
			if i+1 < line.length():
				var c2 = line.substr(i+1, 1)
				if _IsOperator(c + c2):
					_StoreToken(TOKEN_TYPE.OPERATOR, c + c2)
					i += 1
				else:
					_StoreToken(TOKEN_TYPE.OPERATOR, c)
			else:
				_StoreToken(TOKEN_TYPE.OPERATOR, c)
		elif _IsSymbol(c):
			if sym != "":
				if not _StoreNumOrLabel(sym):
					return false
				sym = ""
			_StoreToken(TOKEN_TYPE.SYMBOL, c)
		else:
			sym += c
		
		i += 1
	
	if sym != "":
		if not _StoreNumOrLabel(sym):
			return false
		sym = ""
	_StoreToken(TOKEN_TYPE.EOL)
	return true

# -----------------------------------------------------------------------------
# Public Methods
# -----------------------------------------------------------------------------
func is_valid() -> bool:
	return _errors.size() <= 0

func error_count() -> int:
	return _errors.size()

func get_error(idx : int):
	if idx >= 0 and idx < _errors.size():
		return _errors[idx]
	return null

func tokenize(src : String) -> bool:
	_Reset()
	return _TokenizeLine(src)

func token_count() -> int:
	return _tokens.size()

func cursor_position() -> int:
	return _cursor

func peek() -> Dictionary:
	if _cursor < _tokens.size():
		return _tokens[_cursor]
	return {"type":TOKEN_TYPE.EOL, "sym":""}

func consume() -> Dictionary:
	if _cursor < _tokens.size():
		_cursor += 1
		return _tokens[_cursor - 1]
	return {"type":TOKEN_TYPE.EOL, "sym":""}

func seek(idx : int) -> Dictionary:
	if idx >= 0 and idx < _tokens.size():
		_cursor = idx
		return _tokens[_cursor]
	return {"type":TOKEN_TYPE.EOL, "sym":""}

func reset_cursor():
	_cursor = 0

