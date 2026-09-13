extends SceneTree
## Screenshots are QA captures, not authored runtime raster assets.
var screen
var captures := 0
func _initialize() -> void:
 call_deferred("run")
func capture(label: String) -> void:
 screen._refresh()
 await process_frame
 await process_frame
 await RenderingServer.frame_post_draw
 var picture := root.get_texture().get_image()
 assert(picture.get_size() == Vector2i(390,844))
 assert(picture.save_png("res://../qa/2026-09-13-companion/" + label + ".png") == OK)
 captures += 1
func run() -> void:
 assert(DisplayServer.get_name() != "headless")
 root.size = Vector2i(390,844)
 screen = load("res://scenes/duel.tscn").instantiate()
 root.add_child(screen)
 screen.set_process(false)
 screen.clock = func(): return 1000000
 screen.last_tick_usec = 1000000
 screen._primary()
 screen._area_action("pair",0)
 for n in range(4):
  screen._area_action("node",screen.run.next_nodes()[0])
  screen._primary()
  if n == 0: await capture("01-solo")
  if n == 3: await capture("04-companion-battle")
  while not screen.model.terminal():
   screen._attack(1)
   screen.advance(0.3)
   if n == 3 and screen.model.turn_number == 1: await capture("05-support-impact")
   screen.advance(1.25)
  screen.advance(0.4)
  if n == 2:
   assert(screen.run.state == RunModel.State.RECRUIT)
   await capture("02-kira-joined")
   screen._primary()
  screen._area_action("loot",0)
  if n == 2:
   await capture("03-companion-shrine")
   screen._area_action("companion",2)
  var e := 1
  while e < 5 and screen.run.techniques[e] == 3: e += 1
  screen._area_action("train",0 if e == 5 else e)
 screen._title()
 assert(not screen.companion.visible)
 await capture("06-reset")
 print("PASS native companion smoke: %d captures" % captures)
 screen.queue_free()
 await process_frame
 quit()
