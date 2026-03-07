## Hole
# Ein Loch im Boden. Läuft ein Lemming auf dieses Tile,
# spielt er eine Schrumpf-Animation und stirbt danach.
# Wird vom Designer platziert (DesignerObjectsContainer) – nicht vom Spieler entfernbar.

class_name Hole
extends PlaceableObject


func apply_to_lemming(lemming: Lemming) -> void:
	# Tick-Verbindung trennen damit sich der Lemming nicht weiter bewegt
	if TickManager.tick_happened.is_connected(lemming._on_tick_happened):
		TickManager.tick_happened.disconnect(lemming._on_tick_happened)
	lemming.state = Enums.LemmingState.FALLING
	lemming.start_fall_animation()


func get_object_type() -> String:
	return "hole"

