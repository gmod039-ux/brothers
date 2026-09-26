shader_type canvas_item;
// The painted background of a room: its floor or one of its four walls, the
// way the backgrounds of 1930s cartoons were painted -- no ink, just
// watercolour over a careful drawing, lit from inside the room.
//
// The floor is laid in one of several patterns (square tiles, concrete
// slabs, flagstones, a boxing mat, iron plate, carpet); a wall is a face in
// perspective (brick, riveted steel, rough stone, damask) with a stone cap
// along its top. Each stone gets its own shade and a bevel: lit on the side
// towards the lamps, dark on the far side. Then the room's lights are laid
// over it all, warm pools round the lamps and dark corners away from them.
//
// Works in the room's own pixels (the polygon's vertices), so the same room
// looks the same wherever it stands in the world.

// 0 floor, 1 wall.
uniform int part = 0;
// Floor: 0 tiles, 1 slabs, 2 flagstones, 3 mat, 4 iron plate, 5 carpet.
// Wall: 0 brick, 1 steel panels, 2 rough stone, 3 damask.
uniform int pattern = 0;
uniform vec4 base : source_color = vec4(0.85, 0.72, 0.54, 1.0);
uniform vec4 stain : source_color = vec4(0.72, 0.55, 0.36, 1.0);
uniform vec4 grout : source_color = vec4(0.35, 0.23, 0.14, 1.0);
uniform vec4 cap : source_color = vec4(0.79, 0.64, 0.48, 1.0);
uniform vec4 trim : source_color = vec4(0.91, 0.72, 0.23, 1.0);
uniform float seed = 0.0;
uniform float tile = 112.0;
uniform vec2 floor_origin = vec2(232.0, 148.0);
uniform vec2 floor_size = vec2(1456.0, 784.0);

// A wall's corners: outer edge left to right as seen from the floor, then
// the floor edge right to left -- the order Room.faces() gives them.
uniform vec2 q0;
uniform vec2 q1;
uniform vec2 q2;
uniform vec2 q3;
// Courses of stone from the top of the wall down to the floor.
uniform float rows = 4.0;

// Light: a flat share everywhere, and up to eight lamps.
uniform float ambient = 0.78;
uniform int light_count = 0;
uniform vec3 lights[8];      // x, y, radius
uniform vec4 light_colors[8]; // rgb, strength

// A painted texture instead of a drawn pattern: laid flat on a floor,
// [tex_world] pixels to one repeat; on a wall in courses, [tex_rows]
// courses of stone to one repeat of the picture.
uniform bool textured = false;
uniform sampler2D albedo : source_color, repeat_enable, filter_linear_mipmap;
uniform float tex_world = 600.0;
uniform float tex_rows = 9.0;
// How far the picture's colours are pulled towards the floor's own palette,
// so every texture sits in the same faded 1930s world.
uniform float tex_tint = 0.3;
uniform float tex_desat = 0.25;
// Floors are lifted a little: black-and-white brothers must stand out on them.
uniform float tex_gain = 1.0;

varying vec2 p;

void vertex() {
	p = VERTEX;
}

float hash(vec2 q) {
	q = fract(q * vec2(123.34, 456.21) + seed * 0.013);
	q += dot(q, q + 45.32);
	return fract(q.x * q.y);
}

vec2 hash2(vec2 q) {
	return vec2(hash(q), hash(q + vec2(19.19, 7.73)));
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

float cross2(vec2 a, vec2 b) {
	return a.x * b.y - a.y * b.x;
}

// Where p sits in the quad a b c d, as (u, v) in 0..1: u along the wall,
// v from its top (0) down to the floor (1). Inigo Quilez's inverse
// bilinear map, exact for any four-sided face.
vec2 face_uv(vec2 x, vec2 a, vec2 b, vec2 c, vec2 d) {
	vec2 e = b - a;
	vec2 f = d - a;
	vec2 g = a - b + c - d;
	vec2 h = x - a;
	float k2 = cross2(g, f);
	float k1 = cross2(e, f) + cross2(h, g);
	float k0 = cross2(h, e);
	float v;
	if (abs(k2) < 0.001) {
		v = -k0 / k1;
	} else {
		float w = sqrt(max(k1 * k1 - 4.0 * k0 * k2, 0.0));
		v = (-k1 - w) / (2.0 * k2);
		if (v < -0.01 || v > 1.01) {
			v = (-k1 + w) / (2.0 * k2);
		}
	}
	vec2 den = e + g * v;
	float u = abs(den.x) > abs(den.y) ? (h.x - f.x * v) / den.x : (h.y - f.y * v) / den.y;
	return vec2(u, v);
}

// Signed distance to the edge of a box of half-size b with corners rounded
// by r: negative inside.
float round_box(vec2 x, vec2 b, float r) {
	vec2 q = abs(x) - b + r;
	return length(max(q, 0.0)) + min(max(q.x, q.y), 0.0) - r;
}

// A stone of a paved or built surface: [depth] is how far inside its edge
// the point is, in pixels (negative in the joint). Returns the light the
// bevel catches: > 0 on the edge facing the lamps, < 0 on the far one.
float bevel(float depth, float width) {
	vec2 grad = vec2(dFdx(depth), dFdy(depth));
	float len = length(grad);
	if (len < 0.0001) {
		return 0.0;
	}
	// Outward is down the slope; the light comes from above and to the left.
	vec2 outward = -grad / len;
	float facing = dot(outward, normalize(vec2(-0.55, -0.85)));
	float edge = 1.0 - smoothstep(0.0, width, depth);
	return facing * edge * step(0.0, depth);
}

// Watercolour: pools of pigment, a darker rim where they dried, the tooth
// of the paper.
vec3 wash(vec3 c, vec2 x, float blotch, float amount) {
	float n = fbm(x / blotch + vec2(seed * 13.7, seed * 7.1));
	float pool = smoothstep(0.45, 0.75, n);
	c = mix(c, stain.rgb, pool * amount);
	float rim = 1.0 - smoothstep(0.0, 0.03, abs(n - 0.58));
	c *= 1.0 - rim * 0.08 * amount;
	c *= 0.965 + 0.05 * noise(x * 0.55) + 0.02 * noise(x * 2.1);
	return c;
}

// One stone's own colour: a little lighter or darker than its neighbours,
// now and then leaning towards the stain.
vec3 stone_tone(vec2 id, float spread) {
	float h = hash(id);
	vec3 c = base.rgb * (1.0 - spread * 0.5 + spread * h);
	c = mix(c, stain.rgb, step(0.82, hash(id + 3.7)) * 0.45);
	return c;
}

// --- floors -------------------------------------------------------------

// A hand-laid grid: the joints wander a little, so it does not look ruled.
vec2 wobble(vec2 x, float amount) {
	return x + (vec2(noise(x * 0.013), noise(x * 0.013 + 7.3)) - 0.5) * amount;
}

vec3 floor_tiles(vec2 x, float size, vec2 aspect, bool stagger, float spread) {
	vec2 w = wobble(x, 7.0);
	vec2 cell_size = vec2(size) * aspect;
	float row = floor(w.y / cell_size.y);
	if (stagger && mod(row, 2.0) > 0.5) {
		w.x += cell_size.x * 0.5;
	}
	vec2 id = floor(w / cell_size);
	vec2 f = w - (id + 0.5) * cell_size;
	float joint = 3.5;
	float d = -round_box(f, cell_size * 0.5 - joint, 7.0);
	vec3 c = stone_tone(id, spread);
	// Worn spots and chips in the stone.
	c *= 0.94 + 0.08 * noise(x * 0.07 + id * 3.0);
	float lit = bevel(d, 9.0);
	c *= 1.0 + lit * 0.32;
	// Joints are dark; a soft shadow creeps a few pixels onto each stone.
	c = mix(c, c * 0.8, 1.0 - smoothstep(0.0, 5.0, d));
	return mix(grout.rgb, c, smoothstep(-0.8, 0.8, d));
}

// Poured concrete in big square slabs: speckled, with a darker skin of
// oil and soot here and there, and a steel plate let into some of them.
vec3 slabs(vec2 x) {
	vec2 w = wobble(x, 4.0);
	vec2 size = vec2(tile * 2.0);
	vec2 id = floor(w / size);
	vec2 f = w - (id + 0.5) * size;
	float d = -round_box(f, size * 0.5 - 2.5, 4.0);
	vec3 c = stone_tone(id, 0.12);
	// Aggregate: small light and dark specks.
	float speck = noise(x * 0.45);
	c *= 1.0 + (step(0.82, speck) * 0.08 - step(speck, 0.12) * 0.07);
	c *= 0.95 + 0.07 * noise(x * 0.05 + id * 4.0);
	// A sawn expansion line across the middle of every slab.
	float saw = min(abs(f.x), abs(f.y));
	c *= 1.0 - (1.0 - smoothstep(0.6, 1.6, saw)) * 0.18 * step(0.5, hash(id + 1.3));
	float lit = bevel(d, 5.0);
	c *= 1.0 + lit * 0.25;
	c = mix(c, c * 0.85, 1.0 - smoothstep(0.0, 4.0, d));
	return mix(grout.rgb, c, smoothstep(-0.8, 0.8, d));
}

vec3 flagstones(vec2 x) {
	vec2 w = wobble(x, 10.0);
	float size = 118.0;
	vec2 g = w / size;
	vec2 i = floor(g);
	vec2 fr = fract(g);
	// Voronoi: the nearest seed makes the stone, the gap to the next one
	// is the joint.
	vec2 nearest_id = vec2(0.0);
	vec2 nearest = vec2(0.0);
	float best = 8.0;
	for (int y = -1; y <= 1; y++) {
		for (int xx = -1; xx <= 1; xx++) {
			vec2 o = vec2(float(xx), float(y));
			vec2 r = o + 0.15 + 0.7 * hash2(i + o) - fr;
			float dd = dot(r, r);
			if (dd < best) {
				best = dd;
				nearest = r;
				nearest_id = i + o;
			}
		}
	}
	float edge = 8.0;
	for (int y = -2; y <= 2; y++) {
		for (int xx = -2; xx <= 2; xx++) {
			vec2 o = vec2(float(xx), float(y));
			vec2 r = o + 0.15 + 0.7 * hash2(i + o) - fr;
			vec2 diff = r - nearest;
			if (dot(diff, diff) > 0.0001) {
				edge = min(edge, dot(0.5 * (nearest + r), normalize(diff)));
			}
		}
	}
	float d = edge * size - 3.5;
	vec3 c = stone_tone(nearest_id, 0.22);
	c *= 0.93 + 0.1 * noise(x * 0.06 + nearest_id * 5.0);
	// Moss in the joints.
	float moss = smoothstep(0.55, 0.8, noise(x * 0.012 + 3.0)) * (1.0 - smoothstep(0.0, 9.0, d));
	float lit = bevel(d, 11.0);
	c *= 1.0 + lit * 0.34;
	c = mix(c, c * 0.8, 1.0 - smoothstep(0.0, 6.0, d));
	vec3 joint = mix(grout.rgb, vec3(0.3, 0.42, 0.2), moss * 0.8);
	return mix(joint, c, smoothstep(-0.8, 0.8, d));
}

vec3 ring_mat(vec2 x) {
	// Canvas: a fine weave, a darker apron round the edge.
	float weave = 0.5 + 0.25 * sin(x.x * 1.3) * sin(x.y * 1.3) + 0.25 * sin((x.x + x.y) * 0.9);
	vec3 c = base.rgb * (0.95 + 0.06 * weave);
	vec2 from_edge = min(x - floor_origin, floor_origin + floor_size - x);
	float apron = 1.0 - smoothstep(34.0, 38.0, min(from_edge.x, from_edge.y));
	c = mix(c, stain.rgb * 0.8, apron);
	return c;
}

vec3 iron(vec2 x) {
	// Plates two tiles wide with riveted seams, a diamond tread pressed in.
	vec2 plate = vec2(tile * 2.0, tile * 1.5);
	vec2 id = floor(x / plate);
	vec2 f = x - (id + 0.5) * plate;
	float d = -round_box(f, plate * 0.5 - 2.5, 3.0);
	vec3 c = base.rgb * (0.92 + 0.12 * hash(id));
	// The tread: little raised bars on the diagonals, lit on one side.
	vec2 t = x / 26.0;
	vec2 tf = fract(t) - 0.5;
	float flip = mod(floor(t.x) + floor(t.y), 2.0) > 0.5 ? 1.0 : -1.0;
	vec2 r = mat2(vec2(0.707, 0.707 * flip), vec2(-0.707 * flip, 0.707)) * tf;
	float bar = round_box(r, vec2(0.28, 0.06), 0.06);
	c *= 1.0 - 0.18 * (1.0 - smoothstep(-0.02, 0.02, bar));
	c *= 1.0 + 0.2 * (1.0 - smoothstep(-0.02, 0.02, round_box(r + vec2(0.0, 0.05), vec2(0.28, 0.02), 0.02)));
	// Rivets along each seam.
	vec2 along = abs(f) - (plate * 0.5 - 12.0);
	vec2 rv = vec2(mod(f.x + 12.0, 28.0) - 14.0, along.y);
	vec2 rh = vec2(along.x, mod(f.y + 12.0, 28.0) - 14.0);
	float rivet = min(length(rv), length(rh));
	c = mix(c, c * 1.35, 1.0 - smoothstep(3.0, 4.5, rivet));
	c = mix(c, c * 0.6, (1.0 - smoothstep(4.5, 6.0, rivet)) * smoothstep(3.0, 4.5, rivet));
	float lit = bevel(d, 6.0);
	c *= 1.0 + lit * 0.4;
	// Rust and soot.
	c = mix(c, vec3(0.45, 0.25, 0.14), smoothstep(0.62, 0.85, fbm(x / 140.0)) * 0.5);
	return mix(grout.rgb, c, smoothstep(-0.8, 0.8, d));
}

vec3 carpet(vec2 x) {
	// A red carpet: a lattice of gold lines with a rosette in each diamond,
	// and a border band round the edge.
	vec2 local = x - floor_origin - floor_size * 0.5;
	vec2 t = mat2(vec2(0.707, 0.707), vec2(-0.707, 0.707)) * local / 110.0;
	vec2 f = fract(t) - 0.5;
	vec3 c = base.rgb;
	float line = min(abs(f.x), abs(f.y));
	c = mix(c, stain.rgb, 1.0 - smoothstep(0.03, 0.05, line));
	c = mix(c, trim.rgb * 0.8, 1.0 - smoothstep(0.012, 0.022, line));
	float rose = length(f);
	c = mix(c, trim.rgb * 0.75, (1.0 - smoothstep(0.09, 0.11, rose)) * smoothstep(0.05, 0.07, rose));
	c = mix(c, stain.rgb * 0.8, 1.0 - smoothstep(0.03, 0.05, rose));
	vec2 from_edge = min(x - floor_origin, floor_origin + floor_size - x);
	float e = min(from_edge.x, from_edge.y);
	float band = 1.0 - smoothstep(58.0, 60.0, e);
	c = mix(c, stain.rgb * 0.75, band);
	c = mix(c, trim.rgb * 0.85, (1.0 - smoothstep(1.5, 3.0, abs(e - 48.0))) + (1.0 - smoothstep(1.0, 2.5, abs(e - 64.0))));
	// The pile: soft streaks.
	c *= 0.95 + 0.08 * noise(vec2(x.x * 0.05, x.y * 0.4));
	return c;
}

// --- walls --------------------------------------------------------------

// A course of stones along the wall: [along] and [down] in pixels on the
// face, [course] the height of one. Stones [length] long, every other
// course shifted half a stone; [vary] makes lengths differ stone to stone.
vec3 courses(vec2 face, float course, float length_, float vary, float joint, float round_, float spread) {
	float row = floor(face.y / course);
	float shift = mod(row, 2.0) * 0.5 + hash(vec2(row, 3.0)) * vary;
	float len_ = length_ * (1.0 + (hash(vec2(row, 9.0)) - 0.5) * vary);
	float col = floor(face.x / len_ + shift);
	vec2 id = vec2(col, row);
	vec2 center = vec2((col + 0.5 - shift) * len_, (row + 0.5) * course);
	vec2 f = face - center;
	vec2 half_ = vec2(len_, course) * 0.5 - joint;
	// Rough stones are lumpy: the edge wanders with noise.
	float lump = (noise(face * 0.08 + id * 7.0) - 0.5) * vary * 10.0;
	float d = -(round_box(f, half_, round_) + lump);
	vec3 c = stone_tone(id, spread);
	c *= 0.93 + 0.09 * noise(face * 0.09 + id * 2.0);
	float lit = bevel(d, 7.0);
	c *= 1.0 + lit * 0.4;
	c = mix(c, c * 0.8, 1.0 - smoothstep(0.0, 4.0, d));
	return mix(grout.rgb, c, smoothstep(-0.8, 0.8, d));
}

vec3 steel(vec2 face, float depth) {
	float panel_len = 170.0;
	float col = floor(face.x / panel_len);
	float row = floor(face.y / (depth * 0.5));
	vec2 id = vec2(col, row);
	vec2 center = vec2((col + 0.5) * panel_len, (row + 0.5) * depth * 0.5);
	vec2 f = face - center;
	vec2 half_ = vec2(panel_len, depth * 0.5) * 0.5 - 2.0;
	float d = -round_box(f, half_, 4.0);
	vec3 c = base.rgb * (0.9 + 0.14 * hash(id));
	// Rivets in a row along the top and bottom of each panel.
	float rx = mod(f.x + 14.0, 28.0) - 14.0;
	float ry = abs(f.y) - (half_.y - 8.0);
	float rivet = length(vec2(rx, ry));
	c = mix(c, c * 1.35, 1.0 - smoothstep(2.8, 4.2, rivet));
	c = mix(c, c * 0.55, (1.0 - smoothstep(4.2, 5.5, rivet)) * smoothstep(2.8, 4.2, rivet) * step(0.0, f.y + 2.0));
	float lit = bevel(d, 6.0);
	c *= 1.0 + lit * 0.45;
	// Rust running down from the rivets.
	float streak = smoothstep(0.6, 0.9, noise(vec2(face.x * 0.12, face.y * 0.012)));
	c = mix(c, vec3(0.5, 0.28, 0.15), streak * 0.45);
	return mix(grout.rgb, c, smoothstep(-0.8, 0.8, d));
}

vec3 damask(vec2 face) {
	// Striped wallpaper with a small diamond in the broad stripes.
	float stripe = mod(face.x, 60.0);
	vec3 c = stripe < 38.0 ? base.rgb : stain.rgb;
	c = mix(c, trim.rgb * 0.7, 1.0 - smoothstep(1.0, 2.0, abs(stripe - 40.0)));
	vec2 m = vec2(stripe - 19.0, mod(face.y, 36.0) - 18.0);
	float diamond = abs(m.x) / 9.0 + abs(m.y) / 13.0;
	c = mix(c, stain.rgb, (1.0 - smoothstep(0.9, 1.05, diamond)) * step(stripe, 38.0));
	c *= 0.95 + 0.06 * noise(face * 0.3);
	return c;
}

// A texel of the picture, its colours brought into the room's palette:
// some of its colour taken out, and the rest leaned towards [base].
vec3 tone(vec3 t) {
	float l = dot(t, vec3(0.299, 0.587, 0.114));
	t = mix(t, vec3(l), tex_desat);
	float lb = max(dot(base.rgb, vec3(0.299, 0.587, 0.114)), 0.01);
	vec3 tinted = base.rgb * (l / lb);
	return min(mix(t, tinted, tex_tint) * tex_gain, vec3(1.0));
}

// --- light --------------------------------------------------------------

vec3 light_at(vec2 x) {
	vec3 l = vec3(ambient);
	for (int i = 0; i < 8; i++) {
		if (i >= light_count) {
			break;
		}
		vec3 light = lights[i];
		// Light pools are flattened ellipses: the floor is seen at a slant.
		vec2 d = (x - light.xy) / vec2(1.0, 0.72);
		float k = 1.0 - smoothstep(0.0, light.z, length(d));
		l += light_colors[i].rgb * light_colors[i].a * k * k;
	}
	return l;
}

void fragment() {
	vec3 c;
	if (part == 0) {
		vec2 fl = p - floor_origin;
		if (textured) {
			c = tone(texture(albedo, fl / tex_world).rgb);
		} else if (pattern == 1) {
			c = slabs(fl);
		} else if (pattern == 2) {
			c = flagstones(p);
		} else if (pattern == 3) {
			c = ring_mat(p);
		} else if (pattern == 4) {
			c = iron(fl);
		} else if (pattern == 5) {
			c = carpet(p);
		} else {
			c = floor_tiles(fl, tile, vec2(1.0), false, 0.16);
		}
		c = wash(c, p, 260.0, textured ? 0.18 : (pattern == 5 ? 0.15 : 0.3));
		// The walls' shadow on the floor round its edge, deeper under the tall
		// back wall.
		vec2 near = p - floor_origin;
		vec2 far_ = floor_origin + floor_size - p;
		float shadow = (1.0 - smoothstep(0.0, 110.0, near.y)) * 0.5
				+ (1.0 - smoothstep(0.0, 60.0, near.x)) * 0.32
				+ (1.0 - smoothstep(0.0, 60.0, far_.x)) * 0.32
				+ (1.0 - smoothstep(0.0, 44.0, far_.y)) * 0.22;
		c *= 1.0 - min(shadow, 0.6);
	} else {
		vec2 uv = face_uv(p, q0, q1, q2, q3);
		float along = length(q2 - q3);
		float depth = length(mix(q0, q1, 0.5) - mix(q3, q2, 0.5));
		// Along the wall in floor-edge pixels, so every course has the same
		// number of stones and they close up into the corners.
		vec2 face = vec2(uv.x * along, uv.y * depth);
		float cap_v = 0.16;
		if (uv.y < cap_v) {
			// The cap: a band of dressed stone along the top of the wall.
			vec2 f = vec2(face.x, uv.y / cap_v * 24.0);
			float seg = 140.0;
			float col = floor(f.x / seg);
			float d = -round_box(vec2(f.x - (col + 0.5) * seg, f.y - 12.0), vec2(seg * 0.5 - 2.0, 10.0), 3.0);
			c = cap.rgb * (0.92 + 0.12 * hash(vec2(col, 41.0)));
			c *= 1.0 + bevel(d, 5.0) * 0.4;
			c = mix(grout.rgb, c, smoothstep(-0.8, 0.8, d));
			c = wash(c, face, 180.0, 0.2);
		} else {
			vec2 below = vec2(face.x, face.y - cap_v * depth);
			float course = (depth * (1.0 - cap_v)) / rows;
			if (textured) {
				float repeat = course * tex_rows;
				c = tone(texture(albedo, below / repeat).rgb);
			} else if (pattern == 1) {
				c = steel(below, depth * (1.0 - cap_v));
			} else if (pattern == 2) {
				c = courses(below, course, 78.0, 0.55, 3.5, 9.0, 0.22);
			} else if (pattern == 3) {
				c = damask(below);
			} else {
				c = courses(below, course, 86.0, 0.0, 2.5, 3.0, 0.2);
			}
			c = wash(c, face, 180.0, textured ? 0.2 : 0.35);
			// The cap overhangs a little: a line of shadow under it.
			float under = uv.y - cap_v;
			c *= 1.0 - (1.0 - smoothstep(0.0, 0.07, under)) * 0.35;
			// And the wall darkens down into the corner with the floor.
			c *= 1.0 - smoothstep(0.7, 1.0, uv.y) * 0.25;
		}
	}
	c *= light_at(p);
	COLOR = vec4(c, 1.0) * COLOR;
}
