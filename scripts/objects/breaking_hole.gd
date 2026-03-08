## BreakingHole
# Wie ein normales Hole, lässt aber genau einen Lemming passieren.
# Nachdem der erste Lemming das Tile verlassen hat, wechselt das Sprite
# zu Frame 1 und alle weiteren Lemminge sterben wie bei einem normalen Hole.
# Designer-Only: wird vom Designer direkt im DesignerObjectsContainer platziert.

class_name BreakingHole
extends PlaceableObject

enum State { INTACT, WATCHING, BROKEN }

var _state: State = State.INTACT
var _watched_lemming: Lemming = null

@onready var _sprite: Sprite2D = $Sprite2D


func apply_to_lemming(lemming: Lemming) -> void:
	match _state:
		State.INTACT:
			# Erster Lemming betritt das Tile – harmlos, aber wir beobachten ihn
			_watched_lemming = lemming
			_state = State.WATCHING
			TickManager.tick_happened.connect(_on_tick_watching, CONNECT_ONE_SHOT)
		State.WATCHING:
			# Weiterer Lemming betritt das Tile während wir noch beobachten.
			# Noch harmlos – nichts tun.
			pass
		State.BROKEN:
			# Hole ist kaputt – wie normales Hole
			_kill_lemming(lemming)


func _on_tick_watching(_tick_number: int) -> void:
	if _watched_lemming == null or not is_instance_valid(_watched_lemming):
		# Lemming existiert nicht mehr (z.B. durch anderen Effekt gestorben)
		_break()
		return
	if _watched_lemming.grid_pos != grid_pos:
		# Lemming hat das Tile verlassen → Hole bricht auf
		_watched_lemming = null
		_break()
	else:
		# Lemming steht noch drauf – weiter beobachten
		TickManager.tick_happened.connect(_on_tick_watching, CONNECT_ONE_SHOT)


func _break() -> void:
	_state = State.BROKEN
	_sprite.frame = 1


func _kill_lemming(lemming: Lemming) -> void:
	if TickManager.tick_happened.is_connected(lemming._on_tick_happened):
		TickManager.tick_happened.disconnect(lemming._on_tick_happened)
	lemming.state = Enums.LemmingState.FALLING
	lemming.start_fall_animation()


func get_object_type() -> String:
	return "breaking_hole"

