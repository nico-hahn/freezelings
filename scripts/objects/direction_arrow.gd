## DirectionArrow
# Ändert die Laufrichtung eines Lemmings auf target_direction wenn er dieses Tile betritt.
# Bleibt dauerhaft auf dem Tile (single-use ist NICHT das Standard-Verhalten).

class_name DirectionArrow
extends PlaceableObject

## Zielrichtung für Lemminge die dieses Tile betreten.
@export var target_direction: Enums.Direction = Enums.Direction.NORTH


func _ready() -> void:
	# Frame basierend auf Richtung setzen.
	# Sprite-Sheet-Reihenfolge: NORTH=0, EAST=1, SOUTH=2, WEST=3 – identisch mit Enum-Werten.
	var sprite: Sprite2D = $Sprite2D
	if sprite:
		sprite.frame = target_direction as int


func apply_to_lemming(lemming: Lemming) -> void:
	lemming.direction = target_direction


func get_object_type() -> String:
	return "direction_arrow_" + Enums.direction_to_string(target_direction)

