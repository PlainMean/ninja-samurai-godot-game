extends RefCounted
const NAMES = ["ninja_support","samurai_support","dojo_backdrops","dojo_props","combat_fx","dojo_icons"]
const Playback = preload("res://scripts/frame_playback.gd")
func run(t) -> void:
	var total := 0
	var resident := 0
	for name in NAMES:
		var meta = JSON.parse_string(FileAccess.get_file_as_string("res://../art_sources/moonlit_dojo/%s.json" % name))
		var frames: SpriteFrames = load("res://assets/frames/moonlit_dojo/%s_frames.tres" % name)
		var texture: Texture2D = load("res://assets/sprites/moonlit_dojo/%s_sheet.png" % name)
		var source := Image.new()
		source.load_png_from_buffer(FileAccess.get_file_as_bytes("res://assets/sprites/moonlit_dojo/%s_sheet.png" % name))
		t.check(source.get_data() == texture.get_image().get_data(), name + " imported RGBA equality")
		resident += source.get_data_size()
		t.check(frames.get_animation_names().size() == meta.meta.frameTags.size(), name + " exact tags")
		for tag in meta.meta.frameTags:
			t.check(frames.get_animation_speed(tag.name) == 10 and frames.get_animation_loop(tag.name) == (tag.name in ["idle","lantern"]), name + " playback policy")
			var seconds := 0.0
			for i in range(int(tag.from),int(tag.to)+1):
				var local_index: int = i - int(tag.from)
				var atlas: AtlasTexture = frames.get_frame_texture(tag.name,local_index)
				var r = meta.frames[i].frame
				t.check(atlas.region == Rect2(r.x,r.y,r.w,r.h) and atlas.filter_clip, name + " atlas clipping")
				t.check(roundi(frames.get_frame_duration(tag.name,local_index) * 100.0) == int(meta.frames[i].duration), name + " duration mapping")
				t.check(Playback.index(frames,tag.name,seconds) == local_index, name + " exact stopped frame boundary")
				seconds += meta.frames[i].duration / 1000.0
				total += 1
		var config := ConfigFile.new()
		config.load("res://assets/sprites/moonlit_dojo/%s_sheet.png.import" % name)
		for pair in [["compress/mode",0],["mipmaps/generate",false],["process/fix_alpha_border",false],["process/premult_alpha",false],["process/size_limit",0]]:
			t.check(config.get_value("params",pair[0]) == pair[1],name + " lossless import " + pair[0])
	t.check(total == 51 and resident + 2*192*32*4 <= 1048576, "51 frames and resident atlas budget")
