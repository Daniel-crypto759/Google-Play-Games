extends Node
class_name UIFactory
## Shared "neon alien mining rig" UI look-and-feel so every screen matches.

const BG_TOP := Color(0.06, 0.03, 0.12)
const BG_BOTTOM := Color(0.01, 0.01, 0.04)
const ACCENT := Color(0.35, 0.9, 1.0)
const ACCENT_2 := Color(0.75, 0.3, 1.0)
const WARN := Color(1.0, 0.35, 0.45)
const GOOD := Color(0.55, 1.0, 0.35)
const PANEL := Color(0.09, 0.07, 0.18, 0.92)

static func make_background(parent: Control) -> void:
	var rect := ColorRect.new()
	rect.color = BG_BOTTOM
	rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(rect)
	var grad := GradientTexture2D.new()
	var g := Gradient.new()
	g.set_color(0, BG_TOP)
	g.set_color(1, BG_BOTTOM)
	grad.gradient = g
	grad.fill_from = Vector2(0.5, 0)
	grad.fill_to = Vector2(0.5, 1)
	var tex_rect := TextureRect.new()
	tex_rect.texture = grad
	tex_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	tex_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(tex_rect)

static func style_button(btn: Button, base: Color = ACCENT) -> void:
	btn.custom_minimum_size = Vector2(0, 96)
	btn.add_theme_font_size_override("font_size", 34)
	btn.add_theme_color_override("font_color", Color(0.03, 0.02, 0.06))
	btn.add_theme_color_override("font_hover_color", Color(0.03, 0.02, 0.06))
	btn.add_theme_color_override("font_pressed_color", Color(0.03, 0.02, 0.06))

	var normal := StyleBoxFlat.new()
	normal.bg_color = base
	normal.set_corner_radius_all(20)
	normal.shadow_color = Color(base.r, base.g, base.b, 0.45)
	normal.shadow_size = 14
	btn.add_theme_stylebox_override("normal", normal)

	var hover := StyleBoxFlat.new()
	hover.bg_color = base.lightened(0.15)
	hover.set_corner_radius_all(20)
	hover.shadow_color = Color(base.r, base.g, base.b, 0.6)
	hover.shadow_size = 18
	btn.add_theme_stylebox_override("hover", hover)

	var pressed := StyleBoxFlat.new()
	pressed.bg_color = base.darkened(0.2)
	pressed.set_corner_radius_all(20)
	btn.add_theme_stylebox_override("pressed", pressed)

	var disabled := StyleBoxFlat.new()
	disabled.bg_color = Color(0.25, 0.25, 0.3, 0.6)
	disabled.set_corner_radius_all(20)
	btn.add_theme_stylebox_override("disabled", disabled)
	btn.add_theme_color_override("font_disabled_color", Color(0.6, 0.6, 0.65))

static func make_button(text: String, base: Color = ACCENT) -> Button:
	var btn := Button.new()
	btn.text = text
	style_button(btn, base)
	return btn

static func make_panel(color: Color = PANEL) -> PanelContainer:
	var panel := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = color
	sb.set_corner_radius_all(28)
	sb.set_border_width_all(2)
	sb.border_color = Color(ACCENT.r, ACCENT.g, ACCENT.b, 0.5)
	sb.content_margin_left = 28
	sb.content_margin_right = 28
	sb.content_margin_top = 24
	sb.content_margin_bottom = 24
	panel.add_theme_stylebox_override("panel", sb)
	return panel

static func make_label(text: String, size: int = 28, color: Color = Color(1, 1, 1)) -> Label:
	var lbl := Label.new()
	lbl.text = text
	lbl.add_theme_font_size_override("font_size", size)
	lbl.add_theme_color_override("font_color", color)
	return lbl

static func make_title(text: String) -> Label:
	var lbl := make_label(text, 64, ACCENT)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.add_theme_color_override("font_shadow_color", Color(ACCENT_2.r, ACCENT_2.g, ACCENT_2.b, 0.6))
	lbl.add_theme_constant_override("shadow_offset_x", 0)
	lbl.add_theme_constant_override("shadow_offset_y", 4)
	return lbl
