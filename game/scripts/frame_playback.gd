extends RefCounted
static func index(frames: SpriteFrames, tag: StringName, seconds: float) -> int:
	var total := 0.0
	for i in range(frames.get_frame_count(tag)):
		total += roundf(frames.get_frame_duration(tag, i) * 1000.0 / frames.get_animation_speed(tag)) / 1000.0
	var time := maxf(0, seconds)
	if frames.get_animation_loop(tag): time = fmod(time, total)
	for i in range(frames.get_frame_count(tag)):
		time -= roundf(frames.get_frame_duration(tag, i) * 1000.0 / frames.get_animation_speed(tag)) / 1000.0
		if time < -0.000000001: return i
	return frames.get_frame_count(tag) - 1
static func show_frame(sprite: AnimatedSprite2D, frames: SpriteFrames, tag: StringName, seconds: float) -> void:
	if sprite.sprite_frames != frames: sprite.sprite_frames = frames
	if sprite.animation != tag: sprite.animation = tag
	sprite.stop()
	sprite.frame = index(frames, tag, seconds)
