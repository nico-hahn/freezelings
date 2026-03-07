## InventorySlot
# Ein einzelner Slot im Inventar-Panel.
# Zeigt Icon, Objekt-Name und verbleibende Anzahl.
# Emittiert slot_pressed wenn angeklickt.

class_name InventorySlot
extends PanelContainer

## Emittiert wenn der Spieler diesen Slot anklickt.
signal slot_pressed

@onready var _icon: TextureRect = $VBoxContainer/Icon
@onready var _count_label: Label = $VBoxContainer/CountLabel
@onready var _button: Button = $Button   # Unsichtbarer Button über dem ganzen Slot

var _object_type: String = ""
var _count: int = 0
var _is_selected: bool = false


## Initialisiert den Slot.
func setup(object_type: String, count: int, definition: ObjectDefinition) -> void:
	_object_type = object_type
	_count = count

	if definition != null:
		if definition.icon != null:
			_icon.texture = definition.icon
		_button.tooltip_text = definition.display_name

	_count_label.text = str(count)
	_button.pressed.connect(_on_button_pressed)

	# Slot deaktivieren wenn count == 0
	_update_availability()


## Aktualisiert die angezeigte Anzahl.
func set_count(new_count: int) -> void:
	_count = new_count
	_count_label.text = str(_count)
	_update_availability()


func get_object_type() -> String:
	return _object_type


func get_count() -> int:
	return _count


## Setzt den visuellen Ausgewählt-Zustand des Slots.
func set_selected(selected: bool) -> void:
	_is_selected = selected
	_update_availability()


func _on_button_pressed() -> void:
	if _count > 0:
		slot_pressed.emit()


func _update_availability() -> void:
	if _count <= 0:
		modulate = Color(0.5, 0.5, 0.5, 1.0)
	elif _is_selected:
		modulate = Color(1.0, 0.85, 0.2, 1.0)  # Gold-Highlight
	else:
		modulate = Color.WHITE

