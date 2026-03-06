## Lemming
# Repräsentiert einen einzelnen Lemming.
# Bewegt sich einen Tile pro Tick in seine aktuelle Richtung.
# Bei Wand/Blocker: dreht um 180°.
# Bei Ausgang: reached_exit emittieren.
# Bei platzierbarem Objekt: apply_to_lemming() aufrufen (für nächsten Tick).

class_name Lemming
extends Node2D

## Emittiert wenn der Lemming den Ausgang betritt.
signal reached_exit(lemming: Lemming)

## Emittiert wenn der Lemming stirbt (momentan nicht aktiv ausgelöst, für spätere Erweiterung).
@warning_ignore("unused_signal")
signal died(lemming: Lemming)

var grid_pos: Vector2i
var direction: Enums.Direction
var state: Enums.LemmingState = Enums.LemmingState.ALIVE

var _level_controller: LevelController


## Initialisierung. Muss direkt nach Instanzierung aufgerufen werden.
func initialize(
		start_pos: Vector2i,
		start_dir: Enums.Direction,
		level: LevelController
) -> void:
	grid_pos = start_pos
	direction = start_dir
	_level_controller = level

	# Sofortige visuelle Positionierung (kein Tween beim Spawn)
	global_position = _level_controller.grid_to_world(grid_pos)

	# Tick-Signal verbinden
	TickManager.tick_happened.connect(_on_tick_happened)


func _on_tick_happened(_tick_number: int) -> void:
	if state != Enums.LemmingState.ALIVE:
		return
	_process_movement()


func _process_movement() -> void:
	var move_vec: Vector2i = Enums.direction_to_vector(direction)
	var target_pos: Vector2i = grid_pos + move_vec

	if _level_controller.is_tile_walkable(target_pos):
		# Bewegen
		var old_visual_pos: Vector2 = global_position
		grid_pos = target_pos
		var new_world_pos: Vector2 = _level_controller.grid_to_world(grid_pos)
		_animate_to(old_visual_pos, new_world_pos)

		# Ausgang prüfen
		if _level_controller.is_tile_exit(grid_pos):
			state = Enums.LemmingState.EXITING
			TickManager.tick_happened.disconnect(_on_tick_happened)
			reached_exit.emit(self)
			return

		# Platzierbares Objekt prüfen → Effekt für nächsten Tick
		if _level_controller.has_placed_object(grid_pos):
			var obj: Node = _level_controller.get_placed_object(grid_pos)
			obj.apply_to_lemming(self)
	else:
		# Wand oder Blocker: 180° drehen, nicht bewegen
		direction = Enums.opposite_direction(direction)


## Animiert den Lemming von seiner aktuellen visuellen Position zur Zielposition.
## Dauer: etwas kürzer als tick_duration damit es vor dem nächsten Tick abgeschlossen ist.
func _animate_to(from_pos: Vector2, to_pos: Vector2) -> void:
	global_position = from_pos
	var tween: Tween = create_tween()
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.set_trans(Tween.TRANS_SINE)
	tween.tween_property(self, "global_position", to_pos, TickManager.get_tick_duration() * 0.85)

