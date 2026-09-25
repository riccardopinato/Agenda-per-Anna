import { createClient } from "jsr:@supabase/supabase-js@2";
import webpush from "npm:web-push@3.6.7";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
      "authorization, x-client-info, apikey, content-type",
};

function json(data: unknown, status = 200) {
  return new Response(JSON.stringify(data), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}

function base64UrlBytes(bytes: Uint8Array) {
  let binary = "";
  for (const byte of bytes) binary += String.fromCharCode(byte);
  return btoa(binary)
    .replaceAll("+", "-")
    .replaceAll("/", "_")
    .replaceAll("=", "");
}

function base64UrlJson(value: unknown) {
  return base64UrlBytes(
    new TextEncoder().encode(JSON.stringify(value)),
  );
}

async function importPrivateKey(pem: string) {
  const normalized = pem
    .replace("-----BEGIN PRIVATE KEY-----", "")
    .replace("-----END PRIVATE KEY-----", "")
    .replace(/\s/g, "");
  const binary = atob(normalized);
  const bytes = Uint8Array.from(binary, (char) => char.charCodeAt(0));
  return crypto.subtle.importKey(
    "pkcs8",
    bytes.buffer,
    {
      name: "RSASSA-PKCS1-v1_5",
      hash: "SHA-256",
    },
    false,
    ["sign"],
  );
}

type FirebaseServiceAccount = {
  project_id: string;
  client_email: string;
  private_key: string;
};

async function firebaseAccessToken(serviceAccount: FirebaseServiceAccount) {
  const now = Math.floor(Date.now() / 1000);
  const header = base64UrlJson({ alg: "RS256", typ: "JWT" });
  const payload = base64UrlJson({
    iss: serviceAccount.client_email,
    scope: "https://www.googleapis.com/auth/firebase.messaging",
    aud: "https://oauth2.googleapis.com/token",
    iat: now,
    exp: now + 3600,
  });
  const unsigned = `${header}.${payload}`;
  const key = await importPrivateKey(serviceAccount.private_key);
  const signature = new Uint8Array(
    await crypto.subtle.sign(
      "RSASSA-PKCS1-v1_5",
      key,
      new TextEncoder().encode(unsigned),
    ),
  );
  const assertion = `${unsigned}.${base64UrlBytes(signature)}`;

  const tokenResponse = await fetch(
    "https://oauth2.googleapis.com/token",
    {
      method: "POST",
      headers: {
        "Content-Type": "application/x-www-form-urlencoded",
      },
      body: new URLSearchParams({
        grant_type: "urn:ietf:params:oauth:grant-type:jwt-bearer",
        assertion,
      }),
    },
  );

  if (!tokenResponse.ok) {
    throw new Error(
      `firebase_oauth_${tokenResponse.status}:${await tokenResponse.text()}`,
    );
  }

  const tokenJson = await tokenResponse.json();
  return tokenJson.access_token as string;
}

function loadFirebase(): FirebaseServiceAccount | null {
  const raw = Deno.env.get("FIREBASE_SERVICE_ACCOUNT_JSON");
  if (!raw) return null;
  try {
    const parsed = JSON.parse(raw);
    if (!parsed.project_id || !parsed.client_email || !parsed.private_key) {
      return null;
    }
    return parsed as FirebaseServiceAccount;
  } catch (_) {
    return null;
  }
}


type WebPushConfig = {
  public_key: string;
  private_key: string;
  subject: string;
};

type WebSubscriptionRow = {
  endpoint: string;
  p256dh: string;
  auth: string;
  user_id: string;
};

async function ensureWebPushConfig(admin: any): Promise<WebPushConfig> {
  const { data: existing, error: existingError } = await admin
    .from("web_push_config")
    .select("public_key,private_key,subject")
    .eq("id", "default")
    .maybeSingle();

  if (existingError) {
    throw new Error("web_push_config_lookup_failed");
  }
  if (existing) {
    return existing as WebPushConfig;
  }

  const keyPair = await crypto.subtle.generateKey(
    { name: "ECDSA", namedCurve: "P-256" },
    true,
    ["sign", "verify"],
  ) as CryptoKeyPair;
  const publicRaw = new Uint8Array(
    await crypto.subtle.exportKey("raw", keyPair.publicKey),
  );
  const privateJwk = await crypto.subtle.exportKey(
    "jwk",
    keyPair.privateKey,
  );
  if (!privateJwk.d) {
    throw new Error("web_push_private_key_export_failed");
  }

  const generated = {
    id: "default",
    public_key: base64UrlBytes(publicRaw),
    private_key: privateJwk.d,
    subject: "https://riccardopinato.github.io/Agenda-per-Anna/",
    updated_at: new Date().toISOString(),
  };

  const { data: inserted, error: insertError } = await admin
    .from("web_push_config")
    .insert(generated)
    .select("public_key,private_key,subject")
    .single();

  if (!insertError && inserted) {
    return inserted as WebPushConfig;
  }

  // Two first-time clients may race. If another request inserted the key
  // first, read the canonical row instead of rotating VAPID keys.
  const { data: raced, error: raceError } = await admin
    .from("web_push_config")
    .select("public_key,private_key,subject")
    .eq("id", "default")
    .single();

  if (raceError || !raced) {
    throw new Error("web_push_config_create_failed");
  }
  return raced as WebPushConfig;
}

function classifyWebPushError(error: unknown) {
  const statusCode = Number((error as any)?.statusCode ?? 0);
  if (statusCode > 0) return `web_push_http_${statusCode}`;
  return "web_push_send_exception";
}

async function sendWebPushMessages({
  config,
  subscriptions,
  admin,
  title,
  body,
  data,
}: {
  config: WebPushConfig;
  subscriptions: WebSubscriptionRow[];
  admin: any;
  title: string;
  body: string;
  data: Record<string, string>;
}) {
  if (subscriptions.length === 0) {
    return { delivered: 0, devices: 0, removed: 0, failed: 0 };
  }

  webpush.setVapidDetails(
    config.subject,
    config.public_key,
    config.private_key,
  );

  let delivered = 0;
  let removed = 0;
  let failed = 0;

  for (const subscription of subscriptions) {
    try {
      await webpush.sendNotification(
        {
          endpoint: subscription.endpoint,
          keys: {
            p256dh: subscription.p256dh,
            auth: subscription.auth,
          },
        },
        JSON.stringify({
          title,
          body,
          data,
          url: data.space_id
            ? `./?pushSpace=${encodeURIComponent(data.space_id)}`
            : "./",
        }),
        {
          TTL: 300,
          urgency: "high",
        },
      );
      delivered++;
    } catch (error) {
      const statusCode = Number((error as any)?.statusCode ?? 0);
      if (statusCode === 404 || statusCode === 410) {
        await admin
          .from("web_push_subscriptions")
          .delete()
          .eq("endpoint", subscription.endpoint);
        removed++;
      } else {
        failed++;
      }
    }
  }

  return {
    delivered,
    devices: subscriptions.length,
    removed,
    failed,
  };
}

function combineDeliveryResults(
  fcm: { delivered: number; devices: number; removed: number; failed: number },
  web: { delivered: number; devices: number; removed: number; failed: number },
) {
  return {
    delivered: fcm.delivered + web.delivered,
    devices: fcm.devices + web.devices,
    removed: fcm.removed + web.removed,
    failed: fcm.failed + web.failed,
    fcm_delivered: fcm.delivered,
    fcm_devices: fcm.devices,
    web_delivered: web.delivered,
    web_subscriptions: web.devices,
  };
}

function classifyFirebaseError(error: unknown) {
  const raw = error instanceof Error ? error.message : String(error);
  if (raw.startsWith("firebase_oauth_")) {
    return raw.split(":")[0].slice(0, 80);
  }
  return "firebase_send_exception";
}

function deliveryStatus(result: {
  delivered: number;
  devices: number;
  removed: number;
  failed: number;
}) {
  if (result.devices === 0) return "no_devices";
  if (result.delivered === result.devices) return "delivered";
  if (result.delivered > 0) return "partial";
  return "failed";
}

async function finalizeDeliveryEvent(
  admin: any,
  eventId: string,
  result: {
    delivered: number;
    devices: number;
    removed: number;
    failed: number;
    fcm_delivered?: number;
    fcm_devices?: number;
    web_delivered?: number;
    web_subscriptions?: number;
  },
  error?: string,
) {
  await admin
    .from("push_delivery_events")
    .update({
      device_count: result.devices,
      delivered_count: result.delivered,
      failed_count: result.failed,
      removed_invalid_tokens: result.removed,
      fcm_device_count: result.fcm_devices ?? 0,
      web_subscription_count: result.web_subscriptions ?? 0,
      fcm_delivered_count: result.fcm_delivered ?? 0,
      web_delivered_count: result.web_delivered ?? 0,
      delivery_status: deliveryStatus(result),
      last_error: error ?? null,
      completed_at: new Date().toISOString(),
    })
    .eq("event_id", eventId);
}

async function sendFirebaseMessages({
  firebase,
  devices,
  admin,
  title,
  body,
  data,
}: {
  firebase: FirebaseServiceAccount;
  devices: Array<{ token: string; user_id: string }>;
  admin: any;
  title: string;
  body: string;
  data: Record<string, string>;
}) {
  if (devices.length === 0) {
    return { delivered: 0, devices: 0, removed: 0, failed: 0 };
  }

  const oauthToken = await firebaseAccessToken(firebase);
  const endpoint =
    `https://fcm.googleapis.com/v1/projects/${firebase.project_id}/messages:send`;

  let delivered = 0;
  let removed = 0;
  const failures: number[] = [];

  for (const device of devices) {
    const response = await fetch(endpoint, {
      method: "POST",
      headers: {
        Authorization: `Bearer ${oauthToken}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        message: {
          token: device.token,
          notification: { title, body },
          data,
          android: {
            priority: "high",
            notification: {
              channel_id: "annas_diary_shared_v1",
              icon: "notification_icon",
              color: "#E84A7F",
              sound: "default",
            },
          },
          apns: {
            payload: {
              aps: {
                sound: "default",
                badge: 1,
              },
            },
          },
        },
      }),
    });

    if (response.ok) {
      delivered++;
      continue;
    }

    let errorPayload: any = null;
    try {
      errorPayload = await response.json();
    } catch (_) {}

    const detailCodes = Array.isArray(errorPayload?.error?.details)
      ? errorPayload.error.details.map((item: any) => item?.errorCode)
      : [];
    const unregistered =
      response.status === 404 || detailCodes.includes("UNREGISTERED");

    if (unregistered) {
      await admin.from("push_devices").delete().eq("token", device.token);
      removed++;
    } else {
      failures.push(response.status);
    }
  }

  return {
    delivered,
    devices: devices.length,
    removed,
    failed: failures.length,
  };
}

Deno.serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }
  if (req.method !== "POST") {
    return json({ error: "method_not_allowed" }, 405);
  }

  const authHeader = req.headers.get("Authorization");
  if (!authHeader?.startsWith("Bearer ")) {
    return json({ error: "missing_authorization" }, 401);
  }

  const supabaseUrl = Deno.env.get("SUPABASE_URL") ?? "";
  const publishableKeys = JSON.parse(
    Deno.env.get("SUPABASE_PUBLISHABLE_KEYS") ?? "{}",
  );
  const secretKeys = JSON.parse(
    Deno.env.get("SUPABASE_SECRET_KEYS") ?? "{}",
  );
  const publicKey =
    publishableKeys.default ?? Deno.env.get("SUPABASE_ANON_KEY") ?? "";
  const adminKey =
    secretKeys.default ?? Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";

  if (!supabaseUrl || !publicKey || !adminKey) {
    return json({ error: "supabase_keys_unavailable" }, 500);
  }

  const authClient = createClient(supabaseUrl, publicKey, {
    global: { headers: { Authorization: authHeader } },
    auth: { persistSession: false },
  });
  const admin = createClient(supabaseUrl, adminKey, {
    auth: { persistSession: false },
  });

  const accessJwt = authHeader.substring("Bearer ".length);
  const {
    data: { user },
    error: userError,
  } = await authClient.auth.getUser(accessJwt);

  if (userError || !user) {
    return json({ error: "invalid_session" }, 401);
  }

  let requestBody: Record<string, unknown>;
  try {
    requestBody = await req.json();
  } catch (_) {
    return json({ error: "invalid_json" }, 400);
  }

  const spaceId = String(requestBody.space_id ?? "").trim();
  const eventId = String(requestBody.event_id ?? "").trim();
  const action = String(requestBody.action ?? "updated").trim();
  const entityId = String(requestBody.entity_id ?? "").trim();

  if (action === "web_push_public_key") {
    try {
      const config = await ensureWebPushConfig(admin);
      return json({
        ok: true,
        public_key: config.public_key,
      });
    } catch (error) {
      return json({
        ok: false,
        error: classifyWebPushError(error),
      }, 500);
    }
  }

  if (!eventId) {
    return json({ error: "event_id_required" }, 400);
  }

  const firebase = loadFirebase();

  if (action === "self_test") {
    const { data: ownDevices, error: ownDevicesError } = await admin
      .from("push_devices")
      .select("token,user_id")
      .eq("user_id", user.id);

    if (ownDevicesError) {
      return json({ error: "device_lookup_failed" }, 500);
    }

    const { data: ownWebSubscriptions, error: ownWebError } = await admin
      .from("web_push_subscriptions")
      .select("endpoint,p256dh,auth,user_id")
      .eq("user_id", user.id);

    if (ownWebError) {
      return json({ error: "web_subscription_lookup_failed" }, 500);
    }

    try {
      const title = "Anna's Diary · Test push";
      const body = "Il canale push funziona correttamente ♡";
      const data = {
        kind: "push_self_test",
        event_id: eventId,
      };

      const fcmResult = firebase
        ? await sendFirebaseMessages({
            firebase,
            devices: ownDevices ?? [],
            admin,
            title,
            body,
            data,
          })
        : { delivered: 0, devices: 0, removed: 0, failed: 0 };

      const webConfig = (ownWebSubscriptions ?? []).length > 0
        ? await ensureWebPushConfig(admin)
        : null;
      const webResult = webConfig
        ? await sendWebPushMessages({
            config: webConfig,
            subscriptions: ownWebSubscriptions ?? [],
            admin,
            title,
            body,
            data,
          })
        : { delivered: 0, devices: 0, removed: 0, failed: 0 };

      const result = combineDeliveryResults(fcmResult, webResult);
      return json({
        ok: result.delivered > 0 && result.failed === 0,
        self_test: true,
        delivered: result.delivered,
        devices: result.devices,
        fcm_devices: result.fcm_devices,
        web_subscriptions: result.web_subscriptions,
        fcm_delivered: result.fcm_delivered,
        web_delivered: result.web_delivered,
        removed_invalid_tokens: result.removed,
        failed: result.failed,
        status: deliveryStatus(result),
      });
    } catch (error) {
      const detail = firebase
        ? classifyFirebaseError(error)
        : classifyWebPushError(error);
      return json({
        ok: false,
        self_test: true,
        error: "push_delivery_failed",
        detail,
      }, 502);
    }
  }

  if (!spaceId) {
    return json({ error: "space_id_required" }, 400);
  }

  const { data: members, error: membersError } = await admin
    .from("space_members")
    .select("user_id")
    .eq("space_id", spaceId);

  if (membersError) {
    return json({ error: "membership_lookup_failed" }, 500);
  }

  const memberIds = (members ?? []).map((row) => String(row.user_id));
  if (!memberIds.includes(user.id)) {
    return json({ error: "not_a_space_member" }, 403);
  }

  const recipientIds = memberIds.filter((id) => id !== user.id);
  if (recipientIds.length === 0) {
    return json({ ok: true, delivered: 0 });
  }

  const { error: dedupeError } = await admin
    .from("push_delivery_events")
    .insert({
      event_id: eventId,
      space_id: spaceId,
      sender_user_id: user.id,
    });

  if (dedupeError?.code === "23505") {
    return json({ ok: true, deduplicated: true, delivered: 0 });
  }
  if (dedupeError) {
    return json({ error: "push_dedupe_failed" }, 500);
  }

  const { data: devices, error: devicesError } = await admin
    .from("push_devices")
    .select("token,user_id")
    .in("user_id", recipientIds);

  const { data: webSubscriptions, error: webSubscriptionsError } = await admin
    .from("web_push_subscriptions")
    .select("endpoint,p256dh,auth,user_id")
    .in("user_id", recipientIds);

  if (devicesError || webSubscriptionsError) {
    await admin
      .from("push_delivery_events")
      .update({
        delivery_status: "failed",
        last_error: devicesError
          ? "device_lookup_failed"
          : "web_subscription_lookup_failed",
        completed_at: new Date().toISOString(),
      })
      .eq("event_id", eventId);
    return json({
      error: devicesError
        ? "device_lookup_failed"
        : "web_subscription_lookup_failed",
    }, 500);
  }

  const messageBody =
    action === "comment"
      ? "C’è un nuovo commento in Noi ♡."
      : action === "reaction"
        ? "Hai ricevuto una reazione ❤️ in Noi ♡."
        : action === "photo"
          ? "È stata condivisa una nuova foto in Noi ♡."
          : action === "sketch"
            ? "È stato condiviso un nuovo sketch in Noi ♡."
            : action === "delete"
              ? "Un elemento condiviso è stato aggiornato."
              : "C’è una nuova attività condivisa da leggere.";

  try {
    const title = "Anna's Diary · Noi ♡";
    const data = {
      kind: "shared_update",
      space_id: spaceId,
      event_id: eventId,
      action,
      ...(entityId ? { entity_id: entityId } : {}),
    };

    const fcmResult = firebase
      ? await sendFirebaseMessages({
          firebase,
          devices: devices ?? [],
          admin,
          title,
          body: messageBody,
          data,
        })
      : { delivered: 0, devices: 0, removed: 0, failed: 0 };

    const webConfig = (webSubscriptions ?? []).length > 0
      ? await ensureWebPushConfig(admin)
      : null;
    const webResult = webConfig
      ? await sendWebPushMessages({
          config: webConfig,
          subscriptions: webSubscriptions ?? [],
          admin,
          title,
          body: messageBody,
          data,
        })
      : { delivered: 0, devices: 0, removed: 0, failed: 0 };

    const result = combineDeliveryResults(fcmResult, webResult);
    await finalizeDeliveryEvent(admin, eventId, result);

    return json({
      ok: result.delivered > 0 && result.failed === 0,
      delivered: result.delivered,
      devices: result.devices,
      fcm_devices: result.fcm_devices,
      web_subscriptions: result.web_subscriptions,
      fcm_delivered: result.fcm_delivered,
      web_delivered: result.web_delivered,
      removed_invalid_tokens: result.removed,
      failed: result.failed,
      status: deliveryStatus(result),
    });
  } catch (error) {
    const detail = firebase
      ? classifyFirebaseError(error)
      : classifyWebPushError(error);
    await admin
      .from("push_delivery_events")
      .update({
        delivery_status: "failed",
        last_error: detail,
        completed_at: new Date().toISOString(),
      })
      .eq("event_id", eventId);

    return json({
      ok: false,
      error: "push_delivery_failed",
      detail,
    }, 502);
  }
});
