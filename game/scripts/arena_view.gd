extends Node2D
const Backdrops = preload("res://assets/frames/moonlit_dojo/dojo_backdrops_frames.tres")
const Props = preload("res://assets/frames/moonlit_dojo/dojo_props_frames.tres")
const Playback = preload("res://scripts/frame_playback.gd")
func present(spec: EncounterSpec, clock: float) -> void:
	Playback.show_frame($Environment, Backdrops, spec.backdrop_tag, 0)
	Playback.show_frame($Props/Left, Props, &"lantern", clock)
	Playback.show_frame($Props/Right, Props, &"lantern", clock)
	Playback.show_frame($Props/Banner, Props, spec.banner_tag, 0)
