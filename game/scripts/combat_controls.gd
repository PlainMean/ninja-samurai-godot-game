extends Control
## Presentation only: all choices delegate to CombatModel.
const Touch = preload("res://scripts/touch_action.gd")
var skills_open := false
var screen: Control
var targets: Array[Button] = []
var main_button: Button
var kira_button: Button
var skills_button: Button
var tide_button: Button
var sheet: Panel
var sheet_title: Label
var auto_button: Button
var close_button: Button
var skill_buttons: Array[Button] = []
func make_button(label: String, at: Vector2, extent: Vector2, parent: Node = self) -> Button:
 var button := Touch.new()
 button.text = label
 button.position = at
 button.size = extent
 button.add_theme_font_size_override("font_size",14)
 button.add_theme_constant_override("outline_size",0)
 var style := StyleBoxFlat.new()
 style.bg_color = Color("242c46")
 style.border_color = Color("64718c")
 style.set_border_width_all(1)
 style.set_corner_radius_all(6)
 button.add_theme_stylebox_override("normal",style)
 var selected := style.duplicate()
 selected.bg_color = Color("354c61")
 selected.border_color = Color("84e0ef")
 selected.set_border_width_all(2)
 button.add_theme_stylebox_override("focus", selected)
 parent.add_child(button)
 return button
func _ready() -> void:
 name = "CombatControls"
 mouse_filter = Control.MOUSE_FILTER_IGNORE
 for slot in range(3):
  var button := make_button("",Vector2(14+slot*122,216),Vector2(118,106))
  button.name = "Target%d" % slot
  button.add_theme_font_size_override("font_size",12)
  button.activated.connect(func(): choose_target(slot))
  targets.append(button)
 main_button = make_button("MAIN HERO",Vector2(14,496),Vector2(118,48))
 main_button.name = "MainHero"
 main_button.activated.connect(func(): choose_actor(&"main"))
 kira_button = make_button("KIRA · WATER",Vector2(136,496),Vector2(118,48))
 kira_button.name = "Kira"
 kira_button.activated.connect(func(): choose_actor(&"kira"))
 skills_button = make_button("SKILLS",Vector2(258,496),Vector2(118,48))
 skills_button.name = "Skills"
 skills_button.activated.connect(open_skills)
 tide_button = make_button("TIDE ARC · WATER",Vector2(20,656),Vector2(350,96))
 tide_button.name = "TideArc"
 tide_button.activated.connect(use_tide)
 sheet = Panel.new()
 sheet.name = "SkillsPanel"
 sheet.position = Vector2(14,176)
 sheet.size = Vector2(362,452)
 sheet.z_index = 5
 var style := StyleBoxFlat.new()
 style.bg_color = Color("171e32")
 style.border_color = Color("84e0ef")
 style.set_border_width_all(2)
 style.set_corner_radius_all(10)
 sheet.add_theme_stylebox_override("panel",style)
 add_child(sheet)
 sheet_title = Label.new()
 sheet_title.position = Vector2(14,14)
 sheet_title.size = Vector2(334,54)
 sheet_title.add_theme_font_size_override("font_size",16)
 sheet.add_child(sheet_title)
 for i in range(3):
  var button := make_button("",Vector2(14,80+i*82),Vector2(334,74),sheet)
  button.name = String(CombatModel.SKILLS[i].id)
  button.add_theme_color_override("font_color",Element.effect_color(CombatModel.SKILLS[i].element))
  button.activated.connect(func(): use_skill(CombatModel.SKILLS[i].id))
  skill_buttons.append(button)
 auto_button = make_button("",Vector2(14,332),Vector2(334,48),sheet)
 auto_button.activated.connect(toggle_auto)
 close_button = make_button("Back to combat",Vector2(14,390),Vector2(334,48),sheet)
 close_button.activated.connect(func(): close_skills(); screen._refresh())
 sheet.visible = false

func cancel_pointers() -> void:
 for button in targets + skill_buttons + [main_button,kira_button,skills_button,tide_button,auto_button,close_button]:
  if is_instance_valid(button): button.cancel_pointer()

func eligible() -> bool:
 return screen != null and not screen.paused and screen.run.state == RunModel.State.FIGHT and screen.model.state == CombatModel.Phase.PLAYER_TURN

func fresh_input() -> bool:
 # Match normal attacks: a down during resolution can never become queued input.
 var ready := eligible()
 if screen != null: screen._sync_time()
 return ready and eligible()

func choose_target(slot: int) -> void:
 if fresh_input() and not skills_open: screen.model.select_target(slot)
 screen._refresh()

func choose_actor(actor: StringName) -> void:
 if fresh_input() and not skills_open: screen.model.select_actor(actor)
 screen._refresh()

func open_skills() -> void:
 if not fresh_input(): return
 cancel_pointers()
 skills_open = true
 screen._refresh()

func close_skills() -> void:
 skills_open = false
 if sheet != null: sheet.visible = false
 cancel_pointers()

func use_tide() -> void:
 if fresh_input() and not skills_open: screen.model.request_kira_attack()
 screen._refresh()

func use_skill(id: StringName) -> void:
 if fresh_input() and skills_open and screen.model.request_skill(id): close_skills()
 screen._refresh()

func toggle_auto() -> void:
 if fresh_input() and skills_open: screen.model.set_auto_companion(not screen.model.auto_companion)
 screen._refresh()

func present(owner_screen: Control) -> void:
 screen = owner_screen
 visible = screen.run.area_mode and screen.run.state == RunModel.State.FIGHT and not screen.paused
 if not visible: return
 var c: CombatModel = screen.model
 var h: Control = screen.hud
 var area: bool = screen.run.area_mode
 var compact: bool = h.get_node("Actions").position.y < 650
 # Legacy HUD and its regression text remain intact; new controls use the lower gap.
 for i in range(3):
  var button := targets[i]
  button.visible = area and i < c.enemies.size() and not skills_open
  if not button.visible: continue
  var enemy := c.enemies[i]
  var spec := enemy.spec
  var boss := spec.unit != null and spec.unit.boss
  button.text = "%s#%d %s\n%s\n%s\n%s · %d/%d HP\n%s" % ["✓ " if i == c.target_slot else "",i+1,"BOSS" if boss else "TARGET", spec.display_name.replace(" ","\n") if c.enemies.size()>1 else spec.display_name,spec.unit.role if spec.unit != null else "Guardian",Element.label(spec.element),enemy.hp,spec.enemy_max_hp,"FALLEN" if enemy.hp == 0 else "Next: " + Element.label(enemy.intent_element(c.turn_number))]
  button.tooltip_text = "%s · %s\nIntent %s · %s" % [spec.display_name,spec.unit.role if spec.unit != null else "Guardian",Element.label(enemy.intent_element(c.turn_number)),enemy.intent_name(c.turn_number)]
  button.disabled = not eligible() or enemy.hp == 0
  button.modulate = Color.WHITE if i == c.target_slot else Color("a9b5ca")
  button.position = Vector2(14+i*122,216)
  button.size = Vector2(118,106) if c.enemies.size()>1 else Vector2(362,106)
 var row_y := 464.0 if compact else 496.0
 for button in [main_button,kira_button,skills_button]:
  button.position.y = row_y
  button.visible = not skills_open
  button.disabled = not eligible()
 main_button.text = ("✓ " if c.selected_actor == &"main" else "") + "MAIN HERO"
 kira_button.text = ("✓ " if c.selected_actor == &"kira" else "") + ("KIRA FALLEN" if c.companion_spec != null and c.companion_hp == 0 else "KIRA · WATER")
 kira_button.disabled = not eligible() or c.companion_spec == null or c.companion_hp <= 0
 tide_button.visible = c.selected_actor == &"kira" and not skills_open
 tide_button.disabled = not eligible() or c.companion_hp <= 0
 tide_button.position.y = h.get_node("Actions").position.y
 var forecast := c.kira_forecast()
 tide_button.text = "TIDE ARC · WATER\n%d damage → #%d · %d incoming" % [c.kira_damage(),c.target_slot+1,forecast.get("reply",0)]
 h.get_node("Actions").visible = c.selected_actor != &"kira"
 if area:
  h.get_node("ElementInfo").visible = false
  h.get_node("Intent").visible = false
  h.get_node("Cue").text = ("KIRA" if c.selected_actor == &"kira" else "MAIN HERO") + (" · CHOOSE ACTION" if eligible() else " · RESOLVING")
  h.get_node("Cue").add_theme_font_size_override("font_size",18)
  h.get_node("Feedback").position.y = 516 if compact else 548
  h.get_node("Feedback").text = "\n".join([c.last_action_summary] + c.combat_log.slice(-1 if compact else -2))
  h.get_node("Hint").position.y = 552 if compact else 600
  h.get_node("Hint").add_theme_font_size_override("font_size",12)
  h.get_node("Hint").text = "%s · %s\nRoll 1–4 · same +1/2 · technique +0/1/2" % [screen.run.equipped_weapon().display_name,Element.label(screen.run.equipped_weapon().element)]
  h.get_node("Feedback").add_theme_constant_override("line_spacing",0)
  h.get_node("Hint").add_theme_constant_override("line_spacing",0)
  h.get_node("Feedback").size.y = 32 if compact else 48
  h.get_node("Hint").size.y = 30
  h.get_node("EquippedSwordIcon").position.y = h.get_node("Hint").position.y
  h.get_node("EquippedSwordIcon").size.y = 28
  h.get_node("Footer").text = "Target #%d · replies in slot order · Skills ↑" % (c.target_slot+1)
 sheet.visible = skills_open
 sheet.position.y = 152 if compact else 176
 sheet_title.text = "MAIN HERO SKILLS · development +%d\nTarget #%d · %s" % [c.skill_level,c.target_slot+1,c.spec.display_name]
 for i in range(3):
  var skill := c.SKILLS[i]
  var f := c.skill_forecast(skill.id)
  var effect := "%d damage" % f.damage if skill.base_damage > 0 else "Block %d this round" % f.guard
  if skill.evade: effect += " · evade first reply"
  skill_buttons[i].text = "%s · %s\n%s\n%s · %d incoming" % [skill.display_name,Element.label(skill.element),effect,"READY · 2-turn cooldown" if f.cooldown == 0 else "%d turns until ready" % f.cooldown,f.reply]
  skill_buttons[i].disabled = not f.available
 auto_button.text = "Kira auto: %s · %s" % ["ON" if c.auto_companion else "OFF",screen.run.companion_ability_name()]
 auto_button.disabled = not eligible() or c.companion_hp <= 0
 # TouchAction uses raw touch events; explicitly disable every underlying control.
 if skills_open:
  for button in targets + [main_button,kira_button,tide_button]: button.disabled = true
