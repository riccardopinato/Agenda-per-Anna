import { createClient } from "jsr:@supabase/supabase-js@2";

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

  if (!eventId) {
    return json({ error: "event_id_required" }, 400);
  }

  const firebase = loadFirebase();
  if (!firebase) {
    return json({ error: "firebase_not_configured" }, 503);
  }

  if (action === "self_test") {
    const { data: ownDevices, error: ownDevicesError } = await admin
      .from("push_devices")
      .select("token,user_id")
      .eq("user_id", user.id);

    if (ownDevicesError) {
      return json({ error: "device_lookup_failed" }, 500);
    }

    try {
      const result = await sendFirebaseMessages({
        firebase,
        devices: ownDevices ?? [],
        admin,
        title: "Anna's Diary · Test push",
        body: "Il canale Firebase funziona correttamente ♡",
        data: {
          kind: "push_self_test",
          event_id: eventId,
        },
      });

      return json({
        ok: result.delivered > 0 && result.failed === 0,
        self_test: true,
        delivered: result.delivered,
        devices: result.devices,
        removed_invalid_tokens: result.removed,
        failed: result.failed,
        status: deliveryStatus(result),
      });
    } catch (error) {
      return json({
        ok: false,
        self_test: true,
        error: "firebase_delivery_failed",
        detail: classifyFirebaseError(error),
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

  if (devicesError) {
    await admin
      .from("push_delivery_events")
      .update({
        delivery_status: "failed",
        last_error: "device_lookup_failed",
        completed_at: new Date().toISOString(),
      })
      .eq("event_id", eventId);
    return json({ error: "device_lookup_failed" }, 500);
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
    const result = await sendFirebaseMessages({
      firebase,
      devices: devices ?? [],
      admin,
      title: "Anna's Diary · Noi ♡",
      body: messageBody,
      data: {
        kind: "shared_update",
        space_id: spaceId,
        event_id: eventId,
        action,
        ...(entityId ? { entity_id: entityId } : {}),
      },
    });

    await finalizeDeliveryEvent(admin, eventId, result);

    return json({
      ok: result.delivered > 0 && result.failed === 0,
      delivered: result.delivered,
      devices: result.devices,
      removed_invalid_tokens: result.removed,
      failed: result.failed,
      status: deliveryStatus(result),
    });
  } catch (error) {
    const detail = classifyFirebaseError(error);
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
      error: "firebase_delivery_failed",
      detail,
    }, 502);
  }
});
