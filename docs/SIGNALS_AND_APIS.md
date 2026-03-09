# Signals & APIs – Vollständige Referenz

Dieses Dokument listet alle Signale, öffentlichen Methoden und exportierten Variablen aller Systeme auf.
Dient als Vertrag zwischen den Systemen für die Implementierung.

---

## TickManager (Autoload)

### Signale
| Signal | Parameter | Beschreibung |
|--------|-----------|--------------|
| `tick_happened` | `tick_number: int` | Wird jedes Mal emittiert wenn ein Tick vergeht |
| `paused` | – | Wurde pausiert |
| `resumed` | – | Wurde fortgesetzt |

### Methoden
| Methode | Rückgabe | Beschreibung |
|---------|----------|--------------|
| `start()` | `void` | Startet den Timer (zu Beginn eines Levels aufrufen) |
| `pause()` | `void` | Pausiert den Timer |
| `resume()` | `void` | Setzt den Timer fort |
| `toggle_pause()` | `void` | Wechselt den Pause-Zustand |
| `reset()` | `void` | Stoppt den Timer, setzt tick_count auf 0 zurück |
| `set_tick_duration(seconds: float)` | `void` | Ändert die Tick-Dauer |
| `get_tick_duration()` | `float` | Gibt die aktuelle Tick-Dauer zurück |

### Properties (lesen)
| Property | Typ | Beschreibung |
|----------|-----|--------------|
| `is_paused` | `bool` | Ob der Timer aktuell pausiert ist |
| `tick_count` | `int` | Anzahl vergangener Ticks seit `start()` |
| `tick_duration` | `float` | Aktuelle Tick-Dauer in Sekunden |

---

## GameManager (Autoload)

### Signale
| Signal | Parameter | Beschreibung |
|--------|-----------|--------------|
| `game_state_changed` | `new_state: Enums.GameState` | Spielzustand hat sich geändert |
| `lemming_counts_changed` | `saved: int, dead: int, spawned: int, total: int` | Lemming-Zähler aktualisiert |
| `level_completed` | `success: bool` | Level beendet (true = geschafft) |

### Methoden
| Methode | Rückgabe | Beschreibung |
|---------|----------|--------------|
| `initialize_level(total: int, required: int)` | `void` | Wird von LevelController zu Beginn aufgerufen |
| `load_level(level_path: String)` | `void` | Lädt eine Level-Szene |
| `restart_level()` | `void` | Lädt das aktuelle Level neu |
| `on_lemming_saved()` | `void` | Wird von LevelController aufgerufen wenn ein Lemming gerettet wurde |
| `on_lemming_died()` | `void` | Wird von LevelController aufgerufen wenn ein Lemming stirbt |
| `on_lemming_spawned()` | `void` | Wird von LevelController aufgerufen wenn ein Lemming gespawnt wurde |

### Properties (lesen)
| Property | Typ | Beschreibung |
|----------|-----|--------------|
| `game_state` | `Enums.GameState` | Aktueller Spielzustand |
| `saved_count` | `int` | Anzahl geretteter Lemminge |
| `dead_count` | `int` | Anzahl toter Lemminge |
| `spawned_count` | `int` | Anzahl bisher gespawnter Lemminge |
| `total_lemmings` | `int` | Gesamtanzahl zu spawnender Lemminge |
| `required_saved` | `int` | Mindestanzahl zu rettender Lemminge |

---

## LevelController (Script auf Level-Node)

### Exportierte Variablen
| Variable | Typ | Standard | Beschreibung |
|----------|-----|---------|--------------|
| `total_lemmings` | `int` | `10` | Gesamtanzahl Lemminge |
| `required_saved` | `int` | `7` | Mindestanzahl zum Gewinnen |
| `spawn_interval` | `int` | `3` | Ticks zwischen Spawns |
| `start_direction` | `Enums.Direction` | `EAST` | Startrichtung der Lemminge |
| `starting_inventory` | `Dictionary` | `{}` | Startkontingent (object_id → count) |

### Methoden (öffentlich)
| Methode | Rückgabe | Beschreibung |
|---------|----------|--------------|
| `is_tile_walkable(grid_pos: Vector2i)` | `bool` | Prüft ob Tile begehbar (Wände + Blocker). **Lemminge werden hier nicht geprüft** – damit Objekte unter Lemmingen platziert werden dürfen |
| `is_tile_occupied_by_lemming(grid_pos: Vector2i)` | `bool` | Prüft ob ein Lemming das Tile belegt (nur für Lemming→Lemming-Kollision) |
| `is_tile_exit(grid_pos: Vector2i)` | `bool` | Prüft ob Tile Ausgang ist |
| `has_placed_object(grid_pos: Vector2i)` | `bool` | Prüft ob Objekt auf Tile |
| `get_placed_object(grid_pos: Vector2i)` | `PlaceableObject\|null` | Gibt Objekt zurück |
| `place_object(grid_pos: Vector2i, object_scene: PackedScene)` | `bool` | Platziert Objekt, gibt false zurück wenn nicht möglich |
| `remove_object(grid_pos: Vector2i)` | `void` | Entfernt Objekt |
| `world_to_grid(world_pos: Vector2)` | `Vector2i` | Weltkoordinaten → Grid |
| `grid_to_world(grid_pos: Vector2i)` | `Vector2` | Grid → Weltkoordinaten (Tile-Mittelpunkt) |
| `get_entry_grid_pos()` | `Vector2i` | Gibt EntryPoint als Grid-Position zurück |
| `get_exit_grid_pos()` | `Vector2i` | Gibt ExitPoint als Grid-Position zurück |
| `register_lemming_position(lemming: Lemming)` | `void` | Trägt Lemming in `lemming_positions` ein (aufgerufen von Lemming nach Bewegung) |
| `unregister_lemming_position(lemming: Lemming)` | `void` | Entfernt Lemming aus `lemming_positions` (vor Bewegung/Tod/Exit) |
| `add_active_lemming(lemming: Lemming)` | `void` | Trägt neuen Lemming in `_active_lemmings` ein (aufgerufen vom Spawner) |

### Benötigte Kind-Nodes (by name)
| Node-Name | Typ | Beschreibung |
|-----------|-----|--------------|
| `"Walls"` | `TileMapLayer` | Wand-Tiles |
| `"Markers/EntryPoint"` | `Marker2D` | Eingang |
| `"Markers/ExitPoint"` | `Marker2D` | Ausgang |
| `"LemmingSpawner"` | `LemmingSpawner` | Spawner |
| `"LemmingsContainer"` | `Node2D` | Container für Lemminge |
| `"PlacedObjectsContainer"` | `Node2D` | Container für Objekte |

---

## Lemming

### Signale
| Signal | Parameter | Beschreibung |
|--------|-----------|--------------|
| `reached_exit` | `lemming: Node` | Lemming hat den Ausgang erreicht |
| `died` | `lemming: Node` | Lemming ist gestorben (momentan nicht aktiv genutzt) |

### Methoden (öffentlich)
| Methode | Rückgabe | Beschreibung |
|---------|----------|--------------|
| `initialize(start_pos: Vector2i, start_dir: Enums.Direction, level: Node)` | `void` | Muss nach Instanzierung aufgerufen werden; registriert Lemming in `lemming_positions` |
| `phase_1_plan(snapshot: Dictionary)` | `void` | Berechnet Zielposition anhand Snapshot; ändert `grid_pos` noch nicht |
| `phase_2_commit()` | `void` | Führt Bewegung aus oder dreht um; wird von LevelController koordiniert |

> **Wichtig**: Lemminge verbinden sich **nicht** selbst mit `TickManager.tick_happened`. Die Koordination übernimmt `LevelController._on_tick_happened()`.

### Properties (lesen/schreiben – von apply_to_lemming aus)
| Property | Typ | Beschreibung |
|----------|-----|--------------|
| `grid_pos` | `Vector2i` | Aktuelle Grid-Position |
| `direction` | `Enums.Direction` | Aktuelle Laufrichtung |
| `state` | `Enums.LemmingState` | Aktueller Zustand |

---

## PlaceableObject (Basisklasse)

### Methoden (zu überschreiben)
| Methode | Rückgabe | Beschreibung |
|---------|----------|--------------|
| `apply_to_lemming(lemming: Node)` | `void` | Effekt auf Lemming anwenden |
| `get_object_type()` | `String` | Objekt-ID zurückgeben |

### Properties
| Property | Typ | Beschreibung |
|----------|-----|--------------|
| `grid_pos` | `Vector2i` | Grid-Position des Objekts |

---

## HUD

### Signale
| Signal | Parameter | Beschreibung |
|--------|-----------|--------------|
| `object_selected` | `object_type: String` | Spieler hat Objekt-Typ im Inventar ausgewählt |
| `pause_toggled` | – | Spieler hat Pause-Button gedrückt |

### Methoden (öffentlich)
| Methode | Rückgabe | Beschreibung |
|---------|----------|--------------|
| `setup_inventory(inventory: Dictionary, definitions: Array[ObjectDefinition])` | `void` | Inventar aufbauen |
| `update_inventory_count(object_type: String, count: int)` | `void` | Anzahl im Inventar aktualisieren |
| `set_paused(paused: bool)` | `void` | Pause-Overlay zeigen/verstecken |

---

## Verbindungsübersicht (Wer verbindet sich mit wem)

```
TickManager.tick_happened ──→ LemmingSpawner._on_tick_happened()
                               (spawnt Lemming; verzögert wenn Entry-Tile belegt)
TickManager.tick_happened ──→ LevelController._on_tick_happened()
                               (koordiniert Zwei-Phasen-Bewegung aller Lemminge)
                                   → Phase 1: alle Lemming.phase_1_plan(snapshot)
                                   → Phase 2: alle Lemming.phase_2_commit()
TickManager.paused        ──→ HUD.set_paused(true)
TickManager.resumed       ──→ HUD.set_paused(false)

Lemming.reached_exit      ──→ LevelController._on_lemming_reached_exit()
                               → _active_lemmings.erase(); unregister_lemming_position()
                               → GameManager.on_lemming_saved(); lemming.queue_free()
Lemming.died              ──→ LevelController._on_lemming_died()
                               → _active_lemmings.erase(); unregister_lemming_position()
                               → GameManager.on_lemming_died(); lemming.queue_free()
LemmingSpawner            ──→ GameManager.on_lemming_spawned() (beim Spawnen)
LemmingSpawner            ──→ LevelController.add_active_lemming() (beim Spawnen)

GameManager.lemming_counts_changed ──→ HUD (Label aktualisieren)
GameManager.game_state_changed     ──→ HUD, Game
GameManager.level_completed        ──→ Game (Level-End-Bildschirm zeigen)

HUD.object_selected       ──→ Game._on_object_selected() (selected_object merken)
HUD.pause_toggled         ──→ TickManager.toggle_pause()

Game (Input) Mausklick    ──→ LevelController.place_object()
```

