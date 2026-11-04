// STAGING SOURCE ONLY — injectable Edge HTTP router, NOT deployed.
// verify_jwt=false at Supabase gateway is safe ONLY if all app actions
// authenticate the EXISTING production Supabase user via verifyAppIdentity.
// Google OAuth browser callback is public, but single-use state is mandatory.
const BASE='/functions/v1/gcal-oauth-callback';
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
 return new Response(
  '<!doctype html><html lang="it"><head><meta charset="utf-8">'+
  '<meta name="viewport" content="width=device-width,initial-scale=1">'+
  '<title>Anna\u2019s Diary - Calendar Test</title></head><body><main><p>'+
  message+'</p></main></body></html>',
  {status,headers:{'content-type':'text/html; charset=utf-8',...SECURITY,
    'content-security-policy':"default-src 'none'; base-uri 'none'; frame-ancestors 'none'; form-action 'none'"}});
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
  enabled=false,broker=null,verifyAppIdentity=null,tokenLifecycle=null,requestBudget=null,callbackBudget=null,allowedWebOrigins=[],
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
   if(!url.pathname.startsWith(basePath))return json({error:'NOT_FOUND'},404);
   const suffix=url.pathname.slice(basePath.length);
   if(!['','/health','/start','/preview','/confirm','/disconnect','/connections'].includes(suffix))
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
       await broker.callback({callbackUrl:req.url});
       return browserResponse('Consenso ricevuto. Torna nell\u2019app per verificare l\u2019account Google e confermare il collegamento.');
     } catch {
       return browserResponse('Collegamento non completato. Torna nell\u2019app e riprova.',400);
     }
   }
   if(req.method!=='POST'||!['/start','/preview','/confirm','/disconnect','/connections'].includes(suffix))
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
   if(!onlyFields(body,['/start','/connections'].includes(suffix)?[]:suffix==='/preview'?['handle']:
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