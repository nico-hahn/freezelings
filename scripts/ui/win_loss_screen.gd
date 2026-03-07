## WinLossScreen
# Zeigt das Level-Ergebnis (Erfolg/Niederlage, Sterne, Statistik) an.
# Wird von game.gd über show_result() aufgerufen.

class_name WinLossScreen
extends CanvasLayer

@onready var _title_label: Label = $Panel/VBoxContainer/TitleLabel
@onready var _stars_container: HBoxContainer = $Panel/VBoxContainer/StarsContainer
@onready var _result_label: Label = $Panel/VBoxContainer/ResultLabel
@onready var _restart_button: Button = $Panel/VBoxContainer/RestartButton
@onready var _level_select_button: Button = $Panel/VBoxContainer/LevelSelectButton


func _ready() -> void:
	_restart_button.pressed.connect(_on_restart_pressed)
	_level_select_button.pressed.connect(_on_level_select_pressed)
	visible = false


## Zeigt den Bildschirm mit dem Ergebnis an.
func show_result(success: bool, stars: int, saved: int, total: int) -> void:
	_title_label.text = "Level geschafft! 🎉" if success else "Gescheitert 💀"
	_result_label.text = "Gerettet: %d / %d" % [saved, total]
	_update_stars(stars)
	visible = true


func _update_stars(stars: int) -> void:
	for child in _stars_container.get_children():
		child.queue_free()
	for i in range(3):
		var star_label := Label.new()
		star_label.text = "⭐" if i < stars else "☆"
		star_label.add_theme_font_size_override("font_size", 32)
		_stars_container.add_child(star_label)


func _on_restart_pressed() -> void:
	visible = false
	GameManager.restart_level()


func _on_level_select_pressed() -> void:
	if not ResourceLoader.exists("res://scenes/ui/level_select.tscn"):
		push_error("WinLossScreen: level_select.tscn existiert noch nicht.")
		return
	get_tree().change_scene_to_file("res://scenes/ui/level_select.tscn")

