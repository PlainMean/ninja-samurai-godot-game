extends SceneTree
## Native Compatibility rendering evidence, not authored game artwork.
var screen
var checks := 0
func _initialize() -> void:
	call_deferred("run")
func capture(label: String) -> void:
	screen._refresh()
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	var picture := root.get_texture().get_image()
	assert(picture.get_size()==Vector2i(390,844))
	assert(picture.save_png("res://../qa/mobile/eight-seals/"+label+".png")==OK)
	checks += 1
func run() -> void:
	assert(DisplayServer.get_name()!="headless")
	root.size=Vector2i(390,844)
	screen=load("res://scenes/duel.tscn").instantiate()
	screen.area_campaign = false
	root.add_child(screen)
	screen.set_process(false)
	screen.clock=func(): return 1000000
	screen.last_tick_usec=1000000
	await capture("01-title")
	screen._primary()
	await capture("02-intro")
	for encounter in range(8):
		screen._primary()
		await capture("03-player-turn-%d" % (encounter+1))
		while not screen.model.terminal():
			screen._attack(Element.weakness(screen.run.spec().element))
			screen.advance(0.3)
			if screen.model.turn_number==1: await capture("04-player-impact-%d" % encounter)
			screen.advance(0.3)
			if not screen.model.terminal():
				if encounter==0 and screen.model.turn_number==1: await capture("05-enemy-turn")
				screen.advance(0.65)
				if screen.model.turn_number==1: await capture("06-enemy-impact-%d" % encounter)
				screen.advance(0.3)
				if encounter==0 and screen.model.turn_number==2:
					await capture("07-next-player-turn")
					screen.pause_duel()
					await capture("08-pause")
					screen._primary()
		screen.advance(0.4)
		await capture("09-result-%d" % (encounter+1))
		if encounter<7: screen._reward(&"long_breath" if encounter==0 else &"iron_resolve")
	assert(screen.run.state==RunModel.State.CLEARED and screen.run.seals==8)
	print("PASS native 390x844 Compatibility visual smoke: %d screenshots, complete eight-seal run" % checks)
	screen.queue_free()
	await process_frame
	quit()
