extends RefCounted
static func metrics(available: Vector2) -> Dictionary:
	var compact := available.y / available.x < 2.0
	var logical_height := 780.0 if compact else 844.0
	return {"compact": compact, "height": logical_height, "scale": minf(available.x / 390.0, available.y / logical_height)}
static func apply(screen: Control, available: Vector2) -> void:
	var layout := metrics(available)
	var shift := 64.0 if layout.compact else 0.0
	screen.get_node("HUD/Actions").position.y = 656 - shift
	screen.get_node("HUD/Footer").position.y = 780 - shift
	screen.get_node("HUD/Hint").position.y = 596 - shift
	screen.get_node("HUD/Feedback").position.y = 524 - shift
	screen.get_node("Arena").position.y = -shift * 0.5
	screen.get_node("Modal/Panel").position.y = 482 - shift
