self.addEventListener("push", (event) => {
  let payload = {};
  try {
    payload = event.data ? event.data.json() : {};
  } catch (_) {
    payload = {
      title: "Anna's Diary",
      body: event.data ? event.data.text() : "Nuovo aggiornamento",
      data: {},
    };
  }

  const title = payload.title || "Anna's Diary";
  const body = payload.body || "Hai un nuovo aggiornamento.";
  const data = payload.data || {};
  const url = payload.url ||
    (data.space_id
      ? "./?pushSpace=" + encodeURIComponent(data.space_id)
      : "./");

  event.waitUntil(
    self.registration.showNotification(title, {
      body,
      icon: "icons/Icon-192.png",
      badge: "icons/Icon-192.png",
      tag: data.event_id || "annas-diary-push",
      renotify: Boolean(data.event_id),
      data: { ...data, url },
    }),
  );
});

self.addEventListener("notificationclick", (event) => {
  event.notification.close();
  const relative = event.notification.data?.url || "./";
  const targetUrl = new URL(relative, self.registration.scope).href;

  event.waitUntil((async () => {
    const windows = await self.clients.matchAll({
      type: "window",
      includeUncontrolled: true,
    });

    if (windows.length > 0) {
      const client = windows[0];
      if ("navigate" in client) {
        await client.navigate(targetUrl);
      }
      await client.focus();
      return;
    }

    await self.clients.openWindow(targetUrl);
  })());
});
