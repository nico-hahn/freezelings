## ObjectDefinition
# Resource-Klasse für die Definition eines platzierbaren Objekt-Typs.
# Pro Objekt-Typ existiert eine .tres-Datei in resources/object_definitions/.
# Ermöglicht das einfache Hinzufügen neuer Objekte ohne Code-Änderungen.

class_name ObjectDefinition
extends Resource

## Eindeutige ID, muss mit PlaceableObject.get_object_type() übereinstimmen.
## Beispiele: "direction_arrow_north", "direction_arrow_east", "blocker"
@export var object_id: String = ""

## Anzeigename im HUD-Inventar.
@export var display_name: String = ""

## Szene die instanziert wird wenn das Objekt platziert wird.
@export var scene: PackedScene = null

## Icon für den Inventar-Slot im HUD.
@export var icon: Texture2D = null

