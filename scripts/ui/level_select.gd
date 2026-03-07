## LevelSelect
# Entry-Point des Spiels. Zeigt alle Level als Karten in einem Grid.
# Freigeschaltete Level sind klickbar, gesperrte ausgegraut.

class_name LevelSelect
extends Control

@onready var _level_grid: GridContainer = $VBoxContainer/LevelGrid

@export var level_card_scene: PackedScene  # Im Editor auf level_card.tscn setzen


func _ready() -> void:
	_build_level_grid()


func _build_level_grid() -> void:
	# Alte Karten entfernen (für den Fall eines Reloads)
	for child in _level_grid.get_children():
		child.queue_free()

	var definitions: Array[LevelDefinition] = ProgressManager.get_level_definitions()
	definitions.sort_custom(func(a: LevelDefinition, b: LevelDefinition) -> bool:
		return a.level_index < b.level_index)

	for definition in definitions:
		var index: int = definition.level_index
		var stars: int = ProgressManager.get_stars(index)
		var unlocked: bool = ProgressManager.is_level_unlocked(index)

		var card: LevelCard = level_card_scene.instantiate() as LevelCard
		_level_grid.add_child(card)
		card.setup(definition, stars, unlocked)
		card.card_pressed.connect(_on_card_pressed)


func _on_card_pressed(level_index: int) -> void:
	ProgressManager.current_level_index = level_index
	get_tree().change_scene_to_file("res://scenes/game/game.tscn")
