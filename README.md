# Petal Drift 🌸

A dreamy one-touch mobile game built with Godot 4.

You are a petal adrift in a cosmic world. Tap left or right to steer, release to float upward. Land on glowing flowers to score and bounce higher. Avoid dark clouds. How high can you drift?

## Gameplay

- **Tap left half** of screen → drift left
- **Tap right half** → drift right
- **Release** → float upward gently
- Land on **flowers** → score + combo + bounce
- Avoid **clouds** → they push you down
- Fall below the screen → game over

## Controls

| Action | Input |
|--------|-------|
| Drift Left | Touch left side of screen |
| Drift Right | Touch right side of screen |
| Float | Release touch |
| Restart | Tap after game over |

## Build

### Android APK

This project uses **GitHub Actions** to build the APK in the cloud — no local Godot install needed.

1. Push to `main` branch
2. Go to Actions → "Build Petal Drift APK"
3. Download the artifact when complete

Or trigger manually via **workflow_dispatch**.

### Local testing (optional)

```bash
# Requires Godot 4.3
godot --headless --export-debug "Android" build/petal-drift.apk
```

## Project Structure

```
petal-drift/
├── .github/workflows/build.yml   # CI pipeline
├── assets/icon.svg               # Game icon
├── scenes/
│   ├── main_menu.tscn            # Title screen
│   └── game.tscn                 # Main game scene
├── scripts/
│   ├── game_manager.gd           # Global state, score, persistence
│   ├── game.gd                   # Game controller, spawning
│   ├── main_menu.gd              # Menu logic
│   ├── player.gd                 # Petal movement & collision
│   ├── flower.gd                 # Collectible flowers
│   ├── hazard.gd                 # Dark clouds
│   ├── wind_zone.gd              # Wind currents
│   └── background.gd             # Starfield parallax
├── export_presets.cfg            # Android export config
└── project.godot                 # Project settings
```

## Tech

- **Engine:** Godot 4.3 (GDScript)
- **Platform:** Android (portrait, touch)
- **Art:** All procedural — no external assets
- **CI:** GitHub Actions via chickensoft-games/setup-godot

## License

MIT
