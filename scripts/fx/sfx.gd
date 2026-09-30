class_name Sfx
extends Node
## Every sound the game makes, and none of them from a file: each is made
## here at start-up out of sine waves and noise, the way a cartoon's sound
## man did it with a slide whistle, a wood block and a bicycle horn. Plips
## for shots, a boing for a hit, a pop and a whistle for a poof, a sad
## trombone for the end.
##
## One of these lives under Main; [method play] from anywhere finds it. In a
## check with no Main, playing is quietly nothing.

const RATE := 22050
const VOICES := 10
## Its own bus, so the settings can turn the sounds and the music apart.
const BUS := "Sounds"

static var bank: Sfx

## name -> AudioStreamWAV
var _sounds := {}
## name -> seconds before it may play again, so twenty shots a second do not
## pile into a roar.
var _gap := {}
var _last := {}
var _players: Array[AudioStreamPlayer] = []
var _next := 0
var _clock := 0.0


static func play(sound: String, volume_db := 0.0, jitter := 0.06) -> void:
	if bank != null:
		bank._play(sound, volume_db, jitter)


func _ready() -> void:
	bank = self
	process_mode = Node.PROCESS_MODE_ALWAYS
	if AudioServer.get_bus_index(BUS) < 0:
		AudioServer.add_bus()
		AudioServer.set_bus_name(AudioServer.bus_count - 1, BUS)
		AudioServer.set_bus_send(AudioServer.bus_count - 1, "Master")
	for i in VOICES:
		var player := AudioStreamPlayer.new()
		player.bus = BUS
		add_child(player)
		_players.append(player)
	_make()


func _exit_tree() -> void:
	if bank == self:
		bank = null


func _process(delta: float) -> void:
	_clock += delta


func _play(sound: String, volume_db: float, jitter: float) -> void:
	var stream: AudioStreamWAV = _sounds.get(sound)
	if stream == null:
		return
	if _clock - float(_last.get(sound, -1.0)) < float(_gap.get(sound, 0.0)):
		return
	_last[sound] = _clock
	var player := _players[_next]
	_next = (_next + 1) % _players.size()
	player.stream = stream
	player.volume_db = volume_db
	player.pitch_scale = 1.0 + randf_range(-jitter, jitter)
	player.play()


# --- the recipes ---------------------------------------------------------------


func _make() -> void:
	_add("shot", _sweep(900.0, 480.0, 0.08, 0.5, 0.02), 0.04)
	_add("hit", _mix([_noise(0.05, 0.35, 0.5), _sweep(200.0, 120.0, 0.07, 0.6, 0.01)]), 0.03)
	_add("poof", _mix([_noise(0.2, 0.4, 0.2), _delay(_sweep(700.0, 1500.0, 0.14, 0.25, 0.1), 0.03)]), 0.05)
	_add("hurt", _boing(520.0, 170.0, 0.4), 0.2)
	_add("spit", _mix([_noise(0.1, 0.3, 0.35), _sweep(320.0, 150.0, 0.12, 0.4, 0.02)]), 0.05)
	_add("door", _mix([_sweep(130.0, 90.0, 0.16, 0.8, 0.01), _noise(0.03, 0.4, 0.6)]), 0.1)
	_add("coin", _mix([_bell(1320.0, 0.25, 0.4), _delay(_bell(1760.0, 0.3, 0.45), 0.07)]), 0.03)
	_add("heart", _sweep(300.0, 760.0, 0.16, 0.55, 0.03), 0.05)
	_add("pickup", _mix([_bell(880.0, 0.12, 0.45), _delay(_bell(1175.0, 0.14, 0.4), 0.05)]), 0.05)
	_add("item", _notes([523.0, 659.0, 784.0, 1047.0], 0.09, 0.3, 0.45), 0.3)
	_add("blast", _mix([_noise(0.8, 0.9, 0.08, true), _sweep(80.0, 40.0, 0.5, 0.9, 0.005)]), 0.1)
	_add("stomp", _mix([_sweep(90.0, 45.0, 0.3, 1.0, 0.005), _noise(0.18, 0.5, 0.15, true)]), 0.1)
	_add("whistle_up", _sweep(500.0, 1500.0, 0.4, 0.3, 0.05, true), 0.2)
	_add("whistle_down", _sweep(1300.0, 350.0, 0.6, 0.3, 0.05, true), 0.2)
	_add("stars", _notes([1568.0, 2093.0, 1760.0], 0.06, 0.12, 0.3), 0.3)
	_add("roar", _growl(95.0, 0.7), 0.5)
	_add("select", _bell(1200.0, 0.05, 0.35), 0.03)
	_add("confirm", _notes([660.0, 990.0], 0.07, 0.15, 0.4), 0.1)
	# Uh-uh: two low notes going down, for what cannot be had.
	_add("nope", _notes([233.0, 175.0], 0.1, 0.16, 0.4), 0.3)
	_add("sad", _sad_trombone(), 1.0)
	_add("fuse", _noise(0.25, 0.12, 0.7), 0.3)


func _add(sound: String, samples: PackedFloat32Array, gap: float) -> void:
	var peak := 0.001
	for v in samples:
		peak = maxf(peak, absf(v))
	var data := PackedByteArray()
	data.resize(samples.size() * 2)
	var scale := 0.85 / peak * 32767.0
	for i in samples.size():
		data.encode_s16(i * 2, int(clampf(samples[i] * scale, -32767.0, 32767.0)))
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = RATE
	wav.stereo = false
	wav.data = data
	_sounds[sound] = wav
	_gap[sound] = gap


## A tone gliding from [param from] to [param to] Hz, fading out; with
## [param warble] a slide whistle's wobble.
static func _sweep(from: float, to: float, seconds: float, loud: float, attack: float,
		warble := false) -> PackedFloat32Array:
	var n := int(seconds * RATE)
	var out := PackedFloat32Array()
	out.resize(n)
	var phase := 0.0
	for i in n:
		var t := float(i) / n
		var f := from * pow(to / from, t)
		if warble:
			f *= 1.0 + 0.02 * sin(TAU * 7.0 * i / RATE)
		phase += TAU * f / RATE
		var env := minf(float(i) / RATE / maxf(attack, 0.001), 1.0) * pow(1.0 - t, 1.5)
		out[i] = (sin(phase) + 0.2 * sin(phase * 2.0)) * env * loud
	return out


## Noise, softened by [param dull] (0 bright .. 1 very dull), fading out.
static func _noise(seconds: float, loud: float, dull: float, rumble := false) -> PackedFloat32Array:
	var n := int(seconds * RATE)
	var out := PackedFloat32Array()
	out.resize(n)
	var y := 0.0
	var k := clampf(1.0 - dull, 0.02, 1.0)
	for i in n:
		var t := float(i) / n
		# A rumble closes its filter as it dies away.
		var kk := k * (1.0 - 0.8 * t) if rumble else k
		y += kk * (randf_range(-1.0, 1.0) - y)
		out[i] = y * pow(1.0 - t, 2.0) * loud
	return out


## A struck bell: a pure tone and a quieter overtone, ringing down.
static func _bell(freq: float, seconds: float, loud: float) -> PackedFloat32Array:
	var n := int(seconds * RATE)
	var out := PackedFloat32Array()
	out.resize(n)
	for i in n:
		var s := float(i) / RATE
		var env := exp(-s * 5.0 / seconds) * minf(s / 0.003, 1.0)
		out[i] = (sin(TAU * freq * s) + 0.3 * sin(TAU * freq * 2.76 * s)) * env * loud
	return out


## The cartoon boing: a falling tone with a wobble in it.
static func _boing(from: float, to: float, seconds: float) -> PackedFloat32Array:
	var n := int(seconds * RATE)
	var out := PackedFloat32Array()
	out.resize(n)
	var phase := 0.0
	for i in n:
		var t := float(i) / n
		var f := from * pow(to / from, t) * (1.0 + 0.12 * sin(TAU * 18.0 * t * seconds))
		phase += TAU * f / RATE
		out[i] = (sin(phase) + 0.35 * sin(phase * 2.0)) * pow(1.0 - t, 1.2) * 0.6
	return out


## Notes one after another, each ringing on: a little fanfare.
static func _notes(freqs: Array, step: float, ring: float, loud: float) -> PackedFloat32Array:
	var parts: Array = []
	for i in freqs.size():
		parts.append(_delay(_bell(float(freqs[i]), ring, loud), step * i))
	return _mix(parts)


## A low growl: a buzzy tone shaken by a tremble.
static func _growl(freq: float, seconds: float) -> PackedFloat32Array:
	var n := int(seconds * RATE)
	var out := PackedFloat32Array()
	out.resize(n)
	var phase := 0.0
	for i in n:
		var t := float(i) / n
		phase += TAU * freq * (1.0 + 0.1 * sin(TAU * 3.0 * t)) / RATE
		var buzz := 0.0
		for h in range(1, 7):
			buzz += sin(phase * h) / h
		var env := minf(t / 0.1, 1.0) * pow(1.0 - t, 0.8) * (0.7 + 0.3 * sin(TAU * 11.0 * t * seconds))
		out[i] = buzz * env * 0.5
	return out


## Wah, wah, wah, waaah: four falling notes on a muted trombone, the last
## one wobbling out.
static func _sad_trombone() -> PackedFloat32Array:
	var notes := [[196.0, 0.32], [185.0, 0.32], [175.0, 0.32], [165.0, 0.9]]
	var out := PackedFloat32Array()
	for note: Array in notes:
		var freq: float = note[0]
		var n := int(float(note[1]) * RATE)
		var phase := 0.0
		for i in n:
			var t := float(i) / n
			var wobble := 0.03 * sin(TAU * 6.0 * i / RATE) if note == notes.back() else 0.0
			phase += TAU * freq * (1.0 + wobble) / RATE
			var tone := 0.0
			for h in range(1, 6):
				tone += sin(phase * h) / (h * 1.3)
			# The mute: each note swells in and closes off, "wah".
			var wah := sin(PI * minf(t * 1.3, 1.0))
			out.append(tone * wah * 0.4)
	return out


static func _delay(samples: PackedFloat32Array, seconds: float) -> PackedFloat32Array:
	var out := PackedFloat32Array()
	out.resize(int(seconds * RATE))
	out.append_array(samples)
	return out


static func _mix(parts: Array) -> PackedFloat32Array:
	var n := 0
	for part: PackedFloat32Array in parts:
		n = maxi(n, part.size())
	var out := PackedFloat32Array()
	out.resize(n)
	for part: PackedFloat32Array in parts:
		for i in part.size():
			out[i] += part[i]
	return out
