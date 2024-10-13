shader_type canvas_item;

uniform vec4 baseColor: source_color = vec4(1.0);
uniform vec4 fillColor: source_color = vec4(1.0);
uniform float percentage = 0.0;

void fragment() {

    if (UV.x > percentage) {
        COLOR = texture(TEXTURE, UV) * baseColor;
    } else {
        COLOR = texture(TEXTURE, UV) * fillColor;
    }

}

