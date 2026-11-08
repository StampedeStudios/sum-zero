@tool
## Logo geometry is shared; animation and startup remain runtime-only.
extends Control


func _ready() -> void:
	resized.connect(layout_logo)
	layout_logo.call_deferred()
	if Engine.is_editor_hint():
		$SplashTop.frame = 16
		$SplashBottom.frame = 16


func layout_logo() -> void:
	var top := $SplashTop as AnimatedSprite2D
	var bottom := $SplashBottom as AnimatedSprite2D
	var top_size := top.sprite_frames.get_frame_texture("default", 0).get_size()
	var bottom_size := bottom.sprite_frames.get_frame_texture("default", 0).get_size()
	var extent := Vector2(maxf(top_size.x, bottom_size.x), top_size.y + bottom_size.y)
	var available := (size - Vector2.ONE * 16).max(Vector2.ONE)
	var fit := minf(minf(available.x / extent.x, available.y / extent.y), get_theme_constant("maximum_logo_width") / extent.x)
	top.scale = Vector2.ONE * fit
	bottom.scale = Vector2.ONE * fit
	top.position = size / 2 - Vector2(0, bottom_size.y * fit / 2)
	bottom.position = size / 2 + Vector2(0, top_size.y * fit / 2)
