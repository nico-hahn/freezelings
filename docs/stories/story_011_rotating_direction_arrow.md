# Story 011 – RotatingDirectionArrow-Objekt

**Status**: 🟡 Bereit zur Implementierung  
**Priorität**: Normal  
**Voraussetzungen**: story_008 (`DesignerObjectsContainer`), story_010 (`BreakingHole`) – die Beobachtungs-Logik per `TickManager.tick_happened` mit `CONNECT_ONE_SHOT` ist bekannt und wird hier analog eingesetzt.

---

## Ziel

Ein neues Objekt `RotatingDirectionArrow` einführen. Es funktioniert wie der normale `DirectionArrow` – lenkt Lemminge in `target_direction` – rotiert aber seine Richtung um `90° * k` im Uhrzeigersinn, sobald ein Lemming das Tile verlassen hat. `k` ist per `@export` konfigurierbar (Standard: `k = 2`).

---

## Spielmechanik im Detail

| Ereignis | Verhalten |
|----------|-----------|
| Lemming betritt das Tile | `lemming.direction = target_direction` (wie normaler DirectionArrow) |
| Lemming verlässt das Tile | `target_direction = (target_direction + k) % 4`; Sprite-Frame aktualisieren |
| Nächster Lemming betritt das Tile | Bekommt die bereits rotierte Richtung |

**Rotation im Uhrzeigersinn:** Die `Direction`-Enum ist `NORTH=0, EAST=1, SOUTH=2, WEST=3` – das entspricht bereits dem Uhrzeigersinn. Eine Rotation um 90° CW = `+1 mod 4`, um 180° = `+2 mod 4`, etc.

**Wann verlässt der Lemming das Tile?** Identische Logik wie `BreakingHole`: nach `apply_to_lemming()` einmalig auf `TickManager.tick_happened` hören (`CONNECT_ONE_SHOT`), dann `lemming.grid_pos != grid_pos` prüfen.

---

## Aufgabe 1: `scripts/objects/rotating_direction_arrow.gd`

```gdscript
class_name RotatingDirectionArrow
extends PlaceableObject

## Aktuelle Zielrichtung. Wird nach jedem Lemming-Durchgang rotiert.
@export var target_direction: Enums.Direction = Enums.Direction.NORTH

## Anzahl der 90°-Schritte im Uhrzeigersinn nach jedem Lemming-Durchgang.
## k=1 → 90°, k=2 → 180°, k=3 → 270°
@export var k: int = 2

@onready var _sprite: Sprite2D = $Sprite2D

var _watched_lemming: Lemming = null


func _ready() -> void:
	_update_sprite()


func apply_to_lemming(lemming: Lemming) -> void:
	lemming.direction = target_direction
	# Beobachten wann der Lemming das Tile verlässt
	_watched_lemming = lemming
	TickManager.tick_happened.connect(_on_tick_watching, CONNECT_ONE_SHOT)


func _on_tick_watching(_tick_number: int) -> void:
	if _watched_lemming == null or not is_instance_valid(_watched_lemming):
		# Lemming existiert nicht mehr – trotzdem rotieren
		_rotate_direction()
		return
	if _watched_lemming.grid_pos != grid_pos:
		# Lemming hat das Tile verlassen → rotieren
		_watched_lemming = null
		_rotate_direction()
	else:
		# Lemming steht noch drauf – weiter beobachten
		TickManager.tick_happened.connect(_on_tick_watching, CONNECT_ONE_SHOT)


func _rotate_direction() -> void:
	target_direction = (target_direction + k) % 4 as Enums.Direction
	_update_sprite()


func _update_sprite() -> void:
	if _sprite == null:
		return
	# Sprite-Sheet-Reihenfolge identisch mit Direction-Enum: NORTH=0, EAST=1, SOUTH=2, WEST=3
	_sprite.frame = target_direction as int


func get_object_type() -> String:
	return "rotating_direction_arrow"
```

---

## Aufgabe 2: `scenes/objects/rotating_direction_arrow.tscn`

**Node-Hierarchie:**

```
RotatingDirectionArrow (Node2D)        Script: scripts/objects/rotating_direction_arrow.gd
└── Sprite2D                           Name: "Sprite2D"
                                       Textur: res://assets/direction_arrows_rotating.png
                                       hframes = 4, vframes = 1
                                       frame = 0
```

> `direction_arrows_rotating.png` ist identisch aufgebaut wie `direction_arrows.png` (4 Frames horizontal: NORTH, EAST, SOUTH, WEST). `hframes = 4` setzen damit das Sprite-Sheet korrekt aufgeteilt wird.

---

## Aufgabe 3: Verwendung – Designer vs. Spieler

Der `RotatingDirectionArrow` kann **beides** sein:

- **Spieler-platzierbar**: `ObjectDefinition`-Resource anlegen und ins `starting_inventory` des Levels eintragen (analog zu `direction_arrow_north.tres` etc.)
- **Designer-Only**: Direkt als Kind von `DesignerObjectsContainer` in der Level-Szene platzieren

Da `get_object_type()` `"rotating_direction_arrow"` zurückgibt (ohne Richtungssuffix), reicht **eine einzige** `ObjectDefinition`-Resource – die Startrichtung wird per `@export var target_direction` im Inspector gesetzt.

**Für Spieler-Platzierung** (optional, nur wenn gewünscht):

```
resources/object_definitions/rotating_direction_arrow.tres
  object_id = "rotating_direction_arrow"
  display_name = "Drehender Pfeil"
  scene = res://scenes/objects/rotating_direction_arrow.tscn
  icon = ...
```

> Diese Resource nur anlegen wenn das Objekt tatsächlich ins Spieler-Inventar soll. Vorerst reicht Designer-Only.

---

## Akzeptanzkriterien

- [ ] `scripts/objects/rotating_direction_arrow.gd` existiert mit `class_name RotatingDirectionArrow extends PlaceableObject`
- [ ] `scenes/objects/rotating_direction_arrow.tscn` existiert mit `Sprite2D` und `direction_arrows_rotating.png`
- [ ] `hframes = 4` am Sprite gesetzt; Frame wechselt korrekt mit `target_direction`
- [ ] Lemming betritt Tile → bekommt aktuelle `target_direction`
- [ ] Nachdem Lemming das Tile verlassen hat: `target_direction` rotiert um `k * 90°` CW
- [ ] Sprite zeigt nach der Rotation die neue Richtung (Frame aktualisiert)
- [ ] `k = 2` ist der Standardwert; im Inspector änderbar
- [ ] `target_direction` ist im Inspector änderbar (Startrichtung für jede Instanz individuell)
- [ ] Betritt ein zweiter Lemming das Tile bevor der erste es verlassen hat: bekommt die aktuelle (noch nicht rotierte) Richtung, Rotation wird erst ausgelöst wenn der **beobachtete** (erste) Lemming das Tile verlässt
- [ ] Keine anderen bestehenden Dateien werden verändert

