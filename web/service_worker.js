/* eslint-disable no-restricted-globals */
const SHELL_CACHE_NAME = 'atgevo-shell-v1';
const CORE_ASSETS = [
  '/',
  'index.html',
  'manifest.json',
  'flutter_bootstrap.js',
];

self.addEventListener('install', (event) => {
  event.waitUntil(
    caches.open(SHELL_CACHE_NAME).then((cache) => cache.addAll(CORE_ASSETS)),
  );
  self.skipWaiting();
});

self.addEventListener('activate', (event) => {
  event.waitUntil(
    caches.keys().then((cacheNames) =>
      Promise.all(
        cacheNames
            .filter((cacheName) => cacheName !== SHELL_CACHE_NAME)
            .map((cacheName) => caches.delete(cacheName)),
      )),
  );
  self.clients.claim();
});

self.addEventListener('fetch', (event) => {
  const {request} = event;
  if (request.method !== 'GET') return;

  event.respondWith(
    caches.match(request).then((cachedResponse) => {
      if (cachedResponse) return cachedResponse;
      return fetch(request).then((networkResponse) => {
        if (!networkResponse || networkResponse.status !== 200) {
          return networkResponse;
        }
        const responseClone = networkResponse.clone();
        caches.open(SHELL_CACHE_NAME)
            .then((cache) => cache.put(request, responseClone));
        return networkResponse;
      });
    }),
  );
});

// Delegate to Flutter's service worker for asset precaching.
try {
  // eslint-disable-next-line no-undef
  importScripts('flutter_service_worker.js');
} catch (error) {
  console.warn('Flutter service worker could not be imported', error);
}
