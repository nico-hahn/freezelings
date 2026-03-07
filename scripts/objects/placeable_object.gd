## PlaceableObject
# Basisklasse für alle platzierbaren Objekte.
# Unterklassen überschreiben apply_to_lemming() und get_object_type().

class_name PlaceableObject
extends Node2D

## Grid-Position dieses Objekts. Wird von LevelController beim Platzieren gesetzt.
var grid_pos: Vector2i


## Wendet den Effekt dieses Objekts auf einen Lemming an.
## Wird aufgerufen wenn ein Lemming das Tile dieses Objekts betritt.
## MUSS von Unterklassen überschrieben werden.
func apply_to_lemming(_lemming: Lemming) -> void:
	push_warning("PlaceableObject.apply_to_lemming() nicht implementiert für: " + get_object_type())


## Gibt die eindeutige ID dieses Objekt-Typs zurück.
## MUSS von Unterklassen überschrieben werden.
func get_object_type() -> String:
	push_warning("PlaceableObject.get_object_type() nicht implementiert!")
	return "unknown"

