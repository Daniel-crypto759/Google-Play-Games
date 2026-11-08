# Study AI

A homework AI for **school and college**, styled in black and neon white. It
runs as a **website** and installs as an **app** (a PWA, a Progressive Web App)
on Android, iPhone, Windows, macOS and ChromeOS. You can also publish it to
Google Play (see below).

## Features

- **Solves homework.** Type or paste an exercise, or photograph it, and get a
  numbered step-by-step solution with a clearly marked final answer and a
  one-line "Key idea" for the exam.
- **Camera scanning.** A live scanner with a neon frame takes up to 4 pages per
  question. Photos are shrunk before upload. You can also pick photos from the
  gallery or paste a screenshot.
- **Built for school and college.** Levels: Primary, Middle school, High school,
  College/Uni. Subjects: math, physics, chemistry, biology, computer science,
  economics, history, geography, literature/essays, foreign languages,
  philosophy, or auto-detect.
- **Three modes:** *Solve* (full solution), *Explain* (teaches the concept and
  adds a practice exercise), *Check my work* (corrects your attempt line by
  line).
- **Deep thinking** switch for hard problems such as proofs and university
  physics.
- **16 languages** for both the interface and the answers: English, Deutsch,
  Español, Français, Italiano, Português, Nederlands, Polski, Türkçe, Русский,
  Українська, العربية (right-to-left), हिन्दी, 中文, 日本語, 한국어. The app picks
  the phone's language on first launch.
- Math formulas (KaTeX), tables and code blocks are rendered properly. You can
  ask follow-up questions, copy answers, and reopen past tasks from the History
  list, which is stored only on the device.

## Run it

You need Node.js 20 or newer.

```bash
cd study-ai
npm install
```

**Demo mode** gives canned answers and needs no key, so you can try the look:

```bash
npm run demo
```

**Real AI answers** need a Claude API key from https://console.anthropic.com:

```bash
ANTHROPIC_API_KEY=sk-ant-... npm start
```

Then open http://localhost:3000.

The key stays on the server. The browser never sees it. Each IP address is
limited to 30 questions per 10 minutes (`STUDY_AI_RATE_LIMIT` changes this),
which protects your API bill. Use `PORT` to pick a different port.

## Put it online (website)

Deploy the `study-ai` folder to any host that runs Node, such as Render,
Railway, Fly.io or a VPS. Start command: `npm start`. Set `ANTHROPIC_API_KEY`
as a secret environment variable. The host must serve the site over
**HTTPS**, or the browser won't allow camera access. (localhost works without
HTTPS.)

## Install it as an app

- **Android / Chrome / Edge:** open the website and tap **Install app** in the
  top bar (or use the browser menu's *Install app* option).
- **iPhone / iPad:** in Safari, tap Share, then *Add to Home Screen*.

## Publish to Google Play

The PWA can be wrapped as a Trusted Web Activity once it is online over HTTPS:

1. Go to https://www.pwabuilder.com, enter your site URL and choose
   **Android**. Or use Google's `bubblewrap` CLI:
   `npx @bubblewrap/cli init --manifest https://YOUR-SITE/manifest.webmanifest`
2. Upload the generated `assetlinks.json` to `public/.well-known/` so the app
   opens without a browser bar.
3. Upload the `.aab` file to the Google Play Console.

## Files

| Path | What it is |
|---|---|
| `server.js` | Node server. Serves the app and streams answers from Claude (`/api/solve`). The prompts live here. |
| `public/index.html`, `styles.css`, `app.js` | The app: UI, camera scanner, answer rendering, history |
| `public/i18n.js` | All interface translations |
| `public/manifest.webmanifest`, `sw.js`, `icons/` | What makes it installable and lets it open offline |
| `public/vendor/` | Bundled marked, DOMPurify and KaTeX, so nothing loads from a CDN |

To add a language, add its strings to `public/i18n.js` and its name to
`LANGUAGE_NAMES` in `server.js`.

AI can make mistakes, so check important answers. The app shows the same
reminder.
