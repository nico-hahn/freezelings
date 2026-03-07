# Story 007 – Level-Auswahl Szene

**Status**: 🟡 Bereit zur Implementierung  
**Priorität**: Hoch  
**Voraussetzungen**: story_004, story_005 und story_006 müssen vollständig implementiert sein.

---

## Ziel

Eine Level-Auswahl-Szene (`level_select.tscn`) als neuen Entry-Point des Spiels implementieren. Die Szene zeigt alle verfügbaren Level als Karten in einem Grid an – dynamisch aus `ProgressManager.get_level_definitions()` befüllt. Freigeschaltete Level sind klickbar, gesperrte ausgegraut. Nach der Auswahl wird `game.tscn` geladen.

---

## Aufgabe 1: `scenes/ui/level_card.tscn` erstellen

Einzelne Level-Karte im Grid.

**Node-Hierarchie:**

```
LevelCard (PanelContainer)              Script: scripts/ui/level_card.gd
└── VBoxContainer
    ├── LevelNameLabel (Label)          Level-Name (z.B. "Level 01")
    ├── StarsLabel (Label)              Sterne als Text (z.B. "⭐⭐☆")
    └── LockedOverlay (ColorRect)       Halbtransparent, nur sichtbar wenn gesperrt
```

**`scripts/ui/level_card.gd`:**

```gdscript
class_name LevelCard
extends PanelContainer

signal card_pressed(level_index: int)

@onready var _name_label: Label = $VBoxContainer/LevelNameLabel
@onready var _stars_label: Label = $VBoxContainer/StarsLabel
@onready var _locked_overlay: ColorRect = $VBoxContainer/LockedOverlay

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
```

---

## Aufgabe 2: `scenes/ui/level_select.tscn` erstellen

**Node-Hierarchie:**

```
LevelSelect (Control)                   Script: scripts/ui/level_select.gd
└── VBoxContainer
    ├── TitleLabel (Label)              "Level-Auswahl"
    └── LevelGrid (GridContainer)       columns = 3 (oder anpassen)
```

---

## Aufgabe 3: `scripts/ui/level_select.gd`

```gdscript
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
	# Nach level_index sortieren
	definitions.sort_custom(func(a, b): return a.level_index < b.level_index)

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
```

---

## Aufgabe 4: `game.gd` – Level hardcoding entfernen

`game.gd` lädt das Level aktuell hardcoded:
```gdscript
# ALT (entfernen):
GameManager.load_level("res://scenes/levels/level_01.tscn")
```

Ersetzen durch:
```gdscript
# NEU:
var level_def: LevelDefinition = ProgressManager.get_current_level_definition()
if level_def == null:
	push_error("Game: Keine LevelDefinition im ProgressManager gefunden.")
	return
GameManager.load_level(level_def.scene_path)
```

---

## Aufgabe 5: `project.godot` – Main Scene ändern

```ini
[application]
run/main_scene="res://scenes/ui/level_select.tscn"
```

> Bisher war `run/main_scene="res://scenes/game/game.tscn"`. Das wird geändert.

---

## Aufgabe 6: Win/Loss-Screen Navigation verifizieren

In `win_loss_screen.gd` navigiert der "Zur Level-Auswahl"-Button bereits zu `level_select.tscn` (aus story_006). Sicherstellen dass der Pfad korrekt ist:

```gdscript
func _on_level_select_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/ui/level_select.tscn")
```

---

## Akzeptanzkriterien

- [ ] `scenes/ui/level_card.tscn` existiert mit der beschriebenen Struktur
- [ ] `scripts/ui/level_card.gd` existiert mit `class_name LevelCard`
- [ ] `scenes/ui/level_select.tscn` existiert mit der beschriebenen Struktur
- [ ] `scripts/ui/level_select.gd` existiert mit `class_name LevelSelect`
- [ ] Das Spiel startet mit der Level-Auswahl (nicht direkt mit `game.tscn`)
- [ ] Level-Karten werden dynamisch aus `ProgressManager.get_level_definitions()` befüllt
- [ ] Level 0 ("Level 01") ist von Anfang an freigeschaltet und klickbar
- [ ] Alle anderen Level sind gesperrt (ausgegraut, nicht klickbar) bis das Vorgänger-Level mit ≥1 Stern abgeschlossen wurde
- [ ] Klick auf freigeschaltetes Level → Spiel startet das korrekte Level
- [ ] Nach Level-Abschluss → "Zur Level-Auswahl" → Level-Karte zeigt die erreichten Sterne
- [ ] `level_card_scene` muss im Editor in der `LevelSelect`-Node gesetzt werden

