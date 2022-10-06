// "FlipTri" anti-aliasing
// https://blog.demofox.org/2015/04/23/flipquad-fliptri-antialiasing/

shader_type canvas_item;

void fragment() {
	bool x_odd = (floor(mod(SCREEN_UV.x / SCREEN_PIXEL_SIZE.x, 2.0)) == 1.0);
	bool y_odd = (floor(mod(SCREEN_UV.y / SCREEN_PIXEL_SIZE.y, 2.0)) == 1.0);
	
	vec2 a = vec2(x_odd ? -0.5 : 0.5, y_odd ? -0.5 : 0.5);
	vec2 b = vec2(0.0, y_odd ? 0.5 : -0.5);
	vec2 c = vec2(x_odd ? 0.5 : -0.5, 0.0);
	
	COLOR = (
		texture(SCREEN_TEXTURE, (SCREEN_UV / SCREEN_PIXEL_SIZE + a) * SCREEN_PIXEL_SIZE) * 0.2 +
		texture(SCREEN_TEXTURE, (SCREEN_UV / SCREEN_PIXEL_SIZE + b) * SCREEN_PIXEL_SIZE) * 0.4 +
		texture(SCREEN_TEXTURE, (SCREEN_UV / SCREEN_PIXEL_SIZE + c) * SCREEN_PIXEL_SIZE) * 0.4
	);
}
