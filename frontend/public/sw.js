importScripts("/cache-polyfill.js");

self.addEventListener("install", function (e) {
  e.waitUntil(
    caches.open("booklet").then(function (cache) {
      return cache.addAll([
        "/",
        "/booklet.html",
        "/?concertSlot=may1",
        "/reload/reload.js",
        "/booklet.js",
        "/style.css",
        "assets/OMM_Info_booklet.pdf",
        "assets/Mahler_Mobile.pdf",
        "fonts/Proxima%20Nova%20Regular.otf",
      ]);
    })
  );
});

self.addEventListener("fetch", function (event) {
  console.log(event.request.url);

  event.respondWith(
    caches.match(event.request).then(function (response) {
      return response || fetch(event.request);
    })
  );
});
