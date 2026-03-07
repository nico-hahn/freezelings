## Enums
# Alle globalen Enums des Projekts.
# Registriert als Autoload "Enums" in project.godot
# Zugriff von überall: Enums.Direction.NORTH, Enums.GameState.PLAYING, etc.

extends Node

enum Direction {
	NORTH,  ## Oben  (Vector2i: 0, -1)
	EAST,   ## Rechts (Vector2i: 1, 0)
	SOUTH,  ## Unten  (Vector2i: 0, 1)
	WEST    ## Links  (Vector2i: -1, 0)
}

enum GameState {
	MENU,
	PLAYING,
	PAUSED,
	LEVEL_COMPLETE,
	LEVEL_FAILED
}

enum LemmingState {
	ALIVE,
	EXITING,  ## Wurde gerade gerettet, Animation läuft
	SAVED,    ## Vollständig gerettet
	FALLING,  ## Fällt ins Hole, Schrumpf-Animation läuft
	DEAD
}


## Gibt den Richtungsvektor für eine Richtung zurück.
func direction_to_vector(dir: Direction) -> Vector2i:
	match dir:
		Direction.NORTH: return Vector2i(0, -1)
		Direction.EAST:  return Vector2i(1, 0)
		Direction.SOUTH: return Vector2i(0, 1)
		Direction.WEST:  return Vector2i(-1, 0)
	return Vector2i.ZERO


## Gibt die entgegengesetzte Richtung zurück.
func opposite_direction(dir: Direction) -> Direction:
	match dir:
		Direction.NORTH: return Direction.SOUTH
		Direction.EAST:  return Direction.WEST
		Direction.SOUTH: return Direction.NORTH
		Direction.WEST:  return Direction.EAST
	return dir


## Gibt den Namen der Richtung als String zurück (z.B. für Objekt-IDs).
func direction_to_string(dir: Direction) -> String:
	match dir:
		Direction.NORTH: return "north"
		Direction.EAST:  return "east"
		Direction.SOUTH: return "south"
		Direction.WEST:  return "west"
	return "unknown"
