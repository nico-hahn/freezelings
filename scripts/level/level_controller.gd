## LevelController
# Script für die Root-Node jeder Level-Szene.
# Orchestriert alle Level-Systeme: TileMap, Spawner, Lemminge, Objekte.
# Konfiguration erfolgt über @export-Variablen im Godot-Editor.

class_name LevelController
extends Node2D

## Gesamtanzahl der Lemminge die gespawnt werden.
@export var total_lemmings: int = 10

## Mindestanzahl zu rettender Lemminge für Level-Erfolg.
@export var required_saved: int = 7

## Alle N Ticks wird ein neuer Lemming gespawnt.
@export var spawn_interval: int = 3

## Startrichtung aller Lemminge.
@export var start_direction: Enums.Direction = Enums.Direction.EAST

## Inventar des Spielers für dieses Level.
## Key: object_type (String, z.B. "direction_arrow_north")
## Value: Anzahl (int)
## Beispiel: {"direction_arrow_north": 3, "direction_arrow_east": 2, "blocker": 1}
@export var starting_inventory: Dictionary = {}

## Mindestanzahl geretteter Lemminge für 1 Stern.
@export var stars_threshold_1: int = 1
## Mindestanzahl geretteter Lemminge für 2 Sterne.
@export var stars_threshold_2: int = 5
## Mindestanzahl geretteter Lemminge für 3 Sterne.
@export var stars_threshold_3: int = 8

# Interne Node-Referenzen (werden in _ready() gefunden)
var _walls_layer: TileMapLayer
var _entry_point: Marker2D
var _exit_point: Marker2D
var _lemming_spawner: Node        ## LemmingSpawner
var _lemmings_container: Node2D
var _placed_objects_container: Node2D
var _designer_objects_container: Node2D

## Aktuell platzierte Objekte: Vector2i → PlaceableObject-Node
var placed_objects: Dictionary = {}

## Objekte die der Designer platziert hat: Vector2i → PlaceableObject-Node
## Diese Objekte können vom Spieler nicht entfernt werden.
## Designer-Objekte werden direkt im Godot-Editor als Kinder von DesignerObjectsContainer
## in der Level-Szene platziert. Sie müssen eine PlaceableObject-Unterklasse sein.
## Ihre grid_pos wird automatisch aus ihrer globalen Position berechnet.
## Der Spieler kann diese Objekte nicht entfernen.
var designer_objects: Dictionary = {}

## Grid-Position des Ausgangs (gecacht für schnellen Zugriff)
var _exit_grid_pos: Vector2i


func _ready() -> void:
	# Kind-Nodes finden
	_walls_layer = $Walls as TileMapLayer
	_entry_point = $Markers/EntryPoint as Marker2D
	_exit_point = $Markers/ExitPoint as Marker2D
	_lemming_spawner = $LemmingSpawner
	_lemmings_container = $LemmingsContainer as Node2D
	_placed_objects_container = $PlacedObjectsContainer as Node2D
	_designer_objects_container = $DesignerObjectsContainer as Node2D

	# Exit-Position cachen
	_exit_grid_pos = world_to_grid(_exit_point.global_position)

	# GameManager informieren
	GameManager.initialize_level(total_lemmings, required_saved)

	# Spawner initialisieren
	var entry_grid: Vector2i = world_to_grid(_entry_point.global_position)
	_lemming_spawner.initialize(entry_grid, spawn_interval, total_lemmings, start_direction)

	# Designer-Objekte einlesen
	_load_designer_objects()

	# TickManager starten und sofort pausieren – Spieler startet manuell
	TickManager.start()
	TickManager.pause()


## Liest Designer-Objekte aus DesignerObjectsContainer und registriert sie im Dictionary.
func _load_designer_objects() -> void:
	for child in _designer_objects_container.get_children():
		if child is PlaceableObject:
			var obj := child as PlaceableObject
			var grid_pos_obj: Vector2i = world_to_grid(obj.global_position)
			obj.grid_pos = grid_pos_obj
			designer_objects[grid_pos_obj] = obj


## Gibt true zurück wenn das Tile begehbar ist (kein Wand-Tile, kein Blocker).
func is_tile_walkable(grid_pos: Vector2i) -> bool:
	# Wand-Prüfung: Wenn source_id != -1 ist ein Tile vorhanden = Wand
	if _walls_layer.get_cell_source_id(grid_pos) != -1:
		return false
	# Blocker-Prüfung (beide Container)
	if has_placed_object(grid_pos):
		var obj := get_placed_object(grid_pos)
		if obj != null and obj.get_object_type() == "blocker":
			return false
	return true


## Gibt true zurück wenn das Tile der Ausgang ist.
func is_tile_exit(grid_pos: Vector2i) -> bool:
	return grid_pos == _exit_grid_pos


## Gibt true zurück wenn auf dem Tile ein platzierbares Objekt liegt (beide Container).
func has_placed_object(grid_pos: Vector2i) -> bool:
	return placed_objects.has(grid_pos) or designer_objects.has(grid_pos)


## Gibt das platzierte Objekt auf dem Tile zurück (beide Container), oder null.
## placed_objects hat Vorrang vor designer_objects.
func get_placed_object(grid_pos: Vector2i) -> Node:
	if placed_objects.has(grid_pos):
		return placed_objects.get(grid_pos, null)
	return designer_objects.get(grid_pos, null)


## Platziert ein Objekt auf dem Grid.
## Gibt true zurück wenn erfolgreich, false wenn das Tile nicht geeignet ist.
func place_object(grid_pos: Vector2i, definition: ObjectDefinition) -> bool:
	# Validierung
	if not is_tile_walkable(grid_pos):
		return false
	if has_placed_object(grid_pos):
		return false
	if is_tile_exit(grid_pos):
		return false
	if world_to_grid(_entry_point.global_position) == grid_pos:
		return false

	# Objekt instanzieren
	var obj: Node2D = definition.scene.instantiate() as Node2D
	# exported_properties vor add_child setzen damit _ready() die Werte bereits sieht
	for key: String in definition.exported_properties:
		obj.set(key, definition.exported_properties[key])
	_placed_objects_container.add_child(obj)
	obj.global_position = grid_to_world(grid_pos)
	obj.grid_pos = grid_pos
	placed_objects[grid_pos] = obj
	return true


## Entfernt ein platziertes Objekt vom Grid.
func remove_object(grid_pos: Vector2i) -> void:
	if not placed_objects.has(grid_pos):
		return
	var obj: Node = placed_objects[grid_pos]
	obj.queue_free()
	placed_objects.erase(grid_pos)


## Rechnet eine Weltposition in eine Grid-Position um.
func world_to_grid(world_pos: Vector2) -> Vector2i:
	return _walls_layer.local_to_map(_walls_layer.to_local(world_pos))


## Rechnet eine Grid-Position in den Weltmittelpunkt des Tiles um.
func grid_to_world(grid_pos: Vector2i) -> Vector2:
	return _walls_layer.to_global(_walls_layer.map_to_local(grid_pos))


func get_entry_grid_pos() -> Vector2i:
	return world_to_grid(_entry_point.global_position)


func get_exit_grid_pos() -> Vector2i:
	return _exit_grid_pos


## Aufgerufen wenn ein Lemming den Ausgang erreicht hat.
## Verbunden in LemmingSpawner._spawn_lemming() für jede Lemming-Instanz.
func _on_lemming_reached_exit(lemming: Lemming) -> void:
	GameManager.on_lemming_saved()
	lemming.queue_free()


## Aufgerufen wenn ein Lemming gestorben ist.
## Verbunden in LemmingSpawner._spawn_lemming() für jede Lemming-Instanz.
func _on_lemming_died(lemming: Lemming) -> void:
	GameManager.on_lemming_died()
	lemming.queue_free()


## Berechnet die erreichte Stern-Zahl basierend auf saved_count.
func calculate_stars(saved_count: int) -> int:
	if saved_count >= stars_threshold_3:
		return 3
	elif saved_count >= stars_threshold_2:
		return 2
	elif saved_count >= stars_threshold_1:
		return 1
	return 0
