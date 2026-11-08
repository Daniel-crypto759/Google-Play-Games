import { LANGUAGES, RTL, STRINGS, detectLanguage } from "./i18n.js";

const $ = (id) => document.getElementById(id);
const MAX_PAGES = 4;
const MAX_HISTORY = 40;
const PREFS_KEY = "studyai.prefs";
const HISTORY_KEY = "studyai.history";

// ------------------------------------------------------------------ storage

function load(key, fallback) {
  try {
    const raw = localStorage.getItem(key);
    return raw ? JSON.parse(raw) : fallback;
  } catch {
    return fallback;
  }
}
function save(key, value) {
  try {
    localStorage.setItem(key, JSON.stringify(value));
  } catch {
    /* storage full or blocked: the app still works without it */
  }
}

// -------------------------------------------------------------------- state

const prefs = Object.assign(
  { lang: detectLanguage(), level: "high", subject: "auto", mode: "solve", deep: false },
  load(PREFS_KEY, {}),
);
if (!(prefs.lang in STRINGS)) prefs.lang = "en";

const state = {
  composerImages: [], // [{mediaType, data, preview}]
  followupImages: [],
  conversation: [], // [{role, text, images?}]
  historyId: null,
  controller: null,
  cameraTarget: "composer",
};

const t = (key) => STRINGS[prefs.lang][key] ?? STRINGS.en[key] ?? key;

// --------------------------------------------------------------------- i18n

function applyLanguage() {
  const html = document.documentElement;
  html.lang = prefs.lang;
  html.dir = RTL.has(prefs.lang) ? "rtl" : "ltr";
  document.querySelectorAll("[data-i18n]").forEach((el) => (el.textContent = t(el.dataset.i18n)));
  document.querySelectorAll("[data-i18n-placeholder]").forEach((el) => (el.placeholder = t(el.dataset.i18nPlaceholder)));
  document.querySelectorAll("[data-i18n-title]").forEach((el) => {
    el.title = t(el.dataset.i18nTitle);
    el.setAttribute("aria-label", t(el.dataset.i18nTitle));
  });
  document.querySelectorAll("[data-i18n-aria]").forEach((el) => el.setAttribute("aria-label", t(el.dataset.i18nAria)));
  renderHistory();
}

const langSelect = $("langSelect");
for (const [code, name] of Object.entries(LANGUAGES)) {
  langSelect.add(new Option(name, code));
}
langSelect.value = prefs.lang;
langSelect.addEventListener("change", () => {
  prefs.lang = langSelect.value;
  save(PREFS_KEY, prefs);
  applyLanguage();
});

// ------------------------------------------------------------ option inputs

function setupSegmented(el, key) {
  const buttons = [...el.querySelectorAll("button")];
  const sync = () => buttons.forEach((b) => b.setAttribute("aria-checked", String(b.dataset.value === prefs[key])));
  buttons.forEach((b) =>
    b.addEventListener("click", () => {
      prefs[key] = b.dataset.value;
      save(PREFS_KEY, prefs);
      sync();
    }),
  );
  sync();
}
setupSegmented($("levelSeg"), "level");
setupSegmented($("modeSeg"), "mode");

const subjectSelect = $("subjectSelect");
subjectSelect.value = prefs.subject;
subjectSelect.addEventListener("change", () => {
  prefs.subject = subjectSelect.value;
  save(PREFS_KEY, prefs);
});

const deepToggle = $("deepToggle");
deepToggle.checked = prefs.deep;
deepToggle.addEventListener("change", () => {
  prefs.deep = deepToggle.checked;
  save(PREFS_KEY, prefs);
});

// ------------------------------------------------------------------- toast

let toastTimer;
function toast(message) {
  const el = $("toast");
  el.textContent = message;
  el.classList.remove("hidden");
  clearTimeout(toastTimer);
  toastTimer = setTimeout(() => el.classList.add("hidden"), 3200);
}

// ------------------------------------------------------------------ images

// Shrink photos before upload: faster, cheaper, and still sharp enough to read.
async function compressImage(source, maxSide = 1800) {
  let width, height, drawable;
  if (source instanceof Blob) {
    drawable = await createImageBitmap(source, { imageOrientation: "from-image" }).catch(async () => {
      const url = URL.createObjectURL(source);
      const img = new Image();
      img.src = url;
      await img.decode();
      URL.revokeObjectURL(url);
      return img;
    });
    width = drawable.width;
    height = drawable.height;
  } else {
    drawable = source; // <video>
    width = source.videoWidth;
    height = source.videoHeight;
  }
  const scale = Math.min(1, maxSide / Math.max(width, height));
  const canvas = document.createElement("canvas");
  canvas.width = Math.round(width * scale);
  canvas.height = Math.round(height * scale);
  canvas.getContext("2d").drawImage(drawable, 0, 0, canvas.width, canvas.height);
  const dataUrl = canvas.toDataURL("image/jpeg", 0.85);
  return { mediaType: "image/jpeg", data: dataUrl.split(",")[1], preview: dataUrl };
}

function imagesFor(target) {
  return target === "composer" ? state.composerImages : state.followupImages;
}

async function addFiles(files, target) {
  const list = imagesFor(target);
  for (const file of files) {
    if (!file.type.startsWith("image/")) continue;
    if (list.length >= MAX_PAGES) {
      toast(t("pagesHint"));
      break;
    }
    try {
      list.push(await compressImage(file));
    } catch {
      toast(t("cameraError"));
    }
  }
  renderThumbs(target);
}

function renderThumbs(target) {
  const el = target === "composer" ? $("thumbs") : $("followupThumbs");
  const list = imagesFor(target);
  el.replaceChildren(
    ...list.map((img, i) => {
      const wrap = document.createElement("div");
      wrap.className = "thumb";
      const image = document.createElement("img");
      image.src = img.preview;
      image.alt = "";
      const remove = document.createElement("button");
      remove.type = "button";
      remove.setAttribute("aria-label", t("close"));
      remove.innerHTML = '<svg viewBox="0 0 24 24"><path d="M6 6l12 12M18 6 6 18"/></svg>';
      remove.addEventListener("click", () => {
        list.splice(i, 1);
        renderThumbs(target);
      });
      wrap.append(image, remove);
      return wrap;
    }),
  );
  if (target === "followup") el.classList.toggle("hidden", list.length === 0);
}

const fileInput = $("fileInput");
fileInput.addEventListener("change", async () => {
  await addFiles([...fileInput.files], "composer");
  fileInput.value = "";
});

// Paste a screenshot straight into the text box.
document.addEventListener("paste", (e) => {
  const files = [...(e.clipboardData?.files ?? [])].filter((f) => f.type.startsWith("image/"));
  if (!files.length) return;
  e.preventDefault();
  addFiles(files, state.conversation.length ? "followup" : "composer");
});

// ------------------------------------------------------------------ camera

const camera = {
  stream: null,
  facing: "environment",
  el: $("camera"),
  video: $("cameraVideo"),
};

// Fallback when live camera access isn't possible (e.g. plain http): the
// OS camera picker via a capture input.
const captureInput = document.createElement("input");
captureInput.type = "file";
captureInput.accept = "image/*";
captureInput.capture = "environment";
captureInput.addEventListener("change", async () => {
  await addFiles([...captureInput.files], state.cameraTarget);
  captureInput.value = "";
});

async function openCamera(target) {
  state.cameraTarget = target;
  if (!navigator.mediaDevices?.getUserMedia) {
    captureInput.click();
    return;
  }
  try {
    await startStream();
    camera.el.classList.remove("hidden");
    updateCameraCount();
  } catch {
    captureInput.click();
  }
}

async function startStream() {
  stopStream();
  camera.stream = await navigator.mediaDevices.getUserMedia({
    video: { facingMode: { ideal: camera.facing }, width: { ideal: 2560 }, height: { ideal: 1440 } },
    audio: false,
  });
  camera.video.srcObject = camera.stream;
  await camera.video.play().catch(() => {});
}

function stopStream() {
  camera.stream?.getTracks().forEach((track) => track.stop());
  camera.stream = null;
}

function closeCamera() {
  stopStream();
  camera.el.classList.add("hidden");
}

function updateCameraCount() {
  $("cameraCount").textContent = `${imagesFor(state.cameraTarget).length} / ${MAX_PAGES}`;
}

$("scanBtn").addEventListener("click", () => openCamera("composer"));
$("followupPhotoBtn").addEventListener("click", () => openCamera("followup"));
$("cameraClose").addEventListener("click", closeCamera);
$("cameraDone").addEventListener("click", closeCamera);
$("cameraFlip").addEventListener("click", async () => {
  camera.facing = camera.facing === "environment" ? "user" : "environment";
  try {
    await startStream();
  } catch {
    toast(t("cameraError"));
  }
});
$("cameraShutter").addEventListener("click", async () => {
  const list = imagesFor(state.cameraTarget);
  if (list.length >= MAX_PAGES) return toast(t("pagesHint"));
  if (!camera.video.videoWidth) return;
  list.push(await compressImage(camera.video));
  const flash = document.createElement("div");
  flash.className = "flash";
  camera.el.append(flash);
  setTimeout(() => flash.remove(), 400);
  navigator.vibrate?.(30);
  renderThumbs(state.cameraTarget);
  updateCameraCount();
  if (list.length >= MAX_PAGES) setTimeout(closeCamera, 300);
});
document.addEventListener("keydown", (e) => {
  if (e.key === "Escape" && !camera.el.classList.contains("hidden")) closeCamera();
});

// ---------------------------------------------------------------- markdown

const libsLoaded = typeof marked !== "undefined" && typeof DOMPurify !== "undefined" && typeof katex !== "undefined";
if (libsLoaded) marked.setOptions({ gfm: true, breaks: false });

// Math is pulled out before Markdown parsing (so `_` and `*` inside formulas
// survive), rendered with KaTeX, and put back after sanitizing.
function renderMarkdown(src) {
  if (!libsLoaded) return `<p style="white-space:pre-wrap">${escapeHtml(src)}</p>`;
  const code = [];
  const math = [];
  let text = src.replace(/```[\s\S]*?(?:```|$)|`[^`\n]+`/g, (m) => {
    code.push(m);
    return `\u0000C${code.length - 1}\u0000`;
  });
  const stashMath = (tex, display) => {
    math.push({ tex, display });
    return `MATHPH${math.length - 1}XEND`;
  };
  text = text
    .replace(/\$\$([\s\S]+?)\$\$/g, (_, tex) => stashMath(tex, true))
    .replace(/\\\[([\s\S]+?)\\\]/g, (_, tex) => stashMath(tex, true))
    .replace(/\\\(([\s\S]+?)\\\)/g, (_, tex) => stashMath(tex, false))
    .replace(/\$(?![\s$])([^\n$]+?)(?<!\s)\$(?!\d)/g, (_, tex) => stashMath(tex, false));
  text = text.replace(/\u0000C(\d+)\u0000/g, (_, i) => code[i]);

  let html = DOMPurify.sanitize(marked.parse(text));
  html = html.replace(/MATHPH(\d+)XEND/g, (_, i) => {
    const { tex, display } = math[i];
    try {
      return katex.renderToString(tex, { displayMode: display, throwOnError: false, output: "html" });
    } catch {
      return escapeHtml(tex);
    }
  });
  return html;
}

function escapeHtml(s) {
  return s.replace(/[&<>"']/g, (c) => ({ "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;", "'": "&#39;" })[c]);
}

// ------------------------------------------------------------------ thread

const thread = $("thread");

function showThreadView(on) {
  $("hero").classList.toggle("hidden", on);
  $("composer").classList.toggle("hidden", on);
  thread.classList.toggle("hidden", !on);
  $("followupForm").classList.toggle("hidden", !on);
  $("newTaskWrap").classList.toggle("hidden", !on);
  if (!on) $("followupThumbs").classList.add("hidden");
}

function addUserBubble(message) {
  const el = document.createElement("div");
  el.className = "msg msg-user";
  if (message.images?.length) {
    const imgs = document.createElement("div");
    imgs.className = "msg-images";
    for (const img of message.images) {
      const i = document.createElement("img");
      i.src = img.preview ?? `data:${img.mediaType};base64,${img.data}`;
      i.alt = "";
      imgs.append(i);
    }
    el.append(imgs);
  }
  if (message.text) {
    const p = document.createElement("div");
    p.className = "msg-text";
    p.textContent = message.text;
    el.append(p);
  }
  thread.append(el);
}

function addAiBubble(text = "") {
  const el = document.createElement("div");
  el.className = "msg msg-ai";
  const body = document.createElement("div");
  body.className = "md";
  el.append(body);
  thread.append(el);
  if (text) {
    body.innerHTML = renderMarkdown(text);
    addAiTools(el, text);
  }
  return { el, body };
}

function addAiTools(el, text) {
  const tools = document.createElement("div");
  tools.className = "msg-tools";
  const copy = document.createElement("button");
  copy.type = "button";
  copy.className = "ghost-btn";
  copy.textContent = t("copy");
  copy.addEventListener("click", async () => {
    try {
      await navigator.clipboard.writeText(text);
      copy.textContent = t("copied");
      setTimeout(() => (copy.textContent = t("copy")), 1500);
    } catch {
      /* clipboard blocked */
    }
  });
  tools.append(copy);
  el.append(tools);
}

function workingIndicator() {
  const w = document.createElement("div");
  w.className = "working";
  w.innerHTML = '<span class="dots"><i></i><i></i><i></i></span>';
  w.append(document.createTextNode(t("working")));
  return w;
}

// ------------------------------------------------------------------- solve

async function send(text, images) {
  if (state.controller) return;
  const userMsg = { role: "user", text: text.trim(), images: images.length ? images : undefined };
  if (!userMsg.text && !userMsg.images) {
    toast(t("needInput"));
    return;
  }
  state.conversation.push(userMsg);
  showThreadView(true);
  addUserBubble(userMsg);

  const { el, body } = addAiBubble();
  el.classList.add("streaming");
  body.append(workingIndicator());
  const stopBtn = document.createElement("button");
  stopBtn.type = "button";
  stopBtn.className = "ghost-btn";
  stopBtn.textContent = t("stop");
  const stopTools = document.createElement("div");
  stopTools.className = "msg-tools";
  stopTools.append(stopBtn);
  el.append(stopTools);
  el.scrollIntoView({ behavior: "smooth", block: "start" });
  setBusy(true);

  const controller = new AbortController();
  state.controller = controller;
  stopBtn.addEventListener("click", () => controller.abort());

  let answer = "";
  let notice = null;
  let error = null;
  let scheduled = false;
  const paint = () => {
    scheduled = false;
    body.innerHTML = renderMarkdown(answer);
  };

  try {
    const res = await fetch("api/solve", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      signal: controller.signal,
      body: JSON.stringify({
        level: prefs.level,
        subject: prefs.subject,
        mode: prefs.mode,
        language: prefs.lang,
        deep: prefs.deep,
        messages: state.conversation.map((m) => ({
          role: m.role,
          text: m.text,
          images: m.images?.map(({ mediaType, data }) => ({ mediaType, data })),
        })),
      }),
    });
    if (!res.ok || !res.body) {
      const data = await res.json().catch(() => ({}));
      throw new Error(data.error || t("netError"));
    }
    const reader = res.body.pipeThrough(new TextDecoderStream()).getReader();
    let buffer = "";
    for (;;) {
      const { value, done } = await reader.read();
      if (done) break;
      buffer += value;
      let idx;
      while ((idx = buffer.indexOf("\n\n")) >= 0) {
        const line = buffer.slice(0, idx).trim();
        buffer = buffer.slice(idx + 2);
        if (!line.startsWith("data:")) continue;
        const evt = JSON.parse(line.slice(5));
        if (evt.type === "text") {
          answer += evt.text;
          if (!scheduled) {
            scheduled = true;
            requestAnimationFrame(paint);
          }
        } else if (evt.type === "notice" && evt.notice === "truncated") {
          notice = t("truncated");
        } else if (evt.type === "error") {
          error = evt.error;
        }
      }
    }
  } catch (err) {
    if (err.name !== "AbortError") error = err.message === "Failed to fetch" ? t("netError") : err.message || t("netError");
  }

  state.controller = null;
  setBusy(false);
  stopTools.remove();
  el.classList.remove("streaming");
  paint();

  if (answer) {
    state.conversation.push({ role: "assistant", text: answer });
    addAiTools(el, answer);
    saveToHistory();
  } else {
    // Nothing came back: drop the unanswered question so it can be retried.
    state.conversation.pop();
    if (!error) el.remove();
  }
  if (error || notice) {
    const n = document.createElement("div");
    n.className = "notice" + (error ? " error-text" : "");
    n.textContent = error || notice;
    (answer ? el : body).append(n);
  }
}

function setBusy(busy) {
  $("solveBtn").disabled = busy;
  $("followupSend").disabled = busy;
}

$("solveBtn").addEventListener("click", async () => {
  if (state.controller) return;
  const input = $("taskInput");
  const images = state.composerImages.splice(0);
  const text = input.value;
  if (!text.trim() && !images.length) return toast(t("needInput"));
  input.value = "";
  renderThumbs("composer");
  state.historyId = null;
  await send(text, images);
});

$("taskInput").addEventListener("keydown", (e) => {
  if (e.key === "Enter" && (e.ctrlKey || e.metaKey)) $("solveBtn").click();
});

const followupInput = $("followupInput");
followupInput.addEventListener("input", () => {
  followupInput.style.height = "auto";
  followupInput.style.height = Math.min(followupInput.scrollHeight, 160) + "px";
});
followupInput.addEventListener("keydown", (e) => {
  if (e.key === "Enter" && !e.shiftKey && !e.isComposing) {
    e.preventDefault();
    $("followupForm").requestSubmit();
  }
});
$("followupForm").addEventListener("submit", async (e) => {
  e.preventDefault();
  if (state.controller) return; // still answering; keep what was typed
  const text = followupInput.value;
  const images = state.followupImages.splice(0);
  if (!text.trim() && !images.length) return;
  followupInput.value = "";
  followupInput.style.height = "auto";
  renderThumbs("followup");
  await send(text, images);
});

function newTask() {
  state.controller?.abort();
  state.conversation = [];
  state.historyId = null;
  state.followupImages = [];
  thread.replaceChildren();
  showThreadView(false);
  window.scrollTo({ top: 0, behavior: "smooth" });
  $("taskInput").focus();
}
$("newTaskBtn").addEventListener("click", newTask);

// ----------------------------------------------------------------- history

function saveToHistory() {
  const history = load(HISTORY_KEY, []);
  const first = state.conversation[0];
  const entry = {
    id: state.historyId ?? (crypto.randomUUID?.() ?? String(Date.now())),
    title: first.text ? first.text.slice(0, 80) : null,
    ts: Date.now(),
    subject: prefs.subject,
    level: prefs.level,
    // Photos are not stored (too large); a placeholder keeps the turn valid.
    messages: state.conversation.map((m) => ({
      role: m.role,
      text: m.text || (m.images?.length ? `[${m.images.length} 📷]` : ""),
    })),
  };
  state.historyId = entry.id;
  const next = [entry, ...history.filter((h) => h.id !== entry.id)].slice(0, MAX_HISTORY);
  save(HISTORY_KEY, next);
  renderHistory();
}

function renderHistory() {
  const list = $("historyList");
  const history = load(HISTORY_KEY, []);
  if (!history.length) {
    const li = document.createElement("li");
    li.className = "history-empty";
    li.textContent = t("noHistory");
    list.replaceChildren(li);
    return;
  }
  const fmt = new Intl.DateTimeFormat(prefs.lang, { dateStyle: "medium", timeStyle: "short" });
  list.replaceChildren(
    ...history.map((h) => {
      const li = document.createElement("li");
      const b = document.createElement("button");
      b.type = "button";
      const title = document.createElement("span");
      title.className = "history-title";
      title.textContent = h.title || t("photoTask");
      const meta = document.createElement("span");
      meta.className = "history-meta";
      meta.textContent = `${t(h.subject === "history" ? "historySubj" : h.subject)} · ${t(h.level)} · ${fmt.format(h.ts)}`;
      b.append(title, meta);
      b.addEventListener("click", () => openHistory(h));
      li.append(b);
      return li;
    }),
  );
}

function openHistory(entry) {
  state.controller?.abort();
  state.conversation = entry.messages.map((m) => ({ ...m }));
  state.historyId = entry.id;
  thread.replaceChildren();
  for (const m of state.conversation) {
    if (m.role === "user") addUserBubble(m);
    else addAiBubble(m.text);
  }
  showThreadView(true);
  closeDrawer();
  window.scrollTo({ top: 0 });
}

const drawer = $("drawer");
function openDrawer() {
  renderHistory();
  drawer.classList.add("open");
  drawer.setAttribute("aria-hidden", "false");
  $("scrim").classList.remove("hidden");
}
function closeDrawer() {
  drawer.classList.remove("open");
  drawer.setAttribute("aria-hidden", "true");
  $("scrim").classList.add("hidden");
}
$("historyBtn").addEventListener("click", openDrawer);
$("drawerClose").addEventListener("click", closeDrawer);
$("scrim").addEventListener("click", closeDrawer);
$("clearHistoryBtn").addEventListener("click", () => {
  save(HISTORY_KEY, []);
  renderHistory();
});

// ------------------------------------------------------------- install/PWA

let installEvent = null;
window.addEventListener("beforeinstallprompt", (e) => {
  e.preventDefault();
  installEvent = e;
  $("installBtn").classList.remove("hidden");
});
$("installBtn").addEventListener("click", async () => {
  if (!installEvent) return;
  installEvent.prompt();
  await installEvent.userChoice.catch(() => {});
  installEvent = null;
  $("installBtn").classList.add("hidden");
});
window.addEventListener("appinstalled", () => $("installBtn").classList.add("hidden"));

if ("serviceWorker" in navigator) {
  window.addEventListener("load", () => navigator.serviceWorker.register("sw.js").catch(() => {}));
}

// Android share target / deep link: ?q=... prefills the exercise.
const q = new URLSearchParams(location.search).get("q");
if (q) $("taskInput").value = q;

applyLanguage();
