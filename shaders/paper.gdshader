shader_type canvas_item;
// A flat colour painted in watercolour on paper: soft blotches where the
// pigment pooled, darker rims round them, and the tooth of the paper.
// Works in the drawing's own pixels, so the same wall looks the same
// wherever the room stands.

uniform vec4 base : source_color = vec4(0.91, 0.83, 0.66, 1.0);
uniform vec4 stain : source_color = vec4(0.78, 0.64, 0.43, 1.0);
uniform float blotch = 240.0;
uniform float amount : hint_range(0.0, 1.0) = 0.6;
uniform float seed = 0.0;

varying vec2 p;

void vertex() {
	p = VERTEX;
}

float hash(vec2 q) {
	q = fract(q * vec2(123.34, 456.21));
	q += dot(q, q + 45.32);
	return fract(q.x * q.y);
}

float noise(vec2 q) {
	vec2 i = floor(q);
	vec2 f = fract(q);
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), u.x),
			mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), u.x), u.y);
}

float fbm(vec2 q) {
	float v = 0.0;
	float a = 0.55;
	for (int i = 0; i < 4; i++) {
		v += a * noise(q);
		q = q * 2.03 + vec2(17.1, 9.2);
		a *= 0.5;
	}
	return v;
}

void fragment() {
	vec2 q = p / blotch + vec2(seed * 13.7, seed * 7.1);
	float n = fbm(q);
	float pool = smoothstep(0.42, 0.72, n);
	vec3 c = mix(base.rgb, stain.rgb, pool * amount);
	// Pigment gathers at the edge of a wash and dries darker there.
	float rim = 1.0 - smoothstep(0.0, 0.035, abs(n - 0.55));
	c *= 1.0 - rim * 0.1 * amount;
	// Paper tooth: fine and faint.
	c *= 0.965 + 0.05 * noise(p * 0.55) + 0.02 * noise(p * 2.1);
	COLOR = vec4(c, base.a) * COLOR;
}
