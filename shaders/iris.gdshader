shader_type canvas_item;
// The iris: black everywhere but a circle, closing down on something the way
// an old cartoon ended. Drawn on a rectangle covering the screen; `center` is
// in that rectangle's UV, `radius` in screen heights.

uniform vec2 center = vec2(0.5, 0.5);
uniform float radius = 2.0;
uniform float aspect = 1.7777778;

void fragment() {
	vec2 d = (UV - center) * vec2(aspect, 1.0);
	float r = length(d);
	// A hard edge with a pixel or so of softening, like a real iris blade.
	float outside = smoothstep(radius - 0.0015, radius + 0.0015, r);
	COLOR = vec4(0.07, 0.05, 0.04, outside);
}
