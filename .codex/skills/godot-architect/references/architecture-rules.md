# Godot 4 Architecture Rules

## 1. Establish ownership first

Treat the SceneTree as a lifetime and dependency graph, not merely a spatial hierarchy.

- A child belongs under a parent when deleting the parent should also delete the child.
- A reusable scene must contain everything required for its internal operation.
- The node that instantiates another scene owns its configuration and external connections.
- Cross-feature coordination belongs in the nearest common owner, not in either feature.

Before coding a feature, answer:

1. Who creates it?
2. Who destroys it?
3. What data does it own?
4. Which external services does it require?
5. Which events does it publish?
6. Can its scene run alone for testing?

## 2. Use a dependency direction

Use this default direction and document exceptions:

```text
application -> feature coordinators -> domain actors -> presentation
                              \-> data Resources
platform adapters -----------> interfaces owned by application
```

- Domain actors must not know the concrete HUD, save backend, or scene switcher.
- UI may observe immutable snapshots or signals, then submit commands through a narrow API.
- Data Resources must not reach into scenes.
- Platform code must be isolated behind a small adapter so desktop tests remain possible.

## 3. Choose the smallest Godot abstraction

| Need | Prefer | Avoid |
|---|---|---|
| Position, draw, physics, callbacks, tree lifetime | Node or scene | Plain data object pretending to be a Node |
| Inspector-authored definition data | Custom Resource | Large untyped Dictionary |
| Pure calculation | RefCounted/static helper | Invisible manager Node |
| One scene's reusable visual/behavior unit | PackedScene | Runtime construction spread across scripts |
| Truly global lifetime and isolated state | Autoload | Global access for convenience |
| Many homogeneous objects at scale | Batched rendering/server API after profiling | Thousands of feature-heavy Nodes |

Prefer composition of small scenes over deep inheritance. Use inheritance only when subtype substitution is real and stable.

## 4. Design scene boundaries

A healthy feature scene normally contains:

- a root typed for the feature's dominant behavior;
- internal visuals, collision, animation and audio;
- an explicit public configuration API;
- signals describing completed domain events;
- configuration warnings for required editor setup when practical.

Do not let an instanced scene assume a particular ancestor path. Inject its target, definition Resource, or service before activation.

Use scene unique nodes for stable same-scene references. Do not use them across nested scene boundaries. Cache references in `@onready` variables rather than repeatedly calling `find_child()`.

## 5. Define communication rules

Use direct calls when:

- caller owns the callee;
- the operation is a command with one known receiver;
- the return value is immediately required.

Use signals when:

- a child reports an event to an owner;
- zero or multiple observers may react;
- the emitter should not know presentation or meta systems.

Use a coordinator when an event crosses feature boundaries. Keep signal names in completed-event form such as `damage_applied`, `enemy_defeated`, or `run_finished`. Disconnect long-lived external connections when ownership does not guarantee automatic cleanup.

## 6. Separate definition data from runtime state

Use custom Resources for definitions such as:

- character class and base stats;
- ability timings, costs and effect definitions;
- enemies and loot tables;
- items, quests and world regions.

Use stable string or `StringName` identifiers for saved references. Keep live health, cooldowns, inventory quantities and temporary modifiers in runtime state objects. A loaded Resource is cached and can be shared, so mutating it may affect every consumer.

Resource rules:

- type exported fields;
- validate ranges at authoring or load time;
- split oversized Resources by cohesive responsibility;
- reference other Resources rather than copying their fields;
- version serialized save data separately from content definitions.

## 7. Limit Autoload scope

Acceptable Autoload candidates have a global lifetime and own their state without reaching into arbitrary scenes. Examples include save orchestration, settings, application flow, platform services and audio routing.

Reject an Autoload when:

- it exists only to avoid passing one reference;
- it mutates unrelated feature internals;
- it is a collection of every utility function;
- it makes isolated scene execution impossible;
- order-dependent initialization is undocumented.

Expose narrow methods and signals. Clear session-scoped state explicitly when returning to the title screen.

## 8. Organize files for change locality

Godot uses the filesystem directly. Keep feature-specific scene, script, art and audio close together when that makes ownership obvious. Keep genuinely shared data and utilities in dedicated folders.

Example, not a mandatory template:

```text
res://
  app/
  features/combat/
  features/progression/
  actors/player/
  actors/enemies/
  world/regions/
  ui/
  data/
  platform/
  tests/
```

Use PascalCase for node names, snake_case for files and variables, and `class_name` only for meaningful project-wide types. Do not reorganize a working small project solely to match a generic directory template.

## 9. Make lifecycle explicit

- Configure dependencies before enabling processing.
- Use `_physics_process` for physics movement and `_process` for presentation not tied to physics.
- Define behavior for pause, scene removal, app backgrounding and restoration.
- Cancel timers, tweens and deferred work when the owner exits.
- Keep save checkpoints at deterministic state boundaries.
- Do not rely on scene deletion order for important persistence.

## 10. Review checklist

- Can each important scene run with a small test harness?
- Can dependencies be seen from exports, initialization or constructor-like setup?
- Does every state value have one authoritative owner?
- Do dependencies point downward and events travel upward?
- Are global systems few, isolated and resettable?
- Are content values authored as typed data rather than embedded in behavior?
- Are scene transitions and pause modes explicit?
- Are performance decisions supported by profiler evidence?
