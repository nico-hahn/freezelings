# Story 016 – AudioManager Autoload & Whistle-Sound

**Status**: 🟡 Bereit zur Implementierung  
**Priorität**: Normal  
**Voraussetzung**: Keine. Muss vor story_017 implementiert werden.

---

## Ziel

Einen `AudioManager`-Autoload einführen, der alle Audio-Wiedergabe zentralisiert. In dieser Story: Grundstruktur + Whistle-Sound der beim Klick auf den Pause-Button abgespielt wird. Ambient-Sounds (Wind/Ice) kommen in story_017.

---

## Hintergrund: Architektur-Entscheidungen

- **Autoload** → überlebt Szenenwechsel (wichtig für spätere Hintergrundmusik im Level-Select)
- **`preload()` statt `DirAccess`** → Export-sicher (siehe lesson learned aus ProgressManager)
- **Volume-Fade** statt hartem Start/Stop für Ambient-Sounds → klingt besser; wird in story_017 genutzt
- **Zukünftige Hintergrundmusik**: Ein `_music_player`-Node wird bereits als Stub angelegt (kommentiert), damit story_018 (Hintergrundmusik) sauber anknüpfen kann

---

## Aufgabe 1: `scripts/global/audio_manager.gd`

```gdscript
## AudioManager
# Autoload "AudioManager"
# Zentralisiert alle Audio-Wiedergabe im Spiel.
# Überlebt Szenenwechsel – ideal für Ambient-Loops und Hintergrundmusik.

extends Node

# --- Whistle ---
@onready var _whistle_player: AudioStreamPlayer = $WhistlePlayer

# --- Ambient (Wind + Ice) – werden in story_017 aktiviert ---
@onready var _wind_player: AudioStreamPlayer = $WindPlayer
@onready var _ice_player: AudioStreamPlayer = $IcePlayer

# --- Musik (Stub für story_018) ---
# @onready var _music_player: AudioStreamPlayer = $MusicPlayer


func _ready() -> void:
	# TickManager-Signale für Ambient (story_017 verdrahtet das)
	TickManager.paused.connect(_on_ticks_paused)
	TickManager.resumed.connect(_on_ticks_resumed)


## Spielt den Whistle-Sound einmalig ab.
func play_whistle() -> void:
	_whistle_player.play()


# --- Stubs für story_017 ---

func _on_ticks_paused() -> void:
	pass  # Implementierung in story_017


func _on_ticks_resumed() -> void:
	pass  # Implementierung in story_017


# --- Stub für story_018 ---
# func play_music() -> void:
#     _music_player.play()
#
# func stop_music() -> void:
#     _music_player.stop()
```

---

## Aufgabe 2: `scenes/global/audio_manager.tscn`

AudioManager als Szene, damit die AudioStreamPlayer-Nodes im Szenenbaum sichtbar und konfigurierbar sind.

**Node-Hierarchie:**

```
AudioManager (Node)                    Script: scripts/global/audio_manager.gd
├── WhistlePlayer (AudioStreamPlayer)  stream = res://assets/sound/whistle.wav
│                                      autoplay = false
├── WindPlayer (AudioStreamPlayer)     stream = null (story_017)
│                                      autoplay = false
└── IcePlayer (AudioStreamPlayer)      stream = null (story_017)
                                       autoplay = false
```

> `MusicPlayer` wird erst in story_018 ergänzt – den Node jetzt noch nicht anlegen.

---

## Aufgabe 3: `project.godot` – Autoload registrieren

```ini
[autoload]
...
ProgressManager="*res://scripts/global/progress_manager.gd"
AudioManager="*res://scenes/global/audio_manager.tscn"
```

> **Wichtig**: AudioManager als **Szene** (`.tscn`) registrieren, nicht als Script, damit die AudioStreamPlayer-Kinder korrekt instanziert werden.

---

## Aufgabe 4: `scripts/ui/hud.gd` – Whistle bei Pause-Button

In `_on_pause_button_pressed()` den Whistle-Sound auslösen:

```gdscript
func _on_pause_button_pressed() -> void:
	AudioManager.play_whistle()
	pause_toggled.emit()
```

---

## Akzeptanzkriterien

- [ ] `scripts/global/audio_manager.gd` existiert
- [ ] `scenes/global/audio_manager.tscn` existiert mit `WhistlePlayer`, `WindPlayer`, `IcePlayer`
- [ ] `WhistlePlayer` hat `whistle.wav` als Stream gesetzt
- [ ] AudioManager ist als Autoload in `project.godot` registriert (als `.tscn`)
- [ ] Klick auf Pause-Button → Whistle-Sound ist hörbar
- [ ] Kein Crash wenn TickManager-Signale feuern (leere Stubs funktionieren)

