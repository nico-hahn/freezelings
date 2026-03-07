# Story 005 – LevelProgress: SaveData & Persistenz

**Status**: ✅ Erledigt  
**Priorität**: Hoch  
**Voraussetzung**: story_004 muss vollständig implementiert sein (`ProgressManager` existiert).

---

## Ziel

Den `ProgressManager` um Persistenz erweitern: Fortschrittsdaten (erreichte Sterne, freigeschaltete Level) werden in einer JSON-Datei gespeichert und beim Start geladen. Damit bleibt der Fortschritt über Spielsitzungen hinweg erhalten.

---

## Kontext

`ProgressManager` (`scripts/global/progress_manager.gd`) hat bereits:
- `_progress: Dictionary` – Fortschrittsdaten in-memory
- `record_level_result(index, stars)` – schreibt Ergebnis in `_progress`
- `_initialize_progress()` – initialisiert `_progress` mit Standardwerten

Diese Story ergänzt `save_progress()`, `load_progress()` und bindet sie in den bestehenden Flow ein.

---

## Aufgabe 1: Konstanten ergänzen

Am Anfang von `progress_manager.gd` ergänzen:

```gdscript
const SAVE_PATH: String = "user://save_data.json"
```

---

## Aufgabe 2: `save_progress()` implementieren

```gdscript
## Speichert den aktuellen Fortschritt als JSON in user://save_data.json.
func save_progress() -> void:
	var save_data: Dictionary = {}
	for index in _progress.keys():
		save_data[str(index)] = _progress[index]
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		push_error("ProgressManager: Konnte Savefile nicht öffnen: " + SAVE_PATH)
		return
	file.store_string(JSON.stringify(save_data))
	file.close()
```

---

## Aufgabe 3: `load_progress()` implementieren

```gdscript
## Lädt Fortschrittsdaten aus user://save_data.json.
## Wird in _ready() vor _initialize_progress() aufgerufen.
func load_progress() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return   # Kein Savefile vorhanden → Standardwerte bleiben
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		push_error("ProgressManager: Konnte Savefile nicht lesen: " + SAVE_PATH)
		return
	var content: String = file.get_as_text()
	file.close()
	var parsed = JSON.parse_string(content)
	if parsed == null or not parsed is Dictionary:
		push_error("ProgressManager: Savefile ist kein gültiges JSON.")
		return
	for key in parsed.keys():
		var index: int = int(key)
		_progress[index] = parsed[key]
```

---

## Aufgabe 4: `_ready()` anpassen

`load_progress()` muss **vor** `_initialize_progress()` aufgerufen werden, damit gespeicherte Daten nicht durch Standardwerte überschrieben werden:

```gdscript
func _ready() -> void:
	load_progress()         # Zuerst laden
	_initialize_progress()  # Dann fehlende Einträge mit Standardwerten füllen
```

---

## Aufgabe 5: `record_level_result()` anpassen

Am Ende von `record_level_result()` den Aufruf zu `save_progress()` einfügen:

```gdscript
func record_level_result(index: int, stars: int) -> void:
	# ...bestehende Logik...
	save_progress()   # ← Diese Zeile am Ende ergänzen
```

---

## JSON-Format (Referenz)

```json
{
  "0": { "stars": 3, "unlocked": true },
  "1": { "stars": 1, "unlocked": true },
  "2": { "stars": 0, "unlocked": false }
}
```

> Keys sind Strings (JSON kennt keine Integer-Keys). `int(key)` beim Laden konvertiert zurück.

---

## Akzeptanzkriterien

- [ ] `ProgressManager.save_progress()` schreibt `user://save_data.json`
- [ ] `ProgressManager.load_progress()` liest das Savefile korrekt
- [ ] Beim ersten Start ohne Savefile: Level 0 freigeschaltet, alle anderen gesperrt
- [ ] Nach `record_level_result(0, 2)` und Neustart des Spiels: Level 0 hat 2 Sterne, Level 1 ist freigeschaltet
- [ ] Ungültiges oder fehlendes Savefile führt nicht zu einem Crash
- [ ] Keine anderen bestehenden Dateien werden verändert

