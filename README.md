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

A pseudo-3D canyon-runner in the "swipe to build your stack" style of a
money-stacker game, reskinned as a gold-mining cart run instead of a
money run. The road renders in perspective (converging toward a horizon,
like the reference), the path splits into two branches at each gate —
swipe/steer left or right into the branch with the value you want — and
every 6th checkpoint is a **furnace** that smelts your current bar stack
into permanent nuggets. Stray onto a rockslide obstacle and your cart
wrecks.

- **Main menu** — best distance / nugget balance, Play, Shop, Settings.
- **Gameplay** — perspective road, branching `+N` / `-N` / `x2` / `÷2`
  gates, single-lane rock obstacles, nugget pickups, furnace checkpoints,
  ramping speed, pause/resume, results screen with retry.
- **Shop** — 5 alternate cart/character color skins.
- **Settings** — music/SFX toggles, progress reset.

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

- All rendering is 2D Canvas; all UI is plain HTML/CSS overlaid on the
  canvas — no framework, no external fonts beyond the bundled Google Fonts
  `<link>`.
- Swap the Web Audio beeps in each game's `sfx` object for real music/SFX
  files by adding `<audio>` elements gated on `save.music` / `save.sfx`.
- Skin colors/costs live in each file's `SKINS` object near the top of the
  `<script>` — add more there to expand the shop.
- Bar Rush's perspective/road tuning (`FOV_Z`, `ROAD_HALF_NEAR`,
  `GATE_SPACING`, speeds) lives in the "perspective road" / "game
  constants" sections near the top of its `<script>`.
