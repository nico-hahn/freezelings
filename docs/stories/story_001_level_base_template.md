# Story 001 – Level Base Template Scene

**Status**: 🟡 Bereit zur Implementierung  
**Priorität**: Hoch – Voraussetzung für komfortables Level-Design  

---

## Kontext

Der Designer hat bereits:
- `resources/tilesets/dungeon_tiles.tres` – vollständig konfiguriertes TileSet mit Textur und Tiles
- `scenes/levels/level_01.tscn` – ein fertiges Level mit `Ground`- und `Walls`-TileMapLayer, beide referenzieren `dungeon_tiles.tres`

Die `level_01.tscn` ist aktuell eine eigenständige Szene. Zukünftig soll jedes neue Level durch **Szenen-Vererbung** (`Scene > New Inherited Scene`) entstehen, nicht durch Duplizieren.

---

## Ziel

1. Eine Template-Szene `scenes/levels/level_base.tscn` erstellen, die die gemeinsame Struktur aller Level definiert.
2. `scenes/levels/level_01.tscn` zu einer **Inherited Scene** von `level_base.tscn` umwandeln, dabei alle bestehenden Tile-Daten und Konfigurationen erhalten.

---

## Aufgabe 1: `scenes/levels/level_base.tscn` erstellen

### Node-Hierarchie

```
LevelBase (Node2D)                         ← Root; Script: res://scripts/level/level_controller.gd
├── Ground (TileMapLayer)                  ← Rein visuell (Boden); tile_set = dungeon_tiles.tres
├── Walls (TileMapLayer)                   ← Spiellogik (Wände); tile_set = dungeon_tiles.tres
├── Markers (Node2D)
│   ├── EntryPoint (Marker2D)
│   └── ExitPoint (Marker2D)
├── LemmingSpawner (instanziert aus scenes/entities/lemming_spawner.tscn)
├── LemmingsContainer (Node2D)
└── PlacedObjectsContainer (Node2D)
```

### Wichtige Details

- **`Ground` kommt vor `Walls`** im Szenenbaum – so wird Ground zuerst gerendert (liegt visuell darunter).
- **Beide TileMapLayer** referenzieren dasselbe TileSet: `res://resources/tilesets/dungeon_tiles.tres`
- **Keine Tile-Daten** in `level_base.tscn` eintragen – die Szene bleibt leer (nur Struktur).
- Der Root-Node bekommt `level_controller.gd` als Script mit sinnvollen Export-Standardwerten.
- `EntryPoint` und `ExitPoint` können auf `Vector2(0, 0)` bleiben – der Designer setzt sie im Kind-Level.

### Vollständiges `.tscn`-Format

Die UIDs der `ext_resource`-Einträge müssen den tatsächlichen UIDs der Dateien im Projekt entsprechen. Diese können mit dem Tool `mcp_godot_get_uid` abgefragt werden oder sind in bestehenden Szenen (z.B. `level_01.tscn`) bereits sichtbar:

- `dungeon_tiles.tres` → uid: `uid://brea3fpq2hhp1`
- `level_controller.gd` → uid: `uid://b0gpav47qbmq8`
- `lemming_spawner.tscn` → UID per `mcp_godot_get_uid` abfragen

```tscn
[gd_scene load_steps=4 format=4 uid="uid://NEUE_UID_GENERIEREN"]

[ext_resource type="Script" uid="uid://b0gpav47qbmq8" path="res://scripts/level/level_controller.gd" id="1_lc"]
[ext_resource type="TileSet" uid="uid://brea3fpq2hhp1" path="res://resources/tilesets/dungeon_tiles.tres" id="2_ts"]
[ext_resource type="PackedScene" path="res://scenes/entities/lemming_spawner.tscn" id="3_spawner"]

[node name="LevelBase" type="Node2D"]
script = ExtResource("1_lc")
total_lemmings = 10
required_saved = 7
spawn_interval = 3
start_direction = 1

[node name="Ground" type="TileMapLayer" parent="."]
tile_set = ExtResource("2_ts")
texture_filter = 1

[node name="Walls" type="TileMapLayer" parent="."]
tile_set = ExtResource("2_ts")
texture_filter = 1

[node name="Markers" type="Node2D" parent="."]

[node name="EntryPoint" type="Marker2D" parent="Markers"]

[node name="ExitPoint" type="Marker2D" parent="Markers"]

[node name="LemmingSpawner" parent="." instance=ExtResource("3_spawner")]

[node name="LemmingsContainer" type="Node2D" parent="."]

[node name="PlacedObjectsContainer" type="Node2D" parent="."]
```

> **Hinweis zur UID der Szene selbst**: Die `uid=` im `[gd_scene]`-Header muss eine neue, einzigartige UID sein. Diese kann über `mcp_godot_get_uid` nach dem Erstellen oder durch Öffnen in Godot automatisch vergeben werden. Alternativ: Datei ohne UID-Angabe erstellen, Godot vergibt sie beim ersten Öffnen.

> **Hinweis zur `lemming_spawner.tscn`-UID**: Falls die UID von `lemming_spawner.tscn` noch nicht bekannt ist, `path=` ohne `uid=` angeben – Godot löst das beim Öffnen auf.

---

## Aufgabe 2: `level_01.tscn` zu Inherited Scene umwandeln

`level_01.tscn` enthält bereits die komplette Struktur (Ground, Walls mit Tile-Daten, Markers, Spawner etc.) und **muss erhalten bleiben**. Die Umwandlung zur Inherited Scene bedeutet:

- Der Root-Node referenziert `level_base.tscn` als Elternszene
- Alle Overrides (Tile-Daten, Marker-Positionen, Export-Werte) bleiben erhalten
- Nodes die identisch mit dem Base-Template sind, werden nicht mehr redundant gespeichert

### Vorgehensweise im Godot-Editor (empfohlen)

Da die bestehenden Tile-Daten erhalten bleiben müssen, ist der Editor-Weg am sichersten:

1. `level_01.tscn` im Editor öffnen
2. `Scene > Convert to Inherited Scene` (oder gleichwertiges Menü in Godot 4.5)
3. `level_base.tscn` als Elternszene auswählen
4. Speichern

### Vorgehensweise per .tscn-Datei (Fallback)

Falls kein Editor-Zugriff möglich ist: `level_01.tscn` so umschreiben, dass sie von `level_base.tscn` erbt. Alle bestehenden Node-Daten werden als Overrides eingetragen.

Das aktuelle Format von `level_01.tscn` (Standalone-Szene) muss in dieses Format überführt werden:

```tscn
[gd_scene load_steps=3 format=4 uid="uid://bvxf1r38n7itk"]

[ext_resource type="PackedScene" uid="uid://UID_VON_LEVEL_BASE" path="res://scenes/levels/level_base.tscn" id="1_base"]
[ext_resource type="TileSet" uid="uid://brea3fpq2hhp1" path="res://resources/tilesets/dungeon_tiles.tres" id="2_ts"]

[node name="Level01" instance=ExtResource("1_base")]
total_lemmings = 5
required_saved = 3
start_direction = 2

[node name="Ground" parent="." index="0"]
tile_map_data = PackedByteArray("... BESTEHENDE DATEN UNVERÄNDERT ÜBERNEHMEN ...")
tile_set = ExtResource("2_ts")
texture_filter = 1

[node name="Walls" parent="." index="1"]
tile_map_data = PackedByteArray("... BESTEHENDE DATEN UNVERÄNDERT ÜBERNEHMEN ...")
tile_set = ExtResource("2_ts")
texture_filter = 1

[node name="EntryPoint" parent="Markers" index="0"]
position = Vector2(88, 24)

[node name="ExitPoint" parent="Markers" index="1"]
position = Vector2(120, 136)
```

> ⚠️ Die `PackedByteArray`-Daten aus der aktuellen `level_01.tscn` **unverändert** übernehmen – das sind die vom Designer gemalten Tiles.  
> ⚠️ Die UID von `level_base.tscn` erst nach deren Erstellung eintragen.

---

## Akzeptanzkriterien

- [ ] `scenes/levels/level_base.tscn` existiert mit der beschriebenen Node-Hierarchie
- [ ] `Ground` liegt vor `Walls` im Szenenbaum von `level_base.tscn`
- [ ] Beide TileMapLayer in `level_base.tscn` haben `dungeon_tiles.tres` als TileSet gesetzt
- [ ] `level_base.tscn` enthält keine Tile-Daten (leere TileMapLayer)
- [ ] `level_01.tscn` ist eine Inherited Scene von `level_base.tscn`
- [ ] `level_01.tscn` behält alle bestehenden Tile-Daten, Marker-Positionen und Export-Werte
- [ ] Ein neues Level kann über `Scene > New Inherited Scene > level_base.tscn` angelegt werden
- [ ] Das Projekt öffnet ohne Fehler in Godot 4.5
- [ ] `dungeon_tiles.tres` wird nicht verändert

