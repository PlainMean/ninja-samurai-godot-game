extends PanelContainer
signal action(id: String, value: int)
const Touch = preload("res://scripts/touch_action.gd")
var content: VBoxContainer
var scroll: ScrollContainer
func _ready() -> void:
 name = "AreaPanel"
 position = Vector2(20,142)
 size = Vector2(350,660)
 var style := StyleBoxFlat.new()
 style.bg_color = Color("23253e")
 style.content_margin_left = 12
 style.content_margin_right = 12
 style.content_margin_top = 12
 style.content_margin_bottom = 12
 add_theme_stylebox_override("panel",style)
 scroll = ScrollContainer.new()
 scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
 add_child(scroll)
 content = VBoxContainer.new()
 content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 content.add_theme_constant_override("separation",8)
 scroll.add_child(content)
func label_text(text: String, large := false) -> void:
 var label := Label.new()
 label.text = text
 label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
 label.add_theme_font_size_override("font_size",22 if large else 16)
 content.add_child(label)
func button(text: String, id: String, value := 0, enabled := true, element := 0, parent: Node = null) -> void:
 var b := Touch.new()
 b.text = text
 b.custom_minimum_size = Vector2(0,60)
 b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 b.add_theme_font_size_override("font_size",16)
 b.disabled = not enabled
 if id in ["sword","equip"]:
  b.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
  b.icon = WeaponSpec.VISUALS[element].frames.get_frame_texture(&"sword",0)
  b.expand_icon = true
  b.add_theme_constant_override("icon_max_width",32)
 if element > 0: b.add_theme_color_override("font_color",Element.effect_color(element))
 b.activated.connect(func(): action.emit(id,value))
 (content if parent == null else parent).add_child(b)
func grid() -> GridContainer:
 var g := GridContainer.new()
 g.columns = 2
 g.add_theme_constant_override("h_separation",8)
 g.add_theme_constant_override("v_separation",8)
 content.add_child(g)
 return g
func present(run: RunModel, area: int, sword: int, inventory_open: bool) -> void:
 for child in content.get_children():
  content.remove_child(child)
  child.queue_free()
 scroll.scroll_vertical = 0
 var weapon: WeaponSpec = run.WEAPONS[sword] if run.state == RunModel.State.LOADOUT else run.equipped_weapon()
 var row := HBoxContainer.new()
 content.add_child(row)
 var icon := TextureRect.new()
 icon.name = "EquippedSwordIcon"
 icon.texture = weapon.visual().frames.get_frame_texture(&"sword",0)
 icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
 icon.custom_minimum_size = Vector2(24,24)
 icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
 icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
 row.add_child(icon)
 var title := Label.new()
 title.text = "%s · %s" % [weapon.display_name,Element.label(weapon.element)]
 title.add_theme_font_size_override("font_size",14)
 row.add_child(title)
 match run.state:
  RunModel.State.LOADOUT:
   label_text("Choose your path",true)
   label_text("1. Starting sword · seeded 1–4\nMatch its element for +1 or +2.")
   var swords := grid()
   for i in range(4):
    button(("✓ " if sword == i else "") + run.WEAPONS[i].display_name + "\n" + Element.label(run.WEAPONS[i].element),"sword",i,true,run.WEAPONS[i].element,swords)
   label_text("2. Tap your two starting techniques\nOthers unlock at shrines. Levels 1–3.")
   var pairs := [[1,2],[1,3],[1,4],[2,3],[2,4],[3,4]]
   var pair_grid := grid()
   for i in range(6): button("%s +\n%s" % [Element.label(pairs[i][0]),Element.label(pairs[i][1])],"pair",i,true,0,pair_grid)
  RunModel.State.MAP:
   if inventory_open:
    label_text("Sword inventory",true)
    inventory(run)
    button("Return to Area Map","inventory")
    return
   label_text("Area Map · %d / 12 seals" % run.seals,true)
   label_text("ALLY Kira · WATER · %d/6 HP · L%d" % [run.companion_hp,run.companion_level+1] if run.companion_joined else "Two guards → boss → neighbors")
   var areas := grid()
   for i in range(4): button(run.AREA_NAMES[i] + (" ✓" if i*3+2 in run.cleared_nodes else ""),"area",i,run.area_unlocked(i),i+1,areas)
   label_text(run.AREA_NAMES[area] + " · tap next node",true)
   for slot in range(3):
    var n := area * 3 + slot
    var spec := run.area_encounters[n]
    button("%d. %s%s\n%s · %s\nweak %s · %d HP%s" % [slot+1,"BOSS · " if slot == 2 else "",spec.display_name,spec.unit.role,Element.label(spec.element),Element.label(Element.weakness(spec.element)),spec.enemy_max_hp," · ✓" if n in run.cleared_nodes else ""],"node",n,n in run.next_nodes(),int(spec.element))
   button("Inventory · switch sword" if not inventory_open else "Close inventory","inventory")
   if inventory_open: inventory(run)
  RunModel.State.LOOT:
   label_text("Victory · opponent’s sword",true)
   label_text(run.node_label(run.current_node))
   label_text("Collected: %s\nEquip it or keep any inventory sword." % run.WEAPONS[run.pending_loot].display_name)
   inventory(run)
   button("Keep equipped → shrine","loot")
  RunModel.State.TRAINING:
   label_text("Shrine of renewal",true)
   label_text("Health restored · %d / %d\nChoose one technique to unlock or develop.\nLevel contributes +0 / +1 / +2 damage." % [run.hp,run.max_hp])
   if run.companion_joined:
    label_text("Kira · WATER · %d/6 HP\n%s L%d · choose or upgrade once; then train yourself." % [run.companion_hp,run.companion_ability_name(),run.companion_level+1])
    var allies := grid()
    button("Support Strike\n%d–%d damage" % [1+run.companion_level,2+run.companion_level],"companion",0,not run.companion_trained,2,allies)
    button("Ward Pulse\nBlock %d damage" % (1+run.companion_level),"companion",1,not run.companion_trained,2,allies)
    button("Develop Kira · L%d → L%d" % [run.companion_level+1,mini(3,run.companion_level+2)],"companion",2,not run.companion_trained and run.companion_level<2)
   for e in range(1,5): button("%s · %s" % [Element.label(e),"Unlock level 1" if run.techniques[e] == 0 else "Level %d → %d" % [run.techniques[e],mini(3,run.techniques[e]+1)]],"train",e,run.techniques[e]<3,e)
   if run.techniques.slice(1).min() == 3: button("All mastered → continue","train",0)
func inventory(run: RunModel) -> void:
 var swords := grid()
 for i in run.inventory:
  var w = run.WEAPONS[i]
  button("%s%s\n%s" % ["✓ " if i == run.equipped else "",w.display_name,Element.label(w.element)],"equip",i,true,w.element,swords)
