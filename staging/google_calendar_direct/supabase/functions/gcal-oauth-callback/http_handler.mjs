// STAGING SOURCE ONLY — injectable Edge HTTP router, NOT deployed.
// verify_jwt=false at Supabase gateway is safe ONLY if all app actions
// authenticate the EXISTING production Supabase user via verifyAppIdentity.
// Google OAuth browser callback is public, but single-use state is mandatory.
const BASE='/functions/v1/gcal-oauth-callback';
const STAGING_HOST='https://pdanpljacyozslrutsor.supabase.co';
// The hosted Supabase gateway may strip /functions/v1/<slug> from req.url.
// Accept only these exact representations; never accept arbitrary URL paths.
function routeSuffix(path,basePath) {
 const roots=basePath===BASE?[BASE,'/gcal-oauth-callback','']: [basePath];
 for(const root of roots) {
   if(root==='') {
     if(path==='/')return '';
     if(['/health','/start','/preview','/confirm','/disconnect','/connections','/calendars'].includes(path))
       return path;
     continue;
   }
   if(path===root)return '';
   if(path.startsWith(root+'/'))return path.slice(root.length);
 }
 return null;
}
const SECURITY={
 'cache-control':'no-store, max-age=0',
 'referrer-policy':'no-referrer',
 'x-content-type-options':'nosniff',
 'x-frame-options':'DENY',
 'x-robots-tag':'noindex, nofollow',
};
function json(data,status=200,origin=null) {
 const headers={'content-type':'application/json; charset=utf-8',...SECURITY};
 if(origin) {headers['access-control-allow-origin']=origin;headers['vary']='Origin';}
 return new Response(JSON.stringify(data),{status,headers});
}
function browserResponse(message,status=200) {
 // Supabase's public Edge gateway serves HTML as text/plain for safety.
 // Return deliberate readable plain text instead of raw <html> markup.
 return new Response('Anna\u2019s Diary - Google Calendar QA\n\n'+message,
  {status,headers:{'content-type':'text/plain; charset=utf-8',...SECURITY,
    'content-security-policy':"default-src 'none'; base-uri 'none'; frame-ancestors 'none'; form-action 'none'"}});
}
const CALLBACK_DIAGNOSTIC_CODES=new Set([
  'BAD_CALLBACK','BAD_STATE','WRONG_CALLBACK','REPLAY_OR_UNKNOWN_STATE',
  'VAULT_INTEGRITY','EXPIRED','ACCESS_DENIED','GOOGLE_UNAVAILABLE',
  'GOOGLE_TOKEN_REJECTED','TOKEN_REQUEST_INVALID','BAD_TOKEN_RESPONSE',
  'SCOPE_MISMATCH','BAD_ID_TOKEN','BAD_ALGORITHM','JWKS_UNAVAILABLE',
  'UNKNOWN_KID','BAD_ID_SIGNATURE','BAD_ID_CLAIMS','BAD_GOOGLE_SUBJECT',
  'STATE_COLLISION','COMPLETION_COLLISION',
]);
export function safeCallbackFailureCode(error) {
  // A deliberately finite allowlist. NEVER log error.message, stack,
  // JWTs, callback query, Google code, tokens or SQL/DB secrets.
  return error?.name==='GcalStageFault'&&
    CALLBACK_DIAGNOSTIC_CODES.has(error.kind)
    ? error.kind : 'UNCLASSIFIED_CALLBACK_FAILURE';
}
async function boundedBody(req,limit=2048) {
 const reader=req.body?.getReader();
 if(!reader)return {};
 let total=0,chunks=[];
 try {
   while(true) {
     const {done,value}=await reader.read();
     if(done)break;
     total+=value?.length??0;
     if(total>limit)throw new Error('BODY_TOO_LARGE');
     chunks.push(value);
   }
   const merged=new Uint8Array(total);
   let offset=0;
   for(const c of chunks){merged.set(c,offset);offset+=c.length;}
   const text=new TextDecoder('utf-8',{fatal:true}).decode(merged);
   return text?JSON.parse(text):{};
 } finally {reader.releaseLock();}
}
const onlyFields=(value,fields)=>value&&typeof value==='object'&&!Array.isArray(value)&&
  Object.keys(value).every(k=>fields.includes(k));
export function createGoogleCalendarStagingHandler({
  enabled=false,broker=null,verifyAppIdentity=null,tokenLifecycle=null,requestBudget=null,callbackBudget=null,calendarReadProbe=null,allowedWebOrigins=[],
  basePath=BASE,
}={}) {
 if(enabled&&(!broker||typeof verifyAppIdentity!=='function'||
   !requestBudget||typeof requestBudget.consume!=='function'||
   !callbackBudget||typeof callbackBudget.consume!=='function'))
   throw Error('MISSING_AUTH_GATE');
 const allowed=new Set(allowedWebOrigins.filter(x=>{
   try{const uri=new URL(x);return uri.origin===x&&uri.protocol==='https:';}catch{return false;}
 }));
 return async function handle(req) {
   let url;
   try{url=new URL(req.url);}catch{return json({error:'BAD_URL'},400);}
   const suffix=routeSuffix(url.pathname,basePath);
   if(suffix===null)return json({error:'NOT_FOUND'},404);
   if(!['','/health','/start','/preview','/confirm','/disconnect','/connections','/calendars'].includes(suffix))
     return json({error:'NOT_FOUND'},404);
   if(req.method==='GET'&&suffix==='/health')return json({
     service:'anna-calendar-staging',status:enabled?'configured':'locked',
     google_oauth_active:enabled,google_calendar_writes_active:false,
   });
   if(!enabled)return json({error:'STAGING_NOT_ACTIVATED'},503);
   const origin=req.headers.get('origin');
   if(origin&&!allowed.has(origin))return json({error:'ORIGIN_NOT_ALLOWED'},403);
   if(req.method==='OPTIONS'&&suffix!=='') {
     if(!origin)return json({error:'ORIGIN_REQUIRED'},403);
     return new Response(null,{status:204,headers:{...SECURITY,
       'access-control-allow-origin':origin,
       'access-control-allow-methods':'POST, OPTIONS',
       'access-control-allow-headers':'authorization,content-type',
       'access-control-max-age':'300','vary':'Origin'}});
   }
   if(req.method==='GET'&&suffix==='') {
     // Public browser callback: validate shape before database and token exchange.
     // An arbitrary Origin/IP header is NOT a trustworthy rate-limit identity.
     const states=url.searchParams.getAll('state'),
       codes=url.searchParams.getAll('code'),
       errors=url.searchParams.getAll('error');
     if(url.search.length>8192||states.length!==1||
       !/^[A-Za-z0-9_-]{43}$/.test(states[0])||
       (codes.length===1&&errors.length!==0)||
       (errors.length===1&&codes.length!==0)||
       (codes.length!==1&&errors.length!==1))
       return browserResponse('Collegamento non completato. Torna nell\u2019app e riprova.',400);
     // One atomic global quota across Edge isolates. It is NOT a substitute
     // for a verified upstream ingress/WAF throttle against network floods.
     try {
       if(await callbackBudget.consume()!==true)
         return browserResponse('Troppe richieste. Riprova tra poco.',429);
     } catch {return browserResponse('Servizio temporaneamente non disponibile.',503);}
     // Browser callback never receives Supabase JWT and NEVER links accounts.
     try {
       // Reconstruct the externally registered HTTPS redirect: the gateway
       // may expose an internal http:// URL with its function prefix stripped.
       const publicCallback=new URL(STAGING_HOST+BASE);
       publicCallback.search=url.search;
       await broker.callback({callbackUrl:publicCallback.href});
       return browserResponse('Consenso ricevuto. Torna nell\u2019app per verificare l\u2019account Google e confermare il collegamento.');
     } catch(error) {
       // Non-sensitive failure classification for server-side diagnosis only.
       // No URL, user ID, token, auth code, Google email or free-form exception.
       console.warn('ANNA_GCAL_QA_CALLBACK_RESULT',safeCallbackFailureCode(error));
       return browserResponse('Collegamento non completato. Torna nell\u2019app e riprova.',400);
     }
   }
   if(req.method!=='POST'||!['/start','/preview','/confirm','/disconnect','/connections','/calendars'].includes(suffix))
     return json({error:'METHOD_NOT_ALLOWED'},405);
   const mime=req.headers.get('content-type')?.split(';')[0].toLowerCase().trim();
   if(mime!=='application/json')return json({error:'JSON_REQUIRED'},415,origin);
   const header=req.headers.get('authorization');
   let verified;
   try {verified=await verifyAppIdentity(header);}
   catch {return json({error:'AUTH_REQUIRED'},401,origin);}
   if(!verified||typeof verified.accountId!=='string'||verified.accountId.trim()==='')
     return json({error:'AUTH_REQUIRED'},401,origin);
   // Durable account-scoped throttle. Reject if DB budget is missing or unavailable.
   // Public browser callback remains subject to a separate ingress flood gate.
   try {
     if(await requestBudget.consume(verified.accountId,suffix.slice(1))!==true)
       return json({error:'RATE_LIMITED'},429,origin);
   } catch {return json({error:'RATE_LIMIT_UNAVAILABLE'},503,origin);}
   let body;
   try{body=await boundedBody(req);}catch{return json({error:'INVALID_BODY'},400,origin);}
   if(!onlyFields(body,['/start','/connections'].includes(suffix)?[]:suffix==='/preview'?['handle']:suffix==='/calendars'?['googleSubject']:
     suffix==='/disconnect'?['googleSubject','explicitConfirmation']:
     ['handle','explicitConfirmation']))return json({error:'UNEXPECTED_FIELDS'},400,origin);
   try {
     if(suffix==='/start') {
       const result=await broker.start({verifiedAccountId:verified.accountId});
       return json(result,200,origin);
     }
     if(suffix==='/connections') {
       if(!tokenLifecycle||typeof tokenLifecycle.listConnections!=='function')
         return json({error:'LIFECYCLE_NOT_READY'},503,origin);
       const result=await tokenLifecycle.listConnections({verifiedAccountId:verified.accountId});
       return json(result,200,origin);
     }
     if(suffix==='/calendars') {
       if(!calendarReadProbe||typeof calendarReadProbe.calendars!=='function')
         return json({error:'CALENDAR_READ_NOT_READY'},503,origin);
       if(typeof body.googleSubject!=='string'||body.googleSubject.length<1||
          body.googleSubject.length>256)
         return json({error:'INVALID_GOOGLE_SUBJECT'},400,origin);
       const result=await calendarReadProbe.calendars({verifiedAccountId:verified.accountId,
         googleSubject:body.googleSubject});
       return json(result,200,origin);
     }
     if(suffix==='/disconnect') {
       if(!tokenLifecycle||typeof tokenLifecycle.disconnect!=='function')
         return json({error:'LIFECYCLE_NOT_READY'},503,origin);
       if(body.explicitConfirmation!==true)
         return json({error:'EXPLICIT_CONFIRMATION_REQUIRED'},400,origin);
       if(typeof body.googleSubject!=='string'||body.googleSubject.length<1||
          body.googleSubject.length>256)
         return json({error:'INVALID_GOOGLE_SUBJECT'},400,origin);
       const result=await tokenLifecycle.disconnect({verifiedAccountId:verified.accountId,
         googleSubject:body.googleSubject,explicitConfirmation:true});
       return json(result,200,origin);
     }
     if(typeof body.handle!=='string'||body.handle.length>128)
       return json({error:'INVALID_HANDLE'},400,origin);
     if(suffix==='/preview') {
       const result=await broker.preview({verifiedAccountId:verified.accountId,
         handle:body.handle});
       return json(result,200,origin);
     }
     if(body.explicitConfirmation!==true)
       return json({error:'EXPLICIT_CONFIRMATION_REQUIRED'},400,origin);
     const result=await broker.confirm({verifiedAccountId:verified.accountId,
       handle:body.handle,explicitConfirmation:true});
     return json(result,200,origin);
   } catch {
     // Never echo Google codes, JWTs, browser state, token errors or secrets.
     return json({error:'OAUTH_STEP_REJECTED'},409,origin);
   }
 };
}