shader_type canvas_item;
uniform vec4 base_color: source_color = vec4(1.0);
uniform bool invert_base_color = false;

void fragment() {
    vec4 color = texture(TEXTURE, UV);

    if (invert_base_color) {
        // Create the inverse tinting effect
        // For a light tint (values > 0.5), this creates a dark tint
        // For a dark tint (values < 0.5), this creates a light tint
        vec4 inverted_effect = vec4(1.0) / (base_color + 0.0001); // Avoid division by zero
        COLOR = color * inverted_effect;
    } else {
        // Original tinting behavior
        COLOR = color * base_color;
    }
}
