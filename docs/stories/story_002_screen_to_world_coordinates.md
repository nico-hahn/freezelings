# Story 002 – Korrekte Screen-zu-Welt-Koordinatenumrechnung beim Objekt-Platzieren

**Status**: ✅ Erledigt  
**Priorität**: Hoch – Objekt-Platzierung ist zentrale Spielmechanik  

---

## Problem

In `scripts/game/game.gd` wird die Mausposition (Screen-Koordinaten) aktuell so in Weltkoordinaten umgerechnet:

```gdscript
# _try_place_object() und _try_remove_object() in game.gd
var world_pos: Vector2 = _camera.get_canvas_transform().affine_inverse() * screen_pos
```

Das ist falsch. `_camera.get_canvas_transform()` gibt den Canvas-Transform der **eigenen Camera2D-Node** zurück – nicht den des aktiv gerenderten Viewports. Sobald irgendeine andere Kamera aktiv ist (Godot-Editor "Override In-Game Camera", zukünftige eigene Kamera-Logik, Sub-Viewports etc.), weicht dieser Transform vom tatsächlichen Viewport-Transform ab, und das angeklickte Tile stimmt nicht mehr mit dem platzierten Objekt überein.

Der korrekte Godot-4-Ansatz ist:

```gdscript
var world_pos: Vector2 = get_viewport().get_canvas_transform().affine_inverse() * screen_pos
```

`get_viewport().get_canvas_transform()` liefert immer den tatsächlich aktiven Transform des Viewports – unabhängig davon, welche Camera2D gerade die Kontrolle hat. Das ist die Godot-4-idiomatische Lösung und funktioniert korrekt mit:
- der eigenen Camera2D (zoom, pan)
- dem Godot-Editor-Preview ("Override In-Game Camera")
- zukünftigen Kamera-Systemen

---

## Aufgabe

In `scripts/game/game.gd` die Koordinatenumrechnung an **zwei Stellen** korrigieren:

### Stelle 1: `_try_place_object()`

```gdscript
# VORHER (falsch):
var world_pos: Vector2 = _camera.get_canvas_transform().affine_inverse() * screen_pos

# NACHHER (korrekt):
var world_pos: Vector2 = get_viewport().get_canvas_transform().affine_inverse() * screen_pos
```

### Stelle 2: `_try_remove_object()`

```gdscript
# VORHER (falsch):
var world_pos: Vector2 = _camera.get_canvas_transform().affine_inverse() * screen_pos

# NACHHER (korrekt):
var world_pos: Vector2 = get_viewport().get_canvas_transform().affine_inverse() * screen_pos
```

---

## Akzeptanzkriterien

- [x] `_camera.get_canvas_transform()` kommt in `game.gd` nicht mehr vor
- [x] Beide Stellen (place und remove) verwenden `get_viewport().get_canvas_transform()`
- [x] Objekte werden im Editor-Preview ("Override In-Game Camera") korrekt auf dem angeklickten Tile platziert
- [x] Objekte werden bei laufendem Spiel (eigene Camera2D aktiv) korrekt auf dem angeklickten Tile platziert
- [x] Keine anderen Dateien werden verändert

---

## Post-Mortem: Zweiter Bug

Der erste Coding-Agent hat `get_viewport().get_canvas_transform()` korrekt umgesetzt, aber der Bug blieb bestehen weil ein zweites Problem übersehen wurde:

In `_unhandled_input` wurde `mouse_event.global_position` an `_try_place_object()` übergeben.  
`InputEventMouseButton.global_position` ist in Godot 4 die Position **im globalen Canvas-Koordinatensystem** (bereits transformiert). `get_viewport().get_canvas_transform().affine_inverse()` erwartet aber die rohe **Screen-Position** – das ist `mouse_event.position`.

**Fix** (direkt angewendet, keine weitere Story nötig):
```gdscript
# VORHER (falsch):
_try_place_object(mouse_event.global_position)
_try_remove_object(mouse_event.global_position)

# NACHHER (korrekt):
_try_place_object(mouse_event.position)
_try_remove_object(mouse_event.position)
```

