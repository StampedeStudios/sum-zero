shader_type canvas_item;

uniform float percentage = 0.0;

void fragment() {
    if (UV.x > percentage) {
        discard;
    }
}
