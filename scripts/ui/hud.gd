## HUD
# Verwaltet alle UI-Elemente während des Spiels:
# - Inventar-Panel (platzierbare Objekte)
# - Freezeling-Zähler (gerettet/gesamt) – Lemminge heißen gegenüber dem Spieler "Freezelings"
# - Pause-Button
# - Optional: Tick-Geschwindigkeit

class_name HUD
extends CanvasLayer

## Emittiert wenn der Spieler ein Objekt im Inventar auswählt.
signal object_selected(object_type: String)

## Emittiert wenn der Spieler den Pause-Button drückt.
signal pause_toggled

# Node-Referenzen (im Editor über @ oder $-Pfade setzen)
@onready var _total_label: Label = $TopBar/StatsContainer/TotalLabel
@onready var _saved_label: Label = $TopBar/StatsContainer/SavedLabel
@onready var _pause_button: Button = $BottomBar/PauseButton
@onready var _inventory_panel: HBoxContainer = $BottomBar/InventoryPanel

## Aktuell ausgewählter Objekt-Typ (wird auch im game.gd benötigt)
var selected_object_type: String = ""

## Szene für Inventar-Slots (im Editor zuweisen)
@export var inventory_slot_scene: PackedScene

var _pause_tween: Tween = null

const WOBBLE_ANGLE: float = 12.0
const WOBBLE_SPEED: float = 0.08
const WOBBLE_PAUSE: float = 0.25


func _ready() -> void:
	_pause_button.pressed.connect(_on_pause_button_pressed)

	# Auf GameManager-Signale hören
	GameManager.lemming_counts_changed.connect(_on_lemming_counts_changed)
	GameManager.game_state_changed.connect(_on_game_state_changed)

	# Auf TickManager-Signale hören
	TickManager.paused.connect(func(): set_paused(true))
	TickManager.resumed.connect(func(): set_paused(false))


## Baut das Inventar-Panel auf.
## inventory: Dictionary (object_type → count)
## definitions: Array[ObjectDefinition] – alle verfügbaren Definitionen
func setup_inventory(inventory: Dictionary, definitions: Array) -> void:
	# Alte Slots entfernen
	for child in _inventory_panel.get_children():
		child.queue_free()

	# Slots erstellen für jeden Eintrag im Inventar
	for object_type: String in inventory.keys():
		var count: int = inventory[object_type]
		if count <= 0:
			continue

		# Definition finden
		var definition: ObjectDefinition = null
		for def in definitions:
			if (def as ObjectDefinition).object_id == object_type:
				definition = def as ObjectDefinition
				break

		if inventory_slot_scene == null:
			push_error("HUD: inventory_slot_scene ist nicht gesetzt!")
			continue

		var slot: Node = inventory_slot_scene.instantiate()
		_inventory_panel.add_child(slot)
		# Slot initialisieren (InventorySlot-Skript hat setup()-Methode)
		slot.setup(object_type, count, definition)
		slot.slot_pressed.connect(_on_slot_pressed.bind(object_type))


## Aktualisiert die Anzahl eines Objekt-Typs im Inventar.
func update_inventory_count(object_type: String, count: int) -> void:
	for child in _inventory_panel.get_children():
		if child.has_method("get_object_type") and child.get_object_type() == object_type:
			child.set_count(count)
			break


## Aktualisiert den Pause-Button-Text je nach Zustand.
func set_paused(paused: bool) -> void:
	if paused:
		_start_wobble()
	else:
		_stop_wobble()


func _start_wobble() -> void:
	_stop_wobble()
	_pause_tween = create_tween()
	_pause_tween.set_loops()
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


func _on_pause_button_pressed() -> void:
	pause_toggled.emit()


func _on_lemming_counts_changed(saved: int, _dead: int, _spawned: int, total: int) -> void:
	_total_label.text = "Total Freezelings: %d" % total
	_saved_label.text = "Saved: %d / %d" % [saved, GameManager.required_saved]


func _on_game_state_changed(_new_state: Enums.GameState) -> void:
	# Pause-Overlay bei PLAYING/PAUSED steuert TickManager-Signale
	# Bei LEVEL_COMPLETE / LEVEL_FAILED: game.gd zeigt End-Screen
	pass


func _on_slot_pressed(object_type: String) -> void:
	selected_object_type = object_type
	# Alle Slots deselektieren, dann den gedrückten hervorheben
	for child in _inventory_panel.get_children():
		if child.has_method("set_selected"):
			child.set_selected(child.get_object_type() == object_type)
	object_selected.emit(object_type)


## Hebt die aktuelle Inventar-Auswahl auf.
## Wird von game.gd nach erfolgreicher Objekt-Platzierung aufgerufen.
func deselect_inventory() -> void:
	selected_object_type = ""
	for child in _inventory_panel.get_children():
		if child.has_method("set_selected"):
			child.set_selected(false)
	object_selected.emit("")


## Tastatur-Shortcut: P zum Pausieren
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		pause_toggled.emit()

