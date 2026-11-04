// Anna's Diary Google Calendar — staging callback placeholder.
// Deliberately fails CLOSED: no consent, no codes exchanged, no account links.
// verify_jwt=false is required for a future Google browser callback, but this
// endpoint is safe to expose only because it ignores all OAuth parameters.
const headers: Record<string, string> = {
  'content-type': 'application/json; charset=utf-8',
  'cache-control': 'no-store, max-age=0',
  'referrer-policy': 'no-referrer',
  'x-content-type-options': 'nosniff',
  'x-frame-options': 'DENY',
  'x-robots-tag': 'noindex, nofollow',
  'access-control-allow-origin': 'null',
};

Deno.serve((request: Request): Response => {
  const url = new URL(request.url);
  if (request.method === 'GET' && url.pathname.endsWith('/health')) {
    return new Response(JSON.stringify({
      service: 'anna-calendar-staging',
      status: 'locked',
      google_oauth_active: false,
      google_calendar_writes_active: false,
    }), { status: 200, headers });
  }
  return new Response(JSON.stringify({
    error: 'STAGING_NOT_ACTIVATED',
    google_oauth_active: false,
  }), { status: 503, headers });
});
