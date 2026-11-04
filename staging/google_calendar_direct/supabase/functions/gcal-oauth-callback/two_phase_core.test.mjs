import test from 'node:test';
import assert from 'node:assert/strict';
import {GcalTwoPhaseBroker} from './two_phase_core.mjs';
import {GcalStageVault,GcalStageFault,REQUIRED_SCOPES} from './webcrypto_core.mjs';
import {createProductionIdentityVerifier} from './production_identity.mjs';
import {GcalStageConfirmationPorts} from './confirmation_ports.mjs';
import {GcalStageDbError} from './db_ports.mjs';
const now=()=>1793710000;
const redirect='https://pdanpljacyozslrutsor.supabase.co/functions/v1/gcal-oauth-callback';
const clientId='fake.apps.googleusercontent.com';
const UUID='c16e0ec0-415c-4e53-a488-5c6ed75d2662';
const OTHER='a99d34ac-4859-475e-a43c-789c8192651e';
const denial=(p,kind)=>assert.rejects(p,e=>e instanceof GcalStageFault&&e.kind===kind);
function fixture(options={}) {
 const pending=new Map(),completion=new Map(),links=new Map();
 let exchanges=0;
 const vault=new GcalStageVault(crypto.getRandomValues(new Uint8Array(32)));
 const broker=new GcalTwoPhaseBroker({
   clientId,clientSecret:'fake-server-only',redirectUri:redirect,
   vault,clock:options.clock??now,
   pendingStore:{
     async create(k,v){if(pending.has(k))return false;pending.set(k,v);return true;},
     async take(k){const v=pending.get(k);pending.delete(k);return v??null;},
   },
   completionStore:{
     async create(h,a,e){if(completion.has(h))return false;completion.set(h,{a,e});return true;},
     async read(h,a){const v=completion.get(h);return v?.a===a?v.e:null;},
     async take(h,a){const v=completion.get(h);if(v?.a!==a)return null;completion.delete(h);return v?.e??null;},
   },
   linkStore:{async put(a,s,e){links.set(a+':'+s,e);}},
   tokenExchange:async()=>{exchanges++;return {
     access_token:'fake-access-token',refresh_token:'fake-refresh-token',
     id_token:'fake-id-token',scope:REQUIRED_SCOPES.join(' '),
     token_type:'Bearer',expires_in:3600,
   };},
   idVerifier:async()=>({subject:'google-sub-test',
     email:'test-user@example.invalid',emailVerified:true}),
   ...options,
 });
 return {broker,pending,completion,links,vault,exchanges:()=>exchanges};
}
async function begin(broker,account=UUID) {
 const start=await broker.start({verifiedAccountId:account});
 const oauth=new URL(start.authorizationUrl);
 const callback=new URL(redirect);
 callback.searchParams.set('state',oauth.searchParams.get('state'));
 callback.searchParams.set('code','FAKE-CODE');
 return {start,oauth,callback};
}
test('app starts with private handle only; browser sees only OAuth state',async()=>{
 const f=fixture();const {start,oauth}=await begin(f.broker);
 assert.equal(oauth.host,'accounts.google.com');
 assert.equal(oauth.searchParams.get('scope'),REQUIRED_SCOPES.join(' '));
 assert.equal(oauth.searchParams.get('code_challenge_method'),'S256');
 assert.equal(start.authorizationUrl.includes(start.handle),false);
 assert.equal(start.authorizationUrl.includes(UUID),false);
 assert.equal(start.authorizationUrl.includes('fake-server-only'),false);
 assert.match(start.handle,/^[A-Za-z0-9_-]{43}$/);
 assert.equal(f.pending.size,1);
});
test('Google callback parks consent: no account link until explicit app confirmation',async()=>{
 const f=fixture();const {start,callback}=await begin(f.broker);
 const got=await f.broker.callback({callbackUrl:callback.toString()});
 assert.deepEqual(got,{received:true,connected:false});
 assert.equal(f.pending.size,0);assert.equal(f.completion.size,1);
 assert.equal(f.links.size,0);assert.equal(f.exchanges(),1);
 const preview=await f.broker.preview({verifiedAccountId:UUID,handle:start.handle});
 assert.deepEqual(preview,{status:'awaiting_confirmation',
   googleSubject:'google-sub-test',googleEmail:'test-user@example.invalid'});
 await denial(f.broker.confirm({verifiedAccountId:UUID,handle:start.handle}),
   'CONFIRMATION_REQUIRED');
 assert.equal(f.completion.size,1);
 const accepted=await f.broker.confirm({verifiedAccountId:UUID,handle:start.handle,
   explicitConfirmation:true});
 assert.equal(accepted.connected,true);assert.equal(accepted.googleSubject,'google-sub-test');
 assert.equal(f.links.size,1);
 assert.equal(JSON.stringify([...f.links]).includes('fake-refresh-token'),false);
 await denial(f.broker.confirm({verifiedAccountId:UUID,handle:start.handle,
   explicitConfirmation:true}),'COMPLETION_NOT_READY');
 assert.equal((await f.broker.preview({verifiedAccountId:UUID,handle:start.handle})).status,'waiting');
});
test('wrong Supabase user cannot preview or consume another user confirmation',async()=>{
 const f=fixture();const {start,callback}=await begin(f.broker);
 await f.broker.callback({callbackUrl:callback.toString()});
 assert.equal((await f.broker.preview({verifiedAccountId:OTHER,
   handle:start.handle})).status,'waiting');
 await denial(f.broker.confirm({verifiedAccountId:OTHER,handle:start.handle,
   explicitConfirmation:true}),'COMPLETION_NOT_READY');
 assert.equal(f.completion.size,1);
 assert.equal((await f.broker.preview({verifiedAccountId:UUID,
   handle:start.handle})).status,'awaiting_confirmation');
});
test('callback state replay rejected before a second token exchange',async()=>{
 const f=fixture();const {callback}=await begin(f.broker);
 await f.broker.callback({callbackUrl:callback.toString()});
 await denial(f.broker.callback({callbackUrl:callback.toString()}),'REPLAY_OR_UNKNOWN_STATE');
 assert.equal(f.exchanges(),1);
});
test('denied consent, incorrect scope or unverified subject cannot link',async()=>{
 let f=fixture();let {callback}=await begin(f.broker);
 callback.searchParams.delete('code');callback.searchParams.set('error','access_denied');
 await denial(f.broker.callback({callbackUrl:callback.toString()}),'ACCESS_DENIED');
 assert.equal(f.links.size,0);assert.equal(f.completion.size,0);
 f=fixture({tokenExchange:async()=>({access_token:'a',refresh_token:'r',
   id_token:'i',scope:'openid email',token_type:'Bearer',expires_in:3600})});
 ({callback}=await begin(f.broker));
 await denial(f.broker.callback({callbackUrl:callback.toString()}),'SCOPE_MISMATCH');
 f=fixture({idVerifier:async()=>({subject:''})});({callback}=await begin(f.broker));
 await denial(f.broker.callback({callbackUrl:callback.toString()}),'BAD_GOOGLE_SUBJECT');
});
test('expired OAuth and completion previews fail closed',async()=>{
 let instant=now();const f=fixture({clock:()=>instant});
 const {start,callback}=await begin(f.broker);
 instant+=601;
 await denial(f.broker.callback({callbackUrl:callback.toString()}),'EXPIRED');
 assert.equal(f.completion.size,0);
 let clock=now();const g=fixture({clock:()=>clock});
 const r=await begin(g.broker);
 await g.broker.callback({callbackUrl:r.callback.toString()});
 clock+=601;
 await denial(g.broker.preview({verifiedAccountId:UUID,handle:r.start.handle}),'EXPIRED');
});
test('unverified Google email never appears on preview',async()=>{
 const f=fixture({idVerifier:async()=>({subject:'test-google',email:'unverified@example.invalid',
   emailVerified:false})});const r=await begin(f.broker);
 await f.broker.callback({callbackUrl:r.callback.toString()});
 const preview=await f.broker.preview({verifiedAccountId:UUID,handle:r.start.handle});
 assert.equal(preview.googleEmail,null);
});
test('production identity verifier pins exact Supabase Auth host and rejects anonymous accounts',async()=>{
 let calls=0;const verifier=createProductionIdentityVerifier({
   productionPublishableKey:'sb_publishable_TEST_DO_NOT_USE',
   fetcher:async(url,init)=>{
     calls++;
     assert.equal(url,'https://pxsxlorntswypdbeerzw.supabase.co/auth/v1/user');
     assert.equal(init.method,'GET');assert.equal(init.redirect,'error');
     assert.equal(init.headers.apikey,'sb_publishable_TEST_DO_NOT_USE');
     assert.equal(init.headers.authorization,JWT);
     return {ok:true,json:async()=>({id:UUID,is_anonymous:false})};
   },
 });
 const identity=await verifier(JWT);assert.deepEqual(identity,{accountId:UUID});
 assert.equal(calls,1);
 await denial(verifier('Bearer bad'),'MISSING_USER_TOKEN');
 assert.equal(calls,1);
 const anon=createProductionIdentityVerifier({productionPublishableKey:'sb_publishable_TEST_DO_NOT_USE',
   fetcher:async()=>({ok:true,json:async()=>({id:UUID,is_anonymous:true})})});
 await denial(anon(JWT),'UNTRUSTED_APP_IDENTITY');
});
test('production auth verifier refuses service-role secret key as configuration',()=>{
 assert.throws(()=>createProductionIdentityVerifier({productionPublishableKey:'sb_secret_DO_NOT_USE'}),
   e=>e.kind==='NOT_A_PUBLIC_KEY');
});
test('completion SQL port uses account-scoped atomic consume and encrypted envelopes',async()=>{
 const calls=[],sql=(s,...args)=>{calls.push({q:s.join('?'),args});return Promise.resolve([])};
 sql.json=value=>({json:value});
 const ports=new GcalStageConfirmationPorts(sql),h='a'.repeat(64),a='b'.repeat(64),
   env={v:1,iv:'fakeiv',data:'long-encrypted-data'};
 assert.equal(await ports.create(h,a,env,1793710600),false);
 assert.match(calls[0].q,/insert into gcal_stage\.oauth_completions/);
 assert.match(calls[0].q,/on conflict \(handle_hash\) do nothing/);
 await ports.read(h,a);assert.match(calls[1].q,/app_account_hash=\?/);
 await ports.take(h,a);
 assert.match(calls[2].q,/delete from gcal_stage\.oauth_completions/);
 assert.match(calls[2].q,/app_account_hash=\?/);
 assert.match(calls[2].q,/returning envelope/);
 await assert.rejects(ports.take('bad',a),GcalStageDbError);
 assert.equal(calls.length,3);
});
const JWT='Bearer '+('a'.repeat(25))+'.'+('b'.repeat(25))+'.'+('c'.repeat(25));
