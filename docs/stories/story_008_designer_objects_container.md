# Story 008 – Designer-Objekt-Container (nicht entfernbar)

**Status**: 🟡 Bereit zur Implementierung  
**Priorität**: Hoch – Voraussetzung für story_009 (Hole-Objekt)

---

## Ziel

Einen zweiten Objekt-Container `DesignerObjectsContainer` einführen, in dem der Level-Designer Objekte platzieren kann, die der Spieler **nicht entfernen** kann. Diese Objekte interagieren vollständig mit der Spiellogik (Lemminge reagieren auf `apply_to_lemming()`), sind aber vor Spieler-Eingaben geschützt.

**Rendering-Reihenfolge**: Designer-Objekte sollen **unter** den Lemmingen gerendert werden. Da Godot 2D-Nodes in Baumreihenfolge rendert (weiter oben = früher = dahinter), muss `DesignerObjectsContainer` im Szenenbaum **vor** `LemmingsContainer` stehen.

---

## Kontext

Aktuell prüft `LevelController.has_placed_object()` / `get_placed_object()` ausschließlich das `placed_objects`-Dictionary, das nur Spieler-platzierte Objekte enthält. `game.gd` ruft `remove_object()` auf Basis dieses Dictionarys auf – Designer-Objekte tauchen dort gar nicht auf und wären damit schon sicher. Das Problem ist aber, dass die Lemming-Bewegungslogik ebenfalls nur `has_placed_object()` prüft. Designer-Objekte müssen also in die Abfrage integriert werden, ohne entfernbar zu sein.

---

## Aufgabe 1: `level_base.tscn` – `DesignerObjectsContainer` hinzufügen

Node in `level_base.tscn` einfügen, **vor** `LemmingsContainer`:

```
LevelBase (Node2D)
├── Camera2D
├── Ground (TileMapLayer)
├── Walls (TileMapLayer)
├── Markers (Node2D)
├── LemmingSpawner
├── DesignerObjectsContainer (Node2D)   ← NEU; vor LemmingsContainer!
├── LemmingsContainer (Node2D)
└── PlacedObjectsContainer (Node2D)
```

> `DesignerObjectsContainer` liegt vor `LemmingsContainer` im Baum → wird zuerst gerendert → erscheint visuell darunter.

---

## Aufgabe 2: `level_controller.gd` – zweites Dictionary und neue Abfragen

### Neues Feld

```gdscript
var _designer_objects_container: Node2D

## Objekte die der Designer platziert hat: Vector2i → PlaceableObject-Node
## Diese Objekte können vom Spieler nicht entfernt werden.
var designer_objects: Dictionary = {}
```

### In `_ready()` ergänzen

```gdscript
_designer_objects_container = $DesignerObjectsContainer as Node2D
_load_designer_objects()
```

### `_load_designer_objects()` – Designer-Objekte beim Start einlesen

Designer-Objekte werden vom Designer direkt als Kinder von `DesignerObjectsContainer` in der Level-Szene platziert (im Godot-Editor). Beim Start werden sie eingelesen und im `designer_objects`-Dictionary registriert, damit die Spiellogik sie findet:

```gdscript
func _load_designer_objects() -> void:
	for child in _designer_objects_container.get_children():
		if child is PlaceableObject:
			var obj := child as PlaceableObject
			var grid_pos_obj: Vector2i = world_to_grid(obj.global_position)
			obj.grid_pos = grid_pos_obj
			designer_objects[grid_pos_obj] = obj
```

### Bestehende Abfragen erweitern

`has_placed_object()` und `get_placed_object()` müssen beide Dictionaries prüfen:

```gdscript
func has_placed_object(grid_pos: Vector2i) -> bool:
	return placed_objects.has(grid_pos) or designer_objects.has(grid_pos)

func get_placed_object(grid_pos: Vector2i) -> Node:
	if placed_objects.has(grid_pos):
		return placed_objects.get(grid_pos, null)
	return designer_objects.get(grid_pos, null)
```

`is_tile_walkable()` prüft Blocker bereits über `has_placed_object()` → funktioniert automatisch korrekt für beide Container.

### `remove_object()` bleibt unverändert

`remove_object()` greift ausschließlich auf `placed_objects` zu – Designer-Objekte in `designer_objects` sind damit automatisch vor Entfernung geschützt. Keine Änderung nötig.

---

## Aufgabe 3: Workflow für den Designer dokumentieren

Im Kommentar von `level_controller.gd` festhalten (kein Code, nur Kommentar):

```gdscript
## Designer-Objekte werden direkt im Godot-Editor als Kinder von DesignerObjectsContainer
## in der Level-Szene platziert. Sie müssen eine PlaceableObject-Unterklasse sein.
## Ihre grid_pos wird automatisch aus ihrer globalen Position berechnet.
## Der Spieler kann diese Objekte nicht entfernen.
```

---

## Akzeptanzkriterien

- [ ] `level_base.tscn` hat `DesignerObjectsContainer` als `Node2D` **vor** `LemmingsContainer`
- [ ] `level_controller.gd` hat `designer_objects: Dictionary` und `_load_designer_objects()`
- [ ] `has_placed_object()` findet Objekte in beiden Containern
- [ ] `get_placed_object()` gibt Objekte aus beiden Containern zurück
- [ ] `remove_object()` entfernt **nur** Objekte aus `placed_objects` (Designer-Objekte bleiben)
- [ ] `game.gd` – `_try_remove_object()` – bleibt unverändert (funktioniert korrekt durch obige Logik)
- [ ] Designer-Objekte rendern visuell unter den Lemmingen
- [ ] Bestehende Level (`level_01.tscn`, `level_02.tscn`) funktionieren unverändert weiter

