# Gameplay Design

## Kern-Spielmechanik

Das Spiel ist ein turn-basierter, grid-basierter Puzzler aus der Vogelperspektive.

---

## Lemminge – Verhalten

### Grundregeln
1. Lemminge laufen **immer geradeaus** in ihre aktuelle Richtung.
2. Ein Lemming bewegt sich **genau ein Tile pro Tick**.
3. Alle Lemminge bewegen sich **gleichzeitig** (innerhalb desselben Ticks).
4. Lemminge können sich **gegenseitig überlappen** (mehrere Lemminge auf einem Tile erlaubt).

### Kollision mit Wänden
Wenn ein Lemming in seiner aktuellen Richtung auf ein **Wand-Tile** (oder den Level-Rand) trifft:
- **Er dreht sich um 180°** und bleibt auf seiner aktuellen Position.
- Im nächsten Tick läuft er in die entgegengesetzte Richtung.

> **Design-Entscheidung**: 180°-Drehung statt Pathfinding. Die Spielaufgabe ist es, durch platzierte Objekte die Lemminge in die richtige Richtung zu lenken, bevor sie bouncing in einem Loop landen.

### Interaktion mit platzierten Objekten
- **Nach dem Betreten eines Tiles** prüft der Lemming, ob sich dort ein platzierbares Objekt befindet.
- Wenn ja, wird der Effekt des Objekts **sofort angewendet** (Richtungsänderung etc.).
- Der neue Effekt gilt ab dem **nächsten Tick**.

**Beispiel-Ablauf (DirectionArrow NORTH auf Tile B):**
```
Tick 1: Lemming ist auf A (Richtung EAST), bewegt sich → landet auf B
         → Erkennt Arrow NORTH → Richtung wird auf NORTH gesetzt
Tick 2: Lemming ist auf B (Richtung NORTH), bewegt sich → landet auf C (nördlich von B)
```

### Tick-Reihenfolge innerhalb eines Ticks
1. Alle **Spawner** feuern ggf. einen neuen Lemming
2. Alle **Lemminge** (in beliebiger Reihenfolge) berechnen ihre neue Position:
   a. Zielposition = aktuelle Position + Richtungsvektor
   b. Ist Zielposition begehbar (kein Wand-Tile)?
      - **Ja**: Lemming bewegt sich auf Zielposition
        - Prüfe ob Zielposition = ExitPoint → Lemming gerettet
        - Prüfe ob Zielposition ein platzierbares Objekt enthält → Effekt anwenden
      - **Nein**: Lemming bleibt, dreht sich 180°
3. Visuelle Tween-Animation für alle Lemminge beginnt gleichzeitig

---

## Spawner

- Der Eingang (EntryPoint) definiert, wo und wie Lemminge erscheinen.
- Konfigurierbar pro Level:
  - `total_lemmings: int` – Gesamtanzahl zu spawnender Lemminge
  - `spawn_interval: int` – Alle N Ticks erscheint ein neuer Lemming
  - `start_direction: Direction` – Richtung, in die neue Lemminge initial laufen
- Wenn alle Lemminge gespawnt wurden, hört der Spawner auf.

---

## Win- und Loss-Bedingungen

| Zustand | Bedingung |
|---------|-----------|
| **Level geschafft** | `saved_count >= required_saved` UND alle Lemminge haben das Level verlassen (gerettet oder tot) |
| **Level gescheitert** | Alle Lemminge tot/weg, aber `saved_count < required_saved` |

Die `required_saved`-Zahl ist pro Level konfigurierbar (z.B. "Rette 7 von 10").

---

## Platzierbare Objekte

Alle platzierbaren Objekte:
- Können nur auf **begehbaren, freien Tiles** platziert werden (kein Wand-Tile, kein anderes Objekt, kein EntryPoint, kein ExitPoint)
- Können **während einer Pause** platziert werden (und während laufendem Spiel)
- Können ggf. wieder entfernt werden (Design-Entscheidung: optional, muss nicht in v1)
- Verbrauchen einen Slot im **Inventar des Spielers**

### Inventar
- Jedes Level definiert ein Startkontingent (z.B. `{"direction_arrow_north": 3, "blocker": 1}`)
- Das Inventar ist im HUD sichtbar und klickbar zum Auswählen

---

## Objekt-Typen (Initial)

Detaillierte Specs: siehe `docs/OBJECT_TYPES.md`

| Objekt | Effekt |
|--------|--------|
| **DirectionArrow** (N/O/S/W) | Ändert die Laufrichtung des Lemmings auf die Pfeilrichtung |
| **Blocker** | Wirkt wie eine Wand: Lemming dreht sich 180°, betritt das Tile NICHT |

### Erweiterungsmöglichkeiten (spätere Versionen)
- **Teleporter**: Verbindet zwei Tiles
- **Splitter**: Lemming klont sich (geht in zwei Richtungen)
- **Trap**: Tötet Lemminge

---

## Pause-System

- Spieler kann jederzeit pausieren (Taste `P` oder Pause-Button im HUD)
- Beim Pausieren: TickManager stoppt, keine Ticks mehr
- Spieler kann weiterhin Objekte platzieren
- Ein visueller Overlay + Text signalisiert den Pause-Zustand
- Beim Fortsetzen: TickManager läuft wieder

---

## Tick-Geschwindigkeit

- Standard: 500 ms pro Tick
- Optional: Der Spieler kann die Geschwindigkeit anpassen (z.B. per Slider im HUD oder Hotkeys)
- Configurable als `Constants.DEFAULT_TICK_DURATION`

---

## Kamera

- `Camera2D` im Game-Node
- Zentriert auf das Level beim Laden
- Optional: Pan/Zoom für größere Level (Mouse Wheel + mittlere Maustaste oder Trackpad)

