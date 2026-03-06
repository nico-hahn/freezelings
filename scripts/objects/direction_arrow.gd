## DirectionArrow
# Ändert die Laufrichtung eines Lemmings auf target_direction wenn er dieses Tile betritt.
# Bleibt dauerhaft auf dem Tile (single-use ist NICHT das Standard-Verhalten).

class_name DirectionArrow
extends PlaceableObject

## Zielrichtung für Lemminge die dieses Tile betreten.
@export var target_direction: Enums.Direction = Enums.Direction.NORTH


func _ready() -> void:
	# Sprite rotieren basierend auf Richtung
	var sprite: Sprite2D = $Sprite2D
	if sprite:
		match target_direction:
			Enums.Direction.NORTH: sprite.rotation_degrees = 0.0
			Enums.Direction.EAST:  sprite.rotation_degrees = 90.0
			Enums.Direction.SOUTH: sprite.rotation_degrees = 180.0
			Enums.Direction.WEST:  sprite.rotation_degrees = 270.0


func apply_to_lemming(lemming: Lemming) -> void:
	lemming.direction = target_direction


func get_object_type() -> String:
	return "direction_arrow_" + Enums.direction_to_string(target_direction)

