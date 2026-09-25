shader_type canvas_item;
// Old film over the whole picture: warm faded grading, grain that changes 24
// times a second, a vignette, flicker, and the odd scratch and speck of dust.
// Everything scales with `strength`, so 0 is the clean picture and 1 is the
// full effect.

uniform sampler2D screen : hint_screen_texture, filter_linear_mipmap;
uniform float strength : hint_range(0.0, 1.5) = 1.0;
// The film frame number, set 24 times a second from outside: grain and dust
// hold still for a frame the way they do on a real projector.
uniform float film_frame = 0.0;
uniform float tint : hint_range(0.0, 1.0) = 0.3;
uniform float fade : hint_range(0.0, 1.0) = 0.55;
uniform float grain : hint_range(0.0, 0.3) = 0.075;
uniform float vignette : hint_range(0.0, 1.5) = 0.75;
uniform float flicker : hint_range(0.0, 0.2) = 0.035;
uniform float scratches : hint_range(0.0, 1.0) = 0.6;
uniform float dust : hint_range(0.0, 1.0) = 0.7;

// Dave Hoskins' hash without sine: no visible pattern at any scale.
float hash(vec2 p) {
	vec3 p3 = fract(vec3(p.xyx) * 0.1031);
	p3 += dot(p3, p3.yzx + 33.33);
	return fract((p3.x + p3.y) * p3.z);
}

float hash1(float x) {
	return hash(vec2(x, x * 1.618 + 0.5));
}

void fragment() {
	vec3 c = texture(screen, SCREEN_UV).rgb;
	float s = strength;
	// Grain and dust are sized for a 1080-line picture, so a smaller window
	// shows the same film rather than finer grain.
	vec2 px = SCREEN_UV * vec2(1920.0, 1080.0);
	float f = film_frame;

	// Grading: a warm cast, lifted blacks and softened whites -- print film
	// never reaches true black or true white.
	float luma = dot(c, vec3(0.299, 0.587, 0.114));
	vec3 warm = luma * vec3(1.08, 0.97, 0.80);
	c = mix(c, warm, tint * s);
	c = mix(c, c * 0.88 + vec3(0.075, 0.058, 0.04), fade * s);

	// Flicker: the lamp's brightness wanders from frame to frame.
	c *= 1.0 + (hash1(f) - 0.5) * 2.0 * flicker * s;

	// Grain, in clumps of about 2 pixels of a 1080-line picture, counted in
	// the screen's own pixels: clumps that do not line up with real pixels
	// beat against them into stripes.
	float cell = max(1.0, floor(2.0 / (SCREEN_PIXEL_SIZE.y * 1080.0) + 0.5));
	float g = hash(floor(FRAGCOORD.xy / cell) + vec2(f * 17.0, f * 31.0)) - 0.5;
	c += g * grain * s * (0.6 + 0.8 * luma * (1.0 - luma) * 4.0) * 0.8;

	// Scratches: now and then a thin light line down the whole frame,
	// drifting a little sideways over its length.
	for (int i = 0; i < 2; i++) {
		float seed = f * 3.1 + float(i) * 17.7;
		if (hash1(seed) < 0.55 * scratches) {
			float x = hash1(seed + 1.0) * 1920.0 + sin(px.y * 0.01 + seed) * 3.0;
			float w = 0.8 + hash1(seed + 2.0) * 1.2;
			float line = 1.0 - smoothstep(0.0, w, abs(px.x - x));
			c = mix(c, vec3(0.95, 0.92, 0.84), line * 0.35 * s);
		}
	}

	// Dust: a few dark specks, each for one frame only.
	for (int i = 0; i < 5; i++) {
		float seed = f * 7.3 + float(i) * 5.1;
		if (hash1(seed) < 0.4 * dust) {
			vec2 at = vec2(hash1(seed + 1.0) * 1920.0, hash1(seed + 2.0) * 1080.0);
			vec2 d = (px - at) / vec2(1.0 + hash1(seed + 3.0) * 2.5, 1.0 + hash1(seed + 4.0) * 1.5);
			float speck = 1.0 - smoothstep(1.2, 2.6, length(d) + hash(floor(px)) * 0.8);
			c = mix(c, vec3(0.08, 0.06, 0.05), speck * 0.8 * s);
		}
	}

	// Vignette: the corners of a projected frame are always darker.
	vec2 v = SCREEN_UV - 0.5;
	v.x *= 1.25;
	float edge = smoothstep(0.32, 0.85, length(v));
	c *= 1.0 - edge * vignette * s * 0.75;

	COLOR = vec4(c, 1.0);
}
