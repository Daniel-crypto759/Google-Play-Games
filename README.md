# Google Play Games

Two self-contained HTML5 games — each a single `.html` file (Canvas +
vanilla JS, no build step, no dependencies), so each opens and plays
directly in any modern browser, desktop or mobile.

## Crystal Rush — `index.html`

A neon sci-fi crystal-mining runner. Swipe between three lanes to steer
into **value gates** (`+N`, `-N`, `x2`, `÷2`) that grow or shrink the
crystal stack you're carrying, dodge laser **barriers**, and get
**harvested** at checkpoint rings that bank your stack into permanent
currency.

- **Main menu** — best distance / crystal balance, Play, Shop, Settings.
- **Gameplay** — 3-lane swipe runner, procedurally-spawned value gates,
  obstacles, crystal pickups, periodic harvester checkpoints, ramping
  speed, pause/resume, results screen with retry.
- **Shop** — 5 alternate player-orb skins.
- **Settings** — music/SFX toggles, progress reset.

## Bar Rush — `gold-rush.html`

A real-3D (Three.js) hyper-casual runner in the look of a "swipe to make
money" game: bright sky, green hills and low-poly trees, a blue-and-white
striped bridge road, a red runner, and translucent blue/red value gates —
reskinned around **gold bars** instead of cash. The runner stands on a
tower of gold bars that grows and shrinks with every choice.

### Gameplay

- **Levels** end at a finish arch and a rainbow **multiplier staircase**
  (x1.2 … x5) leading up to a gold bank. Each step costs more bars than the
  last, so the more you carry, the higher you climb. Rated 1–3 stars; all
  10 steps is a PERFECT bonus. Every 5th level is a bonus level.
- **Zones** — Meadow, Desert, Snow and Candy, switching every 5 levels.
- **Gates** — blue = good, red = bad, plus **golden gates** (big x3 / +N
  rewards), purple **mystery "?" gates** (a gamble), and **moving gates**
  whose panels slide and swap sides.
- **Combo → Gold Fever** — blue gates, pickups, boosts and near misses fill
  the combo bar. When it's full, Gold Fever starts: you run faster, bars
  count double, and you smash through traps.
- **Traps** — spiked walls (some move), swinging hammers and sliding saws.
  Hits knock bars off your tower; running out of gold fails the level.
  Dodging closely gives a "CLOSE!" combo bonus.
- **Pickups** — gold bars, **gems** (often hidden in risky spots), and
  **keys**. **Boost pads** give a speed burst.
- **Revive** for 10 gems once per run.

### Main menu (Home / Upgrades / Skins / Missions)

- **8 upgrades** bought with gold: Start Gold, Income, Magnet, Armor,
  Bubble Shield, Gold Fever duration, Lucky Gates, and a **Gold Mine**
  that earns gold while you're away (8h max).
- **Daily reward** calendar (7-day streak), **Lucky Wheel** (free spin
  every 3 hours, or 5 gems), **Treasure Room** (3 keys open chests with
  gold, gems or a free skin).
- **Daily missions** — 3 per day plus a bonus for finishing all 3.
- **Skins** — 9 runners (gold) and 6 gold-bar styles (gems).
- **Settings** — sound, music, vibration, progress reset.
- Synthesized sound and music (Web Audio), vibration, confetti, fly-to-
  counter coin animations. Progress is saved in `localStorage`.

Three.js (r128) loads from cdnjs, so the game needs an internet
connection the first time; for an offline Play Store build, download
`three.min.js` next to the file and point the `<script src>` at it.

## Play them

Just open the file in a browser — no server or build step required:

```
open index.html            # macOS — Crystal Rush
open gold-rush.html        # macOS — Bar Rush
xdg-open index.html        # Linux
```

or double-click the file / drag it into a browser tab. **Swipe left/right**
(Crystal Rush also has on-screen ◄ ► buttons; both support arrow/A-D keys
on desktop) to steer.

Everything — UI, art, audio — is generated in code; neither game loads
external image or sound assets, so both work offline once opened.

## Project layout

```
index.html        Crystal Rush — markup, styles, and game logic in one file
gold-rush.html     Bar Rush — markup, styles, and game logic in one file
README.md          This file
```

## Publishing to Google Play

A plain web page isn't itself an Android app — Google Play needs an
installable APK/AAB. The straightforward path from either `.html` file to
a Play Store listing is to wrap it as a native shell with
[Capacitor](https://capacitorjs.com/) (repeat per game, each in its own
folder/package id):

```bash
npm init -y
npm install @capacitor/core @capacitor/cli @capacitor/android
npx cap init "Bar Rush" "com.barrush.game" --web-dir .
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

- Crystal Rush renders with 2D Canvas; Bar Rush renders with Three.js.
  All UI is plain HTML/CSS overlaid on the canvas.
- Swap the Web Audio beeps in each game's `sfx` object for real music/SFX
  files by adding `<audio>` elements gated on `save.music` / `save.sfx`.
- Skin colors/costs live in each file's `SKINS` object near the top of the
  `<script>` — add more there to expand the shop.
- Bar Rush's level tuning (track length, speed, step cost, gate values,
  trap mix) lives in `buildLevel()` and `genGateOpts()`.
