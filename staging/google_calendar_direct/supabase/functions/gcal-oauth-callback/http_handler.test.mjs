import test from 'node:test';
import assert from 'node:assert/strict';
import {createGoogleCalendarStagingHandler} from './http_handler.mjs';
const base='https://pdanpljacyozslrutsor.supabase.co/functions/v1/gcal-oauth-callback';
const validOrigin='https://riccardopinato.github.io';
const userId='c16e0ec0-415c-4e53-a488-5c6ed75d2662';
const fakeToken='Bearer TEST-user-session-token';
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
   enabled,broker,allowedWebOrigins:[validOrigin],
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
 const url=base+'?code=SENSITIVE-GOOGLE-CODE&state=RANDOM';
 const response=await f.handler(new Request(url));
 assert.equal(response.status,200);
 assert.match(response.headers.get('content-security-policy'),/default-src 'none'/);
 assert.equal(response.headers.get('referrer-policy'),'no-referrer');
 const html=await response.text();
 assert.equal(html.includes('SENSITIVE-GOOGLE-CODE'),false);
 assert.equal(html.includes('state=RANDOM'),false);
 assert.equal(f.calls[0][0],'callback');
 assert.equal(f.verified(),0);
});
test('Google callback failure cannot leak error or authorization code',async()=>{
 const f=fixture();
 const handle=createGoogleCalendarStagingHandler({
   enabled:true,verifyAppIdentity:async()=>({accountId:userId}),
   broker:{callback:async()=>{throw Error('SUPER-SECRET-TOKEN');}},
 });
 const response=await handle(new Request(base+'?code=SECRET&state=TEST'));
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
