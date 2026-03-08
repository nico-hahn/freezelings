# Story 013 – Frozen Sprite & Shiver-Animation beim Pausieren

**Status**: ✅ Erledigt  
**Priorität**: Normal

---

## Ziel

Die Lemming-Szene bekommt ein zweites Sprite (`FrozenSprite2D`) mit der Textur `assets/freezeling_frozen.png`. Dieses Sprite ist identisch zum Original aufgebaut und zeigt immer denselben Frame. Wenn die Ticks pausiert sind, ist nur das Frozen-Sprite sichtbar; wenn die Ticks laufen, nur das Original-Sprite. Zusätzlich spielen alle Lemminge während einer Pause eine kleine Shiver-Animation (links-rechts Vibration mit Pause dazwischen).

---

## Aufgabe 1: `scenes/entities/lemming.tscn` – FrozenSprite2D ergänzen

Ein zweites `Sprite2D` als Kind des Lemming-Root-Nodes hinzufügen, **direkt nach** dem bestehenden `Sprite2D`:

```
Lemming (Node2D)
├── Sprite2D           ← unverändert (freezeling.png)
├── FrozenSprite2D     ← NEU (freezeling_frozen.png)
└── AnimationPlayer    ← unverändert
```

**Eigenschaften von `FrozenSprite2D`** – identisch zu `Sprite2D`:
- `texture` = `res://assets/freezeling_frozen.png`
- `offset` = `Vector2(0, -8)` (identisch zu Sprite2D)
- `hframes` = `4`
- `vframes` = `4`
- `visible` = `false` (startet unsichtbar – Ticks laufen beim Start)

---

## Aufgabe 2: `scripts/entities/lemming.gd` – Frozen-Sprite-Logik

### Neue Node-Referenzen

```gdscript
@onready var _sprite: Sprite2D = $Sprite2D
@onready var _frozen_sprite: Sprite2D = $FrozenSprite2D
```

### Frame-Synchronisation in `_process()`

`FrozenSprite2D` muss immer denselben `frame` wie `Sprite2D` anzeigen. Da der `AnimationPlayer` den Frame-Wert von `Sprite2D` pro Frame aktualisiert, wird `_process()` genutzt um `FrozenSprite2D` synchron zu halten:

```gdscript
func _process(_delta: float) -> void:
	_frozen_sprite.frame = _sprite.frame
```

### Signale verbinden in `initialize()`

```gdscript
TickManager.paused.connect(_on_ticks_paused)
TickManager.resumed.connect(_on_ticks_resumed)
```

### Sichtbarkeits-Wechsel

```gdscript
func _on_ticks_paused() -> void:
	_sprite.visible = false
	_frozen_sprite.visible = true
	_start_shiver()

func _on_ticks_resumed() -> void:
	_sprite.visible = true
	_frozen_sprite.visible = false
	_stop_shiver()
```

### Shiver-Animation

Die Shiver-Animation vibiert den Lemming minimal horizontal. Sie läuft als loopender Tween auf `position.x` relativ zur aktuellen Position (nicht `global_position` – damit sie mit Bewegungs-Tweens nicht interferiert).

**Wichtig:** Die Shiver-Animation verändert `position` (lokale Offset-Position des Nodes), nicht `global_position`. Die Bewegungs-Tweens in `_animate_to()` verändern `global_position`. Die beiden stören sich nicht gegenseitig.

```gdscript
var _shiver_tween: Tween = null
const SHIVER_AMOUNT: float = 1.5   # Pixel nach links/rechts
const SHIVER_SPEED: float = 0.07   # Sekunden pro Halbschwingung
const SHIVER_PAUSE: float = 0.3    # Pause zwischen Schüttel-Bursts


func _start_shiver() -> void:
	_stop_shiver()  # Sicherheitshalber alten Tween beenden
	_shiver_tween = create_tween()
	_shiver_tween.set_loops()  # Endlos wiederholen
	# Burst: kurz links-rechts-links schütteln
	_shiver_tween.tween_property(self, "position:x", -SHIVER_AMOUNT, SHIVER_SPEED)\
		.as_relative().set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	_shiver_tween.tween_property(self, "position:x", SHIVER_AMOUNT * 2.0, SHIVER_SPEED)\
		.as_relative().set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	_shiver_tween.tween_property(self, "position:x", -SHIVER_AMOUNT, SHIVER_SPEED)\
		.as_relative().set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	# Pause zwischen Bursts
	_shiver_tween.tween_interval(SHIVER_PAUSE)


func _stop_shiver() -> void:
	if _shiver_tween != null and _shiver_tween.is_valid():
		_shiver_tween.kill()
		_shiver_tween = null
	# Position zurücksetzen damit kein horizontaler Offset bleibt
	position.x = 0.0
```

### Aufräumen bei Sterben / Verlassen des Levels

Sowohl `_start_exit_animation()` als auch `start_fall_animation()` müssen `_stop_shiver()` aufrufen bevor die Schrumpf-Animation startet, damit kein Konflikt zwischen Shiver und Schrumpf-Tween entsteht. Außerdem TickManager-Signale trennen:

```gdscript
func _start_exit_animation() -> void:
	_stop_shiver()
	TickManager.paused.disconnect(_on_ticks_paused)
	TickManager.resumed.disconnect(_on_ticks_resumed)
	# ... restlicher Code unverändert ...

func start_fall_animation() -> void:
	_stop_shiver()
	TickManager.paused.disconnect(_on_ticks_paused)
	TickManager.resumed.disconnect(_on_ticks_resumed)
	# ... restlicher Code unverändert ...
```

---

## Hinweis zur Shiver-Amplitude

`SHIVER_AMOUNT`, `SHIVER_SPEED` und `SHIVER_PAUSE` sind als Konstanten in `lemming.gd` definiert. Sie müssen nicht per `@export` konfigurierbar sein – bei Bedarf kann das später ergänzt werden.

---

## Akzeptanzkriterien

- [ ] `lemming.tscn` hat einen `FrozenSprite2D (Sprite2D)`-Node mit `freezeling_frozen.png`, `hframes=4`, `vframes=4`, `offset=Vector2(0,-8)`, `visible=false`
- [ ] `FrozenSprite2D.frame` entspricht in jedem Frame exakt `Sprite2D.frame`
- [ ] Wenn Ticks laufen: `Sprite2D` sichtbar, `FrozenSprite2D` unsichtbar
- [ ] Wenn Ticks pausiert sind: `FrozenSprite2D` sichtbar, `Sprite2D` unsichtbar
- [ ] Während der Pause: Lemming vibiert horizontal (Shiver-Animation läuft in Loops)
- [ ] Wenn Ticks fortgesetzt werden: Shiver stoppt, `position.x` wird auf `0` zurückgesetzt
- [ ] Die Bewegungs-Tweens (`_animate_to`) werden durch Shiver nicht gestört
- [ ] Beim Sterben (Hole) und beim Verlassen (Exit): Shiver wird gestoppt, kein horizontaler Offset in der Schrumpf-Animation
- [ ] Lemminge die gespawnt werden während die Ticks bereits pausiert sind, zeigen sofort das Frozen-Sprite und shivern

