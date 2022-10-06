shader_type canvas_item;

uniform vec2 origin = vec2(0.0, 0.0);
uniform float radius = 0.0;

void fragment() {
	float mask = length(UV / TEXTURE_PIXEL_SIZE - origin) >= radius ? 1.0 : 0.0;
	vec4 color = texture(TEXTURE, UV);
	color.a = mask;
	COLOR = color;
}
