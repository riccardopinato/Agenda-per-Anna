import test from 'node:test';
import assert from 'node:assert/strict';
import {createGoogleCalendarStagingHandler} from './http_handler.mjs';
const base='https://pdanpljacyozslrutsor.supabase.co/functions/v1/gcal-oauth-callback';
const validOrigin='https://riccardopinato.github.io';
const userId='c16e0ec0-415c-4e53-a488-5c6ed75d2662';
const fakeToken='Bearer TEST-user-session-token';
const validState='A'.repeat(43);
function fixture({enabled=true}={}) {
 const calls=[];
 const broker={
   async start(args) {calls.push(['start',args]);return {
     authorizationUrl:'https://accounts.google.com/o/oauth2/v2/auth?state=fake-state',
     handle:'fake-one-time-handle',expiresAt:1793710600,
   }},
   async callback(args){calls.push(['callback',args]);return {received:true,connected:false};},
   async preview(args){calls.push(['preview',args]);return {
     status:'awaiting_confirmation',googleSubject:'test-google-id',googleEmail:null,
   }},
   async confirm(args){calls.push(['confirm',args]);return {connected:true,googleSubject:'test-google-id'};},
 };
 let verified=0;
 const handler=createGoogleCalendarStagingHandler({
   enabled,broker,requestBudget:{consume:async()=>true},callbackBudget:{consume:async()=>true},allowedWebOrigins:[validOrigin],
   verifyAppIdentity:async header=>{
     verified++;
     if(header!==fakeToken)throw Error('invalid');
     return {accountId:userId};
   }
 });
 return {handler,calls,verified:()=>verified};
}
const post=(route,body={},{
 origin=validOrigin,auth=fakeToken,mime='application/json',
}={})=>{
 const headers={'content-type':mime,'authorization':auth};
 if(origin) headers.origin=origin;
 return new Request(base+route,{method:'POST',headers,body:JSON.stringify(body)});
};
test('hosted Supabase gateway stripped paths return locked health and deny start',async()=>{
  const f=fixture({enabled:false});
  const origin=new URL(base).origin;
  for(const path of ['/health','/gcal-oauth-callback/health',
                       '/functions/v1/gcal-oauth-callback/health']) {
    const response=await f.handler(new Request(origin+path));
    assert.equal(response.status,200,path);
    const data=await response.json();
    assert.equal(data.status,'locked');
    assert.equal(data.google_oauth_active,false);
    assert.equal(data.google_calendar_writes_active,false);
  }
  for(const path of ['/start','/gcal-oauth-callback/start',
                       '/functions/v1/gcal-oauth-callback/start']) {
    const response=await f.handler(postUrl(origin+path));
    assert.equal(response.status,503,path);
    assert.deepEqual(await response.json(),{error:'STAGING_NOT_ACTIVATED'});
  }
  assert.equal((await f.handler(new Request(origin+'/unrecognized'))).status,404);
  assert.equal(f.verified(),0);
  assert.deepEqual(f.calls,[]);
});
test('gateway callback internal URL is reconstructed to exact Google redirect',async()=>{
  const f=fixture();
  const local='http://127.0.0.1:8000/';
  const response=await f.handler(new Request(local+'?state='+validState+'&code=TEST_CODE'));
  assert.equal(response.status,200);
  assert.equal(f.calls.length,1);
  assert.equal(f.calls[0][0],'callback');
  const u=new URL(f.calls[0][1].callbackUrl);
  assert.equal(u.origin,'https://pdanpljacyozslrutsor.supabase.co');
  assert.equal(u.pathname,'/functions/v1/gcal-oauth-callback');
  assert.equal(u.searchParams.get('state'),validState);
  assert.equal(u.searchParams.get('code'),'TEST_CODE');
  assert.equal((await response.text()).includes('TEST_CODE'),false);
});
const postUrl=(url)=>new Request(url,{method:'POST',headers:{
  'Content-Type':'application/json'},body:'{}'});

test('locked Edge mode blocks real flows without touching identity or OAuth',async()=>{
 const f=fixture({enabled:false});
 const health=await f.handler(new Request(base+'/health'));
 assert.equal(health.status,200);
 assert.equal((await health.json()).google_oauth_active,false);
 const result=await f.handler(post('/start',{}));
 assert.equal(result.status,503);
 assert.deepEqual(f.calls,[]);
 assert.equal(f.verified(),0);
 const cb=await f.handler(new Request(base+'?state=fake&code=FAKE'));
 assert.equal(cb.status,503);
});
test('start requires verified production JWT and forbids user supplied IDs',async()=>{
 const f=fixture();
 let res=await f.handler(post('/start',{}, {auth:'Bearer BAD'}));
 assert.equal(res.status,401);assert.equal(f.calls.length,0);
 res=await f.handler(post('/start',{accountId:'imposter'}));
 assert.equal(res.status,400);assert.equal(f.calls.length,0);
 res=await f.handler(post('/start',{}, {origin:'https://evil.invalid'}));
 assert.equal(res.status,403);
 res=await f.handler(post('/start',{}, {mime:'text/plain'}));
 assert.equal(res.status,415);
 res=await f.handler(post('/start',{}));
 assert.equal(res.status,200);
 const body=await res.json();
 assert.equal(body.handle,'fake-one-time-handle');
 assert.equal(body.authorizationUrl.includes('TEST-user-session-token'),false);
 assert.equal(res.headers.get('cache-control'),'no-store, max-age=0');
 assert.equal(res.headers.get('access-control-allow-origin'),validOrigin);
 assert.equal(f.calls[0][1].verifiedAccountId,userId);
});
test('preview/confirm use verified active account and explicit final consent',async()=>{
 const f=fixture();
 let res=await f.handler(post('/preview',{handle:'opaque'}));
 assert.equal(res.status,200);
 assert.equal((await res.json()).status,'awaiting_confirmation');
 res=await f.handler(post('/confirm',{handle:'opaque'}));
 assert.equal(res.status,400);
 assert.equal(f.calls.filter(x=>x[0]==='confirm').length,0);
 res=await f.handler(post('/confirm',{handle:'opaque',explicitConfirmation:true}));
 assert.equal(res.status,200);
 assert.equal(f.calls.at(-1)[1].verifiedAccountId,userId);
 assert.equal(f.calls.at(-1)[1].handle,'opaque');
});
test('callback response hides OAuth code and Google identity and requires no JWT',async()=>{
 const f=fixture();
 const url=base+'?code=SENSITIVE-GOOGLE-CODE&state='+validState;
 const response=await f.handler(new Request(url));
 assert.equal(response.status,200);
 assert.match(response.headers.get('content-security-policy'),/default-src 'none'/);
 assert.equal(response.headers.get('referrer-policy'),'no-referrer');
 const html=await response.text();
 assert.equal(html.includes('SENSITIVE-GOOGLE-CODE'),false);
 assert.equal(html.includes(validState),false);
 assert.equal(f.calls[0][0],'callback');
 assert.equal(f.verified(),0);
});
test('Google callback failure cannot leak error or authorization code',async()=>{
 const f=fixture();
 const handle=createGoogleCalendarStagingHandler({
   enabled:true,requestBudget:{consume:async()=>true},callbackBudget:{consume:async()=>true},verifyAppIdentity:async()=>({accountId:userId}),
   broker:{callback:async()=>{throw Error('SUPER-SECRET-TOKEN');}},
 });
 const response=await handle(new Request(base+'?code=SECRET&state='+validState));
 assert.equal(response.status,400);
 const text=await response.text();
 assert.equal(text.includes('SECRET'),false);
 assert.equal(text.includes('SUPER-SECRET-TOKEN'),false);
});
test('rejects unknown endpoints and oversized payload without invoking service',async()=>{
 const f=fixture();
 assert.equal((await f.handler(new Request(base+'/../../other'))).status,404);
 const res=await f.handler(post('/confirm',{handle:'a'.repeat(3000),explicitConfirmation:true}));
 assert.equal(res.status,400);
 assert.equal(f.calls.length,0);
});
test('CORS only permits declared web origin with no wildcard and no credentials',async()=>{
 const f=fixture();
 const req=new Request(base+'/start',{
   method:'OPTIONS',headers:{origin:validOrigin,'access-control-request-method':'POST'}
 });
 const res=await f.handler(req);
 assert.equal(res.status,204);
 assert.equal(res.headers.get('access-control-allow-origin'),validOrigin);
 assert.equal(res.headers.get('access-control-allow-credentials'),null);
 const denied=await f.handler(new Request(base+'/start',{
   method:'OPTIONS',headers:{origin:'https://evil.invalid'}
 }));
 assert.equal(denied.status,403);
});


test('connections list is authenticated, rate-limited and never discloses bearer or provider tokens',async()=>{
 let queries=0;
 const handler=createGoogleCalendarStagingHandler({
  enabled:true,broker:{},requestBudget:{async consume(account,action){
   assert.equal(account,userId);assert.equal(action,'connections');return true;
  }},callbackBudget:{consume:async()=>true},
  allowedWebOrigins:[validOrigin],
  verifyAppIdentity:async header=>{
   if(header!==fakeToken)throw Error('wrong-token');
   return {accountId:userId};
  },
  tokenLifecycle:{async listConnections({verifiedAccountId}){
   queries++;assert.equal(verifiedAccountId,userId);
   return {connections:[{googleSubject:'google-one',googleEmail:'verified@example.invalid'}]};
  }},
 });
 let response=await handler(post('/connections',{}, {auth:'Bearer BAD'}));
 assert.equal(response.status,401);assert.equal(queries,0);
 response=await handler(post('/connections',{accountId:'imposter'}));
 assert.equal(response.status,400);assert.equal(queries,0);
 response=await handler(post('/connections',{}));
 assert.equal(response.status,200);
 const body=JSON.stringify(await response.json());
 assert.equal(queries,1);
 assert.equal(body.includes('TEST-user-session-token'),false);
 assert.equal(body.includes('refreshToken'),false);
 assert.match(body,/google-one/);
 assert.equal(response.headers.get('cache-control'),'no-store, max-age=0');
});

test('authenticated disconnect requires explicit consent and never exposes provider tokens',async()=>{
  const calls=[];
  const handler=createGoogleCalendarStagingHandler({
    enabled:true,broker:{},requestBudget:{consume:async()=>true},callbackBudget:{consume:async()=>true},
    allowedWebOrigins:[validOrigin],
    verifyAppIdentity:async header=>{
      if(header!==fakeToken)throw Error('invalid');
      return {accountId:userId};
    },
    tokenLifecycle:{async disconnect(args){
      calls.push(args);return {disconnected:true,providerRevoked:false};
    }},
  });
  let response=await handler(post('/disconnect',{googleSubject:'subject'}));
  assert.equal(response.status,400);
  assert.equal(calls.length,0);
  response=await handler(post('/disconnect',{googleSubject:'subject',
    explicitConfirmation:true},{auth:'Bearer BAD'}));
  assert.equal(response.status,401);
  assert.equal(calls.length,0);
  response=await handler(post('/disconnect',{googleSubject:'subject',
    explicitConfirmation:true}));
  assert.equal(response.status,200);
  assert.deepEqual(await response.json(),{disconnected:true,providerRevoked:false});
  assert.equal(response.headers.get('cache-control'),'no-store, max-age=0');
  assert.deepEqual(calls,[{verifiedAccountId:userId,googleSubject:'subject',
    explicitConfirmation:true}]);
});

test('authenticated staging budget fails closed at the configured quota',async()=>{
  const seen=[];
  const handler=createGoogleCalendarStagingHandler({
    enabled:true,broker:{start:async()=>{throw Error('SHOULD_NOT_START');}},
    requestBudget:{async consume(accountId,action){seen.push([accountId,action]);return false;}},
    callbackBudget:{consume:async()=>true},
    verifyAppIdentity:async()=>({accountId:userId}),
    allowedWebOrigins:[validOrigin],
  });
  const response=await handler(post('/start',{}));
  assert.equal(response.status,429);
  assert.deepEqual(await response.json(),{error:'RATE_LIMITED'});
  assert.deepEqual(seen,[[userId,'start']]);
});
test('budget database outage blocks OAuth operations rather than bypassing quota',async()=>{
  const handler=createGoogleCalendarStagingHandler({
    enabled:true,broker:{start:async()=>{throw Error('SHOULD_NOT_START');}},
    requestBudget:{async consume(){throw Error('SENSITIVE_DB_ERROR');}},
    callbackBudget:{consume:async()=>true},
    verifyAppIdentity:async()=>({accountId:userId}),
    allowedWebOrigins:[validOrigin],
  });
  const response=await handler(post('/start',{}));
  assert.equal(response.status,503);
  const body=await response.text();
  assert.equal(body.includes('SENSITIVE_DB_ERROR'),false);
  assert.match(body,/RATE_LIMIT_UNAVAILABLE/);
});
test('unconfigured budget rejects live router construction',()=>{
  assert.throws(()=>createGoogleCalendarStagingHandler({
    enabled:true,broker:{},verifyAppIdentity:async()=>({accountId:userId}),
  }),/MISSING_AUTH_GATE/);
});

test('callback shape rejected without touching quota, Google or production identity',async()=>{
  let quotaCalls=0,oauthCalls=0;
  const handler=createGoogleCalendarStagingHandler({
    enabled:true,broker:{callback:async()=>{oauthCalls++;}},
    requestBudget:{consume:async()=>true},
    callbackBudget:{consume:async()=>{quotaCalls++;return true;}},
    verifyAppIdentity:async()=>{throw Error('SHOULD_NOT_AUTHENTICATE');},
  });
  const cases=[
    base+'?code=CODE&state=short',
    base+'?code=CODE&state='+validState+'&state='+validState,
    base+'?code=CODE&state='+validState+'&error=access_denied',
    base+'?code=CODE&state='+validState+'&code=SECOND',
    base+'?code='+('X'.repeat(9000))+'&state='+validState,
  ];
  for(const uri of cases) {
    const response=await handler(new Request(uri));
    assert.equal(response.status,400);
    assert.equal(response.headers.get('cache-control'),'no-store, max-age=0');
  }
  assert.equal(quotaCalls,0);
  assert.equal(oauthCalls,0);
});
test('callback global quota 429 blocks broker and never exposes credentials',async()=>{
  let brokerCalls=0;
  const handler=createGoogleCalendarStagingHandler({
    enabled:true,broker:{callback:async()=>{brokerCalls++;}},
    requestBudget:{consume:async()=>true},
    callbackBudget:{consume:async()=>false},
    verifyAppIdentity:async()=>({accountId:userId}),
  });
  const response=await handler(new Request(base+'?state='+validState+'&code=SENSITIVE_GOOGLE_CODE'));
  assert.equal(response.status,429);
  const body=await response.text();
  assert.equal(body.includes('SENSITIVE_GOOGLE_CODE'),false);
  assert.equal(brokerCalls,0);
});
test('callback SQL outage 503 fails closed, no broker call or DB detail leaks',async()=>{
  let brokerCalls=0;
  const handler=createGoogleCalendarStagingHandler({
    enabled:true,broker:{callback:async()=>{brokerCalls++;}},
    requestBudget:{consume:async()=>true},
    callbackBudget:{consume:async()=>{throw Error('PRIVATE_SQL_SECRET');}},
    verifyAppIdentity:async()=>({accountId:userId}),
  });
  const response=await handler(new Request(base+'?state='+validState+'&code=SECRET_CODE'));
  assert.equal(response.status,503);
  const body=await response.text();
  assert.equal(body.includes('PRIVATE_SQL_SECRET'),false);
  assert.equal(body.includes('SECRET_CODE'),false);
  assert.equal(brokerCalls,0);
});
test('enabled OAuth router rejects missing public callback quota',()=>{
  assert.throws(()=>createGoogleCalendarStagingHandler({
    enabled:true,broker:{},verifyAppIdentity:async()=>({accountId:userId}),
    requestBudget:{consume:async()=>true},
  }),/MISSING_AUTH_GATE/);
});
