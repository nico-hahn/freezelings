# Story 010 – BreakingHole-Objekt

**Status**: 🟡 Bereit zur Implementierung  
**Priorität**: Normal  
**Voraussetzungen**: story_008 (`DesignerObjectsContainer`) und story_009 (`Hole`, `Enums.LemmingState.FALLING`, `Lemming.start_fall_animation()`) müssen vollständig implementiert sein.

---

## Ziel

Ein neues Designer-Objekt `BreakingHole` einführen. Es verhält sich wie ein normales `Hole`, lässt aber **genau einen Lemming** passieren. Solange noch kein Lemming das Tile verlassen hat, ist es harmlos. Sobald der erste Lemming das Tile wieder verlässt, wechselt das Sprite zu Frame 1 und das Objekt tötet alle nachfolgenden Lemminge wie ein normales `Hole`.

---

## Spielmechanik im Detail

| Phase | Zustand | Sprite-Frame | Verhalten bei `apply_to_lemming()` |
|-------|---------|-------------|-------------------------------------|
| Unbenutzt | `INTACT` | Frame 0 | Lemming läuft drüber – nichts passiert, Lemming läuft weiter |
| Lemming steht drauf | `INTACT` | Frame 0 | Noch harmlos; BreakingHole beobachtet wann der Lemming das Tile verlässt |
| Lemming hat das Tile verlassen | `BROKEN` | Frame 1 | Tötet alle nachfolgenden Lemminge (wie `Hole`) |

**Wichtig:** „Lemming verlässt das Tile" bedeutet: im nächsten Tick hat der Lemming eine andere `grid_pos`. Das BreakingHole prüft das, indem es sich einmalig auf `TickManager.tick_happened` verbindet und die `grid_pos` des beobachteten Lemmings überwacht.

---

## Aufgabe 1: `scripts/objects/breaking_hole.gd`

```gdscript
class_name BreakingHole
extends PlaceableObject

enum State { INTACT, WATCHING, BROKEN }

var _state: State = State.INTACT
var _watched_lemming: Lemming = null

@onready var _sprite: AnimatedSprite2D = $AnimatedSprite2D


func apply_to_lemming(lemming: Lemming) -> void:
	match _state:
		State.INTACT:
			# Erster Lemming betritt das Tile – harmlos, aber wir beobachten ihn
			_watched_lemming = lemming
			_state = State.WATCHING
			TickManager.tick_happened.connect(_on_tick_watching, CONNECT_ONE_SHOT)
		State.WATCHING:
			# Weiterer Lemming betritt das Tile während wir noch beobachten.
			# Noch harmlos – nichts tun.
			pass
		State.BROKEN:
			# Hole ist kaputt – wie normales Hole
			_kill_lemming(lemming)


func _on_tick_watching(_tick_number: int) -> void:
	if _watched_lemming == null or not is_instance_valid(_watched_lemming):
		# Lemming existiert nicht mehr (z.B. durch anderen Effekt gestorben)
		_break()
		return
	if _watched_lemming.grid_pos != grid_pos:
		# Lemming hat das Tile verlassen → Hole bricht auf
		_watched_lemming = null
		_break()
	else:
		# Lemming steht noch drauf (z.B. durch Blocker direkt daneben) – weiter beobachten
		TickManager.tick_happened.connect(_on_tick_watching, CONNECT_ONE_SHOT)


func _break() -> void:
	_state = State.BROKEN
	_sprite.frame = 1


func _kill_lemming(lemming: Lemming) -> void:
	if TickManager.tick_happened.is_connected(lemming._on_tick_happened):
		TickManager.tick_happened.disconnect(lemming._on_tick_happened)
	lemming.state = Enums.LemmingState.FALLING
	lemming.start_fall_animation()


func get_object_type() -> String:
	return "breaking_hole"
```

> **Hinweis zu `CONNECT_ONE_SHOT`**: Godot 4 unterstützt `CONNECT_ONE_SHOT` als Flag für `connect()`. Das Signal wird nach dem ersten Aufruf automatisch getrennt. Wir verbinden es in `_on_tick_watching` ggf. erneut wenn der Lemming noch nicht weg ist.

---

## Aufgabe 2: `scenes/objects/breaking_hole.tscn`

**Node-Hierarchie:**

```
BreakingHole (Node2D)                  Script: scripts/objects/breaking_hole.gd
└── AnimatedSprite2D                   Name: "AnimatedSprite2D"
```

**AnimatedSprite2D konfigurieren:**
- `SpriteFrames`-Resource erstellen (inline oder als `.tres`)
- Animation `"default"` mit 2 Frames aus `res://assets/breaking_hole.png`
  - Frame 0: linke Hälfte des Sprites (intact)
  - Frame 1: rechte Hälfte des Sprites (broken)
- `autoplay = ""` (keine automatische Animation)
- `frame = 0` (startet auf Frame 0)

> Das Sprite `breaking_hole.png` enthält 2 Frames nebeneinander. Die genaue Tile-Größe richtet sich nach `Constants.TILE_SIZE` (Standard: 32px → Gesamtbreite 64px, jeder Frame 32×32px).

---

## Aufgabe 3: Kein Inventar-Eintrag, keine ObjectDefinition

Wie `Hole` ist `BreakingHole` ein **Designer-Only-Objekt**:
- Kein Eintrag in `starting_inventory`
- Keine `.tres`-Datei unter `resources/object_definitions/`
- Wird vom Designer direkt als Kind von `DesignerObjectsContainer` in der Level-Szene platziert
- `LevelController._load_designer_objects()` registriert es automatisch beim Start

---

## Akzeptanzkriterien

- [ ] `scripts/objects/breaking_hole.gd` existiert mit `class_name BreakingHole extends PlaceableObject`
- [ ] `scenes/objects/breaking_hole.tscn` existiert mit `AnimatedSprite2D` (Name exakt: `"AnimatedSprite2D"`)
- [ ] `breaking_hole.png` wird korrekt als 2-Frame-Sprite konfiguriert (Frame 0 = intact, Frame 1 = broken)
- [ ] Erster Lemming der das Tile betritt: läuft normal weiter, kein Tod
- [ ] Nachdem der erste Lemming das Tile **verlassen** hat: Sprite wechselt zu Frame 1
- [ ] Jeder weitere Lemming der das Tile betritt wenn `_state == BROKEN`: stirbt mit Schrumpf-Animation (wie normales `Hole`)
- [ ] Betritt ein zweiter Lemming das Tile **bevor** der erste es verlassen hat: noch harmlos (kein Tod)
- [ ] Lemming der stirbt (z.B. durch anderen Effekt) während er beobachtet wird: BreakingHole bricht trotzdem auf
- [ ] Der Spieler kann das BreakingHole nicht entfernen (Designer-Only)
- [ ] Keine anderen bestehenden Dateien werden verändert

