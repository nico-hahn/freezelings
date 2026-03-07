## LevelDefinition
# Resource-Klasse die ein Level beschreibt.
# Pro Level existiert eine .tres-Datei in resources/level_definitions/.

class_name LevelDefinition
extends Resource

## Anzeigename des Levels in der Level-Auswahl.
@export var level_name: String = ""

## Res-Pfad zur Level-Szene.
@export var scene_path: String = ""

## 0-basierter Index. Bestimmt Reihenfolge und Freischaltungs-Logik.
## Level 0 ist immer freigeschaltet. Level N wird freigeschaltet wenn Level N-1 >= 1 Stern hat.
@export var level_index: int = 0

