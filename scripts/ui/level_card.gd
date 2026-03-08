## LevelCard
# Einzelne Level-Karte in der Level-Auswahl.
# Zeigt Level-Name, Sterne und einen gesperrten Zustand.

class_name LevelCard
extends PanelContainer

signal card_pressed(level_index: int)

@onready var _name_label: Label = %LevelNameLabel
@onready var _stars_label: Label = %StarsLabel
@onready var _locked_overlay: MarginContainer = %LockedOverlay

var _level_index: int = -1
var _unlocked: bool = false


func setup(definition: LevelDefinition, stars: int, unlocked: bool) -> void:
	_level_index = definition.level_index
	_unlocked = unlocked
	_name_label.text = definition.level_name
	_stars_label.text = _build_stars_string(stars)
	_locked_overlay.visible = not unlocked
	# Gesperrte Karten sind nicht klickbar
	mouse_filter = Control.MOUSE_FILTER_STOP if unlocked else Control.MOUSE_FILTER_IGNORE


func _gui_input(event: InputEvent) -> void:
	if _unlocked and event is InputEventMouseButton:
		var mouse_event := event as InputEventMouseButton
		if mouse_event.button_index == MOUSE_BUTTON_LEFT and mouse_event.pressed:
			card_pressed.emit(_level_index)


func _build_stars_string(stars: int) -> String:
	var result: String = ""
	for i in range(3):
		result += "⭐" if i < stars else "☆"
	return result
