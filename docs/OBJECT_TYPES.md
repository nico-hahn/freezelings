# Platzierbare Objekte – Spezifikation

Dieses Dokument beschreibt alle platzierbaren Objekte im Detail.
Neue Objekte können durch Erstellen einer neuen Unterklasse von `PlaceableObject` hinzugefügt werden.

---

## Allgemeine Regeln für alle Objekte

- Können nur auf **begehbaren Tiles** platziert werden
- Können **nicht** auf anderen platzierten Objekten platziert werden
- Können **nicht** auf EntryPoint oder ExitPoint platziert werden
- Verbrauchen **einen Slot** im Spieler-Inventar
- Sind **permanent** (verbleiben auch nach Betreten durch einen Lemming), außer explizit anders definiert
- Szene-Node-Struktur: `Node2D` mit `Sprite2D` als Kind

---

## Objekt 1: DirectionArrow (Richtungspfeil)

**ID**: `direction_arrow_north`, `direction_arrow_east`, `direction_arrow_south`, `direction_arrow_west`  
**Skript**: `scripts/objects/direction_arrow.gd`  
**Szenen**: `scenes/objects/direction_arrow.tscn` (eine Szene, Richtung per `@export` konfigurierbar)

### Effekt
Wenn ein Lemming dieses Tile betritt, wird seine Laufrichtung auf die Pfeilrichtung gesetzt.

### Verhalten
- Gilt für **alle Lemminge**, die das Tile betreten
- **Permanenter Effekt** – Pfeil bleibt nach Benutzung
- Kann auch rückwärts laufende Lemminge umlenken

### Konfiguration
```gdscript
@export var target_direction: Enums.Direction
```

### Visuelle Anforderung
- Sprite zeigt einen Pfeil in die entsprechende Richtung
- Sprite-Rotation je nach Richtung (0°, 90°, 180°, 270°)
- Alternativ: 4 separate Sprites

### Inventar-Einträge (je eine eigene Ressource)
```
resources/object_definitions/direction_arrow_north.tres
resources/object_definitions/direction_arrow_east.tres
resources/object_definitions/direction_arrow_south.tres
resources/object_definitions/direction_arrow_west.tres
```

---

## Objekt 2: Blocker

**ID**: `blocker`  
**Skript**: `scripts/objects/blocker.gd`  
**Szene**: `scenes/objects/blocker.tscn`

### Effekt
Das Tile mit dem Blocker gilt als **nicht begehbar** (wie eine Wand). Lemminge drehen sich 180° wenn sie gegen einen Blocker laufen.

### Verhalten
- `LevelController.is_tile_walkable()` gibt `false` zurück für Blocker-Tiles
- Lemminge betreten das Tile **nicht** – sie drehen um
- **Permanenter Effekt**

### Visuelle Anforderung
- Ein Hindernis-Sprite (Säule, Wand-Fragment, o.ä.)

### Inventar-Eintrag
```
resources/object_definitions/blocker.tres
```

---

## Geplante zukünftige Objekte (nicht in v1)

### Teleporter (Paar)
- Zwei Teleporter bilden ein Paar
- Lemming betritt Teleporter A → erscheint bei Teleporter B in der gleichen Richtung

### Trap / Falle
- Tötet jeden Lemming, der das Tile betritt
- Kann zur Erschwernis in Leveln eingesetzt werden

### Splitter
- Lemming wird geklont: ein Klon geht geradeaus weiter, ein Klon dreht sich 90° links oder rechts
- Erhöht die Gesamtanzahl der aktiven Lemminge

---

## Implementierungs-Muster für neue Objekte

1. Skript erstellen: `scripts/objects/mein_objekt.gd`
   ```gdscript
   class_name MeinObjekt
   extends PlaceableObject
   
   func apply_to_lemming(lemming: Lemming) -> void:
       # Effekt implementieren
       pass
   
   func get_object_type() -> String:
       return "mein_objekt"
   ```

2. Szene erstellen: `scenes/objects/mein_objekt.tscn`
   - Root: `Node2D` mit Skript `mein_objekt.gd`
   - Kind: `Sprite2D` mit Textur

3. Resource erstellen: `resources/object_definitions/mein_objekt.tres`
   - `object_id = "mein_objekt"`
   - `display_name = "Mein Objekt"`
   - `scene = preload("res://scenes/objects/mein_objekt.tscn")`
   - `icon = preload("res://assets/textures/ui/icon_mein_objekt.png")`

4. Im Level-Dictionary `starting_inventory` eintragen:
   ```gdscript
   @export var starting_inventory: Dictionary = {"mein_objekt": 2}
   ```

