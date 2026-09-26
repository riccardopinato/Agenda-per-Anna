(() => {
  function isIos() {
    return /iphone|ipad|ipod/i.test(navigator.userAgent || "");
  }

  function installedPwa() {
    return window.matchMedia?.("(display-mode: standalone)")?.matches === true ||
      window.navigator.standalone === true;
  }

  function supported() {
    return window.isSecureContext &&
      "serviceWorker" in navigator &&
      "PushManager" in window &&
      "Notification" in window;
  }

  function applicationServerKey(value) {
    const padding = "=".repeat((4 - value.length % 4) % 4);
    const base64 = (value + padding)
      .replace(/-/g, "+")
      .replace(/_/g, "/");
    const raw = atob(base64);
    return Uint8Array.from(raw, (char) => char.charCodeAt(0));
  }

  async function registration(create) {
    if (!("serviceWorker" in navigator)) return null;

    const dedicatedWorker = "annas-diary-push-sw.js";
    const dedicatedPath = new URL(dedicatedWorker, document.baseURI).pathname;
    let result = await navigator.serviceWorker.getRegistration("./");

    const activePath = result?.active?.scriptURL
      ? new URL(result.active.scriptURL).pathname
      : null;
    const needsMigration = result && activePath !== dedicatedPath;

    if (needsMigration || (!result && create)) {
      try {
        // Reuse the existing registration/scope so an existing PushManager
        // subscription survives the worker-script migration.
        result = await navigator.serviceWorker.register(
          dedicatedWorker,
          { scope: "./", updateViaCache: "none" },
        );
        await navigator.serviceWorker.ready;
      } catch (e) {
        if (create) rethrow;
      }
    }

    if (result) {
      try {
        await result.update();
      } catch (_) {
        // Offline startup must keep working with the installed worker.
      }
    }
    return result;
  }

  async function health() {
    const ok = supported();
    let subscription = null;
    let error = null;

    if (ok) {
      try {
        const reg = await registration(false);
        subscription = reg
          ? await reg.pushManager.getSubscription()
          : null;
      } catch (e) {
        error = String(e);
      }
    }

    return JSON.stringify({
      supported: ok,
      secureContext: window.isSecureContext === true,
      installedPwa: installedPwa(),
      isIos: isIos(),
      permission: "Notification" in window
        ? Notification.permission
        : "unsupported",
      subscription: subscription ? subscription.toJSON() : null,
      error,
    });
  }

  async function subscribe(vapidKey) {
    if (!supported()) {
      return JSON.stringify({
        ok: false,
        error: window.isSecureContext
          ? "web_push_not_supported"
          : "secure_context_required",
      });
    }

    if (isIos() && !installedPwa()) {
      return JSON.stringify({
        ok: false,
        error: "ios_install_to_home_required",
      });
    }

    const permission = await Notification.requestPermission();
    if (permission !== "granted") {
      return JSON.stringify({
        ok: false,
        error: "notification_permission_denied",
      });
    }

    const reg = await registration(true);
    let pushSubscription = await reg.pushManager.getSubscription();
    if (!pushSubscription) {
      pushSubscription = await reg.pushManager.subscribe({
        userVisibleOnly: true,
        applicationServerKey: applicationServerKey(vapidKey),
      });
    }

    return JSON.stringify({
      ok: true,
      subscription: pushSubscription.toJSON(),
    });
  }

  async function unsubscribe() {
    const reg = await registration(false);
    if (!reg) {
      return JSON.stringify({ ok: true, endpoint: null });
    }

    const pushSubscription = await reg.pushManager.getSubscription();
    if (!pushSubscription) {
      return JSON.stringify({ ok: true, endpoint: null });
    }

    const endpoint = pushSubscription.endpoint;
    await pushSubscription.unsubscribe();
    return JSON.stringify({ ok: true, endpoint });
  }

  async function takeInitialSpaceId() {
    const url = new URL(window.location.href);
    const spaceId = url.searchParams.get("pushSpace");
    if (spaceId) {
      url.searchParams.delete("pushSpace");
      window.history.replaceState(null, "", url.toString());
    }
    return JSON.stringify({ spaceId });
  }

  // A newly activated dedicated worker should take control without requiring
  // users to clear site data. Reload once when the controller actually changes.
  if ("serviceWorker" in navigator) {
    let reloadingForUpdate = false;
    navigator.serviceWorker.addEventListener("controllerchange", () => {
      if (reloadingForUpdate) return;
      reloadingForUpdate = true;
      window.location.reload();
    });
  }

  window.annasDiaryWebPush = {
    health,
    subscribe,
    unsubscribe,
    takeInitialSpaceId,
  };
})();
