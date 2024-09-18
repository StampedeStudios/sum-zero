shader_type canvas_item;

uniform vec4 base_color = vec4(1.0);

void fragment() {
    vec4 tex_color = texture(TEXTURE, UV);
    COLOR = vec4(base_color.rgb, tex_color.a);
}
