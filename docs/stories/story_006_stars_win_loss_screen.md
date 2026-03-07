# Story 006 – Stern-Bewertung & Win/Loss-Bildschirm

**Status**: 🟡 Bereit zur Implementierung  
**Priorität**: Hoch  
**Voraussetzungen**: story_004 und story_005 müssen vollständig implementiert sein.

---

## Ziel

1. Eine Sterne-Bewertung (0–3) pro Level einführen, deren Schwellwerte der Designer im Editor festlegt.
2. Einen Win/Loss-Bildschirm implementieren, der Ergebnis + Sterne anzeigt und zum Neustart oder zur Level-Auswahl navigiert.
3. Das Ergebnis in `ProgressManager` speichern.

---

## Aufgabe 1: Stern-Schwellwerte in `LevelController`

`scripts/level/level_controller.gd` bekommt drei neue `@export`-Variablen:

```gdscript
## Mindestanzahl geretteter Lemminge für 1 Stern.
@export var stars_threshold_1: int = 1
## Mindestanzahl geretteter Lemminge für 2 Sterne.
@export var stars_threshold_2: int = 5
## Mindestanzahl geretteter Lemminge für 3 Sterne.
@export var stars_threshold_3: int = 8
```

> Der Designer setzt diese Werte pro Level im Inspector. Standardwerte sind Platzhalter.

Außerdem eine Hilfsmethode ergänzen:

```gdscript
## Berechnet die erreichte Stern-Zahl basierend auf saved_count.
func calculate_stars(saved_count: int) -> int:
	if saved_count >= stars_threshold_3:
		return 3
	elif saved_count >= stars_threshold_2:
		return 2
	elif saved_count >= stars_threshold_1:
		return 1
	return 0
```

---

## Aufgabe 2: `GameManager` – Sterne berechnen und speichern

In `game_manager.gd` die `_check_win_loss()`-Methode anpassen:

```gdscript
func _check_win_loss() -> void:
	var finished: int = saved_count + dead_count
	if spawned_count == total_lemmings and finished == total_lemmings:
		var success: bool = saved_count >= required_saved
		TickManager.reset()
		# Sterne berechnen (LevelController holt sich das aktuelle Level)
		var stars: int = 0
		if success:
			var level_controller: LevelController = _get_active_level_controller()
			if level_controller != null:
				stars = level_controller.calculate_stars(saved_count)
		# Fortschritt speichern
		var level_def: LevelDefinition = ProgressManager.get_current_level_definition()
		if level_def != null:
			ProgressManager.record_level_result(level_def.level_index, stars)
		if success:
			_set_state(Enums.GameState.LEVEL_COMPLETE)
		else:
			_set_state(Enums.GameState.LEVEL_FAILED)
		level_completed.emit(success, stars)
```

`level_completed`-Signal bekommt einen zusätzlichen Parameter `stars: int`:

```gdscript
signal level_completed(success: bool, stars: int)
```

Hilfsmethode `_get_active_level_controller()` in `game_manager.gd`:

```gdscript
func _get_active_level_controller() -> LevelController:
	if _level_root == null:
		return null
	for child in _level_root.get_children():
		if child is LevelController:
			return child as LevelController
	return null
```

---

## Aufgabe 3: `scenes/ui/win_loss_screen.tscn` erstellen

**Node-Hierarchie:**

```
WinLossScreen (CanvasLayer)               Script: scripts/ui/win_loss_screen.gd
└── Panel (Panel)                         Zentriert im Viewport
    └── VBoxContainer
        ├── TitleLabel (Label)            "Level geschafft!" / "Gescheitert"
        ├── StarsContainer (HBoxContainer) Drei Stern-Icons (Label oder TextureRect)
        ├── ResultLabel (Label)           "Gerettet: X / Y"
        ├── RestartButton (Button)        "Neustart"
        └── LevelSelectButton (Button)   "Zur Level-Auswahl"
```

> Sterne können als Label mit Emojis (⭐ / ☆) oder als TextureRect mit Texturen dargestellt werden. Für v1 reichen Label-Emojis.

---

## Aufgabe 4: `scripts/ui/win_loss_screen.gd`

```gdscript
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
	# Alle Kinder entfernen und neu aufbauen
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
	get_tree().change_scene_to_file("res://scenes/ui/level_select.tscn")
```

---

## Aufgabe 5: Win/Loss-Screen in `game.tscn` einbinden

`WinLossScreen` als Kind von `Game` in `game.tscn` hinzufügen:

```
Game (Node2D)
├── LevelRoot (Node2D)
├── HUD (CanvasLayer)
└── WinLossScreen (CanvasLayer)    ← NEU; instance von win_loss_screen.tscn
```

---

## Aufgabe 6: `game.gd` anpassen

`@onready`-Referenz auf WinLossScreen ergänzen und `_on_level_completed()` updaten:

```gdscript
@onready var _win_loss_screen: WinLossScreen = $WinLossScreen

func _on_level_completed(success: bool, stars: int) -> void:
	_win_loss_screen.show_result(
		success,
		stars,
		GameManager.saved_count,
		GameManager.total_lemmings
	)
```

> Das Signal `GameManager.level_completed` hat jetzt zwei Parameter (`success`, `stars`) – die Verbindung in `_ready()` muss entsprechend angepasst werden:
> ```gdscript
> GameManager.level_completed.connect(_on_level_completed)
> ```
> GDScript bindet Parameter automatisch wenn die Signatur übereinstimmt.

---

## Aufgabe 7: Level-Restart sicherstellen (`GameManager.restart_level()`)

Der bestehende Stub in `game_manager.gd` muss vollständig implementiert sein:

```gdscript
func restart_level() -> void:
	if _current_level_path.is_empty():
		push_error("GameManager: Kein aktuelles Level zum Neustarten.")
		return
	TickManager.reset()
	load_level(_current_level_path)
```

> `_current_level_path` wird in `load_level()` gesetzt. Sicherstellen dass das korrekt passiert.

---

## Akzeptanzkriterien

- [ ] `LevelController` hat `stars_threshold_1/2/3` als `@export` und `calculate_stars()`
- [ ] `GameManager.level_completed` sendet `(success: bool, stars: int)`
- [ ] Ergebnis wird via `ProgressManager.record_level_result()` gespeichert
- [ ] `scenes/ui/win_loss_screen.tscn` existiert mit der beschriebenen Struktur
- [ ] Bei Level-Erfolg: korrekte Sterne-Zahl (0–3) wird angezeigt
- [ ] Bei Level-Scheitern: 0 Sterne werden angezeigt, Titel "Gescheitert"
- [ ] "Neustart"-Button startet das aktuelle Level neu (Win/Loss-Screen verschwindet)
- [ ] "Zur Level-Auswahl"-Button wechselt zu `level_select.tscn`
- [ ] `level_select.tscn` muss noch nicht existieren – der Button darf vorerst einen Fehler loggen wenn die Szene fehlt

