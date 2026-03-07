# Story 009 – Hole-Objekt

**Status**: ✅ Erledigt  
**Priorität**: Hoch  
**Voraussetzung**: story_008 muss vollständig implementiert sein (`DesignerObjectsContainer` existiert).

---

## Ziel

Ein neues Objekt `Hole` einführen. Läuft ein Lemming auf ein Hole-Tile, stirbt er – aber nicht sofort: Er betritt das Tile normal, und beim **nächsten Tick** spielt er eine Schrumpf-Animation ab (Tween von voller Größe auf `Vector2(0,0)`), bevor er entfernt wird. Das Hole ist ein Designer-Objekt (nicht vom Spieler entfernbar).

---

## Kontext & Spielmechanik

**Ablauf im Detail:**

1. **Tick N**: Lemming bewegt sich auf das Hole-Tile. `apply_to_lemming()` wird aufgerufen → Lemming-State wird auf `FALLING` gesetzt, Tick-Signal wird getrennt (kein weiteres Bewegen), `died`-Signal wird **noch nicht** emittiert.
2. **Sofort nach apply_to_lemming()**: Lemming spielt die Schrumpf-Animation ab (Tween über eine Tick-Dauer).
3. **Nach der Animation**: `died`-Signal emittieren → `LevelController._on_lemming_died()` → `queue_free()`.

Ein neuer State `FALLING` wird in `Enums.LemmingState` eingeführt, damit der Lemming während der Animation korrekt identifizierbar ist.

---

## Aufgabe 1: `Enums.LemmingState` erweitern

In `scripts/global/enums.gd`:

```gdscript
enum LemmingState {
	ALIVE,
	EXITING,
	SAVED,
	FALLING,  ## ← NEU: Lemming fällt ins Hole, Animation läuft
	DEAD
}
```

---

## Aufgabe 2: `scripts/objects/hole.gd`

```gdscript
class_name Hole
extends PlaceableObject


func apply_to_lemming(lemming: Lemming) -> void:
	# Lemming ist auf dem Hole-Tile angekommen.
	# Tick-Verbindung trennen damit er sich nicht weiter bewegt.
	if TickManager.tick_happened.is_connected(lemming._on_tick_happened):
		TickManager.tick_happened.disconnect(lemming._on_tick_happened)
	lemming.state = Enums.LemmingState.FALLING
	lemming.start_fall_animation()


func get_object_type() -> String:
	return "hole"
```

---

## Aufgabe 3: `lemming.gd` – `start_fall_animation()` und `died`-Signal

### `died`-Signal aktivieren

Das Signal existiert bereits, war aber mit `@warning_ignore("unused_signal")` markiert. Diese Annotation entfernen – das Signal wird jetzt aktiv genutzt:

```gdscript
signal died(lemming: Lemming)   # @warning_ignore entfernen
```

### `start_fall_animation()` implementieren

```gdscript
## Spielt die Schrumpf-Animation ab und emittiert danach died.
## Wird von Hole.apply_to_lemming() aufgerufen.
func start_fall_animation() -> void:
	var tween: Tween = create_tween()
	tween.set_ease(Tween.EASE_IN)
	tween.set_trans(Tween.TRANS_QUAD)
	tween.tween_property(self, "scale", Vector2.ZERO, TickManager.get_tick_duration() * 0.9)
	tween.tween_callback(_on_fall_animation_finished)


func _on_fall_animation_finished() -> void:
	state = Enums.LemmingState.DEAD
	died.emit(self)
```

### `_process_movement()` – Sicherheitscheck

Sicherstellen dass ein Lemming im `FALLING`-State nicht mehr bewegt wird (sollte durch das Disconnect bereits verhindert sein, aber als defensive Absicherung):

```gdscript
func _on_tick_happened(_tick_number: int) -> void:
	if state != Enums.LemmingState.ALIVE:
		return
	_process_movement()
```

> Diese Zeile ist bereits korrekt – `FALLING` ist nicht `ALIVE`, also wird `_process_movement()` nicht aufgerufen. Keine Änderung nötig, nur zur Klarheit dokumentiert.

---

## Aufgabe 4: `LevelController` – `_on_lemming_died()` anpassen

`_on_lemming_died()` ruft aktuell direkt `lemming.queue_free()` auf. Das Lemming entfernt sich aber nach der Animation selbst via `died`-Signal. Sicherstellen dass `queue_free()` erst nach der Animation aufgerufen wird – das ist bereits der Fall, da `died` erst in `_on_fall_animation_finished()` emittiert wird. Keine Änderung nötig.

> Zur Klarheit: Die Signalkette ist:  
> `Hole.apply_to_lemming()` → `lemming.start_fall_animation()` → *(Tween läuft)* → `lemming.died.emit()` → `LevelController._on_lemming_died()` → `GameManager.on_lemming_died()` + `lemming.queue_free()`

---

## Aufgabe 5: `scenes/objects/hole.tscn`

**Node-Hierarchie:**

```
Hole (Node2D)                   Script: scripts/objects/hole.gd
└── Sprite2D                    Textur: res://assets/hole.png
```

> Der Dateiname im Asset ist `hole.pnh` laut Anforderung – wahrscheinlich Tippfehler, korrekt ist `hole.png`. Den tatsächlichen Dateinamen im `assets/`-Ordner prüfen und entsprechend referenzieren.

---

## Aufgabe 6: Hole im Level platzieren (Designer-Workflow)

Das Hole wird **nicht** über das Spieler-Inventar platziert, sondern vom Designer direkt im Godot-Editor:

1. `hole.tscn` instanzieren
2. Als Kind von `DesignerObjectsContainer` in der Level-Szene einfügen
3. An der gewünschten Position auf einem begehbaren Tile platzieren
4. `LevelController._load_designer_objects()` registriert das Hole automatisch beim Start

> Das Hole taucht **nicht** im `starting_inventory` auf und wird **nicht** als `ObjectDefinition`-Resource angelegt.

---

## Akzeptanzkriterien

- [ ] `Enums.LemmingState.FALLING` existiert
- [ ] `scripts/objects/hole.gd` existiert mit `class_name Hole extends PlaceableObject`
- [ ] `scenes/objects/hole.tscn` existiert mit Sprite2D und `hole.png` als Textur
- [ ] `lemming.gd` hat `start_fall_animation()` implementiert
- [ ] `lemming.gd` emittiert `died` nach Abschluss der Schrumpf-Animation
- [ ] Lemming bewegt sich normal auf das Hole-Tile (kein sofortiger Tod beim Betreten)
- [ ] Im **nächsten Tick** (oder unmittelbar nach Betreten): Lemming schrumpft auf `scale = Vector2(0,0)` über ~eine Tick-Dauer
- [ ] Nach der Animation: Lemming wird entfernt, `GameManager.on_lemming_died()` wird aufgerufen
- [ ] Lemming bewegt sich während der Schrumpf-Animation nicht weiter
- [ ] Ein im Editor unter `DesignerObjectsContainer` platziertes Hole wird vom LevelController korrekt registriert
- [ ] Der Spieler kann das Hole nicht entfernen (Linksklick hat keinen Effekt)

