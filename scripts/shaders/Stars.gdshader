shader_type canvas_item;

uniform vec4 base_color: source_color = vec4(1.0);
uniform float progress: hint_range(0.0, 1.0);

void fragment() {
    vec4 tex = texture(TEXTURE, UV);

    vec3 blended_rgb = mix(tex.rgb, base_color.rgb, progress);
    COLOR = vec4(blended_rgb, tex.a);
}
