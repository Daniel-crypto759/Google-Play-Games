// Study AI service worker: makes the app installable and lets it open
// offline. Answers always need the network; /api is never cached.
const CACHE = "study-ai-v1";
const SHELL = [
  "./",
  "index.html",
  "styles.css",
  "app.js",
  "i18n.js",
  "manifest.webmanifest",
  "icons/icon.svg",
  "icons/icon-192.png",
  "vendor/marked.umd.js",
  "vendor/purify.min.js",
  "vendor/katex/katex.min.js",
  "vendor/katex/katex.min.css",
];

self.addEventListener("install", (event) => {
  event.waitUntil(caches.open(CACHE).then((cache) => cache.addAll(SHELL)));
  self.skipWaiting();
});

self.addEventListener("activate", (event) => {
  event.waitUntil(
    caches.keys().then((keys) => Promise.all(keys.filter((k) => k !== CACHE).map((k) => caches.delete(k)))),
  );
  self.clients.claim();
});

self.addEventListener("fetch", (event) => {
  const { request } = event;
  const url = new URL(request.url);
  if (request.method !== "GET" || url.pathname.includes("/api/")) return;

  // Stale-while-revalidate for the app shell and the bundled libraries (KaTeX fonts are cached on first use).
  event.respondWith(
    caches.open(CACHE).then(async (cache) => {
      const cached = await cache.match(request, { ignoreSearch: url.origin === location.origin });
      const network = fetch(request)
        .then((res) => {
          if (res.ok || res.type === "opaque") cache.put(request, res.clone());
          return res;
        })
        .catch(() => cached);
      return cached || network;
    }),
  );
});
