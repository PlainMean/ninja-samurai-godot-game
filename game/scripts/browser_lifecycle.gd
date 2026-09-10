extends Node
signal pause_requested
var callback: JavaScriptObject
var window: JavaScriptObject

func _ready() -> void:
	if OS.has_feature("web"):
		window = JavaScriptBridge.get_interface("window")
		callback = JavaScriptBridge.create_callback(_browser_pause)
		window.duelPause = callback
		JavaScriptBridge.eval("window.duelCheckOrientation && window.duelCheckOrientation();")

func _browser_pause(_arguments: Array) -> void:
	pause_requested.emit()

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT or what == NOTIFICATION_APPLICATION_PAUSED:
		pause_requested.emit()

func _exit_tree() -> void:
	if OS.has_feature("web"):
		JavaScriptBridge.eval("window.duelPause = null;")
	callback = null
	window = null
