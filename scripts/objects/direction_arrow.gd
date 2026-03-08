## DirectionArrow
# Ändert die Laufrichtung eines Lemmings auf target_direction wenn er dieses Tile betritt.
# Bleibt dauerhaft auf dem Tile (single-use ist NICHT das Standard-Verhalten).

class_name DirectionArrow
extends PlaceableObject

## Zielrichtung für Lemminge die dieses Tile betreten.
@export var target_direction: Enums.Direction = Enums.Direction.NORTH

## Wenn true: Pfeil kann vom Spieler nicht entfernt werden (Designer-Objekt).
## Zeigt direction_arrows_fixed.png statt direction_arrows.png.
@export var fixed: bool = false

const TEXTURE_NORMAL: String = "res://assets/direction_arrows.png"
const TEXTURE_FIXED: String = "res://assets/direction_arrows_fixed.png"


func _ready() -> void:
	var sprite: Sprite2D = $Sprite2D
	if sprite == null:
		return
	# Textur je nach fixed-Flag setzen
	sprite.texture = load(TEXTURE_FIXED) if fixed else load(TEXTURE_NORMAL)
	# Frame basierend auf Richtung setzen.
	# Sprite-Sheet-Reihenfolge: NORTH=0, EAST=1, SOUTH=2, WEST=3 – identisch mit Enum-Werten.
	sprite.frame = target_direction as int


func apply_to_lemming(lemming: Lemming) -> void:
	lemming.direction = target_direction


func get_object_type() -> String:
	return "direction_arrow_" + Enums.direction_to_string(target_direction)

