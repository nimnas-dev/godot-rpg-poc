class_name AudioRouter
extends Node

var _sfx_players: Array[AudioStreamPlayer] = []
var _ui_players: Array[AudioStreamPlayer] = []
var _streams: Dictionary = {}


func configure_buses(feedback: FeedbackProfile) -> void:
	for bus_name in ["SFX", "UI"]:
		if AudioServer.get_bus_index(bus_name) == -1:
			AudioServer.add_bus()
			AudioServer.set_bus_name(AudioServer.bus_count - 1, bus_name)
	var master := AudioServer.get_bus_index("Master")
	if master >= 0:
		var has_limiter := false
		for index in range(AudioServer.get_bus_effect_count(master)):
			if AudioServer.get_bus_effect(master, index) is AudioEffectLimiter:
				has_limiter = true
				break
		if not has_limiter:
			AudioServer.add_bus_effect(master, AudioEffectLimiter.new())
	if _sfx_players.is_empty():
		for index in range(feedback.max_impact_voices):
			_sfx_players.append(_make_player("SFX"))
		for index in range(2):
			_ui_players.append(_make_player("UI"))
	_build_procedural_streams()


func apply_settings(settings: Dictionary) -> void:
	var sfx_bus := AudioServer.get_bus_index("SFX")
	if sfx_bus < 0:
		return
	var linear := clampf(float(settings.get("sfx_volume", 0.8)), 0.0, 1.0)
	AudioServer.set_bus_volume_db(sfx_bus, linear_to_db(linear) if linear > 0.0 else -80.0)
	var ui_bus := AudioServer.get_bus_index("UI")
	if ui_bus >= 0:
		AudioServer.set_bus_volume_db(ui_bus, linear_to_db(linear) if linear > 0.0 else -80.0)


func play_cue(cue: StringName) -> void:
	if not _streams.has(cue):
		return
	var players := _ui_players if cue == &"ui" else _sfx_players
	for player in players:
		if not player.playing:
			player.stream = _streams[cue]
			player.play()
			return


func _make_player(bus_name: String) -> AudioStreamPlayer:
	var player := AudioStreamPlayer.new()
	player.bus = bus_name
	add_child(player)
	return player


func _build_procedural_streams() -> void:
	if not _streams.is_empty():
		return
	_streams[&"ui"] = _make_tone(520.0, 0.055, 0.18, 0.0)
	_streams[&"attack"] = _make_tone(180.0, 0.08, 0.24, 0.22)
	_streams[&"hit"] = _make_tone(92.0, 0.11, 0.34, 0.45)
	_streams[&"wave"] = _make_tone(420.0, 0.22, 0.2, 0.03)
	_streams[&"level"] = _make_tone(690.0, 0.28, 0.2, 0.02)
	_streams[&"death"] = _make_tone(70.0, 0.42, 0.32, 0.22)


func _make_tone(frequency: float, duration: float, volume: float, noise_mix: float) -> AudioStreamWAV:
	var mix_rate := 22050
	var sample_count := int(duration * mix_rate)
	var bytes := PackedByteArray()
	bytes.resize(sample_count * 2)
	var rng := RandomNumberGenerator.new()
	rng.seed = int(frequency * 1000.0 + duration * 10000.0)
	for index in range(sample_count):
		var time := float(index) / mix_rate
		var envelope := pow(1.0 - float(index) / sample_count, 2.0)
		var tone := sin(TAU * frequency * time)
		var noise := rng.randf_range(-1.0, 1.0)
		var sample := clampf((tone * (1.0 - noise_mix) + noise * noise_mix) * envelope * volume, -1.0, 1.0)
		bytes.encode_s16(index * 2, int(sample * 32767.0))
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = mix_rate
	stream.stereo = false
	stream.data = bytes
	return stream
