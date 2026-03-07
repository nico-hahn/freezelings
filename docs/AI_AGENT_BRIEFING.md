# Freezing Dungeon – AI Agent Briefing

Dies ist das zentrale Einstiegsdokument für AI Coding Agents.
Lies dieses Dokument zuerst, dann die anderen Docs in `docs/`.

---

## Was ist das für ein Spiel?

Top-down Lemmings-Klon in Godot 4.5. Lemminge laufen durch einen Dungeon, der Spieler platziert Objekte (Richtungspfeile, Blocker) um sie zum Ausgang zu lenken. Das Spiel ist tick-basiert und pausierbar.

---

## Godot-Version & wichtige API-Hinweise

- **Godot 4.5** – keine älteren APIs verwenden
- `TileMapLayer` (nicht `TileMap`)
- `Marker2D` für Entry/Exit-Punkte
- `Tween` für Animationen (`create_tween()`)
- Signals mit `.connect(callable)` verbinden (kein alter String-Stil)
- `@export` für alle Level-Konfigurationen
- Typ-Annotationen überall: `var x: int`, `func foo() -> void:`

---

## Aktueller Stand der Codebase

### ✅ Vollständig vorhanden (Scaffold-Skripte)
| Datei | Status |
|-------|--------|
| `scripts/global/enums.gd` | ✅ Vollständig implementiert |
| `scripts/global/constants.gd` | ✅ Vollständig implementiert |
| `scripts/global/tick_manager.gd` | ✅ Vollständig implementiert |
| `scripts/global/game_manager.gd` | ✅ Vollständig implementiert |
| `scripts/level/level_controller.gd` | ✅ Vollständig implementiert |
| `scripts/level/level_camera.gd` | ✅ Vollständig implementiert (Story 003) |
| `scripts/entities/lemming.gd` | ✅ Vollständig implementiert |
| `scripts/entities/lemming_spawner.gd` | ✅ Vollständig implementiert |
| `scripts/objects/placeable_object.gd` | ✅ Vollständig implementiert |
| `scripts/objects/direction_arrow.gd` | ✅ Vollständig implementiert |
| `scripts/objects/blocker.gd` | ✅ Vollständig implementiert |
| `scripts/resources/object_definition.gd` | ✅ Vollständig implementiert |
| `scripts/resources/level_definition.gd` | ✅ Vollständig implementiert (Story 004) |
| `scripts/global/progress_manager.gd` | ✅ Vollständig implementiert (Story 004) |
| `scripts/ui/hud.gd` | ✅ Vollständig implementiert |
| `scripts/ui/win_loss_screen.gd` | ✅ Vollständig implementiert (Story 006) |
| `scripts/game/game.gd` | ✅ Vollständig implementiert |
| `project.godot` | ✅ Autoloads + Input-Action registriert |

### ✅ Vom Designer bereits erstellt
| Datei | Beschreibung |
|-------|-------------|
| `resources/tilesets/dungeon_tiles.tres` | TileSet mit Textur und Tiles – **nicht anfassen** |
| `scenes/levels/level_01.tscn` | Erstes Level; Inherited Scene von `level_base.tscn`; enthält Ground + Walls + Tiles + Marker |

### ✅ Szenen & Resources (implementiert)
| Datei | Beschreibung |
|-------|-------------|
| `scenes/levels/level_base.tscn` | Template-Szene; alle Level erben hiervon; enthält Camera2D mit level_camera.gd (Story 001+003 ✅) |
| `scenes/game/game.tscn` | Haupt-Spielszene (Node2D + LevelRoot + HUD); **keine Camera2D** – sitzt im Level |
| `scenes/entities/lemming.tscn` | Lemming (Node2D + Sprite2D Platzhalter) |
| `scenes/entities/lemming_spawner.tscn` | Spawner (Node mit lemming_spawner.gd + lemming_scene gesetzt) |
| `scenes/objects/direction_arrow.tscn` | Pfeil-Objekt (Node2D + Sprite2D Platzhalter) – Phase 4 ✅ |
| `scenes/objects/blocker.tscn` | Blocker-Objekt (Node2D + Sprite2D Platzhalter) – Phase 4 ✅ |
| `scenes/ui/hud.tscn` | HUD-Szene (CanvasLayer + TopBar + InventoryPanel + PauseOverlay); inventory_slot_scene gesetzt |
| `scenes/ui/inventory_slot.tscn` | Inventar-Slot (PanelContainer + VBoxContainer + Icon + CountLabel + Button) – Phase 4 ✅ |
| `resources/object_definitions/direction_arrow_north.tres` | ObjectDefinition für Pfeil Nord – Phase 4 ✅ |
| `resources/object_definitions/direction_arrow_east.tres` | ObjectDefinition für Pfeil Ost – Phase 4 ✅ |
| `resources/object_definitions/direction_arrow_south.tres` | ObjectDefinition für Pfeil Süd – Phase 4 ✅ |
| `resources/object_definitions/direction_arrow_west.tres` | ObjectDefinition für Pfeil West – Phase 4 ✅ |
| `resources/object_definitions/blocker.tres` | ObjectDefinition für Blocker – Phase 4 ✅ |
| `resources/level_definitions/level_01.tres` | LevelDefinition für Level 01 – Story 004 ✅ |

### ❌ Noch zu erstellen
*Alle Szenen und Resources für Phase 1–4 sind vorhanden. Fehlende Inhalte betreffen Phase 5–6:*
| Thema | Story | Beschreibung |
|-------|-------|-------------|
| LevelDefinition + ProgressManager | story_004 | Resource-Klasse + Autoload für Level-Registry & Fortschritt |
| LevelProgress SaveData | story_005 | Persistenz via JSON in `user://save_data.json` |
| Stern-Bewertung + Win/Loss-Screen | story_006 | Sterne-Berechnung, Win/Loss-Overlay, Neustart-Button |
| Level-Auswahl | story_007 | `level_select.tscn` als Entry-Point, Level-Karten-Grid |


---

## Implementierungs-Reihenfolge

Siehe `docs/IMPLEMENTATION_ORDER.md` für die vollständige Phasen-Planung.

**Kurzversion:**
1. Szenen bauen (Phase 2 in IMPLEMENTATION_ORDER.md)
2. Lemming-Szene + Spawner-Szene
3. Objekt-Szenen
4. HUD-Szene
5. ObjectDefinition-.tres Dateien
6. Testen & Polish

---

## Kritische Design-Entscheidungen

1. **Lemminge drehen bei Wand 180°** (sie bounchen) – kein Pathfinding
2. **Objekt-Effekte gelten ab dem nächsten Tick** (Lemming betritt Tile → nächster Tick mit neuer Richtung)
3. **Blocker wird in `is_tile_walkable()` geprüft**, nicht in `apply_to_lemming()`
4. **Pause stoppt NUR den TickManager-Timer**, nicht den SceneTree → UI bleibt interaktiv
5. **Mehrere Lemminge können dasselbe Tile teilen** (kein Konflikt)
6. **Leere TileMapLayer-Zelle = begehbar**, belegte Zelle = Wand
7. **Rechtsklick entfernt platzierte Objekte** und gibt sie ins Inventar zurück

---

## Schlüssel-Signalkette

```
TickManager.tick_happened
    → LemmingSpawner._on_tick_happened()   (spawnt ggf. neuen Lemming)
    → Lemming._on_tick_happened()           (alle aktiven Lemminge bewegen sich)

Lemming.reached_exit
    → LevelController                       (Lemming queue_free, GameManager.on_lemming_saved())

GameManager.lemming_counts_changed
    → HUD._on_lemming_counts_changed()      (Label aktualisieren)

GameManager.level_completed
    → Game._on_level_completed()            (Win/Loss-Bildschirm)

HUD.pause_toggled
    → TickManager.toggle_pause()

HUD.object_selected
    → Game._on_object_selected()            (selected_object_type merken)
```

---

## Wichtige Namenskonventionen

- Alle Node-Namen in Level-Szenen **exakt** wie hier angegeben (LevelController sucht sie per `$`-Pfad):
  - `$Walls` – TileMapLayer
  - `$Markers/EntryPoint` – Marker2D
  - `$Markers/ExitPoint` – Marker2D
  - `$LemmingSpawner` – LemmingSpawner-Node
  - `$LemmingsContainer` – Node2D
  - `$PlacedObjectsContainer` – Node2D
- In `game.tscn`:
  - `$LevelRoot` – Node2D für Level-Instanz
  - `$HUD` – CanvasLayer mit hud.gd
  - `$Camera2D` – Camera2D

---

## Stories / User Stories

Vollständige Beschreibungen in `docs/stories/`.

| Story | Titel | Status |
|-------|-------|--------|
| story_001 | Level Base Template Scene | ✅ Erledigt |
| story_002 | Korrekte Screen-zu-Welt-Koordinatenumrechnung | ✅ Erledigt |
| story_003 | Kamera: Panning & Zoom | ✅ Erledigt |
| story_004 | LevelDefinition Resource & ProgressManager Autoload | ✅ Erledigt |
| story_005 | LevelProgress: SaveData & Persistenz | ✅ Erledigt |
| story_006 | Stern-Bewertung & Win/Loss-Bildschirm | ✅ Erledigt |
| story_007 | Level-Auswahl Szene | ✅ Erledigt |
| story_007 | Level-Auswahl Szene | 🟡 Bereit (nach story_004+005+006) |

---

## Level-Design-Workflow (für zukünftige Agents)

- **Neues Level anlegen**: Im Editor `Scene > New Inherited Scene > scenes/levels/level_base.tscn` wählen.
- Alle Level erben von `level_base.tscn` – Skript, Spawner, Container sind bereits vorhanden.
- Level-spezifisch im Kind-Level setzen: `@export`-Werte (total_lemmings etc.), Tile-Daten in Ground/Walls, Positionen von EntryPoint/ExitPoint.
- **`level_base.tscn` niemals direkt bearbeiten** ohne alle Kind-Szenen zu berücksichtigen.
- UIDs in `.tscn`-Dateien müssen dem Godot-Format entsprechen (z.B. `uid://b0gpav47qbmq8`). Selbst vergebene Kurz-UIDs wie `uid://myname` sind **invalide** – Godot vergibt echte UIDs beim ersten Öffnen im Editor.

---

## Assets

Assets werden vom Spieldesigner bereitgestellt. Bis dahin: Platzhalter-Farbrects oder den Godot-Placeholder nutzen. Alle erwarteten Asset-Pfade stehen in `assets/README.md`.

