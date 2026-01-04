extends Node
## AudioManager - Terminal beep sound effects
##
## Generates and plays retro terminal-style beep sounds for various game actions.
## Sounds are procedurally generated using AudioStreamGenerator for a authentic
## retro terminal feel.
##
## Part of Issue #89

## Sound enable/disable flag
var sounds_enabled: bool = true

## AudioStreamPlayers for different sound types
var movement_player: AudioStreamPlayer = null
var pickup_player: AudioStreamPlayer = null
var door_player: AudioStreamPlayer = null
var alert_player: AudioStreamPlayer = null
var capture_player: AudioStreamPlayer = null
var win_player: AudioStreamPlayer = null

## Playback objects for concurrent sounds
var playback_movement = null
var playback_pickup = null
var playback_door = null
var playback_alert = null
var playback_capture = null
var playback_win = null

func _ready() -> void:
	"""Initialize audio players with generated beep sounds."""
	_setup_audio_players()

func _setup_audio_players() -> void:
	"""Create and configure audio stream players for each sound type."""
	# Movement - short low beep (220 Hz, 0.05s)
	movement_player = _create_beep_player(220.0, 0.05, 0.15)
	add_child(movement_player)

	# Pickup - medium beep with slight rise (440 Hz, 0.1s)
	pickup_player = _create_beep_player(440.0, 0.1, 0.25)
	add_child(pickup_player)

	# Door - two-tone beep (330 Hz, 0.08s)
	door_player = _create_beep_player(330.0, 0.08, 0.2)
	add_child(door_player)

	# Alert - high urgent beep (880 Hz, 0.15s)
	alert_player = _create_beep_player(880.0, 0.15, 0.3)
	add_child(alert_player)

	# Capture - descending low tone (330 Hz, 0.3s)
	capture_player = _create_beep_player(330.0, 0.3, 0.4)
	add_child(capture_player)

	# Win - ascending happy beep (550 Hz, 0.2s)
	win_player = _create_beep_player(550.0, 0.2, 0.35)
	add_child(win_player)

func _create_beep_player(frequency: float, duration: float, volume_db: float) -> AudioStreamPlayer:
	"""
	Create an AudioStreamPlayer with a procedurally generated beep sound.

	Args:
		frequency: Frequency of the beep in Hz
		duration: Duration of the beep in seconds
		volume_db: Volume in decibels

	Returns:
		AudioStreamPlayer configured with the beep sound
	"""
	var player = AudioStreamPlayer.new()

	# Create the audio stream with beep data
	var stream = AudioStreamWAV.new()
	stream.mix_rate = 22050  # Sample rate
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.stereo = false

	# Generate beep waveform
	var samples_count = int(stream.mix_rate * duration)
	var data = PackedByteArray()
	data.resize(samples_count * 2)  # 2 bytes per sample for 16-bit

	for i in range(samples_count):
		# Generate sine wave with envelope
		var t = float(i) / stream.mix_rate
		var envelope = 1.0

		# Apply fade-out envelope for smoother sound
		if t > duration * 0.7:
			envelope = 1.0 - ((t - duration * 0.7) / (duration * 0.3))

		# Generate sine wave sample
		var sample = sin(2.0 * PI * frequency * t) * envelope

		# Convert to 16-bit integer (-32768 to 32767)
		var sample_int = int(sample * 32767.0 * 0.3)  # 0.3 to avoid clipping

		# Write as little-endian 16-bit
		data[i * 2] = sample_int & 0xFF
		data[i * 2 + 1] = (sample_int >> 8) & 0xFF

	stream.data = data

	player.stream = stream
	player.volume_db = volume_db

	return player

func play_movement() -> void:
	"""Play movement beep sound."""
	if sounds_enabled and movement_player:
		movement_player.play()

func play_pickup() -> void:
	"""Play pickup beep sound."""
	if sounds_enabled and pickup_player:
		pickup_player.play()

func play_door() -> void:
	"""Play door interaction beep sound."""
	if sounds_enabled and door_player:
		door_player.play()

func play_alert() -> void:
	"""Play guard alert beep sound."""
	if sounds_enabled and alert_player:
		alert_player.play()

func play_capture() -> void:
	"""Play capture/game over beep sound."""
	if sounds_enabled and capture_player:
		capture_player.play()

func play_win() -> void:
	"""Play victory beep sound."""
	if sounds_enabled and win_player:
		win_player.play()

func set_sounds_enabled(enabled: bool) -> void:
	"""
	Enable or disable all sound effects.

	Args:
		enabled: True to enable sounds, false to disable
	"""
	sounds_enabled = enabled

func is_sounds_enabled() -> bool:
	"""
	Check if sounds are currently enabled.

	Returns:
		True if sounds are enabled, false otherwise
	"""
	return sounds_enabled

func toggle_sounds() -> void:
	"""Toggle sound effects on/off."""
	sounds_enabled = not sounds_enabled
