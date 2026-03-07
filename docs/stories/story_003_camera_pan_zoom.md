# Story 003 – Kamera: Panning & Zoom

**Status**: ✅ Erledigt  
**Priorität**: Mittel

---

## Ziel

Eine spielbare Kamera implementieren, die Panning (Linksklick-Drag) und Zoom (Mausrad) unterstützt. Die Kamera gehört zum Level, nicht zur Game-Szene.

---

## Kontext & Abhängigkeiten

### Aktueller Zustand
- `scenes/game/game.tscn` enthält aktuell eine `Camera2D` als Kind von `Game (Node2D)`
- `game.gd` referenziert diese Kamera via `@onready var _camera: Camera2D = $Camera2D`
- `game.gd` nutzt die Kamera in `_center_camera_on_level()` um sie auf das Level zu zentrieren
- Objekt-Platzierung läuft über `get_viewport().get_canvas_transform().affine_inverse() * mouse_event.position` – das muss weiterhin korrekt funktionieren

### Gewünschter Zustand
- Die `Camera2D` sitzt in `level_base.tscn` (und wird damit in jedes Level geerbt)
- Ein eigenes Script `scripts/level/level_camera.gd` steuert Panning und Zoom
- `game.gd` erhält eine Referenz auf die Kamera des geladenen Levels
- Die Koordinatenumrechnung für Objekt-Platzierung bleibt unverändert (`get_viewport().get_canvas_transform()`)

---

## Aufgabe 1: `scripts/level/level_camera.gd` erstellen

Neues Script für die Camera2D im Level. Steuert Panning und Zoom.

### Panning-Logik
- Panning ist **nur aktiv wenn kein Objekt im Inventar ausgewählt ist**
- Dafür braucht die Kamera Zugriff auf den Zustand "ist gerade ein Objekt ausgewählt?"
- Lösung: Ein exportiertes oder per Methode setzbares Flag `var is_placing_object: bool = false`
- `game.gd` setzt dieses Flag wenn der Spieler ein Objekt auswählt oder die Auswahl aufhebt

**Panning-Mechanik:**
- `InputEventMouseButton` MOUSE_BUTTON_LEFT pressed + `is_placing_object == false` → Panning starten (`_is_panning = true`, Startposition merken)
- `InputEventMouseButton` MOUSE_BUTTON_LEFT released → Panning stoppen (`_is_panning = false`)
- `InputEventMouseMotion` + `_is_panning == true` → Kamera um `relative`-Vektor verschieben (Achtung: durch aktuellen Zoom dividieren, da `relative` in Screen-Pixeln ist)

**Panning-Formel:**
```gdscript
# In _input(event) oder _unhandled_input(event):
if event is InputEventMouseMotion and _is_panning:
    position -= event.relative / zoom
```

> `zoom` ist ein `Vector2` in Godot 4 – bei gleichmäßigem Zoom `zoom.x` verwenden.

### Zoom-Logik
- `InputEventMouseButton` MOUSE_BUTTON_WHEEL_UP → rein zoomen
- `InputEventMouseButton` MOUSE_BUTTON_WHEEL_DOWN → raus zoomen
- Zoom erfolgt zur **Mausposition** hin (nicht zum Bildschirmmittelpunkt)
- Zoom-Schritt: konfigurierbarer Faktor, Vorschlag `0.1`
- Zoom-Grenzen: Vorschlag `min_zoom = Vector2(0.25, 0.25)`, `max_zoom = Vector2(4.0, 4.0)` – als `@export` damit sie später einfach angepasst werden können

**Zoom-zur-Maus-Formel:**
```gdscript
func _zoom_towards_mouse(zoom_factor: float, mouse_pos: Vector2) -> void:
    var old_zoom: Vector2 = zoom
    var new_zoom: Vector2 = clamp(zoom * zoom_factor, min_zoom, max_zoom)
    # Kameraposition so anpassen, dass der Punkt unter der Maus gleich bleibt
    var zoom_center: Vector2 = get_global_mouse_position()
    position = zoom_center + (position - zoom_center) * (old_zoom.x / new_zoom.x)
    zoom = new_zoom
```

### Vollständige Script-Struktur

```gdscript
class_name LevelCamera
extends Camera2D

@export var zoom_step: float = 0.1
@export var min_zoom: Vector2 = Vector2(0.25, 0.25)
@export var max_zoom: Vector2 = Vector2(4.0, 4.0)

## Wird von game.gd gesetzt: true wenn Spieler gerade ein Objekt zum Platzieren ausgewählt hat
var is_placing_object: bool = false

var _is_panning: bool = false


func _unhandled_input(event: InputEvent) -> void:
    # Panning starten/stoppen
    if event is InputEventMouseButton:
        if event.button_index == MOUSE_BUTTON_LEFT:
            if event.pressed and not is_placing_object:
                _is_panning = true
            else:
                _is_panning = false

        # Zoom
        elif event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:
            _zoom_towards_mouse(1.0 + zoom_step, event.position)
        elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
            _zoom_towards_mouse(1.0 - zoom_step, event.position)

    # Panning ausführen
    elif event is InputEventMouseMotion and _is_panning:
        position -= event.relative / zoom.x


func _zoom_towards_mouse(zoom_factor: float, mouse_screen_pos: Vector2) -> void:
    var old_zoom: float = zoom.x
    var new_zoom_val: float = clampf(zoom.x * zoom_factor, min_zoom.x, max_zoom.x)
    var new_zoom: Vector2 = Vector2(new_zoom_val, new_zoom_val)
    var zoom_center: Vector2 = get_global_mouse_position()
    position = zoom_center + (position - zoom_center) * (old_zoom / new_zoom_val)
    zoom = new_zoom
```

---

## Aufgabe 2: `level_base.tscn` – Camera2D hinzufügen

Die Camera2D aus `game.tscn` wird entfernt und stattdessen in `level_base.tscn` eingefügt.

**Node in `level_base.tscn` hinzufügen:**
```
LevelBase (Node2D)
├── Camera2D                ← NEU; Script: scripts/level/level_camera.gd; enabled = true
├── Ground (TileMapLayer)
├── Walls (TileMapLayer)
...
```

**Wichtig:** Die Camera2D muss `enabled = true` haben damit sie die aktive Kamera im Viewport ist.

---

## Aufgabe 3: `game.tscn` – Camera2D entfernen

Die bestehende `Camera2D` in `game.tscn` entfernen. `game.gd` holt sich die Kamera stattdessen vom geladenen Level.

---

## Aufgabe 4: `game.gd` anpassen

### `_camera`-Referenz
Die `@onready`-Referenz `$Camera2D` entfernen. Stattdessen nach dem Level-Laden die Kamera aus dem Level holen:

```gdscript
# Altes Feld entfernen:
# @onready var _camera: Camera2D = $Camera2D

# Neues Feld:
var _camera: LevelCamera = null
```

In `_on_level_loaded()`, nach dem Finden des LevelControllers:
```gdscript
_camera = _level_controller.get_node("Camera2D") as LevelCamera
```

### `_center_camera_on_level()`
Bleibt inhaltlich gleich, nutzt jetzt `_camera` aus dem Level:
```gdscript
func _center_camera_on_level() -> void:
    if _level_controller == null or _camera == null:
        return
    var walls_layer: TileMapLayer = _level_controller.get_node("Walls") as TileMapLayer
    if walls_layer == null:
        return
    var used_rect: Rect2i = walls_layer.get_used_rect()
    var center_grid: Vector2i = used_rect.position + used_rect.size / 2
    _camera.position = _level_controller.grid_to_world(center_grid)
```

> **Hinweis:** `_camera.position` statt `_camera.global_position` – da die Kamera jetzt Kind des Level-Nodes ist, ist ihr lokaler Transform relevant.

### `_on_object_selected()` – Kamera informieren
```gdscript
func _on_object_selected(object_type: String) -> void:
    _selected_object_type = object_type
    if _camera != null:
        _camera.is_placing_object = not object_type.is_empty()
```

### Panning vs. Platzieren in `_unhandled_input()`
Da die Kamera Panning über `_unhandled_input` steuert und `game.gd` Objekt-Platzierung ebenfalls über `_unhandled_input`, gilt die Godot-Event-Verarbeitungsreihenfolge:
- Nodes weiter unten im Szenenbaum bekommen `_unhandled_input` zuerst
- Die Kamera liegt im Level, das unter `LevelRoot` unter `Game` liegt → die Kamera bekommt das Event **nach** `game.gd`

Das bedeutet: **`game.gd` konsumiert den Klick für Objekt-Platzierung zuerst** (via `get_viewport().set_input_as_handled()`), und die Kamera bekommt ihn gar nicht. Das ist das gewünschte Verhalten.

**`game.gd` muss das Event als behandelt markieren wenn ein Objekt platziert wird:**
```gdscript
func _unhandled_input(event: InputEvent) -> void:
    if event is InputEventMouseButton:
        var mouse_event := event as InputEventMouseButton
        if mouse_event.button_index == MOUSE_BUTTON_LEFT and mouse_event.pressed:
            if not _selected_object_type.is_empty():
                _try_place_object(mouse_event.position)
                get_viewport().set_input_as_handled()   # ← Kamera bekommt diesen Klick nicht
        elif mouse_event.button_index == MOUSE_BUTTON_RIGHT and mouse_event.pressed:
            _try_remove_object(mouse_event.position)
```

---

## Akzeptanzkriterien

- [ ] `scripts/level/level_camera.gd` existiert mit `class_name LevelCamera`
- [ ] `level_base.tscn` hat eine `Camera2D`-Node mit `level_camera.gd` als Script
- [ ] `game.tscn` hat keine `Camera2D` mehr
- [ ] `game.gd` holt `_camera` nach dem Level-Laden aus `_level_controller.get_node("Camera2D")`
- [ ] Linksklick-Drag paniert die Kamera, **wenn kein Objekt ausgewählt ist**
- [ ] Linksklick platziert ein Objekt und startet **kein** Panning, **wenn ein Objekt ausgewählt ist**
- [ ] Mausrad zoomt zur Mausposition hin
- [ ] Zoom ist auf `min_zoom` / `max_zoom` begrenzt
- [ ] Objekt-Platzierung nach Kamera-Bewegung/Zoom trifft weiterhin das korrekte Tile
- [ ] `_center_camera_on_level()` zentriert die Kamera korrekt auf das Level beim Laden

