shader_type canvas_item;

uniform vec4 base_color: source_color = vec4(1.0);
uniform float glow_intensity: hint_range(0.0, 1.0, 0.1) = 1.0;

void fragment() {
    vec4 color = texture(TEXTURE, UV);

    // Adjust the glow intensity based on whether the sprite is hovered
    float final_glow_intensity = glow_intensity;

    // Apply the glow effect
    vec4 glow_color = color * final_glow_intensity;

    // Combine the base color and glow effect
    COLOR = glow_color * base_color;
}
