shader_type canvas_item;

uniform vec4 base_color: source_color = vec4(1.0);
uniform bool is_selected = false;
uniform float glow_intensity: hint_range(1.0, 10.0, 1.0) = 1.0;

void fragment() {
    vec4 color = texture(TEXTURE, UV);

    // Combine the base color and glow effect
    float current_glow = 1.0;
    if (is_selected) {
        current_glow = glow_intensity;
    }

    COLOR = color * current_glow * base_color;
}
