extends SceneTree
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
 assert(picture.save_png("res://../qa/mobile/distinct-units/" + label + ".png") == OK)
 captures += 1
func run() -> void:
 assert(DisplayServer.get_name() != "headless")
 root.size = Vector2i(390,844)
 screen = load("res://scenes/duel.tscn").instantiate()
 root.add_child(screen)
 screen.set_process(false)
 screen.clock = func(): return 1000000
 screen.last_tick_usec = 1000000
 await capture("01-title")
 screen._primary()
 await capture("02-loadout")
 screen._area_action("pair",0)
 await capture("03-map")
 for n in range(12):
  screen._area_action("node",screen.run.next_nodes()[0])
  await capture("04-intro-%02d" % n)
  screen._primary()
  if n == 0:
   await capture("05-battle")
   screen.pause_duel()
   await capture("06-pause")
   screen._primary()
  while not screen.model.terminal():
   screen._attack(1)
   screen.advance(0.3)
   if screen.model.turn_number == 1: await capture("07-impact-%02d" % n)
   screen.advance(1.25)
  screen.advance(0.4)
  assert(screen.run.state == RunModel.State.LOOT)
  if n == 0: await capture("08-loot")
  screen._area_action("loot",0)
  if n == 0: await capture("09-shrine")
  var e := 1
  while e < 5 and screen.run.techniques[e] == 3: e += 1
  screen._area_action("train",0 if e == 5 else e)
  if n == 2: await capture("10-branch-map")
 assert(screen.run.bosses_defeated() == 4)
 await capture("11-reveal")
 print("PASS native area campaign: %d screenshots" % captures)
 screen.queue_free()
 await process_frame
 quit()
