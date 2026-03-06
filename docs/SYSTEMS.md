# System-Spezifikationen

Dieses Dokument beschreibt jedes System technisch im Detail.
Für Godot-Best-Practices: Godot 4.5, GDScript, TileMapLayer, Signals-first.

---

## 1. TickManager (Autoload)

**Datei**: `scripts/global/tick_manager.gd`  
**Registriert als**: `TickManager`

### Verantwortlichkeit
- Verwaltet den Spiel-Takt (Timer-basiert)
- Sendet `tick_happened` Signal an alle Listener
- Steuert Pause/Resume

### Zustand
```gdscript
var tick_duration: float = Constants.DEFAULT_TICK_DURATION
var is_paused: bool = false
var tick_count: int = 0        # Gesamtanzahl der bisher vergangenen Ticks
```

### Signale
```gdscript
signal tick_happened(tick_number: int)
signal paused
signal resumed
```

### Methoden
```gdscript
func pause() -> void
func resume() -> void
func toggle_pause() -> void
func set_tick_duration(seconds: float) -> void
func reset() -> void           # Setzt tick_count zurück, stoppt Timer
func start() -> void           # Startet den Timer (wird von LevelController aufgerufen)
```

### Implementierungshinweise
- Intern: ein `Timer`-Node als Kind
- `Timer.wait_time = tick_duration`
- `Timer.timeout` → `tick_count += 1; emit_signal("tick_happened", tick_count)`
- Pause: `get_tree().paused = false` (wir pausieren NICHT den SceneTree, nur den Timer!)
  - Der SceneTree bleibt laufend, damit UI-Interaktion möglich bleibt
  - Nur `timer.paused = true/false`

---

## 2. GameManager (Autoload)

**Datei**: `scripts/global/game_manager.gd`  
**Registriert als**: `GameManager`

### Verantwortlichkeit
- Globaler Spielzustand (welches Level, Spielphase)
- Zählt gerettete/tote Lemminge
- Erkennt Win/Loss
- Level-Wechsel-Logik

### Zustand
```gdscript
var current_level_scene: Node = null
var game_state: Enums.GameState = Enums.GameState.MENU

# Lemming-Zähler (werden vom aktiven LevelController gesetzt)
var total_lemmings: int = 0
var required_saved: int = 0
var saved_count: int = 0
var dead_count: int = 0
var spawned_count: int = 0
```

### Signale
```gdscript
signal game_state_changed(new_state: Enums.GameState)
signal lemming_counts_changed(saved: int, dead: int, spawned: int, total: int)
signal level_completed(success: bool)
```

### Methoden
```gdscript
func load_level(level_path: String) -> void
func restart_level() -> void
func on_lemming_saved() -> void     # Wird von LevelController aufgerufen
func on_lemming_died() -> void      # Wird von LevelController aufgerufen
func on_lemming_spawned() -> void   # Wird von LevelController aufgerufen
func _check_win_loss() -> void      # Privat: prüft ob Win/Loss-Bedingung erfüllt
func initialize_level(total: int, required: int) -> void
```

---

## 3. LevelController (Script auf Level-Root-Node)

**Datei**: `scripts/level/level_controller.gd`

### Verantwortlichkeit
- Orchestriert das laufende Level
- Kennt TileMapLayer, EntryPoint, ExitPoint, Spawner, Container
- Verwaltet platzierte Objekte (Dictionary)
- Leitet Lemming-Events an GameManager weiter

### Exportierte Variablen (im Editor einstellbar)
```gdscript
@export var total_lemmings: int = 10
@export var required_saved: int = 7
@export var spawn_interval: int = 3         # Alle N Ticks ein neuer Lemming
@export var start_direction: Enums.Direction = Enums.Direction.EAST
@export var starting_inventory: Dictionary = {}
# Beispiel: {"direction_arrow_north": 3, "blocker": 1}
```

### Interner Zustand
```gdscript
var placed_objects: Dictionary = {}    # Vector2i -> PlaceableObject-Node
var _walls_layer: TileMapLayer         # Referenz auf TileMapLayer "Walls"
var _entry_point: Marker2D
var _exit_point: Marker2D
var _lemming_spawner: LemmingSpawner
var _lemmings_container: Node2D
var _placed_objects_container: Node2D
```

### Methoden
```gdscript
func _ready() -> void                  # Findet alle Kind-Nodes, initialisiert GameManager
func is_tile_walkable(grid_pos: Vector2i) -> bool
func is_tile_exit(grid_pos: Vector2i) -> bool
func has_placed_object(grid_pos: Vector2i) -> bool
func get_placed_object(grid_pos: Vector2i) -> PlaceableObject
func place_object(grid_pos: Vector2i, object_scene: PackedScene) -> bool
func remove_object(grid_pos: Vector2i) -> void
func world_to_grid(world_pos: Vector2) -> Vector2i
func grid_to_world(grid_pos: Vector2i) -> Vector2
```

### TileMap-Konvention
- **Leere Zelle** = begehbar (floor)
- **Beliebige Tile-Zelle** in der "Walls"-Layer = Wand (nicht begehbar)
- Prüfung: `walls_layer.get_cell_source_id(grid_pos) == -1` → begehbar

---

## 4. LemmingSpawner

**Datei**: `scripts/entities/lemming_spawner.gd`  
**Szene**: `scenes/entities/lemming_spawner.tscn`

### Verantwortlichkeit
- Hört auf `TickManager.tick_happened`
- Spawnt alle N Ticks einen neuen Lemming (bis `total_lemmings` erreicht)
- Positioniert neue Lemminge an EntryPoint

### Zustand
```gdscript
var spawn_interval: int = 3
var total_lemmings: int = 10
var start_direction: Enums.Direction = Enums.Direction.EAST
var spawned_count: int = 0

@export var lemming_scene: PackedScene   # Referenz auf lemming.tscn
```

### Methoden
```gdscript
func initialize(entry_pos: Vector2i, interval: int, total: int, direction: Enums.Direction) -> void
func _on_tick_happened(tick_number: int) -> void    # Verbunden mit TickManager
func _spawn_lemming() -> void
```

---

## 5. Lemming

**Datei**: `scripts/entities/lemming.gd`  
**Szene**: `scenes/entities/lemming.tscn`

### Node-Struktur
```
Lemming (Node2D)
└── Sprite2D
```

### Zustand
```gdscript
var grid_pos: Vector2i
var direction: Enums.Direction
var state: Enums.LemmingState = Enums.LemmingState.ALIVE
var _level_controller: LevelController   # Referenz, gesetzt beim Spawnen
```

### Signale
```gdscript
signal reached_exit(lemming: Lemming)
signal died(lemming: Lemming)
```

### Methoden
```gdscript
func initialize(start_pos: Vector2i, start_dir: Enums.Direction, level: LevelController) -> void
func _on_tick_happened(tick_number: int) -> void    # Verbunden mit TickManager
func _process_movement() -> void
func _apply_direction(new_dir: Enums.Direction) -> void
func _animate_to(target_world_pos: Vector2) -> void  # Tween-Animation
```

### Bewegungslogik pro Tick
```
1. Falls state != ALIVE: return
2. Zielposition = grid_pos + Direction.to_vector(direction)
3. Wenn _level_controller.is_tile_walkable(zielposition):
     a. grid_pos = zielposition
     b. _animate_to(grid_to_world(grid_pos))
     c. Wenn is_tile_exit(grid_pos): emit reached_exit; state = EXITING; return
     d. Wenn has_placed_object(grid_pos):
          object = get_placed_object(grid_pos)
          object.apply_to_lemming(self)
4. Wenn NICHT walkable:
     direction = Direction.opposite(direction)
```

---

## 6. PlaceableObject (Basisklasse)

**Datei**: `scripts/objects/placeable_object.gd`

### Klasse
```gdscript
class_name PlaceableObject
extends Node2D
```

### Zustand
```gdscript
var grid_pos: Vector2i
```

### Methoden (abstrakt / zu überschreiben)
```gdscript
func apply_to_lemming(lemming: Lemming) -> void   # Effekt auf den Lemming
func get_object_type() -> String                   # ID für Inventar-Matching
```

---

## 7. DirectionArrow (PlaceableObject)

**Datei**: `scripts/objects/direction_arrow.gd`  
**Szene**: `scenes/objects/direction_arrow.tscn`

```gdscript
@export var target_direction: Enums.Direction = Enums.Direction.NORTH

func apply_to_lemming(lemming: Lemming) -> void:
    lemming.direction = target_direction

func get_object_type() -> String:
    return "direction_arrow_" + Enums.Direction.keys()[target_direction].to_lower()
```

---

## 8. Blocker (PlaceableObject)

**Datei**: `scripts/objects/blocker.gd`  
**Szene**: `scenes/objects/blocker.tscn`

Der Blocker wirkt wie eine Wand. Die Kollisionsprüfung im Lemming muss den Blocker berücksichtigen:

```gdscript
# In LevelController:
func is_tile_walkable(grid_pos: Vector2i) -> bool:
    if _walls_layer.get_cell_source_id(grid_pos) != -1:
        return false
    if has_placed_object(grid_pos):
        var obj = get_placed_object(grid_pos)
        if obj is Blocker:
            return false
    return true
```

Der Blocker hat keine `apply_to_lemming`-Methode – er wird bereits in `is_tile_walkable` berücksichtigt.

---

## 9. HUD

**Datei**: `scripts/ui/hud.gd`  
**Szene**: `scenes/ui/hud.tscn`

### Verantwortlichkeit
- Anzeige: "Gerettet: X / Y (benötigt: Z)"
- Inventar: Buttons für platzierbare Objekte mit Anzahl
- Pause-Button
- Pause-Overlay (visuell)
- Ausgewähltes Objekt hervorheben

### Signale empfangen
- `GameManager.lemming_counts_changed` → Label aktualisieren
- `GameManager.game_state_changed` → Overlay zeigen/verstecken
- `TickManager.paused` / `TickManager.resumed` → PauseOverlay

### Signale senden
```gdscript
signal object_selected(object_type: String)   # Spieler wählt Objekt im Inventar
```

### Objekt-Platzierung im Spiel
- Mausklick auf Spielwelt (in `game.gd` oder einem `InputHandler`-Node verarbeiten)
- `game.gd` hört auf `hud.object_selected`, merkt sich das ausgewählte Objekt
- Bei Linksklick auf Spielwelt: Umrechnung Weltkoordinaten → Grid → `level_controller.place_object()`

---

## 10. ObjectDefinition (Resource)

**Datei**: `scripts/resources/object_definition.gd`  
*(Nur als optionale Datenschicht, falls benötigt)*

```gdscript
class_name ObjectDefinition
extends Resource

@export var object_id: String
@export var display_name: String
@export var scene: PackedScene
@export var icon: Texture2D
```

Diese Resource-Dateien (`.tres`) werden in `resources/object_definitions/` abgelegt.
Sie ermöglichen das einfache Hinzufügen neuer Objekt-Typen ohne Code-Änderungen.

---

## 11. Enums (Autoload)

**Datei**: `scripts/global/enums.gd`

```gdscript
enum Direction {
    NORTH,
    EAST,
    SOUTH,
    WEST
}

enum GameState {
    MENU,
    PLAYING,
    PAUSED,
    LEVEL_COMPLETE,
    LEVEL_FAILED
}

enum LemmingState {
    ALIVE,
    EXITING,
    SAVED,
    DEAD
}
```

### Hilfsfunktionen in enums.gd
```gdscript
static func direction_to_vector(dir: Direction) -> Vector2i:
    match dir:
        Direction.NORTH: return Vector2i(0, -1)
        Direction.EAST:  return Vector2i(1, 0)
        Direction.SOUTH: return Vector2i(0, 1)
        Direction.WEST:  return Vector2i(-1, 0)
    return Vector2i.ZERO

static func opposite_direction(dir: Direction) -> Direction:
    match dir:
        Direction.NORTH: return Direction.SOUTH
        Direction.EAST:  return Direction.WEST
        Direction.SOUTH: return Direction.NORTH
        Direction.WEST:  return Direction.EAST
    return dir
```

---

## 12. Constants (Autoload)

**Datei**: `scripts/global/constants.gd`

```gdscript
const TILE_SIZE: int = 32              # Pixel pro Tile (an TileSet anpassen!)
const DEFAULT_TICK_DURATION: float = 0.5
const MIN_TICK_DURATION: float = 0.1
const MAX_TICK_DURATION: float = 2.0
```

