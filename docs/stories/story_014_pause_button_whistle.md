# Story 014 – Pause-Button: Whistle-Icon, Farbe & Rotations-Vibration

**Status**: ✅ Erledigt  
**Priorität**: Normal

---

## Ziel

Den Pause-Button visuell überarbeiten:
1. Statt Text (`⏸` / `▶`) wird `assets/whistle.png` als Icon angezeigt
2. Die Button-Farbe wird auf `#99f1f7` gesetzt
3. Wenn die Pause aktiv ist, vibriert der Button in der Rotation (wie die Shiver-Animation der Lemminge, aber rotierend statt horizontal)

---

## Aufgabe 1: `scenes/ui/hud.tscn` – PauseButton anpassen

### Text entfernen, Icon setzen

```
[node name="PauseButton" type="Button" parent="BottomBar"]
custom_minimum_size = Vector2(96, 96)
text = ""                                      ← leer
icon = ExtResource("... whistle ...")          ← whistle.png als ext_resource
expand_icon = true
pivot_offset = Vector2(48, 48)                 ← Rotations-Pivot auf Mitte des Buttons
```

`expand_icon = true` damit das Whistle-Icon den Button-Bereich füllt.  
`pivot_offset = Vector2(48, 48)` – halbe `custom_minimum_size` – damit die Rotation um die Mitte des Buttons erfolgt.

### Farbe via StyleBoxFlat

Den Button-Hintergrund auf `#99f1f7` setzen. Das geht über eine `StyleBoxFlat` im Theme-Override:

```
[sub_resource type="StyleBoxFlat" id="StyleBoxFlat_pause"]
bg_color = Color(0.6, 0.945, 0.969, 1.0)     # #99f1f7

[node name="PauseButton" ...]
theme_override_styles/normal = SubResource("StyleBoxFlat_pause")
```

> `#99f1f7` = RGB `(153, 241, 247)` = normalisiert `(0.600, 0.945, 0.969)`.  
> Für `hover` und `pressed` können leicht hellere/dunklere Varianten gesetzt werden – vorerst reicht `normal`.

---

## Aufgabe 2: `scripts/ui/hud.gd` – Rotations-Vibration

### `set_paused()` anpassen

`set_paused()` setzt aktuell nur den Button-Text. Das entfällt (kein Text mehr). Stattdessen wird die Vibrations-Animation gestartet oder gestoppt:

```gdscript
var _pause_tween: Tween = null

const WOBBLE_ANGLE: float = 12.0    # Grad nach links/rechts
const WOBBLE_SPEED: float = 0.08    # Sekunden pro Halbschwingung
const WOBBLE_PAUSE: float = 0.25    # Pause zwischen Wobble-Bursts

func set_paused(paused: bool) -> void:
	if paused:
		_start_wobble()
	else:
		_stop_wobble()


func _start_wobble() -> void:
	_stop_wobble()
	_pause_tween = create_tween()
	_pause_tween.set_loops()
	# Burst: kurz links-rechts-links rotieren
	_pause_tween.tween_property(_pause_button, "rotation_degrees", -WOBBLE_ANGLE, WOBBLE_SPEED)\
		.as_relative().set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	_pause_tween.tween_property(_pause_button, "rotation_degrees", WOBBLE_ANGLE * 2.0, WOBBLE_SPEED)\
		.as_relative().set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	_pause_tween.tween_property(_pause_button, "rotation_degrees", -WOBBLE_ANGLE, WOBBLE_SPEED)\
		.as_relative().set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	_pause_tween.tween_interval(WOBBLE_PAUSE)


func _stop_wobble() -> void:
	if _pause_tween != null and _pause_tween.is_valid():
		_pause_tween.kill()
		_pause_tween = null
	_pause_button.rotation_degrees = 0.0
```

---

## Akzeptanzkriterien

- [ ] `whistle.png` ist als `ext_resource` in `hud.tscn` eingetragen
- [ ] `PauseButton.text` ist leer; `PauseButton.icon` zeigt `whistle.png`
- [ ] `expand_icon = true` sodass das Icon den Button füllt
- [ ] `pivot_offset` ist auf die Mitte des Buttons gesetzt (`Vector2(48, 48)`)
- [ ] Hintergrundfarbe des Buttons ist `#99f1f7`
- [ ] Wenn Pause aktiv: Button rotiert in einem Burst-Loop (links → rechts → links → Pause → wiederholen)
- [ ] Wenn Pause beendet: Rotation stoppt, `rotation_degrees` wird auf `0.0` zurückgesetzt
- [ ] Keine anderen bestehenden Dateien werden verändert (außer `hud.tscn` und `hud.gd`)

