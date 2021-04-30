importScripts("/cache-polyfill.js");

var cacheName = "site-cache";

self.addEventListener("install", function (e) {
  e.waitUntil(
    caches.open(cacheName).then(function (cache) {
      return cache.addAll([
        "/",
        "/booklet.html",
        "/reload/reload.js",
        "/booklet.js",
        "/style.css",
      ]);
    })
  );
});

// Cache any new resources as they are fetched
self.addEventListener("fetch", (event) => {
  event.respondWith(
    (async function () {
      try {
        return await fetch(event.request).then(function (response) {
          var requestToCache = event.request.clone();
          var responseToCache = response.clone();
          caches.open(cacheName).then(function (cache) {
            cache.put(requestToCache, responseToCache);
          });
          return response;
        });
      } catch (err) {
        return caches
          .match(event.request, { ignoreSearch: true })
          .then(function (response) {
            if (response) {
              return response;
            }
          });
      }
    })()
  );
});
