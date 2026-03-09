## Hole
# Ein Loch im Boden. Läuft ein Lemming auf dieses Tile,
# spielt er eine Schrumpf-Animation und stirbt danach.
# Wird vom Designer platziert (DesignerObjectsContainer) – nicht vom Spieler entfernbar.

class_name Hole
extends PlaceableObject


func apply_to_lemming(lemming: Lemming) -> void:
	# state auf FALLING setzen – phase_1_plan/phase_2_commit skippen bei state != ALIVE
	lemming.state = Enums.LemmingState.FALLING
	lemming.start_fall_animation()


func get_object_type() -> String:
	return "hole"
