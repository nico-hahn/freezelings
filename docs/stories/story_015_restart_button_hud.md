# Story 015 – Restart-Button im HUD

**Status**: ✅ Erledigt  
**Priorität**: Normal

---

## Ziel

Links neben dem Pause-Button im HUD einen Restart-Button einfügen. Ein Klick darauf startet das aktuelle Level neu – identisch zum "Neustart"-Button im Win/Loss-Screen.

---

## Aufgabe 1: `scenes/ui/hud.tscn` – RestartButton einfügen

Den `RestartButton` als erstes Kind von `BottomBar` einfügen, **vor** `PauseButton`. Da `BottomBar` ein `HBoxContainer` mit `alignment = 1` (zentriert) ist, bestimmt die Baumreihenfolge die visuelle Reihenfolge: RestartButton links, PauseButton rechts daneben.

Stil: Gleiche Größe und StyleBoxFlat-Farbe wie der PauseButton (`#99f1f7`) damit die beiden Buttons optisch zusammengehören. Als Icon oder Text `↺` – kein separates Asset nötig.

```tscn
[node name="RestartButton" type="Button" parent="BottomBar"]
layout_mode = 2
custom_minimum_size = Vector2(96, 96)
text = "↺"
theme_override_font_sizes/font_size = 48
theme_override_styles/normal = SubResource("StyleBoxFlat_pause")
theme_override_styles/hover = SubResource("StyleBoxFlat_pause_hover")
```

> Die bestehenden `StyleBoxFlat_pause` und `StyleBoxFlat_pause_hover` SubResources aus story_014 werden wiederverwendet – keine neuen StyleBoxes nötig.

---

## Aufgabe 2: `scripts/ui/hud.gd` – Button verdrahten

`@onready`-Referenz ergänzen und in `_ready()` verbinden:

```gdscript
@onready var _restart_button: Button = $BottomBar/RestartButton

func _ready() -> void:
	# ...existing code...
	_restart_button.pressed.connect(_on_restart_button_pressed)

func _on_restart_button_pressed() -> void:
	GameManager.restart_level()
```

---

## Akzeptanzkriterien

- [ ] `RestartButton` ist in `hud.tscn` als erstes Kind von `BottomBar` eingetragen (vor `PauseButton`)
- [ ] Button ist `96×96` px, gleiche Farbe wie PauseButton (`#99f1f7`)
- [ ] Klick startet das aktuelle Level neu (`GameManager.restart_level()`)
- [ ] Der Button funktioniert sowohl während des laufenden Spiels als auch wenn pausiert
- [ ] Keine anderen bestehenden Dateien werden verändert (außer `hud.tscn` und `hud.gd`)


