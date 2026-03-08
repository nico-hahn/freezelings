## AudioManager
# Autoload "AudioManager"
# Zentralisiert alle Audio-Wiedergabe im Spiel.
# Überlebt Szenenwechsel – ideal für Ambient-Loops und Hintergrundmusik.

extends Node

## Lautstärke-Fade-Dauer in Sekunden
const FADE_IN_DURATION: float = 0.4
const FADE_OUT_DURATION: float = 0.6

## Verzögerung zwischen Ice-Sounds (zufällig zwischen MIN und MAX)
@export var ice_delay_min: float = 0.3
@export var ice_delay_max: float = 0.7

## Alle Wind-Streams (preload für Export-Sicherheit)
const WIND_STREAMS: Array = [
	preload("res://assets/sound/wind/Sound1.wav"),
	preload("res://assets/sound/wind/Sound2.wav"),
	preload("res://assets/sound/wind/Sound3.wav"),
	preload("res://assets/sound/wind/Sound4.wav"),
	preload("res://assets/sound/wind/Sound5.wav"),
	preload("res://assets/sound/wind/Sound6.wav"),
	preload("res://assets/sound/wind/Sound7.wav"),
	preload("res://assets/sound/wind/Sound8.wav"),
	preload("res://assets/sound/wind/Sound9.wav"),
]

## Alle Ice-Streams (preload für Export-Sicherheit)
const ICE_STREAMS: Array = [
	preload("res://assets/sound/ice/Freeze1.wav"),
	preload("res://assets/sound/ice/Freeze2.wav"),
	preload("res://assets/sound/ice/Freeze3.wav"),
]

## Lautstärke-Referenz Musik
const MUSIC_VOLUME_NORMAL: float = 0.0
const MUSIC_VOLUME_DIMMED: float = -6.0
const MUSIC_FADE_DURATION: float = 0.8

# --- Nodes ---
@onready var _whistle_player: AudioStreamPlayer = $WhistlePlayer
@onready var _wind_player: AudioStreamPlayer = $WindPlayer
@onready var _ice_player: AudioStreamPlayer = $IcePlayer
@onready var _music_player: AudioStreamPlayer = $MusicPlayer

var _ambient_active: bool = false
var _fade_tween: Tween = null
var _music_tween: Tween = null
var _ice_timer: SceneTreeTimer = null


func _ready() -> void:
	TickManager.paused.connect(_on_ticks_paused)
	TickManager.resumed.connect(_on_ticks_resumed)
	_wind_player.finished.connect(_play_next_wind)
	_ice_player.finished.connect(_on_ice_finished)
	# Beide Player starten unhörbar
	_wind_player.volume_db = -80.0
	_ice_player.volume_db = -80.0


## Spielt den Whistle-Sound einmalig ab.
func play_whistle() -> void:
	_whistle_player.play()


# --- Ambient ---

func _on_ticks_paused() -> void:
	_ambient_active = true
	_fade_in_ambient()
	_play_next_wind()
	_schedule_next_ice()
	_set_music_volume(MUSIC_VOLUME_DIMMED)


func _on_ticks_resumed() -> void:
	_ambient_active = false
	_fade_out_ambient()
	_ice_timer = null
	_set_music_volume(MUSIC_VOLUME_NORMAL)


func _fade_in_ambient() -> void:
	if _fade_tween != null and _fade_tween.is_valid():
		_fade_tween.kill()
	_wind_player.volume_db = -80.0
	_ice_player.volume_db = -80.0
	_fade_tween = create_tween().set_parallel(true)
	_fade_tween.tween_property(_wind_player, "volume_db", 0.0, FADE_IN_DURATION)
	_fade_tween.tween_property(_ice_player, "volume_db", 0.0, FADE_IN_DURATION)


func _fade_out_ambient() -> void:
	if _fade_tween != null and _fade_tween.is_valid():
		_fade_tween.kill()
	_fade_tween = create_tween().set_parallel(true)
	_fade_tween.tween_property(_wind_player, "volume_db", -80.0, FADE_OUT_DURATION)
	_fade_tween.tween_property(_ice_player, "volume_db", -80.0, FADE_OUT_DURATION)
	await _fade_tween.finished
	_wind_player.stop()
	_ice_player.stop()


# --- Wind ---

func _play_next_wind() -> void:
	if not _ambient_active:
		return
	_wind_player.stream = WIND_STREAMS[randi() % WIND_STREAMS.size()]
	_wind_player.play()


# --- Ice ---

func _schedule_next_ice() -> void:
	if not _ambient_active:
		return
	var delay: float = randf_range(ice_delay_min, ice_delay_max)
	_ice_timer = get_tree().create_timer(delay)
	_ice_timer.timeout.connect(_play_next_ice, CONNECT_ONE_SHOT)


func _play_next_ice() -> void:
	if not _ambient_active:
		return
	_ice_player.stream = ICE_STREAMS[randi() % ICE_STREAMS.size()]
	_ice_player.play()


func _on_ice_finished() -> void:
	if not _ambient_active:
		return
	_schedule_next_ice()


func _set_music_volume(target_db: float) -> void:
	if _music_tween != null and _music_tween.is_valid():
		_music_tween.kill()
	_music_tween = create_tween()
	_music_tween.tween_property(_music_player, "volume_db", target_db, MUSIC_FADE_DURATION)\
		.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
