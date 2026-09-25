extends Node3D
## Crystal Rush core gameplay: a 3-lane neon runner.
## Swipe to change lane, smash through value gates to grow your carried
## crystal stack, dodge laser barriers, and get harvested (banked) at
## checkpoints before a barrier ends the run.

const LANES := [-2.4, 0.0, 2.4]
const PLAYER_Z := 0.0
const SEGMENT_LENGTH := 15.0
const SPAWN_Z := -85.0
const DESPAWN_Z := 12.0
const BASE_SPEED := 9.0
const MAX_SPEED := 21.0
const SPEED_RAMP := 0.045
const CARRY_BASE := 20
const SWIPE_THRESHOLD := 60.0

var speed := BASE_SPEED
var distance := 0.0
var carried_value := CARRY_BASE
var banked_crystals := 0
var current_lane := 1
var lane_visual_x := 0.0
var game_over := false
var paused := false
var run_started := false

var spawn_accum := 0.0
var segments_spawned := 0

var active_items: Array = []  # each: {node, type, lane, triggered, prev_z}
var player: Node3D
var player_ring: Node3D
var value_label: Label3D
var track_root: Node3D

var drag_active := false
var drag_start_x := 0.0

# --- UI refs ---
var canvas: CanvasLayer
var distance_label: Label
var carried_label: Label
var flash_label: Label
var pause_panel: Control
var gameover_panel: Control
var countdown_label: Label

func _ready() -> void:
	_setup_world()
	_setup_player()
	_setup_ui()
	_start_countdown()

# ---------------------------------------------------------------- WORLD

func _setup_world() -> void:
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.02, 0.015, 0.05)
	env.fog_enabled = true
	env.fog_light_color = Color(0.15, 0.08, 0.3)
	env.fog_density = 0.02
	env.glow_enabled = true
	env.glow_intensity = 0.9
	env.glow_bloom = 0.25
	var world_env := WorldEnvironment.new()
	world_env.environment = env
	add_child(world_env)

	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-55, -35, 0)
	sun.light_color = Color(0.6, 0.75, 1.0)
	sun.light_energy = 0.7
	add_child(sun)

	var fill := OmniLight3D.new()
	fill.position = Vector3(0, 5, 2)
	fill.light_color = Color(0.8, 0.3, 1.0)
	fill.light_energy = 3.0
	fill.omni_range = 20
	add_child(fill)

	var cam := Camera3D.new()
	cam.position = Vector3(0, 6.2, 9.5)
	cam.fov = 70
	add_child(cam)
	cam.look_at(Vector3(0, 1.4, -18), Vector3.UP)

	track_root = Node3D.new()
	track_root.name = "Track"
	add_child(track_root)

	# Endless floor strip.
	var floor_mesh := CSGBox3D.new()
	floor_mesh.size = Vector3(10, 0.4, 4000)
	floor_mesh.position = Vector3(0, -0.2, -1900)
	var floor_mat := StandardMaterial3D.new()
	floor_mat.albedo_color = Color(0.08, 0.06, 0.16)
	floor_mat.emission_enabled = true
	floor_mat.emission = Color(0.15, 0.35, 0.5)
	floor_mat.emission_energy_multiplier = 0.35
	floor_mat.metallic = 0.6
	floor_mat.roughness = 0.3
	floor_mesh.material = floor_mat
	add_child(floor_mesh)

	# Lane divider glow strips.
	for lx in [-1.2, 1.2]:
		var strip := CSGBox3D.new()
		strip.size = Vector3(0.06, 0.02, 4000)
		strip.position = Vector3(lx, 0.01, -1900)
		var sm := StandardMaterial3D.new()
		sm.emission_enabled = true
		sm.emission = Color(0.4, 0.9, 1.0)
		sm.emission_energy_multiplier = 2.0
		sm.albedo_color = Color(0.4, 0.9, 1.0)
		strip.material = sm
		add_child(strip)

	for i in range(10):
		_spawn_decoration(-i * 8.5)

# ---------------------------------------------------------------- PLAYER

func _setup_player() -> void:
	player = Node3D.new()
	player.position = Vector3(LANES[current_lane], 1.1, PLAYER_Z)
	add_child(player)

	var skin_id: String = Save.equipped_skin
	var skin_color: Color = Save.SKINS.get(skin_id, {}).get("color", Color(0.35, 0.85, 1.0))

	var core := CSGSphere3D.new()
	core.radius = 0.55
	var core_mat := StandardMaterial3D.new()
	core_mat.albedo_color = skin_color
	core_mat.emission_enabled = true
	core_mat.emission = skin_color
	core_mat.emission_energy_multiplier = 1.6
	core_mat.metallic = 0.3
	core_mat.roughness = 0.15
	core.material = core_mat
	player.add_child(core)

	player_ring = CSGTorus3D.new()
	player_ring.inner_radius = 0.75
	player_ring.outer_radius = 0.9
	player_ring.rotation_degrees = Vector3(90, 0, 0)
	var ring_mat := StandardMaterial3D.new()
	ring_mat.albedo_color = Color(1, 1, 1)
	ring_mat.emission_enabled = true
	ring_mat.emission = skin_color.lightened(0.3)
	ring_mat.emission_energy_multiplier = 2.2
	player_ring.material = ring_mat
	player.add_child(player_ring)

	value_label = Label3D.new()
	value_label.text = str(carried_value)
	value_label.font_size = 64
	value_label.position = Vector3(0, 1.4, 0)
	value_label.modulate = Color(1, 1, 1)
	value_label.outline_size = 12
	value_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	player.add_child(value_label)

# ---------------------------------------------------------------- UI

func _setup_ui() -> void:
	canvas = CanvasLayer.new()
	add_child(canvas)

	var hud_root := Control.new()
	hud_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	hud_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(hud_root)

	var top_margin := MarginContainer.new()
	top_margin.set_anchors_preset(Control.PRESET_TOP_WIDE)
	top_margin.add_theme_constant_override("margin_left", 30)
	top_margin.add_theme_constant_override("margin_right", 30)
	top_margin.add_theme_constant_override("margin_top", 50)
	hud_root.add_child(top_margin)

	var top_row := HBoxContainer.new()
	top_margin.add_child(top_row)

	var dist_panel := UIFactory.make_panel()
	distance_label = UIFactory.make_label("0 m", 32, Color(0.6, 0.9, 1.0))
	dist_panel.add_child(distance_label)
	top_row.add_child(dist_panel)

	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top_row.add_child(spacer)

	var carried_panel := UIFactory.make_panel()
	carried_label = UIFactory.make_label("◆ " + str(carried_value), 32, UIFactory.ACCENT_2)
	carried_panel.add_child(carried_label)
	top_row.add_child(carried_panel)

	var spacer2 := Control.new()
	spacer2.custom_minimum_size = Vector2(16, 0)
	top_row.add_child(spacer2)

	var pause_btn := UIFactory.make_button("II", Color(0.4, 0.42, 0.55))
	pause_btn.custom_minimum_size = Vector2(80, 80)
	pause_btn.pressed.connect(_on_pause_pressed)
	top_row.add_child(pause_btn)

	# Floating "+N" feedback label.
	flash_label = UIFactory.make_label("", 40, UIFactory.GOOD)
	flash_label.set_anchors_preset(Control.PRESET_CENTER_TOP)
	flash_label.position = Vector2(0, 220)
	flash_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	flash_label.modulate.a = 0.0
	hud_root.add_child(flash_label)

	countdown_label = UIFactory.make_label("3", 140, Color(1, 1, 1))
	countdown_label.set_anchors_preset(Control.PRESET_CENTER)
	countdown_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hud_root.add_child(countdown_label)

	_build_pause_panel(hud_root)
	_build_gameover_panel(hud_root)

func _build_pause_panel(hud_root: Control) -> void:
	pause_panel = Control.new()
	pause_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	pause_panel.visible = false
	pause_panel.process_mode = Node.PROCESS_MODE_ALWAYS
	hud_root.add_child(pause_panel)

	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.7)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	pause_panel.add_child(dim)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	pause_panel.add_child(center)

	var panel := UIFactory.make_panel()
	var col := VBoxContainer.new()
	col.custom_minimum_size = Vector2(500, 0)
	col.add_theme_constant_override("separation", 20)
	col.add_child(UIFactory.make_title("PAUSED"))

	var resume_btn := UIFactory.make_button("RESUME", UIFactory.ACCENT)
	resume_btn.pressed.connect(_on_resume_pressed)
	col.add_child(resume_btn)

	var menu_btn := UIFactory.make_button("MAIN MENU", Color(0.4, 0.42, 0.55))
	menu_btn.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/MainMenu.tscn"))
	col.add_child(menu_btn)

	panel.add_child(col)
	center.add_child(panel)

func _build_gameover_panel(hud_root: Control) -> void:
	gameover_panel = Control.new()
	gameover_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	gameover_panel.visible = false
	hud_root.add_child(gameover_panel)

	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.78)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	gameover_panel.add_child(dim)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	gameover_panel.add_child(center)

	var panel := UIFactory.make_panel()
	gameover_panel.set_meta("panel", panel)
	var col := VBoxContainer.new()
	col.name = "Col"
	col.custom_minimum_size = Vector2(560, 0)
	col.add_theme_constant_override("separation", 16)
	panel.add_child(col)
	center.add_child(panel)
	gameover_panel.set_meta("col", col)

# ---------------------------------------------------------------- FLOW

func _start_countdown() -> void:
	countdown_label.visible = true
	for n in [3, 2, 1]:
		countdown_label.text = str(n)
		await get_tree().create_timer(0.55).timeout
	countdown_label.text = "GO!"
	await get_tree().create_timer(0.35).timeout
	countdown_label.visible = false
	run_started = true

func _on_pause_pressed() -> void:
	if game_over or not run_started:
		return
	paused = true
	pause_panel.visible = true
	get_tree().paused = true

func _on_resume_pressed() -> void:
	paused = false
	pause_panel.visible = false
	get_tree().paused = false

# ---------------------------------------------------------------- INPUT

func _input(event: InputEvent) -> void:
	if game_over or paused or not run_started:
		return
	if event is InputEventScreenTouch or event is InputEventMouseButton:
		var pressed: bool = event.pressed if event is InputEventScreenTouch else (event as InputEventMouseButton).pressed
		var pos: Vector2 = event.position
		if pressed:
			drag_active = true
			drag_start_x = pos.x
		else:
			drag_active = false
	elif event is InputEventScreenDrag or event is InputEventMouseMotion:
		if not drag_active:
			return
		var pos2: Vector2 = event.position
		var delta_x: float = pos2.x - drag_start_x
		if abs(delta_x) > SWIPE_THRESHOLD:
			if delta_x > 0:
				_change_lane(1)
			else:
				_change_lane(-1)
			drag_start_x = pos2.x
	elif event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_LEFT or event.keycode == KEY_A:
			_change_lane(-1)
		elif event.keycode == KEY_RIGHT or event.keycode == KEY_D:
			_change_lane(1)

func _change_lane(dir: int) -> void:
	current_lane = clamp(current_lane + dir, 0, LANES.size() - 1)

# ---------------------------------------------------------------- PROCESS

func _process(delta: float) -> void:
	if game_over or paused or not run_started:
		return

	speed = min(MAX_SPEED, speed + SPEED_RAMP * delta)
	var travel := speed * delta
	distance += travel
	distance_label.text = "%d m" % int(distance)

	# Smooth lane movement + a little lean into the turn.
	var target_x: float = LANES[current_lane]
	lane_visual_x = lerp(lane_visual_x, target_x, clamp(delta * 10.0, 0, 1))
	player.position.x = lane_visual_x
	player.rotation.z = lerp(player.rotation.z, clamp((target_x - lane_visual_x) * -0.6, -0.5, 0.5), clamp(delta * 8.0, 0, 1))
	player_ring.rotation.y += delta * 4.0
	player.position.y = 1.1 + sin(distance * 1.2) * 0.06

	_scroll_and_check(travel)
	_maybe_spawn(travel)

func _scroll_and_check(travel: float) -> void:
	# Each spawned node has its own logical "z" tracked per active_items entry
	# (a shared node like the harvester ring can be registered under several
	# entries, one per lane, so it must not be scrolled more than once).
	var i := active_items.size() - 1
	while i >= 0:
		var item: Dictionary = active_items[i]
		var node: Node3D = item["node"]
		if not is_instance_valid(node):
			active_items.remove_at(i)
			i -= 1
			continue
		var prev_z: float = item["z"]
		var new_z: float = prev_z + travel
		item["z"] = new_z
		if item.get("owns_node", true):
			node.position.z = new_z

		if item.get("type", "deco") != "deco" and not item.get("triggered", false):
			if prev_z < PLAYER_Z and new_z >= PLAYER_Z:
				item["triggered"] = true
				if item["lane"] == current_lane:
					_resolve_trigger(item)

		if new_z > DESPAWN_Z:
			if item.get("owns_node", true):
				node.queue_free()
			active_items.remove_at(i)
		i -= 1

func _resolve_trigger(item: Dictionary) -> void:
	match item["type"]:
		"add":
			_apply_value_delta(item["amount"])
		"sub":
			_apply_value_delta(-item["amount"])
		"mult":
			_apply_value_mult(item["amount"])
		"harvest":
			_bank_run(false)
		"obstacle":
			_die()

func _apply_value_delta(amount: int) -> void:
	carried_value = max(0, carried_value + amount)
	_refresh_value_ui(amount)

func _apply_value_mult(factor: float) -> void:
	var before := carried_value
	carried_value = max(0, int(round(carried_value * factor)))
	_refresh_value_ui(carried_value - before)

func _refresh_value_ui(delta_shown: int) -> void:
	value_label.text = str(carried_value)
	carried_label.text = "◆ " + str(carried_value)
	_show_flash(delta_shown)

func _show_flash(delta_shown: int) -> void:
	if delta_shown == 0:
		return
	var sign_txt := "+" if delta_shown > 0 else ""
	flash_label.text = sign_txt + str(delta_shown)
	flash_label.add_theme_color_override("font_color", UIFactory.GOOD if delta_shown > 0 else UIFactory.WARN)
	var tw := create_tween()
	flash_label.modulate.a = 1.0
	flash_label.position.y = 220
	tw.tween_property(flash_label, "position:y", 160, 0.6)
	tw.parallel().tween_property(flash_label, "modulate:a", 0.0, 0.6).set_delay(0.15)

func _bank_run(final: bool) -> void:
	banked_crystals += carried_value
	if not final:
		_show_flash(0)
		flash_label.text = "BANKED! ◆" + str(carried_value)
		flash_label.add_theme_color_override("font_color", UIFactory.ACCENT_2)
		flash_label.modulate.a = 1.0
		var tw := create_tween()
		tw.tween_property(flash_label, "modulate:a", 0.0, 1.0).set_delay(0.4)
		carried_value = CARRY_BASE
		value_label.text = str(carried_value)
		carried_label.text = "◆ " + str(carried_value)

func _die() -> void:
	if game_over:
		return
	game_over = true
	_bank_run(true)
	Save.register_run(int(distance), banked_crystals)
	_populate_gameover_panel()
	gameover_panel.visible = true

func _populate_gameover_panel() -> void:
	var col: VBoxContainer = gameover_panel.get_meta("col")
	col.add_child(UIFactory.make_title("RUN OVER"))
	col.add_child(UIFactory.make_label("Distance: %d m" % int(distance), 28, Color(1, 1, 1)))
	col.add_child(UIFactory.make_label("Crystals banked: ◆ %d" % banked_crystals, 28, UIFactory.ACCENT_2))
	col.add_child(UIFactory.make_label("Best distance: %d m" % Save.best_score, 22, Color(0.7, 0.7, 0.85)))

	var retry_btn := UIFactory.make_button("RETRY", UIFactory.ACCENT)
	retry_btn.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/Game.tscn"))
	col.add_child(retry_btn)

	var menu_btn := UIFactory.make_button("MAIN MENU", Color(0.4, 0.42, 0.55))
	menu_btn.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/MainMenu.tscn"))
	col.add_child(menu_btn)

# ---------------------------------------------------------------- SPAWNING

func _maybe_spawn(travel: float) -> void:
	spawn_accum += travel
	if spawn_accum >= SEGMENT_LENGTH:
		spawn_accum -= SEGMENT_LENGTH
		_spawn_segment()

func _spawn_segment() -> void:
	segments_spawned += 1
	# Warm-up: first couple of segments are always safe crystal rows.
	if segments_spawned <= 2:
		_spawn_crystal_row(SPAWN_Z)
		return

	if segments_spawned % 7 == 0:
		_spawn_harvester(SPAWN_Z)
		return

	var roll := randf()
	if roll < 0.5:
		_spawn_gate_row(SPAWN_Z)
	elif roll < 0.8:
		_spawn_obstacle_row(SPAWN_Z)
	else:
		_spawn_crystal_row(SPAWN_Z)

	_spawn_decoration(SPAWN_Z)

func _register_item(node: Node3D, type: String, lane: int) -> void:
	active_items.append({"node": node, "type": type, "lane": lane, "triggered": false, "z": node.position.z, "owns_node": true})
	track_root.add_child(node)

func _spawn_gate_row(z: float) -> void:
	# Pick 2 of 3 lanes for value gates; the third stays a neutral open lane.
	var lanes := [0, 1, 2]
	lanes.shuffle()
	var gate_lanes := [lanes[0], lanes[1]]
	var kinds := ["add", "sub", "mult"]
	kinds.shuffle()

	for idx in range(gate_lanes.size()):
		var gl: int = gate_lanes[idx]
		var kind: String = kinds[idx]
		var amount := 0
		var factor := 1.0
		var text := ""
		var color := UIFactory.GOOD
		match kind:
			"add":
				amount = randi_range(8, 26)
				text = "+%d" % amount
				color = UIFactory.GOOD
			"sub":
				amount = randi_range(6, 18)
				text = "-%d" % amount
				color = UIFactory.WARN
			"mult":
				factor = 2.0 if randf() < 0.7 else 0.5
				text = "x2" if factor == 2.0 else "÷2"
				color = UIFactory.ACCENT_2 if factor == 2.0 else UIFactory.WARN

		var gate := _make_gate_visual(text, color)
		gate.position = Vector3(LANES[gl], 0, z)
		var item_type := kind
		active_items.append({"node": gate, "type": item_type, "lane": gl, "triggered": false, "z": z, "owns_node": true, "amount": (amount if kind != "mult" else factor)})
		track_root.add_child(gate)

func _spawn_obstacle_row(z: float) -> void:
	var safe_lane := randi() % 3
	for l in range(3):
		if l == safe_lane:
			continue
		var barrier := _make_barrier_visual()
		barrier.position = Vector3(LANES[l], 0, z)
		_register_item(barrier, "obstacle", l)

func _spawn_crystal_row(z: float) -> void:
	var lane := randi() % 3
	for step in range(4):
		var crystal := _make_crystal_visual()
		var cz: float = z - step * 2.2
		crystal.position = Vector3(LANES[lane], 1.0, cz)
		active_items.append({"node": crystal, "type": "add", "lane": lane, "triggered": false, "z": cz, "owns_node": true, "amount": 3})
		track_root.add_child(crystal)

func _spawn_harvester(z: float) -> void:
	var gate := Node3D.new()
	var ring := CSGTorus3D.new()
	ring.inner_radius = 2.6
	ring.outer_radius = 3.0
	ring.rotation_degrees = Vector3(90, 0, 0)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = UIFactory.ACCENT_2
	mat.emission_enabled = true
	mat.emission = UIFactory.ACCENT_2
	mat.emission_energy_multiplier = 2.5
	ring.material = mat
	gate.add_child(ring)

	var label := Label3D.new()
	label.text = "HARVEST"
	label.font_size = 48
	label.position = Vector3(0, 3.6, 0)
	label.modulate = UIFactory.ACCENT_2
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	gate.add_child(label)

	gate.position = Vector3(0, 0, z)
	track_root.add_child(gate)
	# Harvester spans all lanes: register once per lane so any lane triggers it,
	# but only the first registration owns the node for scroll/cleanup purposes.
	for l in range(3):
		active_items.append({"node": gate, "type": "harvest", "lane": l, "triggered": false, "z": z, "owns_node": l == 0})

func _spawn_decoration(z: float) -> void:
	for side in [-1, 1]:
		var pillar := CSGCylinder3D.new()
		pillar.radius = 0.25
		pillar.height = randf_range(3.0, 7.0)
		pillar.position = Vector3(side * 4.6, pillar.height * 0.5 - 0.2, z)
		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color(0.15, 0.1, 0.3)
		mat.emission_enabled = true
		mat.emission = Color(0.6, 0.2, 1.0) if side < 0 else Color(0.2, 0.7, 1.0)
		mat.emission_energy_multiplier = 1.4
		pillar.material = mat
		active_items.append({"node": pillar, "type": "deco", "lane": -1, "triggered": true, "z": z, "owns_node": true})
		track_root.add_child(pillar)

# ---------------------------------------------------------------- VISUALS

func _make_gate_visual(text: String, color: Color) -> Node3D:
	var root := Node3D.new()
	var panel := CSGBox3D.new()
	panel.size = Vector3(1.8, 2.4, 0.15)
	panel.position = Vector3(0, 1.3, 0)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(color, 0.35)
	mat.emission_enabled = true
	mat.emission = color
	mat.emission_energy_multiplier = 1.8
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	panel.material = mat
	root.add_child(panel)

	var frame := CSGTorus3D.new()
	frame.inner_radius = 1.0
	frame.outer_radius = 1.12
	frame.position = Vector3(0, 1.3, 0)
	var frame_mat := StandardMaterial3D.new()
	frame_mat.emission_enabled = true
	frame_mat.emission = color
	frame_mat.emission_energy_multiplier = 2.5
	frame_mat.albedo_color = color
	frame.material = frame_mat
	root.add_child(frame)

	var label := Label3D.new()
	label.text = text
	label.font_size = 72
	label.position = Vector3(0, 1.3, 0.2)
	label.modulate = Color(1, 1, 1)
	label.outline_size = 14
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	root.add_child(label)
	return root

func _make_barrier_visual() -> Node3D:
	var root := Node3D.new()
	var beam := CSGBox3D.new()
	beam.size = Vector3(1.9, 2.6, 0.3)
	beam.position = Vector3(0, 1.3, 0)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(1.0, 0.15, 0.25, 0.85)
	mat.emission_enabled = true
	mat.emission = Color(1.0, 0.1, 0.2)
	mat.emission_energy_multiplier = 2.2
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	beam.material = mat
	root.add_child(beam)
	return root

func _make_crystal_visual() -> Node3D:
	var crystal := CSGSphere3D.new()
	crystal.radius = 0.32
	crystal.radial_segments = 8
	crystal.rings = 6
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.5, 0.95, 1.0)
	mat.emission_enabled = true
	mat.emission = Color(0.5, 0.95, 1.0)
	mat.emission_energy_multiplier = 2.0
	crystal.material = mat
	return crystal
