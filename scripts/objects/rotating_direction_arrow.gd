## RotatingDirectionArrow
# Lenkt Lemminge wie ein normaler DirectionArrow, rotiert aber seine Richtung
# um k * 90° im Uhrzeigersinn nachdem ein Lemming das Tile verlassen hat.
# Kann vom Designer (DesignerObjectsContainer) oder als Spieler-Objekt verwendet werden.

class_name RotatingDirectionArrow
extends PlaceableObject

## Aktuelle Zielrichtung. Wird nach jedem Lemming-Durchgang rotiert.
@export var target_direction: Enums.Direction = Enums.Direction.NORTH

## Anzahl der 90°-Schritte im Uhrzeigersinn nach jedem Lemming-Durchgang.
## k=1 → 90°, k=2 → 180°, k=3 → 270°
@export var k: int = 2

@onready var _sprite: Sprite2D = $Sprite2D

var _watched_lemming: Lemming = null


func _ready() -> void:
	_update_sprite()


func apply_to_lemming(lemming: Lemming) -> void:
	lemming.direction = target_direction
	# Beobachten wann der Lemming das Tile verlässt
	_watched_lemming = lemming
	TickManager.tick_happened.connect(_on_tick_watching, CONNECT_ONE_SHOT)


func _on_tick_watching(_tick_number: int) -> void:
	if _watched_lemming == null or not is_instance_valid(_watched_lemming):
		# Lemming existiert nicht mehr – trotzdem rotieren
		_rotate_direction()
		return
	if _watched_lemming.grid_pos != grid_pos:
		# Lemming hat das Tile verlassen → rotieren
		_watched_lemming = null
		_rotate_direction()
	else:
		# Lemming steht noch drauf – weiter beobachten
		TickManager.tick_happened.connect(_on_tick_watching, CONNECT_ONE_SHOT)


func _rotate_direction() -> void:
	target_direction = (target_direction + k) % 4 as Enums.Direction
	_update_sprite()


func _update_sprite() -> void:
	if _sprite == null:
		return
	# Sprite-Sheet-Reihenfolge identisch mit Direction-Enum: NORTH=0, EAST=1, SOUTH=2, WEST=3
	_sprite.frame = target_direction as int


func get_object_type() -> String:
	return "rotating_direction_arrow"

