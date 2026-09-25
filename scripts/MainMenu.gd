extends Control
## Main menu for Crystal Rush.

func _ready() -> void:
	UIFactory.make_background(self)
	_build_ui()

func _build_ui() -> void:
	var root := VBoxContainer.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_theme_constant_override("separation", 18)
	add_child(root)

	var top_pad := Control.new()
	top_pad.custom_minimum_size = Vector2(0, 90)
	root.add_child(top_pad)

	var title := UIFactory.make_title("CRYSTAL RUSH")
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root.add_child(title)

	var subtitle := UIFactory.make_label("swipe the alien highway. bank the shards.", 24, Color(0.75, 0.75, 0.9))
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root.add_child(subtitle)

	var stats_spacer := Control.new()
	stats_spacer.custom_minimum_size = Vector2(0, 30)
	root.add_child(stats_spacer)

	# Stat chips: best score + crystal balance
	var stats_row := HBoxContainer.new()
	stats_row.alignment = BoxContainer.ALIGNMENT_CENTER
	stats_row.add_theme_constant_override("separation", 24)
	root.add_child(stats_row)

	var best_panel := UIFactory.make_panel()
	var best_box := VBoxContainer.new()
	best_box.add_child(UIFactory.make_label("BEST DISTANCE", 18, Color(0.6, 0.9, 1.0)))
	best_box.add_child(UIFactory.make_label(str(Save.best_score) + " m", 40, Color(1, 1, 1)))
	best_panel.add_child(best_box)
	stats_row.add_child(best_panel)

	var crystal_panel := UIFactory.make_panel()
	var crystal_box := VBoxContainer.new()
	crystal_box.add_child(UIFactory.make_label("CRYSTALS", 18, Color(0.75, 0.3, 1.0)))
	crystal_box.add_child(UIFactory.make_label(str(Save.crystals), 40, Color(1, 1, 1)))
	crystal_panel.add_child(crystal_box)
	stats_row.add_child(crystal_panel)

	var mid_spacer := Control.new()
	mid_spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(mid_spacer)

	# Menu buttons
	var btn_wrap := CenterContainer.new()
	root.add_child(btn_wrap)
	var btn_col := VBoxContainer.new()
	btn_col.custom_minimum_size = Vector2(560, 0)
	btn_col.add_theme_constant_override("separation", 22)
	btn_wrap.add_child(btn_col)

	var play_btn := UIFactory.make_button("▶  PLAY", UIFactory.ACCENT)
	play_btn.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/Game.tscn"))
	btn_col.add_child(play_btn)

	var shop_btn := UIFactory.make_button("◆  SHOP", UIFactory.ACCENT_2)
	shop_btn.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/Shop.tscn"))
	btn_col.add_child(shop_btn)

	var settings_btn := UIFactory.make_button("⚙  SETTINGS", Color(0.4, 0.42, 0.55))
	settings_btn.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/Settings.tscn"))
	btn_col.add_child(settings_btn)

	var quit_btn := UIFactory.make_button("QUIT", UIFactory.WARN)
	quit_btn.pressed.connect(func(): get_tree().quit())
	btn_col.add_child(quit_btn)

	var bottom_pad := Control.new()
	bottom_pad.custom_minimum_size = Vector2(0, 70)
	root.add_child(bottom_pad)
