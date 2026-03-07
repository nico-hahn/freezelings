# Implementierungs-Reihenfolge für AI Agents

Dieses Dokument beschreibt, in welcher Reihenfolge das Spiel implementiert werden soll.
Jeder Schritt baut auf dem vorherigen auf. Lese zuerst alle anderen Docs.

## Pflichtlektüre vor der Implementierung
1. `docs/ARCHITECTURE.md` – Ordnerstruktur und Szenen-Hierarchie
2. `docs/GAMEPLAY_DESIGN.md` – Spielregeln und Lemming-Verhalten
3. `docs/SYSTEMS.md` – Detaillierte System-Spezifikationen
4. `docs/SIGNALS_AND_APIS.md` – Signal-Verbindungen und APIs
5. `docs/OBJECT_TYPES.md` – Platzierbare Objekte

---

## Phase 1: Grundgerüst & Autoloads

**Ziel**: Projekt läuft ohne Fehler, Autoloads sind registriert.

### Schritt 1: Enums und Constants anlegen
- `scripts/global/enums.gd` – alle Enums + Hilfsfunktionen (direction_to_vector, opposite_direction)
- `scripts/global/constants.gd` – TILE_SIZE, DEFAULT_TICK_DURATION, MIN/MAX

### Schritt 2: TickManager implementieren
- `scripts/global/tick_manager.gd`
- Timer als Kind-Node (autostart: false)
- Signale: tick_happened, paused, resumed
- Methoden: start, pause, resume, toggle_pause, reset, set_tick_duration

### Schritt 3: GameManager implementieren
- `scripts/global/game_manager.gd`
- Zustand verwalten, Zähler, Signale emittieren
- `_check_win_loss()` nach jedem Zähler-Update aufrufen

### Schritt 4: Autoloads in project.godot registrieren
In der Godot-Reihenfolge:
1. `Enums` → `scripts/global/enums.gd`
2. `Constants` → `scripts/global/constants.gd`
3. `TickManager` → `scripts/global/tick_manager.gd`
4. `GameManager` → `scripts/global/game_manager.gd`

---

## Phase 2: Level-Infrastruktur

**Ziel**: Ein Level kann geladen werden, TileMap ist sichtbar, Grid-Koordinaten funktionieren.

### Schritt 5: LevelController implementieren
- `scripts/level/level_controller.gd`
- `@export`-Variablen definieren
- `_ready()`: Kind-Nodes finden (per `$`-Pfad und `get_node()`)
- `is_tile_walkable()`, `is_tile_exit()` implementieren
- `world_to_grid()`, `grid_to_world()` implementieren (TileMapLayer.map_to_local/local_to_map nutzen)
- `GameManager.initialize_level()` in `_ready()` aufrufen
- `TickManager.start()` in `_ready()` aufrufen

### Schritt 6: Demo-Level-Szene erstellen
- `scenes/levels/level_01.tscn`
- Root Node2D mit `level_controller.gd`
- TileMapLayer "Walls" hinzufügen (mit ein paar Beispiel-Tiles)
- Markers-Gruppe mit EntryPoint und ExitPoint (Marker2D) platzieren
- Leere Node2Ds: LemmingsContainer, PlacedObjectsContainer
- LemmingSpawner-Node hinzufügen (zunächst leerer Node)
- Exportierte Werte im Inspector setzen

### Schritt 7: Game-Szene erstellen
- `scenes/game/game.tscn`
- Node2D mit `game.gd`
- Camera2D hinzufügen
- LevelRoot (Node2D) hinzufügen
- Level-Szene instanzieren unter LevelRoot
- HUD (CanvasLayer) hinzufügen (zunächst leer)

### Schritt 8: Main-Szene
- `scenes/main/main.tscn`
- Lädt `game.tscn` (kann vorerst einfach `game.tscn` als Hauptszene gesetzt werden)
- `project.godot`: `run/main_scene` auf `scenes/game/game.tscn` setzen

---

## Phase 3: Lemminge

**Ziel**: Lemminge spawnen und bewegen sich korrekt durch das Level.

### Schritt 9: Lemming-Szene und Skript
- `scenes/entities/lemming.tscn`: Node2D + Sprite2D (Platzhalter-Textur verwenden)
- `scripts/entities/lemming.gd`
- `initialize()` implementieren
- `_on_tick_happened()` verbinden mit TickManager bei `initialize()`
- Bewegungslogik implementieren (siehe SYSTEMS.md §5)
- Tween-Animation: `create_tween().tween_property(self, "position", target, TickManager.tick_duration * 0.9)`
- Signale `reached_exit` und `died` emittieren

### Schritt 10: LemmingSpawner
- `scripts/entities/lemming_spawner.gd`
- `scenes/entities/lemming_spawner.tscn`
- `initialize()` von LevelController aufrufen (in LevelController._ready())
- Auf `TickManager.tick_happened` hören
- Jeden N-ten Tick einen Lemming instanzieren und unter LemmingsContainer hinzufügen
- Lemming mit `initialize()` konfigurieren
- `GameManager.on_lemming_spawned()` aufrufen

### Schritt 11: Lemming-Events in LevelController verarbeiten
- `Lemming.reached_exit` verbinden → `GameManager.on_lemming_saved()`, Lemming aus Szene entfernen
- `Lemming.died` verbinden → `GameManager.on_lemming_died()`, Lemming aus Szene entfernen

---

## Phase 4: Objekt-Platzierung

**Ziel**: Spieler kann Objekte mit der Maus platzieren.

### Schritt 12: PlaceableObject Basisklasse
- `scripts/objects/placeable_object.gd` (class_name PlaceableObject)

### Schritt 13: DirectionArrow implementieren
- `scripts/objects/direction_arrow.gd`
- `scenes/objects/direction_arrow.tscn`
- `apply_to_lemming()`: setzt `lemming.direction`

### Schritt 14: Blocker implementieren
- `scripts/objects/blocker.gd`
- `scenes/objects/blocker.tscn`
- `is_tile_walkable()` in LevelController beachtet Blocker (bereits in SYSTEMS.md beschrieben)

### Schritt 15: ObjectDefinition Resource
- `scripts/resources/object_definition.gd`
- `.tres` Dateien für jedes Objekt erstellen

### Schritt 16: place_object und remove_object in LevelController
- `placed_objects` Dictionary pflegen
- Validierung: walkable, nicht belegt, nicht Entry/Exit
- Objekt instanzieren und unter `PlacedObjectsContainer` hinzufügen
- Position korrekt setzen (grid_to_world)

### Schritt 17: Input-Handling in game.gd
- `_selected_object_type: String` merken
- `_unhandled_input(event)` für Mausklick
- Klickposition → Weltkoordinaten (mit Camera-Offset) → Grid → `level_controller.place_object()`
- Inventar prüfen, Anzahl dekrementieren

---

## Phase 5: HUD & UI

**Ziel**: Vollständiges HUD mit Inventar, Pause und Statistiken.

### Schritt 18: HUD-Szene erstellen
- `scenes/ui/hud.tscn` mit Struktur wie in ARCHITECTURE.md beschrieben
- `scripts/ui/hud.gd`

### Schritt 19: Inventar-Slots
- `scripts/ui/inventory_slot.gd`
- Dynamisch generiert basierend auf `starting_inventory`
- Zeigt Icon + Anzahl
- Bei Klick: `object_selected` Signal senden

### Schritt 20: HUD mit Signalen verbinden
- `GameManager.lemming_counts_changed` → Label
- `TickManager.paused/resumed` → PauseOverlay
- `HUD.pause_toggled` → `TickManager.toggle_pause()`
- `HUD.object_selected` → `game.gd` selected_object

---

## Phase 6: Win/Loss & Spielfluss

**Ziel**: Level kann gewonnen/verloren werden, Fortschritt wird gespeichert, Level-Auswahl ist Entry-Point.

**Abhängigkeiten zwischen den Schritten**: 23 → 24 → 21 → 25. Unbedingt in dieser Reihenfolge implementieren.

### Schritt 21: Win/Loss-Bildschirm mit Sterne-Bewertung
- Overlay-Szene `scenes/ui/win_loss_screen.tscn` (CanvasLayer)
- Zeigt: Titel ("Level geschafft!" / "Gescheitert"), Sterne-Anzeige (0–3), gerettete Lemminge
- Sterne werden von `GameManager` berechnet anhand neuer `@export`-Schwellwerte in `LevelController`
- `LevelController` bekommt: `stars_threshold_1`, `stars_threshold_2`, `stars_threshold_3`
- Button "Neustart" → `GameManager.restart_level()`
- Button "Zur Level-Auswahl" → `get_tree().change_scene_to_file("res://scenes/ui/level_select.tscn")`
- Ergebnis (Sterne) wird in `ProgressManager` geschrieben (Schritt 24 muss vorher fertig sein)
- Siehe **story_006**

### Schritt 22: Level-Restart
- `GameManager.restart_level()` vollständig implementieren (TickManager reset, Level neu laden)
- Wird von Win/Loss-Bildschirm über Button ausgelöst
- Bereits in `game_manager.gd` als Stub vorhanden – nur verdrahten

### Schritt 23: LevelDefinition Resource & ProgressManager Autoload
- Neue Resource-Klasse `scripts/resources/level_definition.gd` (`class_name LevelDefinition`)
  - `@export var level_name: String`
  - `@export var scene_path: String` (z.B. `"res://scenes/levels/level_01.tscn"`)
  - `@export var level_index: int` (0-basiert, bestimmt Reihenfolge + Freischaltung)
- `.tres`-Dateien erstellen: `resources/level_definitions/level_01.tres`
- Neuer Autoload `ProgressManager` (`scripts/global/progress_manager.gd`)
  - `@export var level_definitions: Array[LevelDefinition]` (im Editor befüllen)
  - Stellt bereit: `get_level_definitions()`, `is_level_unlocked(index)`, `get_stars(index)`
- In `project.godot` als Autoload registrieren (nach GameManager)
- Siehe **story_004**

### Schritt 24: LevelProgress – SaveData & Persistenz
- `ProgressManager` bekommt Lade/Speicher-Logik via `FileAccess` (JSON, `user://save_data.json`)
- Methoden: `save_progress()`, `load_progress()`, `record_level_result(index, stars)`
- `record_level_result` schaltet das nächste Level frei wenn stars >= 1
- `load_progress()` wird in `_ready()` aufgerufen
- Level 0 ist immer freigeschaltet (auch ohne Savefile)
- Siehe **story_005**

### Schritt 25: Level-Auswahl Szene
- Neue Szene `scenes/ui/level_select.tscn` als Entry-Point des Spiels
- Script `scripts/ui/level_select.gd`
- Zeigt Grid (`GridContainer`) mit Level-Karten – dynamisch aus `ProgressManager.get_level_definitions()` befüllt
- Jede Karte (`scenes/ui/level_card.tscn`): Level-Name, Sterne (0–3), gesperrt/freigeschaltet
- Klick auf freigeschaltetes Level → `ProgressManager.current_level_index` setzen → `get_tree().change_scene_to_file("res://scenes/game/game.tscn")`
- Gesperrte Level: Karte ausgegraut, nicht klickbar
- `project.godot`: `run/main_scene` auf `res://scenes/ui/level_select.tscn` ändern
- `game.gd` lädt Level nicht mehr hardcoded, sondern über `ProgressManager.get_current_level_definition()`
- Siehe **story_007**

---

## Phase 7: Polish (optional, nach Grundimplementierung)

- Kamera-Pan und Zoom
- Tick-Geschwindigkeit im HUD anpassbar
- Sound-Effekte (wenn Assets vorhanden)
- Objekt-Entfernen (Rechtsklick auf platzierten Objekt)
- Animations-Tweening verfeinern (Easing, Rotation)
- Mehrere Level mit Level-Select

---

## Wichtige Godot 4.5 Hinweise

- **Kein `TileMap`** verwenden – nur `TileMapLayer`
- **`TileMapLayer.local_to_map(pos)`** für Weltpos → Grid
- **`TileMapLayer.map_to_local(cell)`** für Grid → Weltpos (gibt Tile-Mittelpunkt zurück)
- **`TileMapLayer.get_cell_source_id(cell)`** gibt `-1` zurück wenn kein Tile vorhanden
- **Tween**: `var tween = create_tween(); tween.tween_property(node, "position", target_pos, duration)`
- **Autoloads** werden in `project.godot` unter `[autoload]` registriert
- **Signals**: Immer `signal_name.connect(callable)` verwenden (nicht der alte String-Stil)
- **`@export`** für alle Level-Konfigurationsfelder
- **Typ-Annotationen** überall verwenden: `var x: int = 0`, `func foo(bar: String) -> void:`

