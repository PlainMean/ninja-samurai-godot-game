extends Control
const Icons = preload("res://assets/frames/moonlit_dojo/dojo_icons_frames.tres")
func set_text(path: NodePath, value: String) -> void:
	var label = get_node(path)
	if label.text != value: label.text = value
func present(s: Dictionary) -> void:
	set_text(^"Header/PlayerHealth", "You %d / %d" % [s.hp, s.max_hp])
	set_text(^"Header/EnemyHealth", "Enemy %d / %d" % [s.enemy_hp, s.enemy_max_hp])
	set_text(^"EnemyName", s.enemy_name)
	set_text(^"Progress", "Seals %d / 3 · %d / 3" % [s.seals, s.encounter])
	set_text(^"Cue", s.cue)
	set_text(^"Feedback", s.feedback)
	set_text(^"Hint", s.technique)
	$PhaseProgress.value = s.progress
	$CueIcon.texture = Icons.get_frame_texture(s.icon, 0)
	$Heart.texture = Icons.get_frame_texture(&"heart_full" if s.hp > 0 else &"heart_empty", 0)
	for i in range(3): get_node("Seal%d" % i).texture = Icons.get_frame_texture(&"seal_full" if i < s.seals else &"seal_empty", 0)
