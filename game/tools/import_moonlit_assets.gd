extends SceneTree
const NAMES = ["ninja_support", "samurai_support", "dojo_backdrops", "dojo_props", "combat_fx", "dojo_icons"]
func _initialize() -> void:
	for asset in NAMES:
		var metadata = JSON.parse_string(FileAccess.get_file_as_string("res://../art_sources/moonlit_dojo/%s.json" % asset))
		var frames := SpriteFrames.new()
		frames.remove_animation(&"default")
		var texture = load("res://assets/sprites/moonlit_dojo/%s_sheet.png" % asset)
		for tag in metadata.meta.frameTags:
			frames.add_animation(tag.name)
			frames.set_animation_speed(tag.name, 10)
			frames.set_animation_loop(tag.name, tag.name in ["idle", "lantern"])
			for i in range(int(tag.from), int(tag.to) + 1):
				var data = metadata.frames[i]
				var atlas := AtlasTexture.new()
				atlas.atlas = texture
				atlas.region = Rect2(data.frame.x, data.frame.y, data.frame.w, data.frame.h)
				atlas.filter_clip = true
				frames.add_frame(tag.name, atlas, data.duration / 100.0)
		assert(ResourceSaver.save(frames, "res://assets/frames/moonlit_dojo/%s_frames.tres" % asset) == OK)
	print("PASS imported six metadata-driven SpriteFrames resources")
	quit()
