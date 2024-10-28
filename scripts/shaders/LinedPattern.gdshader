shader_type canvas_item;

uniform float speed : hint_range(-1, 1);

void fragment() {
    // Sample the texture with the animated UV coordinates.
    COLOR = texture(TEXTURE, vec2(UV.x + TIME * speed, UV.y));
}
