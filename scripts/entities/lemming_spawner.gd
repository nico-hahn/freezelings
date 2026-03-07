## LemmingSpawner
# Spawnt Lemminge an der EntryPoint-Position in konfigurierbaren Intervallen.
# Hört auf TickManager.tick_happened.

class_name LemmingSpawner
extends Node

## Szene des Lemmings (im Editor zuweisen – wird in Phase 3 gesetzt).
@export var lemming_scene: PackedScene

var _entry_pos: Vector2i
var _spawn_interval: int
var _total_lemmings: int
var _start_direction: Enums.Direction
var _spawned_count: int = 0
var _level_controller: LevelController
var _lemmings_container: Node2D


## Initialisierung. Wird von LevelController._ready() aufgerufen.
func initialize(
		entry_pos: Vector2i,
		spawn_interval: int,
		total_lemmings: int,
		start_direction: Enums.Direction
) -> void:
	_entry_pos = entry_pos
	_spawn_interval = spawn_interval
	_total_lemmings = total_lemmings
	_start_direction = start_direction
	_level_controller = get_parent() as LevelController
	_lemmings_container = _level_controller.get_node("LemmingsContainer") as Node2D

	TickManager.tick_happened.connect(_on_tick_happened)


func _on_tick_happened(tick_number: int) -> void:
	if _spawned_count >= _total_lemmings:
		return
	# Spawne beim ersten Tick und dann alle N Ticks
	if tick_number == 1 or (tick_number - 1) % _spawn_interval == 0:
		_spawn_lemming()


func _spawn_lemming() -> void:
	if lemming_scene == null:
		return  # lemming_scene noch nicht gesetzt (wird in Phase 3 zugewiesen)

	var lemming: Node2D = lemming_scene.instantiate() as Node2D
	_lemmings_container.add_child(lemming)

	# Lemming initialisieren
	var lemming_script: Lemming = lemming as Lemming
	lemming_script.initialize(_entry_pos, _start_direction, _level_controller)

	# Lemming-Signale mit LevelController verbinden (Schritt 11)
	lemming_script.reached_exit.connect(_level_controller._on_lemming_reached_exit)
	lemming_script.died.connect(_level_controller._on_lemming_died)

	_spawned_count += 1
	GameManager.on_lemming_spawned()
