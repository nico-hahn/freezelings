## Constants
# Globale Konstanten des Projekts.
# Registriert als Autoload "Constants" in project.godot.
# Zugriff: Constants.TILE_SIZE, Constants.DEFAULT_TICK_DURATION, etc.

## Größe eines Tiles in Pixeln. Muss mit dem TileSet übereinstimmen.
const TILE_SIZE: int = 32

## Standard-Tick-Dauer in Sekunden.
const DEFAULT_TICK_DURATION: float = 0.5

## Minimale Tick-Dauer (schnellste Spielgeschwindigkeit).
const MIN_TICK_DURATION: float = 0.1

## Maximale Tick-Dauer (langsamste Spielgeschwindigkeit).
const MAX_TICK_DURATION: float = 2.0

## Szenen-Pfade (zentral verwaltet, einfacher zu refactoren)
const SCENE_LEMMING: String = "res://scenes/entities/lemming.tscn"
const SCENE_DIRECTION_ARROW: String = "res://scenes/objects/direction_arrow.tscn"
const SCENE_BLOCKER: String = "res://scenes/objects/blocker.tscn"

## Pfad zum Object-Definitions-Ordner
const OBJECT_DEFINITIONS_PATH: String = "res://resources/object_definitions/"

