extends Control

func _ready():
	# Papyrus style for the StyleBox
	var papyrus_style = StyleBoxFlat.new()
	papyrus_style.bg_color = Color(0.95, 0.9, 0.7, 1.0)
	papyrus_style.border_width_left = 5
	papyrus_style.border_width_top = 5
	papyrus_style.border_width_right = 5
	papyrus_style.border_width_bottom = 5
	papyrus_style.border_color = Color(0.85, 0.75, 0.55, 1.0)
	papyrus_style.corner_radius_top_left = 8
	papyrus_style.corner_radius_top_right = 8
	papyrus_style.corner_radius_bottom_left = 8
	papyrus_style.corner_radius_bottom_right = 8
	papyrus_style.shadow_color = Color(0.0, 0.0, 0.0, 0.3)
	papyrus_style.shadow_size = 5
	papyrus_style.shadow_offset = Vector2(3, 3)
	
	$DialogBox.add_theme_stylebox_override("panel", papyrus_style)
	
	# Create left cap style
	var left_style = StyleBoxFlat.new()
	left_style.bg_color = Color(0.85, 0.75, 0.55, 1.0)
	left_style.corner_radius_top_left = 10
	left_style.corner_radius_bottom_left = 10
	
	$LeftCap.add_theme_stylebox_override("panel", left_style)
	
	# Create right cap style
	var right_style = StyleBoxFlat.new()
	right_style.bg_color = Color(0.85, 0.75, 0.55, 1.0)
	right_style.corner_radius_top_right = 10
	right_style.corner_radius_bottom_right = 10
	
	$RightCap.add_theme_stylebox_override("panel", right_style)
