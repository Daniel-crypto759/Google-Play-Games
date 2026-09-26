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
striped bridge road, and translucent blue/red value gates — reskinned
around **gold bars** instead of cash. The runner is a cel-shaded cartoon
character with ink outlines, big blinking eyes and expressions (happy,
"ouch" on hits, "wow" in Gold Fever), and stands on a tower of gold bars
that grows and shrinks with every choice. Thieves and bosses share the same
cartoon style. The menu uses a bright sticker look: thick outlines, glossy
buttons with shine sweeps, a bouncing logo with spinning light rays, and
wiggling notification icons.

### Game modes

- **Levels** — each zone has 5 levels. Most end at a rainbow **multiplier
  staircase** (x1.2 … x5) up to a gold bank; each step costs more bars than
  the last. Every 5th level is a **boss fight**: tap as fast as you can to
  throw your bars at the zone boss (Bandit King, Sand Golem, Frost Yeti,
  Sugar Tyrant) before your tower runs out. Levels are rated 1–3 stars.
- **Daily Challenge** (from level 2) — a special level each day with a twist
  (Speed Rush, Mystery Madness, Trap Gauntlet, Thief Invasion, Golden
  Hour). First clear of the day pays +15 gems and bonus gold.
- **Endless Run** (from level 3) — an infinite, ever-faster track. Gold
  bank arches save 30% of your tower; you earn 1 gold per meter plus what
  you banked. Beat your best distance.

### Gameplay

- **Swipe** left/right to steer, **swipe up** to jump (arrow keys / A-D /
  W or Space on desktop). The first jumpable obstacle triggers a
  slow-motion jump tutorial.
- **Gates** — blue = good, red = bad, **golden gates**, purple **mystery
  "?" gates**, **moving gates** whose panels swap sides, and **Lucky Slot**
  gates whose value keeps cycling — time your pass. Picking the better of
  two gates builds a **Best Pick** streak; every 3rd pick pays a bonus.
- **Ramps** launch you through an arc of floating gold bars.
- **Traps** — spiked walls (some move), swinging hammers, sliding saws,
  **hurdles** and **rolling barrels** you can jump, **pits** that make
  you fall and lose bars unless you jump, and spinning **sweeper bars** you
  have to time a jump over.
- **Thieves** — gangs of masked runners that chase you and steal bars.
  Dodge them, jump over them, or knock them flying with a shield or Gold
  Fever.
- **Power-ups** — Magnet (pulls in everything), Double Bars, Bubble Shield.
- **Combo → Gold Fever** — good gates, pickups, jumps and near misses fill
  the combo bar; Gold Fever makes you faster, doubles bars and smashes
  traps.
- **Pickups** — gold bars, gems (often in risky spots), keys; boost pads.
- **Revive** for 10 gems once per run.
- **Zones** — Meadow, Desert, Snow and Candy, switching every 5 levels.

### Main menu (Home / Upgrades / Skins / Missions / Trophies)

- **Home** — level journey map for the current zone (stars earned, boss
  node), Daily Challenge and Endless cards, and quick buttons for the
  daily reward, lucky wheel, gold mine and treasure room. The runner waves
  at you.
- **10 upgrades** — Start Gold, Income, Magnet, Armor, Bubble Shield, Gold
  Fever, Power-Ups, Throw Power (boss damage), Lucky Gates, Gold Mine.
- **Wardrobe** — 9 runner colors, 8 hats (cap, party hat, cowboy, top hat,
  crown, viking helmet, halo) and 6 gold-bar styles. Tap to try an item on
  the 3D runner, tap again to buy.
- **Missions** — 3 daily missions plus an all-clear bonus.
- **Trophies** — lifetime stats and 11 three-tier achievements that pay
  gold and gems.
- **Daily reward** (7-day streak), **Lucky Wheel** (free every 3 hours),
  **Treasure Room** (3 keys open chests; the jackpot is a free skin or hat).
- **Settings** — sound, music, vibration, high/low graphics, reset.
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
