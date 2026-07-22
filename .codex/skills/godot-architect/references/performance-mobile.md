# Godot Mobile Performance Architecture

## Measurement order

1. Reproduce on a representative physical Android or iPhone device.
2. Record frame time, spikes, active objects, draw calls and memory behavior.
3. Use the standard profiler for script and physics work.
4. Use the visual profiler for CPU/GPU rendering work.
5. Change one suspected bottleneck.
6. Repeat the same capture and compare frame-time percentiles, not only average FPS.

Use a per-frame budget as an engineering constraint: 60 FPS provides about 16.67 ms and 30 FPS about 33.33 ms for all work. Reserve headroom for thermal throttling and OS activity.

## CPU and SceneTree

- Cache stable node references during initialization.
- Do not call `find_child`, broad group scans, or resource loading in frame loops.
- Disable processing on dormant actors with `process_mode` or explicit activation.
- Spread non-urgent AI perception and planning across frames.
- Keep collision layers and masks narrow.
- Use simple collision primitives where accuracy allows.
- Avoid creating temporary arrays, dictionaries and strings inside hot loops.
- Reuse short-lived combat objects only after allocation/free spikes are measured.

Pooling is not automatically faster. A pool must reset signals, timers, animation, collision, visibility, ownership and runtime state. Prefer normal instantiation until the profiler identifies churn or stutter.

## Rendering

- Use the Mobile or Compatibility renderer appropriate to required features and target devices.
- Control overdraw from particles, full-screen translucency and stacked CanvasItems.
- Batch compatible objects and reuse materials/textures.
- Set sensible texture import sizes and compression for mobile memory.
- Avoid large unbounded particle counts; create low/medium/high effect profiles.
- Prewarm shaders or simplify effects when first-use compilation causes stutter.
- Verify performance at the device's real pixel resolution.

## Tilemaps and worlds

- Use multiple TileMapLayer nodes for clear visual, collision, navigation and foreground responsibilities.
- Choose rendering quadrant sizes through measurement, particularly for frequently changing layers.
- Save reused TileSets as external Resources.
- Bake navigation to NavigationRegion2D or use NavigationServer2D when TileMap navigation becomes a quality or performance limit.
- Stream or partition large worlds at stable region boundaries; unload both nodes and referenced resources when memory must be reclaimed.

## Navigation and enemy counts

- Do not repath every enemy every frame.
- Recalculate paths on target movement thresholds, topology changes or staggered intervals.
- Enable RVO avoidance only for actors that currently need it; it has a material cost at scale.
- Separate high-frequency steering from lower-frequency tactical decisions.
- Use an encounter director to cap simultaneous attackers, expensive effects and off-screen simulation.

## Audio and game feel

- Route audio through named buses and cap simultaneous voices for repeated impacts.
- Use sample variation without spawning unbounded AudioStreamPlayer nodes.
- Keep a limiter on the final mix if overlapping effects can clip.
- Scale screen shake and particles by event importance; more feedback is not always clearer.

## Mobile lifecycle

- Test pause/resume, incoming interruptions, orientation lock, low-memory behavior and audio focus.
- Save at safe transitions and before backgrounding when platform callbacks allow.
- Ensure UI respects display cutouts and different aspect ratios.
- Do not assume touch produces the same event stream as mouse input.
- Test multitouch ownership so movement and abilities work simultaneously.
- Measure battery and thermals during sustained combat, not only short editor runs.

## Performance review output

For every optimization report:

- device, OS, build type and renderer;
- exact scenario and duration;
- before/after frame metrics;
- identified bottleneck and evidence;
- change made and quality tradeoff;
- rollback condition if the optimization complicates maintenance.
