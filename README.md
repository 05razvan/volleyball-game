# Skyline Volley

Skyline Volley is an original browser-first arcade volleyball game made with
Godot 4.7.2. It focuses on manual movement, court-space aiming, charged jumps,
sets and spikes, stamina-driven saves, and readable local multiplayer.

## Play

The production web build is deployed to GitHub Pages on every push to `main`.

Keyboard and mouse:

- `WASD`: move
- Mouse: aim at the court
- Hold/release `Space`: jump
- Left click: receive on the ground, charge a spike in the air
- Right click: dive on the ground, block in the air
- Hold/release `E`: set
- `Ctrl`: dash
- `Shift`: strafe while facing the aim point
- `Esc`: pause

Player two uses a connected gamepad. Press any gamepad button before joining;
left stick moves, right stick aims, south face jumps, west face receives/spikes,
east face dives/blocks, north face sets, and a shoulder button dashes.

## Development

Install Godot 4.7.2 with export templates, then run:

```sh
godot --editor --path .
```

Run headless checks:

```sh
godot --headless --editor --path . --quit
godot --headless --path . --script res://tests/run_tests.gd
```

Export the browser build:

```sh
mkdir -p build/web
godot --headless --path . --export-release Web build/web/index.html
```

Serve `build/web` through HTTP; browsers will not run the WebAssembly build
directly from `file://`.

