## GameManager
# Autoload "GameManager" – verwaltet den globalen Spielzustand.
# Verfolgt Lemming-Zähler, erkennt Win/Loss, steuert Level-Wechsel.

extends Node

## Emittiert wenn sich der Spielzustand ändert.
signal game_state_changed(new_state: Enums.GameState)

## Emittiert wenn sich Lemming-Zähler ändern.
signal lemming_counts_changed(saved: int, dead: int, spawned: int, total: int)

## Emittiert wenn ein Level beendet wurde.
signal level_completed(success: bool, stars: int)

var game_state: Enums.GameState = Enums.GameState.MENU
var total_lemmings: int = 0
var required_saved: int = 0
var saved_count: int = 0
var dead_count: int = 0
var spawned_count: int = 0

var _current_level_path: String = ""
var _level_root: Node = null  ## Referenz auf LevelRoot-Node in game.tscn; wird von game.gd gesetzt


## Wird von LevelController._ready() aufgerufen um den Zähler zu initialisieren.
func initialize_level(total: int, required: int) -> void:
	total_lemmings = total
	required_saved = required
	saved_count = 0
	dead_count = 0
	spawned_count = 0
	_set_state(Enums.GameState.PLAYING)
	lemming_counts_changed.emit(saved_count, dead_count, spawned_count, total_lemmings)


## Lädt eine Level-Szene. level_path ist ein res://-Pfad zur .tscn-Datei.
func load_level(level_path: String) -> void:
	_current_level_path = level_path
	TickManager.reset()
	if _level_root == null:
		push_error("GameManager: _level_root ist nicht gesetzt. game.gd muss GameManager._level_root zuweisen.")
		return
	# Alte Level-Instanz entfernen
	for child in _level_root.get_children():
		child.queue_free()
	# Neue Level-Instanz laden
	var level_scene: PackedScene = load(level_path)
	if level_scene == null:
		push_error("GameManager: Level-Szene konnte nicht geladen werden: " + level_path)
		return
	var level_instance: Node = level_scene.instantiate()
	_level_root.add_child(level_instance)


## Startet das aktuelle Level neu.
func restart_level() -> void:
	if _current_level_path.is_empty():
		push_error("GameManager: Kein aktuelles Level zum Neustarten.")
		return
	load_level(_current_level_path)


## Aufgerufen von LevelController wenn ein Lemming gerettet wurde.
func on_lemming_saved() -> void:
	saved_count += 1
	lemming_counts_changed.emit(saved_count, dead_count, spawned_count, total_lemmings)
	_check_win_loss()


## Aufgerufen von LevelController wenn ein Lemming gestorben ist.
func on_lemming_died() -> void:
	dead_count += 1
	lemming_counts_changed.emit(saved_count, dead_count, spawned_count, total_lemmings)
	_check_win_loss()


## Aufgerufen vom LemmingSpawner wenn ein Lemming gespawnt wurde.
func on_lemming_spawned() -> void:
	spawned_count += 1
	lemming_counts_changed.emit(saved_count, dead_count, spawned_count, total_lemmings)
	_check_win_loss()


## Prüft ob Win- oder Loss-Bedingung erfüllt ist.
func _check_win_loss() -> void:
	var finished: int = saved_count + dead_count
	if spawned_count == total_lemmings and finished == total_lemmings:
		var success: bool = saved_count >= required_saved
		TickManager.reset()
		# Sterne berechnen
		var stars: int = 0
		if success:
			var level_controller: LevelController = _get_active_level_controller()
			if level_controller != null:
				stars = level_controller.calculate_stars(saved_count)
		# Fortschritt speichern
		var level_def: LevelDefinition = ProgressManager.get_current_level_definition()
		if level_def != null:
			ProgressManager.record_level_result(level_def.level_index, stars)
		if success:
			_set_state(Enums.GameState.LEVEL_COMPLETE)
		else:
			_set_state(Enums.GameState.LEVEL_FAILED)
		level_completed.emit(success, stars)


func _get_active_level_controller() -> LevelController:
	if _level_root == null:
		return null
	for child in _level_root.get_children():
		if child is LevelController:
			return child as LevelController
	return null


func _set_state(new_state: Enums.GameState) -> void:
	game_state = new_state
	game_state_changed.emit(new_state)
