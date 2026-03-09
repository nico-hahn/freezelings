# Story 019 – Lemming-Kollision (keine Tile-Teilung)

**Status**: 🟡 Bereit zur Implementierung
**Priorität**: Hoch
**Voraussetzungen**: Keine (betrifft Kernsysteme)

---

## Ziel
Lemminge können sich kein Tile mehr teilen. Ein belegtes Tile wirkt wie eine Wand: der ankommende Lemming dreht 180° um. Beim Gegenüberdrehen prallen **beide** Lemminge ab. Der Spawn verzögert sich wenn der Entry-Punkt belegt ist.

---

## Kontext

**Bisher**: `LevelController.is_tile_walkable()` prüft nur Wände (`_walls_layer`) und Blocker-Objekte. Lemminge ignorieren sich gegenseitig vollständig.

**Neu**: Lemming-Positionen blockieren andere Lemminge. Die Prüfung darf jedoch **nicht** in `is_tile_walkable()` eingebaut werden, da diese Funktion auch in `place_object()` genutzt wird – das Platzieren eines Objekts unter einem Lemming soll weiterhin erlaubt sein.

**Kritische Designentscheidung – Option Y**: Wenn zwei Lemminge in einem Tick aufeinander zulaufen (Positionen am Tick-Anfang sind benachbart, Bewegungsvektoren zeigen aufeinander zu), drehen **beide** um. Es gibt kein visuelles "Durcheinanderlaufen". Die Entscheidung basiert ausschließlich auf den Positionen zu **Tick-Beginn** – `grid_pos` wird erst nach der vollständigen Auswertung aller Lemminge aktualisiert.

**Warum Zwei-Phasen und nicht einfach sequenziell mit sofortigem `grid_pos`-Update?**

Gegenüber-Szenario (A→B, B→A) funktioniert mit sofortigem Update scheinbar: A sieht B, dreht; B sieht A (noch auf altem Platz), dreht. ✅

Aber: Folge-Szenario (A will auf Tile 6, B steht auf 6 und will auf 7): A wird zuerst verarbeitet, sieht B auf 6 → dreht um. B wird danach verarbeitet, geht auf 7 und setzt `grid_pos = 7` sofort. A hat also auf Basis einer Information gedreht, die im selben Tick überholt wurde – B war gar nicht mehr auf 6. Das Ergebnis ist reihenfolgeabhängig und falsch.

**Nur ein Snapshot zu Tick-Beginn** (bevor irgendein Lemming `grid_pos` ändert) garantiert konsistentes, reihenfolgeunabhängiges Verhalten. Das erfordert zwingend, dass alle `grid_pos`-Updates nach allen Entscheidungen erfolgen → Zwei-Phasen.

**Reihenfolge LemmingSpawner vs. LevelController**: Der Spawner verbindet sich in `_ready()` mit `TickManager.tick_happened`, der LevelController ebenfalls. Godot feuert Signale in Verbindungsreihenfolge. Da der Spawner-Node vor dem LevelController-Script `_ready()` aufruft (Spawner ist Kind-Node, feuert `_ready()` vor dem Parent? → Nein, in Godot 4 feuert der Parent `_ready()` **nach** allen Kindern). Das bedeutet: **LevelController registriert sich als letzter** → feuert als letzter. Spawner feuert zuerst. ✅ Das ist korrekt – neu gespawnte Lemminge werden via `add_active_lemming()` in `_active_lemmings` eingetragen und sind **im selben Tick noch nicht Teil der Zwei-Phasen-Schleife** (da `_active_lemmings` beim Snapshot-Zeitpunkt noch nicht den neuen Lemming enthält). Das ist gewolltes Verhalten: ein frisch gespawnter Lemming bewegt sich erst im **nächsten** Tick. Falls die Reihenfolge jemals unsicher ist, soll der Agent die Verbindung des LevelControllers explizit nach dem Spawner registrieren oder `CONNECT_DEFERRED` verwenden.

---

## Aufgabe 1: Lemming-Positions-Tracking in `LevelController`

**Datei**: `scripts/level/level_controller.gd`

Ein neues Dictionary trackt alle aktuellen Lemming-Positionen. Es wird von `lemming.gd` und `lemming_spawner.gd` gepflegt.

```gdscript
## Aktuell belegte Tiles: Vector2i → Lemming-Instanz.
## Wird von Lemming-Instanzen selbst gepflegt (register/unregister).
var lemming_positions: Dictionary = {}
```

Neue öffentliche Methoden im `LevelController`:

```gdscript
## Registriert einen Lemming an seiner grid_pos.
## Wird von Lemming.initialize() und nach jeder Bewegung aufgerufen.
func register_lemming_position(lemming: Lemming) -> void:
    lemming_positions[lemming.grid_pos] = lemming

## Entfernt einen Lemming aus dem Positions-Dictionary.
## Wird aufgerufen bevor ein Lemming queue_free() bekommt oder sich bewegt.
func unregister_lemming_position(lemming: Lemming) -> void:
    if lemming_positions.get(lemming.grid_pos) == lemming:
        lemming_positions.erase(lemming.grid_pos)

## Gibt true zurück wenn ein anderer Lemming das Tile belegt.
## Nicht in is_tile_walkable() – nur für Lemming-zu-Lemming-Kollision.
func is_tile_occupied_by_lemming(grid_pos: Vector2i) -> bool:
    return lemming_positions.has(grid_pos)
```

**`is_tile_walkable()` bleibt unverändert** – Lemming-Positionen werden dort **nicht** geprüft.

---

## Aufgabe 2: Snapshot-basierte Bewegungsauswertung in `lemming.gd`

**Datei**: `scripts/entities/lemming.gd`

Das Kernproblem: `grid_pos` darf in einem Tick erst dann aktualisiert werden, wenn alle Lemminge ihre Ziel-Tiles berechnet haben. Andernfalls sieht ein später verarbeiteter Lemming schon die neue Position eines früher verarbeiteten – was zu nicht-deterministischen Ergebnissen führt.

**Lösung**: Zweiphasige Verarbeitung pro Tick:

1. **Phase 1 (Berechnung)**: Jeder Lemming berechnet sein `_intended_pos` und prüft Wände/Blocker via `is_tile_walkable()`. `grid_pos` wird **noch nicht** geändert.
2. **Phase 2 (Commit)**: Nachdem alle Lemminge ihre Absicht registriert haben, werden Konflikte aufgelöst und `grid_pos` tatsächlich gesetzt.

**Konkrete Umsetzung über zwei Tick-Signale:**

Der `LevelController` bekommt einen zweiten Tick-Handler der **nach** allen Lemmingen feuert. Um die Reihenfolge sicherzustellen, nutzt jeder Lemming intern eine `_tick_phase_1()` / `_tick_phase_2()`-Struktur, koordiniert durch den `LevelController`.

**Einfachere Alternative (empfohlen)**: Der `LevelController` übernimmt die Koordination vollständig. Er hält eine Liste aller aktiven Lemminge und ruft in `_on_tick_happened()` erst alle `phase_1_move()` auf, dann prüft er Konflikte, dann ruft er alle `phase_2_commit()` auf.

Dazu:
- Lemminge verbinden sich **nicht** mehr direkt mit `TickManager.tick_happened`
- Stattdessen ruft `LevelController._on_tick_happened()` alle Lemminge in zwei Phasen auf
- `LevelController` registriert sich einmalig bei `TickManager.tick_happened` und hält eine `_active_lemmings: Array[Lemming]`-Liste

### Änderungen in `lemming.gd`

- `TickManager.tick_happened.connect(_on_tick_happened)` **entfernen** aus `initialize()`
- Neue Methode `phase_1_plan(snapshot: Dictionary) -> void`:
  - `snapshot` ist ein `Dictionary[Vector2i, Lemming]` – der **Snapshot** der Positionen zu Tick-Beginn (eine Kopie von `lemming_positions`, übergeben vom LevelController)
  - Prüft `is_tile_walkable(target_pos)` für Wände/Blocker
  - Prüft `snapshot.has(target_pos)` für Lemming-Kollision (Snapshot, **nicht** live `lemming_positions`)
  - Speichert Ergebnis in `_intended_pos: Vector2i` und `_will_move: bool`
  - Bewegt `grid_pos` noch **nicht**
- Neue Methode `phase_2_commit() -> void`:
  - Wenn `_will_move`: aktualisiert `grid_pos = _intended_pos`, aktualisiert `lemming_positions` via `unregister` + `register`, startet Tween, prüft Exit, prüft PlaceableObject
  - Wenn nicht `_will_move`: dreht Richtung um 180°
- Die bisherige `_process_movement()` wird durch diese zwei Phasen ersetzt
- `_on_tick_happened()` wird **entfernt** (LevelController ruft direkt auf)

```gdscript
# Neue interne Variablen:
var _intended_pos: Vector2i
var _will_move: bool = false

func phase_1_plan(snapshot: Dictionary) -> void:
    if state != Enums.LemmingState.ALIVE:
        return
    var move_vec: Vector2i = Enums.direction_to_vector(direction)
    var target_pos: Vector2i = grid_pos + move_vec
    _intended_pos = target_pos

    if _level_controller.is_tile_walkable(target_pos) and not snapshot.has(target_pos):
        _will_move = true
    else:
        _will_move = false

func phase_2_commit() -> void:
    if state != Enums.LemmingState.ALIVE:
        return
    _play_animation()
    if _will_move:
        var old_visual_pos: Vector2 = global_position
        _level_controller.unregister_lemming_position(self)
        grid_pos = _intended_pos
        _level_controller.register_lemming_position(self)
        var new_world_pos: Vector2 = _level_controller.grid_to_world(grid_pos)
        _animate_to(old_visual_pos, new_world_pos)

        if _level_controller.is_tile_exit(grid_pos):
            state = Enums.LemmingState.EXITING
            _level_controller.unregister_lemming_position(self)
            _start_exit_animation()
            return

        if _level_controller.has_placed_object(grid_pos):
            var obj: Node = _level_controller.get_placed_object(grid_pos)
            obj.apply_to_lemming(self)
    else:
        direction = Enums.opposite_direction(direction)
```

### Änderungen in `lemming.gd` – `initialize()`

- Nach dem Setzen von `grid_pos`: `_level_controller.register_lemming_position(self)` aufrufen
- `TickManager.tick_happened.connect(...)` **entfernen**

### Änderungen in `lemming.gd` – Aufräumen beim Sterben/Exit

Wenn ein Lemming `queue_free()` bekommt (via `reached_exit` / `died` in `_on_lemming_reached_exit` / `_on_lemming_died` im LevelController), muss vorher `unregister_lemming_position(self)` aufgerufen werden.

**Sicherer**: `Lemming` räumt sich selbst auf in `_exit_cleanup()` und `_death_cleanup()` – diese werden am Ende der Exit-/Death-Animationen aufgerufen, bevor das Signal emittiert wird. Da die Signale zu `_on_lemming_reached_exit` / `_on_lemming_died` führen, die `queue_free()` aufrufen, ist das der richtige Moment.

Alternativ: `_level_controller.unregister_lemming_position(self)` direkt in `_on_lemming_reached_exit()` und `_on_lemming_died()` im LevelController aufrufen – **vor** `queue_free()`.

---

## Aufgabe 3: Zwei-Phasen-Tick im `LevelController`

**Datei**: `scripts/level/level_controller.gd`

```gdscript
## Alle aktuell lebenden Lemminge (für Tick-Koordination).
var _active_lemmings: Array[Lemming] = []

func _on_tick_happened(tick_number: int) -> void:
    # Snapshot der Positionen zu Tick-Beginn
    var snapshot: Dictionary = lemming_positions.duplicate()

    # Phase 1: Alle Lemminge planen ihre Bewegung
    for lemming in _active_lemmings:
        lemming.phase_1_plan(snapshot)

    # Phase 2: Alle Lemminge committen ihre Bewegung
    for lemming in _active_lemmings:
        lemming.phase_2_commit()
```

- `TickManager.tick_happened.connect(_on_tick_happened)` in `_ready()` registrieren
- `_active_lemmings` wird befüllt wenn der Spawner einen Lemming hinzufügt (via neue `add_active_lemming()`-Methode oder direkt über `LemmingSpawner`)
- Lemminge werden aus `_active_lemmings` entfernt wenn sie den Ausgang erreichen oder sterben (in `_on_lemming_reached_exit` / `_on_lemming_died`)

**Hinweis**: `TickManager.stop()` / Level-Reset müssen `_active_lemmings` leeren und `lemming_positions` leeren.

---

## Aufgabe 4: Spawner – verzögerter Spawn bei belegtem Entry-Tile

**Datei**: `scripts/entities/lemming_spawner.gd`

Der Spawner darf keinen neuen Lemming spawnen wenn das Entry-Tile belegt ist. Er soll es im nächsten Tick erneut versuchen – der Lemming gilt als "ausstehend" bis er tatsächlich gespawnt wurde.

```gdscript
var _pending_spawn: bool = false  # Spawn aufgeschoben, weil Entry-Tile belegt war

func _on_tick_happened(tick_number: int) -> void:
    if _spawned_count >= _total_lemmings and not _pending_spawn:
        return
    var should_spawn: bool = _pending_spawn \
        or tick_number == 1 \
        or (tick_number - 1) % _spawn_interval == 0

    if should_spawn:
        if _level_controller.is_tile_occupied_by_lemming(_entry_pos):
            _pending_spawn = true  # Tile belegt, nächsten Tick erneut versuchen
        else:
            _pending_spawn = false
            _spawn_lemming()
```

**Wichtig**: `_spawn_lemming()` ruft `_level_controller.add_active_lemming(lemming)` auf (oder äquivalent), damit der LevelController den Lemming in seine Tick-Koordination aufnimmt.

---

## Aufgabe 5: `LemmingSpawner` – neuen Lemming in `_active_lemmings` eintragen

In `_spawn_lemming()` nach `lemming_script.initialize(...)`:

```gdscript
_level_controller.add_active_lemming(lemming_script)
```

Neue Methode in `LevelController`:

```gdscript
func add_active_lemming(lemming: Lemming) -> void:
    _active_lemmings.append(lemming)
```

---

## Aufgabe 6: Aufräumen in `_on_lemming_reached_exit` / `_on_lemming_died`

**Datei**: `scripts/level/level_controller.gd`

```gdscript
func _on_lemming_reached_exit(lemming: Lemming) -> void:
    _active_lemmings.erase(lemming)
    unregister_lemming_position(lemming)
    GameManager.on_lemming_saved()
    lemming.queue_free()

func _on_lemming_died(lemming: Lemming) -> void:
    _active_lemmings.erase(lemming)
    unregister_lemming_position(lemming)
    GameManager.on_lemming_died()
    lemming.queue_free()
```

---

## Akzeptanzkriterien

- [ ] Zwei Lemminge können sich nicht mehr dasselbe Tile teilen – ein ankommender Lemming dreht 180° um
- [ ] Wenn zwei Lemminge aufeinander zulaufen (Gegenüber in benachbarten Tiles), drehen **beide** in demselben Tick um – kein visuelles Durcheinanderlaufen
- [ ] Die Entscheidung basiert auf dem Positions-Snapshot zu Tick-Beginn – `grid_pos` wird erst in Phase 2 aktualisiert
- [ ] `is_tile_walkable()` bleibt unverändert – Lemming-Positionen werden dort **nicht** geprüft
- [ ] Ein Objekt kann unter einem Lemming platziert werden (Lemming blockiert `place_object()` nicht)
- [ ] Der Spawn verzögert sich wenn das Entry-Tile von einem Lemming belegt ist – kein Lemming wird verworfen
- [ ] `lemming_positions` Dictionary ist konsistent: jeder lebende Lemming ist exakt einmal eingetragen, an seiner tatsächlichen `grid_pos`
- [ ] `_active_lemmings` Array ist konsistent: gestorbene/exitierte Lemminge werden korrekt entfernt
- [ ] Beim Level-Reset (Restart) sind `lemming_positions` und `_active_lemmings` vollständig geleert

