## LevelCamera
# Steuert Panning (Linksklick-Drag / Trackpad Two-Finger-Pan) und
# Zoom (Mausrad / Trackpad Pinch) der Spielkamera.
# Sitzt als Kind-Node in jeder Level-Szene (über level_base.tscn geerbt).
# Panning ist nur aktiv wenn kein Objekt im Inventar ausgewählt ist.

class_name LevelCamera
extends Camera2D

## Zoom-Schritt pro Mausrad-Klick (als Faktor, z.B. 0.1 = 10%).
@export var zoom_step: float = 0.1

## Minimaler Zoom-Wert (weiter raus zoomen nicht möglich).
@export var min_zoom: Vector2 = Vector2(0.25, 0.25)

## Maximaler Zoom-Wert (weiter rein zoomen nicht möglich).
@export var max_zoom: Vector2 = Vector2(6.0, 6.0)

## Wird von game.gd gesetzt: true wenn Spieler gerade ein Objekt zum Platzieren ausgewählt hat.
## Wenn true, ist Panning per Linksklick deaktiviert.
var is_placing_object: bool = false

var _is_panning: bool = false


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton

		if mb.button_index == MOUSE_BUTTON_LEFT:
			if mb.pressed and not is_placing_object:
				_is_panning = true
			else:
				_is_panning = false

		elif mb.button_index == MOUSE_BUTTON_WHEEL_UP and mb.pressed:
			_zoom_towards_mouse(1.0 + zoom_step)

		elif mb.button_index == MOUSE_BUTTON_WHEEL_DOWN and mb.pressed:
			_zoom_towards_mouse(1.0 - zoom_step)

	elif event is InputEventMouseMotion and _is_panning:
		position -= (event as InputEventMouseMotion).relative / zoom.x

	elif event is InputEventMagnifyGesture:
		# Pinch-Zoom: factor > 1 = reinzoomen, < 1 = rauszoomen
		_zoom_towards_mouse((event as InputEventMagnifyGesture).factor)

	elif event is InputEventPanGesture and not is_placing_object:
		# Two-Finger-Pan auf dem Trackpad; delta in Screen-Pixeln
		position += (event as InputEventPanGesture).delta / zoom.x


func _zoom_towards_mouse(zoom_factor: float) -> void:
	var old_zoom: float = zoom.x
	var new_zoom_val: float = clampf(old_zoom * zoom_factor, min_zoom.x, max_zoom.x)
	var zoom_center: Vector2 = get_global_mouse_position()
	position = zoom_center + (position - zoom_center) * (old_zoom / new_zoom_val)
	zoom = Vector2(new_zoom_val, new_zoom_val)

