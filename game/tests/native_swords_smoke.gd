extends SceneTree
## QA screenshots only; runtime artwork is exclusively exported by Aseprite.
var s
var captures := 0
func _initialize() -> void:
 call_deferred("run")
func capture(label: String) -> void:
 s._refresh()
 await process_frame
 await process_frame
 await RenderingServer.frame_post_draw
 var picture := root.get_texture().get_image()
 assert(picture.get_size() == Vector2i(390,844))
 assert(picture.save_png("res://../qa/2026-09-13-elemental-swords/"+label+".png") == OK)
 captures += 1
func run() -> void:
 assert(DisplayServer.get_name() != "headless")
 root.size = Vector2i(390,844)
 s = load("res://scenes/duel.tscn").instantiate()
 root.add_child(s)
 s.set_process(false)
 s.clock = func(): return 1000000
 s.last_tick_usec = 1000000
 s._primary()
 await capture("01-four-swords-loadout")
 s._area_action("pair",0)
 for i in range(4):
  s.run.state = RunModel.State.MAP
  s._area_action("equip",i)
  s._area_action("node",0)
  s._primary()
  await capture("0%d-%s-combat" % [i+2,Element.label(s.run.equipped_weapon().element).to_lower()])
  s._attack(1)
  s.advance(0.1)
  await capture("0%d-%s-attack" % [i+6,Element.label(s.run.equipped_weapon().element).to_lower()])
 print("PASS native swords smoke: %d captures at 390x844" % captures)
 s.queue_free()
 await process_frame
 quit()
