# Story 017 – Wind & Ice Ambient-Sounds (Pause-gesteuert)

**Status**: 🟡 Bereit zur Implementierung  
**Priorität**: Normal  
**Voraussetzung**: story_016 muss vollständig implementiert sein (`AudioManager` existiert, `WindPlayer` und `IcePlayer` sind als Nodes vorhanden).

---

## Ziel

Während die Ticks pausiert sind, spielen zwei parallele Ambient-Kanäle:
- **Wind**: Zufällige Auswahl aus 9 Sound-Dateien, nahtlos fortlaufend (wenn eine Datei endet → sofort nächste zufällige)
- **Ice**: Zufällige Auswahl aus 3 Sound-Dateien, mit konfigurierbarer Zufalls-Verzögerung zwischen den Sounds (0.3–0.7s)

Beide Kanäle laufen parallel und unabhängig voneinander. Beim Fortsetzen der Ticks werden beide gestoppt.

**Volume-Fade:** Statt hartem Start/Stop wird die Lautstärke sanft ein- und ausgeblendet (Tween auf `volume_db`). Das verhindert harte Audio-Schnitte.

---

## Vorhandene Sound-Dateien

```
assets/sound/wind/
    Sound1.wav  Sound2.wav  Sound3.wav  Sound4.wav  Sound5.wav
    Sound6.wav  Sound7.wav  Sound8.wav  Sound9.wav

assets/sound/ice/
    Freeze1.wav  Freeze2.wav  Freeze3.wav
```

---

## Aufgabe 1: `scripts/global/audio_manager.gd` – Sound-Arrays und Konfiguration

Folgende Konstanten und Variablen am Anfang des Scripts ergänzen:

```gdscript
## Lautstärke-Fade-Dauer in Sekunden (ein- und ausblenden)
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

var _ambient_active: bool = false
var _fade_tween: Tween = null
var _ice_timer: SceneTreeTimer = null
```

> **Hinweis zu `@export` auf einem Autoload-Script**: `ice_delay_min` und `ice_delay_max` sind über den Inspector des Autoloads im Godot-Editor anpassbar. Die Standardwerte gelten wenn nichts geändert wird.

---

## Aufgabe 2: `_on_ticks_paused()` und `_on_ticks_resumed()` implementieren

Die leeren Stubs aus story_016 ersetzen:

```gdscript
func _on_ticks_paused() -> void:
	_ambient_active = true
	_fade_in_ambient()
	_play_next_wind()
	_schedule_next_ice()


func _on_ticks_resumed() -> void:
	_ambient_active = false
	_fade_out_ambient()
	# Ice-Timer invalidieren – kein neuer Sound mehr nach Fade-Out
	_ice_timer = null
```

---

## Aufgabe 3: Volume-Fade Hilfsmethoden

```gdscript
func _fade_in_ambient() -> void:
	if _fade_tween != null and _fade_tween.is_valid():
		_fade_tween.kill()
	# Beide Player starten bei -80 dB (unhörbar)
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
	# Playback nach Fade stoppen
	await _fade_tween.finished
	_wind_player.stop()
	_ice_player.stop()
```

---

## Aufgabe 4: Wind-Loop

```gdscript
func _play_next_wind() -> void:
	if not _ambient_active:
		return
	var stream: AudioStream = WIND_STREAMS[randi() % WIND_STREAMS.size()]
	_wind_player.stream = stream
	_wind_player.play()


## Wird in _ready() einmalig verbunden:
## _wind_player.finished.connect(_play_next_wind)
```

In `_ready()` die Verbindung herstellen:

```gdscript
func _ready() -> void:
	TickManager.paused.connect(_on_ticks_paused)
	TickManager.resumed.connect(_on_ticks_resumed)
	_wind_player.finished.connect(_play_next_wind)   # ← NEU
	_ice_player.finished.connect(_on_ice_finished)   # ← NEU
	# Beide Player starten unhörbar
	_wind_player.volume_db = -80.0
	_ice_player.volume_db = -80.0
```

---

## Aufgabe 5: Ice-Sounds mit Delay

```gdscript
func _schedule_next_ice() -> void:
	if not _ambient_active:
		return
	var delay: float = randf_range(ice_delay_min, ice_delay_max)
	_ice_timer = get_tree().create_timer(delay)
	_ice_timer.timeout.connect(_play_next_ice, CONNECT_ONE_SHOT)


func _play_next_ice() -> void:
	if not _ambient_active:
		return
	var stream: AudioStream = ICE_STREAMS[randi() % ICE_STREAMS.size()]
	_ice_player.stream = stream
	_ice_player.play()


func _on_ice_finished() -> void:
	if not _ambient_active:
		return
	_schedule_next_ice()
```

---

## Aufgabe 6: `scenes/global/audio_manager.tscn` – Player konfigurieren

`WindPlayer` und `IcePlayer` in der Szene anpassen:
- `volume_db = -80.0` als Startwert (unhörbar bis Pause aktiv)
- `autoplay = false`
- `stream = null` (wird dynamisch gesetzt)

---

## Vollständige Signalkette (zur Übersicht)

```
TickManager.paused
    → AudioManager._on_ticks_paused()
        → _fade_in_ambient()          (Volume 0 dB über FADE_IN_DURATION)
        → _play_next_wind()           (sofort ersten Wind-Sound starten)
        → _schedule_next_ice()        (Delay → _play_next_ice())

WindPlayer.finished → _play_next_wind()   (nächster zufälliger Wind-Sound)
IcePlayer.finished  → _on_ice_finished() → _schedule_next_ice() → _play_next_ice()

TickManager.resumed
    → AudioManager._on_ticks_resumed()
        → _fade_out_ambient()         (Volume -80 dB über FADE_OUT_DURATION)
        → _ice_timer = null           (keinen neuen Ice-Sound einplanen)
        → stop() nach Fade
```

---

## Hinweis: Hintergrundmusik (story_018)

Wenn die Hintergrundmusik implementiert wird, soll sie während der Tick-Pause **leiser** (nicht stumm) werden. Das wird in `_on_ticks_paused()` / `_on_ticks_resumed()` mit einem separaten Fade auf `_music_player.volume_db` ergänzt. Dafür ist der Stub-Kommentar in story_016 bereits vorbereitet.

---

## Akzeptanzkriterien

- [ ] `WIND_STREAMS` und `ICE_STREAMS` als `preload()`-Arrays im Script
- [ ] Tick-Pause aktiv → Wind-Sound startet sofort (zufällige Auswahl), läuft nahtlos weiter
- [ ] Tick-Pause aktiv → Ice-Sounds starten nach zufälliger Verzögerung (0.3–0.7s), nach jedem Sound neue Verzögerung
- [ ] Wind und Ice laufen parallel und unabhängig
- [ ] Lautstärke blendet beim Pausieren sanft ein (`FADE_IN_DURATION`)
- [ ] Lautstärke blendet beim Fortsetzen sanft aus (`FADE_OUT_DURATION`), dann stop()
- [ ] `ice_delay_min` / `ice_delay_max` sind im Inspector des AudioManager-Autoloads konfigurierbar
- [ ] Kein Ice-Sound wird eingeplant nachdem Ticks fortgesetzt wurden
- [ ] Kein Crash wenn Ticks mehrfach schnell hintereinander pausiert/fortgesetzt werden

