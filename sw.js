var CACHE_NAME = 'corpse-v23';
var LOCAL_URLS = [
  './',
  './index.html',
  './manifest.json',
  './icon.svg',
  './vendor/react.production.min.js',
  './vendor/react-dom.production.min.js',
  './fonts/space-mono.css',
  './fonts/space-mono-400.woff2',
  './fonts/space-mono-700.woff2'
];

self.addEventListener('install', function (e) {
  e.waitUntil(
    caches.open(CACHE_NAME).then(function (cache) {
      return cache.addAll(LOCAL_URLS);
    })
  );
  self.skipWaiting();
});

self.addEventListener('activate', function (e) {
  e.waitUntil(
    caches.keys().then(function (names) {
      return Promise.all(
        // clear our own older caches only; the v2 app under /v2/ keeps its own
        names.filter(function (n) { return n !== CACHE_NAME && n.indexOf('corpse-v2app-') !== 0; })
          .map(function (n) { return caches.delete(n); })
      );
    })
  );
  self.clients.claim();
});

self.addEventListener('fetch', function (e) {
  e.respondWith(
    caches.match(e.request).then(function (cached) {
      if (cached) return cached;
      return fetch(e.request).then(function (response) {
        if (response && response.status === 200 && response.type !== 'opaque') {
          var clone = response.clone();
          caches.open(CACHE_NAME).then(function (cache) {
            cache.put(e.request, clone);
          });
        }
        return response;
      }).catch(function () {
        return caches.match('./index.html');
      });
    })
  );
});
