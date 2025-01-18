shader_type canvas_item;

uniform float percentage = 0.0;
uniform bool right_to_left = false;

void fragment() {
    // Get the actual screen position of the fragment
    vec2 screen_uv = SCREEN_UV;
    
    if (!right_to_left) {
        // Use SCREEN_UV.x instead of UV.x to get position relative to screen
        if (screen_uv.x > percentage) {
            discard;
        }
    } else {
        if (screen_uv.x < 1.0 - percentage) {
            discard;
        }
    }
}
