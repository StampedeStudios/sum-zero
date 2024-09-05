shader_type canvas_item;

uniform vec4 color = vec4(1, 1, 1, 1);

uniform bool is_top = false;
uniform bool is_right = false;
uniform bool is_bottom = false;
uniform bool is_left = false;

void fragment() {

    if (!is_top && UV.y < 0.1) {
        discard;
    } 
    if (!is_right && UV.x > 0.9) {
        discard;
    } 
    if (!is_bottom && UV.y > 0.9) {
        discard;
    }
    if (!is_left && UV.x < 0.1) {
        discard;
    }
    COLOR = texture(TEXTURE, UV) * color;
}

