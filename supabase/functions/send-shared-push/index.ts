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

async function firebaseAccessToken(serviceAccount: {
  client_email: string;
  private_key: string;
}) {
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

  let body: Record<string, unknown>;
  try {
    body = await req.json();
  } catch (_) {
    return json({ error: "invalid_json" }, 400);
  }

  const spaceId = String(body.space_id ?? "").trim();
  const eventId = String(body.event_id ?? "").trim();
  const action = String(body.action ?? "updated").trim();

  if (!spaceId || !eventId) {
    return json({ error: "space_id_and_event_id_required" }, 400);
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

  const firebaseRaw = Deno.env.get("FIREBASE_SERVICE_ACCOUNT_JSON");
  if (!firebaseRaw) {
    return json({ error: "firebase_not_configured" }, 503);
  }

  let firebase: {
    project_id: string;
    client_email: string;
    private_key: string;
  };
  try {
    firebase = JSON.parse(firebaseRaw);
  } catch (_) {
    return json({ error: "firebase_secret_invalid" }, 500);
  }

  if (
    !firebase.project_id ||
    !firebase.client_email ||
    !firebase.private_key
  ) {
    return json({ error: "firebase_secret_incomplete" }, 500);
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
    return json({ error: "device_lookup_failed" }, 500);
  }
  if (!devices?.length) {
    return json({ ok: true, delivered: 0, devices: 0 });
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
          notification: {
            title: "Anna's Diary · Noi ♡",
            body:
              action === "delete"
                ? "Un elemento condiviso è stato aggiornato."
                : "C’è una nuova attività condivisa da leggere.",
          },
          data: {
            kind: "shared_update",
            space_id: spaceId,
            event_id: eventId,
          },
          android: {
            priority: "high",
            notification: {
              channel_id: "annas_diary_shared_v1",
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

  return json({
    ok: true,
    delivered,
    devices: devices.length,
    removed_invalid_tokens: removed,
    failed: failures.length,
  });
});
