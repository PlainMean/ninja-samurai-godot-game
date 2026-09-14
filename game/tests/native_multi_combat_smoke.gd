extends SceneTree
## Captures actual native render output for QA; does not author game art.
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
 assert(picture.get_size() == root.size)
 assert(picture.save_png("res://../qa/2026-09-14-multi-hero-combat/" + label + ".png") == OK)
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
 # Reach Kira through an actual first-boss clear before the three-enemy fixture.
 for n in range(3):
  screen._area_action("node",n)
  screen._primary()
  while not screen.model.terminal():
   screen._attack(1)
   screen.advance(0.6)
   while screen.model.state in [CombatModel.Phase.ENEMY_TURN,CombatModel.Phase.ENEMY_ATTACK]: screen.advance(0.95)
  screen.advance(0.4)
  if screen.run.state == RunModel.State.RECRUIT: screen._primary()
  screen._area_action("loot",0)
  screen._area_action("train",1 if screen.run.techniques[1]<3 else 2)
 assert(screen.run.companion_joined)
 screen.run.current_node = 10
 screen.run.state = RunModel.State.INTRO
 screen._primary()
 await capture("01-party-main-390x844")
 screen.combat_controls.choose_target(1)
 screen.combat_controls.choose_actor(&"kira")
 await capture("02-kira-target-390x844")
 screen.combat_controls.use_tide()
 screen.advance(0.3)
 await capture("03-tide-impact-390x844")
 screen.advance(3)
 screen.combat_controls.choose_actor(&"main")
 screen.combat_controls.open_skills()
 await capture("04-skills-390x844")
 screen.combat_controls.use_skill(&"stone_guard")
 screen.advance(3)
 root.size = Vector2i(390,780)
 root.content_scale_size = Vector2i(390,780)
 await process_frame
 screen._layout()
 await capture("05-party-390x780")
 screen.combat_controls.open_skills()
 await capture("06-skills-390x780")
 print("PASS native multi-combat smoke: %d captures" % captures)
 screen.queue_free()
 await process_frame
 quit()
