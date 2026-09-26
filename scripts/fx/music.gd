class_name Music
extends Node
## The gramophone in the corner: ragtime for every part of the game, played
## the way a record of the period sounds -- no deep bass and no sparkle on
## top, a little boxy, with the hiss and crackle of the shellac under it.
##
##   menu      The Entertainer
##   floors    Maple Leaf Rag, Pine Apple Rag, Magnetic Rag
##   boss      Stop Time Rag
## A change of record is a quick fade, the needle lifted and set down.
## [method play] from anywhere finds the one under Main.

const TRACKS := {
	"menu": "res://music/entertainer.ogg",
	"floor0": "res://music/maple_leaf.ogg",
	"floor1": "res://music/pine_apple.ogg",
	"floor2": "res://music/magnetic.ogg",
	"boss": "res://music/stop_time.ogg",
}
const BUS := "Gramophone"
const VOLUME_DB := -11.0
const FADE := 0.6
const CRACKLE_RATE := 22050

static var deck: Music

## Off by `-- mute`, and in checks.
var enabled := true

var _player: AudioStreamPlayer
var _crackle: AudioStreamPlayer
var _current := ""
var _tween: Tween


static func play(track: String) -> void:
	if deck != null:
		deck._play(track)


## The music stops: a run ends badly and the sad trombone has the floor.
static func stop() -> void:
	if deck != null:
		deck._play("")


func _ready() -> void:
	deck = self
	process_mode = Node.PROCESS_MODE_ALWAYS
	_make_bus()
	_player = AudioStreamPlayer.new()
	_player.bus = BUS
	_player.volume_db = -80.0
	add_child(_player)
	_crackle = AudioStreamPlayer.new()
	_crackle.bus = BUS
	_crackle.stream = _crackle_stream()
	_crackle.volume_db = -80.0
	add_child(_crackle)


func _exit_tree() -> void:
	if deck == self:
		deck = null


## A bus that sounds like a gramophone horn: a band from about 200 Hz to
## 4 kHz, a bump in the middle where the horn rings, a touch of drive.
func _make_bus() -> void:
	if AudioServer.get_bus_index(BUS) >= 0:
		return
	AudioServer.add_bus()
	var index := AudioServer.bus_count - 1
	AudioServer.set_bus_name(index, BUS)
	AudioServer.set_bus_send(index, "Master")
	var high := AudioEffectHighPassFilter.new()
	high.cutoff_hz = 190.0
	AudioServer.add_bus_effect(index, high)
	var low := AudioEffectLowPassFilter.new()
	low.cutoff_hz = 4200.0
	AudioServer.add_bus_effect(index, low)
	var eq := AudioEffectEQ6.new()
	eq.set_band_gain_db(0, -6.0)
	eq.set_band_gain_db(2, 3.0)
	eq.set_band_gain_db(3, 2.0)
	eq.set_band_gain_db(5, -8.0)
	AudioServer.add_bus_effect(index, eq)
	var drive := AudioEffectDistortion.new()
	drive.mode = AudioEffectDistortion.MODE_OVERDRIVE
	drive.drive = 0.12
	drive.pre_gain = 0.0
	drive.post_gain = -1.0
	AudioServer.add_bus_effect(index, drive)


## Two seconds of the noise of a record, looped: a soft hiss and random
## pops and ticks.
func _crackle_stream() -> AudioStreamWAV:
	var rng := RandomNumberGenerator.new()
	rng.seed = 1930
	var frames := CRACKLE_RATE * 2
	var data := PackedByteArray()
	data.resize(frames * 2)
	var pop := 0.0
	var hiss := 0.0
	for i in frames:
		hiss = hiss * 0.6 + rng.randf_range(-1.0, 1.0) * 0.4
		var v := hiss * 0.05
		if rng.randf() < 0.0012:
			pop = rng.randf_range(0.3, 0.9) * (1.0 if rng.randf() < 0.5 else -1.0)
		v += pop
		pop *= 0.55
		# The slow swish of the groove going round, 78 times a minute.
		v *= 0.8 + 0.2 * sin(TAU * 1.3 * i / CRACKLE_RATE)
		var s := clampi(int(v * 32767.0), -32768, 32767)
		data.encode_s16(i * 2, s)
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = CRACKLE_RATE
	stream.stereo = false
	stream.data = data
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	stream.loop_end = frames
	return stream


func _play(track: String) -> void:
	if not enabled or track == _current:
		return
	_current = track
	if _tween != null:
		_tween.kill()
	_tween = create_tween()
	_tween.set_parallel(false)
	if _player.playing:
		_tween.tween_property(_player, "volume_db", -60.0, FADE)
	_tween.tween_callback(func() -> void:
		_player.stop()
		if track == "":
			_crackle.stop()
			return
		_player.stream = load(TRACKS[track])
		_player.volume_db = -60.0
		_player.play()
		if not _crackle.playing:
			_crackle.play()
		_crackle.volume_db = VOLUME_DB - 16.0)
	if track != "":
		_tween.tween_property(_player, "volume_db", VOLUME_DB, FADE)
