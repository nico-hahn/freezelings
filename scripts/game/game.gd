## Game
# Haupt-Spielszene. Lädt Level, verwaltet Input für Objekt-Platzierung,
# verbindet HUD mit dem Spielsystem.

extends Node2D

@onready var _level_root: Node2D = $LevelRoot
@onready var _hud: HUD = $HUD
# Kamera sitzt jetzt im Level (level_base.tscn), nicht mehr in game.tscn.
# Wird nach Level-Laden aus dem LevelController geholt.
var _camera: LevelCamera = null

## Alle verfügbaren ObjectDefinitions (im Editor per Array befüllen oder per load)
@export var object_definitions: Array[ObjectDefinition] = []

## Aktuell ausgewählter Objekt-Typ (aus dem Inventar)
var _selected_object_type: String = ""

## Aktuelles Inventar (Kopie aus LevelController, wird hier verwaltet)
var _inventory: Dictionary = {}

## Referenz auf den aktiven LevelController
var _level_controller: LevelController = null


func _ready() -> void:
	# GameManager kennt den LevelRoot
	GameManager._level_root = _level_root

	# HUD-Signale verbinden
	_hud.object_selected.connect(_on_object_selected)
	_hud.pause_toggled.connect(TickManager.toggle_pause)

	# GameManager-Signale verbinden
	GameManager.level_completed.connect(_on_level_completed)

	# Level laden (erstes Level als Standard)
	# Für spätere Erweiterung: Level-Select oder Argument übergeben
	GameManager.load_level("res://scenes/levels/level_01.tscn")
	_on_level_loaded()


## Wird aufgerufen nachdem ein Level geladen wurde.
func _on_level_loaded() -> void:
	# LevelController finden
	_level_controller = null
	await get_tree().process_frame   # Warten bis Level-Node bereit ist
	for child in _level_root.get_children():
		if child is LevelController:
			_level_controller = child as LevelController
			break

	if _level_controller == null:
		push_error("Game: Kein LevelController im geladenen Level gefunden!")
		return

	# Kamera aus dem Level holen
	_camera = _level_controller.get_node("Camera2D") as LevelCamera

	# Inventar aus Level laden
	_inventory = _level_controller.starting_inventory.duplicate()

	# HUD aufbauen
	_hud.setup_inventory(_inventory, object_definitions)

	# Kamera auf Level zentrieren
	_center_camera_on_level()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mouse_event := event as InputEventMouseButton
		if mouse_event.button_index == MOUSE_BUTTON_LEFT and mouse_event.pressed:
			# Zuerst prüfen ob auf dem geklickten Tile ein Objekt liegt → entfernen
			var world_pos: Vector2 = get_viewport().get_canvas_transform().affine_inverse() * mouse_event.position
			var grid_pos: Vector2i = _level_controller.world_to_grid(world_pos) if _level_controller else Vector2i.ZERO
			if _level_controller != null and _level_controller.has_placed_object(grid_pos):
				_try_remove_object(mouse_event.position)
				get_viewport().set_input_as_handled()
			elif not _selected_object_type.is_empty():
				_try_place_object(mouse_event.position)
				get_viewport().set_input_as_handled()
		elif mouse_event.button_index == MOUSE_BUTTON_RIGHT and mouse_event.pressed:
			_try_remove_object(mouse_event.position)


func _try_place_object(screen_pos: Vector2) -> void:
	if _selected_object_type.is_empty() or _level_controller == null:
		return
	if not _inventory.has(_selected_object_type) or _inventory[_selected_object_type] <= 0:
		return

	# Screenposition → Weltposition
	var world_pos: Vector2 = get_viewport().get_canvas_transform().affine_inverse() * screen_pos
	var grid_pos: Vector2i = _level_controller.world_to_grid(world_pos)

	# Passende ObjectDefinition finden
	var definition: ObjectDefinition = _get_definition(_selected_object_type)
	if definition == null or definition.scene == null:
		push_error("Game: Keine ObjectDefinition oder Szene für: " + _selected_object_type)
		return

	# Platzieren
	if _level_controller.place_object(grid_pos, definition):
		_inventory[_selected_object_type] -= 1
		_hud.update_inventory_count(_selected_object_type, _inventory[_selected_object_type])
		# Auswahl aufheben → Panning wieder möglich
		_hud.deselect_inventory()


func _try_remove_object(screen_pos: Vector2) -> void:
	if _level_controller == null:
		return
	var world_pos: Vector2 = get_viewport().get_canvas_transform().affine_inverse() * screen_pos
	var grid_pos: Vector2i = _level_controller.world_to_grid(world_pos)

	if _level_controller.has_placed_object(grid_pos):
		var obj: Node = _level_controller.get_placed_object(grid_pos)
		var obj_type: String = obj.get_object_type()
		_level_controller.remove_object(grid_pos)
		# Objekt zurück ins Inventar
		if _inventory.has(obj_type):
			_inventory[obj_type] += 1
			_hud.update_inventory_count(obj_type, _inventory[obj_type])


func _on_object_selected(object_type: String) -> void:
	_selected_object_type = object_type
	# Kamera informieren damit sie Panning bei aktiver Auswahl deaktiviert
	if _camera != null:
		_camera.is_placing_object = not object_type.is_empty()


func _on_level_completed(success: bool) -> void:
	# TODO: Win/Loss-Overlay zeigen
	# Vorerst: kurze Pause dann Neustart
	if success:
		print("Level geschafft! 🎉")
	else:
		print("Level gescheitert! 😢")


func _center_camera_on_level() -> void:
	if _level_controller == null or _camera == null:
		return
	# Mittelpunkt des Levels berechnen (aus TileMapLayer)
	var walls_layer: TileMapLayer = _level_controller.get_node("Walls") as TileMapLayer
	if walls_layer == null:
		return
	var used_rect: Rect2i = walls_layer.get_used_rect()
	var center_grid: Vector2i = used_rect.position + used_rect.size / 2
	# position (lokal) statt global_position – Kamera ist Kind des Level-Nodes
	_camera.position = _level_controller.grid_to_world(center_grid)


func _get_definition(object_type: String) -> ObjectDefinition:
	for def in object_definitions:
		if (def as ObjectDefinition).object_id == object_type:
			return def as ObjectDefinition
	return null
