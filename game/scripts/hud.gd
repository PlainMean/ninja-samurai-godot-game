extends Control
const Icons = preload("res://assets/frames/moonlit_dojo/dojo_icons_frames.tres")
func ensure_seals(total: int) -> void:
	for i in range(total):
		var icon = get_node("Seal%d" % i) if has_node("Seal%d" % i) else $Seal0.duplicate()
		if icon.get_parent() == null:
			icon.name = "Seal%d" % i
			add_child(icon)
		icon.position.x = 91 + i * 27
		icon.size = Vector2(20,20)
func set_text(path: NodePath, value: String) -> void:
	var label = get_node(path)
	if label.text != value: label.text = value
func present(s: Dictionary) -> void:
	ensure_seals(s.total)
	set_text(^"Header/PlayerHealth", "You %d / %d" % [s.hp, s.max_hp])
	set_text(^"Header/EnemyHealth", "Enemy %d / %d" % [s.enemy_hp, s.enemy_max_hp])
	set_text(^"EnemyName", s.enemy_name)
	set_text(^"Progress", "Seals %d / %d · Level %d / %d" % [s.seals, s.total, s.encounter, s.total])
	set_text(^"Cue", s.cue)
	set_text(^"Feedback", s.feedback)
	set_text(^"Hint", s.technique)
	set_text(^"ElementInfo", "Enemy: %s · Weakness: %s\nTurn %d · Your affinity: %s" % [s.enemy_element, s.weakness, s.turn, s.affinity])
	$Heart.texture = Icons.get_frame_texture(&"heart_full" if s.hp > 0 else &"heart_empty", 0)
	for i in range(s.total): get_node("Seal%d" % i).texture = Icons.get_frame_texture(&"seal_full" if i < s.seals else &"seal_empty", 0)

	set_text(^"Intent", "Intent: %s · %d dmg if foe survives\n%s" % [Element.label(s.intent.element), s.intent.damage, s.intent.name])
	for i in range(4):
		var forecast: Dictionary = s.forecasts[i]
		var label: Label = $Actions.get_child(i).get_node("Forecast")
		label.text = "" if forecast.is_empty() else ("SEAL" if forecast.lethal else "%d dmg" % forecast.damage)
		label.modulate = Color("f6e3ad") if not forecast.is_empty() and forecast.matchup == Element.Matchup.EFFECTIVE else Color.WHITE
