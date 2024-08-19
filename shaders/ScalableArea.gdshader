shader_type canvas_item;

uniform vec4 base_color = vec4(1.0);
uniform bool is_hovered = false;
uniform float glow_intensity = 1.0;
uniform float hover_glow_multiplier = 2.0;

void fragment() {
    vec4 color = texture(TEXTURE, UV);

    // Adjust the glow intensity based on whether the sprite is hovered
    float final_glow_intensity = is_hovered ? glow_intensity * hover_glow_multiplier : glow_intensity;

    // Apply the glow effect
    vec4 glow_color = color * final_glow_intensity;

    // Combine the base color and glow effect
    COLOR = glow_color * base_color;
}
