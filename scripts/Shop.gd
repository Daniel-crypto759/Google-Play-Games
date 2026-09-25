extends Control
## Crystal skin shop.

var crystal_label: Label

func _ready() -> void:
	UIFactory.make_background(self)
	_build_ui()

func _build_ui() -> void:
	var root := VBoxContainer.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_theme_constant_override("separation", 12)
	add_child(root)

	var top_pad := Control.new()
	top_pad.custom_minimum_size = Vector2(0, 60)
	root.add_child(top_pad)

	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 16)
	root.add_child(header)

	var back_btn := UIFactory.make_button("←", Color(0.4, 0.42, 0.55))
	back_btn.custom_minimum_size = Vector2(96, 96)
	back_btn.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/MainMenu.tscn"))
	header.add_child(back_btn)

	var title := UIFactory.make_title("SHARD SHOP")
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)

	var balance_panel := UIFactory.make_panel()
	crystal_label = UIFactory.make_label("◆ " + str(Save.crystals), 30, UIFactory.ACCENT_2)
	balance_panel.add_child(crystal_label)
	header.add_child(balance_panel)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root.add_child(scroll)

	var grid := VBoxContainer.new()
	grid.add_theme_constant_override("separation", 20)
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 50)
	margin.add_theme_constant_override("margin_right", 50)
	margin.add_theme_constant_override("margin_top", 20)
	margin.add_theme_constant_override("margin_bottom", 40)
	margin.add_child(grid)
	scroll.add_child(margin)

	for id in Save.SKINS.keys():
		grid.add_child(_make_skin_row(id))

func _make_skin_row(id: String) -> Control:
	var data: Dictionary = Save.SKINS[id]
	var panel := UIFactory.make_panel()
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 20)
	panel.add_child(row)

	var swatch := ColorRect.new()
	swatch.color = data["color"]
	swatch.custom_minimum_size = Vector2(80, 80)
	row.add_child(swatch)

	var info := VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.add_child(UIFactory.make_label(data["name"], 30, Color(1, 1, 1)))
	var owned: bool = Save.owned_skins.has(id)
	var equipped: bool = Save.equipped_skin == id
	var status_text := "◆ %d" % data["cost"] if not owned else ("EQUIPPED" if equipped else "OWNED")
	var status_color := UIFactory.ACCENT_2 if not owned else (UIFactory.GOOD if equipped else Color(0.7, 0.7, 0.8))
	var status_lbl := UIFactory.make_label(status_text, 20, status_color)
	info.add_child(status_lbl)
	row.add_child(info)

	var action_btn := UIFactory.make_button("", UIFactory.ACCENT)
	action_btn.custom_minimum_size = Vector2(200, 72)
	_refresh_action_btn(action_btn, id)
	action_btn.pressed.connect(func(): _on_action(id, action_btn, status_lbl))
	row.add_child(action_btn)

	return panel

func _refresh_action_btn(btn: Button, id: String) -> void:
	var owned: bool = Save.owned_skins.has(id)
	var equipped: bool = Save.equipped_skin == id
	if equipped:
		btn.text = "EQUIPPED"
		btn.disabled = true
	elif owned:
		btn.text = "EQUIP"
		btn.disabled = false
	else:
		btn.text = "BUY"
		btn.disabled = false

func _on_action(id: String, btn: Button, status_lbl: Label) -> void:
	var owned: bool = Save.owned_skins.has(id)
	if not owned:
		if Save.buy_skin(id):
			Save.equip_skin(id)
	else:
		Save.equip_skin(id)
	crystal_label.text = "◆ " + str(Save.crystals)
	var data: Dictionary = Save.SKINS[id]
	owned = Save.owned_skins.has(id)
	var equipped: bool = Save.equipped_skin == id
	status_lbl.text = "◆ %d" % data["cost"] if not owned else ("EQUIPPED" if equipped else "OWNED")
	status_lbl.add_theme_color_override("font_color", UIFactory.ACCENT_2 if not owned else (UIFactory.GOOD if equipped else Color(0.7, 0.7, 0.8)))
	_refresh_action_btn(btn, id)
	# Equipping affects every row's status label, so rebuild the whole list.
	_reload()

func _reload() -> void:
	for child in get_children():
		child.queue_free()
	call_deferred("_build_ui_deferred")

func _build_ui_deferred() -> void:
	UIFactory.make_background(self)
	_build_ui()
