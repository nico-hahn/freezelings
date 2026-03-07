## TickManager
# Autoload "TickManager" – verwaltet den Spiel-Takt.
# Alle Systeme die tick-weise agieren verbinden sich mit tick_happened.
# Pause stoppt NUR den internen Timer, nicht den SceneTree (UI bleibt interaktiv).

extends Node

## Wird jedes Mal emittiert wenn ein Tick vergeht.
signal tick_happened(tick_number: int)

## Wird emittiert wenn das Spiel pausiert wird.
signal paused

## Wird emittiert wenn das Spiel fortgesetzt wird.
signal resumed

var is_paused: bool = false
var tick_count: int = 0
var tick_duration: float = Constants.DEFAULT_TICK_DURATION

var _timer: Timer


func _ready() -> void:
	_timer = Timer.new()
	_timer.wait_time = tick_duration
	_timer.one_shot = false
	_timer.autostart = false
	_timer.timeout.connect(_on_timer_timeout)
	add_child(_timer)


## Startet den Tick-Timer. Wird von LevelController._ready() aufgerufen.
func start() -> void:
	tick_count = 0
	is_paused = false
	_timer.wait_time = tick_duration
	_timer.start()


## Pausiert den Timer. Emittiert "paused".
func pause() -> void:
	if is_paused:
		return
	is_paused = true
	_timer.paused = true
	paused.emit()


## Setzt den Timer fort. Emittiert "resumed".
func resume() -> void:
	if not is_paused:
		return
	is_paused = false
	_timer.paused = false
	resumed.emit()


## Wechselt zwischen Pause und Laufen.
func toggle_pause() -> void:
	if is_paused:
		resume()
	else:
		pause()


## Stoppt den Timer vollständig und setzt tick_count zurück.
func reset() -> void:
	_timer.stop()
	_timer.paused = false
	tick_count = 0
	is_paused = false


## Ändert die Tick-Dauer. Wirkt ab dem nächsten Timer-Zyklus.
func set_tick_duration(seconds: float) -> void:
	tick_duration = clampf(seconds, Constants.MIN_TICK_DURATION, Constants.MAX_TICK_DURATION)
	_timer.wait_time = tick_duration


func get_tick_duration() -> float:
	return tick_duration


func _on_timer_timeout() -> void:
	tick_count += 1
	tick_happened.emit(tick_count)
