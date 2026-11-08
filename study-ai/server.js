// Study AI server: serves the web app from ./public and streams homework
// solutions from Claude at POST /api/solve. The API key stays on the server.
//
//   ANTHROPIC_API_KEY=sk-ant-... npm start      -> real AI answers
//   npm run demo                                -> canned answers, no key needed
//
// Optional env: PORT (default 3000), STUDY_AI_RATE_LIMIT (requests per IP per
// 10 minutes, default 30).

import http from "node:http";
import fs from "node:fs/promises";
import path from "node:path";
import { fileURLToPath } from "node:url";
import Anthropic from "@anthropic-ai/sdk";

const here = path.dirname(fileURLToPath(import.meta.url));
const PUBLIC_DIR = path.join(here, "public");
const PORT = Number(process.env.PORT) || 3000;
const MOCK = process.env.STUDY_AI_MOCK === "1";
const MODEL = "claude-opus-5-5";
const MAX_BODY_BYTES = 20 * 1024 * 1024; // room for a few compressed photos
const MAX_IMAGES = 4;
const MAX_TURNS = 30;
const RATE_LIMIT = Number(process.env.STUDY_AI_RATE_LIMIT) || 30;
const RATE_WINDOW_MS = 10 * 60 * 1000;

const client = MOCK ? null : new Anthropic();

// ---------------------------------------------------------------- prompting

const LEVELS = {
  primary: "primary / elementary school (ages 6-11): very simple words, short steps, friendly tone",
  middle: "middle school / lower secondary (ages 11-14)",
  high: "high school / upper secondary (ages 14-18), including exam preparation (e.g. SAT, A-levels, Abitur, Bac, Matura)",
  college: "college / university level: rigorous, use correct technical terminology and notation",
};

const SUBJECTS = {
  auto: "Detect the subject yourself",
  math: "Mathematics",
  physics: "Physics",
  chemistry: "Chemistry",
  biology: "Biology",
  cs: "Computer science / programming",
  economics: "Economics / business",
  history: "History / social studies",
  geography: "Geography",
  literature: "Literature, essays and writing",
  languages: "Foreign languages and grammar",
  philosophy: "Philosophy / ethics",
  other: "Other subject",
};

const MODES = {
  solve:
    "SOLVE: Complete every exercise fully. Show a clear worked solution with numbered steps, then the final answer. For writing tasks, write the full text requested.",
  explain:
    "EXPLAIN: Teach the student how to do it. Explain the underlying concept first, then walk through the solution step by step, checking understanding along the way, and finish with the final answer plus one similar practice exercise (with its answer hidden at the end).",
  check:
    "CHECK: The student has attempted the exercise. Check their work line by line, mark what is correct and what is wrong, explain each mistake, and give the corrected final answer.",
};

const LANGUAGE_NAMES = {
  en: "English", de: "German", es: "Spanish", fr: "French", it: "Italian",
  pt: "Portuguese", nl: "Dutch", pl: "Polish", tr: "Turkish", ru: "Russian",
  uk: "Ukrainian", ar: "Arabic", hi: "Hindi", zh: "Simplified Chinese",
  ja: "Japanese", ko: "Korean",
};

function systemPrompt({ level, subject, mode, language }) {
  return `You are Study AI, a homework assistant for school and college students.

Student level: ${LEVELS[level]}.
Subject: ${SUBJECTS[subject]}.
Mode: ${MODES[mode]}

How to answer:
- Write your whole answer in ${LANGUAGE_NAMES[language]}, even if the exercise is in another language. Exception: when the homework itself is a foreign-language exercise (translation, grammar drill, essay in that language), write the exercise answers in the language the task requires and the explanations in ${LANGUAGE_NAMES[language]}.
- Photos may be blurry, rotated or handwritten. Read them carefully. If part of an exercise is unreadable, say exactly which part and solve everything you can read.
- If a page contains several exercises, solve all of them in order and label each one with its number from the sheet (e.g. "Exercise 3b").
- Use Markdown: short headings, numbered steps, tables where useful. Write all math in LaTeX: $...$ inline and $$...$$ for displayed equations. Put code in fenced code blocks.
- Double-check calculations and units before giving the final answer. Mark every final answer clearly with "**Answer:**" (translated into the answer language).
- End with a one-line "Key idea" (translated) that tells the student what to remember for the exam.
- Match the depth and vocabulary to the student level above.`;
}

// ------------------------------------------------------------- validation

const MEDIA_TYPES = new Set(["image/jpeg", "image/png", "image/webp", "image/gif"]);

function validate(body) {
  if (!body || typeof body !== "object") return "Invalid request.";
  const { level, subject, mode, language, messages } = body;
  if (!(level in LEVELS)) return "Unknown level.";
  if (!(subject in SUBJECTS)) return "Unknown subject.";
  if (!(mode in MODES)) return "Unknown mode.";
  if (!(language in LANGUAGE_NAMES)) return "Unknown language.";
  if (!Array.isArray(messages) || messages.length === 0 || messages.length > MAX_TURNS) {
    return "Invalid conversation.";
  }
  let images = 0;
  for (const [i, m] of messages.entries()) {
    const expected = i % 2 === 0 ? "user" : "assistant";
    if (m?.role !== expected) return "Invalid conversation order.";
    if (typeof m.text !== "string" || m.text.length > 20000) return "Message too long.";
    if (m.images !== undefined) {
      if (m.role !== "user" || !Array.isArray(m.images)) return "Invalid images.";
      for (const img of m.images) {
        if (!MEDIA_TYPES.has(img?.mediaType) || typeof img.data !== "string") return "Invalid image.";
        if (!/^[A-Za-z0-9+/=]+$/.test(img.data)) return "Invalid image data.";
        images++;
      }
    }
    if (!m.text.trim() && !(m.images?.length)) return "Empty message.";
  }
  if (images > MAX_IMAGES * 3) return "Too many images.";
  if (messages.at(-1).role !== "user") return "Last message must be from the student.";
  return null;
}

function toApiMessages(messages) {
  return messages.map((m) => {
    if (m.role === "assistant") return { role: "assistant", content: m.text };
    const content = (m.images ?? []).map((img) => ({
      type: "image",
      source: { type: "base64", media_type: img.mediaType, data: img.data },
    }));
    content.push({
      type: "text",
      text: m.text.trim() || "Solve the homework in the photo(s).",
    });
    return { role: "user", content };
  });
}

// ------------------------------------------------------------- rate limit

const hits = new Map();
function rateLimited(ip) {
  const now = Date.now();
  const recent = (hits.get(ip) ?? []).filter((t) => now - t < RATE_WINDOW_MS);
  if (recent.length >= RATE_LIMIT) {
    hits.set(ip, recent);
    return true;
  }
  recent.push(now);
  hits.set(ip, recent);
  return false;
}
setInterval(() => {
  const now = Date.now();
  for (const [ip, times] of hits) {
    if (times.every((t) => now - t >= RATE_WINDOW_MS)) hits.delete(ip);
  }
}, RATE_WINDOW_MS).unref();

// ------------------------------------------------------------------- solve

function sse(res, payload) {
  res.write(`data: ${JSON.stringify(payload)}\n\n`);
}

async function readJson(req) {
  let size = 0;
  const chunks = [];
  for await (const chunk of req) {
    size += chunk.length;
    if (size > MAX_BODY_BYTES) throw Object.assign(new Error("too large"), { status: 413 });
    chunks.push(chunk);
  }
  try {
    return JSON.parse(Buffer.concat(chunks).toString("utf8"));
  } catch {
    throw Object.assign(new Error("bad json"), { status: 400 });
  }
}

async function handleSolve(req, res) {
  const ip = req.socket.remoteAddress ?? "unknown";
  if (rateLimited(ip)) {
    return sendJson(res, 429, { error: "Too many requests. Take a short break and try again in a few minutes." });
  }

  let body;
  try {
    body = await readJson(req);
  } catch (err) {
    const msg = err.status === 413 ? "Photos are too large. Try fewer pages." : "Invalid request.";
    return sendJson(res, err.status ?? 400, { error: msg });
  }
  const problem = validate(body);
  if (problem) return sendJson(res, 400, { error: problem });

  res.writeHead(200, {
    "Content-Type": "text/event-stream; charset=utf-8",
    "Cache-Control": "no-cache, no-transform",
    Connection: "keep-alive",
    "X-Accel-Buffering": "no",
  });

  if (MOCK) return mockSolve(body, res);

  const stream = client.beta.messages.stream({
    model: MODEL,
    max_tokens: 32000,
    // Homework ranges from 2+2 to proofs; "deep" spends more reasoning.
    output_config: { effort: body.deep ? "high" : "medium" },
    system: systemPrompt(body),
    messages: toApiMessages(body.messages),
    // If a safety check declines, let the API retry on a fallback model.
    betas: ["server-side-fallback-2026-07-01"],
    fallbacks: "default",
  });

  // Stop generating (and paying) if the student closes the page.
  res.on("close", () => {
    if (!res.writableEnded) stream.abort();
  });

  try {
    for await (const event of stream) {
      if (event.type === "content_block_delta" && event.delta.type === "text_delta") {
        sse(res, { type: "text", text: event.delta.text });
      }
    }
    const message = await stream.finalMessage();
    if (message.stop_reason === "refusal") {
      sse(res, { type: "error", error: "Study AI can't help with this request." });
    } else if (message.stop_reason === "max_tokens") {
      sse(res, { type: "notice", notice: "truncated" });
    }
    sse(res, { type: "done" });
  } catch (err) {
    if (stream.aborted) return;
    console.error("[solve]", err);
    sse(res, { type: "error", error: describeError(err) });
  }
  res.end();
}

function describeError(err) {
  if (
    err instanceof Anthropic.AuthenticationError ||
    /authentication method/i.test(String(err?.cause?.message ?? err?.message))
  ) {
    return "Server is missing a valid ANTHROPIC_API_KEY.";
  }
  if (err instanceof Anthropic.RateLimitError) {
    return "The AI is busy right now. Please try again in a minute.";
  }
  if (err instanceof Anthropic.BadRequestError) {
    return "The AI couldn't read this request (maybe an image is damaged). Try another photo.";
  }
  if (err instanceof Anthropic.APIConnectionError) {
    return "Couldn't reach the AI service. Check the server's internet connection.";
  }
  if (err instanceof Anthropic.APIError && (err.status ?? 0) >= 500) {
    return "The AI service had a hiccup. Please try again.";
  }
  return "Something went wrong. Please try again.";
}

async function mockSolve(body, res) {
  const lastUser = body.messages.at(-1);
  const pics = lastUser.images?.length ?? 0;
  const text = `## Demo mode

This is a **demo answer** — start the server with an \`ANTHROPIC_API_KEY\` to get real solutions.

You asked in **${LANGUAGE_NAMES[body.language]}**, level **${body.level}**, subject **${body.subject}**, mode **${body.mode}**${pics ? `, with **${pics} photo(s)**` : ""}.

### Example: solve $2x^2 - 8 = 0$

1. Add 8 to both sides: $2x^2 = 8$
2. Divide by 2: $x^2 = 4$
3. Take the square root: $x = \\pm 2$

$$x_{1,2} = \\pm\\sqrt{4} = \\pm 2$$

**Answer:** $x = 2$ or $x = -2$

> **Key idea:** isolate $x^2$ first, then remember that a square root has two signs.`;
  const parts = text.match(/[\s\S]{1,12}/g);
  let closed = false;
  res.on("close", () => (closed = true));
  for (const part of parts) {
    if (closed) return;
    sse(res, { type: "text", text: part });
    await new Promise((r) => setTimeout(r, 15));
  }
  sse(res, { type: "done" });
  res.end();
}

// ------------------------------------------------------------ static files

const MIME = {
  ".html": "text/html; charset=utf-8",
  ".js": "text/javascript; charset=utf-8",
  ".css": "text/css; charset=utf-8",
  ".json": "application/json; charset=utf-8",
  ".webmanifest": "application/manifest+json",
  ".svg": "image/svg+xml",
  ".png": "image/png",
  ".ico": "image/x-icon",
  ".woff2": "font/woff2",
  ".txt": "text/plain; charset=utf-8",
};

function sendJson(res, status, obj) {
  res.writeHead(status, { "Content-Type": "application/json; charset=utf-8" });
  res.end(JSON.stringify(obj));
}

async function serveStatic(req, res) {
  const url = new URL(req.url, "http://localhost");
  let rel = decodeURIComponent(url.pathname);
  if (rel === "/") rel = "/index.html";
  const file = path.normalize(path.join(PUBLIC_DIR, rel));
  if (!file.startsWith(PUBLIC_DIR + path.sep)) {
    res.writeHead(403);
    return res.end();
  }
  try {
    const data = await fs.readFile(file);
    const ext = path.extname(file);
    res.writeHead(200, {
      "Content-Type": MIME[ext] ?? "application/octet-stream",
      "Cache-Control": ext === ".html" || rel === "/sw.js" ? "no-cache" : "public, max-age=3600",
      "X-Content-Type-Options": "nosniff",
    });
    res.end(data);
  } catch {
    res.writeHead(404, { "Content-Type": "text/plain" });
    res.end("Not found");
  }
}

// ------------------------------------------------------------------ server

const server = http.createServer(async (req, res) => {
  try {
    if (req.url === "/api/solve" && req.method === "POST") return await handleSolve(req, res);
    if (req.url === "/api/health") return sendJson(res, 200, { ok: true, mock: MOCK });
    if (req.method === "GET" || req.method === "HEAD") return await serveStatic(req, res);
    res.writeHead(405);
    res.end();
  } catch (err) {
    console.error(err);
    if (!res.headersSent) sendJson(res, 500, { error: "Server error." });
    else res.end();
  }
});

server.listen(PORT, () => {
  console.log(`Study AI running at http://localhost:${PORT}${MOCK ? "  (demo mode: canned answers)" : ""}`);
  if (!MOCK && !process.env.ANTHROPIC_API_KEY) {
    console.warn("Warning: ANTHROPIC_API_KEY is not set. Set it, or run `npm run demo` for demo mode.");
  }
});
