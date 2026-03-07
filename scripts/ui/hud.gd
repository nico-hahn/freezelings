## HUD
# Verwaltet alle UI-Elemente während des Spiels:
# - Inventar-Panel (platzierbare Objekte)
# - Lemming-Zähler (gerettet/gesamt)
# - Pause-Button und -Overlay
# - Optional: Tick-Geschwindigkeit

class_name HUD
extends CanvasLayer

## Emittiert wenn der Spieler ein Objekt im Inventar auswählt.
signal object_selected(object_type: String)

## Emittiert wenn der Spieler den Pause-Button drückt.
signal pause_toggled

# Node-Referenzen (im Editor über @ oder $-Pfade setzen)
@onready var _saved_label: Label = $TopBar/SavedLabel
@onready var _pause_button: Button = $TopBar/PauseButton
@onready var _inventory_panel: HBoxContainer = $InventoryPanel
@onready var _pause_overlay: ColorRect = $PauseOverlay

## Aktuell ausgewählter Objekt-Typ (wird auch im game.gd benötigt)
var selected_object_type: String = ""

## Szene für Inventar-Slots (im Editor zuweisen)
@export var inventory_slot_scene: PackedScene


func _ready() -> void:
	_pause_button.pressed.connect(_on_pause_button_pressed)
	_pause_overlay.visible = false

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


## Zeigt oder versteckt das Pause-Overlay.
func set_paused(paused: bool) -> void:
	_pause_overlay.visible = paused
	_pause_button.text = "▶" if paused else "⏸"


func _on_pause_button_pressed() -> void:
	pause_toggled.emit()


func _on_lemming_counts_changed(saved: int, _dead: int, _spawned: int, total: int) -> void:
	_saved_label.text = "Gerettet: %d / %d" % [saved, total]


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

