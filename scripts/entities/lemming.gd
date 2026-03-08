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

## Emittiert wenn der Lemming stirbt (Hole-Animation abgeschlossen).
signal died(lemming: Lemming)

var grid_pos: Vector2i
var direction: Enums.Direction
var state: Enums.LemmingState = Enums.LemmingState.ALIVE

var _level_controller: LevelController
@onready var _sprite: Sprite2D = $Sprite2D
@onready var _frozen_sprite: Sprite2D = $FrozenSprite2D
@onready var _anim_player: AnimationPlayer = $AnimationPlayer

const _DIRECTION_ANIM: Array[String] = ["north", "east", "south", "west"]

const SHIVER_AMOUNT: float = 1.5
const SHIVER_SPEED: float = 0.07
const SHIVER_PAUSE: float = 0.3

var _shiver_tween: Tween = null


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

	# Animation starten
	_play_animation()

	# Pause-Signale verbinden
	TickManager.paused.connect(_on_ticks_paused)
	TickManager.resumed.connect(_on_ticks_resumed)

	# Falls Ticks schon pausiert sind: sofort frozen zeigen
	if TickManager.is_paused:
		_on_ticks_paused()

	# Tick-Signal verbinden
	TickManager.tick_happened.connect(_on_tick_happened)


func _process(_delta: float) -> void:
	_frozen_sprite.frame = _sprite.frame


func _play_animation() -> void:
	if _anim_player == null:
		return
	_anim_player.play(_DIRECTION_ANIM[direction as int])


func _on_ticks_paused() -> void:
	_sprite.visible = false
	_frozen_sprite.visible = true
	_anim_player.pause()
	_start_shiver()


func _on_ticks_resumed() -> void:
	_sprite.visible = true
	_frozen_sprite.visible = false
	_anim_player.play()
	_stop_shiver()


func _start_shiver() -> void:
	_stop_shiver()
	_shiver_tween = create_tween()
	_shiver_tween.set_loops()
	_shiver_tween.tween_property(_frozen_sprite, "position:x", -SHIVER_AMOUNT, SHIVER_SPEED)\
		.as_relative().set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	_shiver_tween.tween_property(_frozen_sprite, "position:x", SHIVER_AMOUNT * 2.0, SHIVER_SPEED)\
		.as_relative().set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	_shiver_tween.tween_property(_frozen_sprite, "position:x", -SHIVER_AMOUNT, SHIVER_SPEED)\
		.as_relative().set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	_shiver_tween.tween_interval(SHIVER_PAUSE)


func _stop_shiver() -> void:
	if _shiver_tween != null and _shiver_tween.is_valid():
		_shiver_tween.kill()
		_shiver_tween = null
	_frozen_sprite.position.x = 0.0


func _on_tick_happened(_tick_number: int) -> void:
	if state != Enums.LemmingState.ALIVE:
		return
	_process_movement()


func _process_movement() -> void:
	# Animation für aktuelle Richtung spielen (wechselt erst wenn Lemming das Tile verlässt)
	_play_animation()
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
			_start_exit_animation()
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


## Spielt die Schrumpf-Animation beim Betreten des Ausgangs ab.
## Emittiert erst nach Abschluss reached_exit.
func _start_exit_animation() -> void:
	_stop_shiver()
	if TickManager.paused.is_connected(_on_ticks_paused):
		TickManager.paused.disconnect(_on_ticks_paused)
	if TickManager.resumed.is_connected(_on_ticks_resumed):
		TickManager.resumed.disconnect(_on_ticks_resumed)
	var tween: Tween = create_tween()
	tween.set_ease(Tween.EASE_IN)
	tween.set_trans(Tween.TRANS_QUAD)
	tween.tween_property(self, "scale", Vector2.ZERO, TickManager.get_tick_duration() * 0.9)
	tween.tween_callback(_on_exit_animation_finished)


func _on_exit_animation_finished() -> void:
	state = Enums.LemmingState.SAVED
	reached_exit.emit(self)


## Spielt die Schrumpf-Animation ab und emittiert danach died.
## Wird von Hole.apply_to_lemming() aufgerufen.
func start_fall_animation() -> void:
	_stop_shiver()
	if TickManager.paused.is_connected(_on_ticks_paused):
		TickManager.paused.disconnect(_on_ticks_paused)
	if TickManager.resumed.is_connected(_on_ticks_resumed):
		TickManager.resumed.disconnect(_on_ticks_resumed)
	var tween: Tween = create_tween()
	tween.set_ease(Tween.EASE_IN)
	tween.set_trans(Tween.TRANS_QUAD)
	tween.tween_property(self, "scale", Vector2.ZERO, TickManager.get_tick_duration() * 0.9)
	tween.tween_callback(_on_fall_animation_finished)


func _on_fall_animation_finished() -> void:
	state = Enums.LemmingState.DEAD
	died.emit(self)


