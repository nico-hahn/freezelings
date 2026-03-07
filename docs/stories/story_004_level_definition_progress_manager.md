# Story 004 – LevelDefinition Resource & ProgressManager Autoload

**Status**: 🟡 Bereit zur Implementierung  
**Priorität**: Hoch – Voraussetzung für story_005, story_006, story_007  
**Implementiere diese Story vor allen anderen Phase-6-Stories.**

---

## Ziel

Eine `LevelDefinition`-Resource-Klasse einführen, die ein Level beschreibt (Name, Szenen-Pfad, Index). Einen neuen Autoload `ProgressManager` anlegen, der die Level-Registry hält und Fortschrittsdaten bereitstellt (noch ohne Persistenz – das kommt in story_005).

---

## Aufgabe 1: `scripts/resources/level_definition.gd`

Neue Resource-Klasse:

```gdscript
class_name LevelDefinition
extends Resource

## Anzeigename des Levels in der Level-Auswahl.
@export var level_name: String = ""

## Res-Pfad zur Level-Szene.
@export var scene_path: String = ""

## 0-basierter Index. Bestimmt Reihenfolge und Freischaltungs-Logik.
## Level 0 ist immer freigeschaltet. Level N wird freigeschaltet wenn Level N-1 >= 1 Stern hat.
@export var level_index: int = 0
```

---

## Aufgabe 2: `resources/level_definitions/level_01.tres`

`.tres`-Datei für das erste Level anlegen:

```
[gd_resource type="Resource" script_class="LevelDefinition" format=3]

[ext_resource type="Script" path="res://scripts/resources/level_definition.gd" id="1_ld"]

[resource]
script = ExtResource("1_ld")
level_name = "Level 01"
scene_path = "res://scenes/levels/level_01.tscn"
level_index = 0
```

> Für jedes weitere Level das der Designer anlegt, muss analog eine `.tres`-Datei erstellt und im ProgressManager registriert werden.

---

## Aufgabe 3: `scripts/global/progress_manager.gd`

Neuer Autoload. Hält die Level-Registry und stellt Fortschrittsdaten bereit. Persistenz wird in story_005 ergänzt – hier nur die Grundstruktur mit in-memory Daten.

```gdscript
## ProgressManager
# Autoload "ProgressManager"
# Hält die Level-Registry und den Spielfortschritt (Sterne, Freischaltung).
# Persistenz (Speichern/Laden) wird in story_005 ergänzt.

extends Node

## Alle verfügbaren Level in der gewünschten Reihenfolge.
## Im Godot-Editor befüllen (Inspector des Autoloads).
@export var level_definitions: Array[LevelDefinition] = []

## Aktuell ausgewähltes Level (wird vor dem Szenenwechsel zu game.tscn gesetzt).
var current_level_index: int = 0

## Fortschrittsdaten: level_index → { "stars": int, "unlocked": bool }
## Wird in _ready() initialisiert und von story_005 mit Persistenz erweitert.
var _progress: Dictionary = {}


func _ready() -> void:
	_initialize_progress()


## Gibt alle LevelDefinitions zurück.
func get_level_definitions() -> Array[LevelDefinition]:
	return level_definitions


## Gibt die LevelDefinition für den aktuell ausgewählten Level-Index zurück.
func get_current_level_definition() -> LevelDefinition:
	if current_level_index < level_definitions.size():
		return level_definitions[current_level_index]
	push_error("ProgressManager: current_level_index out of range: " + str(current_level_index))
	return null


## Gibt true zurück wenn das Level mit diesem Index freigeschaltet ist.
func is_level_unlocked(index: int) -> bool:
	if index == 0:
		return true
	return _progress.get(index, {}).get("unlocked", false)


## Gibt die erreichten Sterne (0-3) für ein Level zurück.
func get_stars(index: int) -> int:
	return _progress.get(index, {}).get("stars", 0)


## Speichert das Ergebnis eines abgeschlossenen Levels.
## Schaltet das nächste Level frei wenn stars >= 1.
## Überschreibt nur wenn die neue Stern-Zahl höher ist.
func record_level_result(index: int, stars: int) -> void:
	var current_stars: int = get_stars(index)
	if stars > current_stars:
		_progress[index] = {"stars": stars, "unlocked": true}
	# Nächstes Level freischalten
	if stars >= 1:
		var next_index: int = index + 1
		if next_index < level_definitions.size():
			if not _progress.has(next_index):
				_progress[next_index] = {"stars": 0, "unlocked": true}
			else:
				_progress[next_index]["unlocked"] = true
	# Persistenz: wird in story_005 hier aufgerufen → save_progress()


## Initialisiert _progress mit Standardwerten für alle bekannten Level.
func _initialize_progress() -> void:
	for definition in level_definitions:
		var idx: int = definition.level_index
		if not _progress.has(idx):
			_progress[idx] = {"stars": 0, "unlocked": idx == 0}
```

---

## Aufgabe 4: `project.godot` – Autoload registrieren

`ProgressManager` nach `GameManager` eintragen:

```ini
[autoload]
Enums="*res://scripts/global/enums.gd"
Constants="*res://scripts/global/constants.gd"
TickManager="*res://scripts/global/tick_manager.gd"
GameManager="*res://scripts/global/game_manager.gd"
ProgressManager="*res://scripts/global/progress_manager.gd"
```

---

## Aufgabe 5: ProgressManager im Editor konfigurieren

Nach dem Registrieren des Autoloads: In Godot den `ProgressManager`-Node im Autoload-Inspector öffnen und `level_definitions` mit der `level_01.tres` befüllen.

---

## Akzeptanzkriterien

- [ ] `scripts/resources/level_definition.gd` existiert mit `class_name LevelDefinition`
- [ ] `resources/level_definitions/level_01.tres` existiert und referenziert die korrekte Szene
- [ ] `scripts/global/progress_manager.gd` existiert und ist als Autoload `ProgressManager` registriert
- [ ] `ProgressManager.is_level_unlocked(0)` gibt immer `true` zurück
- [ ] `ProgressManager.record_level_result(0, 3)` schaltet Index 1 frei
- [ ] `ProgressManager.get_current_level_definition()` gibt die richtige LevelDefinition zurück
- [ ] Keine anderen bestehenden Dateien werden verändert (außer `project.godot`)

