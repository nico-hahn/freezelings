## Blocker
# Wirkt wie eine Wand: Lemminge drehen um 180° wenn sie dieses Tile betreten wollen.
# Die Kollisionsprüfung erfolgt in LevelController.is_tile_walkable(),
# daher wird apply_to_lemming() für Blocker NIE aufgerufen.

class_name Blocker
extends PlaceableObject


func apply_to_lemming(_lemming: Lemming) -> void:
	# Wird nicht aufgerufen - Blocker wird in is_tile_walkable() behandelt.
	pass


func get_object_type() -> String:
	return "blocker"

