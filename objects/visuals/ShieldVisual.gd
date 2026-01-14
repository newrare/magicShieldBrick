# reviewed
extends Node2D

var shield_parent   : Node2D
var neon_timer      : float = 0.0
var neon_intensity  : float = 1.0

func _ready():
	shield_parent = get_parent()

func _process(delta):
	neon_timer     += delta * 8.0
	neon_intensity  = 0.7 + sin(neon_timer * 15.0) * 0.3
	queue_redraw()

func _draw():
	# Get shield parameters from parent
	var orbit_radius     = shield_parent.orbit_radius if shield_parent else 200.0
	var shield_thickness = shield_parent.shield_thickness if shield_parent else 15.0
	var active_angle     = shield_parent.active_angle if shield_parent else 0.0
	var active_arc_angle = shield_parent.active_arc_angle if shield_parent else PI / 2
	var bounce_scale     = shield_parent.bounce_scale if shield_parent else 1.0

	# Check if using temporary color
	var base_color = Color(0, 1, 1)  # Default cyan
	if shield_parent and shield_parent.is_using_temporary_color:
		base_color = shield_parent.temporary_color

	# Calculate colors with bounce intensity
	var bounce_intensity    = (bounce_scale - 1.0) * 0.5 + 1.0
	var active_color        = Color(base_color.r, base_color.g, base_color.b, 0.9 * bounce_intensity)
	var active_bright_color = Color(base_color.r * 0.8 + 0.2, base_color.g * 0.8 + 0.2, base_color.b * 0.8 + 0.2, 0.6 * bounce_intensity)
	var outline_color       = Color(base_color.r, base_color.g, base_color.b, 1.0 * bounce_intensity)

	# Calculate shield ring radii with bounce scale
	var inner_radius        = (orbit_radius - shield_thickness / 2) * bounce_scale
	var outer_radius        = (orbit_radius + shield_thickness / 2) * bounce_scale
	var scaled_orbit_radius = orbit_radius * bounce_scale
	var scaled_thickness    = shield_thickness * bounce_scale

	# Calculate arc angles
	var start_angle = active_angle - active_arc_angle / 2
	var end_angle   = active_angle + active_arc_angle / 2

	var points   = []
	var segments = 32

	# Build outer arc points
	for i in range(segments + 1):
		var angle = lerp(start_angle, end_angle, float(i) / segments)
		var point = Vector2(cos(angle), sin(angle)) * outer_radius
		points.append(point)

	# Build inner arc points (reverse order to close polygon)
	for i in range(segments, -1, -1):
		var angle = lerp(start_angle, end_angle, float(i) / segments)
		var point = Vector2(cos(angle), sin(angle)) * inner_radius
		points.append(point)

	# Draw main shield arc
	if points.size() > 0:
		draw_colored_polygon(points, active_color)

		# Draw bright center band for glow effect
		var mid_points    = []
		var mid_thickness = scaled_thickness * 0.3
		var mid_inner     = scaled_orbit_radius - mid_thickness / 2
		var mid_outer     = scaled_orbit_radius + mid_thickness / 2

		for i in range(segments + 1):
			var angle = lerp(start_angle, end_angle, float(i) / segments)
			var point = Vector2(cos(angle), sin(angle)) * mid_outer
			mid_points.append(point)

		for i in range(segments, -1, -1):
			var angle = lerp(start_angle, end_angle, float(i) / segments)
			var point = Vector2(cos(angle), sin(angle)) * mid_inner
			mid_points.append(point)

		if mid_points.size() > 0:
			draw_colored_polygon(mid_points, active_bright_color)

	# Draw outer arc outline
	for i in range(segments):
		var angle1 = lerp(start_angle, end_angle, float(i) / segments)
		var angle2 = lerp(start_angle, end_angle, float(i + 1) / segments)

		var point1 = Vector2(cos(angle1), sin(angle1)) * outer_radius
		var point2 = Vector2(cos(angle2), sin(angle2)) * outer_radius
		draw_line(point1, point2, outline_color, 3.0)

	# Draw inner arc outline
	for i in range(segments):
		var angle1 = lerp(start_angle, end_angle, float(i) / segments)
		var angle2 = lerp(start_angle, end_angle, float(i + 1) / segments)

		var point1 = Vector2(cos(angle1), sin(angle1)) * inner_radius
		var point2 = Vector2(cos(angle2), sin(angle2)) * inner_radius
		draw_line(point1, point2, outline_color, 2.0)

	# Draw rounded end caps
	var end_cap_radius = scaled_thickness / 2
	var start_center   = Vector2(cos(start_angle), sin(start_angle)) * scaled_orbit_radius
	var end_center     = Vector2(cos(end_angle), sin(end_angle)) * scaled_orbit_radius

	draw_circle(start_center, end_cap_radius, active_color)
	draw_circle(end_center, end_cap_radius, active_color)

	draw_arc(start_center, end_cap_radius, 0, TAU, 16, outline_color, 2.0)
	draw_arc(end_center, end_cap_radius, 0, TAU, 16, outline_color, 2.0)

	# Draw neon glow effect
	draw_neon_halo(scaled_orbit_radius, scaled_thickness, start_angle, end_angle, bounce_intensity)



func draw_neon_halo(orbit_radius: float, thickness: float, start_angle: float, end_angle: float, bounce_intensity: float):
	# Neon colors with animated intensity
	var neon_cyan   = Color(0, 1, 1, 0.3 * bounce_intensity * neon_intensity)
	var neon_bright = Color(0, 1, 1, 0.6 * bounce_intensity * neon_intensity)
	var neon_core   = Color(1, 1, 1, 0.4 * bounce_intensity * neon_intensity)

	var segments = 64

	# Calculate halo layer radii
	var inner_radius = orbit_radius - thickness / 2
	var outer_radius = orbit_radius + thickness / 2
	var halo_inner   = inner_radius - 5.0 * bounce_intensity
	var halo_outer   = outer_radius + 8.0 * bounce_intensity
	var glow_outer   = outer_radius + 15.0 * bounce_intensity

	# Layer 1: Outermost soft glow
	var glow_points = []
	for i in range(segments + 1):
		var angle = lerp(start_angle, end_angle, float(i) / segments)
		var point = Vector2(cos(angle), sin(angle)) * glow_outer
		glow_points.append(point)

	for i in range(segments, -1, -1):
		var angle = lerp(start_angle, end_angle, float(i) / segments)
		var point = Vector2(cos(angle), sin(angle)) * (halo_outer + 3.0)
		glow_points.append(point)

	if glow_points.size() > 0:
		draw_colored_polygon(glow_points, Color(0, 1, 1, 0.1 * bounce_intensity * neon_intensity))

	# Layer 2: Outer halo
	var halo_ext_points = []
	for i in range(segments + 1):
		var angle = lerp(start_angle, end_angle, float(i) / segments)
		var point = Vector2(cos(angle), sin(angle)) * halo_outer
		halo_ext_points.append(point)

	for i in range(segments, -1, -1):
		var angle = lerp(start_angle, end_angle, float(i) / segments)
		var point = Vector2(cos(angle), sin(angle)) * outer_radius
		halo_ext_points.append(point)

	if halo_ext_points.size() > 0:
		draw_colored_polygon(halo_ext_points, neon_cyan)

	# Layer 3: Inner halo
	var halo_int_points = []
	for i in range(segments + 1):
		var angle = lerp(start_angle, end_angle, float(i) / segments)
		var point = Vector2(cos(angle), sin(angle)) * inner_radius
		halo_int_points.append(point)

	for i in range(segments, -1, -1):
		var angle = lerp(start_angle, end_angle, float(i) / segments)
		var point = Vector2(cos(angle), sin(angle)) * halo_inner
		halo_int_points.append(point)

	if halo_int_points.size() > 0:
		draw_colored_polygon(halo_int_points, neon_cyan)

	# Draw bright neon lines on arc edges
	for i in range(segments):
		var angle1 = lerp(start_angle, end_angle, float(i) / segments)
		var angle2 = lerp(start_angle, end_angle, float(i + 1) / segments)

		var point1_out = Vector2(cos(angle1), sin(angle1)) * outer_radius
		var point2_out = Vector2(cos(angle2), sin(angle2)) * outer_radius
		draw_line(point1_out, point2_out, neon_bright, 4.0)
		draw_line(point1_out, point2_out, neon_core, 1.5)

		var point1_in = Vector2(cos(angle1), sin(angle1)) * inner_radius
		var point2_in = Vector2(cos(angle2), sin(angle2)) * inner_radius
		draw_line(point1_in, point2_in, neon_bright, 3.0)
		draw_line(point1_in, point2_in, neon_core, 1.0)

	# Pulsating glow on end caps
	var pulse_intensity = 0.8 + sin(neon_timer * 12.0) * 0.2
	var start_center    = Vector2(cos(start_angle), sin(start_angle)) * orbit_radius
	var end_center      = Vector2(cos(end_angle), sin(end_angle)) * orbit_radius
	var cap_radius      = thickness / 2

	draw_circle(start_center, cap_radius + 6.0, Color(0, 1, 1, 0.2 * pulse_intensity * bounce_intensity))
	draw_circle(end_center, cap_radius + 6.0, Color(0, 1, 1, 0.2 * pulse_intensity * bounce_intensity))

	draw_circle(start_center, cap_radius + 2.0, Color(0, 1, 1, 0.4 * pulse_intensity * bounce_intensity))
	draw_circle(end_center, cap_radius + 2.0, Color(0, 1, 1, 0.4 * pulse_intensity * bounce_intensity))
