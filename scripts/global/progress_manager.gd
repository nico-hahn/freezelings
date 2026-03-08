## ProgressManager
# Autoload "ProgressManager"
# Hält die Level-Registry und den Spielfortschritt (Sterne, Freischaltung).

extends Node

const SAVE_PATH: String = "user://save_data.json"

## Alle verfügbaren Level in der gewünschten Reihenfolge.
## Wird automatisch aus resources/level_definitions/ geladen wenn leer.
## Kann im Editor-Inspector des Autoloads manuell befüllt werden.
@export var level_definitions: Array[LevelDefinition] = []

## Aktuell ausgewähltes Level (wird vor dem Szenenwechsel zu game.tscn gesetzt).
var current_level_index: int = 0

## Fortschrittsdaten: level_index → { "stars": int, "unlocked": bool }
## Wird in _ready() initialisiert und von story_005 mit Persistenz erweitert.
var _progress: Dictionary = {}


func _ready() -> void:
	# Fallback: Definitionen automatisch laden wenn Array im Editor nicht befüllt wurde
	if level_definitions.is_empty():
		_load_definitions_from_resources()
	load_progress()         # Zuerst laden
	_initialize_progress()  # Dann fehlende Einträge mit Standardwerten füllen


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
	save_progress()


## Speichert den aktuellen Fortschritt als JSON in user://save_data.json.
func save_progress() -> void:
	var save_data: Dictionary = {}
	for index in _progress.keys():
		save_data[str(index)] = _progress[index]
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		push_error("ProgressManager: Konnte Savefile nicht öffnen: " + SAVE_PATH)
		return
	file.store_string(JSON.stringify(save_data))
	file.close()


## Lädt Fortschrittsdaten aus user://save_data.json.
## Wird in _ready() vor _initialize_progress() aufgerufen.
func load_progress() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return   # Kein Savefile vorhanden → Standardwerte bleiben
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		push_error("ProgressManager: Konnte Savefile nicht lesen: " + SAVE_PATH)
		return
	var content: String = file.get_as_text()
	file.close()
	var parsed = JSON.parse_string(content)
	if parsed == null or not parsed is Dictionary:
		push_error("ProgressManager: Savefile ist kein gültiges JSON.")
		return
	for key in parsed.keys():
		var index: int = int(key)
		_progress[index] = parsed[key]


## Initialisiert _progress mit Standardwerten für alle bekannten Level.
func _initialize_progress() -> void:
	for definition in level_definitions:
		var idx: int = definition.level_index
		if not _progress.has(idx):
			_progress[idx] = {"stars": 0, "unlocked": idx == 0}


## Lädt alle LevelDefinition-.tres Dateien.
## Explizite preload()-Aufrufe damit Godot die Dateien beim Export erkennt und mitnimmt.
## Neue Level hier eintragen.
func _load_definitions_from_resources() -> void:
	var definitions: Array[LevelDefinition] = [
		preload("res://resources/level_definitions/level_01.tres"),
		preload("res://resources/level_definitions/level_02.tres"),
		preload("res://resources/level_definitions/level_03.tres"),
		preload("res://resources/level_definitions/level_04.tres"),
	]
	for def in definitions:
		if def != null:
			level_definitions.append(def)
	level_definitions.sort_custom(func(a: LevelDefinition, b: LevelDefinition) -> bool:
		return a.level_index < b.level_index)
