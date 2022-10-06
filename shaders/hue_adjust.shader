shader_type canvas_item;

uniform float hue = 0.0;
uniform float saturation = 1.0;
uniform float value = 1.0;

vec3 rgb2hsb(vec3 c) {
	vec4 K = vec4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
	vec4 p = mix(
		vec4(c.bg, K.wz),
		vec4(c.gb, K.xy),
		step(c.b, c.g)
	);
	vec4 q = mix(
		vec4(p.xyw, c.r),
		vec4(c.r, p.yzx),
		step(p.x, c.r)
	);
	float d = q.x - min(q.w, q.y);
	float e = 1.0e-10;
	return vec3(
		abs(q.z + (q.w - q.y) / (6.0 * d + e)),
		d / (q.x + e),
		q.x
	);
}

vec3 hsb2rgb(vec3 c) {
	vec3 rgb = clamp(abs(mod(
		c.x*6.0+vec3(0.0,4.0,2.0),
		6.0)-3.0)-1.0,
		0.0,
		1.0
	);
	rgb = rgb * rgb * (3.0 - 2.0 * rgb);
	return c.z * mix(vec3(1.0), rgb, c.y);
}

void fragment() {
	COLOR = texture(TEXTURE, UV);
	
	vec3 hsv = rgb2hsb(vec3(COLOR.r, COLOR.g, COLOR.b));
	hsv[0] = hue;
	hsv[1] *= saturation;
	hsv[2] *= value;
	vec3 rgb = hsb2rgb(hsv);
	
	COLOR.r = rgb[0];
	COLOR.g = rgb[1];
	COLOR.b = rgb[2];
}
