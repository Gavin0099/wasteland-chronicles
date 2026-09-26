---
name: godot-game-development-expert
description: Expert-level guidance, implementation patterns, and best practices for developing games using the Godot 4.x engine and GDScript. Covers composition over inheritance, signal bus architecture, typed GDScript conventions, 2D/2.5D visual presentation, and headless testing patterns.
---

# Godot Game Development Expert

This reference guide provides production-grade architectural and implementation patterns for Godot 4.x, specifically curated for clean component-based design, 2D/2.5D gameplay, and strict headless testability.

---

## 1. Core Architecture Principles

### 1.1 Composition Over Inheritance
- Prefer composing nodes and components (`Node`, `Node2D`, `Control`) over deep class inheritance hierarchies.
- Encapsulate distinct behaviors into reusable components (e.g. `GroundShadow`, `HitEffect`, `TelegraphBanner`, `HealthBar`).
- Nodes communicate:
  - **Downwards** via explicit method calls: Parent orchestrates its direct children.
  - **Upwards** via Signals: Children emit signals when state changes or events occur; they never directly mutate their parent.

### 1.2 Separation of Simulation and Presentation
- **Simulation (Model)**: Pure GDScript or `RefCounted` objects with no node dependencies. Responsible for world state, numbers, turn calculation, deterministic outcomes.
- **Presentation (View)**: Godot `Node2D` / `Control` scenes. Responsible only for rendering, sprites, Tweens, audio triggers, and player input collection.
- **Rule**: Never mutate simulation state inside an animation callback or Tween finish event. All outcomes are decided in the simulation layer first; the presentation layer merely plays them back.

---

## 2. GDScript 4.x Conventions

### 2.1 Explicit Static Typing
- Annotate every variable, function parameter, and return value with concrete types:
  ```gdscript
  func calculate_damage(attacker_power: int, defender_armor: int) -> int:
      return maxi(1, attacker_power - defender_armor)
  ```
- **Avoid inferred typing `:=` with Variant expressions**: Calls to `get_node()`, `$Node`, `instantiate()`, Dictionary/Array indexing, or untyped methods must not use `:=`. Use explicit type casting or annotations:
  ```gdscript
  var target_node: Node2D = get_node_or_null("Target") as Node2D
  ```

### 2.2 Constant & Resource Preloading
- Preload scripts and resources at the top of the file as constants for fast, compile-time verified references:
  ```gdscript
  const ItemIcon = preload("res://ui/components/item_icon.gd")
  ```

---

## 3. 2.5D Fake-Depth & Visual Presentation Patterns

### 3.1 Isometric / Elevated Camera Illusion
- Create depth without a full 3D viewport by adopting an elevated perspective (approx 30°~35° pitch angle).
- Backgrounds depict an angled ground plane receding toward a high horizon.
- Sprites are drawn in three-quarter isometric perspective, anchored by their contact point on the ground plane.

### 3.2 Ground Contact Shadows
- Sprites do not float: anchor them with dynamic or drawn contact shadows at their feet.
- Scale and squash the shadow ellipse according to perspective (e.g. `Vector2(1.0, 0.28)` transform).
- During jump or recoil animations, shadow position reflects the ground projection while the character sprite offsets vertically, creating tangible height and impact.

### 3.3 Tween-Driven Combat Motion
- Use `create_tween()` for responsive, non-blocking combat feedback:
  - **Anticipation**: Brief backward windup (`0.08s - 0.1s`).
  - **Lunge / Strike**: Rapid forward acceleration along the perspective axis with `TRANS_CUBIC` and `EASE_IN` (`0.12s - 0.15s`).
  - **Hit Impact**: Immediate hit-stop frame, target flash/modulate, and minor knockback (`0.06s`).
  - **Recovery**: Smooth return to idle origin with `EASE_OUT` (`0.18s - 0.22s`).
- Always support a `reduced_motion` mode for accessibility and rapid automated headless scenario execution.

---

## 4. Headless Testing & Determinism

### 4.1 Headless Test Suites
- All gameplay mechanics, turn resolutions, and state transitions must execute cleanly under `godot --headless --script tests/test_*.gd`.
- Tests must assert observable state and invariants with an exit code of `0` on success, `1` on failure.

### 4.2 Seeded Determinism
- Use monotonic sequence IDs or seeded PRNG (`RandomNumberGenerator.new()`) for any randomized game logic.
- Avoid relying on wall-clock time (`Time.get_ticks_msec()` or system timestamps) for gameplay outcomes.
