# Crystal Rush

A swipe-to-collect endless runner built for Android with [Godot 4](https://godotengine.org/).
You race down a neon alien mining highway, swipe between three lanes to steer
into **value gates** (`+N`, `-N`, `x2`, `÷2`) that grow or shrink the crystal
stack you're carrying, dodge red laser **barriers**, and get **harvested**
at checkpoint rings that bank your current stack into permanent currency.
Bank as much as you can before a barrier ends the run.

This is a from-scratch, differently-themed take on the "swipe to build your
stack, avoid the crash" genre — reskinned as a sci-fi crystal-mining runner
instead of a money run, with its own menu, shop and settings flow.

## Feature overview

- **Main menu** — best distance / crystal balance, Play, Shop, Settings, Quit.
- **Gameplay** — 3-lane swipe runner, procedurally-spawned value gates,
  obstacles, crystal pickups, and periodic "harvester" checkpoints that bank
  your run. Speed ramps up over time for increasing challenge. Pause/resume
  and a results screen with retry are included.
- **Shop** — spend banked crystals on 5 alternate player-orb skins (colors),
  persisted to disk.
- **Settings** — music/SFX toggles and a progress reset, persisted to disk.
- **Save data** — stored locally in `user://crystalrush_save.json` (best
  distance, crystal balance, owned/equipped skins, audio settings).

All gameplay and UI is generated procedurally in code (no external art/audio
assets required), so the project opens and runs immediately with just the
Godot editor — no missing-asset errors.

## Project layout

```
project.godot           Engine + display + Android input configuration
export_presets.cfg      Android (AAB) export preset template
scenes/                 One thin .tscn per screen (MainMenu, Game, Shop, Settings)
scripts/
  SaveManager.gd         Autoload: persistent save/load (Save)
  AudioManager.gd        Autoload: music/SFX bus muting (Audio)
  UIFactory.gd           Shared neon UI theme/widget helpers
  MainMenu.gd            Main menu screen
  Game.gd                Core gameplay (track spawning, input, scoring, HUD)
  Shop.gd                Skin shop
  Settings.gd             Settings screen
assets/icons/icon.svg    App icon
```

## Opening & testing the project

1. Install [Godot 4.3+](https://godotengine.org/download) (standard, non-.NET build).
2. Open Godot → **Import** → select this folder's `project.godot`.
3. Press **F5** (or the Play button) to run. The project boots straight into
   the main menu; touch/mouse-drag to swipe lanes, or use the ← → / A D keys
   when testing on desktop.

## Exporting an Android build for Google Play

1. In Godot, open **Editor → Manage Export Templates** and install the
   templates matching your Godot version (first-time only).
2. Install **Android Studio's command-line tools** (Android SDK + build
   tools) and Java 17, then in Godot go to **Editor → Editor Settings →
   Export → Android** and point Godot at your `Android SDK` path and a
   `debug.keystore` (Godot can generate one for you).
3. Open **Project → Export…**. This repo already ships an `Android` preset
   (`export_presets.cfg`) configured for a `.aab` (Android App Bundle)
   output, which is what Google Play requires:
   - `package/unique_name` is currently `com.crystalrush.runner` — change it
     to your own reverse-domain package id before publishing.
   - For a **Play Store release**, create a real upload keystore
     (`keytool -genkey -v -keystore upload.keystore -alias upload -keyalg RSA
     -keysize 2048 -validity 10000`) and set it under the preset's
     **Release** signing fields (or in Editor Settings) instead of the debug
     keystore — Google Play will reject a debug-signed bundle.
4. Click **Export Project**, choose the `Android` preset, and build. The
   resulting `.aab` goes to `build/android/CrystalRush.aab`.
5. Upload the `.aab` to your app's release track in the
   [Google Play Console](https://play.google.com/console/).

## Notes / next steps

- The whole scene graph (track, gates, obstacles, UI) is built at runtime
  from primitive `CSG*` nodes and `StandardMaterial3D`s, so there's nothing
  to re-import if you tweak colors/values in the scripts.
- Swap in real music/SFX by adding `AudioStreamPlayer` nodes that read
  `Save.music_on` / `Save.sfx_on` (see `AudioManager.gd`) — none are
  bundled since no audio assets were provided.
- `launcher_icons/*` in `export_presets.cfg` point at the bundled SVG icon;
  replace `assets/icons/icon.svg` with your own artwork if you want a
  custom look before publishing.
