# Traffic Light Intersection Controller

Implement the following as a single HTML file (`traffic_light.html`). Write production-quality code.

## Requirements

Build an interactive traffic light intersection controller with full state machine logic, visual rendering, and multiple operating modes.

### Intersection Layout

- **Two directions:** North-South (NS) and East-West (EW)
- **Each direction has:**
  - Three vehicle lights: Red, Yellow, Green (drawn as colored circles)
  - One pedestrian signal displaying either "WALK" or "STOP"
- Render the intersection visually so all lights for both directions are visible simultaneously

### Normal Cycle

The default operating cycle repeats continuously:

| Phase | NS State | EW State | Duration |
|-------|----------|----------|----------|
| 1 | Green | Red | 10 seconds |
| 2 | Yellow | Red | 3 seconds |
| 3 | Red | Red | 2 seconds (all-red buffer) |
| 4 | Red | Green | 10 seconds |
| 5 | Red | Yellow | 3 seconds |
| 6 | Red | Red | 2 seconds (all-red buffer) |

Total cycle time: 30 seconds, then repeat from Phase 1.

### Pedestrian Crossing

- Each direction has a clickable **"Request Walk"** button
- Pressing the button schedules a pedestrian walk phase for that direction in the **next** cycle
- Walk phase behavior:
  - The direction with the walk request gets an 8-second "WALK" signal
  - During WALK, the vehicle light for that direction is **Red** (vehicles stop)
  - The opposite direction is also **Red**
  - The walk phase occurs at the beginning of that direction's green phase, replacing the first 8 seconds
  - After the walk phase ends, the pedestrian signal returns to "STOP" and the vehicle light turns Green for the remaining time
- If no button was pressed, no walk phase occurs (pedestrian signal stays "STOP")
- A button press during the current green phase takes effect in the **next** cycle, not the current one

### Emergency Mode

- A toggle button labeled **"Emergency"**
- When activated: **all directions flash Red** (1 second on, 1 second off)
- Normal cycle is suspended
- Pedestrian buttons are ignored during emergency mode
- Toggling off resumes the normal cycle from the beginning (Phase 1)

### Night Mode

- A toggle button labeled **"Night Mode"**
- When activated: **all directions flash Yellow** (1 second on, 1 second off)
- Normal cycle is suspended
- Pedestrian buttons are ignored during night mode
- Toggling off resumes the normal cycle from the beginning (Phase 1)
- Emergency mode takes priority over night mode if both are activated

### Status Display

Show the following information on the page at all times:

- **Current mode:** Normal, Emergency, or Night
- **Current phase:** description of active phase (e.g., "NS Green / EW Red")
- **Elapsed time:** seconds elapsed in the current state
- **Cycle count:** number of complete cycles since start (or since last mode change)

### Code Architecture

- **Separate state machine logic from rendering.** The state machine (transitions, timing, mode switching) must be implemented as standalone functions that can be called and tested independently of the DOM.
- The state machine functions should be exposed on `window` (e.g., `window.TrafficLight`) so external scripts can access them.
- The rendering layer reads state from the state machine and updates the DOM accordingly.

### Exported State Machine API

Expose the following on `window.TrafficLight`:

```javascript
window.TrafficLight = {
  // Returns current state: { mode, phase, nsLight, ewLight, nsPed, ewPed, elapsed, cycle }
  getState(),

  // Advances the state machine by `ms` milliseconds
  tick(ms),

  // Request pedestrian walk for a direction: "NS" or "EW"
  requestWalk(direction),

  // Set mode: "normal", "emergency", "night"
  setMode(mode),

  // Reset to initial state
  reset()
};
```

- `nsLight` / `ewLight`: one of `"red"`, `"yellow"`, `"green"`, `"off"` (for flashing)
- `nsPed` / `ewPed`: one of `"walk"`, `"stop"`, `"off"` (for flashing)
- `phase`: integer (1-6 for normal cycle, 0 for special modes)
- `mode`: `"normal"`, `"emergency"`, `"night"`

### Constraints

- Single HTML file with embedded `<style>` and `<script>` tags
- No external dependencies (no frameworks, no CDN links)
- Must work in any modern browser (Chrome, Firefox, Safari, Edge)
- Use `requestAnimationFrame` or `setInterval` for the real-time timer
- Visual lights must be clearly distinguishable (use saturated colors, dark background for contrast)
