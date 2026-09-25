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

function envJson(name: string): Record<string, string> {
  try {
    return JSON.parse(Deno.env.get(name) ?? "{}");
  } catch (_) {
    return {};
  }
}

function collectMediaPaths(value: unknown, output: Set<string>) {
  if (Array.isArray(value)) {
    for (const item of value) collectMediaPaths(item, output);
    return;
  }
  if (!value || typeof value !== "object") return;

  for (const [key, raw] of Object.entries(value as Record<string, unknown>)) {
    if (
      (key === "mediaPath" || key === "media_path") &&
      typeof raw === "string" &&
      raw.trim()
    ) {
      output.add(raw.trim());
    } else {
      collectMediaPaths(raw, output);
    }
  }
}

async function listSpaceMedia(
  admin: ReturnType<typeof createClient>,
  spaceId: string,
): Promise<string[]> {
  const storage = admin.storage.from("shared-media");
  const result: string[] = [];

  async function walk(path: string) {
    const pageSize = 100;
    for (let offset = 0;; offset += pageSize) {
      const { data, error } = await storage.list(path, {
        limit: pageSize,
        offset,
      });
      if (error) throw error;
      const entries = data ?? [];
      for (const entry of entries) {
        const fullPath = path ? `${path}/${entry.name}` : entry.name;
        if (entry.id) {
          result.push(fullPath);
        } else {
          await walk(fullPath);
        }
      }
      if (entries.length < pageSize) break;
    }
  }

  await walk(spaceId);
  return result;
}

async function removePaths(
  admin: ReturnType<typeof createClient>,
  paths: Iterable<string>,
) {
  const unique = [...new Set([...paths].map((p) => p.trim()).filter(Boolean))];
  if (unique.length === 0) return 0;

  const storage = admin.storage.from("shared-media");
  let removed = 0;
  for (let i = 0; i < unique.length; i += 100) {
    const chunk = unique.slice(i, i + 100);
    const { error } = await storage.remove(chunk);
    if (error) throw error;
    removed += chunk.length;
  }
  return removed;
}

Deno.serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }
  if (req.method !== "POST") {
    return json({ error: "method_not_allowed" }, 405);
  }

  const authHeader = req.headers.get("Authorization") ?? "";
  if (!authHeader.startsWith("Bearer ")) {
    return json({ error: "missing_authorization" }, 401);
  }

  let body: Record<string, unknown> = {};
  try {
    body = await req.json();
  } catch (_) {
    return json({ error: "invalid_json" }, 400);
  }
  if (body.confirm !== "DELETE_MY_ACCOUNT") {
    return json({ error: "explicit_confirmation_required" }, 400);
  }

  const supabaseUrl = Deno.env.get("SUPABASE_URL") ?? "";
  const publishableKeys = envJson("SUPABASE_PUBLISHABLE_KEYS");
  const secretKeys = envJson("SUPABASE_SECRET_KEYS");
  const publicKey =
    publishableKeys.default ?? Deno.env.get("SUPABASE_ANON_KEY") ?? "";
  const adminKey =
    secretKeys.default ?? Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";

  if (!supabaseUrl || !publicKey || !adminKey) {
    return json({ error: "supabase_keys_unavailable" }, 500);
  }

  const userClient = createClient(supabaseUrl, publicKey, {
    global: { headers: { Authorization: authHeader } },
    auth: { persistSession: false },
  });
  const admin = createClient(supabaseUrl, adminKey, {
    auth: { persistSession: false },
  });

  const accessToken = authHeader.substring("Bearer ".length);
  const {
    data: { user },
    error: userError,
  } = await userClient.auth.getUser(accessToken);
  if (userError || !user) {
    return json({ error: "invalid_session" }, 401);
  }

  try {
    // Preserve collaboration semantics before the database cascades run:
    // - if the user owns a shared space, its whole media folder disappears
    //   with the space;
    // - otherwise remove only media referenced by shared records owned by the
    //   deleting user.
    const mediaPaths = new Set<string>();

    const { data: ownedSpaces, error: ownedSpacesError } = await admin
      .from("shared_spaces")
      .select("id")
      .eq("owner_id", user.id);
    if (ownedSpacesError) throw ownedSpacesError;

    for (const row of ownedSpaces ?? []) {
      const spaceId = String(row.id ?? "").trim();
      if (!spaceId) continue;
      for (const path of await listSpaceMedia(admin, spaceId)) {
        mediaPaths.add(path);
      }
    }

    const { data: ownedRecords, error: ownedRecordsError } = await admin
      .from("agenda_records")
      .select("payload")
      .eq("owner_id", user.id)
      .eq("visibility", "shared");
    if (ownedRecordsError) throw ownedRecordsError;

    for (const row of ownedRecords ?? []) {
      collectMediaPaths(row.payload, mediaPaths);
    }

    const removedMedia = await removePaths(admin, mediaPaths);

    // All application tables referencing auth.users are configured with
    // CASCADE/SET NULL. Auth deletion is therefore the authoritative final
    // transaction for private records, memberships, comments, reactions,
    // push registrations, reminders and owned shared spaces.
    const { error: deleteError } = await admin.auth.admin.deleteUser(user.id);
    if (deleteError) throw deleteError;

    return json({
      ok: true,
      deleted_user_id: user.id,
      removed_shared_media: removedMedia,
    });
  } catch (error) {
    const detail = error instanceof Error ? error.message : String(error);
    return json(
      {
        ok: false,
        error: "account_deletion_failed",
        detail: detail.slice(0, 240),
      },
      500,
    );
  }
});
