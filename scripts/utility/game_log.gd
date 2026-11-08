class_name GameLog extends RefCounted
## Debug is opt-in (SUM_ZERO_DEBUG=1); warnings and errors are always visible.
## Never include player save contents or imported level codes in messages.


static func debug(context: String, message: String) -> void:
	if OS.get_environment("SUM_ZERO_DEBUG") == "1":
		print("[DEBUG][%s] %s" % [context, message])


static func warning(context: String, message: String) -> void:
	push_warning("[WARN][%s] %s" % [context, message])


static func error(context: String, message: String) -> void:
	push_error("[ERROR][%s] %s" % [context, message])
