# Story 012 – Bug: Inventar wird bei Level-Neustart nicht zurückgesetzt

**Status**: 🟡 Bereit zur Implementierung  
**Priorität**: Hoch – betrifft Kernspielbarkeit  
**Typ**: Bugfix

---

## Problem

Wenn der Spieler ein Level über den "Neustart"-Button im Win/Loss-Screen neu startet, wird das Level zwar korrekt neu geladen, aber das Inventar in `game.gd` und das HUD zeigen noch den verbrauchten Zustand aus dem vorigen Durchlauf.

**Ursache:** `GameManager.restart_level()` ruft intern `load_level()` auf, das die Level-Szene neu instanziert. `game.gd` reagiert darauf jedoch nicht – `_on_level_loaded()` wird nur einmalig beim allerersten Start in `_ready()` aufgerufen. Beim Neustart wird weder `_inventory` zurückgesetzt noch `_hud.setup_inventory()` erneut aufgerufen.

---

## Fix

`GameManager` bekommt ein Signal `level_loaded`, das am Ende von `load_level()` emittiert wird. `game.gd` verbindet sich in `_ready()` mit diesem Signal und ruft `_on_level_loaded()` auf. Damit reagiert `game.gd` automatisch auf jeden Ladevorgang – egal ob Erststart, Neustart oder zukünftiger Level-Wechsel.

Der manuelle Aufruf `_on_level_loaded()` in `_ready()` von `game.gd` entfällt damit.

---

## Aufgabe 1: `game_manager.gd` – Signal ergänzen und emittieren

Signal-Deklaration ergänzen:

```gdscript
## Emittiert nachdem eine Level-Szene vollständig instanziert und dem LevelRoot hinzugefügt wurde.
signal level_loaded
```

Am Ende von `load_level()` das Signal emittieren:

```gdscript
func load_level(level_path: String) -> void:
	_current_level_path = level_path
	TickManager.reset()
	if _level_root == null:
		push_error("GameManager: _level_root ist nicht gesetzt.")
		return
	for child in _level_root.get_children():
		child.queue_free()
	var level_scene: PackedScene = load(level_path)
	if level_scene == null:
		push_error("GameManager: Level-Szene konnte nicht geladen werden: " + level_path)
		return
	var level_instance: Node = level_scene.instantiate()
	_level_root.add_child(level_instance)
	level_loaded.emit()   # ← NEU
```

---

## Aufgabe 2: `game.gd` – Signal verbinden, manuellen Aufruf entfernen

In `_ready()` das Signal verbinden **und** den manuellen `_on_level_loaded()`-Aufruf entfernen:

```gdscript
func _ready() -> void:
	GameManager._level_root = _level_root
	_hud.object_selected.connect(_on_object_selected)
	_hud.pause_toggled.connect(TickManager.toggle_pause)
	GameManager.level_completed.connect(_on_level_completed)
	GameManager.level_loaded.connect(_on_level_loaded)   # ← NEU

	var level_def: LevelDefinition = ProgressManager.get_current_level_definition()
	if level_def == null:
		push_error("Game: Keine LevelDefinition im ProgressManager gefunden.")
		return
	GameManager.load_level(level_def.scene_path)
	# _on_level_loaded() wird jetzt über das Signal ausgelöst – kein manueller Aufruf mehr
```

`_on_level_loaded()` selbst bleibt unverändert – sie liest `_level_controller.starting_inventory` aus und ruft `_hud.setup_inventory()` auf, was Inventar und HUD korrekt zurücksetzt.

---

## Akzeptanzkriterien

- [ ] `GameManager` hat ein Signal `level_loaded`
- [ ] `level_loaded` wird am Ende von `load_level()` emittiert – auch beim Neustart über `restart_level()`
- [ ] `game.gd` verbindet sich in `_ready()` mit `GameManager.level_loaded`
- [ ] Der manuelle `_on_level_loaded()`-Aufruf in `game.gd._ready()` ist entfernt
- [ ] Nach einem Neustart zeigt das HUD das vollständige Startkontingent des Levels
- [ ] Objekte die der Spieler im vorigen Durchlauf platziert hat, sind nach dem Neustart nicht mehr im Inventar abgezogen
- [ ] Das Verhalten beim Erststart des Levels bleibt identisch

