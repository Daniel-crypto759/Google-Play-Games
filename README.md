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
wiggling notification icons. After every level a payout breakdown shows
where your gold came from.

### Game modes

- **Levels** — each zone has 5 levels. Most end at a rainbow **multiplier
  staircase** (x1.2 … x5) up to a gold bank; each step costs more bars than
  the last. The bank pays out **30%** of what you carry (times the stairs
  multiplier and your Income upgrade), so gold is earned, not handed out. Every 5th level is a **boss fight**: tap as fast as you can to
  throw your bars at the zone boss (Bandit King, Sand Golem, Frost Yeti,
  Sugar Tyrant) before your tower runs out. Levels are rated 1–3 stars.
- **Daily Challenge** (from level 2) — a special level each day with a twist
  (Speed Rush, Mystery Madness, Trap Gauntlet, Thief Invasion, Golden
  Hour). First clear of the day pays +15 gems and bonus gold.
- **Endless Run** (from level 3) — an infinite, ever-faster track. Gold
  bank arches save 40% of your tower; you earn 0.5 gold per meter plus 30%
  of what you banked. Beat your best distance.

### Gameplay

- **Swipe** left/right to steer, **swipe up** to jump (arrow keys / A-D /
  W or Space on desktop). The first jumpable obstacle triggers a
  slow-motion jump tutorial.
- **Gates** — blue = good, red = bad, **golden gates**, purple **mystery
  "?" gates**, **moving gates** whose panels swap sides, and **Lucky Slot**
  gates whose value keeps cycling — time your pass. Picking the better of
  two gates builds a **Best Pick** streak; every 3rd pick pays a bonus.
- **Bonus goal** — every level rolls one extra objective (take no hits,
  collect N bars, pass N blue gates, reach the finish with N gold, reach x3
  on the stairs, jump N obstacles, trigger Gold Fever, crack a vault). It is
  shown in the HUD; completing it pays +25% gold and 2 gems.
- **Vaults** (from level 3) — a vault door on one lane: pay bars to crack it
  open for 2 gems, a key or a 2.5x jackpot, or find it empty. Arrive with
  too few bars and it stays locked and bounces you away.
- **Falling boulders** (from level 4) — a red ring flashes on a lane, then a
  rock drops in and blocks it. Dodge or jump it.
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
- **Shop** — mystery boxes (Bar Box, Epic Box, Legend Box) that spin a
  reel and land on a gold-bar skin, special offers (Starter Pack, Gold VIP
  for double gold, Box Bundle), gem packs, and gold-for-gems trades. Drop
  rates are always shown next to the boxes, an Epic-or-better is
  guaranteed within 10 boxes, duplicates turn into gems, and the Bar Box is
  free every 6 hours.
- **19 gold-bar skins** in four rarities (Common, Rare, Epic, Legendary),
  including animated ones: Rainbow, Lava, Galaxy, Sunfire, Toxic, plus
  see-through Ice and glowing Neon. Every bar skin also has its own
  **aura** around your tower: sparkles, rising embers and flames, falling
  snowflakes or sprinkles, bubbles, hearts, orbiting stars and shadow mist.
  Rarer skins add a colored glow and a spinning ground ring, Rainbow cycles
  through the colors, and Sunfire shines rotating sun rays. Particles trail
  behind you while you run. The wardrobe and mystery-box cards show each
  aura's name with a small animated preview, and low graphics halves the
  particle count. Some can be bought with gems; the rest
  only come from mystery boxes.
- **Economy** — gold is deliberately scarce: 30% bank payout, Income
  +5% per level, steeper stair costs, and pricier upgrades and cosmetics.
  Missions, achievements, daily rewards, the wheel and the gold mine all pay
  less than before.
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

## In-app purchases (Bar Rush)

Real-money items (`PRODUCTS` in `gold-rush.html`) use Google Play Billing
through [cordova-plugin-purchase](https://github.com/j3k0/cordova-plugin-purchase)
(works with Capacitor). In a normal browser there is no store, so the buy
buttons open a clearly labelled **test checkout** that grants the item for
free and never asks for payment details.

To go live on Google Play:

1. `npm install cordova-plugin-purchase && npx cap sync` in the Capacitor
   project.
2. In the Play Console, create in-app products with exactly these IDs:
   `gems_80`, `gems_500`, `gems_1200`, `gems_3000`, `box_bundle`
   (consumable) and `starter_pack`, `vip_pass` (non-consumable). Set prices
   there — the game shows the store's localized price automatically.
3. Test with a license-tester account before release.
4. For production, verify purchases on a server (the plugin supports a
   validator URL) instead of trusting the device, and move saves off
   `localStorage` so purchases survive a reinstall ("Restore purchases" in
   Settings covers the non-consumables).

Mystery boxes are randomized items that can be bought (indirectly, via
gems) with real money. Google Play requires the odds to be shown before
purchase, which the shop does. Some countries (for example Belgium) restrict
paid loot boxes, so check the rules for each market you publish in.

## Notes / next steps

- Crystal Rush renders with 2D Canvas; Bar Rush renders with Three.js.
  All UI is plain HTML/CSS overlaid on the canvas.
- Swap the Web Audio beeps in each game's `sfx` object for real music/SFX
  files by adding `<audio>` elements gated on `save.music` / `save.sfx`.
- Skin colors/costs live in each file's `SKINS` object near the top of the
  `<script>` — add more there to expand the shop.
- Bar Rush adapts to the device: it lowers its render resolution when
  frames get slow and raises it again when there is headroom, batches
  hills, trees and clouds into a few instanced draw calls, pre-compiles
  shaders before a level starts, and uses frame-rate independent smoothing
  for movement and camera.
- Bar Rush's level tuning (track length, speed, step cost, gate values,
  trap mix) lives in `buildLevel()` and `genGateOpts()`.
