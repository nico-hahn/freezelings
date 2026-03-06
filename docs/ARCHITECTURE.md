# Freezing Dungeon – Architecture Overview

## Spielkonzept (Zusammenfassung)

Top-down Lemmings-Klon. Lemminge betreten einen Dungeon an einem Eingang, laufen immer geradeaus und müssen den Ausgang finden. Der Spieler platziert Objekte (z.B. Richtungspfeile), um die Lemminge zu lenken. Pro Level gibt es ein begrenztes Kontingent an platzierbaren Objekten. Das Spiel läuft tick-basiert (z.B. 500 ms pro Tick); der Spieler kann jederzeit pausieren.

---

## Godot-Version

**Godot 4.5** – es werden ausschließlich Godot 4.x APIs verwendet:
- `TileMapLayer` (kein `TileMap` mehr, deprecated seit 4.3)
- `Marker2D` für Spawn-/Exit-Punkte
- `Tween` für Animationen
- `@export` für konfigurierbare Level-Parameter
- `Resource` für Datendefinitionen
- Autoloads (Singletons) für globale Systeme

---

## Ordnerstruktur

```
freezing-dungeon/
├── project.godot
├── docs/                        # Planungsdokumentation (dieser Ordner)
├── assets/                      # Vom Designer bereitgestellt
│   ├── textures/
│   └── audio/
├── scripts/
│   ├── global/                  # Autoloads & globale Konstanten
│   │   ├── enums.gd             # Alle Enums des Projekts (Autoload: "Enums")
│   │   ├── constants.gd         # Globale Konstanten (Autoload: "Constants")
│   │   ├── tick_manager.gd      # Tick-System (Autoload: "TickManager")
│   │   └── game_manager.gd      # Globaler Spielzustand (Autoload: "GameManager")
│   ├── level/
│   │   └── level_controller.gd  # Script für die Level-Root-Node
│   ├── entities/
│   │   ├── lemming.gd           # Lemming-Logik
│   │   └── lemming_spawner.gd   # Spawner-Logik
│   ├── objects/                 # Platzierbare Objekte
│   │   ├── placeable_object.gd  # Basisklasse
│   │   ├── direction_arrow.gd   # Richtungspfeil
│   │   └── blocker.gd           # Blocker
│   └── ui/
│       ├── hud.gd               # HUD-Logik
│       └── inventory_slot.gd    # Inventar-Slot
├── scenes/
│   ├── main/
│   │   └── main.tscn            # Einstiegsszene
│   ├── game/
│   │   └── game.tscn            # Spielszene (lädt Level)
│   ├── levels/                  # Eine .tscn pro Level (vom Designer erstellt)
│   │   └── level_01.tscn
│   ├── entities/
│   │   ├── lemming.tscn         # Lemming-Szene
│   │   └── lemming_spawner.tscn
│   ├── objects/                 # Szenen für platzierbare Objekte
│   │   ├── direction_arrow.tscn
│   │   └── blocker.tscn
│   └── ui/
│       └── hud.tscn
└── resources/
    └── object_definitions/      # ObjectDefinition-Ressourcen (.tres)
        ├── direction_arrow_north.tres
        ├── direction_arrow_east.tres
        ├── direction_arrow_south.tres
        ├── direction_arrow_west.tres
        └── blocker.tres
```

---

## Autoloads (Singletons)

In `project.godot` müssen folgende Autoloads registriert werden:

| Name           | Skript                          | Zweck                                      |
|----------------|---------------------------------|--------------------------------------------|
| `Enums`        | `scripts/global/enums.gd`       | Globale Enums (Richtungen, Spielzustände)  |
| `Constants`    | `scripts/global/constants.gd`   | Globale Konstanten (TILE_SIZE etc.)        |
| `TickManager`  | `scripts/global/tick_manager.gd`| Tick-Takt, Pause-Steuerung                 |
| `GameManager`  | `scripts/global/game_manager.gd`| Spielzustand, Level-Wechsel, Score         |

---

## Szenen-Hierarchie

### `main.tscn` (Einstieg)
```
Main (Node)
└── [Lädt game.tscn über GameManager]
```

### `game.tscn`
```
Game (Node2D)
├── Camera2D
├── LevelRoot (Node2D)           # Hier wird die Level-.tscn instanziert
└── HUD (CanvasLayer)            # hud.tscn
```

### Jede Level-Szene (z.B. `level_01.tscn`)
```
Level (Node2D)                   # Script: level_controller.gd
│   @export spawn_interval: int = 3
│   @export total_lemmings: int = 10
│   @export required_saved: int = 7
│   @export starting_inventory: Dictionary = {"direction_arrow": 3, "blocker": 1}
│   @export start_direction: Enums.Direction = Direction.EAST
│
├── TileMapLayer "Walls"         # Dungeon-Layout; leere Zellen = begehbar
├── Markers (Node2D)
│   ├── EntryPoint (Marker2D)    # Position des Eingangs (in TileMap-Koordinaten)
│   └── ExitPoint (Marker2D)     # Position des Ausgangs
├── LemmingSpawner               # scenes/entities/lemming_spawner.tscn
├── LemmingsContainer (Node2D)   # Lemminge werden hier gespawnt
└── PlacedObjectsContainer (Node2D) # Platzierte Objekte landen hier
```

### `lemming.tscn`
```
Lemming (Node2D)                 # Script: lemming.gd
├── Sprite2D                     # Visuell
└── [kein Collider nötig – rein grid-basiert]
```

### `hud.tscn`
```
HUD (CanvasLayer)                # Script: hud.gd
├── TopBar (HBoxContainer)
│   ├── PauseButton (Button)
│   ├── SavedLabel (Label)       # "Gerettet: X/Y"
│   └── TickSpeedSlider (HSlider)# Optional: Tick-Geschwindigkeit anpassen
├── InventoryPanel (HBoxContainer)
│   └── [InventorySlot-Szenen, dynamisch generiert]
└── PauseOverlay (ColorRect)     # Halbtransparent, sichtbar wenn pausiert
    └── PausedLabel (Label)      # "PAUSED"
```

---

## Koordinatensystem

- **Grid-Koordinaten**: `Vector2i` (Spalte, Zeile)
- **Weltkoordinaten**: `Vector2` = `grid_pos * Constants.TILE_SIZE`
- Die `TileMapLayer` verwendet dasselbe Koordinatensystem
- `TileMapLayer.map_to_local(Vector2i)` gibt die Weltposition zurück

---

## Kommunikation zwischen Systemen (Signals)

Siehe `docs/SIGNALS_AND_APIS.md` für die vollständige Liste.

Kurzübersicht:
- `TickManager.tick_happened` → alle Lemminge und der Spawner reagieren
- `Lemming.reached_exit(lemming)` → `GameManager` zählt gerettete Lemminge
- `Lemming.died(lemming)` → `GameManager` zählt tote Lemminge
- `GameManager.game_state_changed(state)` → HUD aktualisiert sich
- `GameManager.lemming_counts_changed(saved, dead, total)` → HUD aktualisiert Anzeige

