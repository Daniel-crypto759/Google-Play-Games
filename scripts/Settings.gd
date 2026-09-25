extends Control
## Settings screen: audio toggles + progress reset.

func _ready() -> void:
	UIFactory.make_background(self)
	_build_ui()

func _build_ui() -> void:
	var root := VBoxContainer.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_theme_constant_override("separation", 20)
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

	var title := UIFactory.make_title("SETTINGS")
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)

	var spacer_pad := Control.new()
	spacer_pad.custom_minimum_size = Vector2(96, 0)
	header.add_child(spacer_pad)

	var body_wrap := CenterContainer.new()
	body_wrap.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(body_wrap)

	var col := VBoxContainer.new()
	col.custom_minimum_size = Vector2(640, 0)
	col.add_theme_constant_override("separation", 24)
	body_wrap.add_child(col)

	col.add_child(_make_toggle_row("MUSIC", Save.music_on, func(v): Save.music_on = v; Save.save_game(); Audio.apply_settings()))
	col.add_child(_make_toggle_row("SOUND EFFECTS", Save.sfx_on, func(v): Save.sfx_on = v; Save.save_game(); Audio.apply_settings()))

	var reset_panel := UIFactory.make_panel()
	var reset_col := VBoxContainer.new()
	reset_col.add_theme_constant_override("separation", 14)
	reset_col.add_child(UIFactory.make_label("Progress is saved on this device only.", 20, Color(0.7, 0.7, 0.82)))
	var reset_btn := UIFactory.make_button("RESET PROGRESS", UIFactory.WARN)
	reset_btn.pressed.connect(_on_reset_pressed)
	reset_col.add_child(reset_btn)
	reset_panel.add_child(reset_col)
	col.add_child(reset_panel)

	var version_lbl := UIFactory.make_label("Crystal Rush v1.0", 18, Color(0.45, 0.45, 0.55))
	version_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	version_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root.add_child(version_lbl)

	var bottom_pad := Control.new()
	bottom_pad.custom_minimum_size = Vector2(0, 60)
	root.add_child(bottom_pad)

func _make_toggle_row(label_text: String, value: bool, on_change: Callable) -> Control:
	var panel := UIFactory.make_panel()
	var row := HBoxContainer.new()
	row.add_child(UIFactory.make_label(label_text, 28, Color(1, 1, 1)))
	var toggle_spacer := Control.new()
	toggle_spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(toggle_spacer)
	var chk := CheckButton.new()
	chk.button_pressed = value
	chk.custom_minimum_size = Vector2(90, 50)
	chk.toggled.connect(func(v): on_change.call(v))
	row.add_child(chk)
	panel.add_child(row)
	return panel

func _on_reset_pressed() -> void:
	Save.best_score = 0
	Save.crystals = 0
	Save.owned_skins = ["prism"]
	Save.equipped_skin = "prism"
	Save.save_game()
	for child in get_children():
		child.queue_free()
	call_deferred("_rebuild")

func _rebuild() -> void:
	UIFactory.make_background(self)
	_build_ui()
