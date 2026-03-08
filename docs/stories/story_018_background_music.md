# Story 018 – Hintergrundmusik (Loop, leiser bei Tick-Pause)

**Status**: ✅ Erledigt  
**Priorität**: Normal  
**Voraussetzung**: story_016 und story_017 müssen vollständig implementiert sein.

---

## Ziel

`assets/sound/bg-music.wav` soll als dauerhafter Loop im gesamten Spiel laufen – auch im Level-Select. Bei aktiver Tick-Pause wird die Musik auf ca. 50% Lautstärke heruntergedimmt; beim Fortsetzen kommt sie wieder auf normale Lautstärke. Der `AudioManager`-Autoload überlebt Szenenwechsel, daher läuft die Musik unterbrechungslos durch.

---

## Lautstärke-Referenz (dB)

Da `volume_db` logarithmisch ist, entspricht "50% Lautstärke" nicht `-50 dB` sondern ca. `-6 dB`:

| Zustand | `volume_db` |
|---------|-------------|
| Normal (100%) | `0.0 dB` |
| Gedimmt (≈50%) | `-6.0 dB` |
| Stumm | `-80.0 dB` |

Diese Werte sind als Konstanten im Script definiert und damit leicht anpassbar.

---

## Aufgabe 1: `scenes/global/audio_manager.tscn` – MusicPlayer ergänzen

Einen neuen `AudioStreamPlayer`-Node als Kind von `AudioManager` hinzufügen:

```tscn
[ext_resource type="AudioStreamWAV" path="res://assets/sound/bg-music.wav" id="X_music"]

[node name="MusicPlayer" type="AudioStreamPlayer" parent="."]
stream = ExtResource("X_music")
autoplay = true
```

> `autoplay = true` – Musik startet sofort wenn der AudioManager instanziert wird (beim Spielstart). Da der AudioManager ein Autoload ist, startet die Musik beim ersten Frame des Spiels.

**Looping:** `AudioStreamWAV` loopt in Godot 4 nur wenn `loop_mode` in der Import-Einstellung gesetzt ist. Falls `bg-music.wav` nicht automatisch loopt, muss im Godot-Editor die Import-Option der Datei angepasst werden:
- `bg-music.wav` im FileSystem-Panel anklicken
- Im Import-Panel: `Loop Mode` auf `Forward` setzen
- Re-Import

Alternativ im Script sicherstellen via `stream.loop_mode = AudioStreamWAV.LOOP_FORWARD` nach dem Laden – aber die Import-Einstellung ist der empfohlene Weg.

---

## Aufgabe 2: `scripts/global/audio_manager.gd` – MusicPlayer-Logik

### Konstanten ergänzen

```gdscript
const MUSIC_VOLUME_NORMAL: float = 0.0    # 100% Lautstärke
const MUSIC_VOLUME_DIMMED: float = -6.0   # ~50% Lautstärke bei Tick-Pause
const MUSIC_FADE_DURATION: float = 0.8    # Sekunden für Lautstärke-Übergang
```

### `@onready`-Referenz aktivieren (Stub ersetzen)

Den auskommentierten Stub ersetzen:

```gdscript
# ALT (Stub aus story_016, entfernen):
# @onready var _music_player: AudioStreamPlayer = $MusicPlayer

# NEU:
@onready var _music_player: AudioStreamPlayer = $MusicPlayer
```

### Separater Tween für Musik-Lautstärke

Die Musik verwendet einen **eigenen Tween** (`_music_tween`) damit Ambient-Fade und Musik-Fade nicht gegenseitig unterbrochen werden:

```gdscript
var _music_tween: Tween = null
```

### Hilfsmethode `_set_music_volume()`

```gdscript
func _set_music_volume(target_db: float) -> void:
	if _music_tween != null and _music_tween.is_valid():
		_music_tween.kill()
	_music_tween = create_tween()
	_music_tween.tween_property(_music_player, "volume_db", target_db, MUSIC_FADE_DURATION)\
		.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
```

### `_on_ticks_paused()` und `_on_ticks_resumed()` erweitern

```gdscript
func _on_ticks_paused() -> void:
	_ambient_active = true
	_fade_in_ambient()
	_play_next_wind()
	_schedule_next_ice()
	_set_music_volume(MUSIC_VOLUME_DIMMED)   # ← NEU


func _on_ticks_resumed() -> void:
	_ambient_active = false
	_fade_out_ambient()
	_ice_timer = null
	_set_music_volume(MUSIC_VOLUME_NORMAL)   # ← NEU
```

### Gestrichene Stub-Kommentare

Die auskommentierten `play_music()` / `stop_music()`-Stubs aus story_016 entfernen – sie werden nicht gebraucht, da Musik via `autoplay` läuft.

---

## Akzeptanzkriterien

- [ ] `MusicPlayer`-Node in `audio_manager.tscn` mit `bg-music.wav` und `autoplay = true`
- [ ] `bg-music.wav` loopt ohne Unterbrechung (Import-Setting oder Script)
- [ ] Musik startet beim Spielstart und läuft durch Szenenwechsel (Level-Select → Game → Level-Select) unterbrechungslos
- [ ] Wenn Ticks pausiert werden: Musik dimmt sanft auf ca. `-6 dB` (`MUSIC_FADE_DURATION`)
- [ ] Wenn Ticks fortgesetzt werden: Musik steigt sanft zurück auf `0.0 dB`
- [ ] Ambient-Fade (Wind/Ice) und Musik-Fade laufen auf getrennten Tweens – unterbrechen sich nicht gegenseitig
- [ ] Keine anderen bestehenden Dateien werden verändert (außer `audio_manager.gd` und `audio_manager.tscn`)

