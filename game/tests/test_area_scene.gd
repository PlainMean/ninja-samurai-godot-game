extends RefCounted
func run(t) -> void:
 var s = load("res://scenes/duel.tscn").instantiate()
 t.root.add_child(s)
 s.set_process(false)
 s.clock = func(): return 1000000
 s.last_tick_usec = 1000000
 s._primary()
 t.check(s.run.state == RunModel.State.LOADOUT and s.area_panel.visible, "default loadout modal")
 s._area_action("sword",1)
 s._area_action("pair",4)
 t.check(s.run.equipped == 1 and s.run.techniques == [0,0,1,0,1], "UI starting choice reaches model")
 t.check(s.run.state == RunModel.State.MAP and not s.modal.get_node("Panel").visible, "exclusive area modal")
 await t.process_frame
 await t.process_frame
 for child in s.area_panel.content.get_children():
  if child is Button: t.check(child.size.y >= 60 and child.size.x <= 326, "map touch bounds")
 t.check(s.area_panel.content.size.y <= s.area_panel.scroll.size.y, "map core controls fit without scrolling")
 s._area_action("inventory",0)
 await t.process_frame
 await t.process_frame
 t.check(s.area_panel.content.size.y <= s.area_panel.scroll.size.y, "inventory fits without scrolling")
 s._area_action("inventory",0)
 s._area_action("node",1)
 t.check(s.modal.get_node("Panel").visible and s.primary_button.visible and not s.area_panel.visible, "map restores readable fight intro")
 s._primary()
 t.check(s.attack_buttons[0].disabled and not s.attack_buttons[1].disabled, "four buttons have locked states")
 t.check("Tideglass" in s.hud.get_node("Hint").text, "equipped weapon always visible")
 s.pause_duel()
 t.check(s.paused and not s.area_panel.visible, "pause exclusivity")
 s._primary()
 while not s.model.terminal():
  s._attack(2)
  s.advance(1.55)
 s.advance(0.4)
 t.check(s.run.state == RunModel.State.LOOT and s.area_panel.visible, "victory loot modal")
 s._area_action("equip",s.run.pending_loot)
 s._area_action("loot",0)
 s._area_action("train",1)
 t.check(s.run.state == RunModel.State.MAP and s.run.techniques[1] == 1, "loot shrine unlock map flow")
 s._title()
 t.check(s.run.state == RunModel.State.TITLE and s.run.cleared_nodes.is_empty(), "title resets campaign")
 s.queue_free()
 await t.process_frame
 var clip := Control.new()
 clip.clip_contents = true
 clip.size = Vector2(100,100)
 t.root.add_child(clip)
 var clipped := preload("res://scripts/touch_action.gd").new()
 clipped.position = Vector2(0,120)
 clipped.size = Vector2(80,60)
 clip.add_child(clipped)
 t.check(not clipped._point_visible(Vector2(20,140)), "scrolled-out target cannot receive touches")
 clip.queue_free()
 await t.process_frame
