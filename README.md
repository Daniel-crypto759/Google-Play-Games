# Crystal Rush

A swipe-to-collect endless runner, built as a single self-contained
`index.html` (HTML5 Canvas + vanilla JS, no build step, no dependencies).
You race down a neon alien mining highway, swipe between three lanes to
steer into **value gates** (`+N`, `-N`, `x2`, `÷2`) that grow or shrink the
crystal stack you're carrying, dodge red laser **barriers**, and get
**harvested** at checkpoint rings that bank your current stack into
permanent currency. Bank as much as you can before a barrier ends the run.

This is a from-scratch, differently-themed take on the "swipe to build your
stack, avoid the crash" genre — reskinned as a sci-fi crystal-mining runner
instead of a money run, with its own menu, shop and settings flow.

## Play it

Just open `index.html` in any modern browser — desktop or mobile, no
server or build step required:

```
open index.html          # macOS
xdg-open index.html       # Linux
```

or double-click the file / drag it into a browser tab. **Swipe left/right**
(or use the on-screen ◄ ► buttons, or the arrow/A-D keys on desktop) to
change lanes.

## Feature overview

- **Main menu** — best distance / crystal balance, Play, Shop, Settings.
- **Gameplay** — 3-lane swipe runner, procedurally-spawned value gates,
  obstacles, crystal pickups, and periodic "harvester" checkpoints that bank
  your run. Speed ramps up over time for increasing challenge. Pause/resume
  and a results screen with retry are included. Small synthesized sound
  effects (Web Audio, no audio files) for pickups/gates/obstacles.
- **Shop** — spend banked crystals on 5 alternate player-orb skins (colors),
  persisted to the browser.
- **Settings** — music/SFX toggles and a progress reset, persisted to the
  browser.
- **Save data** — stored in `localStorage` (best distance, crystal balance,
  owned/equipped skins, audio settings); per-device/per-browser.

Everything — UI, art, audio — is generated in code; there are no external
image or sound assets to load, so the page works offline once opened.

## Project layout

```
index.html   Everything: markup, styles, and game logic in one file
README.md    This file
```

## Publishing to Google Play

A plain web page isn't itself an Android app — Google Play needs an
installable APK/AAB. The straightforward path from this `index.html` to a
Play Store listing is to wrap it as a native shell with
[Capacitor](https://capacitorjs.com/):

```bash
npm init -y
npm install @capacitor/core @capacitor/cli @capacitor/android
npx cap init "Crystal Rush" "com.crystalrush.runner" --web-dir .
npx cap add android
npx cap sync
npx cap open android   # opens the generated project in Android Studio
```

From Android Studio you can run it on a device/emulator, then
**Build → Generate Signed Bundle/APK** to produce the `.aab` Google Play
requires (create/select an upload keystore there — a debug-signed bundle
will be rejected). Upload the resulting `.aab` in the
[Google Play Console](https://play.google.com/console/).

(An alternative to Capacitor is a Trusted Web Activity if you'd rather host
the page online and wrap the live URL instead of bundling the file.)

## Notes / next steps

- All rendering is 2D Canvas; all UI is plain HTML/CSS overlaid on the
  canvas — no framework, no external fonts beyond the bundled Google Fonts
  `<link>`.
- Swap the Web Audio beeps in the `sfx` object for real music/SFX files by
  adding `<audio>` elements gated on `save.music` / `save.sfx`.
- Skin colors/costs live in the `SKINS` object near the top of the
  `<script>` — add more there to expand the shop.
